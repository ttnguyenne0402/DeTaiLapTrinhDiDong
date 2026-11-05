using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class MaintenanceRequestDTO
    {
        [Required]
        public string RoomId { get; set; } = null!;

        [Required]
        public string TenantId { get; set; } = null!;

        [Required]
        public string Title { get; set; } = null!;

        [Required]
        public string Description { get; set; } = null!;

        [Required]
        public string Priority { get; set; } = null!; 

        public string? Image { get; set; } 
    }
}