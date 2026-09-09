USE [ocb_platform];
GO

/*========================================================================================================================
    OCB PLATFORM v1.0.0

    WP-3.4 — GOLD FOUNDATIONAL VIEWS

    GOLD OBJECTS

        gold.vw_transaction
            → silver.ananse_transaction

        gold.vw_loan
            → silver.sikacredit_loan

        gold.vw_repayment
            → silver.sikacredit_repayment

        gold.vw_remittance
            → silver.oman_remit_remittance

        gold.vw_customer
            → silver.ocb_customer_unified

        gold.vw_institution
            → silver.ocb_institution

    DESIGN NOTES

        1. Gold views provide the analytical interface over Silver.

        2. cross_domain_id is exposed in Gold event views so downstream
           analytical workloads do not repeatedly join to the identity bridge.

        3. LEFT JOIN is used for identity enrichment so unresolved identity
           does not remove a financial event from the Gold view.

        4. No partitioning or indexed views are introduced at this stage.
           Physical optimization will be addressed in Programme 4 after
           OLAP workloads have been established.

========================================================================================================================*/


/*========================================================================================================================
    1. GOLD SCHEMA
========================================================================================================================*/

IF SCHEMA_ID('gold') IS NULL
    EXEC('CREATE SCHEMA gold');
GO


/*========================================================================================================================
    2. ANANSE TRANSACTION
========================================================================================================================*/

SELECT
    at.transaction_id,
    at.customer_id,
    at.ocb_customer_id,
    oci.cross_domain_id,
    at.wallet_id,
    at.device_id,
    at.transaction_channel,
    at.transaction_type,
    at.transaction_location_region,
    at.transaction_location_town,
    at.transaction_status,
    at.transaction_amount,
    at.transaction_timestamp,
    at.transaction_currency
FROM silver.ananse_transaction AS at
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  at.customer_id = oci.source_customer_id
    AND at.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'ANANSE';


/*========================================================================================================================
    ANANSE TRANSACTION — CHECKS
========================================================================================================================*/

SELECT
    at.transaction_id
FROM silver.ananse_transaction AS at
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  at.customer_id = oci.source_customer_id
    AND at.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'ANANSE'
GROUP BY
    at.transaction_id
HAVING COUNT(*) > 1;


SELECT
    oci.cross_domain_id
FROM silver.ananse_transaction AS at
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  at.customer_id = oci.source_customer_id
    AND at.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'ANANSE'
WHERE oci.cross_domain_id IS NULL;


/*========================================================================================================================
    GOLD.VW_TRANSACTION
========================================================================================================================*/

IF OBJECT_ID('gold.vw_transaction', 'V') IS NOT NULL
    DROP VIEW gold.vw_transaction;
GO

CREATE VIEW gold.vw_transaction
AS
SELECT
    at.transaction_id,
    at.customer_id,
    at.ocb_customer_id,
    oci.cross_domain_id,
    at.wallet_id,
    at.device_id,
    at.transaction_channel,
    at.transaction_type,
    at.transaction_location_region,
    at.transaction_location_town,
    at.transaction_status,
    at.transaction_amount,
    at.transaction_timestamp,
    at.transaction_currency
FROM silver.ananse_transaction AS at
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  at.customer_id = oci.source_customer_id
    AND at.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'ANANSE';
GO


/*========================================================================================================================
    3. SIKACREDIT LOAN
========================================================================================================================*/

SELECT
    skl.loan_id,
    skl.customer_id,
    skl.ocb_customer_id,
    oci.cross_domain_id,
    skl.disbursement_location_region,
    skl.disbursement_location_town,
    skl.principal_amount,
    skl.disbursement_timestamp,
    skl.maturity_date,
    skl.interest_rate,
    skl.loan_currency
FROM silver.sikacredit_loan AS skl
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  skl.customer_id = oci.source_customer_id
    AND skl.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'SIKACREDIT';


/*========================================================================================================================
    SIKACREDIT LOAN — CHECKS
========================================================================================================================*/

SELECT
    skl.loan_id
FROM silver.sikacredit_loan AS skl
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  skl.customer_id = oci.source_customer_id
    AND skl.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'SIKACREDIT'
GROUP BY
    skl.loan_id
HAVING COUNT(*) > 1;


SELECT
    oci.cross_domain_id
FROM silver.sikacredit_loan AS skl
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  skl.customer_id = oci.source_customer_id
    AND skl.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'SIKACREDIT'
WHERE oci.cross_domain_id IS NULL;


/*========================================================================================================================
    GOLD.VW_LOAN
========================================================================================================================*/

