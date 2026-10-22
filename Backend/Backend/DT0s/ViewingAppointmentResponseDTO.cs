namespace Backend.DTOs
{
    public class ViewingAppointmentResponseDTO
    {
        public string Id { get; set; } = null!;
        public string RoomName { get; set; } = null!;
        public string Address { get; set; } = null!;

       
        public string Date { get; set; } = null!; 
        public string Time { get; set; } = null!; 

        public string Status { get; set; } = null!;
        public string? Message { get; set; }
        public string? OwnerNote { get; set; }
    }
}