namespace Backend.Services;

public sealed class PostImageStorage
{
    public const string RequestPath = "/uploads/posts";
    public const int MaxImages = 6;
    public const int MaxImageBytes = 4 * 1024 * 1024;
    public const int MaxRequestBytes = MaxImages * MaxImageBytes + 1024 * 1024;

    public PostImageStorage(IWebHostEnvironment environment)
    {
        DirectoryPath = Path.Combine(environment.ContentRootPath, "App_Data", "post-images");
        Directory.CreateDirectory(DirectoryPath);
    }

    public string DirectoryPath { get; }

    public async Task<string> SaveAsync(IFormFile file, CancellationToken cancellationToken)
    {
        if (file.Length < 12 || file.Length > MaxImageBytes)
            throw new InvalidDataException("Mỗi ảnh phải có dung lượng tối đa 4 MB.");

        await using var input = file.OpenReadStream();
        var header = new byte[12];
        await input.ReadExactlyAsync(header, cancellationToken);
        var name = Guid.NewGuid().ToString("N") + GetExtension(header);
        var destination = Path.Combine(DirectoryPath, name);
        try
        {
            await using var output = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            await output.WriteAsync(header, cancellationToken);
            await input.CopyToAsync(output, cancellationToken);
            return $"{RequestPath}/{name}";
        }
        catch
        {
            File.Delete(destination);
            throw;
        }
    }

    public void DeleteNewImage(string reference)
    {
        File.Delete(Path.Combine(DirectoryPath, Path.GetFileName(reference)));
    }

    public static bool IsSharedReference(string? reference)
    {
        if (string.IsNullOrWhiteSpace(reference) || reference.Length > 255) return false;
        return reference.StartsWith(RequestPath + "/", StringComparison.Ordinal) ||
            reference.StartsWith("frontend/assets/images/", StringComparison.Ordinal) ||
            reference.StartsWith("assets/images/", StringComparison.Ordinal) ||
            (Uri.TryCreate(reference, UriKind.Absolute, out var uri) &&
             (uri.Scheme == Uri.UriSchemeHttps || uri.Scheme == Uri.UriSchemeHttp));
    }

    private static string GetExtension(byte[] header)
    {
        if (header.AsSpan(0, 3).SequenceEqual(new byte[] { 0xFF, 0xD8, 0xFF })) return ".jpg";
        if (header.AsSpan(0, 8).SequenceEqual(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A })) return ".png";
        if (header.AsSpan(0, 4).SequenceEqual("RIFF"u8) && header.AsSpan(8, 4).SequenceEqual("WEBP"u8))
            return ".webp";
        if (header.AsSpan(0, 6).SequenceEqual("GIF87a"u8) || header.AsSpan(0, 6).SequenceEqual("GIF89a"u8))
            return ".gif";
        throw new InvalidDataException("Ảnh phải có định dạng JPEG, PNG, WebP hoặc GIF.");
    }
}
