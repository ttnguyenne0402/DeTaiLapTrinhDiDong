namespace Backend.DTOs
{
    public class ProfileResponseDTO
    {
        public string Id { get; set; } = null!;

        public string Name { get; set; } = null!;

        public string Email { get; set; } = null!;

        public string? Phone { get; set; }

        public string? Avatar { get; set; }

        public string Role { get; set; } = null!;

        public List<BankAccountDTO> BankAccounts { get; set; } = new();
    }
}