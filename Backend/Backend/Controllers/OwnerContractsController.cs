using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend.Helpers;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace Backend.Controllers
{
    [Route("api/[controller]")] // Route sẽ thành: /api/OwnerContracts
    [ApiController]
    public class OwnerContractsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerContractsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }


        [HttpGet]
        [HttpGet("{ownerId}")]
        [Authorize(Roles = "owner,landlord,admin")]
        public async Task<IActionResult> GetContracts( [FromRoute] string? ownerId,[FromQuery] string? status, [FromQuery] string? search, [FromQuery(Name = "ownerId")] string? ownerIdQuery = null)
        {
            try
            {
                  string? targetOwner = !string.IsNullOrEmpty(ownerId)
                             ? ownerId
                             : ownerIdQuery;
                  if (!User.IsInRole("admin"))
                  {
                      var actorId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                      if (string.IsNullOrEmpty(actorId)) return Unauthorized();
                      if (!string.IsNullOrEmpty(targetOwner) && !IsOwner(actorId, targetOwner))
                          return Forbid();
                      targetOwner = actorId;
                  }

                  var query = _context.Contracts
                             .Include(c => c.Room)
                                 .ThenInclude(r => r.Property)
                             .Include(c => c.Tenant)
                             .Include(c => c.ContractMembers)
                             .Include(c => c.ContractServices)
                                 .ThenInclude(cs => cs.Service)
                             .AsQueryable();


                  if (!string.IsNullOrEmpty(targetOwner) && targetOwner != "all")
                         {
                             var targetOwnerIds = OwnerHelper.ResolveOwnerIds(targetOwner);
                             query = query.Where(c => targetOwnerIds.Contains(c.OwnerId));
                         }

                  var rawContracts = await query
                             .OrderByDescending(c => c.CreatedAt)
                             .ToListAsync();


                var today = DateOnly.FromDateTime(DateTime.UtcNow);

                var items = rawContracts.Select(c =>
                {
                    var daysLeft = c.EndDate.DayNumber - today.DayNumber;

                    string displayStatus;
                    string timeText;

                    if (c.Status == "terminated")
                    {
                        displayStatus = "Đã thanh lý";
                        timeText = "Đã kết thúc hợp đồng";
                    }
                    else if (c.Status == "draft")
                    {
                        displayStatus = "Bản nháp";
                        timeText = "Bản nháp mới tạo";
                    }
                    else if (c.Status == "rejected" || c.Status == "withdrawn")
                    {
                        displayStatus = c.Status == "rejected" ? "Đã từ chối" : "Đã thu hồi";
                        timeText = c.SigningClosedAt?.ToString("dd/MM/yyyy") ?? displayStatus;
                    }
                    else if (c.Status == "expired")
                    {
                        displayStatus = "Đã hết hạn";
                        timeText = "Đã hết hạn hợp đồng";
                    }
                    else if (c.Status == "pending")
                    {
                        displayStatus = "Chờ ký";
                        timeText = "Đang chờ ký xác nhận";
                    }
                    else if (daysLeft > 0 && daysLeft <= 30)
                    {
                        displayStatus = "Sắp hết hạn";
                        timeText = $"Hết hạn sau {daysLeft} ngày!";
                    }
                    else
                    {
                        displayStatus = "Đang hiệu lực";
                        var monthsLeft = (int)Math.Max(0, (daysLeft / 30));
                        timeText = monthsLeft > 0 ? $"Còn {monthsLeft} tháng" : "Đang hoạt động";
                    }

                    var roomName = c.Room != null ? c.Room.Name : "Phòng chưa xác định";
                    var floorText = c.Room?.Floor != null ? $" • Tầng {c.Room.Floor}" : "";
                    var propName = c.Room?.Property?.Name ?? "Khu trọ";
                    var areaText = c.Room != null ? $" • {c.Room.Area} m²" : "";

                    var memberCount = c.ContractMembers?.Count ?? 0;
                    var note = memberCount > 0
                        ? $"{memberCount + 1} người ở (Đã khai báo tạm trú)"
                        : "Chưa khai báo người ở cùng";

                    return new ContractListItemDto
                    {
                        Id = c.Id,
                        Code = c.ContractCode,

                        // Bổ sung 2 thuộc tính này để Flutter nạp lại đúng phòng và lịch hẹn
                        RoomId = c.RoomId,
                        ViewingAppointmentId = c.ViewingAppointmentId,

                        Room = $"{roomName}{floorText}",
                        Address = $"{propName}{areaText}",
                        Status = displayStatus,
                        TimeText = timeText,
                        TenantName = c.Tenant?.Name ?? "Chưa rõ",
                        TenantPhone = c.Tenant?.Phone ?? "Chưa có SĐT",
                        RentPrice = $"{c.Rent:N0}đ",
                        DepositPrice = $"{c.Deposit:N0}đ",
                        Duration = $"📅 {c.StartDate:dd/MM/yyyy} - {c.EndDate:dd/MM/yyyy}",
                        CycleText = c.PaymentCycle == "quarterly" ? "Kỳ thu: Hàng quý" : "Kỳ thu: Hàng tháng (Ngày 05)",
                        NoteText = note,
                        Cccd = c.Terms?.StartsWith("CCCD:") == true ? c.Terms.Split('|')[0].Replace("CCCD:", ""): "",
                        OwnerSignature = c.OwnerSignature,
                        TenantSignature = c.TenantSignature,
                        SigningClosedAt = c.SigningClosedAt.HasValue
                            ? DateTime.SpecifyKind(c.SigningClosedAt.Value, DateTimeKind.Utc) : null,
                        SigningCloseReason = c.SigningCloseReason,
                        Services = c.ContractServices.Select(cs => new ContractServiceItemDto
                        {
                            ServiceId = cs.ServiceId,
                            Name = cs.Service?.Name ?? "Dịch vụ",
                            Unit = cs.Service?.Unit ?? "tháng",
                            Price = cs.UnitPrice
                        }).ToList(),
                        StartDate = c.StartDate.ToDateTime(TimeOnly.MinValue),
                        EndDate = c.EndDate.ToDateTime(TimeOnly.MinValue)
                    };
                }).ToList();

                if (!string.IsNullOrWhiteSpace(search))
                {
                    var keyword = search.Trim().ToLower();
                    items = items.Where(x =>
                        x.Code.ToLower().Contains(keyword) ||
                        x.TenantName.ToLower().Contains(keyword) ||
                        x.TenantPhone.Contains(keyword) ||
                        x.Room.ToLower().Contains(keyword)
                    ).ToList();
                }

                if (!string.IsNullOrWhiteSpace(status) && status != "Tất cả")
                {
                    items = items.Where(x => x.Status == status).ToList();
                }

                var activeList = rawContracts.Where(c => c.Status == "active").ToList();
                var activeCount = activeList.Count;
                var expectedRevenue = activeList.Sum(c => c.Rent);

                return Ok(new ContractSummaryDto
                {
                    ActiveCount = activeCount,
                    ExpectedRevenue = expectedRevenue,
                    Contracts = items
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách hợp đồng", error = ex.Message });
            }
        }



        // POST: /api/OwnerContracts (Tạo hợp đồng mới / Lưu bản nháp)
        [HttpPost]
        [Authorize(Roles = "owner,landlord")]
        public async Task<IActionResult> CreateContract([FromBody] CreateContractRequest req, CancellationToken cancellationToken)
        {
            try
            {
                var ownerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(ownerId)) return Unauthorized();
                if (string.IsNullOrWhiteSpace(req.RoomId))
                    return BadRequest(new { message = "Vui lòng chọn phòng trọ để lập hợp đồng." });

                var status = req.Status is "pending" or "Chờ ký" ? "pending" : "draft";
                await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
                await RoomSigningLock.AcquireAsync(_context, req.RoomId, cancellationToken);
                var room = await _context.Rooms.Include(r => r.Property)
                    .FirstOrDefaultAsync(r => r.Id == req.RoomId, cancellationToken);
                if (room == null)
                    return NotFound(new { message = "Không tìm thấy phòng trọ phù hợp để tạo hợp đồng." });
                if (!IsOwner(ownerId, room.Property.OwnerId)) return Forbid();

                if (status == "pending" && (room.Status != "available" ||
                    await _context.Contracts.AnyAsync(c => c.RoomId == room.Id &&
                        (c.Status == "pending" || c.Status == "active"), cancellationToken)))
                {
                    return Conflict(new { message = "Phòng này không còn trống hoặc đang được giữ cho một hợp đồng khác." });
                }

                string inputVal = !string.IsNullOrWhiteSpace(req.TenantPhone) ? req.TenantPhone.Trim() : "";
                string formName = !string.IsNullOrWhiteSpace(req.TenantName) ? req.TenantName.Trim() : "Khách thuê mới";

                var tenant = await _context.Users.FirstOrDefaultAsync(u =>
                    u.Email == inputVal ||
                    u.Phone == inputVal
                );

                if (tenant != null)
                {

                    tenant.Name = formName;
                    tenant.UpdatedAt = DateTime.UtcNow;
                }
                else if (!string.IsNullOrEmpty(inputVal))
                {

                    bool isEmail = inputVal.Contains("@");

                    tenant = new User
                    {
                        Id = "usr_" + Guid.NewGuid().ToString("N")[..8],
                        Name = formName, // Lưu đúng tên Đỗ Hoàng Yến
                        Email = isEmail ? inputVal : $"{inputVal}@tenant.local",
                        Phone = isEmail ? null : inputVal,
                        Password = "default_password_123",
                        Role = "tenant",
                        Status = "active",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    _context.Users.Add(tenant);
                }

                await _context.SaveChangesAsync();

                if (tenant == null)
                {
                    return BadRequest(new
                    {
                        message = "Vui lòng cung cấp Email hoặc Số điện thoại người thuê."
                    });
                }

                // 2. Parse ngày tháng chuẩn định dạng dd/MM/yyyy
                DateOnly start = DateOnly.FromDateTime(DateTime.UtcNow);
                DateOnly end = start.AddYears(1);

                if (!string.IsNullOrWhiteSpace(req.StartDate))
                {
                    if (DateOnly.TryParseExact(req.StartDate, "dd/MM/yyyy", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var s))
                        start = s;
                    else DateOnly.TryParse(req.StartDate, out start);
                }

                if (!string.IsNullOrWhiteSpace(req.EndDate))
                {
                    if (DateOnly.TryParseExact(req.EndDate, "dd/MM/yyyy", System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var e))
                        end = e;
                    else DateOnly.TryParse(req.EndDate, out end);
                }

                // 4. Xử lý mã Lịch hẹn (BỎ CHUỖI "walkin" ĐỂ TRÁNH LỖI KHÓA NGOẠI SQL)
                string? validAppointmentId = null;
                if (!string.IsNullOrEmpty(req.ViewingAppointmentId) && req.ViewingAppointmentId != "walkin")
                {
                    var aptExists = await _context.ViewingAppointments.AnyAsync(a =>
                        a.Id == req.ViewingAppointmentId && a.RoomId == room.Id && a.TenantId == tenant.Id);
                    if (aptExists)
                    {
                        validAppointmentId = req.ViewingAppointmentId;
                    }
                }

                //  KHÓA ĐỐI SOÁT CHÍNH XÁC HỌ TÊN VÀ SỐ CCCD NHÂN THÂN (Không phân biệt hoa/thường/dấu):
                if (!string.IsNullOrWhiteSpace(req.Cccd))
                {
                    var cleanCccd = req.Cccd.Trim();
                    var inputName = req.TenantName?.Trim() ?? "";

                    // 1. Đối soát với bảng ContractMembers (Thành viên / Công dân đã đăng ký CCCD)
                    var memberByCccd = await _context.ContractMembers.FirstOrDefaultAsync(m => m.IdentityCard == cleanCccd);
                    if (memberByCccd != null && RemoveAccents(memberByCccd.Name) != RemoveAccents(inputName))
                    {
                        return BadRequest(new { message = $"Lỗi sai lệch nhân thân: Số CCCD {cleanCccd} đã thuộc về công dân '{memberByCccd.Name}' trên CSDL! Tên '{inputName}' không trùng khớp." });
                    }

                    // 3. Khóa chống trùng CCCD ở các phòng đang hoạt động khác
                    var isCccdInOtherContracts = await _context.Contracts
                        .AnyAsync(c => c.TenantId != tenant.Id &&
                            (c.Status == "draft" || c.Status == "pending" || c.Status == "active") &&
                            c.Terms != null && c.Terms.Contains(cleanCccd));

                    var isCccdInMembers = await _context.ContractMembers
                        .AnyAsync(m => m.IdentityCard == cleanCccd && m.Contract.TenantId != tenant.Id &&
                            (m.Contract.Status == "draft" || m.Contract.Status == "pending" || m.Contract.Status == "active"));

                    if (isCccdInOtherContracts || isCccdInMembers)
                    {
                        return BadRequest(new { message = $"Số CCCD {cleanCccd} đã được sử dụng cho một hợp đồng đang hoạt động ở phòng khác! Vui lòng kiểm tra lại." });
                    }
                }

                // 5. Khởi tạo Hợp đồng mới
                var contract = new Contract
                {
                    Id = "ctr_" + Guid.NewGuid().ToString("N")[..8],
                    ContractCode = $"HD-{DateTime.UtcNow.Year}-P{new Random().Next(100, 999)}",
                    ViewingAppointmentId = validAppointmentId, // Đã được xử lý loại bỏ "walkin" an toàn
                    RoomId = room.Id,
                    OwnerId = room.Property.OwnerId,
                    TenantId = tenant.Id,
                    StartDate = start,
                    EndDate = end,
                    Rent = req.RentPrice > 0 ? req.RentPrice : room.Price,
                    Deposit = req.DepositPrice > 0 ? req.DepositPrice : room.Deposit,
                    PaymentCycle = "monthly",
                    InitialElectricityReading = req.ElectricIndex,
                    InitialWaterReading = req.WaterIndex,
                    Status = status,
                    Terms = $"CCCD:{req.Cccd}|IssueDate:{req.IssueDate}|IssuePlace:{req.IssuePlace}",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                if ((contract.Status == "active" || contract.Status == "pending") && room != null)
                {
                    room.Status = "rented";
                    room.UpdatedAt = DateTime.UtcNow;
                }

                // 🔴 KHÓA CHỐNG LẶP HỢP ĐỒNG: Mỗi phòng chỉ được có 1 Hợp đồng Nháp hoặc 1 Hợp đồng Chờ ký
                if (contract.Status == "draft")
                {
                    var existingDraft = await _context.Contracts
                        .FirstOrDefaultAsync(c => c.RoomId == room.Id && c.Status == "draft");

                    if (existingDraft != null)
                    {
                        return BadRequest(new { message = $"Phòng {room.Name} đã có 1 bản hợp đồng nháp rồi! Vui lòng mở bản nháp hiện tại để tiếp tục chỉnh sửa." });
                    }
                }

                if (contract.Status == "pending")
                {
                    var contractNotif = new Notification
                    {
                         Id = "notif_" + Guid.NewGuid().ToString("N")[..8],
                         UserId = tenant.Id, // Mã tài khoản người thuê
                         Title = "Bạn có hợp đồng thuê phòng mới cần ký!",
                         Message = $"Chủ trọ vừa gửi hợp đồng thuê {room.Name} cho bạn. Vui lòng vào mục Hợp đồng để kiểm tra và ký xác nhận.",
                         Type = "contract_pending",
                         ReferenceId = contract.Id,
                         ReferenceType = "contract",
                         CreatedAt = DateTime.UtcNow,
                         UpdatedAt = DateTime.UtcNow
                    };
                    _context.Notifications.Add(contractNotif);
                 }

                _context.Contracts.Add(contract);

                // 6. Lưu Danh sách Dịch vụ áp dụng (Đã kiểm tra tránh lỗi Khóa ngoại SQL)
                if (req.Services != null && req.Services.Any())
                {
                    foreach (var srv in req.Services)
                    {
                        if (!string.IsNullOrEmpty(srv.ServiceId))
                        {
                            var serviceExists = await _context.Services.AnyAsync(s => s.Id == srv.ServiceId);
                            if (serviceExists)
                            {
                                var contractService = new Backend.Models.ContractService
                                {
                                    Id = "cs_" + Guid.NewGuid().ToString("N")[..8],
                                    ContractId = contract.Id,
                                    ServiceId = srv.ServiceId,
                                    UnitPrice = srv.Price,
                                    Status = "active",
                                    CreatedAt = DateTime.UtcNow,
                                    UpdatedAt = DateTime.UtcNow
                                };
                                _context.ContractServices.Add(contractService);
                            }
                        }
                    }
                }

                // 7. Lưu Danh sách Thành viên ở cùng
                if (req.Members != null && req.Members.Any())
                {
                    foreach (var mem in req.Members)
                    {
                        if (!string.IsNullOrEmpty(mem.FullName))
                        {
                            var member = new Backend.Models.ContractMember
                            {
                                Id = "mem_" + Guid.NewGuid().ToString("N")[..8],
                                ContractId = contract.Id,
                                Name = mem.FullName,
                                IdentityCard = mem.Cccd ?? "",
                                Phone = mem.Phone,
                                Relationship = string.IsNullOrEmpty(mem.Relationship) ? "Ở chung" : mem.Relationship,
                                CreatedAt = DateTime.UtcNow,
                                UpdatedAt = DateTime.UtcNow
                            };
                            _context.ContractMembers.Add(member);
                        }
                    }
                }

                // 8. Đổi trạng thái lịch hẹn sang "completed" nếu đây là hợp đồng gửi ký thật
                if (!string.IsNullOrEmpty(validAppointmentId) && contract.Status != "draft")
                {
                    var apt = await _context.ViewingAppointments.FindAsync(validAppointmentId);
                    if (apt != null)
                    {
                        apt.Status = "completed";
                        apt.CompletedAt = DateTime.UtcNow;
                    }
                }

                await _context.SaveChangesAsync();
                await transaction.CommitAsync(cancellationToken);

                return Ok(new
                {
                    message = "Tạo hợp đồng thành công!",
                    contractId = contract.Id,
                    contractCode = contract.ContractCode,
                    status = contract.Status
                });
            }
            catch (Exception ex)
            {
                string errorMsg = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi tạo hợp đồng", error = errorMsg });
            }
        }

        [HttpPut("{id}/sign")]
        [Authorize(Roles = "owner,landlord,tenant")]
        public async Task<IActionResult> SignContract(
            string id, [FromBody] SignContractRequest req, CancellationToken cancellationToken)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
            var contract = await FindSigningContractAsync(id, cancellationToken);
            if (contract == null) return NotFound(new { message = "Không tìm thấy hợp đồng." });

            var isOwner = (User.IsInRole("owner") || User.IsInRole("landlord")) && IsOwner(userId, contract.OwnerId);
            var isTenant = User.IsInRole("tenant") && string.Equals(userId, contract.TenantId, StringComparison.OrdinalIgnoreCase);
            if (!isOwner && !isTenant) return Forbid();
            if (contract.Status != "pending")
                return Conflict(new { message = "Hợp đồng này không còn chờ ký." });

            if (!string.IsNullOrWhiteSpace(req.OwnerSignature))
            {
                if (!isOwner) return Forbid();
                contract.OwnerSignature = req.OwnerSignature;
            }

            if (!string.IsNullOrWhiteSpace(req.TenantSignature))
                contract.TenantSignature = req.TenantSignature;
            else if (string.IsNullOrWhiteSpace(req.OwnerSignature))
                return BadRequest(new { message = "Vui lòng cung cấp chữ ký." });

            var isBothSigned = !string.IsNullOrWhiteSpace(contract.OwnerSignature) &&
                !string.IsNullOrWhiteSpace(contract.TenantSignature);
            var now = DateTime.UtcNow;
            if (isBothSigned)
            {
                if (contract.Room.Status != "available" || await _context.Contracts.AnyAsync(c =>
                    c.RoomId == contract.RoomId && c.Id != contract.Id && c.Status == "active", cancellationToken))
                    return Conflict(new { message = "Phòng không còn trống để kích hoạt hợp đồng." });

                contract.Status = "active";
                contract.SignedAt = now;
                contract.Room.Status = "rented";
                contract.Room.UpdatedAt = now;
            }

            contract.UpdatedAt = now;
            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            return Ok(new
            {
                message = isBothSigned ? "Hợp đồng đã ký đủ hai bên." : "Đã lưu chữ ký, đang chờ bên còn lại.",
                status = contract.Status,
                isBothSigned
            });
        }

        [HttpPut("{id}/reject-signing")]
        [Authorize(Roles = "tenant")]
        public Task<IActionResult> RejectSigning(
            string id, [FromBody] CloseContractSigningRequest request, CancellationToken cancellationToken) =>
            CloseSigningAsync(id, request.Reason, tenantRejects: true, cancellationToken);

        [HttpPut("{id}/withdraw-signing")]
        [Authorize(Roles = "owner,landlord")]
        public Task<IActionResult> WithdrawSigning(
            string id, [FromBody] CloseContractSigningRequest request, CancellationToken cancellationToken) =>
            CloseSigningAsync(id, request.Reason, tenantRejects: false, cancellationToken);

        private async Task<IActionResult> CloseSigningAsync(
            string id, string? reason, bool tenantRejects, CancellationToken cancellationToken)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
            var contract = await FindSigningContractAsync(id, cancellationToken);
            if (contract == null) return NotFound(new { message = "Không tìm thấy hợp đồng." });
            if (tenantRejects ? !string.Equals(contract.TenantId, userId, StringComparison.OrdinalIgnoreCase)
                              : !IsOwner(userId, contract.OwnerId))
                return Forbid();

            var status = tenantRejects ? "rejected" : "withdrawn";
            var message = tenantRejects ? "Đã từ chối ký hợp đồng." : "Đã thu hồi yêu cầu ký.";
            if (contract.Status == status) return Ok(new { message, status });
            if (contract.Status != "pending")
                return Conflict(new { message = "Chỉ có thể kết thúc yêu cầu ký khi hợp đồng đang chờ ký." });

            var now = DateTime.UtcNow;
            var closeReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
            contract.Status = status;
            contract.SigningClosedAt = now;
            contract.SigningCloseReason = closeReason;
            contract.UpdatedAt = now;

            var party = tenantRejects ? "Người thuê đã từ chối ký" : "Chủ trọ đã thu hồi yêu cầu ký";
            var reasonText = closeReason == null ? "" : $" Lý do: {closeReason}";
            _context.Notifications.Add(new Notification
            {
                Id = "NOTIF_" + Guid.NewGuid().ToString("N"),
                UserId = tenantRejects ? contract.OwnerId : contract.TenantId,
                Title = tenantRejects ? "Hợp đồng bị từ chối ký" : "Yêu cầu ký đã được thu hồi",
                Message = $"{party} hợp đồng {contract.ContractCode}.{reasonText}",
                Type = tenantRejects ? "contract_signing_rejected" : "contract_signing_withdrawn",
                ReferenceId = contract.Id,
                ReferenceType = "contract",
                CreatedAt = now,
                UpdatedAt = now
            });

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Ok(new { message, status });
        }

        private async Task<Contract?> FindSigningContractAsync(string id, CancellationToken cancellationToken)
        {
            var roomId = await _context.Contracts
                .Where(c => c.Id == id || c.ContractCode == id)
                .Select(c => c.RoomId)
                .FirstOrDefaultAsync(cancellationToken);
            if (roomId == null) return null;

            await RoomSigningLock.AcquireAsync(_context, roomId, cancellationToken);
            return await _context.Contracts.Include(c => c.Room)
                .FirstOrDefaultAsync(c => c.Id == id || c.ContractCode == id, cancellationToken);
        }

        private static bool IsOwner(string actorId, string ownerId) =>
            OwnerHelper.ResolveOwnerIds(actorId).Contains(ownerId, StringComparer.OrdinalIgnoreCase);

       // GET: /api/OwnerContracts/available-rooms?ownerId=... (Lấy danh sách phòng trống theo Chủ trọ)
           [HttpGet("available-rooms")]
           public async Task<IActionResult> GetAvailableRooms(
               [FromQuery] string? ownerId,
               [FromQuery] string? selectedRoomId = null,
               [FromQuery] string? includeRoomId = null)
           {
               try
               {
                   var targetIncludeId = !string.IsNullOrEmpty(includeRoomId) ? includeRoomId : selectedRoomId;
                   var query = _context.Rooms
                       .Include(r => r.Property)
                       .Where(r =>
                           (!string.IsNullOrEmpty(includeRoomId) && r.Id == includeRoomId) ||
                           (r.Status == "available" &&
                               (r.Id == targetIncludeId ||
                                !r.Contracts.Any(c => c.Status == "pending" || c.Status == "active"))));


                   if (!string.IsNullOrEmpty(ownerId) && ownerId != "all")
                   {
                       var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);
                       query = query.Where(r => r.Property != null && targetOwnerIds.Contains(r.Property.OwnerId));
                   }

                   var rooms = await query
                       .OrderBy(r => r.Property.Name)
                       .ThenBy(r => r.Name)
                       .Select(r => new AvailableRoomDto
                       {
                           RoomId = r.Id,
                           RoomName = r.Name,
                           PropertyName = r.Property.Name,
                           Price = r.Price,
                           Deposit = r.Deposit,
                           Area = (double)r.Area,
                           Floor = r.Floor
                       })
                       .ToListAsync();

                   return Ok(rooms);
               }
               catch (Exception ex)
               {
                   return StatusCode(500, new { message = "Lỗi nạp phòng trống", error = ex.Message });
               }
           }

        // GET: /api/OwnerContracts/appointments (Lấy lịch hẹn xem phòng để liên kết)
        [HttpGet("appointments")]
        public async Task<IActionResult> GetAppointments()
        {
            try
            {
                var appointments = await _context.ViewingAppointments
                    .Include(a => a.Tenant)
                    .Include(a => a.Room)
                    // LẤY CẢ completed ĐỂ KHÔNG BỊ MẤT KHI ĐÃ LƯU NHÁP HOẶC ĐÃ XEM PHÒNG
                    .Where(a => a.Status == "confirmed" || a.Status == "pending" || a.Status == "completed")
                    .OrderByDescending(a => a.AppointmentDate)
                    .Select(a => new AppointmentOptionDto
                    {
                        Id = a.Id,
                        TenantName = a.Tenant != null ? a.Tenant.Name : "Khách xem phòng",
                        TenantPhone = a.Phone,
                        RoomId = a.RoomId,
                        RoomName = a.Room != null ? a.Room.Name : "Phòng"
                    })
                    .ToListAsync();

                return Ok(appointments);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp lịch hẹn", error = ex.Message });
            }
        }



        // 1. DELETE: /api/OwnerContracts/{id} (Chỉ cho phép xóa khi là bản nháp)
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteContract(string id)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.ContractServices)
                    .Include(c => c.ContractMembers)
                    .FirstOrDefaultAsync(c => c.Id == id || c.ContractCode == id);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                if (contract.Status != "draft")
                {
                    return BadRequest(new { message = "Chỉ có thể xóa các hợp đồng đang ở trạng thái Bản nháp." });
                }

                // Xóa các dịch vụ và thành viên đính kèm của hợp đồng nháp nếu có
                if (contract.ContractServices != null && contract.ContractServices.Any())
                {
                    _context.ContractServices.RemoveRange(contract.ContractServices);
                }
                if (contract.ContractMembers != null && contract.ContractMembers.Any())
                {
                    _context.ContractMembers.RemoveRange(contract.ContractMembers);
                }

                _context.Contracts.Remove(contract);

                if (!string.IsNullOrEmpty(contract.RoomId))
                {
                    var hasOtherActive = await _context.Contracts
                        .AnyAsync(c => c.Id != contract.Id && c.RoomId == contract.RoomId && (c.Status == "active" || c.Status == "pending"));
                    if (!hasOtherActive)
                    {
                        var room = await _context.Rooms.FindAsync(contract.RoomId);
                        if (room != null && room.Status == "rented")
                        {
                            room.Status = "available";
                            room.UpdatedAt = DateTime.UtcNow;
                        }
                    }
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã xóa bản nháp thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa hợp đồng", error = ex.Message });
            }
        }

        [HttpGet("room-services/{roomId}")]
        public async Task<IActionResult> GetRoomServices(string roomId)
        {
            try
            {
                var room = await _context.Rooms
                    .Include(r => r.Property)
                    .FirstOrDefaultAsync(r => r.Id == roomId);

                if (room == null)
                {
                    return NotFound(new { message = "Không tìm thấy phòng trọ." });
                }

                // 1. Dịch vụ riêng mà phòng này đã đăng ký/có nhu cầu trước đó (nếu có)
                var roomCustomServiceIds = await _context.RoomServices
                    .Where(rs => rs.RoomId == roomId)
                    .Select(rs => rs.ServiceId)
                    .ToListAsync();

                // 2. Dịch vụ đã cài đặt cho khu trọ này (kèm giá niêm yết từ tin đăng/cơ sở)
                var propertyServices = await _context.PropertyServices
                    .Include(ps => ps.Service)
                    .Where(ps => ps.PropertyId == room.PropertyId && ps.Status == "active")
                    .Select(ps => new
                    {
                        serviceId = ps.ServiceId,
                        name = ps.Service.Name,
                        unit = ps.Service.Unit,
                        price = ps.Price > 0 ? ps.Price : ps.Service.Price,
                        isMandatory = ps.Service.IsMandatory,
                        isDefault = ps.Service.IsMandatory || roomCustomServiceIds.Contains(ps.ServiceId) // Bắt buộc HOẶC phòng đã đăng ký nhu cầu trước đó
                    })
                    .ToListAsync();

                var existingServiceIds = propertyServices.Select(p => p.serviceId).ToList();

                // 2. Các dịch vụ khác trong CSDL chưa có trong khu trọ này
                var otherServices = await _context.Services
                    .Where(s => s.Status == "active" && !existingServiceIds.Contains(s.Id))
                    .Select(s => new
                    {
                        serviceId = s.Id,
                        name = s.Name,
                        unit = s.Unit,
                        price = 0m,
                        isDefault = false
                    })
                    .ToListAsync();

                return Ok(new
                {
                    defaultServices = propertyServices,
                    otherServices = otherServices
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy dịch vụ của phòng", error = ex.Message });
            }
        }


        // 1. GET: /api/OwnerContracts/{contractId}/members (Lấy danh sách người ở cùng)
        [HttpGet("{contractId}/members")]
        public async Task<IActionResult> GetContractMembers(string contractId)
        {
            try
            {
                var members = await _context.ContractMembers
                    .Where(m => m.ContractId == contractId)
                    .OrderByDescending(m => m.CreatedAt)
                    .Select(m => new
                    {
                        m.Id,
                        m.Name,
                        m.Phone,
                        IdentityCard = m.IdentityCard,
                        m.Relationship,
                        m.CreatedAt
                    })
                    .ToListAsync();

                return Ok(members);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách người ở cùng", error = ex.Message });
            }
        }

        // 2. POST: /api/OwnerContracts/{contractId}/members (Thêm người ở cùng)
        [HttpPost("{contractId}/members")]
        public async Task<IActionResult> AddContractMember(string contractId, [FromBody] ContractMemberItemDto req)
        {
            try
            {
                var contract = await _context.Contracts.FindAsync(contractId);
                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                if (contract.Status == "terminated" || contract.Status == "Đã thanh lý")
                {
                    return BadRequest(new { message = "Không thể thêm người ở ghép cho hợp đồng đã thanh lý!" });
                }

                if (string.IsNullOrWhiteSpace(req.FullName))
                {
                    return BadRequest(new { message = "Vui lòng nhập họ tên người ở cùng." });
                }

                if (!string.IsNullOrWhiteSpace(req.Phone))
                {
                    string phoneVal = req.Phone.Trim();
                    bool isPhoneExist = await _context.Users.AnyAsync(u => u.Phone == phoneVal) ||
                                        await _context.ContractMembers.AnyAsync(m => m.Phone == phoneVal);
                    if (isPhoneExist)
                    {
                        return BadRequest(new { message = $"Số điện thoại {phoneVal} đã được đăng ký/sử dụng trên hệ thống!" });
                    }
                }

                if (!string.IsNullOrWhiteSpace(req.Cccd))
                {
                    string cccdVal = req.Cccd.Trim();
                    bool isCccdExist = await _context.ContractMembers.AnyAsync(m => m.IdentityCard == cccdVal) ||
                                       await _context.Contracts.AnyAsync(c => c.Terms != null && c.Terms.Contains(cccdVal));
                    if (isCccdExist)
                    {
                        return BadRequest(new { message = $"Số CCCD {cccdVal} đã được đăng ký/sử dụng trên hệ thống!" });
                    }
                }

                var member = new Backend.Models.ContractMember
                {
                    Id = "mem_" + Guid.NewGuid().ToString("N")[..8],
                    ContractId = contractId,
                    Name = req.FullName,
                    IdentityCard = req.Cccd ?? "",
                    Phone = req.Phone,
                    Relationship = string.IsNullOrWhiteSpace(req.Relationship) ? "Ở chung" : req.Relationship,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.ContractMembers.Add(member);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm thành viên thành công!", memberId = member.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi thêm người ở cùng", error = ex.Message });
            }
        }

        // 3. DELETE: /api/OwnerContracts/members/{memberId} (Xóa người ở cùng)
        [HttpDelete("members/{memberId}")]
        public async Task<IActionResult> DeleteContractMember(string memberId)
        {
            try
            {
                var member = await _context.ContractMembers.FindAsync(memberId);
                if (member == null)
                {
                    return NotFound(new { message = "Không tìm thấy thành viên." });
                }

                _context.ContractMembers.Remove(member);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã xóa thành viên khỏi hợp đồng." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa thành viên", error = ex.Message });
            }
        }

        // GET: /api/OwnerContracts/{contractId}/liquidation-details
        [HttpGet("{contractId}/liquidation-details")]
        public async Task<IActionResult> GetLiquidationDetails(string contractId)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                            .ThenInclude(p => p.Owner)
                    .Include(c => c.Tenant)
                    .FirstOrDefaultAsync(c => c.Id == contractId || c.ContractCode == contractId);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                var lastUtility = await _context.UtilityReadings
                    .Where(u => u.RoomId == contract.RoomId)
                    .OrderByDescending(u => u.Month)
                    .ThenByDescending(u => u.CreatedAt)
                    .FirstOrDefaultAsync();

                decimal oldElectric = lastUtility != null ? lastUtility.ElectricityNew : contract.InitialElectricityReading;
                decimal newElectric = lastUtility != null ? lastUtility.ElectricityNew : contract.InitialElectricityReading;

                decimal oldWater = lastUtility != null ? lastUtility.WaterNew : contract.InitialWaterReading;
                decimal newWater = lastUtility != null ? lastUtility.WaterNew : contract.InitialWaterReading;

                decimal elecUnitPrice = lastUtility?.ElectricityPrice ?? 3800m;
                decimal waterUnitPrice = lastUtility?.WaterPrice ?? 25000m;

                decimal elecUsage = Math.Max(0, newElectric - oldElectric);
                decimal waterUsage = Math.Max(0, newWater - oldWater);

                decimal elecCost = elecUsage * elecUnitPrice;
                decimal waterCost = waterUsage * waterUnitPrice;
                decimal utilityTotal = elecCost + waterCost;

                return Ok(new
                {
                    contractId = contract.Id,
                    contractCode = contract.ContractCode,
                    roomName = contract.Room?.Name ?? "Phòng",
                    propertyName = contract.Room?.Property?.Name ?? "Khu trọ",
                    tenantName = contract.Tenant?.Name ?? "Khách thuê",
                    ownerName = contract.Room?.Property?.Owner?.Name ?? "Trần Thanh Trúc",
                    tenantPhone = contract.Tenant?.Phone ?? "Chưa có SĐT",
                    startDate = contract.StartDate.ToString("dd/MM/yyyy"),
                    endDate = contract.EndDate.ToString("dd/MM/yyyy"),
                    deposit = contract.Deposit,
                    elecOld = oldElectric,
                    elecNew = newElectric,
                    elecPrice = elecUnitPrice,
                    elecUsage = elecUsage,
                    elecCost = elecCost,
                    waterOld = oldWater,
                    waterNew = newWater,
                    waterPrice = waterUnitPrice,
                    waterUsage = waterUsage,
                    waterCost = waterCost,
                    utilityTotal = utilityTotal,
                    refundAmount = Math.Max(0, contract.Deposit - utilityTotal),
                    bankName = "Techcombank",
                    bankAccount = "190334888291",
                    accountHolder = contract.Tenant?.Name?.ToUpper() ?? "KHÁCH THUÊ"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu thanh lý", error = ex.Message });
            }
        }

        [HttpGet("bank-accounts")]
        [Authorize(Roles = "owner,landlord")]
        public async Task<IActionResult> GetBankAccounts()
        {
            var ownerId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrWhiteSpace(ownerId)) return Unauthorized();

            try
            {
                var banks = await _context.BankAccounts
                    .Where(b => b.UserId == ownerId && b.Status == "active")
                    .Select(b => new
                    {
                        id = b.Id,
                        bankCode = b.BankCode,
                        bankName = b.BankName,
                        accountNumber = b.AccountNumber,
                        accountHolder = b.AccountHolder,
                        isDefault = b.IsDefault
                    })
                    .ToListAsync();

                return Ok(banks);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách tài khoản ngân hàng", error = ex.Message });
            }
        }
        // GET: /api/OwnerContracts/tenants/{ownerId}
        // (Lấy danh sách người thuê nhà đang có hợp đồng active thuộc về chủ nhà)
        [HttpGet("tenants/{ownerId}")]
        public async Task<IActionResult> GetTenantsByOwner(string ownerId)
        {
            try
            {
                var tenants = await _context.Contracts
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                    .Include(c => c.Tenant)
                    .Where(c => c.OwnerId == ownerId && c.Status == "active")
                    .OrderByDescending(c => c.StartDate)
                    .Select(c => new
                    {
                        contractId = c.Id,
                        tenantId = c.TenantId,
                        name = c.Tenant.Name,
                        phone = c.Tenant.Phone ?? "",
                        avatar = c.Tenant.Avatar ?? "", // Nếu có avatar trên DB, có thể trả về
                        room = c.Room.Name ?? "Phòng",
                        property = c.Room.Property.Name ?? "Khu trọ",
                        date = c.StartDate.ToString("dd/MM/yyyy")
                    })
                    .ToListAsync();

                return Ok(tenants);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách người thuê", error = ex.Message });
            }
        }
        // GET: /api/OwnerContracts/tenant-detail/{contractId}
        [HttpGet("tenant-detail/{contractId}")]
        public async Task<IActionResult> GetTenantDetailByContract(string contractId)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.Tenant)
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                    .Include(c => c.ContractMembers)
                    .FirstOrDefaultAsync(c => c.Id == contractId);

                if (contract == null) return NotFound(new { message = "Không tìm thấy thông tin người thuê." });

                return Ok(new
                {
                    contractId = contract.Id,
                    contractCode = contract.ContractCode,
                    tenantName = contract.Tenant.Name,
                    tenantPhone = contract.Tenant.Phone ?? "Chưa cập nhật",
                    tenantEmail = contract.Tenant.Email,
                    tenantAvatar = contract.Tenant.Avatar,
                    roomName = contract.Room.Name,
                    propertyName = contract.Room.Property.Name,
                    address = contract.Room.Property.Address,
                    startDate = contract.StartDate.ToString("dd/MM/yyyy"),
                    endDate = contract.EndDate.ToString("dd/MM/yyyy"),
                    rent = contract.Rent,
                    deposit = contract.Deposit,
                    paymentCycle = contract.PaymentCycle == "monthly" ? "Hàng tháng" : "Hàng quý",
                    members = contract.ContractMembers.Select(m => new {
                        name = m.Name,
                        phone = m.Phone,
                        identityCard = m.IdentityCard,
                        relationship = m.Relationship
                    }).ToList()
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lấy chi tiết người thuê", error = ex.Message });
            }
        }


         // POST: /api/OwnerContracts/{id}/terminate (Xác nhận Hoàn cọc & Thanh lý hợp đồng)
         [HttpPost("{id}/terminate")]
         public async Task<IActionResult> TerminateContract(string id)
         {
                try
                {
                    var contract = await _context.Contracts
                        .Include(c => c.Room)
                        .FirstOrDefaultAsync(c => c.Id == id || c.ContractCode == id);

                    if (contract == null)
                    {
                        return NotFound(new { message = "Không tìm thấy hợp đồng." });
                    }


                    if (contract.Status != "active")
                        return Conflict(new { message = "Chỉ có thể thanh lý hợp đồng đang hiệu lực." });
                    contract.Status = "terminated";
                    contract.TerminatedAt = DateTime.UtcNow;
                    contract.UpdatedAt = DateTime.UtcNow;


                    if (contract.Room != null)
                    {
                        contract.Room.Status = "available";
                        contract.Room.UpdatedAt = DateTime.UtcNow;
                    }

                     if (!string.IsNullOrEmpty(contract.TenantId))
                     {
                                var terminationNotif = new Notification
                                {
                                    Id = "notif_" + Guid.NewGuid().ToString("N")[..8],
                                    UserId = contract.TenantId,
                                    Title = "Hợp đồng thuê phòng đã được thanh lý 🤝",
                                    Message = $"Chủ trọ đã xác nhận hoàn cọc và hoàn tất thanh lý hợp đồng {contract.ContractCode} (Phòng {contract.Room?.Name}). Cảm ơn bạn đã lưu trú!",
                                    Type = "contract_terminated",
                                    ReferenceId = contract.Id,
                                    ReferenceType = "contract",
                                    CreatedAt = DateTime.UtcNow,
                                    UpdatedAt = DateTime.UtcNow
                                };
                                _context.Notifications.Add(terminationNotif);
                     }

                    await _context.SaveChangesAsync();

                    return Ok(new { message = "Thanh lý hợp đồng thành công!" });
                }
                catch (Exception ex)
                {
                    return StatusCode(500, new { message = "Lỗi khi thanh lý hợp đồng", error = ex.Message });
                }
         }

        private static string RemoveAccents(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return "";
            var normalized = text.Normalize(System.Text.NormalizationForm.FormD);
            var sb = new System.Text.StringBuilder();
            foreach (var c in normalized)
            {
                var unicodeCategory = System.Globalization.CharUnicodeInfo.GetUnicodeCategory(c);
                if (unicodeCategory != System.Globalization.UnicodeCategory.NonSpacingMark)
                {
                    sb.Append(c);
                }
            }
            return sb.ToString().Normalize(System.Text.NormalizationForm.FormC).ToLower().Trim();
        }
    }
}
