USE [ocb_platform];
GO

/*========================================================================================================================*
    CUSTOMER IDENTITY DIAGNOSTICS AND CANONICAL RECORD RESOLUTION OCB Platform v1.0.0

    The resolution logic uses the source customer ID suffix to identify customer records that are candidates for
    cross-institution identity resolution.
    Within a shared suffix, the customer attributes are used to distinguish identity groups. The most recently created source
    record is then selected as the canonical representation of that identity group.

    IMPORTANT:
    - The diagnostics below are investigative only.
    - flag = 1 identifies the canonical source record for an identity group.
    - flag > 1 does not mean the source record is invalid or should be deleted.
    - The final identity bridge should retain qualifying source records and map them to the same OCB customer identity.
*========================================================================================================================*/
/*========================================================================================================================*
    DIAGNOSE 1 — IDENTIFY CUSTOMER ID SUFFIXES SHARED ACROSS INSTITUTIONS

    The source customer IDs use institution-specific prefixes, while the customer suffix provides the common identifier used to
    identify potential cross-institution customer relationships.
    Example:
        AN-C000002  →  C000002
        SC-C000002  →  C000002
        OR-C000002  →  C000002
    Only suffixes appearing in more than one source institution are considered
    cross-domain identity candidates.
*========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        created_at
    FROM bronze.oman_remit_customer
    )
SELECT
    cross_domain_id,
    COUNT(*)                        AS customer_record_count,
    COUNT(DISTINCT source_entity)   AS institution_count,
    STRING_AGG(source_entity, ', ') AS institutions_present
FROM unified_customers
GROUP BY cross_domain_id
HAVING COUNT(DISTINCT source_entity) > 1
ORDER BY cross_domain_id;

/*========================================================================================================================*
    DIAGNOSE 2A — IDENTIFY ATTRIBUTE CONFLICTS WITHIN SHARED SUFFIXES

    A shared suffix alone does not establish that the records represent the same person. This diagnostic identifies suffixes
    where basic identity attributes differ across source records.
    These differences are important because they show where the suffix identifies a candidate relationship but the customer
    attributes must be considered before records are treated as one analytical identity.
*========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        created_at
    FROM bronze.oman_remit_customer
    )
SELECT
    cross_domain_id,
    COUNT(DISTINCT first_name)    AS first_name_count,
    COUNT(DISTINCT last_name)     AS last_name_count,
    COUNT(DISTINCT date_of_birth) AS dob_count
FROM unified_customers
GROUP BY cross_domain_id
HAVING COUNT(DISTINCT first_name) > 1
        OR COUNT(DISTINCT last_name) > 1
        OR COUNT(DISTINCT date_of_birth) > 1
ORDER BY cross_domain_id;

/*========================================================================================================================*
    DIAGNOSE 2B — REVIEW FULL IDENTITY ATTRIBUTES FOR SHARED SUFFIXES

    This diagnostic extends the conflict review to the full customer attributes used by the resolution rule.
    The result is restricted to shared suffixes so that unrelated customers whose source IDs are unique to one institution are
    not brought into the cross-domain identity analysis.
*========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        TRIM(customer_id)                                       AS customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        TRIM(phone_number)                                      AS phone_number,
        TRIM(email)                                             AS email,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
    ),
shared_suffixes
AS (
    SELECT
        cross_domain_id
    FROM unified_customers
    GROUP BY cross_domain_id
    HAVING COUNT(DISTINCT source_entity) > 1
    )
SELECT
    uc.cross_domain_id,
    uc.source_entity,
    uc.customer_id,
    uc.first_name,
    uc.last_name,
    uc.date_of_birth,
    uc.phone_number,
    uc.email,
    uc.created_at
FROM unified_customers AS uc
INNER JOIN shared_suffixes AS ss ON
        uc.cross_domain_id = ss.cross_domain_id
WHERE uc.cross_domain_id = 'C000002'
ORDER BY uc.cross_domain_id,
    uc.created_at DESC;

/*========================================================================================================================*
    CANONICAL RECORD RESOLUTION

    This is the actual identity-resolution ranking logic.
    The customer suffix first limits the population to cross-institution candidates. Within each suffix, records are grouped
    using the customer attributes that define the synthetic identity match:
        cross_domain_id
        first_name
        last_name
        date_of_birth
        phone_number
        email
    Within each resulting identity group, the most recently created source record receives flag = 1 and is therefore selected
    as the canonical source representation.

    source_entity and customer_id provide deterministic ordering when two records have the same created_at value.

    The flag is a ranking attribute only. It does not indicate that records with higher flag values are duplicates to be 
    removed; those records remain valid
    source records and can be mapped to the same OCB identity where appropriate.
*========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        TRIM(customer_id)                                       AS customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        TRIM(phone_number)                                      AS phone_number,
        TRIM(email)                                             AS email,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
    ),
shared_suffixes
AS (
    SELECT
        cross_domain_id
    FROM unified_customers
    GROUP BY cross_domain_id
    HAVING COUNT(DISTINCT source_entity) > 1
    ),
ranked_customers
AS (
    SELECT
        uc.cross_domain_id,
        uc.source_entity,
        uc.customer_id,
        uc.first_name,
        uc.last_name,
        uc.date_of_birth,
        uc.phone_number,
        uc.email,
        uc.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY uc.cross_domain_id,
            uc.first_name,
            uc.last_name,
            uc.date_of_birth,
            uc.phone_number,
            uc.email ORDER BY uc.created_at DESC,
                uc.source_entity ASC,
                uc.customer_id ASC
            ) AS flag
    FROM unified_customers AS uc
    INNER JOIN shared_suffixes AS ss ON
            uc.cross_domain_id = ss.cross_domain_id
    )
SELECT -- Verification against the previously identified C000002 identity candidates.
    cross_domain_id,
    source_entity,
    customer_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email,
    created_at,
    flag
FROM ranked_customers
WHERE flag = 1
        AND cross_domain_id = 'C000002'
ORDER BY cross_domain_id,
    source_entity,
    customer_id;

/*========================================================================================================================
    OCB CUSTOMER IDENTITY MAPPING

    The identity-resolution query has already established the canonical record
    using flag = 1.

    The resolved identity is therefore represented by the same combination of:
        cross_domain_id
        first_name
        last_name
        date_of_birth
        phone_number
        email
    Each resolved identity group receives one OCB customer ID.
    The canonical record (flag = 1) supplies the OCB customer key.
    Every source customer record belonging to the same identity group is then mapped to that OCB customer ID.
========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        TRIM(customer_id)                                       AS customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        TRIM(phone_number)                                      AS phone_number,
        TRIM(email)                                             AS email,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
    ),
shared_suffixes
AS (
    SELECT
        cross_domain_id
    FROM unified_customers
    GROUP BY cross_domain_id
    HAVING COUNT(DISTINCT source_entity) > 1
    ),
ranked_customers
AS (
    SELECT
        uc.cross_domain_id,
        uc.source_entity,
        uc.customer_id,
        uc.first_name,
        uc.last_name,
        uc.date_of_birth,
        uc.phone_number,
        uc.email,
        uc.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY uc.cross_domain_id,
            uc.first_name,
            uc.last_name,
            uc.date_of_birth,
            uc.phone_number,
            uc.email ORDER BY uc.created_at DESC,
                uc.source_entity ASC,
                uc.customer_id ASC
            ) AS flag
    FROM unified_customers AS uc
    INNER JOIN shared_suffixes AS ss ON
            uc.cross_domain_id = ss.cross_domain_id
    ),
identity_groups
AS (
    SELECT DISTINCT
        cross_domain_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    FROM ranked_customers
    ),
ocb_identity_assignment
AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY cross_domain_id,
                first_name,
                last_name,
                date_of_birth,
                phone_number,
                email
            ) AS ocb_customer_id,
        cross_domain_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    FROM identity_groups
    )
SELECT
    oia.ocb_customer_id,
    rc.source_entity,
    rc.customer_id,
    rc.cross_domain_id,
    rc.first_name,
    rc.last_name,
    rc.date_of_birth,
    rc.phone_number,
    rc.email,
    rc.created_at,
    rc.flag
FROM ranked_customers AS rc
INNER JOIN ocb_identity_assignment AS oia ON
        rc.cross_domain_id = oia.cross_domain_id
            AND rc.first_name = oia.first_name
            AND rc.last_name = oia.last_name
            AND rc.date_of_birth = oia.date_of_birth
            AND rc.phone_number = oia.phone_number
            AND rc.email = oia.email
ORDER BY oia.ocb_customer_id,
    rc.flag;

/*========================================================================================================================
    OCB CUSTOMER POPULATION

    Identity resolution is based on:
        first_name
        last_name
        date_of_birth
        phone_number
        email
    cross_domain_id is retained for source-level inspection only.
    It is NOT used as part of the identity definition.

    flag = 1 identifies the surviving canonical source record for
    each resolved OCB customer identity.
========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        TRIM(customer_id)                                       AS customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        TRIM(phone_number)                                      AS phone_number,
        TRIM(email)                                             AS email,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
    ),
ranked_customers
AS (
    SELECT
        uc.source_entity,
        uc.customer_id,
        uc.cross_domain_id,
        uc.first_name,
        uc.last_name,
        uc.date_of_birth,
        uc.phone_number,
        uc.email,
        uc.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY uc.first_name,
            uc.last_name,
            uc.date_of_birth,
            uc.phone_number,
            uc.email ORDER BY uc.created_at DESC,
                uc.source_entity ASC,
                uc.customer_id ASC
            ) AS flag
    FROM unified_customers AS uc
    )
/*========================================================================================================================
    POPULATE OCB CUSTOMER
========================================================================================================================*/
INSERT INTO silver.ocb_customer (
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email
    )
