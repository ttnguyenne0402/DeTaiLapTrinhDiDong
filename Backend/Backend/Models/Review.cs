using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Review
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public string TenantId { get; set; } = null!;

    public byte Rating { get; set; }

    public string? Comment { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Room Room { get; set; } = null!;

    public virtual User Tenant { get; set; } = null!;
}
