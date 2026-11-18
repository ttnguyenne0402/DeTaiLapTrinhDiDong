using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Threading.Tasks;
namespace Backend.Controllers
{
    [ApiController]
    [Route("api/maintenance")]
    public class MaintenanceRequestsController : ControllerBase
    {
        private readonly IMaintenanceService _service;

        public MaintenanceRequestsController(IMaintenanceService service)
        {
            _service = service;
        }

        [HttpPost]
        public async Task<IActionResult> CreateRequest(
            [FromBody] MaintenanceRequestDTO request,
            [FromServices] QuanLyPhongTroContext _context)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // 1. KIỂM TRA & TỰ ĐỘNG ĐỒNG BỘ MÃ PHÒNG TỪ HỢP ĐỒNG ĐANG HIỆU LỰC
            bool roomExists = await _context.Rooms.AnyAsync(r => r.Id == request.RoomId);
            if (!roomExists)
            {
                var activeContract = await _context.Contracts
                    .Where(c => c.TenantId == request.TenantId && c.Status == "active")
                    .OrderByDescending(c => c.CreatedAt)
                    .FirstOrDefaultAsync();

                if (activeContract != null)
                {
                    request.RoomId = activeContract.RoomId; 
                }
                else
                {
                    return BadRequest(new { message = "Không tìm thấy phòng hợp lệ hoặc hợp đồng đang hiệu lực." });
                }
            }

            // 2. LƯU YÊU CẦU SỬA CHỮA
            var result = await _service.CreateRequestAsync(request);

           
            // 3. TẠO THÔNG BÁO GỬI CHO CHỦ NHÀ VÀ NGƯỜI THUÊ
            try
            {
                var roomDetails = await _context.Rooms
                    .Include(r => r.Property)
                    .FirstOrDefaultAsync(r => r.Id == request.RoomId);

                var tenant = await _context.Users.FirstOrDefaultAsync(u => u.Id == request.TenantId);

                if (roomDetails != null)
                {
                    var tenantName = tenant?.Name ?? "Khách thuê";
                    var roomName = roomDetails.Name ?? "Phòng";

                    // A. THÔNG BÁO CHO CHỦ TRỌ
                    if (roomDetails.Property != null && !string.IsNullOrEmpty(roomDetails.Property.OwnerId))
                    {
                        var priorityText = request.Priority switch
                        {
                            "urgent" => "Khẩn cấp",
                            "high" => "Cao",
                            "medium" => "Bình thường",
                            "low" => "Thấp",
                            _ => "Bình thường"
                        };

                        _context.Notifications.Add(new Notification
                        {
                            Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                            UserId = roomDetails.Property.OwnerId,
                            Title = "Khách thuê báo sự cố mới!",
                            Message = $"{tenantName} ({roomName}) vừa báo sự cố: {request.Title}. Mức độ: {priorityText}.",
                            Type = "maintenance",
                            ReferenceId = result.Id,
                            ReferenceType = "maintenance",
                            CreatedAt = DateTime.Now,
                            UpdatedAt = DateTime.Now
                        });
                    }

                    // B. THÔNG BÁO XÁC NHẬN CHO CHÍNH NGƯỜI THUÊ (THÊM MỚI)
                    _context.Notifications.Add(new Notification
                    {
                        Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                        UserId = request.TenantId,
                        Title = "Gửi yêu cầu thành công",
                        Message = $"Yêu cầu sửa chữa '{request.Title}' tại {roomName} đã được gửi. Vui lòng chờ chủ trọ tiếp nhận.",
                        Type = "maintenance",
                        ReferenceId = result.Id,
                        ReferenceType = "maintenance",
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    });

                    await _context.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Lỗi tạo thông báo sửa chữa: {ex.Message}");
            }

            return CreatedAtAction(nameof(GetTenantRequests), new { tenantId = request.TenantId }, result);
        }

        // GET: api/maintenance/tenant/{tenantId}
        [HttpGet("tenant/{tenantId}")]
        public async Task<IActionResult> GetTenantRequests(string tenantId, [FromServices] QuanLyPhongTroContext _context)
        {
            // Bỏ qua DTO, truy vấn trực tiếp Entity để lấy TOÀN BỘ dữ liệu bao gồm cả OwnerNote và CompletedAt
            var requests = await _context.MaintenanceRequests
                .Where(m => m.TenantId == tenantId)
                .OrderByDescending(m => m.CreatedAt)
                .Select(r => new
                {
                    r.Id,
                    r.Title,
                    r.Description,
                    r.Priority,
                    r.Status,
                    r.OwnerNote,
                    CreatedAt = r.CreatedAt.HasValue ? r.CreatedAt.Value.ToString("dd/MM/yyyy HH:mm") : "",
                    CompletedAt = r.CompletedAt.HasValue ? r.CompletedAt.Value.ToString("dd/MM/yyyy HH:mm") : ""
                })
                .ToListAsync();

            return Ok(requests);
        }
        //  
        [HttpDelete("{id}/cancel")]
        public async Task<IActionResult> CancelRequest(string id, [FromServices] QuanLyPhongTroContext _context)
        {
            var request = await _context.MaintenanceRequests.FirstOrDefaultAsync(m => m.Id == id);

            if (request == null)
            {
                return NotFound(new { message = "Không tìm thấy yêu cầu sửa chữa." });
            }

            string currentStatus = string.IsNullOrWhiteSpace(request.Status) ? "" : request.Status.Trim().ToLower();

            if (currentStatus != "pending")
            {
                return BadRequest(new { message = "Không thể hủy vì chủ trọ đã tiếp nhận xử lý yêu cầu này." });
            }

            
            request.Status = "rejected";
            request.UpdatedAt = DateTime.Now;

            string title = request.Title;
            string tenantId = request.TenantId;

            _context.Notifications.Add(new Notification
            {
                Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                UserId = tenantId,
                Title = "Đã hủy yêu cầu sửa chữa",
                Message = $"Bạn đã tự hủy yêu cầu sửa chữa '{title}'.",
                Type = "maintenance",
                ReferenceId = id,
                ReferenceType = "maintenance",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            });

            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã hủy yêu cầu sửa chữa thành công." });
        }
    }
}