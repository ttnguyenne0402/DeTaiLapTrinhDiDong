using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class RentalPost
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public string Status { get; set; } = null!;

    public string? RejectionReason { get; set; }

    public DateTime? PublishedAt { get; set; }

    public DateTime? ExpiredAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<RentalPostImage> RentalPostImages { get; set; } = new List<RentalPostImage>();

    public virtual Room Room { get; set; } = null!;
}
