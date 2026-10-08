using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Invoice
{
    public string Id { get; set; } = null!;

    public string InvoiceCode { get; set; } = null!;

    public string ContractId { get; set; } = null!;

    public string? UtilityReadingId { get; set; }

    public DateOnly BillingMonth { get; set; }

    public DateOnly IssueDate { get; set; }

    public DateOnly DueDate { get; set; }

    public decimal Subtotal { get; set; }

    public decimal? Discount { get; set; }

    public decimal Total { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Contract Contract { get; set; } = null!;

    public virtual ICollection<InvoiceItem> InvoiceItems { get; set; } = new List<InvoiceItem>();

    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();

    public virtual UtilityReading? UtilityReading { get; set; }
}
