using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public class ContractRepository : IContractRepository
    {
        private readonly QuanLyPhongTroContext _context;

        public ContractRepository(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Contract>> GetByTenantIdAsync(string tenantId)
        {
            // Lấy hợp đồng, kết hợp (Join) với bảng Rooms và Properties
            return await _context.Contracts
                .Include(c => c.Room)
                    .ThenInclude(r => r.Property)
                .Where(c => c.TenantId == tenantId)
                .OrderByDescending(c => c.StartDate)
                .ToListAsync();
        }
        public async Task<Contract> GetByIdAsync(string id)
        {
            return await _context.Contracts
                .Include(c => c.Room)
                .Include(c => c.Owner)
                .Include(c => c.ContractServices)
                    .ThenInclude(cs => cs.Service) 
                .FirstOrDefaultAsync(c => c.Id == id);
        }
    }
}