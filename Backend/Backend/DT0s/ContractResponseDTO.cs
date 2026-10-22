namespace Backend.DTOs
{
    public class ContractResponseDTO
    {
        public string Id { get; set; } = null!;
        public string ContractCode { get; set; } = null!;

        public string Title { get; set; } = null!;

        public string Status { get; set; } = null!; 

        public string StartDate { get; set; } = null!; 
        public string EndDate { get; set; } = null!;

        public decimal RentPrice { get; set; }
        public decimal Deposit { get; set; }
        public string PaymentCycle { get; set; } = null!;
    }
}