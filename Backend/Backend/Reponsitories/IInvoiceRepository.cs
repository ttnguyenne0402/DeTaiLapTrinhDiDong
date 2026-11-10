using Backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public interface IInvoiceRepository
    {
        Task<IEnumerable<Invoice>> GetByTenantIdAsync(string tenantId);
        Task<Invoice?> GetByIdAsync(string id);
        Task UpdateAsync(Invoice invoice);
    }
}