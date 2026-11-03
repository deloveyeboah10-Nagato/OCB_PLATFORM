USE [ocb_platform];
GO

/*========================================================================================================================*

    OCB PLATFORM v1.0.0

    BRONZE SOURCE-LAYER TABLE DEPLOYMENT

    Purpose:
        Establish the Bronze layer for ingestion of the frozen synthetic source
        dataset and controlled reference data.

    Architecture:

        FROZEN GENERATOR OUTPUT
                    ↓
                 BRONZE
                    ↓
                 SILVER
                    ↓
                  GOLD
                    ↓
              INTELLIGENCE

    Bronze principle:
        Bronze preserves the generated source-world evidence with minimal
        transformation.

    Bronze contains:

        LOAD PROVENANCE
            load_batch

        REFERENCE DATA
            ref_transaction_type
            ref_transaction_status
            ref_transaction_channel
            ref_currency
            ref_country

        ANANSE
            ananse_customer
            ananse_wallet
            ananse_transaction

        SIKACREDIT
            sikacredit_customer
            sikacredit_loan
            sikacredit_repayment

        OMAN REMIT
            oman_remit_customer
            oman_remit_remittance

    Bronze does NOT contain:

        ocb_customer
        ocb_customer_identity

    OCB customer identity is established in Silver from the Bronze source
    customer records.

    Provenance:

        load_batch records are maintained separately from source data.

        load_id
        source_entity
        source_file_name
        load_timestamp

    Important:

        - Bronze contains no OCB identity-resolution results.
        - No Silver tables are created here.
        - No Gold tables are created here.
        - No analytical/business rules are applied here.
        - No source columns are added to the generator source contract.
        - Source customer IDs remain unchanged.
        - Bronze source tables preserve source-world relationships.

    Expected Bronze tables:

        14 total

        1   load_batch
        5   reference
        3   Ananse
        3   SikaCredit
        2   Oman Remit

*========================================================================================================================*/
/*========================================================================================================================*

    1. CREATE BRONZE SCHEMA

*========================================================================================================================*/
IF NOT EXISTS (
        SELECT
            1
        FROM sys.schemas
        WHERE name = N'bronze'
        )
BEGIN
    PRINT '>> bronze schema not found. Creating...';

    EXEC ('CREATE SCHEMA [bronze]');

    PRINT '>> bronze schema created successfully.';
END
ELSE
BEGIN
    PRINT '>> bronze schema already exists. No action required.';
END;
GO

/*========================================================================================================================*

    2. DROP EXISTING BRONZE TABLES

    Development deployment.

    Tables are dropped in child-to-parent dependency order.

    WARNING:
        Existing Bronze data will be permanently deleted.

*========================================================================================================================*/
DROP TABLE IF EXISTS bronze.[ananse_transaction];

DROP TABLE IF EXISTS bronze.[ananse_wallet];

DROP TABLE IF EXISTS bronze.[ananse_customer];

DROP TABLE IF EXISTS bronze.[sikacredit_repayment];

DROP TABLE IF EXISTS bronze.[sikacredit_loan];

DROP TABLE IF EXISTS bronze.[sikacredit_customer];

DROP TABLE IF EXISTS bronze.[oman_remit_remittance];

DROP TABLE IF EXISTS bronze.[oman_remit_customer];

DROP TABLE IF EXISTS bronze.[ref_transaction_channel];

DROP TABLE IF EXISTS bronze.[ref_transaction_status];

DROP TABLE IF EXISTS bronze.[ref_transaction_type];

DROP TABLE IF EXISTS bronze.[ref_currency];

DROP TABLE IF EXISTS bronze.[ref_country];

DROP TABLE IF EXISTS bronze.[load_batch];

PRINT '>> EXISTING BRONZE TABLES DROPPED';
GO

PRINT '===============================================================';
PRINT '>>> BRONZE SOURCE-LAYER DEPLOYMENT STARTED <<<';
PRINT '===============================================================';
GO

/*========================================================================================================================*

    3. BRONZE LOAD-BATCH PROVENANCE

    One row identifies one source-data load.

    These fields constitute the Bronze load provenance record:

        load_id
        source_entity
        source_file_name
        load_timestamp

    The source CSV itself is not modified to contain these fields.

*========================================================================================================================*/
CREATE TABLE bronze.[load_batch] (
    load_id BIGINT IDENTITY(1, 1) NOT NULL,
    source_entity VARCHAR(100) NOT NULL,
    source_file_name NVARCHAR(255) NOT NULL,
    load_timestamp DATETIME2(3) NOT NULL
    CONSTRAINT DF_bronze_load_batch_load_timestamp
    DEFAULT SYSDATETIME(),
    CONSTRAINT PK_bronze_load_batch PRIMARY KEY (load_id)
    );
