USE [ocb_platform];
GO

/*========================================================================================================================
  STEP 1 — TABLE DEPLOYMENT SCRIPT

  WARNING:
      This deployment script is DESTRUCTIVE.

      Existing OCB Platform tables will be dropped before they are recreated.
      Any data stored in those tables will be permanently deleted.

  BACKUP:
      Ensure that any required database or table data has been backed up before
      running this script.

  PURPOSE:
      Establish a clean and consistent OCB Platform v1.0.0 database structure
      for development and simulation.
========================================================================================================================*/

CREATE OR ALTER PROCEDURE dbo.ocb_platform_tables_deployment
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


    /*====================================================================================================================
      DROP EXISTING TABLES

      Tables are dropped before recreation so that the database structure
      always matches the approved OCB Platform schema.
    ====================================================================================================================*/

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


    /*====================================================================================================================
      CREATE OCB TABLES
    ====================================================================================================================*/

    CREATE TABLE ocb.[customer]
    (
        ocb_customer_id BIGINT IDENTITY(1,1) NOT NULL,

        CONSTRAINT PK_ocb_customer
            PRIMARY KEY (ocb_customer_id)
    );


    CREATE TABLE ocb.[customer_identity]
    (
        ocb_customer_id    BIGINT NOT NULL,
        source_entity      NVARCHAR(50) NOT NULL,
        source_customer_id VARCHAR(100) NOT NULL,
        created_at         DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ocb_customer_identity
            PRIMARY KEY (source_entity, source_customer_id)
    );


    /*====================================================================================================================
      CREATE ANANSE TELECOM TABLES
    ====================================================================================================================*/

    CREATE TABLE ananse.[customer]
    (
        customer_id   VARCHAR(100) NOT NULL,
        first_name    NVARCHAR(150) NOT NULL,
        last_name     NVARCHAR(150) NOT NULL,
        date_of_birth DATE NOT NULL,
        nationality   NVARCHAR(150) NOT NULL,
        occupation    NVARCHAR(150) NULL,
        phone_number  VARCHAR(30) NOT NULL,
        email         NVARCHAR(150) NULL,
        created_at    DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ananse_customer
            PRIMARY KEY (customer_id)
    );


    CREATE TABLE ananse.[transaction]
    (
        transaction_id         VARCHAR(100) NOT NULL,
        customer_id            VARCHAR(100) NOT NULL,
        wallet_id              BIGINT NOT NULL,

        transaction_status_id  BIGINT NOT NULL,
        transaction_type_id    BIGINT NOT NULL,
        transaction_channel_id BIGINT NOT NULL,
        currency_id            BIGINT NOT NULL,

        transaction_type       VARCHAR(100) NOT NULL,
        transaction_status     VARCHAR(100) NOT NULL,
        transaction_timestamp  DATETIME2(3) NOT NULL,
        transaction_location   NVARCHAR(150) NOT NULL,
        transaction_channel    VARCHAR(100) NOT NULL,
        device_id              VARCHAR(100) NOT NULL,
        amount                 DECIMAL(18,4) NOT NULL,
        currency               CHAR(3) NOT NULL,

        CONSTRAINT PK_ananse_transaction
            PRIMARY KEY (transaction_id)
    );


    /*====================================================================================================================
      CREATE WALLET TABLE
    ====================================================================================================================*/

    CREATE TABLE wallet.[wallet]
    (
        wallet_id BIGINT NOT NULL,

        CONSTRAINT PK_wallet_wallet
            PRIMARY KEY (wallet_id)
    );


    /*====================================================================================================================
      CREATE SIKACREDIT TABLES
    ====================================================================================================================*/

    CREATE TABLE sikacredit.[customer]
    (
        customer_id   VARCHAR(100) NOT NULL,
        first_name    NVARCHAR(150) NOT NULL,
        last_name     NVARCHAR(150) NOT NULL,
        date_of_birth DATE NOT NULL,
        nationality   NVARCHAR(150) NOT NULL,
        occupation    NVARCHAR(150) NULL,
        phone_number  VARCHAR(30) NOT NULL,
        email         NVARCHAR(150) NULL,
        created_at    DATETIME2(3) NOT NULL,

        CONSTRAINT PK_sikacredit_customer
            PRIMARY KEY (customer_id)
    );


    CREATE TABLE sikacredit.[loan]
    (
        loan_id               VARCHAR(100) NOT NULL,
        customer_id           VARCHAR(100) NOT NULL,
        disbursement_timestamp DATETIME2(3) NOT NULL,
        disbursement_location NVARCHAR(150) NOT NULL,
        maturity_date         DATE NOT NULL,
        principal_amount      DECIMAL(18,4) NOT NULL,
        interest_rate         DECIMAL(5,4) NOT NULL,
        currency              CHAR(3) NOT NULL,

        CONSTRAINT PK_sikacredit_loan
            PRIMARY KEY (loan_id)
    );


    CREATE TABLE sikacredit.[repayment]
    (
        repayment_id        VARCHAR(100) NOT NULL,
        loan_id             VARCHAR(100) NOT NULL,
        repayment_amount    DECIMAL(18,4) NOT NULL,
        repayment_timestamp DATETIME2(3) NOT NULL,
        repayment_location  NVARCHAR(150) NOT NULL,

        CONSTRAINT PK_sikacredit_repayment
            PRIMARY KEY (repayment_id)
    );


    /*====================================================================================================================
      CREATE OMAN REMIT TABLES
    ====================================================================================================================*/

    CREATE TABLE oman_remit.[customer]
    (
        customer_id   VARCHAR(100) NOT NULL,
        first_name    NVARCHAR(150) NOT NULL,
        last_name     NVARCHAR(150) NOT NULL,
        date_of_birth DATE NOT NULL,
        nationality   NVARCHAR(150) NOT NULL,
        occupation    NVARCHAR(150) NULL,
        phone_number  VARCHAR(30) NOT NULL,
        email         NVARCHAR(150) NULL,
        created_at    DATETIME2(3) NOT NULL,

        CONSTRAINT PK_oman_remit_customer
            PRIMARY KEY (customer_id)
    );


    CREATE TABLE oman_remit.[remittance]
    (
        remittance_id        VARCHAR(100) NOT NULL,
        customer_id          VARCHAR(100) NOT NULL,
        country_id           BIGINT NOT NULL,
        remittance_status    VARCHAR(50) NOT NULL,
        remittance_timestamp DATETIME2(3) NOT NULL,
        transaction_location NVARCHAR(150) NOT NULL,
        amount               DECIMAL(18,4) NOT NULL,
        currency             CHAR(3) NOT NULL,
        origin_country       NVARCHAR(150) NOT NULL,
        destination_country  NVARCHAR(150) NOT NULL,
        transaction_channel  VARCHAR(100) NOT NULL,

        CONSTRAINT PK_oman_remit_remittance
            PRIMARY KEY (remittance_id)
    );


    /*====================================================================================================================
      CREATE LEDGER TABLES
    ====================================================================================================================*/

    CREATE TABLE ledger.[financial_event]
    (
        financial_event_id BIGINT NOT NULL,
        source_entity      NVARCHAR(50) NOT NULL,
        source_event_id    VARCHAR(100) NOT NULL,
        event_type         VARCHAR(100) NOT NULL,
        event_timestamp    DATETIME2(3) NOT NULL,
        event_status       VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ledger_financial_event
            PRIMARY KEY (financial_event_id)
    );


    CREATE TABLE ledger.[financial_consequence]
    (
        financial_consequence_id BIGINT NOT NULL,
        financial_event_id       BIGINT NOT NULL,
        consequence_type         VARCHAR(100) NOT NULL,
        amount                   DECIMAL(18,4) NOT NULL,
        currency                 CHAR(3) NOT NULL,
        wallet_id                BIGINT NOT NULL,
        customer_id              VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ledger_financial_consequence
            PRIMARY KEY (financial_consequence_id)
    );


    CREATE TABLE ledger.[entry]
    (
        ledger_entry_id          BIGINT NOT NULL,
        financial_consequence_id BIGINT NOT NULL,
        financial_event_id       BIGINT NOT NULL,
        transaction_id           VARCHAR(100) NOT NULL,
        wallet_id                BIGINT NOT NULL,
        account_reference        VARCHAR(100) NOT NULL,
        entry_type               VARCHAR(100) NOT NULL,
        amount                   DECIMAL(18,4) NOT NULL,
        currency                 CHAR(3) NOT NULL,
        entry_timestamp          DATETIME2(3) NOT NULL,

        CONSTRAINT PK_ledger_entry
            PRIMARY KEY (ledger_entry_id)
    );


    /*====================================================================================================================
      CREATE REFERENCE TABLES

      Reference IDs are the stable relational identifiers.
      Business codes remain available as controlled business identifiers.
    ====================================================================================================================*/

    CREATE TABLE ref.[transaction_type]
    (
        transaction_type_id   BIGINT IDENTITY(1,1) NOT NULL,
        transaction_type_code VARCHAR(20) NOT NULL,
        transaction_type_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_type_id
            PRIMARY KEY (transaction_type_id)
    );


    CREATE TABLE ref.[transaction_status]
    (
        transaction_status_id   BIGINT IDENTITY(1,1) NOT NULL,
        transaction_status_code VARCHAR(20) NOT NULL,
        transaction_status_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_status_id
            PRIMARY KEY (transaction_status_id)
    );


    CREATE TABLE ref.[transaction_channel]
    (
        transaction_channel_id   BIGINT IDENTITY(1,1) NOT NULL,
        transaction_channel_code VARCHAR(20) NOT NULL,
        transaction_channel_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_transaction_channel_id
            PRIMARY KEY (transaction_channel_id)
    );


    CREATE TABLE ref.[currency]
    (
        currency_id   BIGINT IDENTITY(1,1) NOT NULL,
        currency_code CHAR(3) NOT NULL,
        currency_name VARCHAR(100) NOT NULL,

        CONSTRAINT PK_ref_currency_id
            PRIMARY KEY (currency_id)
    );


    CREATE TABLE ref.[country]
    (
        country_id   BIGINT IDENTITY(1,1) NOT NULL,
        country_code CHAR(3) NOT NULL,
        country_name NVARCHAR(150) NOT NULL,

        CONSTRAINT PK_ref_country_id
            PRIMARY KEY (country_id)
    );


    SET @end_time = SYSDATETIME();

    PRINT '>> TABLE CREATION COMPLETE';
    PRINT '>> TOTAL BATCH DURATION: '
        + CAST(DATEDIFF(millisecond, @start_time, @end_time) AS NVARCHAR(20))
        + ' ms';

    PRINT '=========================================================================================================================';

