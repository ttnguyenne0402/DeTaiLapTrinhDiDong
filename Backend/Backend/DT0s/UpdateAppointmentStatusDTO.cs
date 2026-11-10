using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class UpdateAppointmentStatusDTO
    {
        [Required]
        public string Status { get; set; } = null!; 
    }
}