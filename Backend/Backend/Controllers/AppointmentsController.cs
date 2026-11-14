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
                        query = query.Where(v => v.Status == "pending" || v.Status == "confirmed" || v.Status == "rescheduled");
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
                    string displayRoomName = roomName.StartsWith("Phòng", StringComparison.OrdinalIgnoreCase) ? roomName : $"Phòng {roomName}";
                    string roomInfo = string.IsNullOrEmpty(propName) ? displayRoomName : $"{displayRoomName} - {propName}";

                    return new OwnerAppointmentDto
                    {
                        Id = v.Id,
                        TenantId = v.TenantId,
                        Name = tenantName,
                        Phone = v.Phone,
                        RoomId = v.RoomId,
                        RoomName = roomName,
                        PropertyId = v.Room?.PropertyId ?? "",
                        PropertyName = propName,
                        PropertyAddress = v.Room?.Property?.Address ?? propName,
                        RoomPrice = v.Room?.Price ?? 0,
                        RoomDeposit = v.Room?.Deposit ?? (v.Room?.Price ?? 0),
                        RoomArea = v.Room?.Area ?? 25,
                        RoomInfo = roomInfo,
                        Time = displayTime,
                        RawTime = timeFormatted,
                        Date = dateStr,
                        Status = v.Status,
                        Note = v.Message,
                        OwnerNote = v.OwnerNote,
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

        // 2. PUT: api/owner/appointments/{id}/status (Xác nhận, từ chối, đổi giờ, hoàn thành hoặc hủy lịch)
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateAppointmentStatusDto dto)
        {
            try
            {
                var appointment = await _context.ViewingAppointments
                    .Include(v => v.Room)
                        .ThenInclude(r => r.Property)
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
                else if (input.Contains("reschedul") || input.Contains("đổi giờ") || input.Contains("dời"))
                {
                    newStatus = "rescheduled";
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

                // Nếu chủ trọ đề xuất Đổi giờ (rescheduled), cập nhật ngày và giờ hẹn mới
                if (!string.IsNullOrWhiteSpace(dto.NewDate))
                {
                    if (DateOnly.TryParseExact(dto.NewDate.Trim(), new[] { "yyyy-MM-dd", "dd/MM/yyyy", "d/M/yyyy" }, null, System.Globalization.DateTimeStyles.None, out var parsedDate))
                    {
                        appointment.AppointmentDate = parsedDate;
                    }
                }

                if (!string.IsNullOrWhiteSpace(dto.NewTime))
                {
                    if (TimeOnly.TryParseExact(dto.NewTime.Trim(), new[] { "HH:mm", "H:mm", "HH:mm:ss" }, null, System.Globalization.DateTimeStyles.None, out var parsedTime))
                    {
                        appointment.AppointmentTime = parsedTime;
                    }
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

                // Tự động tạo thông báo gửi về App cho Người thuê (Tenant)
                if (!string.IsNullOrEmpty(appointment.TenantId))
                {
                    string roomTitle = appointment.Room != null
                        ? $"{appointment.Room.Name} ({appointment.Room.Property?.Name})"
                        : appointment.RoomId;
                    string timeStr = $"{appointment.AppointmentTime:HH:mm} ngày {appointment.AppointmentDate:dd/MM/yyyy}";

                    string notifTitle = "Cập nhật lịch hẹn xem phòng";
                    string notifMessage = $"Lịch hẹn xem {roomTitle} đã được cập nhật.";

                    if (newStatus == "confirmed")
                    {
                        notifTitle = "Lịch hẹn xem phòng đã được xác nhận";
                        notifMessage = $"Chủ trọ đã xác nhận lịch hẹn xem {roomTitle} vào lúc {timeStr}.";
                    }
                    else if (newStatus == "rejected")
                    {
                        notifTitle = "Lịch hẹn xem phòng bị từ chối";
                        string reason = !string.IsNullOrWhiteSpace(dto.OwnerNote) ? dto.OwnerNote : "Bận hoặc phòng đã hết";
                        notifMessage = $"Chủ trọ đã từ chối lịch hẹn xem {roomTitle}. Lý do: {reason}.";
                    }
                    else if (newStatus == "rescheduled")
                    {
                        notifTitle = "Chủ trọ đề xuất đổi giờ xem phòng";
                        string note = !string.IsNullOrWhiteSpace(dto.OwnerNote) ? $" Ghi chú: {dto.OwnerNote}" : "";
                        notifMessage = $"Chủ trọ đề xuất dời lịch xem {roomTitle} sang {timeStr}.{note}";
                    }
                    else if (newStatus == "completed")
                    {
                        notifTitle = "Đã hoàn tất xem phòng";
                        notifMessage = $"Cảm ơn bạn đã đến xem {roomTitle}. Hãy liên hệ chủ trọ nếu bạn muốn tiến hành ký hợp đồng.";
                    }

                    var tenantNotif = new Notification
                    {
                        Id = "NOTIF_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                        UserId = appointment.TenantId,
                        Title = notifTitle,
                        Message = notifMessage,
                        Type = "appointment_" + newStatus,
                        ReferenceId = appointment.Id,
                        ReferenceType = "viewing_appointment",
                        CreatedAt = now,
                        UpdatedAt = now
                    };
                    _context.Notifications.Add(tenantNotif);
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
