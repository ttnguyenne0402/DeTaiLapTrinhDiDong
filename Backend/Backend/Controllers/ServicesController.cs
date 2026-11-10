using Backend.DT0s;
using Backend.Helpers;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/owner/services")]
    [ApiController]
    public class ServicesController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public ServicesController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. GET: api/owner/services/{ownerId}
        [HttpGet("{ownerId}")]
        public async Task<IActionResult> GetServices(string ownerId)
        {
            try
            {
                var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);

                // Lấy tất cả dịch vụ của chủ trọ này hoặc dịch vụ mặc định hệ thống (OwnerId == null)
                var services = await _context.Services
                    .Include(s => s.PropertyServices)
                    .Where(s => s.OwnerId == null || targetOwnerIds.Contains(s.OwnerId))
                    .OrderBy(s => s.CreatedAt)
                    .ToListAsync();

                // Lấy các thuộc tính bất động sản của chủ trọ để đối chiếu giá dịch vụ
                var ownerPropertyIds = await _context.Properties
                    .Where(p => targetOwnerIds.Contains(p.OwnerId))
                    .Select(p => p.Id)
                    .ToListAsync();

                var result = services.Select(s =>
                {
                    // Lấy giá từ bảng services hoặc PropertyService gần nhất
                    var propService = s.PropertyServices
                        .FirstOrDefault(ps => ownerPropertyIds.Contains(ps.PropertyId))
                        ?? s.PropertyServices.FirstOrDefault();

                    decimal price = s.Price > 0 ? s.Price : (propService?.Price ?? 0);

                    // Lấy icon đã lưu hoặc tự suy đoán icon dựa theo tên dịch vụ
                    string iconName = !string.IsNullOrEmpty(s.Icon) ? s.Icon : DetermineIcon(s.Name);

                    // Phân biệt dịch vụ bắt buộc dựa trực tiếp vào cấu hình database
                    bool isMandatory = s.IsMandatory;

                    return new ServiceDto
                    {
                        Id = s.Id,
                        OwnerId = s.OwnerId,
                        Name = s.Name,
                        Price = price,
                        PriceFormatted = $"{price:N0}".Replace(",", "."),
                        Unit = s.Unit,
                        IsMandatory = isMandatory,
                        Status = s.Status == "active",
                        StatusCode = s.Status,
                        Description = s.Description ?? "Dịch vụ tính theo nhu cầu sử dụng thực tế.",
                        Icon = iconName
                    };
                }).ToList();

                return Ok(result);
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách dịch vụ", error });
            }
        }

        // 2. POST: api/owner/services
        [HttpPost]
        public async Task<IActionResult> CreateService([FromBody] CreateServiceDto dto)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.Name) || string.IsNullOrWhiteSpace(dto.Unit))
                {
                    return BadRequest(new { message = "Tên dịch vụ và đơn vị tính không được để trống." });
                }

                var serviceId = "SRV_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper();

                var service = new Service
                {
                    Id = serviceId,
                    OwnerId = dto.OwnerId,
                    Name = dto.Name,
                    Unit = dto.Unit,
                    Price = dto.Price,
                    IsMandatory = dto.IsMandatory,
                    Icon = string.IsNullOrEmpty(dto.Icon) ? DetermineIcon(dto.Name) : dto.Icon,
                    Description = dto.Description,
                    Status = dto.Status ? "active" : "inactive",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                _context.Services.Add(service);

                // Nếu có chỉ định propertyId hoặc chủ trọ có bất động sản, tạo kèm bản ghi PropertyService để lưu đơn giá
                var targetPropertyIds = new List<string>();
                if (!string.IsNullOrEmpty(dto.PropertyId))
                {
                    targetPropertyIds.Add(dto.PropertyId);
                }
                else if (!string.IsNullOrEmpty(dto.OwnerId))
                {
                    targetPropertyIds = await _context.Properties
                        .Where(p => p.OwnerId == dto.OwnerId)
                        .Select(p => p.Id)
                        .ToListAsync();
                }

                foreach (var propId in targetPropertyIds)
                {
                    var propService = new PropertyService
                    {
                        Id = "PSRV_" + Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                        PropertyId = propId,
                        ServiceId = service.Id,
                        Price = dto.Price,
                        Status = dto.Status ? "active" : "inactive",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _context.PropertyServices.Add(propService);
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Thêm dịch vụ thành công", serviceId = service.Id });
            }
            catch (Exception ex)
            {
                string error = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
                return StatusCode(500, new { message = "Lỗi khi thêm dịch vụ mới", error });
            }
        }

        // 3. PUT: api/owner/services/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateService(string id, [FromBody] UpdateServiceDto dto)
        {
            try
            {
                var service = await _context.Services
                    .Include(s => s.PropertyServices)
                    .FirstOrDefaultAsync(s => s.Id == id || s.Id.ToLower() == id.ToLower());

                if (service == null)
                {
                    return NotFound(new { message = "Không tìm thấy dịch vụ cần cập nhật." });
                }

                if (!string.IsNullOrWhiteSpace(dto.Name)) service.Name = dto.Name;
                if (!string.IsNullOrWhiteSpace(dto.Unit)) service.Unit = dto.Unit;
                if (!string.IsNullOrWhiteSpace(dto.Description)) service.Description = dto.Description;
                service.Price = dto.Price;
                service.IsMandatory = dto.IsMandatory;
                if (!string.IsNullOrWhiteSpace(dto.Icon)) service.Icon = dto.Icon;
                service.Status = dto.Status ? "active" : "inactive";
                service.UpdatedAt = DateTime.UtcNow;

                // Cập nhật giá trên các PropertyServices liên quan
                foreach (var ps in service.PropertyServices)
                {
                    ps.Price = dto.Price;
                    ps.Status = service.Status;
                    ps.UpdatedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();
                return Ok(new { message = "Cập nhật dịch vụ thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật dịch vụ", error = ex.Message });
            }
        }

        // 4. PUT: api/owner/services/{id}/toggle-status
        [HttpPut("{id}/toggle-status")]
        public async Task<IActionResult> ToggleServiceStatus(string id)
        {
            try
            {
                var service = await _context.Services
                    .Include(s => s.PropertyServices)
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (service == null)
                {
                    return NotFound(new { message = "Không tìm thấy dịch vụ." });
                }

                service.Status = service.Status == "active" ? "inactive" : "active";
                service.UpdatedAt = DateTime.UtcNow;

                foreach (var ps in service.PropertyServices)
                {
                    ps.Status = service.Status;
                    ps.UpdatedAt = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đổi trạng thái dịch vụ thành công", status = service.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi chuyển trạng thái dịch vụ", error = ex.Message });
            }
        }

        // 5. DELETE: api/owner/services/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteService(string id)
        {
            try
            {
                var service = await _context.Services
                    .Include(s => s.PropertyServices)
                    .Include(s => s.ContractServices)
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (service == null)
                {
                    return NotFound(new { message = "Không tìm thấy dịch vụ." });
                }

                if (service.ContractServices.Any())
                {
                    return BadRequest(new { message = "Không thể xóa dịch vụ đang được sử dụng trong hợp đồng thuê phòng." });
                }

                _context.PropertyServices.RemoveRange(service.PropertyServices);
                _context.Services.Remove(service);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Xóa dịch vụ thành công" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi xóa dịch vụ", error = ex.Message });
            }
        }

        private static string DetermineIcon(string name)
        {
            string lower = name.ToLower();
            if (lower.Contains("điện")) return "bolt";
            if (lower.Contains("nước")) return "water_drop";
            if (lower.Contains("wifi") || lower.Contains("mạng") || lower.Contains("internet")) return "wifi";
            if (lower.Contains("rác") || lower.Contains("vệ sinh")) return "cleaning_services";
            if (lower.Contains("thang máy")) return "elevator";
            if (lower.Contains("xe") || lower.Contains("gửi xe")) return "two_wheeler";
            if (lower.Contains("an ninh") || lower.Contains("bảo vệ")) return "security";
            if (lower.Contains("giặt")) return "local_laundry_service";
            return "bolt";
        }
    }
}

