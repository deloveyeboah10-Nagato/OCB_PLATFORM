USE [ocb_platform];
GO

/*
    OCB Platform v1.0.0
    Table Deployment Script

    This procedure creates the approved OCB Platform tables if they do
    not already exist.

    The deployment is NON-DESTRUCTIVE:
        - Existing tables are not dropped.
        - Existing table data is not modified.
        - Existing tables are left unchanged.

    The procedure is therefore safe to re-run against an existing
    deployment, provided that the existing tables conform to the
    approved schema.

    IMPORTANT:
        This procedure does not alter existing table definitions.
        Schema changes to existing tables must be handled through a
        controlled migration/change process.
*/

-- Wrapping script in procedure.
CREATE OR ALTER PROCEDURE ocb_platform_tables_deployment
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @start_time DATETIME2(3),
        @end_time   DATETIME2(3);

    SET @start_time = SYSDATETIME();

    PRINT '=========================================================================================================================';
    PRINT '>>> STARTING OCB_PLATFORM TABLE DEPLOYMENT <<<';
    PRINT '>>> CHECKING IF TABLES EXIST <<<';
    PRINT '-------------------------------------------------------------------------------------------------------------------------';

    IF OBJECT_ID(N'ocb.[customer]', 'U') IS NULL
        CREATE TABLE ocb.[customer]
        (
            ocb_customer_id BIGINT IDENTITY(1,1) NOT NULL
        );


    IF OBJECT_ID(N'ocb.[customer_identity]', 'U') IS NULL
        CREATE TABLE ocb.[customer_identity]
        (
            ocb_customer_id BIGINT NOT NULL,
            source_entity NVARCHAR(50) NOT NULL,
            source_customer_id VARCHAR(100) NOT NULL,
            created_at DATETIME2(3) NOT NULL
        );

    IF OBJECT_ID(N'ananse.[customer]', 'U') IS NULL
        CREATE TABLE ananse.[customer]
        (
            customer_id VARCHAR(100) NOT NULL,
            first_name NVARCHAR(150) NOT NULL,
            last_name NVARCHAR(150) NOT NULL,
            date_of_birth DATE NOT NULL,
            nationality NVARCHAR(150) NOT NULL,
            occupation NVARCHAR(150) NULL,
            phone_number VARCHAR(30) NOT NULL,
            email NVARCHAR(150) NULL,
            created_at DATETIME2(3) NOT NULL
        );


    IF OBJECT_ID(N'ananse.[transaction]', 'U') IS NULL
        CREATE TABLE ananse.[transaction]
        (
            transaction_id VARCHAR(100) NOT NULL,
            customer_id VARCHAR(100) NOT NULL,
            wallet_id BIGINT NOT NULL,
            transaction_type VARCHAR(100) NOT NULL,
            transaction_status VARCHAR(100) NOT NULL,
            transaction_timestamp DATETIME2(3) NOT NULL,
            transaction_location NVARCHAR(150) NOT NULL,
            transaction_channel VARCHAR(100) NOT NULL,
            device_id VARCHAR(100) NOT NULL,
            amount DECIMAL(18,4) NOT NULL,
            currency CHAR(3) NOT NULL
        );


    IF OBJECT_ID(N'wallet.[wallet]', 'U') IS NULL
        CREATE TABLE wallet.[wallet]
        (
            wallet_id BIGINT NOT NULL
        );


    IF OBJECT_ID(N'sikacredit.[customer]', 'U') IS NULL
        CREATE TABLE sikacredit.[customer]
        (
            customer_id VARCHAR(100) NOT NULL,
            first_name NVARCHAR(150) NOT NULL,
            last_name NVARCHAR(150) NOT NULL,
            date_of_birth DATE NOT NULL,
            nationality NVARCHAR(150) NOT NULL,
            occupation NVARCHAR(150) NULL,
            phone_number VARCHAR(30) NOT NULL,
            email NVARCHAR(150) NULL,
            created_at DATETIME2(3) NOT NULL
        );


    IF OBJECT_ID(N'sikacredit.[loan]', 'U') IS NULL
        CREATE TABLE sikacredit.[loan]
        (
            loan_id VARCHAR(100) NOT NULL,
            customer_id VARCHAR(100) NOT NULL,
            disbursement_timestamp DATETIME2(3) NULL,
            disbursement_location NVARCHAR(150) NOT NULL,
            maturity_date DATE NOT NULL,
            principal_amount DECIMAL(18,4) NOT NULL,
            interest_rate DECIMAL(5,4) NOT NULL,
            currency CHAR(3) NOT NULL
        );


    IF OBJECT_ID(N'sikacredit.[repayment]', 'U') IS NULL
        CREATE TABLE sikacredit.[repayment]
        (
            repayment_id VARCHAR(100) NOT NULL,
            loan_id VARCHAR(100) NOT NULL,
            repayment_amount DECIMAL(18,4) NOT NULL,
            repayment_timestamp DATETIME2(3) NOT NULL,
            repayment_location NVARCHAR(150) NOT NULL
        );


    IF OBJECT_ID(N'oman_remit.[customer]', 'U') IS NULL
        CREATE TABLE oman_remit.[customer]
        (
            customer_id VARCHAR(100) NOT NULL,
            first_name NVARCHAR(150) NOT NULL,
            last_name NVARCHAR(150) NOT NULL,
            date_of_birth DATE NOT NULL,
            nationality NVARCHAR(150) NOT NULL,
            occupation NVARCHAR(150) NULL,
            phone_number VARCHAR(30) NOT NULL,
            email NVARCHAR(150) NULL,
            created_at DATETIME2(3) NOT NULL
        );


    IF OBJECT_ID(N'oman_remit.[remittance]', 'U') IS NULL
        CREATE TABLE oman_remit.[remittance]
        (
            remittance_id VARCHAR(100) NOT NULL,
            customer_id VARCHAR(100) NOT NULL,
            remittance_status VARCHAR(50) NOT NULL,
            remittance_timestamp DATETIME2(3) NOT NULL,
            transaction_location NVARCHAR(150) NOT NULL,
            amount DECIMAL(18,4) NOT NULL,
            currency CHAR(3) NOT NULL,
            origin_country NVARCHAR(150) NOT NULL,
            destination_country NVARCHAR(150) NOT NULL,
            transaction_channel VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ledger.[financial_event]', 'U') IS NULL
        CREATE TABLE ledger.[financial_event]
        (
            financial_event_id BIGINT NOT NULL,
            source_entity NVARCHAR(50) NOT NULL,
            source_event_id VARCHAR(100) NOT NULL,
            event_type VARCHAR(100) NOT NULL,
            event_timestamp DATETIME2(3) NOT NULL,
            event_status VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ledger.[financial_consequence]', 'U') IS NULL
        CREATE TABLE ledger.[financial_consequence]
        (
            financial_consequence_id BIGINT NOT NULL,
            financial_event_id BIGINT NOT NULL,
            consequence_type VARCHAR(100) NOT NULL,
            amount DECIMAL(18,4) NOT NULL,
            currency CHAR(3) NOT NULL,
            wallet_id BIGINT NOT NULL,
            customer_id VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ledger.[entry]', 'U') IS NULL
        CREATE TABLE ledger.[entry]
        (
            ledger_entry_id BIGINT NOT NULL,
            financial_consequence_id BIGINT NOT NULL,
            financial_event_id BIGINT NOT NULL,
            transaction_id VARCHAR(100) NOT NULL,
            wallet_id BIGINT NOT NULL,
            account_reference VARCHAR(100) NOT NULL,
            entry_type VARCHAR(100) NOT NULL,
            amount DECIMAL(18,4) NOT NULL,
            currency CHAR(3) NOT NULL,
            entry_timestamp DATETIME2(3) NOT NULL
        );


    IF OBJECT_ID(N'ref.[transaction_type]', 'U') IS NULL
        CREATE TABLE ref.[transaction_type]
        (
            transaction_type_code VARCHAR(20) NOT NULL,
            transaction_type_name VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ref.[transaction_status]', 'U') IS NULL
        CREATE TABLE ref.[transaction_status]
        (
            transaction_status_code VARCHAR(20) NOT NULL,
            transaction_status_name VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ref.[transaction_channel]', 'U') IS NULL
        CREATE TABLE ref.[transaction_channel]
        (
            transaction_channel_code VARCHAR(20) NOT NULL,
            transaction_channel_name VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ref.[currency]', 'U') IS NULL
        CREATE TABLE ref.[currency]
        (
            currency_code CHAR(3) NOT NULL,
            currency_name VARCHAR(100) NOT NULL
        );


    IF OBJECT_ID(N'ref.[country]', 'U') IS NULL
        CREATE TABLE ref.[country]
        (
            country_code CHAR(3) NOT NULL,
            country_name NVARCHAR(150) NOT NULL
        );


    SET @end_time = SYSDATETIME();

    PRINT '>> DEPLOYMENT COMPLETE';
    PRINT '>> TOTAL BATCH DURATION: '+ CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR(20)) + ' ms';
    PRINT '=========================================================================================================================';
END;
GO



/*
    Table Verification Procedure

    Purpose:
        Verifies that the expected OCB Platform tables exist after deployment.

    The procedure:
        1. Defines the approved list of 18 tables expected in v1.0.0.
        2. Identifies any expected tables that are missing.
        3. Compares the expected table count against the actual table count.
        4. Displays the tables currently deployed in the OCB Platform schemas.

    Important:
        This procedure only verifies the existence of tables.
        It does not verify columns, data types, keys, constraints, or table contents.

        It is non-destructive and does not modify the database.
*/

-- Wrapping verification in procedure.
CREATE OR ALTER PROCEDURE verify_ocb_platform_tables
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @expected_table_count INT = 18;

    PRINT '>>> STARTING OCB_PLATFORM TABLE VERIFICATION <<<';
    PRINT '=================================================================';


    /*
        Define the approved table inventory.
        The verification uses this list as the expected structural baseline for the OCB Platform v1.0.0 database.
    */

    DECLARE @expected_tables TABLE
    (
        schema_name SYSNAME,
        table_name SYSNAME
    );

    INSERT INTO @expected_tables
    VALUES
        ('ocb', 'customer'),
        ('ocb', 'customer_identity'),
        ('ananse', 'customer'),
        ('ananse', 'transaction'),
        ('wallet', 'wallet'),
        ('sikacredit', 'customer'),
        ('sikacredit', 'loan'),
        ('sikacredit', 'repayment'),
        ('oman_remit', 'customer'),
        ('oman_remit', 'remittance'),
        ('ledger', 'financial_event'),
        ('ledger', 'financial_consequence'),
        ('ledger', 'entry'),
        ('ref', 'transaction_type'),
        ('ref', 'transaction_status'),
        ('ref', 'transaction_channel'),
        ('ref', 'currency'),
        ('ref', 'country');


    /*
        Identify missing tables.
        The expected table inventory is compared against the actual tables in the database. Any expected table that does not exist
        is returned as MISSING.
    */

    SELECT
        e.schema_name,
        e.table_name,
        'MISSING' AS validation_status
    FROM @expected_tables e
    LEFT JOIN sys.tables t
    ON t.name = e.table_name
    LEFT JOIN sys.schemas s 
    ON s.schema_id = t.schema_id
    AND s.name = e.schema_name
    WHERE t.object_id IS NULL;

    /*
        Count the tables actually deployed within the OCB Platform schemas.
    */

    DECLARE @actual_table_count INT;

    SELECT
    @actual_table_count = COUNT(*)
    FROM sys.tables t
    INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
    AND s.name IN ('ocb', 'ananse', 'sikacredit', 'oman_remit', 'wallet', 'ledger', 'ref');


    /*
        Compare the expected table count against the actual count.
        A matching count indicates that the expected number of tables has been deployed. The missing-table result above should also
        be reviewed because a matching count alone does not prove that the correct tables exist.
    */

    SELECT
        @expected_table_count AS expected_table_count,
        @actual_table_count AS actual_table_count,

        CASE
            WHEN @actual_table_count = @expected_table_count
            THEN 'PASS'
            ELSE 'RE-CHECK TABLE LIST'
        END AS validation_status;


    /*
        Display the tables currently deployed.
        This provides a simple human-readable inventory that can be compared with the approved table list above.
    */

    SELECT
        s.name AS schema_name,
        t.name AS table_name
    FROM sys.tables t
    INNER JOIN sys.schemas s
    ON s.schema_id = t.schema_id
    AND s.name IN ('ocb', 'ananse', 'sikacredit', 'oman_remit', 'wallet', 'ledger', 'ref')
    ORDER BY s.name, t.name;

    PRINT '>> VERIFICATION COMPLETE';
    PRINT '=================================================================';

END;
GO


-- Execute the Deployment Procedure
EXEC ocb_platform_tables_deployment;
GO

-- Execute Verification Procedure.
EXEC verify_ocb_platform_tables;
GO