using System.Collections.Generic;

namespace Backend.DTOs
{
    public class InvoiceResponseDTO
    {
        public string Id { get; set; } = null!;
        public string InvoiceCode { get; set; } = null!;
        public string BillingMonth { get; set; } = null!; 
        public string IssueDate { get; set; } = null!;    
        public string DueDate { get; set; } = null!;      
        public decimal Subtotal { get; set; }
        public decimal Discount { get; set; }
        public decimal Total { get; set; }
        public string Status { get; set; } = null!;

        // Danh sách các khoản thu (tiền phòng, điện, nước...)
        public List<InvoiceItemDTO> Items { get; set; } = new List<InvoiceItemDTO>();
    }
}