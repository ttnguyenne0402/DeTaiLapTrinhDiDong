namespace Backend.DTOs
{
    public class NotificationResponseDTO
    {
        public string Id { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public string Type { get; set; } = null!; 
        public bool IsRead { get; set; } 
        public string CreatedAt { get; set; } = null!; 
    }
}