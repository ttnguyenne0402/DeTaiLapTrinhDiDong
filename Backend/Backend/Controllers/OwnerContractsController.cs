using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend.Helpers;

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
        public async Task<IActionResult> GetContracts( [FromRoute] string? ownerId,[FromQuery] string? status, [FromQuery] string? search, [FromQuery(Name = "ownerId")] string? ownerIdQuery = null)
        {
            try
            {
                  string? targetOwner = !string.IsNullOrEmpty(ownerId)
                             ? ownerId
                             : ownerIdQuery;

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
                    else if (c.SignedAt == null && c.Status != "active")
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
        public async Task<IActionResult> CreateContract([FromBody] CreateContractRequest req)
        {
            try
            {
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

                // 3. Lấy thông tin phòng trọ và Bất động sản
                var roomId = req.RoomId;
                Room? room = null;

                if (!string.IsNullOrEmpty(roomId))
                {
                    room = await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync(r => r.Id == roomId);
                }

                if (room == null)
                {
                    room = await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync(r => r.Status == "available")
                           ?? await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync();
                }

                if (room == null || room.Property == null)
                {
                    return BadRequest(new { message = "Không tìm thấy phòng trọ phù hợp để tạo hợp đồng." });
                }

                // 4. Xử lý mã Lịch hẹn (BỎ CHUỖI "walkin" ĐỂ TRÁNH LỖI KHÓA NGOẠI SQL)
                string? validAppointmentId = null;
                if (!string.IsNullOrEmpty(req.ViewingAppointmentId) && req.ViewingAppointmentId != "walkin")
                {
                    var aptExists = await _context.ViewingAppointments.AnyAsync(a => a.Id == req.ViewingAppointmentId);
                    if (aptExists)
                    {
                        validAppointmentId = req.ViewingAppointmentId;
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
                    Status = (req.Status == "Chờ ký" || req.Status == "pending") ? "pending" : "draft",
                    Terms = $"CCCD:{req.Cccd}|IssueDate:{req.IssueDate}|IssuePlace:{req.IssuePlace}",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

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
            public async Task<IActionResult> SignContract(string id, [FromBody] SignContractRequest req)
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

                    // 1. Chỉ cập nhật chữ ký nào có gửi lên (Không đè rỗng lên chữ ký cũ)
                    if (!string.IsNullOrWhiteSpace(req.OwnerSignature))
                    {
                        contract.OwnerSignature = req.OwnerSignature;
                    }

                    if (!string.IsNullOrWhiteSpace(req.TenantSignature))
                    {
                        contract.TenantSignature = req.TenantSignature;
                    }

                    // 🔴 2. KIỂM TRA PHÁP LÝ: CHỈ KÍCH HOẠT 'active' KHI CẢ CHỦ TRỌ VÀ NGƯỜI THUÊ ĐÃ KÝ ĐỦ
                    bool isBothSigned = !string.IsNullOrWhiteSpace(contract.OwnerSignature) &&
                                       !string.IsNullOrWhiteSpace(contract.TenantSignature);

                    if (isBothSigned)
                    {
                        contract.Status = "active"; // Đã ký đủ 2 bên -> Đang hiệu lực
                        contract.SignedAt = DateTime.UtcNow;

                        if (contract.Room != null)
                        {
                            contract.Room.Status = "rented"; // Chuyển phòng sang Đã thuê
                            contract.Room.UpdatedAt = DateTime.UtcNow;
                        }
                    }
                    else
                    {
                        contract.Status = "pending"; // Mới 1 bên ký -> Vẫn ở trạng thái Chờ ký!
                    }

                    contract.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();

                    return Ok(new
                    {
                        message = isBothSigned
                            ? "Hợp đồng đã ký đủ 2 bên và chính thức có hiệu lực!"
                            : "Đã lưu chữ ký, đang chờ bên còn lại ký xác nhận.",
                        status = contract.Status,
                        isBothSigned = isBothSigned
                    });
                }
                catch (Exception ex)
                {
                    string errorMsg = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                    return StatusCode(500, new { message = "Lỗi khi ký hợp đồng", error = errorMsg });
                }
            }




       // GET: /api/OwnerContracts/available-rooms?ownerId=... (Lấy danh sách phòng trống theo Chủ trọ)
           [HttpGet("available-rooms")]
           public async Task<IActionResult> GetAvailableRooms([FromQuery] string? ownerId)
           {
               try
               {
                   var query = _context.Rooms
                       .Include(r => r.Property)
                       .Where(r => r.Status == "available");


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

                // 1. Dịch vụ đã cài đặt cho khu trọ này (kèm giá niêm yết từ tin đăng/cơ sở)
                var propertyServices = await _context.PropertyServices
                    .Include(ps => ps.Service)
                    .Where(ps => ps.PropertyId == room.PropertyId && ps.Status == "active")
                    .Select(ps => new
                    {
                        serviceId = ps.ServiceId,
                        name = ps.Service.Name,
                        unit = ps.Service.Unit,
                        price = ps.Price,
                        isDefault = true // Mặc định tự chọn
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

                if (string.IsNullOrWhiteSpace(req.FullName))
                {
                    return BadRequest(new { message = "Vui lòng nhập họ tên người ở cùng." });
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
        public async Task<IActionResult> GetBankAccounts()
        {
            try
            {
                var banks = await _context.BankAccounts
                    .Where(b => b.Status == "active")
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


    }
}