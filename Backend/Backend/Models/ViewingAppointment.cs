using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class ViewingAppointment
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public string TenantId { get; set; } = null!;

    public DateOnly AppointmentDate { get; set; }

    public TimeOnly AppointmentTime { get; set; }

    public string Phone { get; set; } = null!;

    public string? Message { get; set; }

    public string Status { get; set; } = null!;

    public string? OwnerNote { get; set; }

    public DateTime? ConfirmedAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Contract> Contracts { get; set; } = new List<Contract>();

    public virtual Room Room { get; set; } = null!;

    public virtual User Tenant { get; set; } = null!;
}
