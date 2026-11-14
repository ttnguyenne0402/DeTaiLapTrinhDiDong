using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    
    public class ProcessMaintenanceDto
    {
        [Required]
        public string Status { get; set; } = null!; 

        public string? OwnerNote { get; set; } 
    }
    // DTO dùng cho Chủ nhà tự tạo sự cố mới
    public class CreateMaintenanceByOwnerDto
    {
        [Required]
        public string RoomId { get; set; } = null!;

        [Required]
        public string Title { get; set; } = null!;

        public string? Description { get; set; }

        public string? ImageBase64 { get; set; } 
    }
}