USE [ocb_platform];
GO

/*
    Schema Deployment Script

    Purpose:
        Creates the seven approved database schemas required by the OCB Platform v1.0.0 database structure.

    The script:
        - Checks whether each approved schema already exists.
        - Creates the schema if it does not exist.
        - Leaves existing schemas unchanged.
        - Reports the deployment status through PRINT messages.

    Approved schemas:
        ocb
        ananse
        sikacredit
        oman_remit
        wallet
        ledger
        ref

    The script is non-destructive and safe to re-run.
*/

PRINT '===============================================================';
PRINT '>>> STARTING OCB_PLATFORM SCHEMA DEPLOYMENT <<<';
PRINT '===============================================================';


/* OCB */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ocb')
BEGIN
    PRINT '>> ocb schema not found. Creating...';

    EXEC ('CREATE SCHEMA [ocb]');

    PRINT '>> ocb schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> ocb schema already exists. No action required.';
END;


/* Ananse */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ananse')
BEGIN
    PRINT '>> ananse schema not found. Creating...';

    EXEC ('CREATE SCHEMA [ananse]');

    PRINT '>> ananse schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> ananse schema already exists. No action required.';
END;


/* SikaCredit */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sikacredit')
BEGIN
    PRINT '>> sikacredit schema not found. Creating...';

    EXEC ('CREATE SCHEMA [sikacredit]');

    PRINT '>> sikacredit schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> sikacredit schema already exists. No action required.';
END;


/* Oman Remit */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'oman_remit')
BEGIN
    PRINT '>> oman_remit schema not found. Creating...';

    EXEC ('CREATE SCHEMA [oman_remit]');

    PRINT '>> oman_remit schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> oman_remit schema already exists. No action required.';
END;


/* Wallet */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'wallet')
BEGIN
    PRINT '>> wallet schema not found. Creating...';

    EXEC ('CREATE SCHEMA [wallet]');

    PRINT '>> wallet schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> wallet schema already exists. No action required.';
END;


/* Ledger */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ledger')
BEGIN
    PRINT '>> ledger schema not found. Creating...';

    EXEC ('CREATE SCHEMA [ledger]');

    PRINT '>> ledger schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> ledger schema already exists. No action required.';
END;


/* Reference */

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ref')
BEGIN
    PRINT '>> ref schema not found. Creating...';

    EXEC ('CREATE SCHEMA [ref]');

    PRINT '>> ref schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> ref schema already exists. No action required.';
END;


PRINT '===============================================================';
PRINT '>>> SCHEMA DEPLOYMENT COMPLETE <<<';
PRINT '===============================================================';

GO


/*
    Schema Validation

    Purpose:
        Confirms that all seven approved OCB Platform schemas exist after deployment.

    The validation:
        1. Compares the expected schema count with the actual count.
        2. Displays the approved schemas currently present.

    This validation checks schema existence only.
    It does not validate schema ownership, tables, objects, or permissions.
*/

DECLARE @expected_schema_count INT = 7;

SELECT
    @expected_schema_count AS expected_schema_count,
    COUNT(*) AS actual_schema_count,
    CASE
        WHEN @expected_schema_count = COUNT(*)
            THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM sys.schemas
WHERE name IN ('ocb', 'ananse', 'sikacredit', 'oman_remit', 'wallet', 'ledger', 'ref');


/* Display the approved schemas currently present. */

SELECT
    s.schema_id,
    s.name AS schema_name
FROM sys.schemas s
WHERE name IN ('ocb', 'ananse', 'sikacredit', 'oman_remit', 'wallet', 'ledger', 'ref')
ORDER BY s.schema_id ASC;
GO