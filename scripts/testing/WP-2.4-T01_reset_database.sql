USE master;
GO

/*
    OCB Platform v1.0.0
    Database Reset Script

    WARNING:
    This script is DESTRUCTIVE.

    If [ocb_platform] exists, this script will:
      1. Force active connections to disconnect.
      2. Roll back active transactions.
      3. Permanently DROP the database.
      4. Recreate an empty [ocb_platform] database.

    ALL DATA AND DATABASE OBJECTS IN [ocb_platform] WILL BE LOST.

    Use ONLY when a complete development/test environment reset
    is explicitly intended.

    DO NOT RUN AGAINST A DATABASE CONTAINING DATA THAT MUST BE PRESERVED.
*/

USE master;
GO

IF DB_ID(N'ocb_platform') IS NOT NULL
BEGIN
    ALTER DATABASE [ocb_platform]
        SET SINGLE_USER
        WITH ROLLBACK IMMEDIATE;

    DROP DATABASE [ocb_platform];
END;
GO

CREATE DATABASE [ocb_platform];
GO

-- Verify that the database was created successfully.
SELECT
    name,
    state_desc
FROM sys.databases
WHERE name = N'ocb_platform';
GO
