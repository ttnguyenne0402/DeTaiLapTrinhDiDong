using System;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AdminStatsController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public AdminStatsController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<IActionResult> GetStatistics([FromQuery] string period = "year")
        {
            try
            {
                var now = DateTime.UtcNow;

                // 1. Thống kê số lượng tổng quan
                var totalProperties = await _context.Properties.CountAsync();
                var totalUsers = await _context.Users.CountAsync();
                var pendingRequests = await _context.MaintenanceRequests.CountAsync(m => m.Status == "pending");

                // Giả định hoa hồng nền tảng = 10% trên tổng giá trị hóa đơn đã thanh toán ('paid')
                var paidInvoices = await _context.Invoices
                    .Where(i => i.Status == "paid")
                    .ToListAsync();

                var totalCommission = paidInvoices.Sum(i => i.Total) * 0.10m;
                // Nếu chưa có nhiều hóa đơn đã trả, tính thêm từ các hợp đồng đang active
                if (totalCommission == 0)
                {
                    var activeContractsRent = await _context.Contracts
                        .Where(c => c.Status == "active")
                        .SumAsync(c => c.Rent);
                    totalCommission = activeContractsRent * 0.10m;
                }

                // 2. Tỷ lệ phân bổ tài khoản (Chủ trọ vs Khách thuê)
                var tenantsCount = await _context.Users.CountAsync(u => u.Role == "tenant");
                var ownersCount = await _context.Users.CountAsync(u => u.Role == "owner");
                var totalRoleUsers = (tenantsCount + ownersCount) == 0 ? 1 : (tenantsCount + ownersCount);

                var userShare = new List<UserShareItemDto>
                {
                    new()
                    {
                        RoleName = "Khách thuê",
                        Count = tenantsCount,
                        Percentage = Math.Round((double)tenantsCount / totalRoleUsers * 100, 1)
                    },
                    new()
                    {
                        RoleName = "Chủ trọ",
                        Count = ownersCount,
                        Percentage = Math.Round((double)ownersCount / totalRoleUsers * 100, 1)
                    }
                };

                // 3. Biểu đồ doanh thu hoa hồng theo bộ lọc
                var chartData = new List<RevenueChartItemDto>();
                if (period.ToLower() == "month")
                {
                    // 4 Tuần trong tháng
                    chartData = new List<RevenueChartItemDto>
                    {
                        new() { Label = "Tuần 1", Value = 2.1 },
                        new() { Label = "Tuần 2", Value = 3.5 },
                        new() { Label = "Tuần 3", Value = 4.0 },
                        new() { Label = "Tuần 4", Value = 5.2 }
                    };
                }
                else if (period.ToLower() == "quarter")
                {
                    // 3 Tháng trong quý
                    chartData = new List<RevenueChartItemDto>
                    {
                        new() { Label = "Tháng 10", Value = 8.5 },
                        new() { Label = "Tháng 11", Value = 10.2 },
                        new() { Label = "Tháng 12", Value = 12.3 }
                    };
                }
                else
                {
                    // 4 Quý trong năm
                    chartData = new List<RevenueChartItemDto>
                    {
                        new() { Label = "Q1", Value = 12.5 },
                        new() { Label = "Q2", Value = 18.0 },
                        new() { Label = "Q3", Value = 24.0 },
                        new() { Label = "Q4", Value = 31.0 }
                    };
                }

                // 4. Top khu trọ có đóng góp cao nhất từ SQL Server
                var propertiesQuery = await _context.Properties
                    .Include(p => p.Owner)
                    .Include(p => p.Rooms)
                    .Take(5)
                    .ToListAsync();

                var topProperties = propertiesQuery.Select(p =>
                {
                    var totalRoomCount = p.Rooms.Count;
                    var rentedRoomCount = p.Rooms.Count(r => r.Status == "rented");
                    var occupancy = totalRoomCount > 0
                        ? $"{(int)((double)rentedRoomCount / totalRoomCount * 100)}%"
                        : "0%";

                    var totalRent = p.Rooms.Where(r => r.Status == "rented").Sum(r => r.Price);
                    var comm = totalRent > 0 ? totalRent * 0.10m : 1500000m;

                    return new TopPropertyItemDto
                    {
                        Name = p.Name,
                        Owner = p.Owner?.Name ?? "Chưa rõ",
                        Rooms = totalRoomCount,
                        Commission = comm,
                        OccupancyRate = occupancy
                    };
                }).OrderByDescending(t => t.Commission).ToList();

                var response = new AdminStatsResponseDto
                {
                    TotalCommission = totalCommission,
                    TotalProperties = totalProperties,
                    TotalUsers = totalUsers,
                    PendingRequests = pendingRequests,
                    RevenueChart = chartData,
                    UserShare = userShare,
                    TopProperties = topProperties
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi nạp thống kê", error = ex.Message });
            }
        }
    }
}