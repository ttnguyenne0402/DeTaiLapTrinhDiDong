using System.Collections.Generic;

namespace Backend.DT0s
{
    public class AiChatMessageDto
    {
        public string Role { get; set; } = "user"; // "user" hoặc "model"
        public string Text { get; set; } = string.Empty;
    }

    public class AiChatRequestDto
    {
        public string Message { get; set; } = string.Empty;
        public List<AiChatMessageDto>? History { get; set; }
        public string? UserId { get; set; }
        public string? Scope { get; set; }
    }

    public class AiChatResponseDto
    {
        public string Reply { get; set; } = string.Empty;
        public bool Success { get; set; } = true;
        public string? Error { get; set; }
    }
}