IF OBJECT_ID('gold.vw_loan', 'V') IS NOT NULL
    DROP VIEW gold.vw_loan;
GO

CREATE VIEW gold.vw_loan
AS
SELECT
    skl.loan_id,
    skl.customer_id,
    skl.ocb_customer_id,
    oci.cross_domain_id,
    skl.disbursement_location_region,
    skl.disbursement_location_town,
    skl.principal_amount,
    skl.disbursement_timestamp,
    skl.maturity_date,
    skl.interest_rate,
    skl.loan_currency
FROM silver.sikacredit_loan AS skl
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  skl.customer_id = oci.source_customer_id
    AND skl.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'SIKACREDIT';
GO


/*========================================================================================================================
    4. SIKACREDIT REPAYMENT

    No identity join is required.

    ocb_customer_id is already present in the Silver repayment table.
========================================================================================================================*/

SELECT
    skr.repayment_id,
    skr.loan_id,
    skr.ocb_customer_id,
    skr.repayment_location_region,
    skr.repayment_location_town,
    skr.repayment_amount,
    skr.repayment_timestamp
FROM silver.sikacredit_repayment AS skr;


/*========================================================================================================================
    SIKACREDIT REPAYMENT — CHECKS
========================================================================================================================*/

SELECT
    skr.repayment_id
FROM silver.sikacredit_repayment AS skr
GROUP BY
    skr.repayment_id
HAVING
    COUNT(*) > 1
    OR skr.repayment_id IS NULL;


/*========================================================================================================================
    GOLD.VW_REPAYMENT
========================================================================================================================*/

IF OBJECT_ID('gold.vw_repayment', 'V') IS NOT NULL
    DROP VIEW gold.vw_repayment;
GO

CREATE VIEW gold.vw_repayment
AS
SELECT
    skr.repayment_id,
    skr.loan_id,
    skr.ocb_customer_id,
    skr.repayment_location_region,
    skr.repayment_location_town,
    skr.repayment_amount,
    skr.repayment_timestamp
FROM silver.sikacredit_repayment AS skr;
GO


/*========================================================================================================================
    5. OMAN REMIT REMITTANCE
========================================================================================================================*/

SELECT
    orr.remittance_id,
    orr.customer_id,
    orr.ocb_customer_id,
    oci.cross_domain_id,
    orr.remittance_transaction_channel,
    orr.remittance_type,
    orr.remittance_origin_country,
    orr.remittance_location_region,
    orr.remittance_location_town,
    orr.remittance_status,
    orr.remittance_amount,
    orr.remittance_timestamp,
    orr.remittance_currency
FROM silver.oman_remit_remittance AS orr
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  orr.customer_id = oci.source_customer_id
    AND orr.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'OMAN_REMIT';


/*========================================================================================================================
    OMAN REMIT REMITTANCE — CHECKS
========================================================================================================================*/

SELECT
    orr.remittance_id
FROM silver.oman_remit_remittance AS orr
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  orr.customer_id = oci.source_customer_id
    AND orr.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'OMAN_REMIT'
GROUP BY
    orr.remittance_id
HAVING COUNT(*) > 1;


SELECT
    oci.cross_domain_id
FROM silver.oman_remit_remittance AS orr
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  orr.customer_id = oci.source_customer_id
    AND orr.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'OMAN_REMIT'
WHERE oci.cross_domain_id IS NULL;


/*========================================================================================================================
    GOLD.VW_REMITTANCE
========================================================================================================================*/

IF OBJECT_ID('gold.vw_remittance', 'V') IS NOT NULL
    DROP VIEW gold.vw_remittance;
GO

CREATE VIEW gold.vw_remittance
AS
SELECT
    orr.remittance_id,
    orr.customer_id,
    orr.ocb_customer_id,
    oci.cross_domain_id,
    orr.remittance_transaction_channel,
    orr.remittance_type,
    orr.remittance_origin_country,
    orr.remittance_location_region,
    orr.remittance_location_town,
    orr.remittance_status,
    orr.remittance_amount,
    orr.remittance_timestamp,
    orr.remittance_currency
FROM silver.oman_remit_remittance AS orr
LEFT JOIN silver.ocb_customer_identity AS oci
    ON  orr.customer_id = oci.source_customer_id
    AND orr.ocb_customer_id = oci.ocb_customer_id
    AND oci.source_entity = 'OMAN_REMIT';
GO


/*========================================================================================================================
    6. OCB CUSTOMER UNIFICATION
========================================================================================================================*/

IF OBJECT_ID('tempdb..#unified_occupation_nationality') IS NOT NULL
    DROP TABLE #unified_occupation_nationality;


