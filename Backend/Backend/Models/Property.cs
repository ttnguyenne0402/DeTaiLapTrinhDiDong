using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Property
{
    public string Id { get; set; } = null!;

    public string OwnerId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string Type { get; set; } = null!;

    public string Address { get; set; } = null!;

    public string District { get; set; } = null!;

    public string Ward { get; set; } = null!;

    public decimal? Latitude { get; set; }

    public decimal? Longitude { get; set; }

    public string? Description { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual User Owner { get; set; } = null!;

    public virtual ICollection<PropertyService> PropertyServices { get; set; } = new List<PropertyService>();

    public virtual ICollection<Room> Rooms { get; set; } = new List<Room>();
}
