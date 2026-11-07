namespace Backend.DTOs
{
    public class AdminUserListItemDto
    {
        public string Id { get; set; } = null!;
        public string Name { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? Phone { get; set; }
        public string? Avatar { get; set; }
        public string Role { get; set; } = null!;      // "admin", "owner", "tenant"
        public string Status { get; set; } = null!;    // "active", "inactive", "blocked"
        public DateTime? CreatedAt { get; set; }
    }

    public class UpdateUserStatusRequest
    {
        public string Status { get; set; } = null!;    // "active" hoặc "blocked"
    }
}