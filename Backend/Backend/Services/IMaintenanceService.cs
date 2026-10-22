using Backend.DTOs;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface IMaintenanceService
    {
        Task<MaintenanceResponseDTO> CreateRequestAsync(MaintenanceRequestDTO request);
        Task<IEnumerable<MaintenanceResponseDTO>> GetTenantRequestsAsync(string tenantId);
    }
}
