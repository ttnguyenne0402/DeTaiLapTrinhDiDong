
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RoomController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public RoomController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // GET: api/Room
        // GET: api/Room?keyword=Quan 1
        // GET: api/Room?maxPrice=3000000&minArea=15&maxArea=30
        // GET: api/Room?amenity=May lanh
        [HttpGet]
        public async Task<IActionResult> GetRooms(
            [FromQuery] string? keyword,
            [FromQuery] decimal? maxPrice,
            [FromQuery] decimal? minArea,
            [FromQuery] decimal? maxArea,
            [FromQuery] string? amenity)
        {
            var query = _context.Rooms
                .AsNoTracking()
                .Include(r => r.Property)
                .Include(r => r.RoomAmenities)
                    .ThenInclude(ra => ra.Amenity)
                .AsQueryable();

            // Chỉ lấy phòng đang trống
            query = query.Where(r => r.Status == "available");

            // Tìm kiếm theo tên phòng, tên khu trọ,
            // địa chỉ, quận và phường
            if (!string.IsNullOrWhiteSpace(keyword))
            {
                string search = keyword.Trim();

                query = query.Where(r =>
                    r.Name.Contains(search) ||
                    r.Property.Name.Contains(search) ||
                    r.Property.Address.Contains(search) ||
                    r.Property.District.Contains(search) ||
                    r.Property.Ward.Contains(search));
            }

            // Lọc giá tối đa
            if (maxPrice.HasValue)
            {
                query = query.Where(r => r.Price <= maxPrice.Value);
            }

            // Lọc diện tích tối thiểu
            if (minArea.HasValue)
            {
                query = query.Where(r => r.Area >= minArea.Value);
            }

            // Lọc diện tích tối đa
            if (maxArea.HasValue)
            {
                query = query.Where(r => r.Area <= maxArea.Value);
            }

            // Lọc theo tiện ích
            if (!string.IsNullOrWhiteSpace(amenity))
            {
                string amenityName = amenity.Trim();

                query = query.Where(r =>
                    r.RoomAmenities.Any(ra =>
                        ra.Amenity.Name.Contains(amenityName)));
            }

            var rooms = await query
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    id = r.Id,
                    propertyId = r.PropertyId,
                    propertyName = r.Property.Name,
                    title = r.Name,
                    street = r.Property.Address,
                    district = r.Property.District,
                    ward = r.Property.Ward,
                    latitude = r.Property.Latitude,
                    longitude = r.Property.Longitude,
                    area = r.Area,
                    price = r.Price,
                    deposit = r.Deposit,
                    maxPeople = r.MaxPeople,
                    status = r.Status,
                    amenities = r.RoomAmenities
                        .Select(ra => ra.Amenity.Name)
                        .ToList(),
                    image = r.Images
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                message = "Lấy danh sách phòng thành công",
                data = rooms
            });
        }

        // GET: api/Room/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetRoomById(string id)
        {
            var room = await _context.Rooms
                .AsNoTracking()
                .Include(r => r.Property)
                .Include(r => r.RoomAmenities)
                    .ThenInclude(ra => ra.Amenity)
                .Where(r => r.Id == id && r.Status == "available")
                .Select(r => new
                {
                    id = r.Id,

                    // Thông tin khu trọ
                    propertyId = r.PropertyId,
                    propertyName = r.Property.Name,
                    street = r.Property.Address,
                    district = r.Property.District,
                    ward = r.Property.Ward,
                    latitude = r.Property.Latitude,
                    longitude = r.Property.Longitude,

                    // Thông tin phòng
                    title = r.Name,
                    floor = r.Floor,
                    area = r.Area,
                    price = r.Price,
                    deposit = r.Deposit,
                    maxPeople = r.MaxPeople,
                    status = r.Status,
                    description = r.Description,

                    // Tiện ích
                    amenities = r.RoomAmenities.Any()
                        ? r.RoomAmenities.Select(ra => ra.Amenity.Name).ToList()
                        : (r.Property.PropertyAmenities.Any(pa => pa.Status == "active")
                            ? _context.PropertyAmenities.Where(pa => pa.PropertyId == r.PropertyId && pa.Status == "active").Select(pa => pa.Amenity.Name).ToList()
                            : new List<string> { "Wifi tốc độ cao", "Máy lạnh", "Thang máy", "Chỗ để xe máy", "Camera an ninh 24/7", "Giờ giấc tự do", "Khóa vân tay" }),

                    // Dịch vụ đi kèm
                    services = _context.PropertyServices
                        .Where(ps => ps.PropertyId == r.PropertyId && ps.Status == "active")
                        .Select(ps => new
                        {
                            name = ps.Service.Name,
                            price = ps.Price,
                            unit = ps.Service.Unit
                        }).ToList(),

                    // Hình ảnh
                    image = r.Images
                })
                .FirstOrDefaultAsync();

            if (room == null)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không tìm thấy phòng hoặc phòng hiện không còn trống"
                });
            }

            // 1. Tự động tăng lượt xem của bài đăng khi khách hàng xem chi tiết phòng
            var post = await _context.RentalPosts.FirstOrDefaultAsync(p => p.RoomId == id);
            if (post != null)
            {
                post.Views += 1;
                try
                {
                    await _context.SaveChangesAsync();
                }
                catch
                {
                    // Tránh chặn luồng xem phòng nếu có xung đột ghi
                }
            }

            return Ok(new
            {
                success = true,
                message = "Lấy thông tin phòng thành công",
                data = room
            });
        }

        // POST: api/Room/{id}/favorite?userId={userId}
        [HttpPost("{id}/favorite")]
        public async Task<IActionResult> ToggleFavorite(string id, [FromQuery] string? userId)
        {
            try
            {
                var room = await _context.Rooms.FindAsync(id);
                if (room == null)
                {
                    return NotFound(new { success = false, message = "Không tìm thấy phòng." });
                }

                // Tìm user hợp lệ để liên kết (chỉ khách hàng / tenant mới có thể yêu thích)
                User? user = null;
                if (!string.IsNullOrWhiteSpace(userId))
                {
                    user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                    if (user != null && (user.Role == "owner" || user.Role == "landlord"))
                    {
                        return BadRequest(new { success = false, message = "Chủ trọ không thể tự thích bài đăng của mình." });
                    }
                }

                if (user == null)
                {
                    user = await _context.Users.FirstOrDefaultAsync(u => u.Role == "tenant" || u.Role == "user")
                           ?? await _context.Users.FirstOrDefaultAsync();
                }

                if (user == null)
                {
                    return BadRequest(new { success = false, message = "Không xác định được người dùng." });
                }

                var existing = await _context.Favorites.FirstOrDefaultAsync(f => f.RoomId == id && f.UserId == user.Id);
                bool isFavorite;
                if (existing != null)
                {
                    _context.Favorites.Remove(existing);
                    isFavorite = false;
                }
                else
                {
                    var newFav = new Favorite
                    {
                        Id = "FAV_" + Guid.NewGuid().ToString("N").Substring(0, 10).ToUpper(),
                        RoomId = id,
                        UserId = user.Id,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.Favorites.Add(newFav);
                    isFavorite = true;
                }

                await _context.SaveChangesAsync();

                int likesCount = await _context.Favorites.CountAsync(f => f.RoomId == id);
                return Ok(new
                {
                    success = true,
                    isFavorite,
                    likesCount,
                    message = isFavorite ? "Đã thêm vào yêu thích" : "Đã bỏ khỏi yêu thích"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = ex.Message });
            }
        }
    }
}
