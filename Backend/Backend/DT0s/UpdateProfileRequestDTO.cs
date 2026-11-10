namespace Backend.DTOs
{
    public class UpdateProfileRequestDTO
    {
        public string Name { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? Phone { get; set; }
    }
}