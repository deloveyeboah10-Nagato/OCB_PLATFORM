USE [ocb_platform];
GO

CREATE
        OR

ALTER PROCEDURE dbo.silver_transformations_full_load
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @load_start_time DATETIME2(7) = SYSDATETIME();
    DECLARE @load_end_time DATETIME2(7);
    DECLARE @load_duration_seconds DECIMAL(18, 3);

    PRINT '========================================================================================================================';
    PRINT 'OCB PLATFORM v1.0.0 — SILVER TRANSFORMATIONS FULL LOAD';
    PRINT '========================================================================================================================';
    PRINT 'Silver full load started: ' + CONVERT(VARCHAR(30), @load_start_time, 121);

    BEGIN TRY
        BEGIN TRANSACTION;

        /*========================================================================================================================*

            OCB PLATFORM v1.0.0

            WP-5.3 — SILVER TRANSFORMATIONS FULL LOAD

            Purpose:
                Transform and load the validated Bronze source data into the Silver
                trusted layer.

            Load strategy:
                Full refresh from the frozen Bronze dataset.

            Transaction strategy:
                The complete Silver refresh executes as one atomic transaction.
                Any load-blocking failure or SQL error causes the entire refresh to
                roll back.

            Load-batch strategy:
                silver.load_batch records a successful Silver entity load only after
                the corresponding Silver target INSERT completes successfully.

            Dependency order:

                OCB CUSTOMER
                    ↓
                OCB CUSTOMER IDENTITY
                    ↓
                ANANSE CUSTOMER
                    ↓
                ANANSE WALLET
                    ↓
                ANANSE TRANSACTION
                    ↓
                SIKACREDIT CUSTOMER
                    ↓
                SIKACREDIT LOAN
                    ↓
                SIKACREDIT REPAYMENT
                    ↓
                OMAN REMIT CUSTOMER
                    ↓
                OMAN REMIT REMITTANCE

            Source records are preserved in Silver.
            Identity resolution consolidates identities through ocb_customer_id;
            it does not remove valid source-system records.

        *========================================================================================================================*/
        /*========================================================================================================================
            1. OCB CUSTOMER
        ========================================================================================================================*/
        /*
            PURPOSE

            Resolve source customer identities across ANANSE, SIKACREDIT and
            OMAN_REMIT and populate the canonical OCB customer entity.

            Identity definition:

                first_name
                last_name
                date_of_birth
                phone_number
                email

            cross_domain_id is retained as source-level identity evidence only.
            It is not part of the canonical identity definition.

            flag = 1 identifies the most recently created source record within
            each resolved identity group and is used to populate ocb_customer.

            All source records remain valid and are retained in the identity bridge.
        */
        /*------------------------------------------------------------------------------------------------------------------------
            OCB CUSTOMER — LOAD-BLOCKING VALIDATION
        ------------------------------------------------------------------------------------------------------------------------*/
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
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.ananse_customer
                GROUP BY customer_id
                HAVING COUNT(*) > 1
                )
        BEGIN
                ;

            THROW 50002,
                'Silver load aborted: duplicate customer_id detected in bronze.ananse_customer.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.sikacredit_customer
                WHERE customer_id IS NULL
                )
        BEGIN
                ;

            THROW 50003,
                'Silver load aborted: NULL customer_id detected in bronze.sikacredit_customer.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.sikacredit_customer
                GROUP BY customer_id
                HAVING COUNT(*) > 1
                )
        BEGIN
                ;

            THROW 50004,
                'Silver load aborted: duplicate customer_id detected in bronze.sikacredit_customer.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.oman_remit_customer
                WHERE customer_id IS NULL
                )
        BEGIN
                ;

            THROW 50005,
                'Silver load aborted: NULL customer_id detected in bronze.oman_remit_customer.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.oman_remit_customer
                GROUP BY customer_id
                HAVING COUNT(*) > 1
                )
        BEGIN
                ;

            THROW 50006,
                'Silver load aborted: duplicate customer_id detected in bronze.oman_remit_customer.',
                1;
        END;

        /*------------------------------------------------------------------------------------------------------------------------
            OCB CUSTOMER — REFRESH
        ------------------------------------------------------------------------------------------------------------------------*/
        DELETE
        FROM silver.ocb_customer;

        /*------------------------------------------------------------------------------------------------------------------------
            OCB CUSTOMER — STANDARDIZATION AND IDENTITY RESOLUTION
        ------------------------------------------------------------------------------------------------------------------------*/
        /*
            The identity grouping is based on the standardized identity attributes.
            The latest created source record is assigned flag = 1.

            flag is a ranking attribute only.
            Records with flag > 1 are not deleted.
        */
        WITH unified_customers
        AS (
            SELECT
                'ANANSE'                                                AS source_entity,
                TRIM(customer_id)                                       AS customer_id,
                SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))) AS cross_domain_id,
                LOWER(TRIM(first_name))                                 AS first_name,
                LOWER(TRIM(last_name))                                  AS last_name,
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
                SUBSTRING(TRIM(customer_id), 4, LEN(TRIM(customer_id))),
                LOWER(TRIM(first_name)),
                LOWER(TRIM(last_name)),
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
            first_name,
            last_name,
            date_of_birth,
            phone_number,
            email
        FROM ranked_customers
        WHERE flag = 1;

        /*------------------------------------------------------------------------------------------------------------------------
            OCB CUSTOMER — SUCCESSFUL LOAD REGISTRATION
        ------------------------------------------------------------------------------------------------------------------------*/
        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'ocb_customer',
            'bronze.ananse_customer; bronze.sikacredit_customer; bronze.oman_remit_customer'
            );

        /*========================================================================================================================
            2. OCB CUSTOMER IDENTITY
        ========================================================================================================================*/
        DELETE
        FROM silver.ocb_customer_identity;

        INSERT INTO silver.ocb_customer_identity (
            source_entity,
            source_customer_id,
            cross_domain_id,
            ocb_customer_id
            )
        SELECT
            *
        FROM silver.ocb_customer_identity_resolved;

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'ocb_customer_identity',
            'bronze.ananse_customer; bronze.sikacredit_customer; bronze.oman_remit_customer'
            );

        /*========================================================================================================================
            3. ANANSE CUSTOMER
        ========================================================================================================================*/
        DELETE
        FROM silver.ananse_customer;

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
            )
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
            sc.customer_id,
            oci.ocb_customer_id,
            sc.first_name,
            sc.last_name,
            sc.date_of_birth,
            sc.nationality,
            sc.occupation,
            sc.phone_number,
            sc.email,
            sc.created_at
        FROM standardized_customers AS sc
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                sc.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'ANANSE';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_customer',
            'bronze.ananse_customer'
            );

        /*========================================================================================================================
            4. ANANSE WALLET
        ========================================================================================================================*/
        DELETE
        FROM silver.ananse_wallet;

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

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_wallet',
            'bronze.ananse_wallet'
            );

        /*========================================================================================================================
            5. ANANSE TRANSACTION
        ========================================================================================================================*/
        /*
            LB-01 — TRANSACTION IDENTIFIER MUST NOT BE NULL
            LB-02 — TRANSACTION IDENTIFIER MUST BE UNIQUE
            LB-03 — CUSTOMER IDENTIFIER MUST NOT BE NULL
            LB-04 — WALLET IDENTIFIER MUST NOT BE NULL
        */
        IF EXISTS (
                SELECT
                    1
                FROM bronze.ananse_transaction
                WHERE transaction_id IS NULL
                )
        BEGIN
                ;

            THROW 50007,
                'Silver load aborted: NULL transaction_id detected in bronze.ananse_transaction.',
                1;
        END;

        IF EXISTS (
                SELECT
                    transaction_id
                FROM bronze.ananse_transaction
                GROUP BY transaction_id
                HAVING COUNT(*) > 1
                )
        BEGIN
                ;

            THROW 50008,
                'Silver load aborted: duplicate transaction_id detected in bronze.ananse_transaction.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.ananse_transaction
                WHERE customer_id IS NULL
                )
        BEGIN
                ;

            THROW 50009,
                'Silver load aborted: NULL customer_id detected in bronze.ananse_transaction.',
                1;
        END;

        IF EXISTS (
                SELECT
                    1
                FROM bronze.ananse_transaction
                WHERE wallet_id IS NULL
                )
        BEGIN
                ;

            THROW 50010,
                'Silver load aborted: NULL wallet_id detected in bronze.ananse_transaction.',
                1;
        END;

        DELETE
        FROM silver.ananse_transaction;

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
            )
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
        FROM standardized_transactions AS st
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                st.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'ANANSE';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'ananse_transaction',
            'bronze.ananse_transaction'
            );

        /*========================================================================================================================
            6. SIKACREDIT CUSTOMER
        ========================================================================================================================*/
        DELETE
        FROM silver.sikacredit_customer;

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
            )
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
            sc.customer_id,
            oci.ocb_customer_id,
            sc.first_name,
            sc.last_name,
            sc.date_of_birth,
            sc.nationality,
            sc.occupation,
            sc.phone_number,
            sc.email,
            sc.created_at
        FROM standardized_customers AS sc
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                sc.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'SIKACREDIT';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_customer',
            'bronze.sikacredit_customer'
            );

        /*========================================================================================================================
            7. SIKACREDIT LOAN
        ========================================================================================================================*/
        DELETE
        FROM silver.sikacredit_loan;

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
        INSERT INTO silver.sikacredit_loan (
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
        FROM standardized_loan AS sl
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                sl.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'SIKACREDIT';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_loan',
            'bronze.sikacredit_loan'
            );

        /*========================================================================================================================
            8. SIKACREDIT REPAYMENT
        ========================================================================================================================*/
        DELETE
        FROM silver.sikacredit_repayment;

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
        INSERT INTO silver.sikacredit_repayment (
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
        FROM standardized_repayment AS sr
        LEFT JOIN silver.sikacredit_loan AS sl ON
                sr.loan_id = sl.loan_id;

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'sikacredit_repayment',
            'bronze.sikacredit_repayment'
            );

        /*========================================================================================================================
            9. OMAN REMIT CUSTOMER
        ========================================================================================================================*/
        DELETE
        FROM silver.oman_remit_customer;

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
            )
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
            oc.customer_id,
            oci.ocb_customer_id,
            oc.first_name,
            oc.last_name,
            oc.date_of_birth,
            oc.nationality,
            oc.occupation,
            oc.phone_number,
            oc.email,
            oc.created_at
        FROM standardized_customers AS oc
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                oc.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'OMAN_REMIT';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'oman_remit_customer',
            'bronze.oman_remit_customer'
            );

        /*========================================================================================================================
            10. OMAN REMIT REMITTANCE
        ========================================================================================================================*/
        DELETE
        FROM silver.oman_remit_remittance;

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
            LEFT JOIN bronze.ref_country AS rc ON
                    orr.country_id = rc.country_id
            LEFT JOIN bronze.ref_transaction_channel AS rtc ON
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
            FROM standardized_remittance AS sr
            )
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
        FROM remittance_type_derivation AS rtd
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                rtd.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'OMAN_REMIT';

        INSERT INTO silver.load_batch (
            source_entity,
            source_file_name
            )
        VALUES (
            'oman_remit_remittance',
            'bronze.oman_remit_remittance'
            );

        /*========================================================================================================================
            SILVER FULL LOAD COMPLETE
        ========================================================================================================================*/
        COMMIT TRANSACTION;

        SET @load_end_time = SYSDATETIME();
        SET @load_duration_seconds = DATEDIFF_BIG(MICROSECOND, @load_start_time, @load_end_time) / 1000000.0;

        PRINT 'Silver full load completed successfully: ' + CONVERT(VARCHAR(30), @load_end_time, 121);
        PRINT 'Silver full load duration: ' + CAST(@load_duration_seconds AS VARCHAR(30)) + ' seconds';
        PRINT '========================================================================================================================';
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;;

        SET @load_end_time = SYSDATETIME();
        SET @load_duration_seconds = DATEDIFF_BIG(MICROSECOND, @load_start_time, @load_end_time) / 1000000.0;

        PRINT 'SILVER FULL LOAD FAILED';
        PRINT 'Failure time: ' + CONVERT(VARCHAR(30), @load_end_time, 121);
        PRINT 'Elapsed time before failure: ' + CAST(@load_duration_seconds AS VARCHAR(30)) + ' seconds';

        THROW;
    END CATCH;
