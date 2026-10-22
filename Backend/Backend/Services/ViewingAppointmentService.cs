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
            // 1. Xử lý nghiệp vụ: Tự động tạo ID cho lịch hẹn mới
            string newId = "VA" + DateTime.Now.ToString("yyyyMMddHHmmss");

            // 2. Chuyển đổi từ DTO (Flutter gửi) sang Model (Database hiểu)
            var appointment = new ViewingAppointment
            {
                Id = newId,
                RoomId = request.RoomId,
                TenantId = request.TenantId,
                AppointmentDate = DateOnly.FromDateTime(request.AppointmentDate), 
                AppointmentTime = TimeOnly.FromTimeSpan(request.AppointmentTime), 
                Phone = request.Phone,
                Message = request.Message,
                Status = "pending", // Luôn gán trạng thái mặc định là Đang chờ
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            // 3. Gọi Repo để lưu xuống SQL Server
            await _repository.AddAsync(appointment);

            // 4. Trả về kết quả xác nhận cho Flutter
            return new ViewingAppointmentResponseDTO
            {
                Id = appointment.Id,
                RoomName = "Đã ghi nhận", // Sẽ cập nhật đủ khi load danh sách
                Address = "Đã ghi nhận",
                Status = appointment.Status
            };
        }

        public async Task<IEnumerable<ViewingAppointmentResponseDTO>> GetTenantAppointmentsAsync(string tenantId)
        {
            var appointments = await _repository.GetByTenantIdAsync(tenantId);

            // Xử lý nghiệp vụ: Định dạng lại dữ liệu cho đẹp trước khi quăng lên UI Flutter
            return appointments.Select(a => new ViewingAppointmentResponseDTO
            {
                Id = a.Id,
                // Lấy tên phòng từ bảng Rooms
                RoomName = a.Room?.Name != null ? $"Phòng {a.Room.Name}" : "Phòng không xác định",
                // Ghép chuỗi địa chỉ từ bảng Properties
                Address = a.Room?.Property != null
                          ? $"{a.Room.Property.Address}, {a.Room.Property.Ward}, {a.Room.Property.District}"
                          : "Chưa cập nhật địa chỉ",

                // Định dạng ngày giờ chuẩn Việt Nam cho Flutter khỏi tốn công parse
                Date = a.AppointmentDate.ToString("dd/MM/yyyy"),
                Time = a.AppointmentTime.ToString(@"hh\:mm"),

                Status = a.Status,
                Message = a.Message,
                OwnerNote = a.OwnerNote
            });
        }
    }
}