USE [ocb_platform];
GO

/*
    Table Deployment Script

    WARNING!!!:
    This deployment script is DESTRUCTIVE.

    Existing OCB Platform tables will be dropped before they are recreated. Any data stored in those tables will be permanently
    deleted.

    BACKUP:
    Ensure that any required database or table data has been backed up before running this script.

    DO NOT RUN this script against a database containing data that must be preserved unless an appropriate backup has been taken.

    This script is intended for the controlled OCB development and simulation environment.

    PURPOSE:
    Establish a clean and consistent OCB Platform v1.0.0 database structure for development and simulation.
*/

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
    PRINT '>>> DEVELOPMENT DEPLOYMENT: EXISTING TABLES WILL BE DROPPED <<<';
    PRINT '-------------------------------------------------------------------------------------------------------------------------';


    /*
        DROP EXISTING TABLES
        Tables are dropped before recreation so that the database structure always matches the approved OCB Platform schema.
    */

    DROP TABLE IF EXISTS ledger.[entry];

    DROP TABLE IF EXISTS ledger.[financial_consequence];

    DROP TABLE IF EXISTS ledger.[financial_event];

    DROP TABLE IF EXISTS sikacredit.[repayment];

    DROP TABLE IF EXISTS sikacredit.[loan];

    DROP TABLE IF EXISTS oman_remit.[remittance];

    DROP TABLE IF EXISTS ananse.[transaction];

    DROP TABLE IF EXISTS ocb.[customer_identity];

    DROP TABLE IF EXISTS ananse.[customer];

    DROP TABLE IF EXISTS sikacredit.[customer];

    DROP TABLE IF EXISTS oman_remit.[customer];

    DROP TABLE IF EXISTS ocb.[customer];

    DROP TABLE IF EXISTS wallet.[wallet];

    DROP TABLE IF EXISTS ref.[transaction_type];

    DROP TABLE IF EXISTS ref.[transaction_status];

    DROP TABLE IF EXISTS ref.[transaction_channel];

    DROP TABLE IF EXISTS ref.[currency];

    DROP TABLE IF EXISTS ref.[country];


    PRINT '>> EXISTING TABLES DROPPED';
    PRINT '-------------------------------------------------------------------------------------------------------------------------';


    /*
        CREATE OCB TABLES
    */

    CREATE TABLE ocb.[customer]
    (
        ocb_customer_id BIGINT IDENTITY(1,1) NOT NULL,

        CONSTRAINT PK_ocb_customer
        PRIMARY KEY (ocb_customer_id)
    );


    CREATE TABLE ocb.[customer_identity]
    (
        ocb_customer_id BIGINT NOT NULL,
        source_entity NVARCHAR(50) NOT NULL,
        source_customer_id VARCHAR(100) NOT NULL,
        created_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ocb_customer_identity
        PRIMARY KEY (source_entity, source_customer_id)
    );


    /*
        CREATE ANANSE TELECOM TABLES
    */

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
        created_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ananse_customer
        PRIMARY KEY (customer_id)
    );


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
        currency CHAR(3) NOT NULL,

        CONSTRAINT PK_ananse_transaction
        PRIMARY KEY (transaction_id)
    );


    /*
        CREATE WALLET TABLE
    */

    CREATE TABLE wallet.[wallet]
    (
        wallet_id BIGINT NOT NULL,

        CONSTRAINT PK_wallet_wallet
        PRIMARY KEY (wallet_id)
    );


    /*
        CREATE SIKACREDIT TABLES
    */

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
        created_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_sikacredit_customer
        PRIMARY KEY (customer_id)
    );


    CREATE TABLE sikacredit.[loan]
    (
        loan_id VARCHAR(100) NOT NULL,
        customer_id VARCHAR(100) NOT NULL,
        disbursement_timestamp DATETIME2(3) NULL,
        disbursement_location NVARCHAR(150) NOT NULL,
        maturity_date DATE NOT NULL,
        principal_amount DECIMAL(18,4) NOT NULL,
        interest_rate DECIMAL(5,4) NOT NULL,
        currency CHAR(3) NOT NULL,

        CONSTRAINT PK_sikacredit_loan
        PRIMARY KEY (loan_id)
    );


    CREATE TABLE sikacredit.[repayment]
    (
        repayment_id VARCHAR(100) NOT NULL,
        loan_id VARCHAR(100) NOT NULL,
        repayment_amount DECIMAL(18,4) NOT NULL,
        repayment_timestamp DATETIME2(3) NOT NULL,
        repayment_location NVARCHAR(150) NOT NULL,

        CONSTRAINT PK_sikacredit_repayment
        PRIMARY KEY (repayment_id)
    );


    /*
        CREATE OMAN REMIT TABLES
    */

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
        created_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_oman_remit_customer
        PRIMARY KEY (customer_id)
    );


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
        transaction_channel VARCHAR(100) NOT NULL,

        CONSTRAINT PK_oman_remit_remittance
        PRIMARY KEY (remittance_id)
    );


    /*
        CREATE LEDGER TABLES
    */

    CREATE TABLE ledger.[financial_event]
    (
        financial_event_id BIGINT NOT NULL,
        source_entity NVARCHAR(50) NOT NULL,
        source_event_id VARCHAR(100) NOT NULL,
        event_type VARCHAR(100) NOT NULL,
        event_timestamp DATETIME2(3) NOT NULL,
        event_status VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ledger_financial_event
        PRIMARY KEY (financial_event_id)
    );


    CREATE TABLE ledger.[financial_consequence]
    (
        financial_consequence_id BIGINT NOT NULL,
        financial_event_id BIGINT NOT NULL,
        consequence_type VARCHAR(100) NOT NULL,
        amount DECIMAL(18,4) NOT NULL,
        currency CHAR(3) NOT NULL,
        wallet_id BIGINT NOT NULL,
        customer_id VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ledger_financial_consequence
        PRIMARY KEY (financial_consequence_id)
    );


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
        entry_timestamp DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ledger_entry
        PRIMARY KEY (ledger_entry_id)
    );


    /*
        CREATE REFERENCE TABLES
    */

    CREATE TABLE ref.[transaction_type]
    (
        transaction_type_code VARCHAR(20) NOT NULL,
        transaction_type_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_type
        PRIMARY KEY (transaction_type_code)
    );


    CREATE TABLE ref.[transaction_status]
    (
        transaction_status_code VARCHAR(20) NOT NULL,
        transaction_status_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_status
        PRIMARY KEY (transaction_status_code)
    );


    CREATE TABLE ref.[transaction_channel]
    (
        transaction_channel_code VARCHAR(20) NOT NULL,
        transaction_channel_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_channel
        PRIMARY KEY (transaction_channel_code)
    );


    CREATE TABLE ref.[currency]
    (
        currency_code CHAR(3) NOT NULL,
        currency_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_currency
        PRIMARY KEY (currency_code)
    );


    CREATE TABLE ref.[country]
    (
        country_code CHAR(3) NOT NULL,
        country_name NVARCHAR(150) NOT NULL,

        CONSTRAINT PK_ref_country
        PRIMARY KEY (country_code)
    );


    SET @end_time = SYSDATETIME();

    PRINT '>> TABLE CREATION COMPLETE';
    PRINT '>> TOTAL BATCH DURATION: ' + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR(20)) + ' ms';
    PRINT '=========================================================================================================================';
