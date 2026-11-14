using System.Security.Claims;
using Backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers;

[ApiController]
[Route("api/tenant-utilities")]
[Authorize(Roles = "tenant")]
public sealed class TenantUtilitiesController : ControllerBase
{
    private readonly QuanLyPhongTroContext _context;

    public TenantUtilitiesController(QuanLyPhongTroContext context)
    {
        _context = context;
    }

    [HttpGet("mine")]
    public async Task<IActionResult> GetMyUtilityHistory(CancellationToken cancellationToken)
    {
        var tenantId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(tenantId)) return Unauthorized();

        var contract = await _context.Contracts
            .Include(c => c.Room)
                .ThenInclude(r => r.Property)
            .Where(c => c.TenantId == tenantId && c.Status == "active")
            .OrderByDescending(c => c.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (contract == null)
        {
            return NotFound(new { message = "Bạn chưa có hợp đồng thuê đang hiệu lực." });
        }

        var readings = await _context.UtilityReadings
            .Where(r => r.RoomId == contract.RoomId)
            .OrderByDescending(r => r.Month)
            .Take(12)
            .ToListAsync(cancellationToken);

        var readingData = readings.Select(r => new
            {
                id = r.Id,
                month = r.Month.ToString("MM/yyyy"),
                monthNumber = r.Month.Month,
                year = r.Month.Year,
                electricOld = r.ElectricityOld,
                electricNew = r.ElectricityNew,
                electricUsage = Math.Max(0, r.ElectricityNew - r.ElectricityOld),
                electricPrice = r.ElectricityPrice,
                electricCost = Math.Max(0, r.ElectricityNew - r.ElectricityOld) * r.ElectricityPrice,
                waterOld = r.WaterOld,
                waterNew = r.WaterNew,
                waterUsage = Math.Max(0, r.WaterNew - r.WaterOld),
                waterPrice = r.WaterPrice,
                waterCost = Math.Max(0, r.WaterNew - r.WaterOld) * r.WaterPrice,
                totalCost = Math.Max(0, r.ElectricityNew - r.ElectricityOld) * r.ElectricityPrice +
                            Math.Max(0, r.WaterNew - r.WaterOld) * r.WaterPrice,
                recordedAt = r.CreatedAt
            })
            .ToList();

        return Ok(new
        {
            roomName = contract.Room.Name,
            propertyName = contract.Room.Property.Name,
            contractStatus = contract.Status,
            readings = readingData
        });
    }
}
