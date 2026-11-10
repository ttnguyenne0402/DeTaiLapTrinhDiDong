using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/contracts")]
    public class ContractsController : ControllerBase
    {
        private readonly IContractService _service;

        public ContractsController(IContractService service)
        {
            _service = service;
        }

        // GET: api/contracts/tenant/{tenantId}
        // Lấy danh sách hợp đồng cho màn hình my_contracts_screen
        [HttpGet("tenant/{tenantId}")]
        public async Task<IActionResult> GetTenantContracts(string tenantId)
        {
            var contracts = await _service.GetTenantContractsAsync(tenantId);
            return Ok(contracts); 
        }
        // GET: api/contracts/{id}
        // Lấy chi tiết hợp đồng cho màn hình contract_detail_screen
        [HttpGet("{id}")]
        public async Task<IActionResult> GetContractDetail(string id)
        {
            var contract = await _service.GetContractDetailAsync(id);

            if (contract == null)
                return NotFound(new { message = "Không tìm thấy hợp đồng" });

            return Ok(contract);
        }
    }
}