SELECT
    ac.ocb_customer_id,
    ac.occupation,
    ac.nationality
INTO #unified_occupation_nationality
FROM silver.ananse_customer AS ac

UNION ALL

SELECT
    sc.ocb_customer_id,
    sc.occupation,
    sc.nationality
FROM silver.sikacredit_customer AS sc

UNION ALL

SELECT
    orc.ocb_customer_id,
    orc.occupation,
    orc.nationality
FROM silver.oman_remit_customer AS orc;


/*========================================================================================================================
    OCB CUSTOMER — ATTRIBUTE CONSISTENCY CHECK
========================================================================================================================*/

IF EXISTS
(
    SELECT
        uon.ocb_customer_id
    FROM #unified_occupation_nationality AS uon
    GROUP BY
        uon.ocb_customer_id
    HAVING
        COUNT(DISTINCT uon.occupation) <> 1
        OR
        COUNT(DISTINCT uon.nationality) <> 1
)
BEGIN
    ;THROW 50001,
        'Customer attribute validation failed: occupation or nationality contains multiple distinct values for at least one OCB customer.',
        1;
END;


/*========================================================================================================================
    OCB CUSTOMER — REMOVE IDENTICAL DUPLICATE OBSERVATIONS
========================================================================================================================*/

IF OBJECT_ID('tempdb..#unified_customer') IS NOT NULL
    DROP TABLE #unified_customer;


SELECT
    uon.ocb_customer_id,
    uon.occupation,
    uon.nationality
INTO #unified_customer
FROM #unified_occupation_nationality AS uon
GROUP BY
    uon.ocb_customer_id,
    uon.occupation,
    uon.nationality;


/*========================================================================================================================
    SILVER.OCB_CUSTOMER_UNIFIED
========================================================================================================================*/

IF OBJECT_ID('silver.ocb_customer_unified', 'U') IS NOT NULL
    DROP TABLE silver.ocb_customer_unified;


SELECT
    uc.ocb_customer_id,
    i.cross_domain_id,
    oc.first_name,
    oc.last_name,
    oc.date_of_birth,
    oc.phone_number,
    oc.email,
    uc.occupation,
    uc.nationality
INTO silver.ocb_customer_unified
FROM #unified_customer AS uc
LEFT JOIN silver.ocb_customer AS oc
    ON uc.ocb_customer_id = oc.ocb_customer_id
LEFT JOIN
(
    SELECT
        ocb_customer_id,
        cross_domain_id
    FROM silver.ocb_customer_identity
    GROUP BY
        ocb_customer_id,
        cross_domain_id
) AS i
    ON uc.ocb_customer_id = i.ocb_customer_id;


/*========================================================================================================================
    OCB CUSTOMER — FINAL CHECKS
========================================================================================================================*/

SELECT
    ocb_customer_id
FROM silver.ocb_customer_unified
GROUP BY
    ocb_customer_id
HAVING COUNT(*) > 1;


SELECT
    cross_domain_id
FROM silver.ocb_customer_unified
WHERE cross_domain_id IS NULL;


/*========================================================================================================================
    GOLD.VW_CUSTOMER
========================================================================================================================*/

IF OBJECT_ID('gold.vw_customer', 'V') IS NOT NULL
    DROP VIEW gold.vw_customer;
GO

CREATE VIEW gold.vw_customer
AS
SELECT
    ocb_customer_id,
    cross_domain_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email,
    occupation,
    nationality
FROM silver.ocb_customer_unified;
GO


/*========================================================================================================================
    7. OCB INSTITUTION
========================================================================================================================*/

IF OBJECT_ID('silver.ocb_institution', 'U') IS NOT NULL
    DROP TABLE silver.ocb_institution;


CREATE TABLE silver.ocb_institution
(
    institution    VARCHAR(100) NOT NULL,
    entity_code    VARCHAR(50)  NOT NULL,

    CONSTRAINT PK_ocb_institution
        PRIMARY KEY (entity_code)
);


INSERT INTO silver.ocb_institution
(
    institution,
    entity_code
)
VALUES
    ('ANANSE TELECOM', 'ANANSE'),
    ('SIKACREDIT',     'SIKACREDIT'),
    ('OMAN_REMIT',     'OMAN_REMIT');


/*========================================================================================================================
    GOLD.VW_INSTITUTION
========================================================================================================================*/

IF OBJECT_ID('gold.vw_institution', 'V') IS NOT NULL
    DROP VIEW gold.vw_institution;
GO

CREATE VIEW gold.vw_institution
AS
SELECT
    institution,
    entity_code
FROM silver.ocb_institution;
GO