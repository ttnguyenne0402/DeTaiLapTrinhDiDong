
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public ReviewController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // ============================================
        // GET: api/Review/room/{roomId}
        // Lấy danh sách đánh giá của một phòng
        // ============================================
        [HttpGet("room/{roomId}")]
        public async Task<IActionResult> GetReviewsByRoom(string roomId)
        {
            // Bước 1: Kiểm tra phòng có tồn tại không
            var roomExists = await _context.Rooms
                .AnyAsync(r => r.Id == roomId);

            if (!roomExists)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy phòng"
                });
            }

            // Bước 2: Lấy danh sách đánh giá đã được hiển thị
            var reviews = await _context.Reviews
                .AsNoTracking()
                .Where(r =>
                    r.RoomId == roomId &&
                    r.Status == "visible")
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    id = r.Id,
                    roomId = r.RoomId,
                    tenantId = r.TenantId,
                    tenantName = r.Tenant.Name,
                    tenantAvatar = r.Tenant.Avatar,
                    rating = r.Rating,
                    comment = r.Comment,
                    status = r.Status,
                    createdAt = r.CreatedAt
                })
                .ToListAsync();

            // Bước 3: Trả kết quả
            return Ok(new
            {
                success = true,
                message = "Lấy danh sách đánh giá thành công",
                data = reviews
            });
        }

        // ============================================
        // GET: api/Review/room/{roomId}/summary
        // Lấy điểm trung bình và tổng số đánh giá
        // ============================================
        [HttpGet("room/{roomId}/summary")]
        public async Task<IActionResult> GetReviewSummary(string roomId)
        {
            // Bước 1: Kiểm tra phòng có tồn tại không
            var roomExists = await _context.Rooms
                .AnyAsync(r => r.Id == roomId);

            if (!roomExists)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy phòng"
                });
            }

            // Bước 2: Chỉ thống kê đánh giá đang hiển thị
            var query = _context.Reviews
                .AsNoTracking()
                .Where(r =>
                    r.RoomId == roomId &&
                    r.Status == "visible");

            // Bước 3: Tính tổng số đánh giá
            var totalReviews = await query.CountAsync();

            // Bước 4: Tính điểm trung bình
            var averageRating = totalReviews > 0
                ? await query.AverageAsync(r => (double)r.Rating)
                : 0;

            // Bước 5: Trả kết quả
            return Ok(new
            {
                success = true,
                message = "Lấy thống kê đánh giá thành công",
                data = new
                {
                    roomId = roomId,
                    totalReviews = totalReviews,
                    averageRating = Math.Round(averageRating, 1)
                }
            });
        }

        // ============================================
        // POST: api/Review
        // Người thuê gửi đánh giá phòng
        // ============================================
        [HttpPost]
        public async Task<IActionResult> CreateReview(
            [FromBody] CreateReviewRequest request)
        {
            // BƯỚC 1: Kiểm tra dữ liệu đầu vào
            if (string.IsNullOrWhiteSpace(request.RoomId))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Mã phòng không được để trống"
                });
            }

            if (string.IsNullOrWhiteSpace(request.TenantId))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Mã người thuê không được để trống"
                });
            }

            if (request.Rating < 1 || request.Rating > 5)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Số sao phải từ 1 đến 5"
                });
            }

            if (string.IsNullOrWhiteSpace(request.Comment))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Nội dung đánh giá không được để trống"
                });
            }

            if (request.Comment.Trim().Length > 500)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Nội dung đánh giá không được vượt quá 500 ký tự"
                });
            }

            // BƯỚC 2: Kiểm tra phòng tồn tại
            var roomExists = await _context.Rooms
                .AnyAsync(r => r.Id == request.RoomId);

            if (!roomExists)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy phòng"
                });
            }

            // BƯỚC 3: Kiểm tra người dùng tồn tại và có vai trò tenant
            var tenant = await _context.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == request.TenantId);

            if (tenant == null)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy người dùng"
                });
            }

            if (tenant.Role != "tenant")
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Chỉ người thuê mới được phép đánh giá phòng"
                });
            }

            // BƯỚC 4: Kiểm tra người thuê có hợp đồng hợp lệ với phòng không
            // Chấp nhận: active, expired, terminated
            // Không chấp nhận: draft
            var hasValidContract = await _context.Contracts
                .AnyAsync(c =>
                    c.RoomId == request.RoomId &&
                    c.TenantId == request.TenantId &&
                    (c.Status == "active" ||
                     c.Status == "expired" ||
                     c.Status == "terminated"));

            if (!hasValidContract)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Bạn chưa có hợp đồng hợp lệ với phòng này nên không thể đánh giá"
                });
            }

            // BƯỚC 5: Kiểm tra người thuê đã đánh giá phòng chưa
            var alreadyReviewed = await _context.Reviews
                .AnyAsync(r =>
                    r.RoomId == request.RoomId &&
                    r.TenantId == request.TenantId);

            if (alreadyReviewed)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Bạn đã đánh giá phòng này rồi"
                });
            }

            // BƯỚC 6: Tạo đánh giá mới
            var review = new Review
            {
                Id = "REV_" + Guid.NewGuid().ToString("N"),
                RoomId = request.RoomId,
                TenantId = request.TenantId,
                Rating = request.Rating,
                Comment = request.Comment.Trim(),
                Status = "visible",
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.Reviews.Add(review);

            await _context.SaveChangesAsync();

            // BƯỚC 7: Trả kết quả thành công
            return Ok(new
            {
                success = true,
                message = "Gửi đánh giá thành công",
                data = new
                {
                    id = review.Id,
                    roomId = review.RoomId,
                    tenantId = review.TenantId,
                    tenantName = tenant.Name,
                    tenantAvatar = tenant.Avatar,
                    rating = review.Rating,
                    comment = review.Comment,
                    status = review.Status,
                    createdAt = review.CreatedAt
                }
            });
        }
    }

    // ============================================
    // DTO: Dữ liệu nhận khi gửi đánh giá
    // ============================================
    public class CreateReviewRequest
    {
        public string RoomId { get; set; } = string.Empty;

        public string TenantId { get; set; } = string.Empty;

        public byte Rating { get; set; }

        public string Comment { get; set; } = string.Empty;
    }
}
