
USE master
GO

SELECT
    @@SERVERNAME AS server_name,
    DB_NAME() AS current_database,
    @@VERSION AS sql_server_version;
GO

SELECT
    'VS Code SQL validation successful' AS validation_result,
    GETDATE() AS validation_time;
GO

SELECT
    @@SERVERNAME AS server_name,
    DB_NAME() AS current_database,
    'OCB database development workflow validation successful' AS validation_result,
    GETDATE() AS validation_time;
GO