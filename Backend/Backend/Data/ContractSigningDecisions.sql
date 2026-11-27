SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.contracts', 'signing_closed_at') IS NULL
    ALTER TABLE dbo.contracts ADD signing_closed_at DATETIME2 NULL;

IF COL_LENGTH('dbo.contracts', 'signing_close_reason') IS NULL
    ALTER TABLE dbo.contracts ADD signing_close_reason NVARCHAR(500) NULL;

DECLARE @dropStatusChecks NVARCHAR(MAX);
SELECT @dropStatusChecks = STRING_AGG(
    CAST(N'ALTER TABLE dbo.contracts DROP CONSTRAINT ' + QUOTENAME(c.name) + N';' AS NVARCHAR(MAX)), N' ')
FROM sys.check_constraints c
WHERE c.parent_object_id = OBJECT_ID(N'dbo.contracts')
AND (c.name = N'CK_contracts_status' OR c.parent_column_id =
    COLUMNPROPERTY(OBJECT_ID(N'dbo.contracts'), 'status', 'ColumnId'));

IF @dropStatusChecks IS NOT NULL EXEC sys.sp_executesql @dropStatusChecks;

ALTER TABLE dbo.contracts WITH CHECK ADD CONSTRAINT CK_contracts_status
CHECK (status IN ('draft', 'pending', 'active', 'expired', 'terminated', 'rejected', 'withdrawn'));

COMMIT TRANSACTION;
