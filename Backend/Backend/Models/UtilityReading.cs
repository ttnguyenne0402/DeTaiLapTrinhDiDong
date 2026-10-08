using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class UtilityReading
{
    public string Id { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public DateOnly Month { get; set; }

    public decimal ElectricityOld { get; set; }

    public decimal ElectricityNew { get; set; }

    public decimal ElectricityPrice { get; set; }

    public decimal WaterOld { get; set; }

    public decimal WaterNew { get; set; }

    public decimal WaterPrice { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();

    public virtual Room Room { get; set; } = null!;
}
