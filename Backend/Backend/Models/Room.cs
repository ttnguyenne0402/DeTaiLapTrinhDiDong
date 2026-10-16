using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Room
{
    public string Id { get; set; } = null!;

    public string PropertyId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public decimal Area { get; set; }

    public decimal Price { get; set; }

    public decimal Deposit { get; set; }

    public int MaxPeople { get; set; }

    public int? Floor { get; set; }

    public string? Description { get; set; }

    public string? Images { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Contract> Contracts { get; set; } = new List<Contract>();

    public virtual ICollection<Favorite> Favorites { get; set; } = new List<Favorite>();

    public virtual ICollection<MaintenanceRequest> MaintenanceRequests { get; set; } = new List<MaintenanceRequest>();

    public virtual Property Property { get; set; } = null!;

    public virtual ICollection<RentalPost> RentalPosts { get; set; } = new List<RentalPost>();

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<RoomAmenity> RoomAmenities { get; set; } = new List<RoomAmenity>();

    public virtual ICollection<UtilityReading> UtilityReadings { get; set; } = new List<UtilityReading>();

    public virtual ICollection<ViewingAppointment> ViewingAppointments { get; set; } = new List<ViewingAppointment>();
}
