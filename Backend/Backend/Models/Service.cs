using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Service
{
    public string Id { get; set; } = null!;

    public string? OwnerId { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public string Unit { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<ContractService> ContractServices { get; set; } = new List<ContractService>();

    public virtual ICollection<InvoiceItem> InvoiceItems { get; set; } = new List<InvoiceItem>();

    public virtual User? Owner { get; set; }

    public virtual ICollection<PropertyService> PropertyServices { get; set; } = new List<PropertyService>();
}
