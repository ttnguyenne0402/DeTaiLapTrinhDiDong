using Backend.DTOs;
using Backend.Models;
using Backend.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Services
{
    public class ViewingAppointmentService : IViewingAppointmentService
    {
        private readonly IViewingAppointmentRepository _repository;

        public ViewingAppointmentService(IViewingAppointmentRepository repository)
        {
            _repository = repository;
        }

        public async Task<ViewingAppointmentResponseDTO> CreateAppointmentAsync(ViewingAppointmentRequestDTO request)
        {
            // Tự động tạo ID cho lịch hẹn mới (thêm hậu tố ngẫu nhiên để không trùng trong cùng 1 giây)
            string newId = "VA" + DateTime.Now.ToString("yyyyMMddHHmmss") + Guid.NewGuid().ToString("N").Substring(0, 4).ToUpper();

            // Chuyển đổi từ DTO (Flutter gửi) sang Model (Database hiểu)
            var appointment = new ViewingAppointment
            {
                Id = newId,
                RoomId = request.RoomId,
                TenantId = request.TenantId,
                AppointmentDate = DateOnly.FromDateTime(request.AppointmentDate),
                AppointmentTime = TimeOnly.FromTimeSpan(request.AppointmentTime),
                Phone = request.Phone,
                Message = request.Message,
                Status = "pending",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            // Gọi Repo để lưu xuống SQL Server
            await _repository.AddAsync(appointment);

            // Trả về kết quả xác nhận cho Flutter
            return new ViewingAppointmentResponseDTO
            {
                Id = appointment.Id,
                RoomName = "Đã ghi nhận",
                Address = "Đã ghi nhận",
                Status = appointment.Status
            };
        }

        public async Task<IEnumerable<ViewingAppointmentResponseDTO>> GetTenantAppointmentsAsync(string tenantId)
        {
            var appointments = await _repository.GetByTenantIdAsync(tenantId);

            // Định dạng lại dữ liệu trước khi đưa lên UI Flutter
            return appointments.Select(a => new ViewingAppointmentResponseDTO
            {
                Id = a.Id,
                // rooms.name đã có sẵn chữ "Phòng ..." (vd "Phòng 101") nên không ghép thêm tiền tố
                RoomName = a.Room?.Name ?? "Phòng không xác định",
                // Ghép chuỗi địa chỉ từ bảng Properties
                Address = a.Room?.Property != null
                          ? $"{a.Room.Property.Address}, {a.Room.Property.Ward}, {a.Room.Property.District}"
                          : "Chưa cập nhật địa chỉ",

                // Định dạng ngày giờ chuẩn Việt Nam cho Flutter khỏi tốn công parse
                Date = a.AppointmentDate.ToString("dd/MM/yyyy"),
                // TimeOnly: "HH" = 24 giờ. Dùng "hh" sẽ ra 12 giờ (15:00 thành 03:00)
                Time = a.AppointmentTime.ToString("HH:mm"),

                Status = a.Status,
                Message = a.Message,
                OwnerNote = a.OwnerNote
            });
        }

        public async Task<bool> CancelAppointmentAsync(string id)
        {
            var appointment = await _repository.GetByIdAsync(id);
            if (appointment == null) return false;

            // Đã hủy rồi thì coi như thành công (bấm 2 lần không báo lỗi);
            // controller tự chống trùng thông báo
            if (appointment.Status == "cancelled") return true;

            // Chỉ cho hủy các lịch còn hiệu lực, không hủy lịch đã hoàn thành / bị từ chối
            if (appointment.Status != "pending" &&
                appointment.Status != "confirmed" &&
                appointment.Status != "rescheduled")
            {
                return false;
            }

            appointment.Status = "cancelled";
            appointment.CancelledAt = DateTime.Now;
            appointment.UpdatedAt = DateTime.Now;

            await _repository.UpdateAsync(appointment);
            return true;
        }

        public async Task<bool> UpdateStatusAsync(string id, string status)
        {
            var appointment = await _repository.GetByIdAsync(id);
            if (appointment == null) return false;

            appointment.Status = status;
            appointment.UpdatedAt = DateTime.Now;

            // Nếu đồng ý lịch dời, ghi lại thời gian xác nhận
            if (status == "confirmed")
            {
                appointment.ConfirmedAt = DateTime.Now;
            }

            await _repository.UpdateAsync(appointment);
            return true;
        }
    }
}