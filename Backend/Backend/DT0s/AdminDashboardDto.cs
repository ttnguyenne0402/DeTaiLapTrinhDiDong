namespace Backend.DT0s
{
    public class AdminDashboardDto
    {
        public int TotalUsers { get; set; }
        public int TotalRooms { get; set; }
        public int PendingPosts { get; set; }
        public int ApprovedPosts { get; set; }
        public int RejectedPosts { get; set; }
    }
}