END;
GO


/*========================================================================================================================
  EXECUTE TABLE DEPLOYMENT
========================================================================================================================*/

EXEC dbo.ocb_platform_tables_deployment;
GO


/*========================================================================================================================
  TABLE DEPLOYMENT VERIFICATION

  Purpose:
      Confirms that the expected OCB Platform tables were created.

  Checks:
      1. Total deployed table count.
      2. Tables currently present.
      3. Primary key assigned to each table.

  This verification is NON-DESTRUCTIVE.
========================================================================================================================*/


/* 1. Check total expected table count */

DECLARE @expected_table_count INT = 18;

SELECT
    @expected_table_count AS expected_table_count,
    COUNT(*) AS actual_table_count,
    CASE
        WHEN COUNT(*) = @expected_table_count
            THEN 'PASS'
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


/* 2. Display deployed tables */

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
ORDER BY
    s.schema_id,
    t.name;


/* 3. Display primary keys */

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
ORDER BY
    s.schema_id,
    t.name;

GO


/*========================================================================================================================
  STEP 2 — FOREIGN KEY IMPLEMENTATION

  Approved existing relationships:
      1. ocb.customer_identity  → ocb.customer
      2. ananse.transaction      → ananse.customer
      3. ananse.transaction      → wallet.wallet
      4. sikacredit.loan         → sikacredit.customer
      5. sikacredit.repayment    → sikacredit.loan
      6. oman_remit.remittance   → oman_remit.customer

  Reference-layer relationships:
      7.  ananse.transaction     → ref.transaction_type
      8.  ananse.transaction     → ref.transaction_status
      9.  ananse.transaction     → ref.transaction_channel
      10. ananse.transaction     → ref.currency
      11. oman_remit.remittance  → ref.country

  Total implemented FK relationships: 11
========================================================================================================================*/


