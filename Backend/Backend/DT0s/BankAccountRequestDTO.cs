namespace Backend.DTOs
{
    public class BankAccountRequestDTO
    {
        public string? BankCode { get; set; }
        public string? BankName { get; set; }
        public string AccountNumber { get; set; } = null!;
        public string AccountHolder { get; set; } = null!;
    }
}