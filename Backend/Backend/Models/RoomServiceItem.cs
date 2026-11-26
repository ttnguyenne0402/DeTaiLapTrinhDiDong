namespace Backend.Models;

public partial class RoomServiceItem
{
    public string Id { get; set; } = null!;
    public string RoomId { get; set; } = null!;
    public string ServiceId { get; set; } = null!;
    public DateTime? CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public virtual Room Room { get; set; } = null!;
    public virtual Service Service { get; set; } = null!;
}
