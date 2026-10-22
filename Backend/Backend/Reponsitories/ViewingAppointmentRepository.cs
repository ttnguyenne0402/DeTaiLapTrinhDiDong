using Backend.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public class ViewingAppointmentRepository : IViewingAppointmentRepository
    {
        private readonly QuanLyPhongTroContext _context;

        public ViewingAppointmentRepository(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        public async Task<ViewingAppointment> AddAsync(ViewingAppointment appointment)
        {
            await _context.ViewingAppointments.AddAsync(appointment);
            await _context.SaveChangesAsync();
            return appointment;
        }

        public async Task<IEnumerable<ViewingAppointment>> GetByTenantIdAsync(string tenantId)
        {
            // Lấy lịch hẹn, kết hợp (Join) với bảng Rooms và Properties để lấy tên phòng & địa chỉ
            return await _context.ViewingAppointments
                .Include(v => v.Room)
                    .ThenInclude(r => r.Property)
                .Where(v => v.TenantId == tenantId)
                .OrderByDescending(v => v.CreatedAt)
                .ToListAsync();
        }
    }
}