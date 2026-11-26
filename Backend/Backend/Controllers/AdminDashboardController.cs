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
        public async Task<IActionResult> GetDashboardStats(
            [FromQuery] DateTime? startDate,
            [FromQuery] DateTime? endDate,
            CancellationToken cancellationToken)
        {
            var end = endDate ?? DateTime.UtcNow;
            var start = startDate ?? end.AddDays(-30);
            if (start > end)
                return BadRequest(new { message = "Ngày bắt đầu phải trước hoặc bằng ngày kết thúc." });

            var posts = _context.RentalPosts;
            return Ok(new AdminDashboardDto
            {
                TotalUsers = await _context.Users.CountAsync(cancellationToken),
                TotalRooms = await _context.Rooms.CountAsync(cancellationToken),
                PendingPosts = await posts.CountAsync(p => p.Status == "pending", cancellationToken),
                ApprovedPosts = await posts.CountAsync(p => p.Status == "published" &&
                    (p.PublishedAt ?? p.CreatedAt) >= start &&
                    (p.PublishedAt ?? p.CreatedAt) <= end, cancellationToken),
                RejectedPosts = await posts.CountAsync(p => p.Status == "rejected" &&
                    (p.UpdatedAt ?? p.CreatedAt) >= start &&
                    (p.UpdatedAt ?? p.CreatedAt) <= end, cancellationToken),
            });
        }


    }
}
