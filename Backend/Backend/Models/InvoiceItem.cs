using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class InvoiceItem
{
    public string Id { get; set; } = null!;

    public string InvoiceId { get; set; } = null!;

    public string Type { get; set; } = null!;

    public string? Description { get; set; }

    public decimal? Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public decimal Amount { get; set; }

    public string? ServiceId { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Invoice Invoice { get; set; } = null!;

    public virtual Service? Service { get; set; }
}
