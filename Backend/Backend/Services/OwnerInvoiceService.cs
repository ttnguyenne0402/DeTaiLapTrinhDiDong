using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Backend.DTOs;
using Backend.Models; 

namespace Backend.Services
{
    public class OwnerInvoiceService : IOwnerInvoiceService
    {
        private readonly QuanLyPhongTroContext _context;

        public OwnerInvoiceService(QuanLyPhongTroContext context)
        {
            _context = context;
        }

        // 1. Lấy danh sách phòng đang có hợp đồng thuê hoạt động (để chọn khi lập hóa đơn)
        public async Task<List<ActiveContractForBillingDto>> GetActiveContractsAsync()
        {
            return await _context.Contracts
                .Include(c => c.Room)
                    .ThenInclude(r => r.Property)
                .Include(c => c.Tenant)
                .Where(c => c.Status == "active")
                .Select(c => new ActiveContractForBillingDto
                {
                    ContractId = c.Id,
                    ContractCode = c.ContractCode,
                    PropertyName = c.Room.Property != null ? c.Room.Property.Name : "Khu trọ",
                    RoomName = c.Room != null ? c.Room.Name : "Phòng",
                    TenantName = c.Tenant != null ? c.Tenant.Name : "Khách thuê",
                    TenantPhone = c.Tenant != null ? (c.Tenant.Phone ?? "") : ""
                })
                .ToListAsync();
        }

        // 2. Lấy danh sách hóa đơn theo tháng & tổng hợp tài chính (Đã thu, Còn phải thu)
        public async Task<MonthlyInvoiceSummaryDto> GetMonthlyInvoicesAsync(int? month, int? year, string? search)
        {
            var targetMonth = month ?? DateTime.Now.Month;
            var targetYear = year ?? DateTime.Now.Year;

            var query = _context.Invoices
                .Include(i => i.Contract)
                    .ThenInclude(c => c.Room)
                .Include(i => i.Contract)
                    .ThenInclude(c => c.Tenant)
                .Where(i => i.BillingMonth.Month == targetMonth && i.BillingMonth.Year == targetYear);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.ToLower().Trim();
                query = query.Where(i =>
                    (i.InvoiceCode != null && i.InvoiceCode.ToLower().Contains(s)) ||
                    (i.Contract.Room != null && i.Contract.Room.Name.ToLower().Contains(s)) ||
                    (i.Contract.Tenant != null && i.Contract.Tenant.Name.ToLower().Contains(s)));
            }

            var invoices = await query.OrderByDescending(i => i.CreatedAt).ToListAsync();

            var list = invoices.Select(i => new InvoiceListItemDto
            {
                Id = i.Id,
                Code = i.InvoiceCode,
                Room = i.Contract?.Room?.Name ?? "Phòng",
                Tenant = i.Contract?.Tenant?.Name ?? "Khách thuê",
                Phone = i.Contract?.Tenant?.Phone ?? "",
                DueDate = i.DueDate.ToDateTime(TimeOnly.MinValue),
                Total = i.Total,
                Status = i.Status,
                PaymentInfo = i.Status == "paid" ? "VietQR Napas 24/7 (Đã thanh toán)" : ""
            }).ToList();

            var totalPaid = list.Where(x => x.Status == "paid").Sum(x => x.Total);
            var totalOutstanding = list.Where(x => x.Status != "paid" && x.Status != "cancelled").Sum(x => x.Total);

            return new MonthlyInvoiceSummaryDto
            {
                Month = targetMonth,
                Year = targetYear,
                TotalPaid = totalPaid,
                TotalOutstanding = totalOutstanding,
                Invoices = list
            };
        }

