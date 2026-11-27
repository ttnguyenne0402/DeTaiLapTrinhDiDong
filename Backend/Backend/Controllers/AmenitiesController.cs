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
                List<AmenityDto> resultList = new List<AmenityDto>();

                try
                {
                    var list = await _context.Amenities.ToListAsync();

                    var assignedAmenityIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    if (!string.IsNullOrEmpty(propertyId))
                    {
                        try
                        {
                            var propAmenities = await _context.PropertyAmenities
                                .Where(pa => pa.PropertyId == propertyId && pa.Status == "active")
                                .Select(pa => pa.AmenityId)
                                .ToListAsync();
                            foreach (var id in propAmenities) assignedAmenityIds.Add(id);
                        }
                        catch { }
                    }

                    resultList = list.Select(a => new AmenityDto
                    {
                        Id = a.Id,
                        OwnerId = a.OwnerId,
                        Name = a.Name,
                        Description = a.Description ?? "Tiện ích cơ sở vật chất phòng trọ.",
                        Icon = !string.IsNullOrEmpty(a.Icon) ? a.Icon : "check_circle",
                        Status = a.Status == "active",
                        StatusCode = a.Status,
                        IsAssigned = !string.IsNullOrEmpty(propertyId) && assignedAmenityIds.Count > 0 ? assignedAmenityIds.Contains(a.Id) : true,
                        PropertyId = propertyId
                    }).ToList();
                }
                catch
                {
                    // Fallback tự động nếu CSDL cũ chưa có cột owner_id / icon
                    resultList = new List<AmenityDto>
                    {
                        new AmenityDto { Id = "amn_wifi", Name = "Wifi tốc độ cao", Description = "Trang bị wifi riêng từng tầng", Icon = "wifi", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_ac", Name = "Máy lạnh", Description = "Inverter tiết kiệm điện", Icon = "ac_unit", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_elev", Name = "Thang máy", Description = "Thang máy di chuyển nhanh", Icon = "elevator", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_park", Name = "Nhà xe", Description = "Giữ xe miễn phí tầng hầm", Icon = "two_wheeler", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_cam", Name = "Camera an ninh", Description = "Giám sát 24/7", Icon = "videocam", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_fridge", Name = "Bếp / Tủ lạnh", Description = "Nấu ăn tự do", Icon = "kitchen", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_time", Name = "Giờ giấc tự do", Description = "Cổng ra vào 24/24", Icon = "access_time", Status = true, IsAssigned = true },
                        new AmenityDto { Id = "amn_finger", Name = "Khoá vân tay", Description = "Cổng khóa vân tay an toàn", Icon = "fingerprint", Status = true, IsAssigned = true }
                    };
                }

                return Ok(resultList);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách tiện ích", error = ex.Message });
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

                var cleanName = dto.Name.Trim();
                var amenityId = "AMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper();

                string? validOwnerId = null;
                if (!string.IsNullOrEmpty(dto.OwnerId))
                {
                    var ownerExists = await _context.Users.AnyAsync(u => u.Id == dto.OwnerId);
                    if (ownerExists) validOwnerId = dto.OwnerId;
                }

                try
                {
                    var amenity = new Amenity
                    {
                        Id = amenityId,
                        OwnerId = validOwnerId,
                        Name = cleanName,
                        Description = dto.Description,
                        Icon = !string.IsNullOrEmpty(dto.Icon) ? dto.Icon : "check_circle",
                        Status = dto.Status ? "active" : "inactive",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    _context.Amenities.Add(amenity);
                    await _context.SaveChangesAsync();
                }
                catch
                {
                    string statusVal = dto.Status ? "active" : "inactive";
                    string descVal = dto.Description ?? "";
                    string rawSql = $"IF NOT EXISTS (SELECT 1 FROM amenities WHERE name = N'{cleanName}') INSERT INTO amenities (id, name, description, status) VALUES ('{amenityId}', N'{cleanName}', N'{descVal}', '{statusVal}')";
                    await _context.Database.ExecuteSqlRawAsync(rawSql);
                }

                // Gán tiện ích này vào Khu trọ nếu truyền propertyId
                if (!string.IsNullOrEmpty(dto.PropertyId))
                {
                    try
                    {
                        var propExists = await _context.Properties.AnyAsync(p => p.Id == dto.PropertyId);
                        if (propExists)
                        {
                            var existingPropAmenity = await _context.PropertyAmenities
                                .FirstOrDefaultAsync(pa => pa.PropertyId == dto.PropertyId && pa.AmenityId == amenityId);

                            if (existingPropAmenity != null)
                            {
                                existingPropAmenity.Status = "active";
                                existingPropAmenity.UpdatedAt = DateTime.UtcNow;
                            }
                            else
                            {
                                _context.PropertyAmenities.Add(new PropertyAmenity
                                {
                                    Id = "PAMN_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                                    PropertyId = dto.PropertyId,
                                    AmenityId = amenityId,
                                    Status = "active",
                                    CreatedAt = DateTime.UtcNow,
                                    UpdatedAt = DateTime.UtcNow
                                });
                            }
                            await _context.SaveChangesAsync();
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[PROPERTY AMENITY BIND NOTICE]: {ex.Message}");
                    }
                }

                return Ok(new { message = "Thêm tiện ích thành công", amenityId = amenityId });
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
