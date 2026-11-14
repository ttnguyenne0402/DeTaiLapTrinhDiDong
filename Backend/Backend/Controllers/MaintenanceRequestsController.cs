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

            // 3. TẠO THÔNG BÁO GỬI CHO CHỦ NHÀ
            try
            {
                var roomDetails = await _context.Rooms
                    .Include(r => r.Property)
                    .FirstOrDefaultAsync(r => r.Id == request.RoomId);

                var tenant = await _context.Users.FirstOrDefaultAsync(u => u.Id == request.TenantId);

                if (roomDetails?.Property != null && !string.IsNullOrEmpty(roomDetails.Property.OwnerId))
                {
                    var priorityText = request.Priority switch
                    {
                        "urgent" => "Khẩn cấp",
                        "high" => "Cao",
                        "medium" => "Bình thường",
                        "low" => "Thấp",
                        _ => "Bình thường"
                    };

                    var tenantName = tenant?.Name ?? "Khách thuê";

                    _context.Notifications.Add(new Notification
                    {
                        Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                        UserId = roomDetails.Property.OwnerId,
                        Title = "Khách thuê báo sự cố mới!",
                        Message = $"{tenantName} ({roomDetails.Name}) vừa báo sự cố: {request.Title}. Mức độ: {priorityText}.",
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
        public async Task<IActionResult> GetTenantRequests(string tenantId)
        {
            var requests = await _service.GetTenantRequestsAsync(tenantId);
            return Ok(requests);
        }
    }
}