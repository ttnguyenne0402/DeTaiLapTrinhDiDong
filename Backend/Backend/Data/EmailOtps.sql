IF OBJECT_ID(N'dbo.email_otps', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.email_otps
    (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_email_otps PRIMARY KEY,
        user_id NVARCHAR(50) NOT NULL,
        purpose VARCHAR(30) NOT NULL,
        code_hash VARCHAR(64) NOT NULL,
        created_at DATETIME2 NOT NULL,
        expires_at DATETIME2 NOT NULL,
        used_at DATETIME2 NULL,
        attempts INT NOT NULL CONSTRAINT DF_email_otps_attempts DEFAULT (0),
        CONSTRAINT FK_email_otps_users
            FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE
    );

    CREATE INDEX IX_email_otps_user_id_purpose_created_at
        ON dbo.email_otps(user_id, purpose, created_at DESC);
END;
