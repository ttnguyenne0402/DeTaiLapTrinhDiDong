using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public class InvoiceRepository : IInvoiceRepository
    {
        private readonly QuanLyPhongTroContext _context;

        public InvoiceRepository(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Invoice>> GetByTenantIdAsync(string tenantId)
        {
            // Join qua bảng Contract vì Invoice không có TenantId
            return await _context.Invoices
                .Include(i => i.Contract)
                .Where(i => i.Contract.TenantId == tenantId)
                .OrderByDescending(i => i.IssueDate)
                .ToListAsync();
        }

        public async Task<Invoice?> GetByIdAsync(string id)
        {
            // Lấy chi tiết hóa đơn kèm theo danh sách các khoản thu
            return await _context.Invoices
                .Include(i => i.InvoiceItems)
                .FirstOrDefaultAsync(i => i.Id == id);
        }

        public async Task UpdateAsync(Invoice invoice)
        {
            _context.Invoices.Update(invoice);
            await _context.SaveChangesAsync();
        }
    }
}