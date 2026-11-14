using System;
using System.Collections.Generic;

namespace Backend.DTOs
{
    // DTO lấy chỉ số kỳ trước (để tự điền số điện/nước cũ vào form)
    public class PreviousReadingDto
    {
        public string ContractId { get; set; } = null!;
        public string RoomName { get; set; } = null!;
        public string TenantName { get; set; } = null!;
        public string TenantPhone { get; set; } = null!;
        public decimal RentPrice { get; set; }
        public decimal OldElectric { get; set; }
        public decimal OldWater { get; set; }
        public decimal ElectricUnitPrice { get; set; } = 3800; // Mặc định nếu chưa cài đặt
        public decimal WaterUnitPrice { get; set; } = 25000;
        public List<ContractServiceItemDto> OtherServices { get; set; } = new();
    }

    // DTO gửi lên để lập hóa đơn mới
    public class CreateInvoiceRequest
    {
        public string ContractId { get; set; } = null!;
        public int Month { get; set; }
        public int Year { get; set; }
        public decimal OldElectric { get; set; }
        public decimal NewElectric { get; set; }
        public decimal OldWater { get; set; }
        public decimal NewWater { get; set; }
        public decimal DiscountAmount { get; set; } = 0; 
        public string? Note { get; set; }
        public string Status { get; set; } = "unpaid"; 

   
        public string? BankAccountId { get; set; }
    }


    public class UpdateInvoiceStatusRequest
    {
        public string Status { get; set; } = null!; // "paid", "unpaid", "pending", "cancelled"
        public string? PaymentMethod { get; set; } 
    }

    public class InvoiceListItemDto
    {
        public string Id { get; set; } = null!;
        public string Code { get; set; } = null!;
        public string Room { get; set; } = null!;
        public string Tenant { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public DateTime DueDate { get; set; }
        public decimal Total { get; set; }
        public string Status { get; set; } = null!;
        public string PaymentInfo { get; set; } = "";
    }

    public class MonthlyInvoiceSummaryDto
    {
        public int Month { get; set; }
        public int Year { get; set; }
        public decimal TotalPaid { get; set; }
        public decimal TotalOutstanding { get; set; }
        public decimal TotalExpected => TotalPaid + TotalOutstanding;
        public List<InvoiceListItemDto> Invoices { get; set; } = new();
    }

    public class ActiveContractForBillingDto
    {
        public string ContractId { get; set; } = null!;
        public string ContractCode { get; set; } = null!;
        public string PropertyId { get; set; } = null!;
        public string PropertyName { get; set; } = null!;
        public string RoomName { get; set; } = null!;
        public string TenantName { get; set; } = null!;
        public string TenantPhone { get; set; } = "";
    }

    public class BankAccountInfoDto
    {
        public string BankCode { get; set; } = null!;
        public string? BankName { get; set; }
        public string AccountNumber { get; set; } = null!;
        public string AccountHolder { get; set; } = null!;
    }
}