GO

/*========================================================================================================================*

    4. REFERENCE — TRANSACTION TYPE

*========================================================================================================================*/
CREATE TABLE bronze.[ref_transaction_type] (
    transaction_type_id BIGINT NOT NULL,
    transaction_type_code VARCHAR(20) NOT NULL,
    transaction_type_name VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_ref_transaction_type PRIMARY KEY (transaction_type_id)
    );
GO

/*========================================================================================================================*

    5. REFERENCE — TRANSACTION STATUS

*========================================================================================================================*/
CREATE TABLE bronze.[ref_transaction_status] (
    transaction_status_id BIGINT NOT NULL,
    transaction_status_code VARCHAR(20) NOT NULL,
    transaction_status_name VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_ref_transaction_status PRIMARY KEY (transaction_status_id)
    );
GO

/*========================================================================================================================*

    6. REFERENCE — TRANSACTION CHANNEL

*========================================================================================================================*/
CREATE TABLE bronze.[ref_transaction_channel] (
    transaction_channel_id BIGINT NOT NULL,
    transaction_channel_code VARCHAR(20) NOT NULL,
    transaction_channel_name VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_ref_transaction_channel PRIMARY KEY (transaction_channel_id)
    );
GO

/*========================================================================================================================*

    7. REFERENCE — CURRENCY

*========================================================================================================================*/
CREATE TABLE bronze.[ref_currency] (
    currency_id BIGINT NOT NULL,
    currency_code CHAR(3) NOT NULL,
    currency_name VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_ref_currency PRIMARY KEY (currency_id)
    );
GO

/*========================================================================================================================*

    8. REFERENCE — COUNTRY

*========================================================================================================================*/
CREATE TABLE bronze.[ref_country] (
    country_id BIGINT NOT NULL,
    country_code CHAR(3) NOT NULL,
    country_name NVARCHAR(150) NOT NULL,
    CONSTRAINT PK_bronze_ref_country PRIMARY KEY (country_id)
    );
GO

/*========================================================================================================================*

    9. ANANSE CUSTOMER

*========================================================================================================================*/
CREATE TABLE bronze.[ananse_customer] (
    customer_id VARCHAR(100) NOT NULL,
    first_name NVARCHAR(150) NOT NULL,
    last_name NVARCHAR(150) NOT NULL,
    date_of_birth DATE NOT NULL,
    nationality NVARCHAR(150) NOT NULL,
    occupation NVARCHAR(150) NULL,
    phone_number VARCHAR(30) NOT NULL,
    email NVARCHAR(150) NULL,
    created_at DATETIME2(3) NOT NULL,
    CONSTRAINT PK_bronze_ananse_customer PRIMARY KEY (customer_id)
    );
GO

/*========================================================================================================================*

    10. SIKACREDIT CUSTOMER

*========================================================================================================================*/
CREATE TABLE bronze.[sikacredit_customer] (
    customer_id VARCHAR(100) NOT NULL,
    first_name NVARCHAR(150) NOT NULL,
    last_name NVARCHAR(150) NOT NULL,
    date_of_birth DATE NOT NULL,
    nationality NVARCHAR(150) NOT NULL,
    occupation NVARCHAR(150) NULL,
    phone_number VARCHAR(30) NOT NULL,
    email NVARCHAR(150) NULL,
    created_at DATETIME2(3) NOT NULL,
    CONSTRAINT PK_bronze_sikacredit_customer PRIMARY KEY (customer_id)
    );
GO

/*========================================================================================================================*

    11. OMAN REMIT CUSTOMER

*========================================================================================================================*/
CREATE TABLE bronze.[oman_remit_customer] (
    customer_id VARCHAR(100) NOT NULL,
    first_name NVARCHAR(150) NOT NULL,
    last_name NVARCHAR(150) NOT NULL,
    date_of_birth DATE NOT NULL,
    nationality NVARCHAR(150) NOT NULL,
    occupation NVARCHAR(150) NULL,
    phone_number VARCHAR(30) NOT NULL,
    email NVARCHAR(150) NULL,
    created_at DATETIME2(3) NOT NULL,
    CONSTRAINT PK_bronze_oman_remit_customer PRIMARY KEY (customer_id)
    );
GO

/*========================================================================================================================*

    12. ANANSE WALLET

    Depends on:
        bronze.ananse_customer

*========================================================================================================================*/
CREATE TABLE bronze.[ananse_wallet] (
    wallet_id BIGINT NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_ananse_wallet PRIMARY KEY (wallet_id),
    CONSTRAINT FK_bronze_ananse_wallet_customer FOREIGN KEY (customer_id)
    REFERENCES bronze.[ananse_customer](customer_id)
    );
