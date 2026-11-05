using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/payments")]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _service;

        public PaymentsController(IPaymentService service)
        {
            _service = service;
        }

        // POST: api/payments
        [HttpPost]
        public async Task<IActionResult> SubmitPayment([FromBody] PaymentRequestDTO request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var success = await _service.SubmitPaymentAsync(request);
            if (!success)
            {
                return BadRequest("Hóa đơn không hợp lệ hoặc đã được thanh toán.");
            }

            return Ok(new { message = "Đã ghi nhận thanh toán. Chờ chủ nhà duyệt." });
        }
    }
}