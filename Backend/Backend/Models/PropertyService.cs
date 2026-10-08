using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class PropertyService
{
    public string Id { get; set; } = null!;

    public string PropertyId { get; set; } = null!;

    public string ServiceId { get; set; } = null!;

    public decimal Price { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Property Property { get; set; } = null!;

    public virtual Service Service { get; set; } = null!;
}
