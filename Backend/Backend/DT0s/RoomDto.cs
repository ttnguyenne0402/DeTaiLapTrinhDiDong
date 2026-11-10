namespace Backend.DT0s
{
    public class RoomDto
    {
        public string Id { get; set; } = string.Empty;
        public string PropertyId { get; set; } = string.Empty;
        public string PropertyName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal Area { get; set; }
        public int? Floor { get; set; }
        public decimal Price { get; set; }
        public decimal Deposit { get; set; }
        public int MaxPeople { get; set; }
        public string Status { get; set; } = string.Empty; // available, rented, maintenance
        public string StatusText { get; set; } = string.Empty; // Còn trống, Đang cho thuê, Bảo trì
        public bool IsRented { get; set; }
        public string Detail { get; set; } = string.Empty; // "25 m² - Tầng 2"
        public string PriceFormatted { get; set; } = string.Empty; // "4.000.000đ"
        public string Images { get; set; } = "frontend/assets/images/anhPhongDemo.jpg";
        public string? Description { get; set; }
    }

    public class CreateRoomDto
    {
        public string PropertyId { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public decimal Area { get; set; }
        public int? Floor { get; set; } = 1;
        public decimal Price { get; set; }
        public decimal? Deposit { get; set; }
        public int? MaxPeople { get; set; } = 2;
        public string Status { get; set; } = "available"; // available, rented, maintenance
        public string? Description { get; set; }
        public string? Images { get; set; } = "frontend/assets/images/anhPhongDemo.jpg";
    }

    public class UpdateRoomDto
    {
        public string? PropertyId { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Area { get; set; }
        public int? Floor { get; set; }
        public decimal Price { get; set; }
        public decimal? Deposit { get; set; }
        public int? MaxPeople { get; set; }
        public string Status { get; set; } = "available";
        public string? Description { get; set; }
        public string? Images { get; set; }
    }
}