GO

/*========================================================================================================================*

    13. SIKACREDIT LOAN

    Depends on:
        bronze.sikacredit_customer

*========================================================================================================================*/
CREATE TABLE bronze.[sikacredit_loan] (
    loan_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    disbursement_timestamp DATETIME2(3) NOT NULL,
    disbursement_location NVARCHAR(150) NOT NULL,
    maturity_date DATE NOT NULL,
    principal_amount DECIMAL(18, 4) NOT NULL,
    interest_rate DECIMAL(5, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    CONSTRAINT PK_bronze_sikacredit_loan PRIMARY KEY (loan_id),
    CONSTRAINT FK_bronze_sikacredit_loan_customer FOREIGN KEY (customer_id)
    REFERENCES bronze.[sikacredit_customer](customer_id)
    );
GO

/*========================================================================================================================*

    14. OMAN REMIT REMITTANCE

    Depends on:
        bronze.oman_remit_customer
        bronze.ref_country

*========================================================================================================================*/
CREATE TABLE bronze.[oman_remit_remittance] (
    remittance_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    country_id BIGINT NOT NULL,
    remittance_status VARCHAR(50) NOT NULL,
    remittance_timestamp DATETIME2(3) NOT NULL,
    transaction_location NVARCHAR(150) NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    currency CHAR(3) NOT NULL,
    transaction_channel VARCHAR(100) NOT NULL,
    CONSTRAINT PK_bronze_oman_remit_remittance PRIMARY KEY (remittance_id),
    CONSTRAINT FK_bronze_oman_remit_remittance_customer FOREIGN KEY (customer_id)
    REFERENCES bronze.[oman_remit_customer](customer_id),
    CONSTRAINT FK_bronze_oman_remit_remittance_country FOREIGN KEY (country_id)
    REFERENCES bronze.[ref_country](country_id)
    );
GO

/*========================================================================================================================*

    15. ANANSE TRANSACTION

    Structure follows the generator source contract.

    Depends on:
        bronze.ananse_customer
        bronze.ananse_wallet
        bronze.ref_transaction_status
        bronze.ref_transaction_type
        bronze.ref_transaction_channel
        bronze.ref_currency

*========================================================================================================================*/
CREATE TABLE bronze.[ananse_transaction] (
    transaction_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100) NOT NULL,
    wallet_id BIGINT NOT NULL,
    transaction_status_id BIGINT NOT NULL,
    transaction_type_id BIGINT NOT NULL,
    transaction_channel_id BIGINT NOT NULL,
    currency_id BIGINT NOT NULL,
    transaction_timestamp DATETIME2(3) NOT NULL,
    transaction_location NVARCHAR(150) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    amount DECIMAL(18, 4) NOT NULL,
    CONSTRAINT PK_bronze_ananse_transaction PRIMARY KEY (transaction_id),
    CONSTRAINT FK_bronze_ananse_transaction_customer FOREIGN KEY (customer_id)
    REFERENCES bronze.[ananse_customer](customer_id),
    CONSTRAINT FK_bronze_ananse_transaction_wallet FOREIGN KEY (wallet_id)
    REFERENCES bronze.[ananse_wallet](wallet_id),
    CONSTRAINT FK_bronze_ananse_transaction_transaction_status FOREIGN KEY (transaction_status_id)
    REFERENCES bronze.[ref_transaction_status](transaction_status_id),
    CONSTRAINT FK_bronze_ananse_transaction_transaction_type FOREIGN KEY (transaction_type_id)
    REFERENCES bronze.[ref_transaction_type](transaction_type_id),
    CONSTRAINT FK_bronze_ananse_transaction_transaction_channel FOREIGN KEY (transaction_channel_id)
    REFERENCES bronze.[ref_transaction_channel](transaction_channel_id),
    CONSTRAINT FK_bronze_ananse_transaction_currency FOREIGN KEY (currency_id)
    REFERENCES bronze.[ref_currency](currency_id)
    );
GO

/*========================================================================================================================*

    16. SIKACREDIT REPAYMENT

    Depends on:
        bronze.sikacredit_loan

*========================================================================================================================*/
CREATE TABLE bronze.[sikacredit_repayment] (
    repayment_id VARCHAR(100) NOT NULL,
    loan_id VARCHAR(100) NOT NULL,
    repayment_amount DECIMAL(18, 4) NOT NULL,
    repayment_timestamp DATETIME2(3) NOT NULL,
    repayment_location NVARCHAR(150) NOT NULL,
    CONSTRAINT PK_bronze_sikacredit_repayment PRIMARY KEY (repayment_id),
    CONSTRAINT FK_bronze_sikacredit_repayment_loan FOREIGN KEY (loan_id)
    REFERENCES bronze.[sikacredit_loan](loan_id)
    );
