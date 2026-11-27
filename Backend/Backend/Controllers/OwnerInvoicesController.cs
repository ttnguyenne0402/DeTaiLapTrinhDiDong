using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.DTOs;
using Backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Backend.Helpers;

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

        // GET: /api/OwnerInvoices/active-contracts?ownerId=...&propertyId=...
        [HttpGet("active-contracts")]
        public async Task<IActionResult> GetActiveContracts(
            [FromQuery] string? ownerId,
            [FromQuery] string? propertyId)
        {
            try
            {
                var query = _context.Contracts
                    .Include(c => c.Room)
                        .ThenInclude(r => r.Property)
                    .Include(c => c.Tenant)
                    .Where(c => c.Status == "active");

               
                if (!string.IsNullOrEmpty(ownerId) && ownerId != "all")
                {
                    var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);
                    query = query.Where(c => targetOwnerIds.Contains(c.OwnerId));
                }

                if (!string.IsNullOrEmpty(propertyId) && propertyId != "all")
                {
                    query = query.Where(c =>
                        c.Room != null && c.Room.PropertyId == propertyId);
                }

                var contracts = await query
                    .Select(c => new ActiveContractForBillingDto
                    {
                        ContractId = c.Id,
                        ContractCode = c.ContractCode,
                        RoomId = c.RoomId,
                        PropertyId = c.Room.PropertyId,
                        PropertyName = c.Room.Property != null
                            ? c.Room.Property.Name
                            : "Khu trọ",
                        RoomName = c.Room != null ? c.Room.Name : "Phòng",
                        TenantName = c.Tenant != null ? c.Tenant.Name : "Khách thuê",
                        TenantPhone = c.Tenant != null ? (c.Tenant.Phone ?? "") : ""
                    })
                    .ToListAsync();

                // 🔴 LỌC BỎ NHỮNG PHÒNG ĐÃ THANH TOÁN HÓA ĐƠN THÁNG NÀY RỒI (KHÔNG CHO LẬP TRÙNG TRONG DROPDOWN LẬP HÓA ĐƠN)
                var currentMonth = new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
                var paidContractIds = await _context.Invoices
                    .Where(i => i.BillingMonth == currentMonth && i.Status == "paid")
                    .Select(i => i.ContractId)
                    .ToListAsync();

                var availableContracts = contracts
                    .Where(c => !paidContractIds.Contains(c.ContractId))
                    .ToList();

                return Ok(availableContracts);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    message = "Lỗi nạp danh sách phòng",
                    error = ex.Message
                });
            }
        }

        // 1. GET: /api/OwnerInvoices?ownerId=...&month=8&year=2026&search=
        [HttpGet]
        public async Task<IActionResult> GetMonthlyInvoices(
           [FromQuery] string? ownerId,
           [FromQuery] int? month,
           [FromQuery] int? year,
           [FromQuery] string? search)
        {
           try
           {
               var targetMonth = month ?? DateTime.UtcNow.Month;
               var targetYear = year ?? DateTime.UtcNow.Year;

               var query = _context.Contracts
                   .Include(c => c.Room)
                   .Include(c => c.Tenant)
                   .Include(c => c.Invoices)
                   .Where(c => c.Status == "active");


               if (!string.IsNullOrEmpty(ownerId) && ownerId != "all")
               {
                   var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);
                   query = query.Where(c => targetOwnerIds.Contains(c.OwnerId));
               }

               var contracts = await query.ToListAsync();

               var listItems = new List<InvoiceListItemDto>();
               decimal totalPaid = 0;
               decimal totalOutstanding = 0;

               foreach (var ctr in contracts)
               {
                   var inv = ctr.Invoices.FirstOrDefault(i =>
                       i.BillingMonth.Month == targetMonth &&
                       i.BillingMonth.Year == targetYear);

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
                           PaymentInfo = status == "paid"
                               ? "VietQR Napas 247 (Đã thanh toán)"
                               : ""
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
               return StatusCode(500, new
               {
                   message = "Lỗi khi lấy danh sách hóa đơn",
                   error = ex.Message
               });
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

                var lastReading = await _context.UtilityReadings
                    .Where(u => u.RoomId == contract.RoomId)
                    .OrderByDescending(u => u.Month)
                    .FirstOrDefaultAsync();


                decimal oldElectric = lastReading != null ? lastReading.ElectricityOld : contract.InitialElectricityReading;
                decimal newElectric = lastReading != null ? lastReading.ElectricityNew : contract.InitialElectricityReading;

                decimal oldWater = lastReading != null ? lastReading.WaterOld : contract.InitialWaterReading;
                decimal newWater = lastReading != null ? lastReading.WaterNew : contract.InitialWaterReading;

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
                    NewElectric  = newElectric,
                    OldWater = oldWater,
                    NewWater = newWater,
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

               var lastReading = await _context.UtilityReadings
                              .Where(u => u.RoomId == contract.RoomId)
                              .OrderByDescending(u => u.Month)
                              .ThenByDescending(u => u.CreatedAt)
                              .FirstOrDefaultAsync();

               decimal oldElectric = lastReading != null
                              ? lastReading.ElectricityNew
                              : contract.InitialElectricityReading;

               decimal oldWater = lastReading != null
                              ? lastReading.WaterNew
                              : contract.InitialWaterReading;

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

               var existingInvoice = await _context.Invoices
                   .FirstOrDefaultAsync(i => i.ContractId == contract.Id && i.BillingMonth == billingMonth && i.Status != "cancelled");

               if (existingInvoice != null)
               {
                   return BadRequest(new { message = $"Phòng {contract.Room?.Name} đã được phát hành hóa đơn cho Tháng {req.Month}/{req.Year} rồi!" });
               }

               string? validBankId = string.IsNullOrWhiteSpace(req.BankAccountId) ? null : req.BankAccountId;


               if (validBankId != null)
               {
                 var bankExists = await _context.BankAccounts.AnyAsync(b => b.Id == validBankId);
                 if (!bankExists) validBankId = null; // Tránh lỗi Khóa ngoại SQL
               }


               string uniqueCode = $"#HD-T{req.Month:D2}-{contract.Room?.Name?.Replace(" ", "")}-{new Random().Next(100, 999)}";

                var invoice = new Invoice
                {
                    Id = "inv_" + Guid.NewGuid().ToString("N")[..8],
                    InvoiceCode = uniqueCode,
                    ContractId = contract.Id,
                    BankAccountId = validBankId, // Đã được xử lý gán NULL an toàn nếu trống
                    BillingMonth = billingMonth,
                    IssueDate = today,
                    DueDate = dueDate,
                    Subtotal = subtotal,
                    Discount = req.DiscountAmount > 0 ? req.DiscountAmount : null,
                    Total = total,
                    Status = string.IsNullOrWhiteSpace(req.Status) ? "unpaid" : req.Status,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                var existingReading = await _context.UtilityReadings
                    .FirstOrDefaultAsync(u => u.RoomId == contract.RoomId && u.Month == billingMonth);

                if (existingReading != null)
                {
                    existingReading.ElectricityNew = req.NewElectric;
                    existingReading.WaterNew = req.NewWater;
                    existingReading.UpdatedAt = DateTime.UtcNow;
                }
                else
                {
                    var utilityReading = new UtilityReading
                    {
                        Id = "ur_" + Guid.NewGuid().ToString("N")[..8],
                        RoomId = contract.RoomId,
                        Month = billingMonth,
                        ElectricityOld = oldElectric,
                        ElectricityNew = req.NewElectric,
                        ElectricityPrice = electricUnitPrice,
                        WaterOld = oldWater,
                        WaterNew = req.NewWater,
                        WaterPrice = waterUnitPrice,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _context.UtilityReadings.Add(utilityReading);
                }

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
                // Dùng Include để lấy được Contract.TenantId
                var invoice = await _context.Invoices
                    .Include(i => i.Contract)
                    .FirstOrDefaultAsync(i => i.Id == id);

                if (invoice == null)
                {
                    return NotFound(new { message = "Không tìm thấy hóa đơn." });
                }

                var oldStatus = invoice.Status;
                invoice.Status = req.Status;
                invoice.UpdatedAt = DateTime.Now;

                // Nếu chủ trọ vừa xác nhận đã thanh toán (tránh gửi trùng nếu hóa đơn đã paid trước đó)
                if (req.Status == "paid" && oldStatus != "paid" && !string.IsNullOrEmpty(invoice.Contract?.TenantId))
                {
                    var period = invoice.BillingMonth.ToString("MM/yyyy");
                    _context.Notifications.Add(new Notification
                    {
                        Id = "NOTIF_" + Guid.NewGuid().ToString("N")[..8],
                        UserId = invoice.Contract.TenantId,
                        Title = "Thanh toán hóa đơn thành công",
                        Message = $"Chủ trọ đã xác nhận thanh toán {invoice.Total:N0}đ cho hóa đơn {invoice.InvoiceCode} (kỳ {period}).",
                        Type = "invoice",
                        ReferenceId = invoice.Id,
                        ReferenceType = "invoice",
                        CreatedAt = DateTime.Now,
                        UpdatedAt = DateTime.Now
                    });
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã cập nhật trạng thái hóa đơn!", status = req.Status });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi cập nhật trạng thái", error = ex.Message });
            }
        }

        // 5. GET: /api/OwnerInvoices/{id} (Chi tiết hóa đơn đầy đủ kèm tài khoản ngân hàng)
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
                    .Include(i => i.BankAccount) // <-- Nạp tài khoản ngân hàng đã chọn
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
                    electricOld = reading?.ElectricityOld ?? contract?.InitialElectricityReading ?? 0,
                    electricNew = reading?.ElectricityNew ?? contract?.InitialElectricityReading ?? 0,
                    electricUsage = electricUsage,
                    electricUnitPrice = electricUnitPrice,
                    electricAmount = electricAmount,
                    waterOld = reading?.WaterOld ?? contract?.InitialWaterReading ?? 0,
                    waterNew = reading?.WaterNew ?? contract?.InitialWaterReading ?? 0,
                    waterUsage = waterUsage,
                    waterUnitPrice = waterUnitPrice,
                    waterAmount = waterAmount,
                    subtotal = invoice.Subtotal,
                    discount = invoice.Discount ?? 0,
                    total = invoice.Total,
                    otherServices = otherServices,

                    // Thông tin ngân hàng trả về cho app Người thuê xem & quét VietQR
                    bankAccount = invoice.BankAccount != null ? new
                    {
                        bankCode = invoice.BankAccount.BankCode,
                        bankName = invoice.BankAccount.BankName,
                        accountNumber = invoice.BankAccount.AccountNumber,
                        accountHolder = invoice.BankAccount.AccountHolder
                    } : null
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lấy chi tiết hóa đơn", error = ex.Message });
            }
        }

         // GET: /api/OwnerInvoices/rooms-utility-summary?ownerId=...&propertyId=...
            [HttpGet("rooms-utility-summary")]
            public async Task<IActionResult> GetRoomsUtilitySummary([FromQuery] string? ownerId, [FromQuery] string? propertyId)
            {
                try
                {
                    var query = _context.Contracts
                        .Include(c => c.Room)
                            .ThenInclude(r => r.Property)
                        .Include(c => c.Tenant)
                        .Where(c => c.Status == "active");

                    // 🔴 LỌC CHÍNH XÁC CHỦ TRỌ ĐANG ĐĂNG NHẬP
                    if (!string.IsNullOrEmpty(ownerId) && ownerId != "all")
                    {
                        var targetOwnerIds = OwnerHelper.ResolveOwnerIds(ownerId);
                        query = query.Where(c => targetOwnerIds.Contains(c.OwnerId) || (c.Room != null && c.Room.Property != null && targetOwnerIds.Contains(c.Room.Property.OwnerId)));
                    }

                    // 🔴 LỌC CHÍNH XÁC TÒA NHÀ ĐƯỢC CHỌN
                    if (!string.IsNullOrEmpty(propertyId) && propertyId != "all")
                    {
                        query = query.Where(c => c.Room != null && c.Room.PropertyId == propertyId);
                    }

                    var contracts = await query.ToListAsync();
                    var result = new List<object>();
                    var currentMonth = new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);

                    foreach (var c in contracts)
                    {
                        var currentMonthReading = await _context.UtilityReadings
                            .FirstOrDefaultAsync(u => u.RoomId == c.RoomId && u.Month == currentMonth);

                        var lastReading = await _context.UtilityReadings
                            .Where(u => u.RoomId == c.RoomId && u.Month < currentMonth)
                            .OrderByDescending(u => u.Month)
                            .ThenByDescending(u => u.CreatedAt)
                            .FirstOrDefaultAsync();

                        var paidInvoice = await _context.Invoices
                            .FirstOrDefaultAsync(i => i.ContractId == c.Id && i.BillingMonth == currentMonth && i.Status == "paid");

                        decimal oldElectric = currentMonthReading != null
                            ? currentMonthReading.ElectricityOld
                            : (lastReading != null ? lastReading.ElectricityNew : c.InitialElectricityReading);

                        decimal oldWater = currentMonthReading != null
                            ? currentMonthReading.WaterOld
                            : (lastReading != null ? lastReading.WaterNew : c.InitialWaterReading);

                        decimal? elecNew = currentMonthReading != null ? currentMonthReading.ElectricityNew : null;
                        decimal? waterNew = currentMonthReading != null ? currentMonthReading.WaterNew : null;
                        bool isRecorded = currentMonthReading != null;
                        bool isPaid = paidInvoice != null;

                        result.Add(new
                        {
                            contractId = c.Id,
                            roomId = c.RoomId,
                            roomName = c.Room?.Name ?? "Phòng",
                            tenantName = c.Tenant?.Name ?? "Khách thuê",
                            phone = c.Tenant?.Phone ?? "",
                            elecOld = oldElectric,
                            waterOld = oldWater,
                            elecNew = elecNew,
                            waterNew = waterNew,
                            isRecorded = isRecorded,
                            isPaid = isPaid
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
                var contract = await _context.Contracts.FirstOrDefaultAsync(c => c.Id == roomId || c.ContractCode == roomId || c.RoomId == roomId);
                string targetRoomId = contract != null ? contract.RoomId : roomId;

                var rawReadings = await _context.UtilityReadings
                    .Include(u => u.Room)
                    .Where(u => u.RoomId == targetRoomId || u.RoomId == roomId || (contract != null && u.RoomId == contract.Id))
                    .OrderByDescending(u => u.Month)
                    .ThenByDescending(u => u.CreatedAt)
                    .ToListAsync();

                // Group theo Tháng/Năm để mỗi kỳ Tháng 11 chỉ hiển thị 1 bản ghi mới nhất
                var readings = rawReadings
                    .GroupBy(r => new { r.Month.Year, r.Month.Month })
                    .Select(g => g.First())
                    .Take(12)
                    .ToList();

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

        [HttpGet("bank-accounts")]
        public async Task<IActionResult> GetBankAccounts()
        {
            try
            {
                var banks = await _context.BankAccounts
                    .Where(b => b.Status == "active")
                    .Select(b => new
                    {
                        id = b.Id,
                        bankCode = b.BankCode,
                        bankName = b.BankName,
                        accountNumber = b.AccountNumber,
                        accountHolder = b.AccountHolder,
                        isDefault = b.IsDefault
                    })
                    .ToListAsync();

                return Ok(banks);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi nạp danh sách ngân hàng", error = ex.Message });
            }
        }

        // POST: /api/OwnerInvoices/save-utility-reading
        [HttpPost("save-utility-reading")]
        public async Task<IActionResult> SaveUtilityReading([FromBody] SaveUtilityReadingRequest req)
        {
            try
            {
                var contract = await _context.Contracts
                    .Include(c => c.Room)
                    .FirstOrDefaultAsync(c => c.Id == req.ContractId);

                if (contract == null)
                {
                    return NotFound(new { message = "Không tìm thấy hợp đồng." });
                }

                int m = req.Month ?? DateTime.UtcNow.Month;
                int y = req.Year ?? DateTime.UtcNow.Year;
                var billingMonth = new DateOnly(y, m, 1);

                var paidInvoice = await _context.Invoices
                    .FirstOrDefaultAsync(i => i.ContractId == contract.Id && i.BillingMonth == billingMonth && i.Status == "paid");

                if (paidInvoice != null)
                {
                    return BadRequest(new { message = $"Hóa đơn Tháng {m}/{y} của phòng {contract.Room?.Name} đã được người thuê thanh toán thành công! Không thể sửa đổi chỉ số điện nước nữa." });
                }

                var existingReading = await _context.UtilityReadings
                    .FirstOrDefaultAsync(u => u.RoomId == contract.RoomId && u.Month == billingMonth);

                var lastReading = await _context.UtilityReadings
                    .Where(u => u.RoomId == contract.RoomId && u.Month < billingMonth)
                    .OrderByDescending(u => u.Month)
                    .ThenByDescending(u => u.CreatedAt)
                    .FirstOrDefaultAsync();

                decimal oldElectric = lastReading != null ? lastReading.ElectricityNew : contract.InitialElectricityReading;
                decimal oldWater = lastReading != null ? lastReading.WaterNew : contract.InitialWaterReading;

                if (existingReading != null)
                {
                    existingReading.ElectricityNew = req.NewElectric;
                    existingReading.WaterNew = req.NewWater;
                    existingReading.UpdatedAt = DateTime.UtcNow;
                }
                else
                {
                    var newReading = new UtilityReading
                    {
                        Id = "ur_" + Guid.NewGuid().ToString("N")[..8],
                        RoomId = contract.RoomId,
                        Month = billingMonth,
                        ElectricityOld = oldElectric,
                        ElectricityNew = req.NewElectric,
                        ElectricityPrice = 3800,
                        WaterOld = oldWater,
                        WaterNew = req.NewWater,
                        WaterPrice = 25000,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };
                    _context.UtilityReadings.Add(newReading);
                }

                contract.InitialElectricityReading = req.NewElectric;
                contract.InitialWaterReading = req.NewWater;
                contract.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Đã lưu vĩnh viễn chỉ số điện nước vào CSDL thành công!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi lưu chỉ số điện nước", error = ex.Message });
            }
        }

        // PUT: /api/OwnerInvoices/{id} (Chỉnh sửa & Phát hành lại hóa đơn chưa thanh toán)
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateInvoice(string id, [FromBody] CreateInvoiceRequest req)
        {
            try
            {
                var invoice = await _context.Invoices
                    .Include(i => i.InvoiceItems)
                    .Include(i => i.Contract)
                    .FirstOrDefaultAsync(i => i.Id == id);

                if (invoice == null)
                {
                    return NotFound(new { message = "Không tìm thấy hóa đơn." });
                }

                if (invoice.Status == "paid")
                {
                    return BadRequest(new { message = "Hóa đơn đã được thanh toán, không thể chỉnh sửa!" });
                }

                var contract = invoice.Contract;
                if (contract == null) return NotFound(new { message = "Không tìm thấy hợp đồng." });

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

                decimal electricUsage = Math.Max(0, req.NewElectric - req.OldElectric);
                decimal waterUsage = Math.Max(0, req.NewWater - req.OldWater);

                decimal electricAmount = electricUsage * electricUnitPrice;
                decimal waterAmount = waterUsage * waterUnitPrice;
                decimal rentAmount = contract.Rent;

                decimal subtotal = rentAmount + electricAmount + waterAmount + totalServiceAmount;
                decimal total = Math.Max(0, subtotal - req.DiscountAmount);

                invoice.Subtotal = subtotal;
                invoice.Discount = req.DiscountAmount > 0 ? req.DiscountAmount : null;
                invoice.Total = total;
                invoice.BankAccountId = string.IsNullOrWhiteSpace(req.BankAccountId) ? null : req.BankAccountId;
                invoice.UpdatedAt = DateTime.UtcNow;

                var reading = await _context.UtilityReadings.FirstOrDefaultAsync(u => u.RoomId == contract.RoomId && u.Month == invoice.BillingMonth);
                if (reading != null)
                {
                    reading.ElectricityOld = req.OldElectric;
                    reading.ElectricityNew = req.NewElectric;
                    reading.WaterOld = req.OldWater;
                    reading.WaterNew = req.NewWater;
                    reading.UpdatedAt = DateTime.UtcNow;
                }

                contract.InitialElectricityReading = req.NewElectric;
                contract.InitialWaterReading = req.NewWater;
                contract.UpdatedAt = DateTime.UtcNow;

                _context.InvoiceItems.RemoveRange(invoice.InvoiceItems);

                var items = new List<InvoiceItem>
                {
                    new InvoiceItem { Id = "item_" + Guid.NewGuid().ToString("N")[..8], InvoiceId = invoice.Id, Type = "rent", Description = $"Tiền thuê phòng ({contract.Room?.Name})", Quantity = 1, UnitPrice = rentAmount, Amount = rentAmount, CreatedAt = DateTime.UtcNow },
                    new InvoiceItem { Id = "item_" + Guid.NewGuid().ToString("N")[..8], InvoiceId = invoice.Id, Type = "electricity", Description = $"Tiền điện ({req.OldElectric} ➔ {req.NewElectric} kWh)", Quantity = electricUsage, UnitPrice = electricUnitPrice, Amount = electricAmount, CreatedAt = DateTime.UtcNow },
                    new InvoiceItem { Id = "item_" + Guid.NewGuid().ToString("N")[..8], InvoiceId = invoice.Id, Type = "water", Description = $"Tiền nước ({req.OldWater} ➔ {req.NewWater} m³)", Quantity = waterUsage, UnitPrice = waterUnitPrice, Amount = waterAmount, CreatedAt = DateTime.UtcNow }
                };

                _context.InvoiceItems.AddRange(items);

                if (!string.IsNullOrEmpty(contract.TenantId))
                {
                    _context.Notifications.Add(new Notification
                    {
                        Id = "notif_" + Guid.NewGuid().ToString("N")[..8],
                        UserId = contract.TenantId,
                        Title = "Hóa đơn đã được cập nhật 📝",
                        Message = $"Chủ trọ vừa điều chỉnh lại Hóa đơn {invoice.InvoiceCode}. Tổng tiền mới: {total:N0}đ.",
                        Type = "invoice_updated",
                        ReferenceId = invoice.Id,
                        CreatedAt = DateTime.UtcNow
                    });
                }

                await _context.SaveChangesAsync();

                return Ok(new { message = "Cập nhật và phát hành lại hóa đơn thành công!", invoiceId = invoice.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Lỗi khi cập nhật hóa đơn", error = ex.Message });
            }
        }
    }

    public class SaveUtilityReadingRequest
    {
        public string ContractId { get; set; } = null!;
        public decimal NewElectric { get; set; }
        public decimal NewWater { get; set; }
        public int? Month { get; set; }
        public int? Year { get; set; }
    }
}