USE [ocb_platform];
GO

/*========================================================================================================================
    1. UNIFY BRONZE CUSTOMER DATA

    Combine customer records from all source systems into a temporary table.
========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                AS source_entity,
        TRIM(customer_id)       AS source_customer_id,
        LOWER(TRIM(first_name)) AS first_name,
        LOWER(TRIM(last_name))  AS last_name,
        date_of_birth,
        TRIM(phone_number)      AS phone_number,
        TRIM(email)             AS email
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        LOWER(TRIM(first_name)),
        LOWER(TRIM(last_name)),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email)
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        LOWER(TRIM(first_name)),
        LOWER(TRIM(last_name)),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email)
    FROM bronze.oman_remit_customer
    )
SELECT
    *
INTO #unified_customers
FROM unified_customers;

/*========================================================================================================================
    2. LOAD IDENTITY GROUND TRUTH

    Load the generator identity mapping into a temporary table.
========================================================================================================================*/
CREATE TABLE #synthetic_identity_ground_truth_raw (
    synthetic_person_id VARCHAR(20) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,
    source_customer_id  VARCHAR(100) NOT NULL
    );

BULK INSERT #synthetic_identity_ground_truth_raw
FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\control\synthetic_identity_ground_truth.csv' WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
        );

/*========================================================================================================================
    3. CHECK INPUT COUNTS

    Compare the row counts of the source customer data and loaded ground truth.
========================================================================================================================*/
SELECT
    COUNT(*) AS row_count
FROM #synthetic_identity_ground_truth_raw;

SELECT
    COUNT(*) AS row_count
FROM #unified_customers;

/*========================================================================================================================
    4. NORMALIZE GROUND TRUTH

    Standardize the ground-truth identifiers and source entity values.
========================================================================================================================*/
SELECT
    TRIM(gtr.synthetic_person_id)                                                                      AS synthetic_person_id,
    TRIM(REPLACE(REPLACE(gtr.source_customer_id, CHAR(13), ''), CHAR(10), ''))                         AS source_customer_id,
    TRIM(UPPER(SUBSTRING(TRIM(gtr.source_entity), 1, CHARINDEX('.', TRIM(gtr.source_entity), 1) - 1))) AS source_entity
INTO #synthetic_identity_ground_truth
FROM #synthetic_identity_ground_truth_raw AS gtr;

/*========================================================================================================================
    5. CHECK SOURCE ENTITY VALUES

    Compare the distinct source entity values in the source data and ground truth.
========================================================================================================================*/
SELECT DISTINCT
    source_entity
FROM #unified_customers;

SELECT DISTINCT
    source_entity
FROM #synthetic_identity_ground_truth;

/*========================================================================================================================
    6. MATCH SOURCE DATA TO GROUND TRUTH

    Join source customer records to their corresponding ground-truth identities.
========================================================================================================================*/
SELECT
    uc.source_customer_id,
    uc.source_entity,
    gt.synthetic_person_id,
    uc.first_name,
    uc.last_name,
    uc.date_of_birth,
    uc.phone_number,
    uc.email
INTO #unified_customers_ground_truth
FROM #unified_customers AS uc
LEFT JOIN #synthetic_identity_ground_truth AS gt ON
        uc.source_customer_id = gt.source_customer_id
            AND uc.source_entity = gt.source_entity;

/*========================================================================================================================
    7. CHECK GROUND-TRUTH COVERAGE

    Count matched and unmatched source customer records.
========================================================================================================================*/
SELECT
    COUNT(ucgt.source_customer_id)                                   AS uc_row_count,
    COUNT(ucgt.synthetic_person_id)                                  AS gt_row_count,
    COUNT(ucgt.source_customer_id) - COUNT(ucgt.synthetic_person_id) AS unmatched_count
FROM #unified_customers_ground_truth AS ucgt;

