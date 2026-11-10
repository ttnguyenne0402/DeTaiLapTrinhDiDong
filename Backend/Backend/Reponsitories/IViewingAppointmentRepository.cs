using Backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Repositories
{
    public interface IViewingAppointmentRepository
    {
        // Hàm lưu lịch hẹn mới vào CSDL
        Task<ViewingAppointment> AddAsync(ViewingAppointment appointment);

        // Hàm lấy danh sách lịch hẹn của 1 người thuê
        Task<IEnumerable<ViewingAppointment>> GetByTenantIdAsync(string tenantId);
        // Hàm lấy 1 lịch hẹn theo ID
        Task<ViewingAppointment> GetByIdAsync(string id);

        // Hàm cập nhật thay đổi xuống CSDL
        Task UpdateAsync(ViewingAppointment appointment);
    }
}