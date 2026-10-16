using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class MaintenanceRequest
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public string TenantId { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string Description { get; set; } = null!;

    public string Priority { get; set; } = null!;

    public string Status { get; set; } = null!;

    public string? Image { get; set; }

    public string? OwnerNote { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Room Room { get; set; } = null!;

    public virtual User Tenant { get; set; } = null!;
}
