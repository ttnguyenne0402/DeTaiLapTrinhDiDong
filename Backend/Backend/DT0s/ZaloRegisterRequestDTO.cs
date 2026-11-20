namespace Backend.DT0s
{
    public class ZaloRegisterRequestDTO
    {
        public string AccessToken { get; set; } = string.Empty;
        public string Role { get; set; } = "tenant";
        public string Phone { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}
