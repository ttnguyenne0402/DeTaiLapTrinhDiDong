using Backend.DTOs;
using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/maintenance")]
    public class MaintenanceRequestsController : ControllerBase
    {
        private readonly IMaintenanceService _service;

        public MaintenanceRequestsController(IMaintenanceService service)
        {
            _service = service;
        }

        // POST: api/maintenance
        [HttpPost]
        public async Task<IActionResult> CreateRequest([FromBody] MaintenanceRequestDTO request)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var result = await _service.CreateRequestAsync(request);
            return CreatedAtAction(nameof(GetTenantRequests), new { tenantId = request.TenantId }, result);
        }

        // GET: api/maintenance/tenant/{tenantId}
        [HttpGet("tenant/{tenantId}")]
        public async Task<IActionResult> GetTenantRequests(string tenantId)
        {
            var requests = await _service.GetTenantRequestsAsync(tenantId);
            return Ok(requests);
        }
    }
}