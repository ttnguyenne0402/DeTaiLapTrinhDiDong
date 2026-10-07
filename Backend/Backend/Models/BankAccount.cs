using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class BankAccount
{
    public string Id { get; set; } = null!;

    public string UserId { get; set; } = null!;

    public string BankCode { get; set; } = null!;

    public string? BankName { get; set; }

    public string AccountNumber { get; set; } = null!;

    public string AccountHolder { get; set; } = null!;

    public bool IsDefault { get; set; }

    public string Status { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual User User { get; set; } = null!;
}
