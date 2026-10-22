using Backend.DTOs;
using Backend.Models;
using Backend.Repositories;
using System;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly IPaymentRepository _paymentRepo;
        private readonly IInvoiceRepository _invoiceRepo;

        public PaymentService(IPaymentRepository paymentRepo, IInvoiceRepository invoiceRepo)
        {
            _paymentRepo = paymentRepo;
            _invoiceRepo = invoiceRepo;
        }

        public async Task<bool> SubmitPaymentAsync(PaymentRequestDTO request)
        {
            var invoice = await _invoiceRepo.GetByIdAsync(request.InvoiceId);
            if (invoice == null || invoice.Status == "paid" || invoice.Status == "pending")
            {
                return false;
                // Hóa đơn không tồn tại, đã thanh toán, hoặc đang chờ duyệt rồi
            }

            // 1. Lưu giao dịch thanh toán mới
            var payment = new Payment
            {
                Id = "PAY" + DateTime.Now.ToString("yyyyMMddHHmmss"),
                PaymentCode = "GD" + DateTime.Now.ToString("yyyyMMddHHmmss"),
                InvoiceId = request.InvoiceId,
                PayerId = request.PayerId,
                Amount = request.Amount,
                Method = request.Method,
                Status = "pending", 
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            await _paymentRepo.AddAsync(payment);

            // 2. Đổi trạng thái hóa đơn sang "Đang chờ duyệt" (pending)
            invoice.Status = "pending";
            invoice.UpdatedAt = DateTime.Now;
            await _invoiceRepo.UpdateAsync(invoice);

            return true;
        }
    }
}