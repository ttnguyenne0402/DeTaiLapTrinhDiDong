using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/dashboard")]
    [ApiController]
    public class OwnerDashboardController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerDashboardController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetDashboardData(string ownerId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                // 1. Lấy thông tin chủ trọ
                var owner = await _context.Users.FirstOrDefaultAsync(u => targetOwnerIds.Contains(u.Id));
                if (owner == null) return NotFound(new { message = "Không tìm thấy chủ trọ" });

                // Lấy danh sách ID các phòng thuộc quyền sở hữu của chủ trọ này
                var roomIds = await (from p in _context.Properties
                                     join r in _context.Rooms on p.Id equals r.PropertyId
                                     where targetOwnerIds.Contains(p.OwnerId)
                                     select r.Id).ToListAsync();

                // 2. Thống kê số lượng các chỉ số chính (ngắn gọn bằng LINQ CountAsync)
                var rentedRooms = await _context.Rooms.CountAsync(r => roomIds.Contains(r.Id) && r.Status == "rented");
                var emptyRooms = await _context.Rooms.CountAsync(r => roomIds.Contains(r.Id) && r.Status == "available");
                var scheduledAppointments = await _context.ViewingAppointments.CountAsync(v => roomIds.Contains(v.RoomId) && (v.Status == "confirmed" || v.Status == "pending" || v.Status == "rescheduled"));
                var repairRequests = await _context.MaintenanceRequests.CountAsync(m => roomIds.Contains(m.RoomId) && m.Status == "pending");

                // 3. Lấy danh sách lịch xem phòng sắp tới
                var rawAppointments = await (from v in _context.ViewingAppointments
                                             join r in _context.Rooms on v.RoomId equals r.Id
                                             join u in _context.Users on v.TenantId equals u.Id
                                             where roomIds.Contains(v.RoomId) && (v.Status == "confirmed" || v.Status == "pending" || v.Status == "rescheduled")
                                             orderby v.AppointmentDate, v.AppointmentTime
                                             select new
                                             {
                                                 date = v.AppointmentDate,
                                                 timeSpan = v.AppointmentTime,
                                                 name = u.Name,
                                                 roomName = r.Name,
                                                 phone = v.Phone,
                                                 status = v.Status == "confirmed" ? "Đã xác nhận" : (v.Status == "rescheduled" ? "Đã đổi giờ" : "Chờ xác nhận")
                                             })
                                             .Take(5)
                                             .ToListAsync(); 

                // Format lại chuỗi thời gian ở phía client C# cho an toàn tuyệt đối
                var upcomingAppointments = rawAppointments.Select(v => new {
                    time = v.date.ToString("dd/MM/yyyy") + ", " + v.timeSpan.ToString("HH:mm"),
                    name = v.name,
                    roomInfo = v.roomName.StartsWith("Phòng", StringComparison.OrdinalIgnoreCase) ? v.roomName : "Phòng " + v.roomName,
                    status = v.status,
                    phone = v.phone
                }).ToList();

                // 4. Đóng gói kết quả trả về JSON gọn gàng
                var response = new
                {
                    ownerName = owner.Name,
                    ownerRole = "Chủ trọ khu vực quản lý",
                    totalRentedRooms = rentedRooms,
                    scheduledAppointments = scheduledAppointments,
                    emptyRooms = emptyRooms,
                    repairRequests = repairRequests,
                    upcomingAppointments = upcomingAppointments
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu owner dashboard", error = ex.Message });
            }
        }
    }
}