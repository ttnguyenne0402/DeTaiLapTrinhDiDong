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
    }
}