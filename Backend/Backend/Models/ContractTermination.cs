using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class ContractTermination
{
    public string Id { get; set; } = null!;

    public string ContractId { get; set; } = null!;

    public decimal DepositAmount { get; set; }

    public decimal? DeductionAmount { get; set; }

    public string? DeductionReason { get; set; }

    public decimal RefundAmount { get; set; }

    public DateOnly ReturnDate { get; set; }

    public string? Note { get; set; }

    public virtual Contract Contract { get; set; } = null!;
}
