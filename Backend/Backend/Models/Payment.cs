using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Payment
{
    public string Id { get; set; } = null!;

    public string PaymentCode { get; set; } = null!;

    public string InvoiceId { get; set; } = null!;

    public string PayerId { get; set; } = null!;

    public decimal Amount { get; set; }

    public string Method { get; set; } = null!;

    public string? TransactionCode { get; set; }

    public DateTime? PaidAt { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Invoice Invoice { get; set; } = null!;

    public virtual User Payer { get; set; } = null!;
}
