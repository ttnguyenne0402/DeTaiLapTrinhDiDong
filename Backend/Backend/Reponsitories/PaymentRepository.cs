using Backend.Models;
using Microsoft.EntityFrameworkCore; 
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
      
        public async Task<Payment?> GetByPaymentCodeAsync(string paymentCode)
        {
            return await _context.Payments.FirstOrDefaultAsync(p => p.PaymentCode == paymentCode);
        }

       
        public async Task UpdateAsync(Payment payment)
        {
            _context.Payments.Update(payment);
            await _context.SaveChangesAsync();
        }
    }
}