using System;
using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs
{
    public class ViewingAppointmentRequestDTO
    {
        [Required]
        public string RoomId { get; set; } = null!;

        [Required]
        public string TenantId { get; set; } = null!;

        [Required]
        public DateTime AppointmentDate { get; set; }

        [Required]
        public TimeSpan AppointmentTime { get; set; }

        [Required]
        [StringLength(20)]
        public string Phone { get; set; } = null!;

        public string? Message { get; set; }
    }
}