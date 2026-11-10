namespace Backend.DT0s
{
    public class OwnerDashboardResponseDTO
    {
        public string OwnerName { get; set; } = string.Empty;
        public string OwnerRole { get; set; } = string.Empty;
        public int TotalRentedRooms { get; set; }
        public int ScheduledAppointments { get; set; }
        public int EmptyRooms { get; set; }
        public int RepairRequests { get; set; }
        public List<DashboardAppointmentDto> UpcomingAppointments { get; set; } = new();
    }

    public class DashboardAppointmentDto
    {
        public string Time { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string RoomInfo { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
    }
}