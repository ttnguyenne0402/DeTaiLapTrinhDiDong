using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class Favorite
{
    public string Id { get; set; } = null!;

    public string UserId { get; set; } = null!;

    public string RoomId { get; set; } = null!;

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual Room Room { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
