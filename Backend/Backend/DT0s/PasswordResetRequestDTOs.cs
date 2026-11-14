using System.ComponentModel.DataAnnotations;

namespace Backend.DT0s;

public sealed class ForgotPasswordRequestDTO
{
    [Required, EmailAddress, MaxLength(255)]
    public string Email { get; set; } = null!;
}

public sealed class ResetPasswordRequestDTO
{
    [Required, EmailAddress, MaxLength(255)]
    public string Email { get; set; } = null!;

    [Required, StringLength(6, MinimumLength = 6)]
    public string Code { get; set; } = null!;

    [Required, MinLength(8), MaxLength(128)]
    public string NewPassword { get; set; } = null!;
}

