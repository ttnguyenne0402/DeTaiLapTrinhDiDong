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

        [HttpPost]
        public async Task<IActionResult> SubmitPayment([FromBody] PaymentRequestDTO request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Lấy IP giả lập gửi cho VNPay
            string ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";

            var result = await _service.SubmitPaymentAsync(request, ip);
            if (!result.Success) return BadRequest(result.Message);

            return Ok(new { message = result.Message, paymentUrl = result.PaymentUrl });
        }

        // VNPay sẽ tự động gọi ngầm vào link này sau khi khách quẹt thẻ xong
        [HttpGet("vnpay-return")]
        public async Task<IActionResult> VnPayReturn([FromQuery] string vnp_TxnRef, [FromQuery] string vnp_ResponseCode)
        {
            bool isSuccess = await _service.ConfirmVnPayTransactionAsync(vnp_TxnRef, vnp_ResponseCode);

            if (isSuccess)
                return Ok("Thanh toán thành công. Đã gạch nợ hóa đơn!");
            else
                return BadRequest("Giao dịch bị hủy hoặc thất bại.");
        }
    }
}