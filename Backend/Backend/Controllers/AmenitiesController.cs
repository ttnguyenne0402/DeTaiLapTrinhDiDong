using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Backend.Controllers
{
    [Route("api/owner/amenities")]
    [ApiController]
    public class AmenitiesController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public AmenitiesController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/amenities/{ownerId}?propertyId=...
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetAmenities(string ownerId, [FromQuery] string? propertyId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                var query = _context.Amenities
                    .Include(a => a.PropertyAmenities)
                    .Where(a => a.OwnerId == null || targetOwnerIds.Contains(a.OwnerId))
                    .OrderBy(a => a.CreatedAt);

                var list = await query.ToListAsync();

                // Lấy danh sách amenity_id đã được gán cho propertyId nếu có
                var assignedAmenityIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                if (!string.IsNullOrEmpty(propertyId))
                {
                    var propAmenities = await _context.PropertyAmenities
                        .Where(pa => pa.PropertyId == propertyId && pa.Status == "active")
                        .Select(pa => pa.AmenityId)
                        .ToListAsync();
                    foreach (var id in propAmenities) assignedAmenityIds.Add(id);
                }

                var result = list.Select(a => new AmenityDto
                {
                    Id = a.Id,
                    OwnerId = a.OwnerId,
                    Name = a.Name,
                    Description = a.Description ?? "Tiện ích cơ sở vật chất phòng trọ.",
                    Icon = !string.IsNullOrEmpty(a.Icon) ? a.Icon : "check_circle",
                    Status = a.Status == "active",
                    StatusCode = a.Status,
                    IsAssigned = !string.IsNullOrEmpty(propertyId) ? assignedAmenityIds.Contains(a.Id) : true,
                    PropertyId = propertyId
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách tiện ích", error });
            }
        }

        // 2. POST: api/owner/amenities
        [HttpPost]
        public async Task<IActionResult> CreateAmenity([FromBody] CreateAmenityDto dto)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.Name))
                {
                    return BadRequest(new { message = "Tên tiện ích không được để trống." });
                }

                var amenityId = "AMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper();

                var amenity = new Amenity
                {
                    Id = amenityId,
                    OwnerId = dto.OwnerId,
                    Name = dto.Name.Trim(),
                    Description = dto.Description,
                    Icon = !string.IsNullOrEmpty(dto.Icon) ? dto.Icon : "check_circle",
                    Status = dto.Status ? "active" : "inactive",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Amenities.Add(amenity);

                // Nếu có chỉ định propertyId, tự động gán tiện ích này vào khu trọ đó
                if (!string.IsNullOrEmpty(dto.PropertyId))
                {
                    var propAmenity = new PropertyAmenity
                    {
                        Id = "PAMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                        PropertyId = dto.PropertyId,
                        AmenityId = amenity.Id,
                        Status = dto.Status ? "active" : "inactive",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _context.PropertyAmenities.Add(propAmenity);
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm tiện ích thành công", amenityId = amenity.Id });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi thêm tiện ích mới", error });
            }
        }

        // 3. PUT: api/owner/amenities/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateAmenity(string id, [FromBody] UpdateAmenityDto dto)
        {
            try
            {
                var amenity = await _context.Amenities.FirstOrDefaultAsync(a => a.Id == id || a.Id.ToLower() == id.ToLower());
                if (amenity == null)
                {
                    return NotFound(new { message = "Không tìm thấy tiện ích." });
                }

                if (!string.IsNullOrWhiteSpace(dto.Name)) amenity.Name = dto.Name.Trim();
                if (dto.Description != null) amenity.Description = dto.Description;
                if (!string.IsNullOrWhiteSpace(dto.Icon)) amenity.Icon = dto.Icon;
                amenity.Status = dto.Status ? "active" : "inactive";
                amenity.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật tiện ích thành công" });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi cập nhật tiện ích", error });
            }
        }

        // 4. DELETE: api/owner/amenities/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteAmenity(string id)
        {
            try
            {
                var amenity = await _context.Amenities
                    .Include(a => a.PropertyAmenities)
                    .Include(a => a.RoomAmenities)
                    .FirstOrDefaultAsync(a => a.Id == id || a.Id.ToLower() == id.ToLower());

                if (amenity == null)
                {
                    return NotFound(new { message = "Không tìm thấy tiện ích." });
                }

                _context.PropertyAmenities.RemoveRange(amenity.PropertyAmenities);
                _context.RoomAmenities.RemoveRange(amenity.RoomAmenities);
                _context.Amenities.Remove(amenity);

                await _context.SaveChangesAsync();
                return Ok(new { message = "Xóa tiện ích thành công" });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi xóa tiện ích", error });
            }
        }

        // 5. POST: api/owner/amenities/property/{propertyId}/sync
        [HttpPost("property/{propertyId}/sync")]
        public async Task<IActionResult> SyncPropertyAmenities(string propertyId, [FromBody] List<string> amenityIds)
        {
            try
            {
                var property = await _context.Properties.FindAsync(propertyId);
                if (property == null)
                {
                    return NotFound(new { message = "Không tìm thấy bất động sản." });
                }

                var existing = await _context.PropertyAmenities
                    .Where(pa => pa.PropertyId == propertyId)
                    .ToListAsync();

                var requestedIds = new HashSet<string>(amenityIds ?? new List<string>(), StringComparer.OrdinalIgnoreCase);

                // Cập nhật trạng thái những cái cũ
                foreach (var item in existing)
                {
                    bool shouldBeActive = requestedIds.Contains(item.AmenityId);
                    item.Status = shouldBeActive ? "active" : "inactive";
                    item.UpdatedAt = DateTime.UtcNow;
                    requestedIds.Remove(item.AmenityId);
                }

                // Thêm những cái mới chưa từng có
                foreach (var newAmenityId in requestedIds)
                {
                    _context.PropertyAmenities.Add(new PropertyAmenity
                    {
                        Id = "PAMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                        PropertyId = propertyId,
                        AmenityId = newAmenityId,
                        Status = "active",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    });
                }

                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã cập nhật danh sách tiện ích cho khu trọ" });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi đồng bộ tiện ích khu trọ", error });
            }
        }

        // 6. PUT: api/owner/amenities/property/{propertyId}/toggle/{amenityId}
        [HttpPut("property/{propertyId}/toggle/{amenityId}")]
        public async Task<IActionResult> TogglePropertyAmenity(string propertyId, string amenityId)
        {
            try
            {
                var propAmenity = await _context.PropertyAmenities
                    .FirstOrDefaultAsync(pa => pa.PropertyId == propertyId && pa.AmenityId == amenityId);

                if (propAmenity == null)
                {
                    // Nếu chưa có, tạo mới với status = active
                    _context.PropertyAmenities.Add(new PropertyAmenity
                    {
                        Id = "PAMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                        PropertyId = propertyId,
                        AmenityId = amenityId,
                        Status = "active",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    });
                    await _context.SaveChangesAsync();
                    return Ok(new { message = "Đã bật tiện ích cho khu trọ", status = "active", isAssigned = true });
                }
                else
                {
                    propAmenity.Status = propAmenity.Status == "active" ? "inactive" : "active";
                    propAmenity.UpdatedAt = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                    return Ok(new { message = "Đã cập nhật trạng thái tiện ích", status = propAmenity.Status, isAssigned = propAmenity.Status == "active" });
                }
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi đổi trạng thái tiện ích", error });
            }
        }
    }
}
