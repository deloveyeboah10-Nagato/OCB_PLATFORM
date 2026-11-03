USE master;
GO

/*
    OCB Platform v1.0.0
    Database Create Script

    If [ocb_platform] doesn't exist, this script will create an empty [ocb_platform] database.
    If [ocb_platform] already exists, this script leaves it unchanged.

*/
IF DB_ID(N'ocb_platform') IS NULL
BEGIN
    CREATE DATABASE [ocb_platform];
    PRINT 'ocb_platform CREATED SUCCESSFULLY'
END;
GO

-- Verifying that the DB state is ONLINE
SELECT
    name,
    state_desc
FROM sys.databases
WHERE name = N'ocb_platform';
GO