SELECT
    ROW_NUMBER() OVER (
        ORDER BY first_name,
            last_name,
            date_of_birth,
            phone_number,
            email
        ) AS ocb_customer_id,
    LOWER(first_name) AS first_name,
    LOWER(last_name) AS last_name,
    date_of_birth,
    phone_number,
    email
FROM ranked_customers
WHERE flag = 1;
GO

/*========================================================================================================================
    VERIFY SILVER DATA
========================================================================================================================*/
SELECT
    *
FROM silver.ocb_customer
WHERE last_name = 'quaye'
        AND first_name = 'fiifi'
ORDER BY date_of_birth,
    ocb_customer_id;
GO

/*========================================================================================================================*
    OCB CUSTOMER IDENTITY POPULATION
    Purpose:
    Populates silver.ocb_customer_identity with the resolved relationship between each source-system customer and the canonical
    OCB customer identity.
    The related columns are:
        source_entity
        source_customer_id
        cross_domain_id
        ocb_customer_id
    
    IMPORTANT:
    Every source customer record is inserted into silver.ocb_customer_identity.
    The flag = 1 record is used only to establish the canonical customer profile;
    it does NOT determine which source records are retained in the identity table.
*========================================================================================================================*/
WITH unified_customers
AS (
    SELECT
        'ANANSE'                                                AS source_entity,
        TRIM(customer_id)                                       AS customer_id,
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
        TRIM(first_name)                                        AS first_name,
        TRIM(last_name)                                         AS last_name,
        date_of_birth,
        TRIM(phone_number)                                      AS phone_number,
        TRIM(email)                                             AS email,
        created_at
    FROM bronze.ananse_customer
    
    UNION ALL
    
    SELECT
        'SIKACREDIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.sikacredit_customer
    
    UNION ALL
    
    SELECT
        'OMAN_REMIT',
        TRIM(customer_id),
        SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
        TRIM(first_name),
        TRIM(last_name),
        date_of_birth,
        TRIM(phone_number),
        TRIM(email),
        created_at
    FROM bronze.oman_remit_customer
    ),
ranked_customers
AS (
    SELECT
        uc.source_entity,
        uc.customer_id,
        uc.cross_domain_id,
        uc.first_name,
        uc.last_name,
        uc.date_of_birth,
        uc.phone_number,
        uc.email,
        uc.created_at,
        ROW_NUMBER() OVER (
            PARTITION BY uc.first_name,
            uc.last_name,
            uc.date_of_birth,
            uc.phone_number,
            uc.email ORDER BY uc.created_at DESC,
                uc.source_entity ASC,
                uc.customer_id ASC
            ) AS flag
    FROM unified_customers AS uc
    ),
identity_groups
AS (
    SELECT DISTINCT
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    FROM ranked_customers
    ),
ocb_identity_assignment
AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY first_name,
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
    FROM identity_groups
    )
INSERT INTO silver.ocb_customer_identity (
    source_entity,
    source_customer_id,
    cross_domain_id,
    ocb_customer_id
    )
SELECT
    rc.source_entity,
    rc.customer_id AS source_customer_id,
    rc.cross_domain_id,
    oia.ocb_customer_id
FROM ranked_customers AS rc
INNER JOIN ocb_identity_assignment AS oia ON
        rc.first_name = oia.first_name
            AND rc.last_name = oia.last_name
            AND rc.date_of_birth = oia.date_of_birth
            AND rc.phone_number = oia.phone_number
            AND (
            rc.email = oia.email
                OR (
                rc.email IS NULL
                    AND oia.email IS NULL
                )
            );
GO

/*========================================================================================================================
    VERIFY SILVER DATA
========================================================================================================================*/
SELECT
    *
FROM silver.ocb_customer_identity
WHERE cross_domain_id = 'C001435';
GO

/*
    VERIFY SOURCE → SILVER OCB CUSTOMER ID PRESERVATION

    Purpose:
    Confirm that the ocb_customer_id is preserved in the ocb_customer_identity after transformation.

    A null value would refer to ghost ids in the ocb_customer_identity.
*/
SELECT
    oci.ocb_customer_id,
    oc.first_name,
    oc.last_name,
    oci.source_entity
FROM silver.ocb_customer oc
LEFT OUTER JOIN silver.ocb_customer_identity oci ON
        oc.ocb_customer_id = oci.ocb_customer_id
WHERE oci.ocb_customer_id IS NULL;
GO

/*
    =====================================
        ANANSE CUSTOMER
    =====================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Ananse customer data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Derive the shared Ananse customer identity key.
    7. Detect and resolve potential duplicate customer records.
    8. Load the trusted Silver customer records.
    9. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.ananse_customer

    ## TARGET
    silver.ananse_customer

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * customer_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is the source identifier and the primary key of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.ananse_customer
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.ananse_customer.',
        1;
END
GO

/*
    LB-02 — CUSTOMER IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    customer_id is expected to uniquely identify each source customer.

    Duplicate customer IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            customer_id
        FROM bronze.ananse_customer
        GROUP BY customer_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate customer_id detected in bronze.ananse_customer.',
        2;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — PHONE NUMBER FORMAT CHECK

    ## EXPECTED FORMAT
    +233XXXXXXXXX

    ## CHECKS
    * Phone number is not NULL.
    * Phone number contains 13 characters.
    * Phone number begins with +233.

    ## NOTE
    This is a data-quality check and does not currently block the Silver load.
*/
SELECT
    ac.customer_id,
    ac.phone_number
FROM bronze.ananse_customer AS ac
WHERE ac.phone_number IS NULL
        OR LEN(ac.phone_number) <> 13
        OR ac.phone_number NOT LIKE '+233%'
        OR SUBSTRING(phone_number, 5, 9) LIKE '%[^0-9]%';
GO

/*
    DQ-02 — SHARED PHONE NUMBER PROFILING

    ## PURPOSE
    Identify phone numbers associated with more than one customer.

    ## NOTE
    A shared phone number is not automatically considered invalid.
    Multiple individuals may legitimately share a phone number.
*/
SELECT
    ac.phone_number,
    COUNT(DISTINCT ac.customer_id)   AS distinct_customer_count,
    STRING_AGG(ac.customer_id, ', ') AS associated_customer_ids
FROM bronze.ananse_customer AS ac
GROUP BY ac.phone_number
HAVING COUNT(DISTINCT ac.customer_id) > 1;
GO

/*
    DQ-03 — NATIONALITY PROFILING

    ## PURPOSE
    Identify distinct nationality values and determine whether standardization is required.
*/
SELECT DISTINCT
    TRIM(ac.nationality) AS nationality
FROM bronze.ananse_customer AS ac
ORDER BY nationality;
GO

