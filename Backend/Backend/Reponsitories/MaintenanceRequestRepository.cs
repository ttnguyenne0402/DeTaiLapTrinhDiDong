using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public class MaintenanceRequestRepository : IMaintenanceRequestRepository
    {
        private readonly QuanLyPhongTroContext _context;

        public MaintenanceRequestRepository(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        public async Task<MaintenanceRequest> AddAsync(MaintenanceRequest request)
        {
            await _context.MaintenanceRequests.AddAsync(request);
            await _context.SaveChangesAsync();
            return request;
        }

        public async Task<IEnumerable<MaintenanceRequest>> GetByTenantIdAsync(string tenantId)
        {
            return await _context.MaintenanceRequests
                .Where(m => m.TenantId == tenantId)
                .OrderByDescending(m => m.CreatedAt)
                .ToListAsync();
        }
    }
}