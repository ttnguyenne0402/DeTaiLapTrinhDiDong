namespace Backend.DT0s
{
    public class GoogleLoginRequestDTO
    {
        public string IdToken { get; set; } = string.Empty;
        public string Role { get; set; } = "tenant";
    }
}