/*
    DQ-04 — DATE OF BIRTH VALIDITY

    ## RULE
    date_of_birth must occur before the current date.

    ## PURPOSE
    Identify future or current-date dates of birth.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    ac.customer_id,
    ac.date_of_birth
FROM bronze.ananse_customer AS ac
WHERE ac.date_of_birth >= CAST(GETDATE() AS DATE);
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'ananse_customer',
    'bronze.ananse_customer'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Ananse customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.ananse_customer;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES
    TR-01 — Trim and lower-case applicable string attributes.
    TR-02 — Preserve the source customer_id.
    TR-03 — Derive ananse_customer_key from customer_id.
    TR-04 — Perform duplicate detection after standardization.
    TR-05 — A potential duplicate customer is identified where the standardized first_name, last_name, date_of_birth and 
    phone_number are identical.
    The duplicate-detection composite is:
        first_name
        last_name
        date_of_birth
        phone_number
    TR-06 — Where potential duplicates exist, retain the record with the latest created_at.
    TR-07 — Where created_at is identical, use the highest customer_id as the deterministic tie-breaker.
*/
WITH standardized_customers
AS (
    SELECT
        TRIM(ac.customer_id)        AS customer_id,
        LOWER(TRIM(ac.first_name))  AS first_name,
        LOWER(TRIM(ac.last_name))   AS last_name,
        ac.date_of_birth,
        LOWER(TRIM(ac.nationality)) AS nationality,
        LOWER(TRIM(ac.occupation))  AS occupation,
        TRIM(ac.phone_number)       AS phone_number,
        TRIM(ac.email)              AS email,
        ac.created_at
    FROM bronze.ananse_customer AS ac
    ),
