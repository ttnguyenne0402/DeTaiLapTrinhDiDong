using System;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OwnerMaintenanceController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerMaintenanceController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/OwnerMaintenance/owner/{ownerId} 
        // (Lấy danh sách tất cả yêu cầu sửa chữa thuộc các khu trọ của Chủ nhà)
        [HttpGet("owner/{ownerId}")]
        public async Task<IActionResult> GetRequestsByOwner(string ownerId)
        {
            try
            {
                var requests = await _context.MaintenanceRequests
                    .Include(m => m.Room)
                        .ThenInclude(r => r.Property)
                    .Include(m => m.Tenant)
                    .Where(m => m.Room.Property.OwnerId == ownerId)
                    .OrderByDescending(m => m.CreatedAt)
                    .Select(m => new
                    {
                        id = m.Id,
                        title = m.Title,
                        description = m.Description,
                        priority = m.Priority,
                        status = m.Status,
                        createdAt = m.CreatedAt,
                        roomName = m.Room.Name ?? "Phòng",
                        propertyName = m.Room.Property.Name ?? "Khu trọ",
                        tenantName = m.Tenant.Name ?? "Khách thuê",
                        tenantPhone = m.Tenant.Phone ?? "",
                        image = m.Image
                    })
                    .ToListAsync();

                return Ok(requests);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp danh sách sự cố", error = ex.Message });
            }
        }

        // 2. GET: api/OwnerMaintenance/{id}
        // (Lấy chi tiết 1 yêu cầu sửa chữa)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetRequestDetail(string id)
        {
            try
            {
                var request = await _context.MaintenanceRequests
                    .Include(m => m.Room)
                        .ThenInclude(r => r.Property)
                    .Include(m => m.Tenant)
                    .FirstOrDefaultAsync(m => m.Id == id);

                if (request == null) return NotFound(new { message = "Không tìm thấy sự cố." });

                return Ok(new
                {
                    id = request.Id,
                    title = request.Title,
                    description = request.Description,
                    priority = request.Priority,
                    status = request.Status,
                    image = request.Image,
                    ownerNote = request.OwnerNote,
                    createdAt = request.CreatedAt,
                    completedAt = request.CompletedAt,
                    roomName = request.Room?.Name,
                    propertyName = request.Room?.Property?.Name,
                    tenantName = request.Tenant?.Name,
                    tenantPhone = request.Tenant?.Phone
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lấy chi tiết sự cố", error = ex.Message });
            }
        }

        // 3. PUT: api/OwnerMaintenance/{id}/process
        // (Chủ nhà bấm "Tiếp nhận" hoặc "Nghiệm thu & Đóng")
        [HttpPut("{id}/process")]
        public async Task<IActionResult> ProcessRequest(string id, [FromBody] ProcessMaintenanceDto req)
        {
            try
            {
                // Thêm Include Room để lấy tên phòng ghép vào thông báo
                var request = await _context.MaintenanceRequests
                    .Include(m => m.Room)
                    .FirstOrDefaultAsync(m => m.Id == id);

                if (request == null) return NotFound(new { message = "Không tìm thấy sự cố." });

                // Cập nhật trạng thái
                request.Status = req.Status;

                // Nếu chủ nhà có ghi chú chi phí, phân bổ thì lưu vào đây
                if (!string.IsNullOrEmpty(req.OwnerNote))
                {
                    request.OwnerNote = req.OwnerNote;
                }

                // Nếu đổi trạng thái thành hoàn thành thì lưu thời gian lại
                if (req.Status == "completed")
                {
                    request.CompletedAt = DateTime.UtcNow;
                }

                request.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // BẮT ĐẦU CHÈN CODE TẠO THÔNG BÁO CHO NGƯỜI THUÊ
                try
                {
                    string title = "";
                    string message = "";
                    string roomName = request.Room?.Name ?? "phòng của bạn";

                    if (req.Status == "processing")
                    {
                        title = "Yêu cầu sửa chữa đang được xử lý";
                        message = $"Chủ trọ đã tiếp nhận và đang xử lý sự cố '{request.Title}' tại {roomName}.";
                    }
                    else if (req.Status == "completed")
                    {
                        title = "Yêu cầu sửa chữa đã hoàn tất";
                        message = $"Sự cố '{request.Title}' tại {roomName} đã được khắc phục xong.";
                        if (!string.IsNullOrEmpty(req.OwnerNote))
                        {
                            message += $" Ghi chú từ chủ trọ: {req.OwnerNote}";
                        }
                    }
                    else if (req.Status == "rejected")
                    {
                        title = "Yêu cầu sửa chữa bị từ chối";
                        message = $"Chủ trọ đã từ chối yêu cầu sửa chữa '{request.Title}'.";
                        if (!string.IsNullOrEmpty(req.OwnerNote))
                        {
                            message += $" Lý do: {req.OwnerNote}";
                        }
                    }

                    if (!string.IsNullOrEmpty(title))
                    {
                        var notif = new Notification
                        {
                            Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                            UserId = request.TenantId, // Gửi cho NGƯỜI THUÊ
                            Title = title,
                            Message = message,
                            Type = "maintenance",
                            ReferenceId = request.Id,
                            ReferenceType = "maintenance",
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _context.Notifications.Add(notif);
                        await _context.SaveChangesAsync();
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Lỗi tạo thông báo sửa chữa cho khách thuê: {ex.Message}");
                }
                // KẾT THÚC CHÈN CODE

                return Ok(new { message = "Đã cập nhật trạng thái sự cố thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi xử lý sự cố", error = ex.Message });
            }
        }
        // 4. POST: api/OwnerMaintenance/owner/{ownerId}
        // (Chủ nhà tự báo cáo sự cố mới)
        [HttpPost("owner/{ownerId}")]
        public async Task<IActionResult> CreateRequestByOwner(string ownerId, [FromBody] CreateMaintenanceByOwnerDto req)
        {
            try
            {
                // 1. Kiểm tra phòng có tồn tại không
                var room = await _context.Rooms.Include(r => r.Property).FirstOrDefaultAsync(r => r.Id == req.RoomId);
                if (room == null) return BadRequest(new { message = "Không tìm thấy phòng." });

                // 2. Xử lý logic Database: Cột tenant_id bắt buộc NOT NULL.
                // Ta sẽ tìm người thuê đang active của phòng này. Nếu phòng trống, gán tạm ID của chủ nhà.
                var activeContract = await _context.Contracts
                    .FirstOrDefaultAsync(c => c.RoomId == req.RoomId && c.Status == "active");
                string tenantId = activeContract != null ? activeContract.TenantId : ownerId;

                // 3. Khởi tạo sự cố mới
                var newRequest = new MaintenanceRequest
                {
                    Id = "MAINT_" + Guid.NewGuid().ToString("N").Substring(0, 6).ToUpper(),
                    RoomId = req.RoomId,
                    TenantId = tenantId,
                    Title = req.Title,
                    Description = req.Description ?? "",
                    Priority = "medium", // Chủ nhà tự tạo mặc định là mức "Vừa"
                    Status = "processing", // Bỏ qua "Chờ tiếp nhận", gán thẳng Đang xử lý
                    Image = req.ImageBase64, // Cột VARCHAR(MAX) lưu chuỗi Base64
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.MaintenanceRequests.Add(newRequest);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã tạo sự cố thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi tạo sự cố", error = ex.InnerException?.Message ?? ex.Message });
            }
        }
        // 5. GET: api/OwnerMaintenance/owner/{ownerId}/properties-rooms
        // (Lấy danh sách Khu trọ và Phòng của chủ nhà để đổ vào Dropdown lúc tạo sự cố)
        [HttpGet("owner/{ownerId}/properties-rooms")]
        public async Task<IActionResult> GetPropertiesAndRooms(string ownerId)
        {
            try
            {
                var properties = await _context.Properties
                    .Where(p => p.OwnerId == ownerId && p.Status == "active")
                    .Select(p => new
                    {
                        propertyId = p.Id,
                        propertyName = p.Name,
                        rooms = _context.Rooms
                            .Where(r => r.PropertyId == p.Id && r.Status != "hidden")
                            .Select(r => new
                            {
                                roomId = r.Id,
                                roomName = r.Name
                            }).ToList()
                    })
                    .ToListAsync();

                return Ok(properties);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp danh sách phòng", error = ex.Message });
            }
        }
    }
}