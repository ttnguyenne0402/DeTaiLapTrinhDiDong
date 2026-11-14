using Backend.DTOs;
using Backend.Models;
using Backend.Repositories;
using Backend.Utils;
using System;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly IPaymentRepository _paymentRepo;
        private readonly IInvoiceRepository _invoiceRepo;

        // TODO: chuyển các giá trị này sang appsettings.json / user-secrets, không để trong code
        private const string Vnp_TmnCode = "CC55FG4O";
        private const string Vnp_HashSecret = "STYTYTIHZBSLWYQININXOAQNEZYKXGHL";
        private const string Vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
        private const string Vnp_ReturnUrl = "http://10.0.2.2:5093/api/payments/vnpay-return";

        public PaymentService(IPaymentRepository paymentRepo, IInvoiceRepository invoiceRepo)
        {
            _paymentRepo = paymentRepo;
            _invoiceRepo = invoiceRepo;
        }

        public async Task<(bool Success, string Message, string? PaymentUrl)> SubmitPaymentAsync(PaymentRequestDTO request, string ipAddress)
        {
            var invoice = await _invoiceRepo.GetByIdAsync(request.InvoiceId);
            if (invoice == null || invoice.Status == "paid")
                return (false, "Hóa đơn không hợp lệ hoặc đã thanh toán.", null);

            // Số tiền do client gửi lên không đáng tin: phải khớp với hóa đơn,
            // vì đây chính là số tiền sẽ hiện trong thông báo cho chủ trọ
            if (request.Amount != invoice.Total)
                return (false, "Số tiền thanh toán không khớp với hóa đơn.", null);

            // Thêm hậu tố ngẫu nhiên để 2 giao dịch trong cùng 1 giây không đụng khóa
            string suffix = Guid.NewGuid().ToString("N").Substring(0, 4).ToUpper();
            string stamp = DateTime.Now.ToString("yyyyMMddHHmmss");
            string txnRef = "GD" + stamp + suffix;

            var payment = new Payment
            {
                Id = "PAY" + stamp + suffix,
                PaymentCode = txnRef,
                InvoiceId = request.InvoiceId,
                PayerId = request.PayerId,
                Amount = request.Amount,
                Method = request.Method,
                Status = "pending",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            await _paymentRepo.AddAsync(payment);

            // NẾU LÀ VNPAY -> TẠO LINK
            if (request.Method == "qr")
            {
                string info = $"Thanh toan hoa don {request.InvoiceId}";
                string paymentUrl = VnPayHelper.GenerateUrl(Vnp_TmnCode, Vnp_HashSecret, Vnp_Url, Vnp_ReturnUrl, txnRef, request.Amount, info, ipAddress);
                return (true, "Vui lòng thanh toán qua link.", paymentUrl);
            }

            // NẾU LÀ TIỀN MẶT / CHUYỂN KHOẢN
            invoice.Status = "pending";
            await _invoiceRepo.UpdateAsync(invoice);
            return (true, "Đã ghi nhận, chờ chủ nhà duyệt.", null);
        }

        public async Task<bool> ConfirmVnPayTransactionAsync(string txnRef, string responseCode)
        {
            // 1. Tìm giao dịch thanh toán trong database dựa vào mã txnRef
            var payment = await _paymentRepo.GetByPaymentCodeAsync(txnRef);
            if (payment == null) return false;

            // Idempotent: VNPay/người dùng gọi lại thì không xử lý lần 2
            // (tránh việc một lệnh gọi "thất bại" đến sau làm hóa đơn đã paid bị đổi về unpaid)
            if (payment.Status == "success") return true;
            if (payment.Status != "pending") return false;

            // 2. Tìm hóa đơn liên kết với giao dịch này
            var invoice = await _invoiceRepo.GetByIdAsync(payment.InvoiceId);
            if (invoice == null) return false;

            // 3. Nếu khách hàng thanh toán thành công trên VNPay
            if (responseCode == "00")
            {
                payment.Status = "success";
                payment.PaidAt = DateTime.Now;
                payment.UpdatedAt = DateTime.Now;
                await _paymentRepo.UpdateAsync(payment);

                invoice.Status = "paid";
                invoice.UpdatedAt = DateTime.Now;
                await _invoiceRepo.UpdateAsync(invoice);

                return true;
            }

            // Khách hủy giao dịch hoặc thanh toán thất bại
            payment.Status = "failed";
            payment.UpdatedAt = DateTime.Now;
            await _paymentRepo.UpdateAsync(payment);

            // Chỉ khôi phục về unpaid nếu hóa đơn chưa được thanh toán bằng giao dịch khác
            if (invoice.Status != "paid")
            {
                invoice.Status = "unpaid";
                invoice.UpdatedAt = DateTime.Now;
                await _invoiceRepo.UpdateAsync(invoice);
            }

            return false;
        }
    }
}