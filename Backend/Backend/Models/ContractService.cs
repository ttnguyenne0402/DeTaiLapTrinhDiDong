using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class ContractService
{
    public string Id { get; set; } = null!;

    public string ContractId { get; set; } = null!;

    public string ServiceId { get; set; } = null!;

    public decimal? Quantity { get; set; }

    public decimal UnitPrice { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Contract Contract { get; set; } = null!;

    public virtual Service Service { get; set; } = null!;
}
