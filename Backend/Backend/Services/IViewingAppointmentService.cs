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
        // Hàm hủy lịch
        Task<bool> CancelAppointmentAsync(string id);

        // Hàm cập nhật trạng thái (Đồng ý/Từ chối dời lịch)
        Task<bool> UpdateStatusAsync(string id, string status);
    }
}