        // 3. Lấy chỉ số điện/nước kỳ trước và biểu phí của phòng theo Hợp đồng
        public async Task<PreviousReadingDto?> GetPreviousReadingAsync(string contractId)
        {
            var contract = await _context.Contracts
                .Include(c => c.Room)
                .Include(c => c.Tenant)
                .Include(c => c.ContractServices)
                    .ThenInclude(cs => cs.Service)
                .FirstOrDefaultAsync(c => c.Id == contractId);

            if (contract == null) return null;

            // Tìm chỉ số đồng hồ chốt gần đây nhất của phòng này
            var lastReading = await _context.UtilityReadings
                .Where(u => u.RoomId == contract.RoomId)
                .OrderByDescending(u => u.Month)
                .FirstOrDefaultAsync();

            decimal oldElectric = lastReading?.ElectricityNew ?? contract.InitialElectricityReading;
            decimal oldWater = lastReading?.WaterNew ?? contract.InitialWaterReading;

            decimal electricPrice = 3800; // Giá mặc định nếu phòng chưa cấu hình
            decimal waterPrice = 25000;
            var otherServices = new List<ContractServiceItemDto>();

            if (contract.ContractServices != null)
            {
                foreach (var cs in contract.ContractServices)
                {
                    var name = cs.Service?.Name?.ToLower() ?? "";
                    if (name.Contains("điện")) electricPrice = cs.UnitPrice;
                    else if (name.Contains("nước")) waterPrice = cs.UnitPrice;
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
            }

            return new PreviousReadingDto
            {
                ContractId = contract.Id,
                RoomName = contract.Room?.Name ?? "Phòng",
                TenantName = contract.Tenant?.Name ?? "Khách thuê",
                TenantPhone = contract.Tenant?.Phone ?? "",
                RentPrice = contract.Rent,
                OldElectric = oldElectric,
                OldWater = oldWater,
                ElectricUnitPrice = electricPrice,
                WaterUnitPrice = waterPrice,
                OtherServices = otherServices
            };
        }

        // 4. Tính toán chi phí, lưu chỉ số mới và tạo hóa đơn vào CSDL
        public async Task<object> CreateInvoiceAsync(CreateInvoiceRequest req)
        {
            var contract = await _context.Contracts
                .Include(c => c.ContractServices)
                    .ThenInclude(cs => cs.Service)
                .FirstOrDefaultAsync(c => c.Id == req.ContractId);

            if (contract == null)
                throw new Exception("Hợp đồng không tồn tại.");

            var readingInfo = await GetPreviousReadingAsync(req.ContractId);
            if (readingInfo == null)
                throw new Exception("Không nạp được biểu phí phòng.");

            // Tính toán mức tiêu thụ
            decimal electricKwh = Math.Max(0, req.NewElectric - readingInfo.OldElectric);
            decimal waterM3 = Math.Max(0, req.NewWater - readingInfo.OldWater);

            decimal electricAmount = electricKwh * readingInfo.ElectricUnitPrice;
            decimal waterAmount = waterM3 * readingInfo.WaterUnitPrice;

            decimal serviceTotal = readingInfo.OtherServices.Sum(s => s.Price);
            decimal subtotal = readingInfo.RentPrice + electricAmount + waterAmount + serviceTotal;
            decimal total = Math.Max(0, subtotal - req.DiscountAmount);

            var reading = new UtilityReading
            {
                Id = "ur_" + Guid.NewGuid().ToString("N").Substring(0, 10),
                RoomId = contract.RoomId,
                Month = new DateOnly(req.Year, req.Month, 1), 
                ElectricityOld = readingInfo.OldElectric,
                ElectricityNew = req.NewElectric,
                ElectricityPrice = readingInfo.ElectricUnitPrice,
                WaterOld = readingInfo.OldWater,
                WaterNew = req.NewWater,
                WaterPrice = readingInfo.WaterUnitPrice,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };
            _context.UtilityReadings.Add(reading);

            // 2. Tạo hóa đơn
            var invoice = new Invoice
            {
                Id = "inv_" + Guid.NewGuid().ToString("N").Substring(0, 10),
                InvoiceCode = $"INV-{req.Year}{req.Month:D2}-{new Random().Next(100, 999)}",
                ContractId = contract.Id,
                UtilityReadingId = reading.Id,
                BillingMonth = new DateOnly(req.Year, req.Month, 1), // DateOnly
                IssueDate = DateOnly.FromDateTime(DateTime.Now),      // DateOnly
                DueDate = DateOnly.FromDateTime(DateTime.Now.AddDays(5)), // DateOnly
                Subtotal = subtotal,
                Discount = req.DiscountAmount,
                Total = total,
                Status = string.IsNullOrWhiteSpace(req.Status) ? "unpaid" : req.Status,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };
            _context.Invoices.Add(invoice);

            await _context.SaveChangesAsync();

            return new { id = invoice.Id, code = invoice.InvoiceCode, total = invoice.Total, status = invoice.Status };
        }

        // 5. Cập nhật trạng thái thanh toán (Xác nhận thu / Gạch nợ)
        public async Task<bool> UpdateInvoiceStatusAsync(string invoiceId, UpdateInvoiceStatusRequest req)
        {
            var invoice = await _context.Invoices.FirstOrDefaultAsync(i => i.Id == invoiceId);
            if (invoice == null) return false;

            invoice.Status = req.Status;
            invoice.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();
            return true;
        }
    }
}