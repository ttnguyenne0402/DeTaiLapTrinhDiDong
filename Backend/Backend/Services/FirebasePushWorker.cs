using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services;

public sealed class FirebasePushWorker(
    IServiceScopeFactory scopeFactory,
    IConfiguration configuration,
    ILogger<FirebasePushWorker> logger) : BackgroundService
{
    private const int MaxAttempts = 8;
    private const string ClaimSql = """
        SET NOCOUNT ON;
        DECLARE @claimed TABLE (
            id BIGINT, notification_id NVARCHAR(50), token_hash BINARY(32),
            attempt_count INT, created_at DATETIME2
        );

        ;WITH next_delivery AS (
            SELECT TOP (1) id, notification_id, token_hash, attempt_count, created_at, available_at, lease_id
            FROM dbo.push_deliveries WITH (UPDLOCK)
            WHERE available_at <= SYSUTCDATETIME()
            ORDER BY available_at, id
        )
        UPDATE next_delivery
        SET available_at = DATEADD(MINUTE, 2, SYSUTCDATETIME()),
            attempt_count = attempt_count + 1,
            lease_id = @leaseId
        OUTPUT inserted.id, inserted.notification_id, inserted.token_hash, inserted.attempt_count,
            inserted.created_at INTO @claimed;

        SELECT c.id, c.attempt_count, c.notification_id, n.user_id, n.title, d.token
        FROM @claimed c
        LEFT JOIN dbo.notifications n ON n.id = c.notification_id AND n.read_at IS NULL
        LEFT JOIN dbo.push_devices d ON d.token_hash = c.token_hash AND d.user_id = n.user_id
            AND c.created_at >= DATEADD(HOUR, -24, SYSUTCDATETIME());
        """;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (string.IsNullOrWhiteSpace(configuration["Firebase:ProjectId"])) return;

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (await ProcessNextAsync(stoppingToken)) continue;
                await Task.Delay(TimeSpan.FromSeconds(2), stoppingToken);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogWarning("Unable to process FCM queue ({ErrorType})", ex.GetType().Name);
                await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);
            }
        }
    }

    private async Task<bool> ProcessNextAsync(CancellationToken stoppingToken)
    {
        using var scope = scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<QuanLyPhongTroContext>();
        var push = scope.ServiceProvider.GetRequiredService<FirebasePushService>();
        var leaseId = Guid.NewGuid();
        var claimed = await ClaimAsync(db, leaseId, stoppingToken);
        if (claimed == null) return false;

        var completed = claimed.Delivery == null;
        if (claimed.Delivery != null && claimed.Attempts <= MaxAttempts)
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(stoppingToken);
            timeout.CancelAfter(TimeSpan.FromSeconds(20));
            try
            {
                completed = await push.SendAsync(claimed.Delivery, timeout.Token);
            }
            catch (Exception ex) when (!stoppingToken.IsCancellationRequested)
            {
                logger.LogWarning("FCM delivery {DeliveryId} failed ({ErrorType})", claimed.Id, ex.GetType().Name);
            }
        }

        if (completed || claimed.Attempts >= MaxAttempts)
        {
            await db.Database.ExecuteSqlInterpolatedAsync(
                $"DELETE FROM dbo.push_deliveries WHERE id = {claimed.Id} AND lease_id = {leaseId}",
                stoppingToken);
        }
        else
        {
            var delaySeconds = Math.Min(300, 10 * (1 << (claimed.Attempts - 1)));
            await db.Database.ExecuteSqlInterpolatedAsync($"""
                UPDATE dbo.push_deliveries
                SET available_at = DATEADD(SECOND, {delaySeconds}, SYSUTCDATETIME()), lease_id = NULL
                WHERE id = {claimed.Id} AND lease_id = {leaseId}
                """, stoppingToken);
        }
        return true;
    }

    private static async Task<ClaimedDelivery?> ClaimAsync(
        QuanLyPhongTroContext db, Guid leaseId, CancellationToken cancellationToken)
    {
        await db.Database.OpenConnectionAsync(cancellationToken);
        try
        {
            await using var command = db.Database.GetDbConnection().CreateCommand();
            command.CommandText = ClaimSql;
            var parameter = command.CreateParameter();
            parameter.ParameterName = "@leaseId";
            parameter.Value = leaseId;
            command.Parameters.Add(parameter);

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            if (!await reader.ReadAsync(cancellationToken)) return null;

            var delivery = reader.IsDBNull(5) ? null : new FirebasePushService.PushDelivery(
                reader.GetString(2), reader.GetString(3), reader.GetString(4), reader.GetString(5));
            return new ClaimedDelivery(reader.GetInt64(0), reader.GetInt32(1), delivery);
        }
        finally
        {
            await db.Database.CloseConnectionAsync();
        }
    }

    private sealed record ClaimedDelivery(long Id, int Attempts, FirebasePushService.PushDelivery? Delivery);
}
