using System.Collections.Generic;
using System.Threading.Tasks;
using Backend.DTOs;

namespace Backend.Services
{
    public interface IOwnerInvoiceService
    {
        // 1. Lấy danh sách hợp đồng/phòng đang thuê để chọn khi lập hóa đơn
        Task<List<ActiveContractForBillingDto>> GetActiveContractsAsync();

        // 2. Lấy danh sách hóa đơn và tổng quan tài chính theo tháng
        Task<MonthlyInvoiceSummaryDto> GetMonthlyInvoicesAsync(int? month, int? year, string? search);

        // 3. Lấy chỉ số điện nước cũ & biểu phí phòng theo hợp đồng
        Task<PreviousReadingDto?> GetPreviousReadingAsync(string contractId);

        // 4. Lập hóa đơn mới và cập nhật chỉ số đồng hồ
        Task<object> CreateInvoiceAsync(CreateInvoiceRequest req);

        // 5. Cập nhật trạng thái (Gạch nợ / Xác nhận đã thu)
        Task<bool> UpdateInvoiceStatusAsync(string invoiceId, UpdateInvoiceStatusRequest req);
    }
}