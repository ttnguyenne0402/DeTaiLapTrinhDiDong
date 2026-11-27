using Backend.DTOs;
using Backend.Models;
using Backend.Helpers;
using Backend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/viewing-appointments")]
    public class ViewingAppointmentsController : ControllerBase
    {
        private const string CancelNotifTitle = "Một lịch hẹn vừa bị hủy";

        private readonly IViewingAppointmentService _service;
        private readonly ILogger<ViewingAppointmentsController> _logger;

        public ViewingAppointmentsController(
            IViewingAppointmentService service,
            ILogger<ViewingAppointmentsController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreateAppointment(
            [FromBody] ViewingAppointmentRequestDTO request,
            [FromServices] QuanLyPhongTroContext context,
            CancellationToken cancellationToken)
        {
            var tenantId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(tenantId)) return Unauthorized();
            if (!string.Equals(tenantId, request.TenantId, StringComparison.OrdinalIgnoreCase)) return Forbid();

            await using var transaction = await context.Database.BeginTransactionAsync(cancellationToken);
            await RoomSigningLock.AcquireAsync(context, request.RoomId, cancellationToken);
            // Hai yêu cầu đồng thời của cùng tài khoản phải kiểm tra và lưu theo thứ tự.
            var lockName = $"viewing-appointment:{tenantId.ToUpperInvariant()}";
            await context.Database.ExecuteSqlInterpolatedAsync($"""
                DECLARE @result INT;
                EXEC @result = sys.sp_getapplock @Resource = {lockName},
                    @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 5000;
                IF @result < 0 THROW 50001, 'Unable to lock viewing appointment creation.', 1;
                """, cancellationToken);

            var hasActiveAppointment = await context.ViewingAppointments.AnyAsync(
                appointment => appointment.TenantId == tenantId &&
                    appointment.RoomId == request.RoomId &&
                    (appointment.Status == "pending" || appointment.Status == "confirmed" ||
                     appointment.Status == "rescheduled"),
                cancellationToken);
            if (hasActiveAppointment)
            {
                return Conflict(new
                {
                    message = "Bạn đã có lịch xem phòng này. Mở Lịch hẹn để xem trạng thái hoặc hủy lịch trước khi đặt lại."
                });
            }

            var room = await context.Rooms.Include(r => r.Property)
                .FirstOrDefaultAsync(r => r.Id == request.RoomId, cancellationToken);
            if (room == null) return NotFound(new { message = "Không tìm thấy phòng cần đặt lịch." });
            if (room.Status != "available" || await context.Contracts.AnyAsync(
                c => c.RoomId == room.Id && (c.Status == "pending" || c.Status == "active"), cancellationToken))
            {
                return Conflict(new
                {
                    code = "room_unavailable",
                    message = "Phòng đang được giữ hoặc đã cho thuê."
                });
            }

            request.TenantId = tenantId;
            request.RoomId = room.Id;
            var result = await _service.CreateAppointmentAsync(request);
            var roomName = room.Property == null ? room.Name : $"{room.Name} ({room.Property.Name})";
            var time = TimeOnly.FromTimeSpan(request.AppointmentTime).ToString("HH:mm");
            var date = request.AppointmentDate.ToString("dd/MM/yyyy");
            var now = DateTime.UtcNow;

            context.Notifications.Add(new Notification
            {
                Id = "NOTIF_" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant(),
                UserId = tenantId,
                Title = "Đặt lịch thành công",
                Message = $"Bạn đã gửi yêu cầu xem {roomName} vào lúc {time} ngày {date}. Vui lòng chờ chủ trọ xác nhận.",
                Type = "viewing_appointment",
                ReferenceId = result.Id,
                ReferenceType = "viewing_appointment",
                CreatedAt = now,
                UpdatedAt = now
            });

            var ownerId = room.Property?.OwnerId;
            if (!string.IsNullOrEmpty(ownerId))
            {
                context.Notifications.Add(new Notification
                {
                    Id = "NOTIF_" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant(),
                    UserId = ownerId,
                    Title = "Lịch hẹn xem phòng mới 📅",
                    Message = $"Khách hàng vừa đặt lịch hẹn xem {roomName} vào lúc {time} ngày {date}. SĐT: {request.Phone}.",
                    Type = "appointment_new",
                    ReferenceId = result.Id,
                    ReferenceType = "viewing_appointment",
                    CreatedAt = now,
                    UpdatedAt = now
                });
            }

            await context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return CreatedAtAction(nameof(GetTenantAppointments), new { tenantId }, result);
        }

        // GET: api/viewing-appointments/tenant/{tenantId}
        // Lấy danh sách lịch sử cho màn hình booking_history_screen
        [HttpGet("tenant/{tenantId}")]
        public async Task<IActionResult> GetTenantAppointments(string tenantId)
        {
            var appointments = await _service.GetTenantAppointmentsAsync(tenantId);
            return Ok(appointments);
            // Trả về mã 200 OK kèm danh sách JSON
        }

        [HttpPatch("{id}/cancel")]
        public async Task<IActionResult> CancelAppointment(string id, [FromServices] QuanLyPhongTroContext _context)
        {
            var result = await _service.CancelAppointmentAsync(id);
            if (!result) return NotFound(new { message = "Không tìm thấy lịch hẹn hoặc không thể hủy." });

            try
            {
                // 1. Thông báo cho chủ trọ (Giữ nguyên)
                await NotifyOwnerAppointmentCancelledAsync(_context, id);

                // 2. THÊM MỚI: Thông báo cho NGƯỜI THUÊ
                var appointment = await _context.ViewingAppointments
                    .Include(v => v.Room).ThenInclude(r => r.Property)
                    .FirstOrDefaultAsync(v => v.Id == id);

                if (appointment != null && !string.IsNullOrEmpty(appointment.TenantId))
                {
                    string roomName = appointment.Room?.Name ?? "phòng";
                    string propName = appointment.Room?.Property?.Name ?? "";
                    string displayPlace = string.IsNullOrEmpty(propName) ? roomName : $"{roomName} ({propName})";

                    var tenantNotif = new Notification
                    {
                        Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper(),
                        UserId = appointment.TenantId, // Báo cho người thuê
                        Title = "Đã hủy lịch xem phòng",
                        Message = $"Bạn đã hủy lịch hẹn xem {displayPlace} thành công.",
                        Type = "viewing_appointment",
                        ReferenceId = appointment.Id,
                        ReferenceType = "viewing_appointment",
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(tenantNotif);
                    await _context.SaveChangesAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo thông báo hủy lịch hẹn.");
            }

            return Ok(new { message = "Đã hủy lịch hẹn thành công." });
        }

        // PATCH: api/viewing-appointments/{id}/status
        // Nút "Đồng ý giờ mới" hoặc "Từ chối" khi lịch bị dời (rescheduled)
        [HttpPatch("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateAppointmentStatusDTO request)
        {
            if (request.Status != "confirmed" && request.Status != "rejected")
            {
                return BadRequest(new { message = "Trạng thái không hợp lệ." });
            }

            var result = await _service.UpdateStatusAsync(id, request.Status);
            if (!result) return NotFound(new { message = "Không tìm thấy lịch hẹn." });

            return Ok(new { message = "Đã cập nhật trạng thái lịch hẹn." });
        }

        /// <summary>
        /// Báo cho chủ trọ: tên khách + ngày giờ hẹn đã hủy (+ phòng) để chủ trọ chủ động thời gian.
        /// </summary>
        private async Task NotifyOwnerAppointmentCancelledAsync(QuanLyPhongTroContext context, string appointmentId)
        {
            var appointment = await context.ViewingAppointments
                .Include(v => v.Room)
                    .ThenInclude(r => r.Property)
                .Include(v => v.Tenant)
                .FirstOrDefaultAsync(v => v.Id == appointmentId);

            if (appointment == null) return;

            var ownerId = appointment.Room?.Property?.OwnerId;
            if (string.IsNullOrEmpty(ownerId))
            {
                _logger.LogWarning("Không xác định được chủ trọ cho lịch hẹn {Id}", appointmentId);
                return;
            }

            // Chống trùng khi client bấm hủy nhiều lần
            bool alreadyNotified = await context.Notifications.AnyAsync(n =>
                n.UserId == ownerId &&
                n.Type == "viewing_appointment" &&
                n.ReferenceId == appointment.Id &&
                n.Title == CancelNotifTitle);

            if (alreadyNotified) return;

            var tenantName = appointment.Tenant?.Name ?? "Khách hàng";
            var roomName = appointment.Room?.Name ?? "";
            var propertyName = appointment.Room?.Property?.Name ?? "";

            // appointment_date (DATE) và appointment_time (TIME) là 2 cột riêng
            var dateStr = appointment.AppointmentDate.ToString("dd/MM/yyyy");
            var timeStr = appointment.AppointmentTime.ToString("HH:mm");

            var place = string.Join(" - ", new[] { roomName, propertyName }.Where(s => !string.IsNullOrEmpty(s)));
            var placePart = string.IsNullOrEmpty(place) ? "" : $" ({place})";

            context.Notifications.Add(new Notification
            {
                Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                UserId = ownerId, // Gửi cho CHỦ NHÀ
                Title = CancelNotifTitle,
                Message = $"{tenantName} đã hủy lịch xem phòng{placePart} vào lúc {timeStr} ngày {dateStr}.",
                Type = "viewing_appointment",
                ReferenceId = appointment.Id,
                ReferenceType = "viewing_appointment",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            });

            await context.SaveChangesAsync();
        }
    }
}
