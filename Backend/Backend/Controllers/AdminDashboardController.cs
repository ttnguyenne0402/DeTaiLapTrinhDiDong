using Backend.DT0s;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    public class AdminDashboardController : Controller
    {
        private readonly QuanLyPhongTroContext _context;
        public AdminDashboardController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        [HttpGet("stats")]

        public async Task<IActionResult> GetDashboardStats([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                // Mặc định nếu không truyền ngày thì lấy 30 ngày gần nhất
                var start = startDate ?? DateTime.UtcNow.AddDays(-30);
                var end = endDate ?? DateTime.UtcNow;

                // 1. Thống kê 4 thẻ StarCard
                var totalUsers = await _context.Users.CountAsync();
                var totalRooms = await _context.Rooms.CountAsync();

                // Lọc tin đăng theo khoảng thời gian (kiểm tra tên cột thời gian trong RentalPost, VD: CreatedAt hoặc PostDate)
                var approvedPosts = await _context.RentalPosts
                    .Where(p => p.CreatedAt >= start && p.CreatedAt <= end)
                     .Where(p => p.Status == "Approved") // Bỏ comment nếu RentalPost có trường Status
                    .CountAsync();

                // Số lượng tin chờ duyệt hoặc báo cáo vi phạm
                var pendingReports = await _context.RentalPosts
                    .Where(p => p.CreatedAt >= start && p.CreatedAt <= end)
                    // .Where(p => p.Status == "Pending")
                    .CountAsync();

                // 2. Dữ liệu biểu đồ
                var chartPoints = new List<ChartDataPointDto>
                {
                    new ChartDataPointDto { Label = "Tuần 1", Views = 480, Searches = 340 },
                    new ChartDataPointDto { Label = "Tuần 2", Views = 620, Searches = 470 },
                    new ChartDataPointDto { Label = "Tuần 3", Views = 550, Searches = 410 },
                    new ChartDataPointDto { Label = "Tuần 4", Views = 790, Searches = 630 }
                };

                var response = new AdminDashboardDto
                {
                    TotalUsers = totalUsers,
                    TotalRooms = totalRooms,
                    ApprovedPosts = approvedPosts,
                    PendingOrReportedPosts = pendingReports,
                    ChartData = chartPoints
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy dữ liệu dashboard", error = ex.Message });
            }
        }


    }
}
