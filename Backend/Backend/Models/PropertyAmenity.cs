using System;

namespace Backend.Models;

public partial class PropertyAmenity
{
    public string Id { get; set; } = null!;

    public string PropertyId { get; set; } = null!;

    public string AmenityId { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Amenity Amenity { get; set; } = null!;

    public virtual Property Property { get; set; } = null!;
}
