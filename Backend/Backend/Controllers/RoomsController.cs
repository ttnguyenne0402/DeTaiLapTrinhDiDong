using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/rooms")]
    [ApiController]
    public class RoomsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public RoomsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/rooms/{ownerId}?status=all&propertyId=all
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetRooms(string ownerId, [FromQuery] string? status, [FromQuery] string? propertyId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                // Lấy danh sách ID bất động sản thuộc quyền sở hữu của chủ trọ
                var ownerProperties = await _context.Properties
                    .Where(p => targetOwnerIds.Contains(p.OwnerId))
                    .Select(p => new { p.Id, p.Name })
                    .ToListAsync();

                var propertyIds = ownerProperties.Select(p => p.Id).ToList();

                if (!propertyIds.Any())
                {
                    return Ok(new List<RoomDto>());
                }

                var query = _context.Rooms
                    .Include(r => r.Property)
                    .Where(r => propertyIds.Contains(r.PropertyId));

                // Bỏ qua nếu propertyId là placeholder Swagger ("propertyId" hoặc "all")
                if (!OwnerHelper.IsPlaceholder(propertyId, "propertyId"))
                {
                    string cleanPropId = propertyId!.Trim().ToLower();
                    query = query.Where(r => r.PropertyId.ToLower() == cleanPropId);
                }

                // Lọc theo trạng thái phòng (bỏ qua nếu status là "status" hoặc "all")
                if (!OwnerHelper.IsPlaceholder(status, "status"))
                {
                    string s = status!.Trim().ToLower();
                    if (s == "rented" || s.Contains("thuê"))
                    {
                        query = query.Where(r => r.Status == "rented");
                    }
                    else if (s == "empty" || s == "available" || s.Contains("trống"))
                    {
                        query = query.Where(r => r.Status == "available");
                    }
                    else if (s == "maintenance" || s.Contains("trì"))
                    {
                        query = query.Where(r => r.Status == "maintenance");
                    }
                    else
                    {
                        query = query.Where(r => r.Status == status);
                    }
                }

                var rawRooms = await query.OrderBy(r => r.Name).ToListAsync();

                var result = rawRooms.Select(r => new RoomDto
                {
                    Id = r.Id,
                    PropertyId = r.PropertyId,
                    PropertyName = r.Property?.Name ?? "Chưa rõ tòa nhà",
                    Name = r.Name,
                    Area = r.Area,
                    Floor = r.Floor,
                    Price = r.Price,
                    Deposit = r.Deposit,
                    MaxPeople = r.MaxPeople,
                    Status = r.Status,
                    StatusText = r.Status == "rented" ? "Đang cho thuê" : (r.Status == "available" ? "Còn trống" : "Bảo trì"),
                    IsRented = r.Status == "rented",
                    Detail = $"{r.Area} m²" + (r.Floor.HasValue ? $" - Tầng {r.Floor}" : ""),
                    PriceFormatted = $"{r.Price:N0}đ",
                    Images = string.IsNullOrEmpty(r.Images) ? "frontend/assets/images/anhPhongDemo.jpg" : r.Images,
                    Description = r.Description
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                string errorDetails = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách phòng", error = errorDetails });
            }
        }

        // 2. GET: api/owner/rooms/detail/{id}
        [HttpGet("detail/{id}")]
        public async Task<IActionResult> GetRoomDetail(string id)
        {
            try
            {
                var r = await _context.Rooms
                    .Include(x => x.Property)
                    .FirstOrDefaultAsync(x => x.Id == id);

                if (r == null)
                {
                    return NotFound(new { message = "Không tìm thấy phòng trọ" });
                }

                var dto = new RoomDto
                {
                    Id = r.Id,
                    PropertyId = r.PropertyId,
                    PropertyName = r.Property?.Name ?? "",
                    Name = r.Name,
                    Area = r.Area,
                    Floor = r.Floor,
                    Price = r.Price,
                    Deposit = r.Deposit,
                    MaxPeople = r.MaxPeople,
                    Status = r.Status,
                    StatusText = r.Status == "rented" ? "Đang cho thuê" : (r.Status == "available" ? "Còn trống" : "Bảo trì"),
                    IsRented = r.Status == "rented",
                    Detail = $"{r.Area} m²" + (r.Floor.HasValue ? $" - Tầng {r.Floor}" : ""),
                    PriceFormatted = $"{r.Price:N0}đ",
                    Images = string.IsNullOrEmpty(r.Images) ? "frontend/assets/images/anhPhongDemo.jpg" : r.Images,
                    Description = r.Description
                };

                return Ok(dto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy chi tiết phòng", error = ex.Message });
            }
        }

        // 3. POST: api/owner/rooms
        [HttpPost]
        public async Task<IActionResult> CreateRoom([FromBody] CreateRoomDto dto)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.PropertyId) || string.IsNullOrWhiteSpace(dto.Name))
                {
                    return BadRequest(new { message = "Mã bất động sản và tên phòng không được để trống." });
                }

                var property = await _context.Properties.FirstOrDefaultAsync(p => p.Id == dto.PropertyId || p.Id.ToLower() == dto.PropertyId.ToLower());
                if (property == null)
                {
                    property = await _context.Properties.FirstOrDefaultAsync();
                }

                if (property == null)
                {
                    return BadRequest(new { message = "Bất động sản không tồn tại." });
                }

                string validPropertyId = property.Id;
                int targetFloor = dto.Floor ?? 1;
                string rawInputName = dto.Name.Trim();
                string normalizedInputName = rawInputName.ToLower();
                string strippedInputName = normalizedInputName.StartsWith("phòng ")
                    ? normalizedInputName.Substring(6).Trim()
                    : normalizedInputName;

                // Kiểm tra trùng tên phòng trong cùng tòa nhà và cùng tầng (không phân biệt hoa thường)
                var existingRoomsOnFloor = await _context.Rooms
                    .Where(r => r.PropertyId == validPropertyId && (r.Floor ?? 1) == targetFloor)
                    .Select(r => r.Name)
                    .ToListAsync();

                bool isDuplicate = existingRoomsOnFloor.Any(existingName =>
                {
                    string normExisting = (existingName ?? "").Trim().ToLower();
                    string strippedExisting = normExisting.StartsWith("phòng ")
                        ? normExisting.Substring(6).Trim()
                        : normExisting;
                    return normExisting == normalizedInputName || strippedExisting == strippedInputName;
                });

                if (isDuplicate)
                {
                    return BadRequest(new
                    {
                        message = $"Phòng '{rawInputName}' thuộc tầng {targetFloor} đã tồn tại trong {property.Name}. Vui lòng đặt tên khác!"
                    });
                }

                string normalizedStatus = dto.Status.ToLower();
                if (normalizedStatus.Contains("trống") || normalizedStatus == "available" || normalizedStatus == "empty")
                {
                    normalizedStatus = "available";
                }
                else if (normalizedStatus.Contains("thuê") || normalizedStatus == "rented")
                {
                    normalizedStatus = "rented";
                }
                else if (normalizedStatus.Contains("trì") || normalizedStatus == "maintenance")
                {
                    normalizedStatus = "maintenance";
                }
                else
                {
                    normalizedStatus = "available";
                }

                var room = new Room
                {
                    Id = "ROOM_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                    PropertyId = validPropertyId,
                    Name = dto.Name,
                    Area = dto.Area,
                    Floor = dto.Floor ?? 1,
                    Price = dto.Price,
                    Deposit = dto.Deposit ?? dto.Price,
                    MaxPeople = dto.MaxPeople ?? 2,
                    Status = normalizedStatus,
                    Description = dto.Description,
                    Images = string.IsNullOrEmpty(dto.Images) ? "frontend/assets/images/anhPhongDemo.jpg" : dto.Images,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Rooms.Add(room);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm phòng thành công", roomId = room.Id });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi thêm phòng", error });
            }
        }

        // 4. PUT: api/owner/rooms/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateRoom(string id, [FromBody] UpdateRoomDto dto)
        {
            try
            {
                var room = await _context.Rooms
                    .FirstOrDefaultAsync(r => r.Id == id || r.Id.ToLower() == id.ToLower());

                if (room == null)
                {
                    return NotFound(new { message = "Không tìm thấy phòng cần cập nhật" });
                }

                string targetPropertyId = room.PropertyId;
                if (!string.IsNullOrWhiteSpace(dto.PropertyId))
                {
                    var prop = await _context.Properties
                        .FirstOrDefaultAsync(p => p.Id == dto.PropertyId || p.Id.ToLower() == dto.PropertyId.ToLower());
                    if (prop != null)
                    {
                        targetPropertyId = prop.Id;
                    }
                }

                int targetFloor = dto.Floor ?? room.Floor ?? 1;
                string newRoomName = !string.IsNullOrWhiteSpace(dto.Name) ? dto.Name.Trim() : room.Name.Trim();
                string normalizedInputName = newRoomName.ToLower();
                string strippedInputName = normalizedInputName.StartsWith("phòng ")
                    ? normalizedInputName.Substring(6).Trim()
                    : normalizedInputName;

                var otherRoomsOnFloor = await _context.Rooms
                    .Where(r => r.Id != room.Id && r.PropertyId == targetPropertyId && (r.Floor ?? 1) == targetFloor)
                    .Select(r => r.Name)
                    .ToListAsync();

                bool isDuplicate = otherRoomsOnFloor.Any(existingName =>
                {
                    string normExisting = (existingName ?? "").Trim().ToLower();
                    string strippedExisting = normExisting.StartsWith("phòng ")
                        ? normExisting.Substring(6).Trim()
                        : normExisting;
                    return normExisting == normalizedInputName || strippedExisting == strippedInputName;
                });

                if (isDuplicate)
                {
                    return BadRequest(new
                    {
                        message = $"Phòng '{newRoomName}' thuộc tầng {targetFloor} đã tồn tại trong tòa nhà này. Vui lòng đặt tên khác!"
                    });
                }

                room.PropertyId = targetPropertyId;
                if (!string.IsNullOrWhiteSpace(dto.Name)) room.Name = dto.Name.Trim();
                if (dto.Area > 0) room.Area = dto.Area;
                if (dto.Floor.HasValue) room.Floor = dto.Floor;
                if (dto.Price > 0) room.Price = dto.Price;
                if (dto.Deposit.HasValue) room.Deposit = dto.Deposit.Value;
                if (dto.MaxPeople.HasValue) room.MaxPeople = dto.MaxPeople.Value;
                if (dto.Description != null) room.Description = dto.Description;
                if (!string.IsNullOrWhiteSpace(dto.Images)) room.Images = dto.Images;

                if (!string.IsNullOrWhiteSpace(dto.Status))
                {
                    string s = dto.Status.ToLower();
                    if (s.Contains("trống") || s == "available") room.Status = "available";
                    else if (s.Contains("thuê") || s == "rented") room.Status = "rented";
                    else if (s.Contains("trì") || s == "maintenance") room.Status = "maintenance";
                    else room.Status = dto.Status;
                }

                room.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật phòng thành công", roomId = room.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật phòng", error = ex.Message });
            }
        }

        // 5. DELETE: api/owner/rooms/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteRoom(string id)
        {
            try
            {
                var room = await _context.Rooms
                    .Include(r => r.Contracts)
                    .FirstOrDefaultAsync(r => r.Id == id);

                if (room == null)
                {
                    return NotFound(new { message = "Không tìm thấy phòng cần xóa" });
                }

                if (room.Contracts.Any(c => c.Status == "active"))
                {
                    return BadRequest(new { message = "Không thể xóa phòng đang có hợp đồng hoạt động." });
                }

                _context.Rooms.Remove(room);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Xóa phòng thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa phòng", error = ex.Message });
            }
        }
    }
}
