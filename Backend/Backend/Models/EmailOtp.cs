namespace Backend.Models;

public sealed class EmailOtp
{
    public int Id { get; set; }
    public string UserId { get; set; } = null!;
    public string Purpose { get; set; } = null!;
    public string CodeHash { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? UsedAt { get; set; }
    public int Attempts { get; set; }
}
