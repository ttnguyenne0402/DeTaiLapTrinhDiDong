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
                    Address = p.Address ?? string.Empty,
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

                var newProperty = new Property
                {
                    Id = "PROP_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                    OwnerId = dto.OwnerId,
                    Name = dto.Name,
                    Type = string.IsNullOrEmpty(dto.Type) ? "rooming_house" : dto.Type,
                    Address = dto.Address,
                    District = string.IsNullOrEmpty(dto.District) ? "Chưa rõ" : dto.District,
                    Ward = string.IsNullOrEmpty(dto.Ward) ? "Chưa rõ" : dto.Ward,
                    Description = dto.Description,
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
    }
}