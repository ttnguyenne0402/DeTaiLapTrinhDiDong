using Backend.DTOs;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface IPaymentService
    {
        Task<bool> SubmitPaymentAsync(PaymentRequestDTO request);
    }
}