using System.ComponentModel.DataAnnotations;

namespace Backend.DT0s
{
    public class LoginRequestDTO
    {
        [Required]
        public string EmailOrPhone { get; set; } = null!;

        [Required]
        public string Password { get; set; } = null!;
    }
}
