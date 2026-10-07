using System;
using System.Collections.Generic;

namespace Backend.Models;

public partial class RentalPostImage
{
    public string Id { get; set; } = null!;

    public string RentalPostId { get; set; } = null!;

    public string ImagePath { get; set; } = null!;

    public bool? IsThumbnail { get; set; }

    public int? SortOrder { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual RentalPost RentalPost { get; set; } = null!;
}
