namespace Backend.DTOs
{
    public class InvoiceItemDTO
    {
        public string Type { get; set; } = null!;
        public string? Description { get; set; }
        public decimal Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal Amount { get; set; }
    }
}