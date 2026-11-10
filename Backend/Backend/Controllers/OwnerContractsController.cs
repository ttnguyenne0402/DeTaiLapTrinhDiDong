using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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
        public async Task<IActionResult> GetContracts([FromQuery] string? status, [FromQuery] string? search)
        {
            try
            {
                var query = _context.Contracts
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                    .Include(c => c.Tenant)
                    .Include(c => c.ContractMembers)
                    .AsQueryable();

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
                // 1. Xử lý khách thuê (khách vãng lai hoặc khách hẹn trước)
                string? tenantId = null;
                if (!string.IsNullOrWhiteSpace(req.TenantPhone))
                {
                    var tenant = await _context.Users.FirstOrDefaultAsync(u => u.Phone == req.TenantPhone);
                    if (tenant == null)
                    {
                        tenant = new User
                        {
                            Id = "usr_" + Guid.NewGuid().ToString("N")[..8],
                            Name = !string.IsNullOrWhiteSpace(req.TenantName) ? req.TenantName : "Khách thuê mới",
                            Phone = req.TenantPhone,
                            Email = $"{req.TenantPhone}@tenant.local",
                            Password = "default_password_123", // Bổ sung mật khẩu mặc định để tránh lỗi NOT NULL
                            Role = "tenant",
                            Status = "active",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.Users.Add(tenant);
                        await _context.SaveChangesAsync();
                    }
                    tenantId = tenant.Id;
                }

                if (string.IsNullOrEmpty(tenantId))
                {
                    return BadRequest(new { message = "Vui lòng cung cấp số điện thoại người thuê." });
                }

                // 2. Phân giải ngày bắt đầu và kết thúc
                DateOnly start = DateOnly.FromDateTime(DateTime.UtcNow);
                DateOnly end = start.AddYears(1);

                if (!string.IsNullOrWhiteSpace(req.StartDate) && DateOnly.TryParse(req.StartDate, out var s))
                    start = s;
                if (!string.IsNullOrWhiteSpace(req.EndDate) && DateOnly.TryParse(req.EndDate, out var e))
                    end = e;

                // 3. Lấy thông tin phòng và chủ sở hữu của phòng
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

                // 4. Khởi tạo hợp đồng mới
                var contract = new Contract
                {
                    Id = "ctr_" + Guid.NewGuid().ToString("N")[..8],
                    ContractCode = $"HD-{DateTime.UtcNow.Year}-P{new Random().Next(100, 999)}",
                    ViewingAppointmentId = req.ViewingAppointmentId, // Lưu mã lịch hẹn nếu có, NULL nếu là khách vãng lai
                    RoomId = room.Id,
                    OwnerId = room.Property.OwnerId, // Gán OwnerId từ khu trọ để tránh lỗi NOT NULL
                    TenantId = tenantId,
                    StartDate = start,
                    EndDate = end,
                    Rent = req.RentPrice > 0 ? req.RentPrice : room.Price,
                    Deposit = req.DepositPrice > 0 ? req.DepositPrice : room.Deposit,
                    PaymentCycle = "monthly",
                    Status = (req.Status == "Chờ ký" || req.Status == "pending") ? "pending" : "draft",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Contracts.Add(contract);

                if (req.Services != null && req.Services.Any())
                {
                    foreach (var srv in req.Services)
                    {
                        if (!string.IsNullOrEmpty(srv.ServiceId))
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

                // Lưu danh sách thành viên ở cùng vào bảng contract_members
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

                // 5. Chỉ đổi sang completed nếu KHÔNG PHẢI là bản nháp
                if (!string.IsNullOrEmpty(req.ViewingAppointmentId) && contract.Status != "draft")
                {
                    var apt = await _context.ViewingAppointments.FindAsync(req.ViewingAppointmentId);
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
                return StatusCode(500, new { message = "Lỗi tạo hợp đồng", error = ex.Message });
            }
        }

        // PUT: /api/OwnerContracts/{id}/sign (Ký hợp đồng và kích hoạt)
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
                
                contract.OwnerSignature = req.OwnerSignature;
                contract.TenantSignature = req.TenantSignature;

                // 2. Cập nhật trạng thái hợp đồng sang active (Đang hiệu lực)
                contract.Status = "active";
                contract.SignedAt = DateTime.UtcNow;
                contract.UpdatedAt = DateTime.UtcNow;

                // 3. Tự động chuyển phòng sang trạng thái đã thuê
                if (contract.Room != null)
                {
                    contract.Room.Status = "rented";
                    contract.Room.UpdatedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Hợp đồng đã ký thành công và có hiệu lực!",
                    contractId = contract.Id,
                    status = "active"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi ký hợp đồng", error = ex.Message });
            }
        }



        // GET: /api/OwnerContracts/available-rooms (Lấy danh sách phòng trống)
        [HttpGet("available-rooms")]
        public async Task<IActionResult> GetAvailableRooms()
        {
            try
            {
                var rooms = await _context.Rooms
                    .Include(r => r.Property)
                    .Where(r => r.Status == "available")
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
                    .Include(c => c.Tenant)
                    .FirstOrDefaultAsync(c => c.Id == contractId || c.ContractCode == contractId);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                // Lấy thông tin chốt điện nước kỳ cuối (nếu có)
                var lastUtility = await _context.UtilityReadings
                    .Where(u => u.RoomId == contract.RoomId)
                    .OrderByDescending(u => u.Month)
                    .FirstOrDefaultAsync();

                decimal elecUsage = lastUtility != null ? Math.Max(0, lastUtility.ElectricityNew - lastUtility.ElectricityOld) : 0;
                decimal waterUsage = lastUtility != null ? Math.Max(0, lastUtility.WaterNew - lastUtility.WaterOld) : 0;

                // Bạn có thể tùy chỉnh đơn giá điện nước cho phù hợp với dự án
                decimal elecCost = elecUsage * 3800m;
                decimal waterCost = waterUsage * 25000m;
                decimal utilityTotal = elecCost + waterCost;

                // Các khoản khấu trừ bàn giao (ví dụ hư hỏng, vệ sinh - có thể điều chỉnh theo logic thực tế)
                decimal deductionItems = 700000m; // VD: 500k vỡ kính + 200k dọn vệ sinh
                decimal refundAmount = contract.Deposit - utilityTotal - deductionItems;

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
                    elecOld = lastUtility?.ElectricityOld ?? 0,
                    elecNew = lastUtility?.ElectricityNew ?? 0,
                    elecUsage = elecUsage,
                    elecCost = elecCost,
                    waterOld = lastUtility?.WaterOld ?? 0,
                    waterNew = lastUtility?.WaterNew ?? 0,
                    waterUsage = waterUsage,
                    waterCost = waterCost,
                    utilityTotal = utilityTotal,
                    deductionTotal = deductionItems,
                    refundAmount = Math.Max(0, refundAmount),
                    bankName = "Techcombank", // Hoặc lấy từ thông tin tenant nếu có
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
    }
}