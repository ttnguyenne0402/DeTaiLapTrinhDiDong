using Backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public interface IMaintenanceRequestRepository
    {
        Task<MaintenanceRequest> AddAsync(MaintenanceRequest request);
        Task<IEnumerable<MaintenanceRequest>> GetByTenantIdAsync(string tenantId);
    }
}