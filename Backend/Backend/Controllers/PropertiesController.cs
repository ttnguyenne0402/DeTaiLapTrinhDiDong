using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/properties")]
    [ApiController]
    public class PropertiesController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public PropertiesController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // GET: api/owner/properties/{ownerId}?status=all
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetProperties(string ownerId, [FromQuery] string? status)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                var query = _context.Properties
                    .Where(p => targetOwnerIds.Contains(p.OwnerId));

                // Xử lý lọc chuẩn xác theo trạng thái (bỏ qua placeholder)
                if (!OwnerHelper.IsPlaceholder(status, "status"))
                {
                    string s = status!.Trim().ToLower();
                    if (s == "active")
                    {
                        query = query.Where(p => p.Status == "active");
                    }
                    else if (s == "maintenance" || s == "inactive")
                    {
                        query = query.Where(p => p.Status == "inactive");
                    }
                    else
                    {
                        query = query.Where(p => p.Status == s);
                    }
                }

                var rawProperties = await query.ToListAsync();

                // Lấy tất cả phòng của các property này trong 1 câu lệnh duy nhất
                var propertyIds = rawProperties.Select(p => p.Id).ToList();
                var allRooms = await _context.Rooms
                    .Where(r => propertyIds.Contains(r.PropertyId))
                    .ToListAsync();

                // Map sang DTO an toàn trên RAM
                var properties = rawProperties.Select(p => new PropertyDto
                {
                    Id = p.Id ?? string.Empty,
                    Name = p.Name ?? string.Empty,
                    Type = p.Type ?? "rooming_house",
                    Address = p.Address ?? string.Empty,
                    District = p.District ?? string.Empty,
                    Ward = p.Ward ?? string.Empty,
                    Latitude = p.Latitude,
                    Longitude = p.Longitude,
                    Description = p.Description ?? string.Empty,
                    TotalRooms = allRooms.Count(r => r.PropertyId == p.Id),
                    RentedRooms = allRooms.Count(r => r.PropertyId == p.Id && r.Status == "rented"),
                    EmptyRooms = allRooms.Count(r => r.PropertyId == p.Id && r.Status == "available"),
                    Status = p.Status == "active" ? "Đang hoạt động" : "Bảo trì",
                    Image = string.IsNullOrEmpty(p.Image) ? "frontend/assets/images/anhPhongDemo.jpg" : p.Image
                }).ToList();

                return Ok(properties);
            }
            catch (Exception ex)
            {
                string errorDetails = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách bất động sản", error = errorDetails });
            }
        }

        // POST: api/owner/properties
        [HttpPost]
        public async Task<IActionResult> CreateProperty([FromBody] CreatePropertyDto dto)
        {
            try
            {
                if (string.IsNullOrEmpty(dto.Name) || string.IsNullOrEmpty(dto.OwnerId))
                {
                    return BadRequest(new { message = "Tên bất động sản và mã chủ trọ không được để trống." });
                }

                if (!dto.Latitude.HasValue || !dto.Longitude.HasValue ||
                    dto.Latitude < -90 || dto.Latitude > 90 ||
                    dto.Longitude < -180 || dto.Longitude > 180)
                {
                    return BadRequest(new { message = "Vui lòng chọn tọa độ hợp lệ trên bản đồ." });
                }

                var newProperty = new Property
                {
                    Id = "PROP_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                    OwnerId = dto.OwnerId,
                    Name = dto.Name,
                    Type = string.IsNullOrEmpty(dto.Type) ? "rooming_house" : dto.Type,
                    Address = dto.Address,
                    District = string.IsNullOrEmpty(dto.District) ? "Chưa rõ" : dto.District,
                    Ward = string.IsNullOrEmpty(dto.Ward) ? "Chưa rõ" : dto.Ward,
                    Latitude = dto.Latitude.Value,
                    Longitude = dto.Longitude.Value,
                    Description = dto.Description,
                    Image = string.IsNullOrEmpty(dto.Image) ? "frontend/assets/images/anhPhongDemo.jpg" : dto.Image,
                    Status = string.IsNullOrEmpty(dto.Status) ? "active" : dto.Status
                };

                _context.Properties.Add(newProperty);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm bất động sản thành công", propertyId = newProperty.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi thêm bất động sản", error = ex.Message });
            }
        }

        // PUT: api/owner/properties/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProperty(string id, [FromBody] UpdatePropertyDto dto)
        {
            try
            {
                var property = await _context.Properties.FirstOrDefaultAsync(p => p.Id == id);
                if (property == null)
                {
                    return NotFound(new { message = "Không tìm thấy bất động sản cần cập nhật." });
                }

                if (string.IsNullOrEmpty(dto.Name))
                {
                    return BadRequest(new { message = "Tên bất động sản không được để trống." });
                }

                property.Name = dto.Name;
                if (!string.IsNullOrEmpty(dto.Type)) property.Type = dto.Type;
                if (!string.IsNullOrEmpty(dto.Address)) property.Address = dto.Address;
                if (!string.IsNullOrEmpty(dto.District)) property.District = dto.District;
                if (!string.IsNullOrEmpty(dto.Ward)) property.Ward = dto.Ward;
                if (dto.Latitude.HasValue) property.Latitude = dto.Latitude.Value;
                if (dto.Longitude.HasValue) property.Longitude = dto.Longitude.Value;
                property.Description = dto.Description;
                if (!string.IsNullOrEmpty(dto.Status)) property.Status = dto.Status;
                if (!string.IsNullOrEmpty(dto.Image)) property.Image = dto.Image;
                property.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Cập nhật bất động sản thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật bất động sản", error = ex.Message });
            }
        }

        // DELETE: api/owner/properties/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProperty(string id)
        {
            try
            {
                var property = await _context.Properties.FirstOrDefaultAsync(p => p.Id == id);
                if (property == null)
                {
                    return NotFound(new { message = "Không tìm thấy bất động sản cần xóa." });
                }

                _context.Properties.Remove(property);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Xóa bất động sản thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa bất động sản", error = ex.Message });
            }
        }
    }
}
