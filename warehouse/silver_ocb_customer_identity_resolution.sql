USE [ocb_platform];
GO

/*========================================================================================================================
    OCB PLATFORM v1.0.0

    SILVER CUSTOMER IDENTITY RESOLUTION AND VALIDATION

    Purpose:
        Generate the initial source-to-OCB identity mapping from Bronze customer
        records, validate it against the generator ground truth, and persist the
        validated mapping for the Silver full-load transformation.

    Execution prerequisite:
        Bronze deployment and loading must be complete.
        silver_table_deployment.sql must have been executed.

    Output:
        silver.ocb_customer_identity_resolved

    The candidate OCB IDs use the same identity attributes, ROW_NUMBER ranking,
    tie-breaking order, and canonical-ID ordering as the Silver full-load
    transformation. Ground truth is used for validation, not to assign IDs.
========================================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Remove any previous mapping so a failed validation cannot leave stale IDs available.
DELETE FROM silver.ocb_customer_identity_resolved;

/*========================================================================================================================
    1. UNIFY BRONZE CUSTOMER RECORDS
========================================================================================================================*/
WITH unified_customers AS (
    SELECT
        'ANANSE' AS source_entity,
        TRIM(customer_id) AS source_customer_id,
        LOWER(TRIM(first_name)) AS first_name,
        LOWER(TRIM(last_name)) AS last_name,
        date_of_birth,
        TRIM(phone_number) AS phone_number,
        TRIM(email) AS email,
        created_at
    FROM bronze.ananse_customer

    UNION ALL

    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        LOWER(TRIM(first_name)),
        LOWER(TRIM(last_name)),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer

    UNION ALL

    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        LOWER(TRIM(first_name)),
        LOWER(TRIM(last_name)),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
)
SELECT *
INTO #unified_customers
FROM unified_customers;

/*========================================================================================================================
    2. REPRODUCE THE SILVER CANONICAL ID-GENERATION LOGIC

    The ranking and ordering below intentionally match the OCB CUSTOMER block
    in WP-5.3-silver_transformations_final_load.sql.
========================================================================================================================*/
WITH ranked_customers AS (
    SELECT
        uc.source_entity,
        uc.source_customer_id,
        uc.first_name,
        uc.last_name,
        uc.date_of_birth,
        uc.phone_number,
        uc.email,
        uc.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY
                uc.first_name,
                uc.last_name,
                uc.date_of_birth,
                uc.phone_number,
                uc.email
            ORDER BY
                uc.created_at DESC,
                uc.source_entity ASC,
                uc.source_customer_id ASC
        ) AS flag
    FROM #unified_customers AS uc
),
canonical_customers AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                first_name,
                last_name,
                date_of_birth,
                phone_number,
                email
        ) AS ocb_customer_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    FROM ranked_customers
    WHERE flag = 1
)
SELECT
    rc.source_entity,
    rc.source_customer_id,
    cc.ocb_customer_id
INTO #candidate_identity_mapping
FROM ranked_customers AS rc
INNER JOIN canonical_customers AS cc
    ON  rc.first_name = cc.first_name
    AND rc.last_name = cc.last_name
    AND rc.date_of_birth = cc.date_of_birth
    AND rc.phone_number = cc.phone_number
    AND (rc.email = cc.email OR (rc.email IS NULL AND cc.email IS NULL));

/*========================================================================================================================
    3. LOAD AND NORMALIZE GENERATOR GROUND TRUTH

    Update the BULK INSERT path for the machine executing this script.
========================================================================================================================*/
CREATE TABLE #synthetic_identity_ground_truth_raw (
    synthetic_person_id VARCHAR(20) NOT NULL,
    source_entity       VARCHAR(50) NOT NULL,
    source_customer_id  VARCHAR(100) NOT NULL
);

BULK INSERT #synthetic_identity_ground_truth_raw
FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\control\synthetic_identity_ground_truth.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

SELECT
    TRIM(synthetic_person_id) AS synthetic_person_id,
    TRIM(UPPER(LEFT(TRIM(source_entity), CHARINDEX('.', TRIM(source_entity) + '.') - 1))) AS source_entity,
    TRIM(REPLACE(REPLACE(source_customer_id, CHAR(13), ''), CHAR(10), '')) AS source_customer_id
INTO #synthetic_identity_ground_truth
FROM #synthetic_identity_ground_truth_raw;

