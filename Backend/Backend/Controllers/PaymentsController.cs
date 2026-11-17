using Backend.DTOs;
using Backend.Models;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/payments")]
    public class PaymentsController : ControllerBase
    {
        private static readonly CultureInfo ViCulture = new CultureInfo("vi-VN");

        private readonly IPaymentService _service;
        private readonly ILogger<PaymentsController> _logger;

        public PaymentsController(IPaymentService service, ILogger<PaymentsController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> SubmitPayment(
            [FromBody] PaymentRequestDTO request,
            [FromServices] QuanLyPhongTroContext _context)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            // Lấy IP giả lập gửi cho VNPay
            string ip = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "127.0.0.1";

            var result = await _service.SubmitPaymentAsync(request, ip);
            if (!result.Success) return BadRequest(result.Message);

            // Tiền mặt / chuyển khoản: chủ trọ phải đối soát và duyệt -> báo ngay khi khách gửi.
            // (VNPay thì báo ở vnpay-return, sau khi tiền về.)
            if (request.Method != "qr")
            {
                try
                {
                    var payment = await PaymentWithContext(_context)
                        .Where(p => p.InvoiceId == request.InvoiceId
                                 && p.PayerId == request.PayerId
                                 && p.Status == "pending")
                        .OrderByDescending(p => p.CreatedAt)
                        .FirstOrDefaultAsync();

                    if (payment != null)
                        await NotifyOwnerAsync(_context, payment, awaitingApproval: true);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Không thể tạo thông báo chờ duyệt thanh toán. InvoiceId={InvoiceId}", request.InvoiceId);
                }
            }

            return Ok(new { message = result.Message, paymentUrl = result.PaymentUrl });
        }

        [HttpGet("vnpay-return")]
        public async Task<IActionResult> VnPayReturn(
            [FromQuery] string vnp_TxnRef,
            [FromQuery] string vnp_ResponseCode,
            [FromServices] QuanLyPhongTroContext _context)
        {
            // _service đã thực hiện gạch nợ hóa đơn bên trong
            bool isSuccess = await _service.ConfirmVnPayTransactionAsync(vnp_TxnRef, vnp_ResponseCode);

            if (!isSuccess)
            {
                return BadRequest("Giao dịch bị hủy hoặc thất bại.");
            }

            // Thông báo cho chủ trọ: lỗi ở đây không được làm hỏng luồng thanh toán chính
            try
            {
                var payment = await PaymentWithContext(_context)
                    .FirstOrDefaultAsync(p => p.PaymentCode == vnp_TxnRef || p.Id == vnp_TxnRef);

                if (payment != null)
                    await NotifyOwnerAsync(_context, payment, awaitingApproval: false);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Không thể tạo thông báo thanh toán cho chủ trọ. TxnRef={TxnRef}", vnp_TxnRef);
            }

            return Ok("Thanh toán thành công. Đã gạch nợ hóa đơn!");
        }

        private static IQueryable<Payment> PaymentWithContext(QuanLyPhongTroContext context) =>
            context.Payments
                .Include(p => p.Invoice)
                    .ThenInclude(i => i.Contract)
                        .ThenInclude(c => c.Tenant)
                .Include(p => p.Invoice)
                    .ThenInclude(i => i.Contract)
                        .ThenInclude(c => c.Room);

        /// <summary>
        /// Báo cho chủ trọ: tên khách, kỳ thanh toán, số tiền đã nộp (+ mã hóa đơn, mã giao dịch để đối soát).
        /// awaitingApproval = true: tiền mặt/chuyển khoản, chủ trọ cần xác nhận.
        /// awaitingApproval = false: VNPay đã thành công, hóa đơn đã được gạch nợ.
        /// </summary>
        private async Task NotifyOwnerAsync(QuanLyPhongTroContext context, Payment payment, bool awaitingApproval)
        {
            var invoice = payment.Invoice;
            var contract = invoice?.Contract;

            if (invoice == null || contract == null)
            {
                _logger.LogWarning("Không đủ dữ liệu để tạo thông báo thanh toán. PaymentId={Id}", payment.Id);
                return;
            }

            // Thông báo "đã thanh toán" chỉ gửi khi giao dịch thật sự thành công
            if (!awaitingApproval && payment.Status != "success") return;

            // Chống trùng (VNPay gọi lại / F5 / gửi lặp): mỗi mã giao dịch chỉ báo 1 lần
            bool alreadyNotified = await context.Notifications.AnyAsync(n =>
                n.UserId == contract.OwnerId &&
                n.Type == "invoice" &&
                n.ReferenceId == invoice.Id &&
                n.Message.Contains(payment.PaymentCode));

            if (alreadyNotified) return;

            var tenantName = contract.Tenant?.Name ?? "Khách hàng";
            var roomName = contract.Room?.Name ?? "";
            var roomPart = string.IsNullOrEmpty(roomName) ? "" : $" ({roomName})";
            var amountStr = payment.Amount.ToString("N0", ViCulture) + "đ";
            var period = invoice.BillingMonth.ToString("MM/yyyy");   // kỳ thanh toán, có cả năm

            string title, message;
            if (awaitingApproval)
            {
                var methodLabel = payment.Method switch
                {
                    "cash" => "tiền mặt",
                    "bank_transfer" => "chuyển khoản",
                    _ => payment.Method
                };
                title = "Khách gửi thanh toán - chờ bạn xác nhận";
                message = $"{tenantName}{roomPart} báo đã nộp {amountStr} bằng {methodLabel} cho hóa đơn {invoice.InvoiceCode} (kỳ {period}). Mã GD: {payment.PaymentCode}. Vui lòng đối soát và xác nhận.";
            }
            else
            {
                title = "Khách vừa thanh toán hóa đơn!";
                message = $"{tenantName}{roomPart} đã thanh toán {amountStr} cho hóa đơn {invoice.InvoiceCode} (kỳ {period}). Mã GD: {payment.PaymentCode}.";
            }

            context.Notifications.Add(new Notification
            {
                Id = "NOTIF_" + Guid.NewGuid().ToString("N").Substring(0, 8),
                UserId = contract.OwnerId,
                Title = title,
                Message = message,
                Type = "invoice",
                ReferenceId = invoice.Id,
                ReferenceType = "invoice",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            });

            await context.SaveChangesAsync();
        }
    }
}