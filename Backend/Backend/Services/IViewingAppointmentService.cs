using Backend.DTOs;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Backend.Services
{
    public interface IViewingAppointmentService
    {
        // Hàm xử lý logic khi khách bấm nút "Gửi lịch hẹn"
        Task<ViewingAppointmentResponseDTO> CreateAppointmentAsync(ViewingAppointmentRequestDTO request);

        // Hàm lấy và định dạng danh sách lịch sử để hiển thị trên app
        Task<IEnumerable<ViewingAppointmentResponseDTO>> GetTenantAppointmentsAsync(string tenantId);
    }
}