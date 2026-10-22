using Backend.DTOs;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface IContractService
    {
        Task<IEnumerable<ContractResponseDTO>> GetTenantContractsAsync(string tenantId);
    }
}