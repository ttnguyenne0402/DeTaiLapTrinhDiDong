using Backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public interface IContractRepository
    {
        // Hàm lấy danh sách hợp đồng của 1 người thuê
        Task<IEnumerable<Contract>> GetByTenantIdAsync(string tenantId);
    }
}