GO

/*========================================================================================================================*

    17. BRONZE DEPLOYMENT VERIFICATION

    Expected:
        14 Bronze tables

            1   load_batch
            5   Reference
            3   Ananse
            3   SikaCredit
            2   Oman Remit

        Total = 14

*========================================================================================================================*/
DECLARE @expected_bronze_table_count INT = 14;

SELECT
    @expected_bronze_table_count AS expected_bronze_table_count,
    COUNT(*) AS actual_bronze_table_count,
    CASE 
        WHEN COUNT(*) = @expected_bronze_table_count
            THEN 'PASS'
        ELSE 'FAIL'
        END AS validation_status
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze';
GO

/*========================================================================================================================*

    18. FOREIGN KEY DEPLOYMENT VERIFICATION

    Expected:
        12 foreign keys

    Breakdown:

        Ananse Wallet          1
        SikaCredit Loan        1
        Oman Remittance        2
        Ananse Transaction     6
        SikaCredit Repayment   1

        Total                  11

*========================================================================================================================*/
DECLARE @expected_foreign_key_count INT = 11;

SELECT
    @expected_foreign_key_count AS expected_foreign_key_count,
    COUNT(*) AS actual_foreign_key_count,
    CASE 
        WHEN COUNT(*) = @expected_foreign_key_count
            THEN 'PASS'
        ELSE 'FAIL'
        END AS validation_status
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS t ON
        fk.parent_object_id = t.OBJECT_ID
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze';
GO

/*========================================================================================================================*

    19. DISPLAY DEPLOYED BRONZE TABLES

*========================================================================================================================*/
SELECT
    s.name AS SCHEMA_NAME,
    t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze'
ORDER BY t.name;
GO

/*========================================================================================================================*

    20. DISPLAY PRIMARY KEYS

*========================================================================================================================*/
SELECT
    s.name AS SCHEMA_NAME,
    t.name AS table_name,
    i.name AS primary_key_name
FROM sys.indexes AS i
INNER JOIN sys.tables AS t ON
        i.OBJECT_ID = t.OBJECT_ID
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze'
        AND i.is_primary_key = 1
ORDER BY t.name;
GO

/*========================================================================================================================*

    21. DISPLAY FOREIGN KEYS

*========================================================================================================================*/
SELECT
    fk.name AS foreign_key_name,
    SCHEMA_NAME(parent_table.SCHEMA_ID) AS child_schema,
    parent_table.name AS child_table,
    parent_column.name AS child_column,
    SCHEMA_NAME(referenced_table.SCHEMA_ID) AS parent_schema,
    referenced_table.name AS parent_table,
    referenced_column.name AS parent_column
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON
        fk.OBJECT_ID = fkc.constraint_object_id
INNER JOIN sys.tables AS parent_table ON
        fk.parent_object_id = parent_table.OBJECT_ID
INNER JOIN sys.columns AS parent_column ON
        parent_column.OBJECT_ID = fkc.parent_object_id
            AND parent_column.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS referenced_table ON
        fk.referenced_object_id = referenced_table.OBJECT_ID
INNER JOIN sys.columns AS referenced_column ON
        referenced_column.OBJECT_ID = fkc.referenced_object_id
            AND referenced_column.column_id = fkc.referenced_column_id
WHERE SCHEMA_NAME(parent_table.SCHEMA_ID) = 'bronze'
ORDER BY child_table,
    foreign_key_name;
GO

/*========================================================================================================================*

    22. BRONZE DEPLOYMENT SUMMARY

*========================================================================================================================*/
SELECT
    'Bronze Tables' AS validation_item,
    14 AS expected_value,
    COUNT(*) AS actual_value,
    CASE 
        WHEN COUNT(*) = 14
            THEN 'PASS'
        ELSE 'FAIL'
        END AS validation_status
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze'

UNION ALL

SELECT
    'Bronze Foreign Keys',
    11,
    COUNT(*),
    CASE 
        WHEN COUNT(*) = 11
            THEN 'PASS'
        ELSE 'FAIL'
        END
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS t ON
        fk.parent_object_id = t.OBJECT_ID
INNER JOIN sys.schemas AS s ON
        t.SCHEMA_ID = s.SCHEMA_ID
WHERE s.name = 'bronze';
GO

PRINT '===============================================================';
PRINT '>>> BRONZE SOURCE-LAYER DEPLOYMENT COMPLETE <<<';
PRINT '===============================================================';
GO


