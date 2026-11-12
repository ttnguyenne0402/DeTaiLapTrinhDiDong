using System.ComponentModel.DataAnnotations;

namespace Backend.DT0s
{
    public class RegisterRequestDTO
    {
        [Required]
        public string FullName { get; set; } = null!;

        [Required, EmailAddress, MaxLength(255)]
        public string Email { get; set; } = null!;

        [Required, Phone, MaxLength(20)]
        public string Phone { get; set; } = null!;

        [Required, MinLength(8), MaxLength(128)]
        public string Password { get; set; } = null!;

        [Required]
        public string Role { get; set; } = "tenant";
    }
}