ranked_customers_cte
AS (
    SELECT
        *
    FROM standardized_customers AS sc
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.ananse_customer (
    customer_id,
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    nationality,
    occupation,
    phone_number,
    email,
    created_at
    )
SELECT
    rc.customer_id,
    oci.ocb_customer_id,
    rc.first_name,
    rc.last_name,
    rc.date_of_birth,
    rc.nationality,
    rc.occupation,
    rc.phone_number,
    rc.email,
    rc.created_at
FROM ranked_customers_cte AS rc
LEFT JOIN silver.ocb_customer_identity AS oci ON
        rc.customer_id = oci.source_customer_id
            AND oci.source_entity = 'ANANSE';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.ananse_customer;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.ananse_customer;
GO

/*
Verify whether every Ananse customer resolves to exactly one OCB identity
*/
SELECT
    ac.customer_id,
    COUNT(oci.ocb_customer_id) AS identity_matches
FROM bronze.ananse_customer AS ac
LEFT JOIN silver.ocb_customer_identity AS oci
    ON ac.customer_id = oci.source_customer_id
    AND oci.source_entity = 'ANANSE'
GROUP BY
    ac.customer_id
HAVING COUNT(oci.ocb_customer_id) <> 1;
GO



/*
    =====================================
        SIKACREDIT CUSTOMER
    =====================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Sikacredit customer data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Detect and resolve potential duplicate customer records.
    7. Load the trusted Silver customer records.
    8. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.sikacredit_customer

    ## TARGET
    silver.sikacredit_customer

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * customer_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is the source identifier and the primary key of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.sikacredit_customer
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.sikacredit_customer.',
        1;
END
GO

/*
    LB-02 — CUSTOMER IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    customer_id is expected to uniquely identify each source customer.

    Duplicate customer IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            customer_id
        FROM bronze.sikacredit_customer
        GROUP BY customer_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate customer_id detected in bronze.sikacredit_customer.',
        2;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — PHONE NUMBER FORMAT CHECK

    ## EXPECTED FORMAT
    +233XXXXXXXXX

    ## CHECKS
    * Phone number is not NULL.
    * Phone number contains 13 characters.
    * Phone number begins with +233.

    ## NOTE
    This is a data-quality check and does not currently block the Silver load.
*/
SELECT
    sc.customer_id,
    sc.phone_number
FROM bronze.sikacredit_customer AS sc
WHERE sc.phone_number IS NULL
        OR LEN(sc.phone_number) <> 13
        OR sc.phone_number NOT LIKE '+233%'
        OR SUBSTRING(phone_number, 5, 9) LIKE '%[^0-9]%';
GO

/*
    DQ-02 — SHARED PHONE NUMBER PROFILING

    ## PURPOSE
    Identify phone numbers associated with more than one customer.

    ## NOTE
    A shared phone number is not automatically considered invalid.
    Multiple individuals may legitimately share a phone number.
*/
SELECT
    sc.phone_number,
    COUNT(DISTINCT sc.customer_id)   AS distinct_customer_count,
    STRING_AGG(sc.customer_id, ', ') AS associated_customer_ids
FROM bronze.sikacredit_customer AS sc
GROUP BY sc.phone_number
HAVING COUNT(DISTINCT sc.customer_id) > 1;
GO

/*
    DQ-03 — NATIONALITY PROFILING

    ## PURPOSE
    Identify distinct nationality values and determine whether standardization is required.
*/
SELECT DISTINCT
    TRIM(sc.nationality) AS nationality
FROM bronze.sikacredit_customer AS sc
ORDER BY nationality;
GO

/*
    DQ-04 — DATE OF BIRTH VALIDITY

    ## RULE
    date_of_birth must occur before the current date.

    ## PURPOSE
    Identify future or current-date dates of birth.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    sc.customer_id,
    sc.date_of_birth
FROM bronze.sikacredit_customer AS sc
WHERE sc.date_of_birth >= CAST(GETDATE() AS DATE);
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'sikacredit_customer',
    'bronze.sikacredit_customer'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Sikacredit customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.sikacredit_customer;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES
    TR-01 — Trim and lower-case applicable string attributes.
    TR-02 — Preserve the source customer_id.
    TR-03 — Perform duplicate detection after standardization.
    TR-04 — A potential duplicate customer is identified where the standardized first_name, last_name, date_of_birth and 
    phone_number are identical.
    The duplicate-detection composite is:
        first_name
        last_name
        date_of_birth
        phone_number
    TR-05 — Where potential duplicates exist, retain the record with the latest created_at.
    TR-06 — Where created_at is identical, use the highest customer_id as the deterministic tie-breaker.
*/
WITH standardized_customers
AS (
    SELECT
        TRIM(sc.customer_id)        AS customer_id,
        LOWER(TRIM(sc.first_name))  AS first_name,
        LOWER(TRIM(sc.last_name))   AS last_name,
        sc.date_of_birth,
        LOWER(TRIM(sc.nationality)) AS nationality,
        LOWER(TRIM(sc.occupation))  AS occupation,
        TRIM(sc.phone_number)       AS phone_number,
        TRIM(sc.email)              AS email,
        sc.created_at
    FROM bronze.sikacredit_customer AS sc
    ),
ranked_customers_cte
AS (
    SELECT
        *
    FROM standardized_customers AS sc
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.sikacredit_customer (
    customer_id,
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    nationality,
    occupation,
    phone_number,
    email,
    created_at
    )
SELECT
    rc.customer_id,
    oci.ocb_customer_id,
    rc.first_name,
    rc.last_name,
    rc.date_of_birth,
    rc.nationality,
    rc.occupation,
    rc.phone_number,
    rc.email,
    rc.created_at
FROM ranked_customers_cte AS rc
LEFT JOIN silver.ocb_customer_identity AS oci ON
        rc.customer_id = oci.source_customer_id
            AND oci.source_entity = 'SIKACREDIT';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.sikacredit_customer;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.sikacredit_customer;
GO

/*
    Verify whether every SikaCredit customer resolves to exactly one OCB identity
*/
SELECT
    sc.customer_id,
    COUNT(oci.ocb_customer_id) AS identity_matches
FROM bronze.sikacredit_customer AS sc
LEFT JOIN silver.ocb_customer_identity AS oci
    ON sc.customer_id = oci.source_customer_id
    AND oci.source_entity = 'SIKACREDIT'
GROUP BY
    sc.customer_id
HAVING COUNT(oci.ocb_customer_id) <> 1;
GO

/*
    =====================================
        OMAN REMIT CUSTOMER
    =====================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Sikacredit customer data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Detect and resolve potential duplicate customer records.
    7. Load the trusted Silver customer records.
    8. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.oman_remit_customer

    ## TARGET
    silver.oman_remit_customer

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * customer_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is the source identifier and the primary key of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.oman_remit_customer
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.oman_remit_customer.',
        1;
END
GO

/*
    LB-02 — CUSTOMER IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    customer_id is expected to uniquely identify each source customer.

    Duplicate customer IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            customer_id
        FROM bronze.oman_remit_customer
        GROUP BY customer_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate customer_id detected in bronze.oman_remit_customer.',
        2;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — PHONE NUMBER FORMAT CHECK

    ## EXPECTED FORMAT
    +233XXXXXXXXX

    ## CHECKS
    * Phone number is not NULL.
    * Phone number contains 13 characters.
    * Phone number begins with +233.

    ## NOTE
    This is a data-quality check and does not currently block the Silver load.
*/
SELECT
    oc.customer_id,
    oc.phone_number
FROM bronze.oman_remit_customer AS oc
WHERE oc.phone_number IS NULL
        OR LEN(oc.phone_number) <> 13
        OR oc.phone_number NOT LIKE '+233%'
        OR SUBSTRING(oc.phone_number, 5, 9) LIKE '%[^0-9]%';
GO

/*
    DQ-02 — SHARED PHONE NUMBER PROFILING

    ## PURPOSE
    Identify phone numbers associated with more than one customer.

    ## NOTE
    A shared phone number is not automatically considered invalid.
    Multiple individuals may legitimately share a phone number.
*/
SELECT
    oc.phone_number,
    COUNT(DISTINCT oc.customer_id)   AS distinct_customer_count,
    STRING_AGG(oc.customer_id, ', ') AS associated_customer_ids
FROM bronze.oman_remit_customer AS oc
GROUP BY oc.phone_number
HAVING COUNT(DISTINCT oc.customer_id) > 1;
GO

/*
    DQ-03 — NATIONALITY PROFILING

    ## PURPOSE
    Identify distinct nationality values and determine whether standardization is required.
*/
SELECT DISTINCT
    TRIM(oc.nationality) AS nationality
FROM bronze.oman_remit_customer AS oc
ORDER BY nationality;
GO

/*
    DQ-04 — DATE OF BIRTH VALIDITY

    ## RULE
    date_of_birth must occur before the current date.

    ## PURPOSE
    Identify future or current-date dates of birth.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    oc.customer_id,
    oc.date_of_birth
FROM bronze.oman_remit_customer AS oc
WHERE oc.date_of_birth >= CAST(GETDATE() AS DATE);
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'oman_remit_customer',
    'bronze.oman_remit_customer'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Sikacredit customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.oman_remit_customer;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES
    TR-01 — Trim and lower-case applicable string attributes.
    TR-02 — Preserve the source customer_id.
    TR-03 — Perform duplicate detection after standardization.
    TR-04 — A potential duplicate customer is identified where the standardized first_name, last_name, date_of_birth and 
    phone_number are identical.
    The duplicate-detection composite is:
        first_name
        last_name
        date_of_birth
        phone_number
    TR-05 — Where potential duplicates exist, retain the record with the latest created_at.
    TR-06 — Where created_at is identical, use the highest customer_id as the deterministic tie-breaker.
*/
WITH standardized_customers
AS (
    SELECT
        TRIM(oc.customer_id)        AS customer_id,
        LOWER(TRIM(oc.first_name))  AS first_name,
        LOWER(TRIM(oc.last_name))   AS last_name,
        oc.date_of_birth,
        LOWER(TRIM(oc.nationality)) AS nationality,
        LOWER(TRIM(oc.occupation))  AS occupation,
        TRIM(oc.phone_number)       AS phone_number,
        TRIM(oc.email)              AS email,
        oc.created_at
    FROM bronze.oman_remit_customer AS oc
    ),
ranked_customers_cte
AS (
    SELECT
        *
    FROM standardized_customers AS sc
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.oman_remit_customer (
    customer_id,
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    nationality,
    occupation,
    phone_number,
    email,
    created_at
    )
SELECT
    rc.customer_id,
    oci.ocb_customer_id,
    rc.first_name,
    rc.last_name,
    rc.date_of_birth,
    rc.nationality,
    rc.occupation,
    rc.phone_number,
    rc.email,
    rc.created_at
FROM ranked_customers_cte AS rc
LEFT JOIN silver.ocb_customer_identity AS oci ON
        rc.customer_id = oci.source_customer_id
            AND oci.source_entity = 'OMAN_REMIT';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.oman_remit_customer;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.oman_remit_customer;
GO

/*
    Verify whether every Oman_Remit customer resolves to exactly one OCB identity
*/
SELECT
    orc.customer_id,
    COUNT(oci.ocb_customer_id) AS identity_matches
FROM bronze.oman_remit_customer AS orc
LEFT JOIN silver.ocb_customer_identity AS oci
    ON orc.customer_id = oci.source_customer_id
    AND oci.source_entity = 'OMAN_REMIT'
GROUP BY
    orc.customer_id
HAVING COUNT(oci.ocb_customer_id) <> 1;
GO

/*
    VERIFY DUPLICATE-RESOLUTION IMPACT

    Purpose:
    Identify Bronze customer records that were not carried into Silver.
    These records should be explainable by the documented duplicate-resolution rule.
*/
SELECT
    boc.customer_id AS excluded_bronze_customer_id,
    boc.first_name,
    boc.last_name,
    boc.date_of_birth,
    boc.phone_number,
    boc.created_at
FROM bronze.oman_remit_customer AS boc
LEFT OUTER JOIN silver.oman_remit_customer AS soc ON
        boc.customer_id = soc.customer_id
LEFT OUTER JOIN silver.ocb_customer_identity AS oci ON
        boc.customer_id = oci.source_customer_id
WHERE soc.customer_id IS NULL
        AND oci.source_customer_id IS NULL
ORDER BY boc.first_name,
    boc.last_name,
    boc.date_of_birth,
    boc.phone_number,
    boc.created_at DESC;
GO

/*
    =========================================
    SIKACREDIT LOAN.
    =========================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Sikacredit loan data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Detect and resolve potential duplicate customer records.
    7. Load the trusted Silver customer records.
    8. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.[sikacredit_loan]

    ## TARGET
   silver.[sikacredit_loan]

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * loan_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — REMITTANCE IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    loan_id is the source identifier and the primary key of the Silver target.

    A NULL loan ID would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.sikacredit_loan
        WHERE loan_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL loan_id detected in bronze.sikacredit_loan.',
        1;
END
GO

/*
    LB-02 — LOAN IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    loan_id is expected to uniquely identify each source transaction.

    Duplicate loan IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            loan_id
        FROM bronze.sikacredit_loan
        GROUP BY loan_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate loan_id detected in bronze.sikacredit_loan.',
        2;
END
GO

/*
    LB-03 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is a foreign key identifier of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.sikacredit_loan
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.sikacredit_loan.',
        3;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — LOAN TIMESTAMP VALIDITY

    ## RULE
    disbursement_timestamp must occur before the current date and must not be null.
    maturity_date must occur after disbursement_timestamp and must not be null.

    ## PURPOSE
    Identify invalid dates.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    skl.disbursement_timestamp
FROM bronze.sikacredit_loan AS skl
WHERE skl.disbursement_timestamp IS NULL
        OR skl.disbursement_timestamp >= CAST(GETDATE() AS DATE);
GO

SELECT
    skl.maturity_date
FROM bronze.sikacredit_loan AS skl
WHERE CAST(skl.maturity_date AS DATETIME2(3)) <= skl.disbursement_timestamp

/*
    DQ-02 — DISBURSEMENT LOCATION PROFILING

    ## PURPOSE
    Identify distinct disbursement location values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. The standardization for this happens in the 
    standardization layer.
*/
SELECT DISTINCT
    TRIM(skl.disbursement_location) AS transaction_location
FROM bronze.sikacredit_loan AS skl
ORDER BY 1;
GO

/*
    DQ-03 — PRINCIPAL AMOUNT VALIDITY

    ## RULE
    The principal amount represents the disbursed amount and the amount cannot:
    be less than or equal to zero;
    be null;

    ## NOTE
    Any null or amount <= 0, shall be transformed to 'unknown'.
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    skl.principal_amount
FROM bronze.sikacredit_loan AS skl
WHERE skl.principal_amount <= 0
        OR skl.principal_amount IS NULL;
GO

/*
    DQ-04 — INTEREST RATE VALIDITY

    ## RULE
    The interest rate represents the rate of return on the loan and it cannot:
    be null;

    ## NOTE
    Any null or amount <= 0, shall be transformed to 'unknown'.
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    skl.interest_rate
FROM bronze.sikacredit_loan AS skl
WHERE skl.principal_amount IS NULL;
GO

/*
    DQ-05 — REMITTANCE CURRENCY PROFILING

    ## PURPOSE
    Identify distinct currency values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. 
*/
SELECT DISTINCT
    skl.currency
FROM bronze.sikacredit_loan AS skl;
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'sikacredit_loan',
    'bronze.sikacredit_loan'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Ananse customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.sikacredit_loan;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES

    TR-01 — Trim and lower_case applicable string attributes.
    TR-02 — Extract the transaction region and town from the transaction_location  
    TR-03 — Join the table to ocb_customer and include the ocb_customer_id column in the final frozen table.
    TR-04 — Preserve the source remittance_id.
    TR-05 — Perform duplicate detection after standardization.

    */
WITH standardized_loan
AS (
    SELECT
        skl.loan_id,
        skl.customer_id,
        skl.disbursement_location,
        SUBSTRING(LOWER(TRIM(skl.disbursement_location)), 1, CHARINDEX('|', LOWER(TRIM(skl.disbursement_location)), 1) - 1)                                           AS disbursement_location_region,
        SUBSTRING(LOWER(TRIM(skl.disbursement_location)), CHARINDEX('|', LOWER(TRIM(skl.disbursement_location)), 1) + 1, LEN(LOWER(TRIM(skl.disbursement_location)))) AS disbursement_location_town,
        skl.principal_amount,
        skl.disbursement_timestamp,
        skl.interest_rate,
        skl.maturity_date,
        LOWER(TRIM(skl.currency))                                                                                                                                     AS loan_currency
    FROM bronze.sikacredit_loan AS skl
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.[sikacredit_loan] (
    loan_id,
    customer_id,
    ocb_customer_id,
    principal_amount,
    disbursement_timestamp,
    disbursement_location_region,
    disbursement_location_town,
    maturity_date,
    interest_rate,
    loan_currency
    )
SELECT
    sl.loan_id,
    sl.customer_id,
    oci.ocb_customer_id,
    sl.principal_amount,
    sl.disbursement_timestamp,
    sl.disbursement_location_region,
    sl.disbursement_location_town,
    sl.maturity_date,
    sl.interest_rate,
    sl.loan_currency
FROM standardized_loan sl
LEFT JOIN silver.ocb_customer_identity oci ON
        sl.customer_id = oci.source_customer_id
            AND oci.source_entity = 'SIKACREDIT';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.sikacredit_loan;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.sikacredit_loan;
GO

/*
    Verify whether every Sikacredit loan can be linked to a Sikacredit customer
*/
SELECT
    sl.loan_id,
    sl.customer_id,
    sl.ocb_customer_id
FROM silver.sikacredit_loan AS sl
LEFT JOIN silver.sikacredit_customer AS sc
    ON sl.customer_id = sc.customer_id
WHERE sc.customer_id IS NULL;

/*
    Verify whether every Sikacredit loan customer has an OCB ID
*/
SELECT
    sl.loan_id,
    sl.customer_id,
    sl.ocb_customer_id AS loan_ocb_customer_id,
    sc.ocb_customer_id AS customer_ocb_customer_id
FROM silver.sikacredit_loan AS sl
INNER JOIN silver.sikacredit_customer AS sc
    ON sl.customer_id = sc.customer_id
WHERE sl.ocb_customer_id <> sc.ocb_customer_id
   OR sl.ocb_customer_id IS NULL
   OR sc.ocb_customer_id IS NULL;
GO

/*
    Verify the loan grain.
    One loan id = One loan record
*/
SELECT
    loan_id,
    COUNT(*) AS row_count
FROM silver.sikacredit_loan
GROUP BY loan_id
HAVING COUNT(*) <> 1;

/*
    =========================================
    SIKACREDIT REPAYMENT.
    =========================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Sikacredit loan data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Detect and resolve potential duplicate customer records.
    7. Load the trusted Silver customer records.
    8. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.[sikacredit_repayment]

    ## TARGET
   silver.[sikacredit_repayment]

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * repayment_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — REPAYMENT IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    repayment_id is the source identifier and the primary key of the Silver target.

    A NULL loan ID would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.sikacredit_repayment
        WHERE loan_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL loan_id detected in bronze.sikacredit_repayment.',
        1;
END
GO

/*
    LB-02 — REPAYMENT IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    repayment_id is expected to uniquely identify each source transaction.

    Duplicate repayment IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            repayment_id
        FROM bronze.sikacredit_repayment
        GROUP BY repayment_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate repayment_id detected in bronze.sikacredit_repayment.',
        2;
END
GO

/*
    LB-03 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    loan_id is a foreign key identifier of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.sikacredit_repayment
        WHERE loan_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL loan_id detected in bronze.sikacredit_repayment.',
        3;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — REPAYMENT AMOUNT VALIDITY

    ## RULE
    The repayment amount represents the repaid amount with respect to the loan and the repayment amount cannot:
    be less than or equal to zero;
    be null;

    ## NOTE
    Any null or amount <= 0, shall be transformed to 'unknown'.
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    skr.repayment_amount
FROM bronze.sikacredit_repayment AS skr
WHERE skr.repayment_amount <= 0
        OR skr.repayment_amount IS NULL;
GO

/*
    DQ-02 — REPAYMENT TIMESTAMP VALIDITY

    ## RULE
    repayment_timestamp must occur before the current date and must not be null.

    ## PURPOSE
    Identify invalid dates.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    skr.repayment_timestamp
FROM bronze.sikacredit_repayment AS skr
WHERE skr.repayment_timestamp IS NULL
        OR skr.repayment_timestamp >= CAST(GETDATE() AS DATETIME2(3));
GO

/*
    DQ-03 — REPAYMENT LOCATION PROFILING

    ## PURPOSE
    Identify distinct repayment location values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. The standardization for this happens in the 
    standardization layer.
*/
SELECT DISTINCT
    TRIM(skr.repayment_location) AS transaction_location
FROM bronze.sikacredit_repayment AS skr
ORDER BY 1;
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'sikacredit_repayment',
    'bronze.sikacredit_repayment'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Ananse customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.sikacredit_repayment;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES

    TR-01 — Trim and lower_case applicable string attributes.
    TR-02 — Extract the repayment region and town from the repayment_location  
    TR-03 — Join the table to ocb_customer and include the ocb_customer_id column in the final frozen table.
    TR-04 — Preserve the source remittance_id.
    TR-05 — Perform duplicate detection after standardization.

    */
WITH standardized_repayment
AS (
    SELECT
        skr.repayment_id,
        skr.loan_id,
        skr.repayment_location,
        SUBSTRING(LOWER(TRIM(skr.repayment_location)), 1, CHARINDEX('|', LOWER(TRIM(skr.repayment_location)), 1) - 1)                                        AS repayment_location_region,
        SUBSTRING(LOWER(TRIM(skr.repayment_location)), CHARINDEX('|', LOWER(TRIM(skr.repayment_location)), 1) + 1, LEN(LOWER(TRIM(skr.repayment_location)))) AS repayment_location_town,
        skr.repayment_amount,
        skr.repayment_timestamp
    FROM bronze.sikacredit_repayment AS skr
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.[sikacredit_repayment] (
    repayment_id,
    loan_id,
    ocb_customer_id,
    repayment_amount,
    repayment_timestamp,
    repayment_location_region,
    repayment_location_town
    )
SELECT
    sr.repayment_id,
    sr.loan_id,
    sl.ocb_customer_id,
    sr.repayment_amount,
    sr.repayment_timestamp,
    sr.repayment_location_region,
    sr.repayment_location_town
FROM standardized_repayment sr
LEFT JOIN silver.sikacredit_loan sl ON
        sr.loan_id = sl.loan_id
LEFT JOIN silver.ocb_customer_identity oci ON
        sl.ocb_customer_id = oci.ocb_customer_id
            AND oci.source_entity = 'SIKACREDIT'
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.sikacredit_repayment;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.sikacredit_repayment;
GO

/*
    Verify whether every repayment has a related loan id
*/
SELECT
    sr.repayment_id,
    sr.loan_id,
    sr.ocb_customer_id
FROM silver.sikacredit_repayment AS sr
LEFT JOIN silver.sikacredit_loan AS sl
    ON sr.loan_id = sl.loan_id
WHERE sl.loan_id IS NULL;
GO

/*
    Verify whether every repayment can be linked to an OCB ID
*/
SELECT
    sr.repayment_id,
    sr.loan_id,
    sr.ocb_customer_id AS repayment_ocb_customer_id,
    sl.ocb_customer_id AS loan_ocb_customer_id
FROM silver.sikacredit_repayment AS sr
INNER JOIN silver.sikacredit_loan AS sl
    ON sr.loan_id = sl.loan_id
WHERE sr.ocb_customer_id <> sl.ocb_customer_id
   OR sr.ocb_customer_id IS NULL
   OR sl.ocb_customer_id IS NULL;
GO

/*
    Verify the repayment grain
*/
SELECT
    repayment_id,
    COUNT(*) AS row_count
FROM silver.sikacredit_repayment
GROUP BY repayment_id
HAVING COUNT(*) <> 1;
GO

/*
    =========================================
    OMAN REMIT REMITTANCES.
    =========================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Oman Remit remittances data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Detect and resolve potential duplicate customer records.
    7. Load the trusted Silver customer records.
    8. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.[oman_remit_remittance]

    ## TARGET
    silver.[oman_remit_remittance]

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * remittance_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — REMITTANCE IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    remittance_id is the source identifier and the primary key of the Silver target.

    A NULL remittance ID would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.oman_remit_remittance
        WHERE remittance_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL transaction_id detected in bronze.oman_remit_remittance.',
        1;
END
GO

/*
    LB-02 — REMITTANCE IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    remittance_id is expected to uniquely identify each source transaction.

    Duplicate remittance IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            remittance_id
        FROM bronze.oman_remit_remittance
        GROUP BY remittance_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate transaction_id detected in bronze.oman_remit_remittance.',
        2;
END
GO

/*
    LB-03 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is a foreign key identifier of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.oman_remit_remittance
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.oman_remit_remittance.',
        3;
END
GO

/*
    LB-04 — COUNTRY IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    country_id is a foreign key identifier in the Silver target.

    A NULL country_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.oman_remit_remittance
        WHERE country_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL country_id detected in bronze.oman_remit_remittance.',
        3;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — REIMTTANCE STATUS PROFILING

    ## PURPOSE
    Identify distinct remittance status values and determine whether standardization is required.
*/
/* QUESTION:
WHAT DOES REJECTED MEAN?? I ASKED THAT WE USE ONLY FAILED AND SUCCESSFUL. YET GENERATOR INCLUDED IT. NOW WE HAVE TO DEFINE IT OR
TRANSFORM IT AS FAILED.
WE COULD MAINTAIN THE REJECTED AND USE IT AS A WATCHLIST. IF YOU HAVE YOUR TRANSACTION REJECTED, THEN MAYBE YOU COULD BE ON THE
ENTITY'S WATCHLIST. SO THAT COULD BE A DERIVED MEAING. BUT ID WANT TO KNOW WHAT YOU THINK
*/
SELECT DISTINCT
    orr.remittance_status
FROM bronze.oman_remit_remittance orr
ORDER BY 1;

/*
    DQ-02 — REMITTANCE TRANSACTION LOCATION PROFILING

    ## PURPOSE
    Identify distinct transaction location values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. The standardization for this happens in the 
    standardization layer.
*/
SELECT DISTINCT
    TRIM(orr.transaction_location) AS transaction_location
FROM bronze.oman_remit_remittance AS orr
ORDER BY 1;
GO

/*
    DQ-03 — REMITTANCE TIMESTAMP VALIDITY

    ## RULE
    remittance_timestamp must occur before the current date and must not be null.

    ## PURPOSE
    Identify future or current-dates.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    orr.remittance_timestamp
FROM bronze.oman_remit_remittance AS orr
WHERE orr.remittance_timestamp IS NULL
        OR orr.remittance_timestamp >= CAST(GETDATE() AS DATE);
GO

/*
    DQ-04 — AMOUNT VALIDITY

    ## RULE
    The amount represents the remittance amount and the amount cannot:
    be less than or equal to zero;
    be null;

    ## NOTE
    Any null or amount <= 0, shall be transformed to 'unknown'.
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    orr.amount
FROM bronze.oman_remit_remittance AS orr
WHERE orr.amount <= 0
        OR orr.amount IS NULL;
GO

/*
    DQ-05 — REMITTANCE CURRENCY PROFILING

    ## PURPOSE
    Identify distinct currency values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. 
*/
SELECT DISTINCT
    orr.currency
FROM bronze.oman_remit_remittance AS orr;
GO

/*
    DQ-06 — REMITTANCE TRANSACTION CHANNEL PROFILING

    ## PURPOSE
    Identify distinct transaction channel values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. The standardization for this happens in the 
    standardization layer.
*/
SELECT DISTINCT
    TRIM(orr.transaction_channel) AS transaction_channel
FROM bronze.oman_remit_remittance AS orr
ORDER BY 1;
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'oman_remit_remittance',
    'bronze.oman_remit_remittance'
    );
GO

/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Ananse customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.oman_remit_remittance;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES

    TR-01 — Map the references to the relative ids
    TR-02 — Trim and lower_case applicable string attributes.
    TR-03 — Extract the transaction region and town from the transaction_location  
    TR-04 — Join the table to ocb_customer and include the ocb_customer_id column in the final frozen table.
    TR-05 — Preserve the source remittance_id.
    TR-06 — Perform duplicate detection after standardization.

    NOTE:
    'Ghana' exists in the country id (as an origin country)
    Meaning Ghana is also a sender despite being the host country where this sandbox analysis is taking place
    This is not an error and was intentionally engineered so as to enrich remit-related analysis.
    Thus, there is the need to eliminate ambiguity from the transaction location and use a case when to derive a 
    new column-remittance type, to distinguish both a 'send' and 'receive' type of remit.
    */
WITH standardized_remittance
AS (
    SELECT
        orr.remittance_id,
        orr.customer_id,
        LOWER(TRIM(rc.country_name))                                                                                                                               AS remittance_origin_country,
        orr.transaction_location,
        SUBSTRING(LOWER(TRIM(orr.transaction_location)), 1, CHARINDEX('|', LOWER(TRIM(orr.transaction_location)), 1) - 1)                                          AS remittance_location_region,
        SUBSTRING(LOWER(TRIM(orr.transaction_location)), CHARINDEX('|', LOWER(TRIM(orr.transaction_location)), 1) + 1, LEN(LOWER(TRIM(orr.transaction_location)))) AS remittance_location_town,
        LOWER(TRIM(rtc.transaction_channel_name))                                                                                                                  AS remittance_transaction_channel,
        LOWER(TRIM(orr.remittance_status))                                                                                                                         AS remittance_status,
        orr.remittance_timestamp,
        orr.amount                                                                                                                                                 AS remittance_amount,
        LOWER(TRIM(orr.currency))                                                                                                                                  AS remittance_currency
    FROM bronze.oman_remit_remittance AS orr
    LEFT JOIN bronze.ref_country rc ON
            orr.country_id = rc.country_id
    LEFT JOIN bronze.ref_transaction_channel rtc ON
            orr.transaction_channel = rtc.transaction_channel_code
    ),
remittance_type_derivation
AS (
    SELECT
        sr.remittance_id,
        sr.customer_id,
        sr.remittance_origin_country,
        sr.remittance_location_region,
        sr.remittance_location_town,
        sr.remittance_transaction_channel,
        CASE sr.remittance_origin_country
            WHEN 'ghana'
                THEN 'remittance_sent'
            ELSE 'remittance_received'
            END AS remittance_type,
        sr.remittance_status,
        sr.remittance_timestamp,
        sr.remittance_amount,
        sr.remittance_currency
    FROM standardized_remittance sr
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.oman_remit_remittance (
    remittance_id,
    customer_id,
    ocb_customer_id,
    remittance_origin_country,
    remittance_location_region,
    remittance_location_town,
    remittance_transaction_channel,
    remittance_type,
    remittance_status,
    remittance_timestamp,
    remittance_amount,
    remittance_currency
    )
SELECT
    rtd.remittance_id,
    rtd.customer_id,
    oci.ocb_customer_id,
    rtd.remittance_origin_country,
    rtd.remittance_location_region,
    rtd.remittance_location_town,
    rtd.remittance_transaction_channel,
    rtd.remittance_type,
    rtd.remittance_status,
    rtd.remittance_timestamp,
    rtd.remittance_amount,
    rtd.remittance_currency
FROM remittance_type_derivation rtd
LEFT JOIN silver.ocb_customer_identity oci ON
        rtd.customer_id = oci.source_customer_id
            AND oci.source_entity = 'OMAN_REMIT';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.oman_remit_remittance;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.ananse_customer;
GO

/*
    Verify whether every remittance can be linked to every Oman Remit customer
*/
SELECT
    orr.remittance_id,
    orr.customer_id,
    orr.ocb_customer_id
FROM silver.oman_remit_remittance AS orr
LEFT JOIN silver.oman_remit_customer AS orc
    ON orr.customer_id = orc.customer_id
WHERE orc.customer_id IS NULL;
GO

/*
    Verify whether every remittance can be linked to an OCB ID
*/
SELECT
    orr.remittance_id,
    orr.customer_id,
    orr.ocb_customer_id AS remittance_ocb_customer_id,
    orc.ocb_customer_id AS customer_ocb_customer_id
FROM silver.oman_remit_remittance AS orr
INNER JOIN silver.oman_remit_customer AS orc
    ON orr.customer_id = orc.customer_id
WHERE orr.ocb_customer_id <> orc.ocb_customer_id
   OR orr.ocb_customer_id IS NULL
   OR orc.ocb_customer_id IS NULL;
GO

/*
    Verify whether the remittance id has more than one remittance grain

*/
SELECT
    remittance_id,
    COUNT(*) AS row_count
FROM silver.oman_remit_remittance
GROUP BY remittance_id
HAVING COUNT(*) <> 1;
GO

/*
    Verify whether the derived column remittance_type has any validity issues
*/

SELECT
    remittance_id,
    remittance_origin_country,
    remittance_type
FROM silver.oman_remit_remittance
WHERE remittance_type IS NULL
   OR remittance_type NOT IN ('remittance_sent', 'remittance_received');
GO
/*
    =========================================
    ANANSE TRANSACTION
    =========================================
*/
/*
    ## PURPOSE

    Transform and standardize Bronze Ananse transaction data into the Silver / Trusted layer.

    ## PROCESS
    1. Perform load-blocking structural validation.
    2. Perform data-quality and profiling checks.
    3. Register the Silver entity load in silver.load_batch.
    4. Perform a full refresh of the Silver target.
    5. Standardize source attributes.
    6. Derive the shared Ananse customer identity key.
    7. Detect and resolve potential duplicate transaction records.
    8. Load the trusted Silver transaction records.
    9. Verify the resulting Silver dataset.

    ## SOURCE
    bronze.ananse_transaction

    ## TARGET
    silver.ananse_transaction

    ## LOAD STRATEGY
    Full refresh from the frozen Bronze dataset.

    ## PROVENANCE
    * transaction_id preserves source-record identity.
    * silver.load_batch records the Silver entity load event.
  ====================================================================
*/
/*  ================================================================
    LAYER 1 — LOAD-BLOCKING (LB) STRUCTURAL VALIDATION
    ================================================================ 
*/
/*
    LB-01 — TRANSACTION IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    transaction_id is the source identifier and the primary key of the Silver target.

    A NULL transaction_id would prevent reliable source traceability and violate the Silver table primary-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.ananse_transaction
        WHERE transaction_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL transaction_id detected in bronze.ananse_transaction.',
        1;
END
GO

/*
    LB-02 — TRANSACTION IDENTIFIER MUST BE UNIQUE

    ## RATIONALE
    transaction_id is expected to uniquely identify each source transaction.

    Duplicate transaction IDs would compromise source-level uniqueness and conflict with the Silver table primary key.
*/
IF EXISTS (
        SELECT
            transaction_id
        FROM bronze.ananse_transaction
        GROUP BY transaction_id
        HAVING COUNT(*) > 1
        )
BEGIN
        ;

    THROW 50002,
        'Silver load aborted: duplicate transaction_id detected in bronze.ananse_transaction.',
        2;
END
GO

/*
    LB-03 — CUSTOMER IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    customer_id is a foreign key identifier of the Silver target.

    A NULL customer_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.ananse_transaction
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL customer_id detected in bronze.ananse_transaction.',
        3;
END
GO

/*
    LB-04 — WALLET IDENTIFIER MUST NOT BE NULL

    ## RATIONALE
    wallet_id is a foreign key identifier the Silver target.

    A NULL wallet_id would prevent reliable source traceability and violate the Silver table foreign-key requirement.
*/
IF EXISTS (
        SELECT
            1
        FROM bronze.ananse_transaction
        WHERE customer_id IS NULL
        )
BEGIN
        ;

    THROW 50001,
        'Silver load aborted: NULL wallet_id detected in bronze.ananse_transaction.',
        3;
END
GO

/* 
    ================================================================
    LAYER 2 — DATA QUALITY AND PROFILING
    ================================================================ 
 */
/*
    DQ-01 — SHARED DEVICES PROFILING

    ## PURPOSE
    Identify devices associated with more than one customer.

    ## NOTE
    In this simulated economy, a shared device is not automatically considered invalid. Multiple individuals may legitimately
    share a device.
*/
SELECT
    AT.device_id,
    COUNT(DISTINCT AT.customer_id)                         AS distinct_customer_count,
    STRING_AGG(CAST(AT.customer_id AS VARCHAR(MAX)), ', ') AS associated_customer_ids
FROM bronze.ananse_transaction AS AT
GROUP BY AT.device_id
HAVING COUNT(DISTINCT AT.customer_id) > 1;
GO

/*
    DQ-02 — TRANSACTION LOCATION PROFILING

    ## PURPOSE
    Identify distinct transaction location values and determine whether standardization is required.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load. The standardization for this happens in the 
    standardization layer.
*/
SELECT DISTINCT
    TRIM(AT.transaction_location) AS transaction_location
FROM bronze.ananse_transaction AS AT
ORDER BY 1;
GO

/*
    DQ-03 — TRANSACTION TIMESTAMP VALIDITY

    ## RULE
    transaction_timestamp must occur before the current date.

    ## PURPOSE
    Identify future or current-date dates of birth.

    ## NOTE
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    AT.customer_id,
    AT.transaction_timestamp
FROM bronze.ananse_transaction AS AT
WHERE AT.transaction_timestamp >= CAST(GETDATE() AS DATE);
GO

/*
    DQ-04 — AMOUNT VALIDITY

    ## RULE
    The amount represents transaction amount and the amount cannot:
    be less than or equal to zero
    be null

    ## NOTE
    Any null or amount <= 0, shall be filtered out.
    This is currently a data-quality check and does not block the Silver load.
*/
SELECT
    AT.amount
FROM bronze.ananse_transaction AS AT
WHERE AT.amount <= 0
        OR AT.amount IS NULL;
GO

/* 
    ================================================================
    LAYER 3 — REGISTER SILVER LOAD
    ================================================================ 
*/
/*
    LOAD-BATCH REGISTRATION
    A new record is appended to silver.load_batch for this entity load.

    The table maintains historical load events and must therefore not be truncated as part of the Silver full-refresh process.
*/
INSERT INTO silver.load_batch (
    source_entity,
    source_file_name
    )
VALUES (
    'ananse_transaction',
    'bronze.ananse_transaction'
    );
GO

/*
    Load into silver.ananse_wallet
*/
INSERT INTO silver.ananse_wallet (
    wallet_id,
    customer_id,
    ocb_customer_id
    )
SELECT
    aw.wallet_id,
    aw.customer_id,
    oci.ocb_customer_id
FROM bronze.ananse_wallet AS aw
LEFT JOIN silver.ocb_customer_identity AS oci ON
        aw.customer_id = oci.source_customer_id
            AND oci.source_entity = 'ANANSE';
GO

/*
    Verify whether:
        Every Bronze wallet has exactly one valid Silver Ananse customer.
        Every Bronze wallet gets loaded exactly once into Silver.
*/
SELECT
    aw.wallet_id,
    COUNT(ac.customer_id) AS customer_matches
FROM bronze.ananse_wallet AS aw
LEFT JOIN silver.ananse_customer AS ac
    ON aw.customer_id = ac.customer_id
GROUP BY aw.wallet_id
HAVING COUNT(ac.customer_id) <> 1;
GO


SELECT
    aw.wallet_id
FROM bronze.ananse_wallet AS aw
LEFT JOIN silver.ananse_wallet AS saw
    ON aw.wallet_id = saw.wallet_id
WHERE saw.wallet_id IS NULL;
GO

/*
    Verify whether any orphan values exist in reference tables
*/
-- transaction_type
SELECT
    at.transaction_id,
    at.transaction_type_id
FROM bronze.ananse_transaction AS at
LEFT JOIN bronze.ref_transaction_type AS rtt
    ON at.transaction_type_id = rtt.transaction_type_id
WHERE rtt.transaction_type_id IS NULL;
GO

-- transaction_channel
SELECT
    at.transaction_id,
    at.transaction_channel_id
FROM bronze.ananse_transaction AS at
LEFT JOIN bronze.ref_transaction_channel AS rtc
    ON at.transaction_channel_id = rtc.transaction_channel_id
WHERE rtc.transaction_channel_id IS NULL;
GO

-- transaction_status
SELECT
    at.transaction_id,
    at.transaction_status_id
FROM bronze.ananse_transaction AS at
LEFT JOIN bronze.ref_transaction_status AS rts
    ON at.transaction_status_id = rts.transaction_status_id
WHERE rts.transaction_status_id IS NULL;
GO

-- transaction_currency
SELECT
    at.transaction_id,
    at.currency_id
FROM bronze.ananse_transaction AS at
LEFT JOIN bronze.ref_currency AS rc
    ON at.currency_id = rc.currency_id
WHERE rc.currency_id IS NULL;
GO


/* 
    ================================================================
    LAYER 4 — SILVER FULL REFRESH
    ================================================================
*/
/*
    FULL REFRESH STRATEGY
    The Bronze dataset is frozen for the current project execution.
    The Silver Ananse customer table is therefore rebuilt from the Bronze baseline.
*/
DELETE silver.ananse_transaction;
GO

/* 
    ================================================================
    LAYER 5 — STANDARDIZATION AND TRANSFORMATION
    ================================================================
*/
/*
    TRANSFORMATION RULES

    TR-01 — Map the references to the relative ids
    TR-01 — Trim applicable string attributes.
    TR-02 — Preserve the source transaction_id.
    TR-03 — Derive customer_key from transaction_id.
    TR-04 — Perform duplicate detection after standardization.
*/
WITH standardized_transactions
AS (
    SELECT
        AT.transaction_id,
        AT.customer_id,
        AT.wallet_id,
        LOWER(TRIM(rtt.transaction_type_name))                                                                                                                  AS transaction_type,
        SUBSTRING(LOWER(TRIM(AT.transaction_location)), 1, CHARINDEX('|', LOWER(TRIM(AT.transaction_location)), 1) - 1)                                         AS transaction_location_region,
        SUBSTRING(LOWER(TRIM(AT.transaction_location)), CHARINDEX('|', LOWER(TRIM(AT.transaction_location)), 1) + 1, LEN(LOWER(TRIM(AT.transaction_location)))) AS transaction_location_town,
        LOWER(TRIM(rtc.transaction_channel_name))                                                                                                               AS transaction_channel,
        LOWER(TRIM(rts.transaction_status_name))                                                                                                                AS transaction_status,
        AT.transaction_timestamp,
        AT.device_id,
        AT.amount                                                                                                                                               AS transaction_amount,
        LOWER(TRIM(rc.currency_name))                                                                                                                           AS transaction_currency
    FROM bronze.ananse_transaction AS AT
    LEFT JOIN bronze.ref_transaction_type AS rtt ON
            AT.transaction_type_id = rtt.transaction_type_id
    LEFT JOIN bronze.ref_transaction_channel AS rtc ON
            AT.transaction_channel_id = rtc.transaction_channel_id
    LEFT JOIN bronze.ref_transaction_status AS rts ON
            AT.transaction_status_id = rts.transaction_status_id
    LEFT JOIN bronze.ref_currency AS rc ON
            AT.currency_id = rc.currency_id
    LEFT JOIN bronze.ananse_wallet aw ON
            AT.customer_id = aw.customer_id
                AND AT.wallet_id = aw.wallet_id
    )
/* 
    ================================================================
    LAYER 6 — LOAD TRUSTED SILVER DATA
    ================================================================
*/
INSERT INTO silver.ananse_transaction (
    transaction_id,
    customer_id,
    ocb_customer_id,
    wallet_id,
    transaction_type,
    transaction_channel,
    transaction_timestamp,
    transaction_amount,
    transaction_status,
    transaction_location_region,
    transaction_location_town,
    device_id,
    transaction_currency
    )
SELECT
    st.transaction_id,
    st.customer_id,
    oci.ocb_customer_id,
    st.wallet_id,
    st.transaction_type,
    st.transaction_channel,
    st.transaction_timestamp,
    st.transaction_amount,
    st.transaction_status,
    st.transaction_location_region,
    st.transaction_location_town,
    st.device_id,
    st.transaction_currency
FROM standardized_transactions st
LEFT JOIN silver.ocb_customer_identity oci ON
        st.customer_id = oci.source_customer_id
            AND oci.source_entity = 'ANANSE';
GO

/* 
    ================================================================
    LAYER 7 — POST-LOAD VERIFICATION
    ================================================================ 
*/
/*
    ## VERIFY SILVER DATA
*/
SELECT
    *
FROM silver.ananse_transaction;
GO

/*
    ## VERIFY SILVER ROW COUNT
*/
SELECT
    COUNT(*) AS silver_customer_count
FROM silver.ananse_transaction;
GO

/*
    Verify whether every Bronze transaction customer resolves to exactly one OCB identity.
*/
SELECT
    at.customer_id,
    COUNT(DISTINCT oci.ocb_customer_id) AS identity_matches
FROM bronze.ananse_transaction AS at
LEFT JOIN silver.ocb_customer_identity AS oci
    ON at.customer_id = oci.source_customer_id
    AND oci.source_entity = 'ANANSE'
GROUP BY
    at.customer_id
HAVING COUNT(DISTINCT oci.ocb_customer_id) <> 1;
GO

/*
    Verify whether every customer_id appearing in Ananse transactions has a corresponding record in silver.ananse_customer
*/
SELECT
    at.customer_id
FROM bronze.ananse_transaction AS at
LEFT JOIN silver.ananse_customer AS ac
    ON at.customer_id = ac.customer_id
WHERE ac.customer_id IS NULL
GROUP BY at.customer_id;
GO


/*
    Verify whether every wallet referenced by an Ananse transaction exists in silver.ananse_wallet
*/

SELECT
    at.wallet_id
FROM bronze.ananse_transaction AS at
LEFT JOIN silver.ananse_wallet AS aw
    ON at.wallet_id = aw.wallet_id
WHERE aw.wallet_id IS NULL
GROUP BY at.wallet_id;
GO

/*
    Verify whether records referenced by an Ananse transaction can be mapped to its relative wallet, ocb_customer_id
*/
SELECT
    at.transaction_id,
    at.customer_id,
    at.wallet_id,
    at.ocb_customer_id
FROM silver.ananse_transaction AS at
LEFT JOIN silver.ananse_wallet AS aw
    ON at.wallet_id = aw.wallet_id
    AND at.ocb_customer_id = aw.ocb_customer_id
    AND at.customer_id = aw.customer_id
WHERE aw.wallet_id IS NULL;
GO

/*
    Verify whether Ananse transaction grain.
    One transaction_id = exactly one Silver transaction row.
*/
SELECT
    transaction_id,
    COUNT(*) AS row_count
FROM silver.ananse_transaction
GROUP BY transaction_id
HAVING COUNT(*) <> 1;
GO


/*
============================================================================================================================
REJECTED STATUS EXPLORATION FOR OMAN_REMIT AND ANANSE TRANSACTIONS
============================================================================================================================
*/
SELECT
    'ANANSE' AS source_entity,
    transaction_status AS status,
    COUNT(*) AS transaction_count
FROM silver.ananse_transaction
GROUP BY transaction_status

UNION ALL

SELECT
    'OMAN_REMIT' AS source_entity,
    remittance_status AS status,
    COUNT(*) AS transaction_count
FROM silver.oman_remit_remittance
GROUP BY remittance_status
ORDER BY
    source_entity,
    transaction_count DESC;














