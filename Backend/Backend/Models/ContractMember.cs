using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class ContractMember
{
    public string Id { get; set; } = null!;

    public string ContractId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string IdentityCard { get; set; } = null!;

    public string? Phone { get; set; }

    public string? Relationship { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Contract Contract { get; set; } = null!;
}
