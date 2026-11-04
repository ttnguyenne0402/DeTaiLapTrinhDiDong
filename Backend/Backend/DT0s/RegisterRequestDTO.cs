using System.ComponentModel.DataAnnotations;

namespace Backend.DT0s
{
    public class RegisterRequestDTO
    {
        [Required]
        public string FullName { get; set; } = null!;

        [Required]
        public string EmailOrPhone { get; set; } = null!;

        [Required]
        public string Password { get; set; } = null!;

        [Required]
        public string Role { get; set; } = "tenant";
    }
}