/*-----------------------------------------------
  OCB
------------------------------------------------*/

ALTER TABLE ocb.[customer_identity]
ADD CONSTRAINT FK_ocb_customer_identity_customer
    FOREIGN KEY (ocb_customer_id)
    REFERENCES ocb.[customer](ocb_customer_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → CUSTOMER
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_customer
    FOREIGN KEY (customer_id)
    REFERENCES ananse.[customer](customer_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → TRANSACTION TYPE
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_type_id
    FOREIGN KEY (transaction_type_id)
    REFERENCES ref.[transaction_type](transaction_type_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → TRANSACTION STATUS
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_status_id
    FOREIGN KEY (transaction_status_id)
    REFERENCES ref.[transaction_status](transaction_status_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → TRANSACTION CHANNEL
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_channel_id
    FOREIGN KEY (transaction_channel_id)
    REFERENCES ref.[transaction_channel](transaction_channel_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → CURRENCY
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_currency_id
    FOREIGN KEY (currency_id)
    REFERENCES ref.[currency](currency_id);


/*-----------------------------------------------
  ANANSE TRANSACTION → WALLET
------------------------------------------------*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT FK_ananse_transaction_wallet
    FOREIGN KEY (wallet_id)
    REFERENCES wallet.[wallet](wallet_id);


/*-----------------------------------------------
  SIKACREDIT LOAN → CUSTOMER
------------------------------------------------*/

ALTER TABLE sikacredit.[loan]
ADD CONSTRAINT FK_sikacredit_loan_customer
    FOREIGN KEY (customer_id)
    REFERENCES sikacredit.[customer](customer_id);


/*-----------------------------------------------
  SIKACREDIT REPAYMENT → LOAN
------------------------------------------------*/

ALTER TABLE sikacredit.[repayment]
ADD CONSTRAINT FK_sikacredit_repayment_loan
    FOREIGN KEY (loan_id)
    REFERENCES sikacredit.[loan](loan_id);


/*-----------------------------------------------
  OMAN REMIT REMITTANCE → CUSTOMER
------------------------------------------------*/

ALTER TABLE oman_remit.[remittance]
ADD CONSTRAINT FK_oman_remit_remittance_customer
    FOREIGN KEY (customer_id)
    REFERENCES oman_remit.[customer](customer_id);


/*-----------------------------------------------
  OMAN REMIT REMITTANCE → ORIGIN COUNTRY
------------------------------------------------*/

ALTER TABLE oman_remit.[remittance]
ADD CONSTRAINT FK_oman_remit_remittance_country
    FOREIGN KEY (country_id)
    REFERENCES ref.[country](country_id);

GO


/*========================================================================================================================
  FOREIGN KEY VERIFICATION

  Verifies all foreign keys currently deployed on OCB Platform tables.

  Expected:
      11 foreign keys.

  This verification is NON-DESTRUCTIVE.
========================================================================================================================*/

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    fk.name AS foreign_key_name,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) referenced_schema_name,
    OBJECT_NAME(fk.referenced_object_id) referenced_table_name
FROM sys.foreign_keys fk
INNER JOIN sys.schemas s
    ON fk.schema_id = s.schema_id
INNER JOIN sys.tables t
    ON fk.parent_object_id = t.object_id
ORDER BY
    s.name,
    t.name,
    fk.name;

GO


/*========================================================================================================================
  STEP 3 — CHECK CONSTRAINT IMPLEMENTATION
========================================================================================================================*/


/*===============================================================
  ANANSE TELECOM
================================================================*/

ALTER TABLE ananse.[transaction]
ADD CONSTRAINT CK_ananse_transaction_amount
CHECK (amount >= 0);


/*===============================================================
  SIKACREDIT
================================================================*/

ALTER TABLE sikacredit.[loan]
ADD CONSTRAINT CK_sikacredit_loan_principal_amount
CHECK (principal_amount >= 0);

ALTER TABLE sikacredit.[loan]
ADD CONSTRAINT CK_sikacredit_loan_interest_rate
CHECK (interest_rate >= 0);

ALTER TABLE sikacredit.[loan]
ADD CONSTRAINT CK_sikacredit_loan_maturity_after_disbursement
CHECK (maturity_date > disbursement_timestamp);

ALTER TABLE sikacredit.[repayment]
ADD CONSTRAINT CK_sikacredit_repayment_amount
CHECK (repayment_amount >= 0);


/*===============================================================
  OMAN REMIT
================================================================*/

ALTER TABLE oman_remit.[remittance]
ADD CONSTRAINT CK_oman_remit_remittance_amount
CHECK (amount >= 0);


/*===============================================================
  LEDGER
================================================================*/

ALTER TABLE ledger.[financial_consequence]
ADD CONSTRAINT CK_ledger_financial_consequence_amount
CHECK (amount >= 0);

ALTER TABLE ledger.[entry]
ADD CONSTRAINT CK_ledger_entry_amount
CHECK (amount >= 0);

GO


/*========================================================================================================================
  CHECK CONSTRAINT VERIFICATION

  Expected:
      8 CHECK constraints.
========================================================================================================================*/

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    cc.name AS constraint_check_name,
    cc.definition AS check_definition
FROM sys.check_constraints cc
INNER JOIN sys.schemas s
    ON cc.schema_id = s.schema_id
INNER JOIN sys.tables t
    ON cc.parent_object_id = t.object_id
ORDER BY
    s.name,
    t.name,
    cc.name;

GO


/*========================================================================================================================
  T09 — INDEX VERIFICATION

  Purpose:
      Verifies indexes currently present on the approved OCB Platform v1.0.0
      tables following implementation of primary-key and unique constraints.

  No additional workload-specific nonclustered indexes are introduced
  at this stage.
========================================================================================================================*/

DECLARE @expected_tables_schemas TABLE
(
    schema_name SYSNAME,
    table_name  SYSNAME
);

INSERT INTO @expected_tables_schemas
VALUES
    ('ocb',         'customer'),
    ('ocb',         'customer_identity'),
    ('ananse',      'customer'),
    ('ananse',      'transaction'),
    ('wallet',      'wallet'),
    ('sikacredit',  'customer'),
    ('sikacredit',  'loan'),
    ('sikacredit',  'repayment'),
    ('oman_remit',  'customer'),
    ('oman_remit',  'remittance'),
    ('ledger',      'financial_event'),
    ('ledger',      'financial_consequence'),
    ('ledger',      'entry'),
    ('ref',         'transaction_type'),
    ('ref',         'transaction_status'),
    ('ref',         'transaction_channel'),
    ('ref',         'currency'),
    ('ref',         'country');


SELECT
    ts.schema_name,
    ts.table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    c.name AS column_name,
    ic.column_id,
    ic.key_ordinal,
    ic.is_included_column AS coverage_column,
    i.index_id,
    i.is_unique,
    i.is_primary_key,
    i.is_unique_constraint
FROM @expected_tables_schemas ts
INNER JOIN sys.tables t
    ON ts.table_name = t.name
INNER JOIN sys.schemas s
    ON ts.schema_name = s.name
    AND t.schema_id = s.schema_id
INNER JOIN sys.indexes i
    ON t.object_id = i.object_id
INNER JOIN sys.index_columns ic
    ON t.object_id = ic.object_id
    AND i.index_id = ic.index_id
INNER JOIN sys.columns c
    ON ic.column_id = c.column_id
    AND t.object_id = c.object_id
WHERE i.is_disabled = 0
ORDER BY
    s.schema_id,
    t.name,
    i.index_id,
    ic.key_ordinal;

GO