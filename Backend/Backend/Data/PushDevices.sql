IF OBJECT_ID(N'dbo.push_devices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.push_devices
    (
        token_hash BINARY(32) NOT NULL PRIMARY KEY,
        token NVARCHAR(2048) NOT NULL,
        user_id NVARCHAR(50) NOT NULL REFERENCES dbo.users(id) ON DELETE CASCADE
    );

    CREATE INDEX IX_push_devices_user_id ON dbo.push_devices(user_id);
END;
GO

IF OBJECT_ID(N'dbo.push_deliveries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.push_deliveries
    (
        id BIGINT IDENTITY PRIMARY KEY,
        notification_id NVARCHAR(50) NOT NULL REFERENCES dbo.notifications(id) ON DELETE CASCADE,
        token_hash BINARY(32) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        available_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        attempt_count INT NOT NULL DEFAULT 0,
        lease_id UNIQUEIDENTIFIER NULL
    );

    CREATE INDEX IX_push_deliveries_available_at ON dbo.push_deliveries(available_at, id);
    CREATE INDEX IX_push_deliveries_notification_id ON dbo.push_deliveries(notification_id);
END;
GO

CREATE OR ALTER TRIGGER dbo.QueueFirebasePush ON dbo.notifications
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT dbo.push_deliveries (notification_id, token_hash)
    SELECT n.id, d.token_hash
    FROM inserted n
    INNER JOIN dbo.push_devices d ON d.user_id = n.user_id
    WHERE n.read_at IS NULL;
END;
GO
