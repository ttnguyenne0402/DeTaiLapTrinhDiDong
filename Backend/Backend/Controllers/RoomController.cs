
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

            return Ok(new
            {
                success = true,
                message = "Lấy thông tin phòng thành công",
                data = room
            });
        }
    }
}
