using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class RoomAmenity
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public string AmenityId { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Amenity Amenity { get; set; } = null!;

    public virtual Room Room { get; set; } = null!;
}
