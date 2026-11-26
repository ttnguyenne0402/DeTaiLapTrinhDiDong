using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Backend.Models;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public sealed class FirebasePushService(
    QuanLyPhongTroContext context,
    IHttpClientFactory clients,
    IConfiguration configuration,
    ILogger<FirebasePushService> logger)
{
    private const string MessagingScope = "https://www.googleapis.com/auth/firebase.messaging";

    public bool Enabled => !string.IsNullOrWhiteSpace(configuration["Firebase:ProjectId"]);

    public Task RegisterAsync(string userId, string token, CancellationToken cancellationToken)
    {
        var hash = HashToken(token);
        return context.Database.ExecuteSqlInterpolatedAsync($"""
            MERGE dbo.push_devices WITH (HOLDLOCK) AS device
            USING (SELECT {hash} AS token_hash) AS incoming
            ON device.token_hash = incoming.token_hash
            WHEN MATCHED THEN UPDATE SET token = {token}, user_id = {userId}
            WHEN NOT MATCHED THEN INSERT (token_hash, token, user_id) VALUES ({hash}, {token}, {userId});
            """, cancellationToken);
    }

    public Task UnregisterAsync(string userId, string token, CancellationToken cancellationToken)
    {
        var hash = HashToken(token);
        return context.Database.ExecuteSqlInterpolatedAsync(
            $"DELETE FROM dbo.push_devices WHERE token_hash = {hash} AND user_id = {userId}",
            cancellationToken);
    }

    public async Task<bool> SendAsync(PushDelivery delivery, CancellationToken cancellationToken)
    {
        var projectId = configuration["Firebase:ProjectId"]!;
        var credential = (await GoogleCredential.GetApplicationDefaultAsync(cancellationToken))
            .CreateScoped(MessagingScope);
        var accessToken = await credential.UnderlyingCredential
            .GetAccessTokenForRequestAsync(cancellationToken: cancellationToken);

        using var client = clients.CreateClient();
        using var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://fcm.googleapis.com/v1/projects/{Uri.EscapeDataString(projectId)}/messages:send");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        request.Content = JsonContent.Create(new
        {
            message = new
            {
                token = delivery.Token,
                notification = new
                {
                    title = delivery.Title,
                    body = "Mở ứng dụng để xem nội dung.",
                },
                data = new
                {
                    notificationId = delivery.NotificationId,
                    userId = delivery.UserId,
                },
                android = new
                {
                    priority = "HIGH",
                    ttl = "3600s",
                    notification = new
                    {
                        channel_id = "tro_oi_notifications",
                        tag = delivery.NotificationId,
                    },
                },
            },
        });

        using var response = await client.SendAsync(request, cancellationToken);
        if (response.IsSuccessStatusCode) return true;

        if (response.StatusCode == System.Net.HttpStatusCode.NotFound &&
            await IsUnregisteredAsync(response, cancellationToken))
        {
            await UnregisterAsync(delivery.UserId, delivery.Token, cancellationToken);
            return true;
        }

        logger.LogWarning("FCM rejected notification {NotificationId} with status {Status}",
            delivery.NotificationId, response.StatusCode);
        var status = (int)response.StatusCode;
        return status is >= 400 and < 500 and not (401 or 403 or 408 or 429);
    }

    private static async Task<bool> IsUnregisteredAsync(
        HttpResponseMessage response, CancellationToken cancellationToken)
    {
        using var payload = await response.Content.ReadFromJsonAsync<JsonDocument>(
            cancellationToken: cancellationToken);
        return payload != null && payload.RootElement.TryGetProperty("error", out var error) &&
            error.TryGetProperty("details", out var details) &&
            details.EnumerateArray().Any(entry =>
                entry.TryGetProperty("errorCode", out var code) && code.GetString() == "UNREGISTERED");
    }

    public sealed record PushDelivery(string NotificationId, string UserId, string Title, string Token);

    private static byte[] HashToken(string token) => SHA256.HashData(Encoding.UTF8.GetBytes(token));
}