/*========================================================================================================================
    4. VALIDATE SOURCE AND GROUND-TRUTH COVERAGE
========================================================================================================================*/
SELECT
    COUNT(*) AS bronze_customer_count,
    (SELECT COUNT(*) FROM #synthetic_identity_ground_truth) AS ground_truth_row_count,
    (SELECT COUNT(*) FROM #candidate_identity_mapping) AS candidate_mapping_count;

-- Source records without a ground-truth row.
SELECT
    uc.source_entity,
    uc.source_customer_id
FROM #unified_customers AS uc
LEFT JOIN #synthetic_identity_ground_truth AS gt
    ON  uc.source_entity = gt.source_entity
    AND uc.source_customer_id = gt.source_customer_id
WHERE gt.source_customer_id IS NULL;

-- Ground-truth rows without a matching Bronze source record.
SELECT
    gt.source_entity,
    gt.source_customer_id,
    gt.synthetic_person_id
FROM #synthetic_identity_ground_truth AS gt
LEFT JOIN #unified_customers AS uc
    ON  gt.source_entity = uc.source_entity
    AND gt.source_customer_id = uc.source_customer_id
WHERE uc.source_customer_id IS NULL;

-- Duplicate source identities in ground truth.
SELECT
    source_entity,
    source_customer_id,
    COUNT(*) AS mapping_count
FROM #synthetic_identity_ground_truth
GROUP BY source_entity, source_customer_id
HAVING COUNT(*) > 1;

/*========================================================================================================================
    5. COMPARE CANDIDATE MAPPING WITH GROUND TRUTH
========================================================================================================================*/
SELECT
    uc.source_entity,
    uc.source_customer_id,
    gt.synthetic_person_id,
    cm.ocb_customer_id
INTO #identity_comparison
FROM #unified_customers AS uc
LEFT JOIN #synthetic_identity_ground_truth AS gt
    ON  uc.source_entity = gt.source_entity
    AND uc.source_customer_id = gt.source_customer_id
LEFT JOIN #candidate_identity_mapping AS cm
    ON  uc.source_entity = cm.source_entity
    AND uc.source_customer_id = cm.source_customer_id;

-- Coverage summary.
SELECT
    COUNT(*) AS source_record_count,
    COUNT(synthetic_person_id) AS ground_truth_match_count,
    COUNT(ocb_customer_id) AS candidate_mapping_count,
    SUM(CASE WHEN synthetic_person_id IS NULL THEN 1 ELSE 0 END) AS missing_ground_truth_count,
    SUM(CASE WHEN ocb_customer_id IS NULL THEN 1 ELSE 0 END) AS missing_candidate_mapping_count
FROM #identity_comparison;

-- False splits: one ground-truth person assigned multiple candidate OCB IDs.
SELECT
    synthetic_person_id,
    COUNT(DISTINCT ocb_customer_id) AS candidate_ocb_customer_count
FROM #identity_comparison
WHERE synthetic_person_id IS NOT NULL
GROUP BY synthetic_person_id
HAVING COUNT(DISTINCT ocb_customer_id) > 1;

-- False merges: one candidate OCB ID assigned to multiple ground-truth people.
SELECT
    ocb_customer_id,
    COUNT(DISTINCT synthetic_person_id) AS ground_truth_person_count
FROM #identity_comparison
WHERE ocb_customer_id IS NOT NULL
    AND synthetic_person_id IS NOT NULL
GROUP BY ocb_customer_id
HAVING COUNT(DISTINCT synthetic_person_id) > 1;

/*========================================================================================================================
    6. STOP IF VALIDATION DOES NOT PASS
========================================================================================================================*/
IF EXISTS (
    SELECT 1
    FROM #identity_comparison
    WHERE synthetic_person_id IS NULL OR ocb_customer_id IS NULL
)
    THROW 51001, 'Identity resolution failed: one or more Bronze customer records lack ground-truth or candidate identity mappings.', 1;

IF EXISTS (
    SELECT 1
    FROM #synthetic_identity_ground_truth AS gt
    LEFT JOIN #unified_customers AS uc
        ON  gt.source_entity = uc.source_entity
        AND gt.source_customer_id = uc.source_customer_id
    WHERE uc.source_customer_id IS NULL
)
    THROW 51002, 'Identity resolution failed: ground-truth contains source identities absent from Bronze.', 1;

IF EXISTS (
    SELECT 1
    FROM #synthetic_identity_ground_truth
    GROUP BY source_entity, source_customer_id
    HAVING COUNT(*) > 1
)
    THROW 51003, 'Identity resolution failed: duplicate source identity mappings exist in ground truth.', 1;

IF EXISTS (
    SELECT 1
    FROM #identity_comparison
    GROUP BY synthetic_person_id
    HAVING COUNT(DISTINCT ocb_customer_id) > 1
)
    THROW 51004, 'Identity resolution failed: false splits detected.', 1;

IF EXISTS (
    SELECT 1
    FROM #identity_comparison
    GROUP BY ocb_customer_id
    HAVING COUNT(DISTINCT synthetic_person_id) > 1
)
    THROW 51005, 'Identity resolution failed: false merges detected.', 1;

/*========================================================================================================================
    7. PERSIST VALIDATED IDENTITY MAPPING

    The output is rebuilt only after all validation checks pass.
========================================================================================================================*/
BEGIN TRY
    BEGIN TRANSACTION;

    INSERT INTO silver.ocb_customer_identity_resolved (
        source_entity,
        source_customer_id,
        cross_domain_id,
        ocb_customer_id
    )
    SELECT
        ic.source_entity,
        ic.source_customer_id,
        ic.synthetic_person_id,
        ic.ocb_customer_id
    FROM #identity_comparison AS ic;

    COMMIT TRANSACTION;

    SELECT
        COUNT(*) AS resolved_identity_count,
        COUNT(DISTINCT cross_domain_id) AS ground_truth_person_count,
        COUNT(DISTINCT ocb_customer_id) AS resolved_ocb_customer_count,
        'PASS' AS identity_resolution_status
    FROM silver.ocb_customer_identity_resolved;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
