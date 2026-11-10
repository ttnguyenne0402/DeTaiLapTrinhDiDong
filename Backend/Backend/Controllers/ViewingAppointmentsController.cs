using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/viewing-appointments")]
    public class ViewingAppointmentsController : ControllerBase
    {
        private readonly IViewingAppointmentService _service;

        public ViewingAppointmentsController(IViewingAppointmentService service)
        {
            _service = service;
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
        
        // Nút "Hủy lịch" khi lịch đang ở trạng thái pending
        [HttpPatch("{id}/cancel")]
        public async Task<IActionResult> CancelAppointment(string id)
        {
            // Tự định nghĩa hàm Cancel trong Service của bạn
            var result = await _service.CancelAppointmentAsync(id);
            if (!result) return NotFound(new { message = "Không tìm thấy lịch hẹn hoặc không thể hủy." });

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
    }
}