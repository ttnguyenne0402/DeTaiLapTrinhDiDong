namespace Backend.DT0s
{
    public class AdminDashboardDto
    {
        public int TotalUsers { get; set; }
        public int TotalRooms { get; set; }
        public int ApprovedPosts { get; set; }
        public int PendingOrReportedPosts { get; set; } // hoặc tính theo Review/Report
        public List<ChartDataPointDto> ChartData { get; set; } = new();
    }

    public class ChartDataPointDto
    {
        public string Label { get; set; } = string.Empty;
        public double Views { get; set; }
        public double Searches { get; set; }
    }
}
