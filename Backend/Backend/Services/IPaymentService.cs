using Backend.DTOs;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface IPaymentService
    {
        // Trả về Tuple gồm: Trạng thái, Thông báo, và URL thanh toán (nếu có)
        Task<(bool Success, string Message, string? PaymentUrl)> SubmitPaymentAsync(PaymentRequestDTO request, string ipAddress);

        // Hàm để VNPay gọi ngầm báo kết quả
        Task<bool> ConfirmVnPayTransactionAsync(string txnRef, string responseCode);
    }
}