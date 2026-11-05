using Backend.Models;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public class PaymentRepository : IPaymentRepository
    {
        private readonly QuanLyPhongTroContext _context;

        public PaymentRepository(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        public async Task<Payment> AddAsync(Payment payment)
        {
            await _context.Payments.AddAsync(payment);
            await _context.SaveChangesAsync();
            return payment;
        }
    }
}