END;
GO

-- Execute the Procedure
EXEC ocb_platform_tables_deployment;
GO


/*
    Table Deployment Verification

    Purpose:
        Confirms that the expected OCB Platform tables were created.

        The verification checks:
            1. The number of deployed tables.
            2. The tables currently present.
            3. The primary key assigned to each table.

    This verification is NON-DESTRUCTIVE.
    It does not modify the database.
*/


-- 1. Check the total number of expected tables.

DECLARE @expected_table_count INT = 18;

SELECT
    @expected_table_count AS expected_table_count,
    COUNT(*) AS actual_table_count,
    CASE
        WHEN COUNT(*) = @expected_table_count THEN 'PASS'
        ELSE 'RE-CHECK TABLE LIST'
    END AS validation_status
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name IN
(
    'ocb',
    'ananse',
    'sikacredit',
    'oman_remit',
    'wallet',
    'ledger',
    'ref'
);


-- 2. Display the deployed tables.

SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE s.name IN
(
    'ocb',
    'ananse',
    'sikacredit',
    'oman_remit',
    'wallet',
    'ledger',
    'ref'
)
ORDER BY s.schema_id,t.name;


-- 3. Display the primary keys assigned to the tables.

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS primary_key_name
FROM sys.indexes i
INNER JOIN sys.tables t
    ON i.object_id = t.object_id
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE i.is_primary_key = 1
ORDER BY s.schema_id,t.name;
GO


/*
    THIS SCRIPT ALTERS EXISTING TABLES AND ADDS FOREIGN KEYS AND CONSTRAINTS.
    ITS NON DESTRUCTIVE.
*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_customer
    FOREIGN KEY (customer_id)
    REFERENCES ananse.[customer](customer_id);









































































































































