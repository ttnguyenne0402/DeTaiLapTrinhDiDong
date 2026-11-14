namespace Backend.DTOs
{
    public class RevenueChartItemDto
    {
        public string Label { get; set; } = null!;
        public double Value { get; set; } // Triệu VNĐ
    }

    public class UserShareItemDto
    {
        public string RoleName { get; set; } = null!;
        public double Percentage { get; set; }
        public int Count { get; set; }
    }

    public class TopPropertyItemDto
    {
        public string Name { get; set; } = null!;
        public string Owner { get; set; } = null!;
        public int Rooms { get; set; }
        public decimal Commission { get; set; }
        public string OccupancyRate { get; set; } = "0%";
    }

    public class AdminStatsResponseDto
    {
        public decimal TotalCommission { get; set; }
        public int TotalProperties { get; set; }
        public int TotalUsers { get; set; }
        public int PendingRequests { get; set; }

        public List<RevenueChartItemDto> RevenueChart { get; set; } = new();
        public List<UserShareItemDto> UserShare { get; set; } = new();
        public List<TopPropertyItemDto> TopProperties { get; set; } = new();
    }
}