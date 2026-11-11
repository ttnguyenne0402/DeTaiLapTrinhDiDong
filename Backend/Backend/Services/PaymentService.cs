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


            string txnRef = "GD" + DateTime.Now.ToString("yyyyMMddHHmmss");

            var payment = new Payment
            {
                Id = "PAY" + DateTime.Now.ToString("yyyyMMddHHmmss"),
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

            // NẾU LÀ TIỀN MẶT
            invoice.Status = "pending";
            await _invoiceRepo.UpdateAsync(invoice);
            return (true, "Đã ghi nhận, chờ chủ nhà duyệt.", null);
        }

        public async Task<bool> ConfirmVnPayTransactionAsync(string txnRef, string responseCode)
        {
            // 1. Tìm giao dịch thanh toán trong database dựa vào mã txnRef
            var payment = await _paymentRepo.GetByPaymentCodeAsync(txnRef);

            if (payment == null)
            {
                return false; 
            }

            // 2. Tìm hóa đơn liên kết với giao dịch này
            var invoice = await _invoiceRepo.GetByIdAsync(payment.InvoiceId);

            if (invoice == null)
            {
                return false; // Không tìm thấy hóa đơn
            }

            // 3. Nếu khách hàng thanh toán thành công trên VNPay
            if (responseCode == "00")
            {
                // Cập nhật trạng thái Giao dịch thành công
                payment.Status = "success";
                payment.PaidAt = DateTime.Now;
                payment.UpdatedAt = DateTime.Now;
                await _paymentRepo.UpdateAsync(payment);

                // Cập nhật trạng thái Hóa đơn thành đã thanh toán
                invoice.Status = "paid";
                invoice.UpdatedAt = DateTime.Now;
                await _invoiceRepo.UpdateAsync(invoice);

                return true;
            }
            else
            {
                // Nếu khách hàng hủy giao dịch hoặc thanh toán thất bại
                payment.Status = "failed";
                payment.UpdatedAt = DateTime.Now;
                await _paymentRepo.UpdateAsync(payment);

                // Khôi phục trạng thái hóa đơn về unpaid 
                invoice.Status = "unpaid";
                invoice.UpdatedAt = DateTime.Now;
                await _invoiceRepo.UpdateAsync(invoice);

                return false;
            }
        }
    }
}