using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Backend.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OwnerInvoicesController : ControllerBase
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerInvoicesController(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // GET: /api/OwnerInvoices/active-contracts?propertyId=...
        [HttpGet("active-contracts")]
        public async Task<IActionResult> GetActiveContracts([FromQuery] string? propertyId)
        {
            try
            {
                var query = _context.Contracts
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                    .Include(c => c.Tenant)
                    .Where(c => c.Status == "active");

                // Lọc theo khu trọ nếu có truyền propertyId
                if (!string.IsNullOrEmpty(propertyId))
                {
                    query = query.Where(c => c.Room != null && c.Room.PropertyId == propertyId);
                }

                var contracts = await query
                    .Select(c => new ActiveContractForBillingDto
                    {
                        ContractId = c.Id,
                        ContractCode = c.ContractCode,
                        PropertyId = c.Room.PropertyId,
                        PropertyName = c.Room.Property != null ? c.Room.Property.Name : "Khu trọ",
                        RoomName = c.Room != null ? c.Room.Name : "Phòng",
                        TenantName = c.Tenant != null ? c.Tenant.Name : "Khách thuê",
                        TenantPhone = c.Tenant != null ? (c.Tenant.Phone ?? "") : ""
                    })
                    .ToListAsync();

                return Ok(contracts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp danh sách phòng", error = ex.Message });
            }
        }

        // 1. GET: /api/OwnerInvoices?month=8&year=2026&search=
        // Lấy danh sách hóa đơn và tổng quan tài chính theo tháng
        [HttpGet]
        public async Task<IActionResult> GetMonthlyInvoices(
            [FromQuery] int? month,
            [FromQuery] int? year,
            [FromQuery] string? search)
        {
            try
            {
                var targetMonth = month ?? DateTime.UtcNow.Month;
                var targetYear = year ?? DateTime.UtcNow.Year;

                var contracts = await _context.Contracts
                    .Include(c => c.Room)
                    .Include(c => c.Tenant)
                    .Include(c => c.Invoices)
                    .Where(c => c.Status == "active")
                    .ToListAsync();

                var listItems = new List<InvoiceListItemDto>();
                decimal totalPaid = 0;
                decimal totalOutstanding = 0;

                foreach (var ctr in contracts)
                {
                    var inv = ctr.Invoices.FirstOrDefault(i =>
                        i.BillingMonth.Month == targetMonth && i.BillingMonth.Year == targetYear);

                    if (inv != null)
                    {
                        var status = inv.Status ?? "unpaid";
                        var total = inv.Total;

                        if (status == "paid")
                        {
                            totalPaid += total;
                        }
                        else if (status != "draft" && status != "cancelled")
                        {
                            totalOutstanding += total;
                        }

                        var dueDateDt = inv.DueDate.ToDateTime(TimeOnly.MinValue);

                        listItems.Add(new InvoiceListItemDto
                        {
                            Id = inv.Id,
                            Code = inv.InvoiceCode,
                            Room = ctr.Room?.Name ?? "Phòng",
                            Tenant = ctr.Tenant?.Name ?? "Khách thuê",
                            Phone = ctr.Tenant?.Phone ?? "",
                            DueDate = dueDateDt,
                            Total = total,
                            Status = status,
                            PaymentInfo = status == "paid" ? "VietQR Napas 247 (Đã thanh toán)" : ""
                        });
                    }
                }

                if (!string.IsNullOrWhiteSpace(search))
                {
                    var kw = search.Trim().ToLower();
                    listItems = listItems.Where(x =>
                        x.Room.ToLower().Contains(kw) ||
                        x.Code.ToLower().Contains(kw) ||
                        x.Tenant.ToLower().Contains(kw)
                    ).ToList();
                }

                return Ok(new MonthlyInvoiceSummaryDto
                {
                    Month = targetMonth,
                    Year = targetYear,
                    TotalPaid = totalPaid,
                    TotalOutstanding = totalOutstanding,
                    Invoices = listItems
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy danh sách hóa đơn", error = ex.Message });
            }
        }

        // 2. GET: /api/OwnerInvoices/previous-reading/{contractId}
        [HttpGet("previous-reading/{contractId}")]
        public async Task<IActionResult> GetPreviousReading(string contractId)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.Room)
                    .Include(c => c.Tenant)
                    .Include(c => c.ContractServices)
                        .ThenInclude(cs => cs.Service)
                    .FirstOrDefaultAsync(c => c.Id == contractId || c.ContractCode == contractId);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                // Tìm lần ghi điện nước gần nhất theo RoomId và sắp xếp giảm dần theo Month
                var lastReading = await _context.UtilityReadings
                    .Where(u => u.RoomId == contract.RoomId)
                    .OrderByDescending(u => u.Month)
                    .FirstOrDefaultAsync();

                // Nếu đã có lần chốt số trước -> Lấy số mới của lần trước làm số cũ kỳ này
                // Nếu chưa từng có -> Lấy số ban đầu trong hợp đồng
                decimal oldElectric = lastReading != null
                    ? lastReading.ElectricityNew
                    : contract.InitialElectricityReading;

                decimal oldWater = lastReading != null
                    ? lastReading.WaterNew
                    : contract.InitialWaterReading;

                decimal electricPrice = 3800;
                decimal waterPrice = 25000;

                var otherServices = new List<ContractServiceItemDto>();

                foreach (var cs in contract.ContractServices)
                {
                    var sName = cs.Service?.Name?.ToLower() ?? "";
                    if (sName.Contains("điện"))
                    {
                        electricPrice = cs.UnitPrice;
                    }
                    else if (sName.Contains("nước"))
                    {
                        waterPrice = cs.UnitPrice;
                    }
                    else
                    {
                        otherServices.Add(new ContractServiceItemDto
                        {
                            ServiceId = cs.ServiceId,
                            Name = cs.Service?.Name ?? "Dịch vụ",
                            Unit = cs.Service?.Unit ?? "tháng",
                            Price = cs.UnitPrice
                        });
                    }
                }

                return Ok(new PreviousReadingDto
                {
                    ContractId = contract.Id,
                    RoomName = contract.Room?.Name ?? "Phòng trọ",
                    TenantName = contract.Tenant?.Name ?? "Khách thuê",
                    TenantPhone = contract.Tenant?.Phone ?? "",
                    RentPrice = contract.Rent,
                    OldElectric = oldElectric,
                    OldWater = oldWater,
                    ElectricUnitPrice = electricPrice,
                    WaterUnitPrice = waterPrice,
                    OtherServices = otherServices
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp chỉ số kỳ trước", error = ex.Message });
            }
        }

        // 3. POST: /api/OwnerInvoices (Tính toán cước & Lập hóa đơn mới)
        [HttpPost]
        public async Task<IActionResult> CreateInvoice([FromBody] CreateInvoiceRequest req)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.Room)
                    .Include(c => c.ContractServices)
                        .ThenInclude(cs => cs.Service)
                    .FirstOrDefaultAsync(c => c.Id == req.ContractId);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                decimal oldElectric = contract.InitialElectricityReading;
                decimal oldWater = contract.InitialWaterReading;

                decimal electricUnitPrice = 3800;
                decimal waterUnitPrice = 25000;
                decimal totalServiceAmount = 0;

                foreach (var cs in contract.ContractServices)
                {
                    var name = cs.Service?.Name?.ToLower() ?? "";
                    if (name.Contains("điện")) electricUnitPrice = cs.UnitPrice;
                    else if (name.Contains("nước")) waterUnitPrice = cs.UnitPrice;
                    else totalServiceAmount += cs.UnitPrice;
                }

                decimal electricUsage = Math.Max(0, req.NewElectric - oldElectric);
                decimal waterUsage = Math.Max(0, req.NewWater - oldWater);

                decimal electricAmount = electricUsage * electricUnitPrice;
                decimal waterAmount = waterUsage * waterUnitPrice;
                decimal rentAmount = contract.Rent;

                decimal subtotal = rentAmount + electricAmount + waterAmount + totalServiceAmount;
                decimal total = Math.Max(0, subtotal - req.DiscountAmount);

                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var billingMonth = new DateOnly(req.Year, req.Month, 1);
                var dueDate = today.AddDays(5);

                var invoice = new Invoice
                {
                    Id = "inv_" + Guid.NewGuid().ToString("N")[..8],
                    InvoiceCode = $"#HD-T{req.Month:D2}-{contract.Room?.Name?.Replace(" ", "")}",
                    ContractId = contract.Id,
                    BillingMonth = billingMonth,
                    IssueDate = today,
                    DueDate = dueDate,
                    Subtotal = subtotal,
                    Discount = req.DiscountAmount > 0 ? req.DiscountAmount : null,
                    Total = total,
                    Status = req.Status,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var utilityReading = new UtilityReading
                {
                    Id = "ur_" + Guid.NewGuid().ToString("N")[..8],
                    RoomId = contract.RoomId,
                    Month = billingMonth, // billingMonth kiểu DateOnly đã khai báo ở trên
                    ElectricityOld = oldElectric,
                    ElectricityNew = req.NewElectric,
                    ElectricityPrice = electricUnitPrice,
                    WaterOld = oldWater,
                    WaterNew = req.NewWater,
                    WaterPrice = waterUnitPrice, // Tên biến đúng là waterUnitPrice
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.UtilityReadings.Add(utilityReading);

                _context.Invoices.Add(invoice);

                contract.InitialElectricityReading = req.NewElectric;
                contract.InitialWaterReading = req.NewWater;
                contract.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Lập hóa đơn thành công!",
                    invoiceId = invoice.Id,
                    code = invoice.InvoiceCode,
                    subtotal = subtotal,
                    total = total
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi tạo hóa đơn", error = ex.Message });
            }
        }

        // 4. PUT: /api/OwnerInvoices/{id}/status (Gạch nợ / Xác nhận thu tiền)
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(string id, [FromBody] UpdateInvoiceStatusRequest req)
        {
            try
            {
                var invoice = await _context.Invoices.FindAsync(id);
                if (invoice == null)
                {
                    return NotFound(new { message = "Không tìm thấy hóa đơn." });
                }

                invoice.Status = req.Status;
                invoice.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã cập nhật trạng thái hóa đơn!", status = req.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi cập nhật trạng thái", error = ex.Message });
            }
        }

        // 5. GET: /api/OwnerInvoices/{id} (Chi tiết hóa đơn đầy đủ)
        [HttpGet("{id}")]
        public async Task<IActionResult> GetInvoiceDetail(string id)
        {
            try
            {
                var invoice = await _context.Invoices
                    .Include(i => i.Contract)
                        .ThenInclude(c => c.Room)
                    .Include(i => i.Contract)
                        .ThenInclude(c => c.Tenant)
                    .Include(i => i.UtilityReading)
                    .Include(i => i.InvoiceItems)
                        .ThenInclude(it => it.Service)
                    .FirstOrDefaultAsync(i => i.Id == id || i.InvoiceCode == id);

                if (invoice == null)
                {
                    return NotFound(new { message = "Không tìm thấy hóa đơn." });
                }

                var contract = invoice.Contract;
                var reading = invoice.UtilityReading;

                // Lấy tiền điện nước từ InvoiceItems hoặc UtilityReading
                decimal electricAmount = 0;
                decimal waterAmount = 0;
                decimal electricUsage = 0;
                decimal waterUsage = 0;
                decimal electricUnitPrice = reading?.ElectricityPrice ?? 3500;
                decimal waterUnitPrice = reading?.WaterPrice ?? 20000;

                if (reading != null)
                {
                    electricUsage = Math.Max(0, reading.ElectricityNew - reading.ElectricityOld);
                    waterUsage = Math.Max(0, reading.WaterNew - reading.WaterOld);
                    electricAmount = electricUsage * reading.ElectricityPrice;
                    waterAmount = waterUsage * reading.WaterPrice;
                }

                // Danh sách dịch vụ khác (lấy từ InvoiceItems loại service/other)
                var otherServices = new List<object>();

                if (invoice.InvoiceItems != null && invoice.InvoiceItems.Any())
                {
                    foreach (var it in invoice.InvoiceItems)
                    {
                        if (it.Type == "electricity" && electricAmount == 0) electricAmount = it.Amount;
                        else if (it.Type == "water" && waterAmount == 0) waterAmount = it.Amount;
                        else if (it.Type == "service" || it.Type == "other")
                        {
                            otherServices.Add(new
                            {
                                name = it.Description ?? it.Service?.Name ?? "Dịch vụ",
                                price = it.Amount,
                                unit = it.Service?.Unit ?? "tháng"
                            });
                        }
                    }
                }

                return Ok(new
                {
                    id = invoice.Id,
                    code = invoice.InvoiceCode,
                    room = contract?.Room?.Name ?? "Phòng",
                    tenant = contract?.Tenant?.Name ?? "Khách thuê",
                    phone = contract?.Tenant?.Phone ?? "",
                    status = invoice.Status,
                    issueDate = invoice.IssueDate.ToString("yyyy-MM-dd"),
                    dueDate = invoice.DueDate.ToString("yyyy-MM-dd"),
                    billingMonth = $"T{invoice.BillingMonth.Month:D2}/{invoice.BillingMonth.Year}",
                    rentPrice = contract?.Rent ?? 0,
                    electricUsage = electricUsage,
                    electricUnitPrice = electricUnitPrice,
                    electricAmount = electricAmount,
                    waterUsage = waterUsage,
                    waterUnitPrice = waterUnitPrice,
                    waterAmount = waterAmount,
                    subtotal = invoice.Subtotal,
                    discount = invoice.Discount ?? 0,
                    total = invoice.Total,
                    otherServices = otherServices
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy chi tiết hóa đơn", error = ex.Message });
            }
        }


        // GET: /api/OwnerInvoices/rooms-utility-summary
        [HttpGet("rooms-utility-summary")]
        public async Task<IActionResult> GetRoomsUtilitySummary()
        {
            try
            {
                var contracts = await _context.Contracts
                    .Include(c => c.Room)
                    .Include(c => c.Tenant)
                    .Where(c => c.Status == "active")
                    .ToListAsync();

                var result = new List<object>();

                foreach (var c in contracts)
                {
                    // Lấy lần ghi gần nhất của phòng
                    var lastReading = await _context.UtilityReadings
                        .Where(u => u.RoomId == c.RoomId)
                        .OrderByDescending(u => u.Month)
                        .FirstOrDefaultAsync();

                    decimal oldElectric = lastReading != null
                        ? lastReading.ElectricityNew
                        : c.InitialElectricityReading;

                    decimal oldWater = lastReading != null
                        ? lastReading.WaterNew
                        : c.InitialWaterReading;

                    result.Add(new
                    {
                        contractId = c.Id,
                        roomId = c.RoomId,
                        roomName = c.Room?.Name ?? "Phòng",
                        tenantName = c.Tenant?.Name ?? "Khách thuê",
                        phone = c.Tenant?.Phone ?? "",
                        elecOld = oldElectric,
                        waterOld = oldWater
                    });
                }

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi lấy dữ liệu ghi số", error = ex.Message });
            }
        }


        // GET: /api/OwnerInvoices/room-utility-history/{roomId}
        [HttpGet("room-utility-history/{roomId}")]
        public async Task<IActionResult> GetRoomUtilityHistory(string roomId)
        {
            try
            {
                var readings = await _context.UtilityReadings
                    .Include(u => u.Room)
                    .Where(u => u.RoomId == roomId)
                    .OrderByDescending(u => u.Month)
                    .Take(12) // Lấy 12 tháng gần nhất cho biểu đồ
                    .ToListAsync();

                var historyList = readings.Select(r => new
                {
                    id = r.Id,
                    month = r.Month.ToString("MM/yyyy"),
                    monthCode = r.Month.Month.ToString("D2"),
                    elecOld = r.ElectricityOld,
                    elecNew = r.ElectricityNew,
                    elecUsage = Math.Max(0, r.ElectricityNew - r.ElectricityOld),
                    elecPrice = r.ElectricityPrice,
                    elecCost = Math.Max(0, r.ElectricityNew - r.ElectricityOld) * r.ElectricityPrice,
                    waterOld = r.WaterOld,
                    waterNew = r.WaterNew,
                    waterUsage = Math.Max(0, r.WaterNew - r.WaterOld),
                    waterPrice = r.WaterPrice,
                    waterCost = Math.Max(0, r.WaterNew - r.WaterOld) * r.WaterPrice,
                    totalCost = (Math.Max(0, r.ElectricityNew - r.ElectricityOld) * r.ElectricityPrice) +
                                (Math.Max(0, r.WaterNew - r.WaterOld) * r.WaterPrice),
                    createdAt = r.CreatedAt?.ToString("dd/MM/yyyy") ?? ""
                }).ToList();

                return Ok(historyList);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp lịch sử điện nước", error = ex.Message });
            }
        }
    }
}