/*========================================================================================================================
    8. COMPARE WITH SILVER IDENTITY

    Join the ground-truth mapping to the existing Silver identity mapping.
========================================================================================================================*/
SELECT
    ucgt.source_entity,
    ucgt.source_customer_id,
    ucgt.synthetic_person_id,
    sci.ocb_customer_id
INTO #identity_comparison
FROM #unified_customers_ground_truth AS ucgt
LEFT JOIN silver.ocb_customer_identity AS sci ON
        ucgt.source_customer_id = sci.source_customer_id
            AND ucgt.source_entity = sci.source_entity;

/*========================================================================================================================
    9. CHECK IDENTITY COVERAGE

    Return records with missing ground-truth or Silver identity mappings.
========================================================================================================================*/
SELECT
    *
FROM #identity_comparison
WHERE ocb_customer_id IS NULL
        OR synthetic_person_id IS NULL
ORDER BY ocb_customer_id ASC;

SELECT
    COUNT(*)                          AS source_row_count,
    COUNT(synthetic_person_id)        AS ground_truth_count,
    COUNT(ocb_customer_id)            AS silver_identity_count,
    COUNT(*) - COUNT(ocb_customer_id) AS silver_unmatched_count
FROM #identity_comparison;

/*========================================================================================================================
    10. CHECK FALSE SPLITS

    Identify ground-truth identities assigned to multiple OCB customer IDs.
========================================================================================================================*/
SELECT
    synthetic_person_id,
    COUNT(DISTINCT ocb_customer_id) AS ocb_customer_count
FROM #identity_comparison
GROUP BY synthetic_person_id
HAVING COUNT(DISTINCT ocb_customer_id) > 1
ORDER BY synthetic_person_id;

/*========================================================================================================================
    11. CHECK FALSE MERGES

    Identify OCB customer IDs assigned to multiple ground-truth identities.
========================================================================================================================*/
SELECT
    ocb_customer_id,
    COUNT(DISTINCT synthetic_person_id) AS synthetic_person_count
FROM #identity_comparison
GROUP BY ocb_customer_id
HAVING COUNT(DISTINCT synthetic_person_id) > 1
ORDER BY ocb_customer_id;

/*========================================================================================================================
    12. CHECK IDENTITY MAPPINGS

    Display the distinct ground-truth to OCB identity mappings.
========================================================================================================================*/
SELECT
    synthetic_person_id,
    ocb_customer_id,
    COUNT(*) AS source_record_count
FROM #identity_comparison
GROUP BY synthetic_person_id,
    ocb_customer_id
ORDER BY synthetic_person_id,
    ocb_customer_id;

SELECT
    COUNT(*)                            AS mapping_count,
    COUNT(DISTINCT synthetic_person_id) AS synthetic_person_count,
    COUNT(DISTINCT ocb_customer_id)     AS ocb_customer_count
FROM (
    SELECT
        synthetic_person_id,
        ocb_customer_id
    FROM #identity_comparison
    GROUP BY synthetic_person_id,
        ocb_customer_id
    ) AS mappings;

/*========================================================================================================================
    13. CHECK DISTINCT ID COUNTS

    Compare source identities, ground-truth identities, and OCB identities.
========================================================================================================================*/
SELECT
    COUNT(*)                                                 AS row_count,
    COUNT(DISTINCT source_entity + '|' + source_customer_id) AS source_identity_count,
    COUNT(DISTINCT synthetic_person_id)                      AS cross_domain_count,
    COUNT(DISTINCT ocb_customer_id)                          AS ocb_customer_count
FROM #identity_comparison;

/*========================================================================================================================
    14. FREEZE RESOLVED IDENTITY MAPPING

    Persist the validated identity mapping for use by the Silver transformation pipeline.
========================================================================================================================*/
SELECT
    ic.source_entity,
    ic.source_customer_id,
    ic.synthetic_person_id AS cross_domain_id,
    ic.ocb_customer_id
INTO silver.ocb_customer_identity_resolved
FROM #identity_comparison AS ic;
GO


