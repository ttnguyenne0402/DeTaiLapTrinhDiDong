using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

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

        // POST: api/viewing-appointments
        // Nhận dữ liệu từ form Đặt lịch của bạn (booking_screen)
        [HttpPost]
        public async Task<IActionResult> CreateAppointment([FromBody] ViewingAppointmentRequestDTO request)
        {
            if (!ModelState.IsValid)
            {
                // Tự động báo lỗi nếu Flutter gửi thiếu dữ liệu
                return BadRequest(ModelState);
            }

            var result = await _service.CreateAppointmentAsync(request);
            // Trả về mã 201 Created cùng dữ liệu xác nhận
            return CreatedAtAction(nameof(GetTenantAppointments), new { tenantId = request.TenantId }, result);
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

        // PATCH: api/viewing-appointments/{id}/cancel
        [HttpPatch("{id}/cancel")]
        public async Task<IActionResult> CancelAppointment(string id, [FromServices] QuanLyPhongTroContext _context)
        {
            var result = await _service.CancelAppointmentAsync(id);
            if (!result) return NotFound(new { message = "Không tìm thấy lịch hẹn hoặc không thể hủy." });

            // Thông báo cho chủ trọ: lỗi ở đây không được làm client mất kết quả "hủy thành công"
            try
            {
                await NotifyOwnerAppointmentCancelledAsync(_context, id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo thông báo hủy lịch hẹn cho chủ trọ. AppointmentId={Id}", id);
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