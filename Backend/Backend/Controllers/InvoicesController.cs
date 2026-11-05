using Backend.Services;
using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/invoices")]
    public class InvoicesController : ControllerBase
    {
        private readonly IInvoiceService _service;

        public InvoicesController(IInvoiceService service)
        {
            _service = service;
        }

        // GET: api/invoices/tenant/{tenantId}
        [HttpGet("tenant/{tenantId}")]
        public async Task<IActionResult> GetTenantInvoices(string tenantId)
        {
            var invoices = await _service.GetTenantInvoicesAsync(tenantId);
            return Ok(invoices);
        }

        // GET: api/invoices/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetInvoiceDetail(string id)
        {
            var invoice = await _service.GetInvoiceDetailAsync(id);
            if (invoice == null) return NotFound();
            return Ok(invoice);
        }
    }
}