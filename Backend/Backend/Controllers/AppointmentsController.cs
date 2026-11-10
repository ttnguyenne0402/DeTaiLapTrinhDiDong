using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/appointments")]
    [ApiController]
    public class AppointmentsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public AppointmentsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/appointments/{ownerId}?status=all
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetAppointments(string ownerId, [FromQuery] string? status)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                // Lấy ID tất cả phòng thuộc các bất động sản của chủ trọ này
                var roomIds = await (from p in _context.Properties
                                     join r in _context.Rooms on p.Id equals r.PropertyId
                                     where targetOwnerIds.Contains(p.OwnerId)
                                     select r.Id).ToListAsync();

                if (!roomIds.Any())
                {
                    return Ok(new List<OwnerAppointmentDto>());
                }

                var query = _context.ViewingAppointments
                    .Include(v => v.Room)
                        .ThenInclude(r => r.Property)
                    .Include(v => v.Tenant)
                    .Where(v => roomIds.Contains(v.RoomId));

                // Lọc theo tab trạng thái (bỏ qua nếu status là "status" hoặc "all")
                if (!OwnerHelper.IsPlaceholder(status, "status"))
                {
                    string s = status!.Trim().ToLower();
                    if (s == "upcoming")
                    {
                        query = query.Where(v => v.Status == "pending" || v.Status == "confirmed");
                    }
                    else if (s == "completed")
                    {
                        query = query.Where(v => v.Status == "completed");
                    }
                    else if (s == "cancelled")
                    {
                        query = query.Where(v => v.Status == "cancelled" || v.Status == "rejected");
                    }
                    else
                    {
                        query = query.Where(v => v.Status == s);
                    }
                }

                var rawList = await query
                    .OrderByDescending(v => v.AppointmentDate)
                    .ThenByDescending(v => v.AppointmentTime)
                    .ToListAsync();

                var today = DateOnly.FromDateTime(DateTime.Today);
                var tomorrow = today.AddDays(1);

                var result = rawList.Select(v =>
                {
                    string dateStr = v.AppointmentDate.ToString("dd/MM/yyyy");
                    // TimeOnly dùng "HH" để hiển thị giờ dạng 24h, "hh" sẽ bị đổi về 12h (16:00 thành 04:00)
                    string timeFormatted = v.AppointmentTime.ToString("HH:mm");
                    string displayTime = $"{timeFormatted} - {dateStr}";

                    if (v.AppointmentDate == today)
                    {
                        displayTime = $"{timeFormatted} - Hôm nay";
                    }
                    else if (v.AppointmentDate == tomorrow)
                    {
                        displayTime = $"{timeFormatted} - Ngày mai";
                    }

                    string tenantName = v.Tenant?.Name ?? "Khách liên hệ";
                    string roomName = v.Room?.Name ?? "Chưa rõ";
                    string propName = v.Room?.Property?.Name ?? "";
                    string roomInfo = string.IsNullOrEmpty(propName) ? $"Phòng {roomName}" : $"Phòng {roomName} - {propName}";

                    return new OwnerAppointmentDto
                    {
                        Id = v.Id,
                        TenantId = v.TenantId,
                        Name = tenantName,
                        Phone = v.Phone,
                        RoomId = v.RoomId,
                        RoomInfo = roomInfo,
                        Time = displayTime,
                        Date = dateStr,
                        Status = v.Status,
                        Note = !string.IsNullOrEmpty(v.OwnerNote) ? v.OwnerNote : v.Message,
                        Avatar = string.IsNullOrEmpty(v.Tenant?.Avatar) ? "frontend/assets/images/avatarDemo.jpg" : v.Tenant.Avatar
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách lịch hẹn", error });
            }
        }

        // 2. PUT: api/owner/appointments/{id}/status (Xác nhận, hoàn thành hoặc hủy lịch)
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateAppointmentStatusDto dto)
        {
            try
            {
                var appointment = await _context.ViewingAppointments
                    .FirstOrDefaultAsync(v => v.Id == id || v.Id.ToLower() == id.ToLower());

                if (appointment == null)
                {
                    return NotFound(new { message = "Không tìm thấy lịch hẹn." });
                }

                string input = (dto.Status ?? "").Trim().ToLower();
                string newStatus = input;
                if (input.Contains("complete") || input.Contains("xong") || input.Contains("thành"))
                {
                    newStatus = "completed";
                }
                else if (input.Contains("từ chối") || input.Contains("reject"))
                {
                    newStatus = "rejected";
                }
                else if (input.Contains("cancel") || input.Contains("hủy"))
                {
                    newStatus = "cancelled";
                }
                else if (input.Contains("confirm") || input.Contains("xác nhận"))
                {
                    newStatus = "confirmed";
                }

                appointment.Status = newStatus;
                if (!string.IsNullOrEmpty(dto.OwnerNote))
                {
                    appointment.OwnerNote = dto.OwnerNote;
                }

                // Dùng giờ máy chủ để khớp với giá trị mặc định GETDATE() trong SQL Server
                var now = DateTime.Now;
                appointment.UpdatedAt = now;

                if (newStatus == "confirmed")
                {
                    appointment.ConfirmedAt = now;
                }
                else if (newStatus == "completed")
                {
                    appointment.CompletedAt = now;
                }
                else if (newStatus == "cancelled" || newStatus == "rejected")
                {
                    appointment.CancelledAt = now;
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Cập nhật trạng thái lịch hẹn thành công", status = newStatus });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật lịch hẹn", error = ex.Message });
            }
        }
    }
}
