namespace Backend.DTOs
{
    public class MaintenanceResponseDTO
    {
        public string Id { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string Priority { get; set; } = null!;
        public string Status { get; set; } = null!; 
        public string CreatedAt { get; set; } = null!;
    }
}