END;
GO

/*========================================================================================================================*

    OCB PLATFORM v1.0.0

    WP-5.3 — SILVER TRANSFORMATION VERIFICATION

    Purpose:
        Verify that the completed Silver full load produced the intended
        trusted-layer result from the validated Bronze dataset.

    Verification scope:
        1. Bronze → Silver row-count reconciliation
        2. OCB identity resolution
        3. Silver referential integrity
        4. Transformation sanity
        5. Silver load-batch registration

    Principle:
        Bronze structural validation has already established source-data
        validity. Silver verification therefore focuses on transformation
        correctness, identity mapping, relationships, and completeness.

    Result convention:
        PASS = verification condition is satisfied.
        FAIL = verification condition is not satisfied.

*========================================================================================================================*/
CREATE
        OR

ALTER PROCEDURE dbo.silver_transformations_full_load_verification
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '========================================================================================================================';
    PRINT 'SILVER TRANSFORMATION VERIFICATION STARTED';
    PRINT '========================================================================================================================';
    /*========================================================================================================================*
        1. ROW-COUNT RECONCILIATION
    *========================================================================================================================*/
    PRINT '1. ROW-COUNT RECONCILIATION';

    SELECT
        'ananse_customer' AS entity,
        (
            SELECT
                COUNT(*)
            FROM bronze.ananse_customer
            ) AS bronze_count,
        (
            SELECT
                COUNT(*)
            FROM silver.ananse_customer
            ) AS silver_count,
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.ananse_customer
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.ananse_customer
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    
    UNION ALL
    
    SELECT
        'ananse_wallet',
        (
            SELECT
                COUNT(*)
            FROM bronze.ananse_wallet
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.ananse_wallet
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.ananse_wallet
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.ananse_wallet
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'ananse_transaction',
        (
            SELECT
                COUNT(*)
            FROM bronze.ananse_transaction
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.ananse_transaction
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.ananse_transaction
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.ananse_transaction
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'sikacredit_customer',
        (
            SELECT
                COUNT(*)
            FROM bronze.sikacredit_customer
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.sikacredit_customer
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.sikacredit_customer
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.sikacredit_customer
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'sikacredit_loan',
        (
            SELECT
                COUNT(*)
            FROM bronze.sikacredit_loan
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.sikacredit_loan
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.sikacredit_loan
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.sikacredit_loan
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'sikacredit_repayment',
        (
            SELECT
                COUNT(*)
            FROM bronze.sikacredit_repayment
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.sikacredit_repayment
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.sikacredit_repayment
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.sikacredit_repayment
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'oman_remit_customer',
        (
            SELECT
                COUNT(*)
            FROM bronze.oman_remit_customer
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.oman_remit_customer
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.oman_remit_customer
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.oman_remit_customer
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END
    
    UNION ALL
    
    SELECT
        'oman_remit_remittance',
        (
            SELECT
                COUNT(*)
            FROM bronze.oman_remit_remittance
            ),
        (
            SELECT
                COUNT(*)
            FROM silver.oman_remit_remittance
            ),
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM bronze.oman_remit_remittance
                    ) = (
                    SELECT
                        COUNT(*)
                    FROM silver.oman_remit_remittance
                    )
                THEN 'PASS'
            ELSE 'FAIL'
            END;

    /*========================================================================================================================*
        2. IDENTITY RESOLUTION
    *========================================================================================================================*/
    PRINT '2. IDENTITY RESOLUTION';

    SELECT
        'Source customers without OCB identity' AS verification,
        COUNT(*)                                AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM (
        SELECT
            ac.customer_id
        FROM silver.ananse_customer AS ac
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                ac.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'ANANSE'
        WHERE oci.ocb_customer_id IS NULL
        
        UNION ALL
        
        SELECT
            sc.customer_id
        FROM silver.sikacredit_customer AS sc
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                sc.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'SIKACREDIT'
        WHERE oci.ocb_customer_id IS NULL
        
        UNION ALL
        
        SELECT
            oc.customer_id
        FROM silver.oman_remit_customer AS oc
        LEFT JOIN silver.ocb_customer_identity AS oci ON
                oc.customer_id = oci.source_customer_id
                    AND oci.source_entity = 'OMAN_REMIT'
        WHERE oci.ocb_customer_id IS NULL
        ) AS unresolved;

    SELECT
        'Duplicate source identity mappings' AS verification,
        COUNT(*)                             AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM (
        SELECT
            source_entity,
            source_customer_id
        FROM silver.ocb_customer_identity
        GROUP BY source_entity,
            source_customer_id
        HAVING COUNT(*) > 1
        ) AS duplicates;

    /*========================================================================================================================*
        3. SILVER REFERENTIAL INTEGRITY
    *========================================================================================================================*/
    PRINT '3. SILVER REFERENTIAL INTEGRITY';

    SELECT
        'Ananse transactions without customer' AS verification,
        COUNT(*)                               AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.ananse_transaction AS AT
    LEFT JOIN silver.ananse_customer AS ac ON
            AT.customer_id = ac.customer_id
    WHERE ac.customer_id IS NULL;

    SELECT
        'Ananse transactions without wallet' AS verification,
        COUNT(*)                             AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.ananse_transaction AS AT
    LEFT JOIN silver.ananse_wallet AS aw ON
            AT.wallet_id = aw.wallet_id
    WHERE aw.wallet_id IS NULL;

    SELECT
        'SikaCredit loans without customer' AS verification,
        COUNT(*)                            AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.sikacredit_loan AS sl
    LEFT JOIN silver.sikacredit_customer AS sc ON
            sl.customer_id = sc.customer_id
    WHERE sc.customer_id IS NULL;

    SELECT
        'SikaCredit repayments without loan' AS verification,
        COUNT(*)                             AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.sikacredit_repayment AS sr
    LEFT JOIN silver.sikacredit_loan AS sl ON
            sr.loan_id = sl.loan_id
    WHERE sl.loan_id IS NULL;

    SELECT
        'Oman Remit remittances without customer' AS verification,
        COUNT(*)                                  AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.oman_remit_remittance AS orr
    LEFT JOIN silver.oman_remit_customer AS oc ON
            orr.customer_id = oc.customer_id
    WHERE oc.customer_id IS NULL;

    /*========================================================================================================================*
        4. TRANSFORMATION SANITY
    *========================================================================================================================*/
    PRINT '4. TRANSFORMATION SANITY';

    SELECT
        'Ananse transaction location parsing' AS verification,
        COUNT(*)                              AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.ananse_transaction
    WHERE transaction_location_region IS NULL
            OR transaction_location_town IS NULL;

    SELECT
        'SikaCredit loan location parsing' AS verification,
        COUNT(*)                           AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.sikacredit_loan
    WHERE disbursement_location_region IS NULL
            OR disbursement_location_town IS NULL;

    SELECT
        'SikaCredit repayment location parsing' AS verification,
        COUNT(*)                                AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.sikacredit_repayment
    WHERE repayment_location_region IS NULL
            OR repayment_location_town IS NULL;

    SELECT
        'Oman Remit location parsing' AS verification,
        COUNT(*)                      AS exception_count,
        CASE 
            WHEN COUNT(*) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.oman_remit_remittance
    WHERE remittance_location_region IS NULL
            OR remittance_location_town IS NULL;

    SELECT
        'Oman Remit remittance type derivation' AS verification,
        COUNT(*)                                AS exception_count,
        CASE 
            WHEN (
                    SELECT
                        COUNT(*)
                    FROM silver.oman_remit_remittance
                    WHERE (
                            remittance_origin_country = 'ghana'
                                AND remittance_type <> 'remittance_sent'
                            )
                            OR (
                            remittance_origin_country <> 'ghana'
                                AND remittance_type <> 'remittance_received'
                            )
                            OR remittance_type IS NULL
                    ) = 0
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM silver.oman_remit_remittance;

    /*========================================================================================================================*
        5. LOAD-BATCH VERIFICATION
    *========================================================================================================================*/
    PRINT '5. LOAD-BATCH VERIFICATION';

    SELECT
        expected.source_entity,
        CASE 
            WHEN lb.source_entity IS NOT NULL
                THEN 'PASS'
            ELSE 'FAIL'
            END AS verification_result
    FROM (
        SELECT
            'ocb_customer' AS source_entity
        
        UNION ALL
        
        SELECT
            'ocb_customer_identity'
        
        UNION ALL
        
        SELECT
            'ananse_customer'
        
        UNION ALL
        
        SELECT
            'ananse_wallet'
        
        UNION ALL
        
        SELECT
            'ananse_transaction'
        
        UNION ALL
        
        SELECT
            'sikacredit_customer'
        
        UNION ALL
        
        SELECT
            'sikacredit_loan'
        
        UNION ALL
        
        SELECT
            'sikacredit_repayment'
        
        UNION ALL
        
        SELECT
            'oman_remit_customer'
        
        UNION ALL
        
        SELECT
            'oman_remit_remittance'
        ) AS expected
    LEFT JOIN silver.load_batch AS lb ON
            expected.source_entity = lb.source_entity;

    PRINT '========================================================================================================================';
    PRINT 'SILVER TRANSFORMATION VERIFICATION COMPLETE';
    PRINT '========================================================================================================================';
END;
GO

/*========================================================================================================================
    EXECUTE SILVER FULL LOAD
========================================================================================================================*/
EXEC dbo.silver_transformations_full_load;

/*========================================================================================================================
    EXECUTE SILVER VERIFICATION
========================================================================================================================*/
EXEC dbo.silver_transformations_full_load_verification;

