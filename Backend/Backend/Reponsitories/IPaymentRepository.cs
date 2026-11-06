using Backend.Models;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public interface IPaymentRepository
    {
        Task<Payment> AddAsync(Payment payment);
       
        Task<Payment?> GetByPaymentCodeAsync(string paymentCode);

        Task UpdateAsync(Payment payment);
    }
}
