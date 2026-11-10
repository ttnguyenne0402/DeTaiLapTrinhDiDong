namespace Backend.DT0s
{
    public class PostDto
    {
        public string Id { get; set; } = string.Empty;
        public string RoomId { get; set; } = string.Empty;
        public string RoomName { get; set; } = string.Empty;
        public string PropertyId { get; set; } = string.Empty;
        public string PropertyName { get; set; } = string.Empty;
        public string PropertyAddress { get; set; } = string.Empty;
        public string Room { get; set; } = string.Empty; // "Phòng 201 - Chung cư Mini Q7"
        public decimal RoomArea { get; set; }
        public decimal RoomDeposit { get; set; }
        public int RoomMaxPeople { get; set; }
        public int? RoomFloor { get; set; }
        public string RoomStatus { get; set; } = string.Empty;
        public string RoomDescription { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string PriceFormatted { get; set; } = string.Empty; // "4.000.000đ/tháng"
        public List<string> Amenities { get; set; } = new();
        public int Views { get; set; }
        public int Likes { get; set; }
        public string Date { get; set; } = string.Empty; // "24/09/2026"
        public string Status { get; set; } = string.Empty; // active, pending, draft, rejected, hidden
        public string? SubmitNote { get; set; }
        public string? RejectReason { get; set; }
        public string Image { get; set; } = "frontend/assets/images/anhPhongDemo.jpg";
        public List<string> Images { get; set; } = new();
    }

    public class CreatePostDto
    {
        public string RoomId { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal? Price { get; set; }
        public List<string>? Amenities { get; set; }
        public string Status { get; set; } = "pending"; // pending hoặc draft
        public string? SubmitNote { get; set; }
        public List<string>? Images { get; set; }
    }

    public class UpdatePostDto
    {
        public string? RoomId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal? Price { get; set; }
        public List<string>? Amenities { get; set; }
        public string Status { get; set; } = "pending";
        public string? SubmitNote { get; set; }
        public List<string>? Images { get; set; }
    }

    public class UpdatePostStatusDto
    {
        public string Status { get; set; } = string.Empty; // active, hidden, pending, draft
    }
}

