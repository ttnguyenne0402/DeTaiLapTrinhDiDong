namespace Backend.DTOs
{
    public class BankAccountDTO
    {
        public string Id { get; set; } = null!;

        public string BankCode { get; set; } = null!;

        public string? BankName { get; set; }

        public string AccountNumber { get; set; } = null!;

        public string AccountHolder { get; set; } = null!;

        public bool IsDefault { get; set; }

        public string Status { get; set; } = null!;
    }
}