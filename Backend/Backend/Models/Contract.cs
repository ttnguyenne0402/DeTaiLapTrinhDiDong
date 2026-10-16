using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Contract
{
    public string Id { get; set; } = null!;

    public string ContractCode { get; set; } = null!;

    public string? ViewingAppointmentId { get; set; }

    public string RoomId { get; set; } = null!;

    public string OwnerId { get; set; } = null!;

    public string TenantId { get; set; } = null!;

    public DateOnly StartDate { get; set; }

    public DateOnly EndDate { get; set; }

    public decimal Rent { get; set; }

    public decimal Deposit { get; set; }

    public string PaymentCycle { get; set; } = null!;

    public string? Terms { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? SignedAt { get; set; }

    public DateTime? TerminatedAt { get; set; }

    public decimal InitialElectricityReading { get; set; }

    public decimal InitialWaterReading { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<ContractMember> ContractMembers { get; set; } = new List<ContractMember>();

    public virtual ICollection<ContractService> ContractServices { get; set; } = new List<ContractService>();

    public virtual ICollection<ContractTermination> ContractTerminations { get; set; } = new List<ContractTermination>();

    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();

    public virtual User Owner { get; set; } = null!;

    public virtual Room Room { get; set; } = null!;

    public virtual User Tenant { get; set; } = null!;

    public virtual ViewingAppointment? ViewingAppointment { get; set; }
}
