using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    
    public class ProcessMaintenanceDto
    {
        [Required]
        public string Status { get; set; } = null!; 

        public string? OwnerNote { get; set; } 
    }
}