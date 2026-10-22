USE [ocb_platform];
GO

/*
====================================================================================================================================
    Ananse Institutional Monitoring
====================================================================================================================================
*/
-- 1. Overall Temporal Activity Analysis
CREATE
        OR

ALTER VIEW intelligence.vw_ananse_institutional_monitoring
AS
WITH monthly_totals
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        COUNT(DISTINCT ocb_customer_id)              AS distinct_customers,
        COUNT(*)                                     AS total_transaction_count,
        SUM(transaction_amount)                      AS total_transaction_value,
        AVG(transaction_amount)                      AS average_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
            AND transaction_type <> 'merchant payment'
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120)
    ),
monthly_medians
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (PARTITION BY CONVERT(CHAR(7), transaction_timestamp, 120)) AS median_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
            AND transaction_type <> 'merchant payment'
    ),
monthly_summary
AS (
    SELECT
        t.*,
        m.median_transaction_value
    FROM monthly_totals t
    INNER JOIN monthly_medians m ON
            t.year_month = m.year_month
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_transaction_count) OVER (
            ORDER BY year_month
            ) AS previous_transaction_count,
        LAG(total_transaction_value) OVER (
            ORDER BY year_month
            ) AS previous_transaction_value
    FROM monthly_summary
    )
SELECT
    year_month,
    distinct_customers,
    total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))                                                                                AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))                                                                              AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))                                                                               AS median_transaction_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3))    AS customers_mom_change_pct,
    CAST(ROUND((total_transaction_count - previous_transaction_count) * 100.0 / NULLIF(previous_transaction_count, 0), 3) AS DECIMAL(19, 3)) AS transaction_count_mom_change_pct,
    CAST(ROUND((total_transaction_value - previous_transaction_value) * 100.0 / NULLIF(previous_transaction_value, 0), 3) AS DECIMAL(19, 3)) AS transaction_value_mom_change_pct
FROM monthly_changes;
GO

-- 2. Transaction Type Activity
WITH transaction_type_analysis
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_type,
        COUNT(*)                                     AS total_transaction_count,
        SUM(transaction_amount)                      AS total_transaction_value,
        AVG(transaction_amount)                      AS average_transaction_value,
        COUNT(DISTINCT ocb_customer_id)              AS distinct_customers
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120),
        transaction_type
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_type,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), transaction_timestamp, 120),
            transaction_type
            ) AS median_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_transaction_value
    FROM transaction_type_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND a.transaction_type = m.transaction_type
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY transaction_type ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_transaction_count) OVER (
            PARTITION BY transaction_type ORDER BY year_month
            ) AS previous_transaction_count,
        LAG(total_transaction_value) OVER (
            PARTITION BY transaction_type ORDER BY year_month
            ) AS previous_transaction_value
    FROM monthly_activity
    )
SELECT
    year_month,
    transaction_type,
    distinct_customers,
    total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))                                                                                AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))                                                                              AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))                                                                               AS median_transaction_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3))    AS customers_mom_change_pct,
    CAST(ROUND((total_transaction_count - previous_transaction_count) * 100.0 / NULLIF(previous_transaction_count, 0), 3) AS DECIMAL(19, 3)) AS transaction_count_mom_change_pct,
    CAST(ROUND((total_transaction_value - previous_transaction_value) * 100.0 / NULLIF(previous_transaction_value, 0), 3) AS DECIMAL(19, 3)) AS transaction_value_mom_change_pct
FROM monthly_changes
ORDER BY transaction_type,
    year_month;
GO

-- 3. Transaction Channel Activity
WITH channel_analysis
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_channel,
        COUNT(*)                                     AS total_transaction_count,
        SUM(transaction_amount)                      AS total_transaction_value,
        AVG(transaction_amount)                      AS average_transaction_value,
        COUNT(DISTINCT ocb_customer_id)              AS distinct_customers
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120),
        transaction_channel
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_channel,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), transaction_timestamp, 120),
            transaction_channel
            ) AS median_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_transaction_value
    FROM channel_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND a.transaction_channel = m.transaction_channel
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY transaction_channel ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_transaction_count) OVER (
            PARTITION BY transaction_channel ORDER BY year_month
            ) AS previous_transaction_count,
        LAG(total_transaction_value) OVER (
            PARTITION BY transaction_channel ORDER BY year_month
            ) AS previous_transaction_value
    FROM monthly_activity
    )
SELECT
    year_month,
    transaction_channel,
    distinct_customers,
    total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))                                                                                AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))                                                                              AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))                                                                               AS median_transaction_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3))    AS customers_mom_change_pct,
    CAST(ROUND((total_transaction_count - previous_transaction_count) * 100.0 / NULLIF(previous_transaction_count, 0), 3) AS DECIMAL(19, 3)) AS transaction_count_mom_change_pct,
    CAST(ROUND((total_transaction_value - previous_transaction_value) * 100.0 / NULLIF(previous_transaction_value, 0), 3) AS DECIMAL(19, 3)) AS transaction_value_mom_change_pct
FROM monthly_changes
ORDER BY transaction_channel,
    year_month;
GO

-- 4. Transaction Region Activity
WITH region_analysis
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_location_region                  AS transaction_region,
        COUNT(*)                                     AS total_transaction_count,
        SUM(transaction_amount)                      AS total_transaction_value,
        AVG(transaction_amount)                      AS average_transaction_value,
        COUNT(DISTINCT ocb_customer_id)              AS distinct_customers
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120),
        transaction_location_region
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_location_region                  AS transaction_region,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), transaction_timestamp, 120),
            transaction_location_region
            ) AS median_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_transaction_value
    FROM region_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND (
                a.transaction_region = m.transaction_region
                    OR (
                    a.transaction_region IS NULL
                        AND m.transaction_region IS NULL
                    )
                )
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY transaction_region ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_transaction_count) OVER (
            PARTITION BY transaction_region ORDER BY year_month
            ) AS previous_transaction_count,
        LAG(total_transaction_value) OVER (
            PARTITION BY transaction_region ORDER BY year_month
            ) AS previous_transaction_value
    FROM monthly_activity
    )
SELECT
    year_month,
    transaction_region,
    distinct_customers,
    total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))                                                                                AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))                                                                              AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))                                                                               AS median_transaction_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3))    AS customers_mom_change_pct,
    CAST(ROUND((total_transaction_count - previous_transaction_count) * 100.0 / NULLIF(previous_transaction_count, 0), 3) AS DECIMAL(19, 3)) AS transaction_count_mom_change_pct,
    CAST(ROUND((total_transaction_value - previous_transaction_value) * 100.0 / NULLIF(previous_transaction_value, 0), 3) AS DECIMAL(19, 3)) AS transaction_value_mom_change_pct
FROM monthly_changes
ORDER BY transaction_region,
    year_month;
GO

-- 5. Transaction Town Activity
WITH town_analysis
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_location_town                    AS transaction_town,
        COUNT(*)                                     AS total_transaction_count,
        SUM(transaction_amount)                      AS total_transaction_value,
        AVG(transaction_amount)                      AS average_transaction_value,
        COUNT(DISTINCT ocb_customer_id)              AS distinct_customers
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120),
        transaction_location_town
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        transaction_location_town                    AS transaction_town,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), transaction_timestamp, 120),
            transaction_location_town
            ) AS median_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_transaction_value
    FROM town_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND (
                a.transaction_town = m.transaction_town
                    OR (
                    a.transaction_town IS NULL
                        AND m.transaction_town IS NULL
                    )
                )
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY transaction_town ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_transaction_count) OVER (
            PARTITION BY transaction_town ORDER BY year_month
            ) AS previous_transaction_count,
        LAG(total_transaction_value) OVER (
            PARTITION BY transaction_town ORDER BY year_month
            ) AS previous_transaction_value
    FROM monthly_activity
    )
SELECT
    year_month,
    transaction_town,
    distinct_customers,
    total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))                                                                                AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))                                                                              AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))                                                                               AS median_transaction_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3))    AS customers_mom_change_pct,
    CAST(ROUND((total_transaction_count - previous_transaction_count) * 100.0 / NULLIF(previous_transaction_count, 0), 3) AS DECIMAL(19, 3)) AS transaction_count_mom_change_pct,
    CAST(ROUND((total_transaction_value - previous_transaction_value) * 100.0 / NULLIF(previous_transaction_value, 0), 3) AS DECIMAL(19, 3)) AS transaction_value_mom_change_pct
FROM monthly_changes
ORDER BY transaction_town,
    year_month;
GO

-- 6. Successful vs Failure vs Rejection rates (Monthly)
WITH customer_outcome_analytics
AS (
    SELECT
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        COUNT(*)                                     AS total_transaction_count,
        SUM(CASE transaction_status
                WHEN 'successful'
                    THEN 1
                ELSE 0
                END) AS successful_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'successful'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS successful_rate,
        SUM(CASE transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS failure_rate,
        SUM(CASE transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS rejection_rate,
        ROUND(CAST(100.0 * (
                    SUM(CASE transaction_status
                            WHEN 'failed'
                                THEN 1
                            ELSE 0
                            END) + SUM(CASE transaction_status
                            WHEN 'rejected'
                                THEN 1
                            ELSE 0
                            END)
                    ) AS FLOAT) / (COUNT(*)), 3) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    GROUP BY CONVERT(CHAR(7), transaction_timestamp, 120)
    )
SELECT
    *
FROM customer_outcome_analytics
ORDER BY year_month;
GO

-- 7. Successful vs Failure vs Rejection rates (Channel)
WITH customer_outcome_analytics
AS (
    SELECT
        transaction_channel,
        COUNT(*) AS total_transaction_count,
        SUM(CASE transaction_status
                WHEN 'successful'
                    THEN 1
                ELSE 0
                END) AS successful_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'successful'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS successful_rate,
        SUM(CASE transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS failure_rate,
        SUM(CASE transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS rejection_rate,
        ROUND(CAST(100.0 * (
                    SUM(CASE transaction_status
                            WHEN 'failed'
                                THEN 1
                            ELSE 0
                            END) + SUM(CASE transaction_status
                            WHEN 'rejected'
                                THEN 1
                            ELSE 0
                            END)
                    ) AS FLOAT) / (COUNT(*)), 3) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    GROUP BY transaction_channel
    )
SELECT
    *
FROM customer_outcome_analytics;
GO

-- 8. Successful vs Failure vs Rejection rates (Type)
WITH customer_outcome_analytics
AS (
    SELECT
        transaction_type,
        COUNT(*) AS total_transaction_count,
        SUM(CASE transaction_status
                WHEN 'successful'
                    THEN 1
                ELSE 0
                END) AS successful_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'successful'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS successful_rate,
        SUM(CASE transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS failure_rate,
        SUM(CASE transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS rejection_rate,
        ROUND(CAST(100.0 * (
                    SUM(CASE transaction_status
                            WHEN 'failed'
                                THEN 1
                            ELSE 0
                            END) + SUM(CASE transaction_status
                            WHEN 'rejected'
                                THEN 1
                            ELSE 0
                            END)
                    ) AS FLOAT) / (COUNT(*)), 3) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    GROUP BY transaction_type
    )
SELECT
    *
FROM customer_outcome_analytics
GO

-- 9. Successful vs Failure vs Rejection rates (Customer)
CREATE
        OR

ALTER VIEW intelligence.vw_ananse_customer_transaction_outcomes
AS
WITH customer_outcome_analytics
AS (
    SELECT
        ocb_customer_id,
        COUNT(*) AS total_transaction_count,
        SUM(CASE transaction_status
                WHEN 'successful'
                    THEN 1
                ELSE 0
                END) AS successful_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'successful'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS successful_rate,
        SUM(CASE transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS failure_rate,
        SUM(CASE transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        ROUND(CAST(100.00 * SUM(CASE transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS rejection_rate,
        SUM(CASE 
                WHEN transaction_status IN (
                        'failed',
                        'rejected'
                        )
                    THEN 1
                ELSE 0
                END) AS unsuccessful_transactions,
        ROUND(CAST(100.00 * SUM(CASE 
                        WHEN transaction_status IN (
                                'failed',
                                'rejected'
                                )
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 3) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
    GROUP BY ocb_customer_id
    )
SELECT
    *
FROM customer_outcome_analytics;
GO

-- 10. Customer Activity Analysis: Top 10 by Successful Transaction Value
WITH customer_transaction_analysis
AS (
    SELECT
        t.ocb_customer_id,
        c.first_name,
        c.last_name,
        c.date_of_birth,
        c.phone_number,
        c.email,
        t.transaction_amount,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY t.transaction_amount
            ) OVER (PARTITION BY t.ocb_customer_id) AS median_transaction_value
    FROM gold.vw_transaction t
    INNER JOIN gold.vw_customer c ON
            t.ocb_customer_id = c.ocb_customer_id
    WHERE t.transaction_status = 'successful'
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email,
        COUNT(*)                      AS total_transaction_count,
        SUM(transaction_amount)       AS total_transaction_value,
        AVG(transaction_amount)       AS average_transaction_value,
        MAX(median_transaction_value) AS median_transaction_value
    FROM customer_transaction_analysis
    GROUP BY ocb_customer_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    )
SELECT TOP 10
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email,
    CAST(ROUND(total_transaction_count * 1.0, 3) AS DECIMAL(19, 3)) AS total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))       AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))     AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))      AS median_transaction_value
FROM customer_summary
ORDER BY total_transaction_value DESC;
GO

/*
====================================================================================================================================
    SikaCredit Institutional Monitoring
====================================================================================================================================
*/
-- SikaCredit: Monthly Principal Flows
WITH monthly_disbursements
AS (
    SELECT
        CONVERT(CHAR(7), disbursement_timestamp, 120) AS year_month,
        COUNT(DISTINCT ocb_customer_id)               AS distinct_loan_customers,
        SUM(principal_amount)                         AS principal_disbursed,
        COUNT(*)                                      AS principal_disbursed_count,
        AVG(principal_amount)                         AS average_principal_disbursed
    FROM gold.vw_loan
    GROUP BY CONVERT(CHAR(7), disbursement_timestamp, 120)
    ),
monthly_repayments
AS (
    SELECT
        CONVERT(CHAR(7), repayment_timestamp, 120) AS year_month,
        COUNT(DISTINCT ocb_customer_id)            AS distinct_repayment_customers,
        SUM(repayment_amount)                      AS principal_repaid,
        COUNT(*)                                   AS principal_repaid_count,
        AVG(repayment_amount)                      AS average_principal_repaid
    FROM gold.vw_repayment
    GROUP BY CONVERT(CHAR(7), repayment_timestamp, 120)
    ),
monthly_flows
AS (
    SELECT
        COALESCE(d.year_month, r.year_month)      AS year_month,
        COALESCE(distinct_loan_customers, 0)      AS distinct_loan_customers,
        COALESCE(average_principal_disbursed, 0)  AS average_principal_disbursed,
        COALESCE(d.principal_disbursed, 0)        AS principal_disbursed,
        COALESCE(d.principal_disbursed_count, 0)  AS principal_disbursed_count,
        COALESCE(distinct_repayment_customers, 0) AS distinct_repayment_customers,
        COALESCE(r.principal_repaid, 0)           AS principal_repaid,
        COALESCE(average_principal_repaid, 0)     AS average_principal_repaid,
        COALESCE(r.principal_repaid_count, 0)     AS principal_repaid_count
    FROM monthly_disbursements d
    FULL OUTER JOIN monthly_repayments r ON
            d.year_month = r.year_month
    )
SELECT
    year_month,
    distinct_loan_customers,
    principal_disbursed_count,
    CAST(principal_disbursed AS DECIMAL(19, 3))                    AS principal_disbursed,
    CAST(average_principal_disbursed AS DECIMAL(19, 3))            AS average_principal_disbursed,
    distinct_repayment_customers,
    principal_repaid_count,
    CAST(principal_repaid AS DECIMAL(19, 3))                       AS principal_repaid,
    CAST(average_principal_repaid AS DECIMAL(19, 3))               AS average_principal_repaid,
    CAST(principal_disbursed - principal_repaid AS DECIMAL(19, 3)) AS net_principal_flow,
    CAST(SUM(principal_disbursed - principal_repaid) OVER (
            ORDER BY year_month ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS DECIMAL(19, 3)) AS cumulative_net_principal_flow
FROM monthly_flows
ORDER BY year_month;
GO

/*
    WP-6.1 — INSTITUTIONAL MONITORING

    SikaCredit Institutional Health Monitoring

    Reporting period: April 2023 - December 2025

    Metrics:
    1. Principal Growth Rate
    2. Principal Repayment Ratio
    3. Principal Repayment-to-Growth Spread
    4. Repayment-to-Opening-Outstanding Principal Ratio
    5. Post-Maturity Outstanding Principal Value and Count
    6. Post-Maturity Outstanding Ratio

    Modelling assumptions:
    - Recorded repayments reduce principal directly.
    - Opening outstanding principal is configurable.
    - Outstanding principal is calculated from observed loans.
    - Maturity exposure is evaluated at each month-end.
*/
CREATE
        OR

ALTER VIEW intelligence.vw_sikacredit_institutional_monitoring
AS
WITH reporting_months
AS (
    SELECT
        CAST('2023-04-01' AS DATE) AS month_start
    
    UNION ALL
    
    SELECT
        DATEADD(MONTH, 1, month_start)
    FROM reporting_months
    WHERE month_start < CAST('2025-12-01' AS DATE)
    ),
monthly_disbursements
AS (
    SELECT
        DATEFROMPARTS(YEAR(disbursement_timestamp), MONTH(disbursement_timestamp), 1) AS month_start,
        COUNT(*)                                                                      AS loan_count,
        COUNT(DISTINCT ocb_customer_id)                                               AS distinct_borrowers,
        SUM(principal_amount)                                                         AS principal_disbursed
    FROM gold.vw_loan
    WHERE disbursement_timestamp >= '2023-04-01'
            AND disbursement_timestamp < '2026-01-01'
    GROUP BY DATEFROMPARTS(YEAR(disbursement_timestamp), MONTH(disbursement_timestamp), 1)
    ),
monthly_repayments
AS (
    SELECT
        DATEFROMPARTS(YEAR(repayment_timestamp), MONTH(repayment_timestamp), 1) AS month_start,
        COUNT(*)                                                                AS repayment_count,
        SUM(repayment_amount)                                                   AS principal_repaid
    FROM gold.vw_repayment
    WHERE repayment_timestamp >= '2023-04-01'
            AND repayment_timestamp < '2026-01-01'
    GROUP BY DATEFROMPARTS(YEAR(repayment_timestamp), MONTH(repayment_timestamp), 1)
    ),
monthly_flows
AS (
    SELECT
        m.month_start,
        COALESCE(d.loan_count, 0)          AS loan_count,
        COALESCE(d.distinct_borrowers, 0)  AS distinct_borrowers,
        COALESCE(d.principal_disbursed, 0) AS principal_disbursed,
        COALESCE(r.repayment_count, 0)     AS repayment_count,
        COALESCE(r.principal_repaid, 0)    AS principal_repaid
    FROM reporting_months m
    LEFT JOIN monthly_disbursements d ON
            m.month_start = d.month_start
    LEFT JOIN monthly_repayments r ON
            m.month_start = r.month_start
    ),
running_portfolio
AS (
    SELECT
        month_start,
        loan_count,
        distinct_borrowers,
        principal_disbursed,
        repayment_count,
        principal_repaid,
        principal_disbursed - principal_repaid AS net_principal_flow,
        COALESCE(SUM(principal_disbursed - principal_repaid) OVER (
                ORDER BY month_start ROWS BETWEEN UNBOUNDED PRECEDING
                        AND 1 PRECEDING
                ), 0) AS opening_outstanding_principal,
        SUM(principal_disbursed - principal_repaid) OVER (
            ORDER BY month_start ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS closing_outstanding_principal
    FROM monthly_flows
    ),
monthly_loan_balances
AS (
    SELECT
        m.month_start,
        l.loan_id,
        l.maturity_date,
        l.principal_amount,
        l.principal_amount - COALESCE(SUM(r.repayment_amount), 0) AS outstanding_principal
    FROM reporting_months m
    INNER JOIN gold.vw_loan l ON
            l.disbursement_timestamp < DATEADD(MONTH, 1, m.month_start)
    LEFT JOIN gold.vw_repayment r ON
            r.loan_id = l.loan_id
                AND r.repayment_timestamp < DATEADD(MONTH, 1, m.month_start)
    GROUP BY m.month_start,
        l.loan_id,
        l.maturity_date,
        l.principal_amount
    ),
monthly_maturity_exposure
AS (
    SELECT
        month_start,
        SUM(CASE 
                WHEN maturity_date <= EOMONTH(month_start)
                        AND outstanding_principal > 0
                    THEN outstanding_principal
                ELSE 0
                END) AS post_maturity_outstanding_principal,
        SUM(CASE 
                WHEN maturity_date <= EOMONTH(month_start)
                        AND outstanding_principal > 0
                    THEN 1
                ELSE 0
                END) AS post_maturity_outstanding_loan_count
    FROM monthly_loan_balances
    GROUP BY month_start
    ),
health_metrics
AS (
    SELECT
        p.*,
        100.0 * p.principal_disbursed / NULLIF(p.opening_outstanding_principal, 0) AS principal_growth_rate_pct,
        100.0 * p.principal_repaid / NULLIF(p.principal_disbursed, 0)              AS principal_repayment_ratio_pct,
        (100.0 * p.principal_repaid / NULLIF(p.principal_disbursed, 0)) - (100.0 * p.principal_disbursed / NULLIF(p.opening_outstanding_principal, 0)) AS principal_repayment_growth_spread_pp,
        100.0 * p.principal_repaid / NULLIF(p.opening_outstanding_principal, 0)    AS repayment_to_opening_outstanding_pct,
        COALESCE(e.post_maturity_outstanding_principal, 0)                         AS post_maturity_outstanding_principal,
        COALESCE(e.post_maturity_outstanding_loan_count, 0)                        AS post_maturity_outstanding_loan_count
    FROM running_portfolio p
    LEFT JOIN monthly_maturity_exposure e ON
            p.month_start = e.month_start
    )
SELECT
    CONVERT(CHAR(7), month_start, 120)                                                                             AS year_month,
    loan_count                                                                                                     AS loans_disbursed_count,
    distinct_borrowers,
    CAST(principal_disbursed AS DECIMAL(19, 2))                                                                    AS principal_disbursed,
    repayment_count,
    CAST(principal_repaid AS DECIMAL(19, 2))                                                                       AS principal_repaid,
    CAST(net_principal_flow AS DECIMAL(19, 2))                                                                     AS net_principal_flow,
    CAST(opening_outstanding_principal AS DECIMAL(19, 2))                                                          AS opening_outstanding_principal,
    CAST(closing_outstanding_principal AS DECIMAL(19, 2))                                                          AS closing_outstanding_principal,
    CAST(principal_growth_rate_pct AS DECIMAL(19, 2))                                                              AS principal_growth_rate_pct,
    CAST(principal_repayment_ratio_pct AS DECIMAL(19, 2))                                                          AS principal_repayment_ratio_pct,
    CAST(principal_repayment_growth_spread_pp AS DECIMAL(19, 2))                                                   AS principal_repayment_growth_spread_pp,
    CAST(repayment_to_opening_outstanding_pct AS DECIMAL(19, 2))                                                   AS repayment_to_opening_outstanding_pct,
    CAST(post_maturity_outstanding_principal AS DECIMAL(19, 2))                                                    AS post_maturity_outstanding_principal,
    post_maturity_outstanding_loan_count,
    CAST(100.0 * post_maturity_outstanding_principal / NULLIF(closing_outstanding_principal, 0) AS DECIMAL(19, 2)) AS post_maturity_outstanding_ratio_pct
FROM health_metrics;
GO

/*
-- WP-6.1 Institutional Health Monitoring — SikaCredit Credit Portfolio Construction
-- OBJECTIVE
-- Construct a monthly institutional monitoring portfolio for SikaCredit to track credit expansion, principal repayment activity,
    outstanding principal, and post-maturity exposure.
-- The portfolio provides supervisory indicators of institutional credit behaviour and identifies changes requiring further
    investigation.
-- REPORTING PERIOD
-- The reporting period runs from April 2023 through December 2025, covering 33 consecutive calendar months.
-- April 2023 is the opening reporting month because the earliest observed SikaCredit loan was disbursed on 4 April 2023.
-- The reporting end date is 31 December 2025. Monthly portfolio and maturity exposure measures are calculated at each calendar
    month-end.
-- REPORTING CALENDAR
-- A recursive common table expression generates the complete sequence of reporting months, beginning on 1 April 2023 and advancing
    one month at a time until December 2025.
-- This establishes a continuous reporting calendar independent of lending or repayment activity.
-- Months with no recorded disbursements or repayments remain in the portfolio, allowing institutional activity and outstanding
    balances to be monitored consistently across the full reporting period.
-- OPENING PORTFOLIO ASSUMPTION
-- The opening outstanding principal balance is configured as zero.
-- This assumption is consistent with the observed loan population because the earliest recorded loan was disbursed during April
    2023, the first reporting month.
-- The model assumes that the observed loan and repayment records represent the principal activity required to reconstruct the
    portfolio over the reporting period.
-- If the model is extended to cover an institution with an existing portfolio before the reporting start date, the opening balance
    must be supported by an appropriate opening portfolio position and corresponding loan-level records where maturity exposure is
    required.
-- PRINCIPAL PORTFOLIO CONSTRUCTION
-- Monthly principal disbursements represent the total original principal value of loans disbursed during each reporting month.
-- Monthly principal repayments represent the total recorded repayment value during each reporting month and are treated as
    repayments against principal.
-- Monthly net principal flow is calculated as principal disbursed minus principal repaid.
-- Opening outstanding principal for each month is the preceding month's closing outstanding principal, beginning with the
    configured opening balance.
-- Closing outstanding principal is reconstructed by adding the current month's net principal flow to the opening outstanding
    principal.
-- This produces an aggregate principal portfolio movement measure across the reporting period.
-- The model is principal-only. It excludes interest, fees, penalties, and other charges from outstanding balances.
-- Repayment records are assumed to reduce principal directly. The model does not allocate repayments between principal, interest,
    fees, or other components.
-- MONTH-END LOAN BALANCES
-- Loan-level outstanding principal is reconstructed for each reporting month using the original loan principal less cumulative
    recorded repayments up to the relevant month-end.
-- These loan-level balances are used to identify principal that remains outstanding after the contractual maturity date.
-- The aggregate portfolio balance and loan-level balances are based on the same principal-only assumption.
-- POST-MATURITY EXPOSURE
-- A loan contributes to post-maturity exposure when its contractual maturity date has passed by the reporting month-end and it
    retains a positive outstanding principal balance.
-- Post-maturity outstanding principal is the sum of the remaining principal balances of all loans meeting these conditions.
-- The post-maturity loan count is the number of loans meeting the same conditions.
-- Post-maturity outstanding ratio measures post-maturity outstanding principal as a percentage of the aggregate closing outstanding
    principal.
-- The model treats a loan as post-maturity once its contractual maturity date has passed, regardless of how many days have elapsed
    since maturity.
-- The measure therefore identifies outstanding principal beyond contractual maturity but does not distinguish between one day past
    maturity and prolonged delinquency.
-- METRIC 1 — PRINCIPAL GROWTH RATE
-- Measures monthly principal disbursements relative to opening outstanding principal.
-- A higher value indicates that new lending is large relative to the principal portfolio carried into the month.
-- A value cannot be calculated when opening outstanding principal is zero.
-- The metric measures lending intensity relative to the opening portfolio; it does not independently establish sustainable growth,
    credit quality, or risk.
-- METRIC 2 — PRINCIPAL REPAYMENT RATIO
-- Measures monthly principal repayments relative to principal disbursed during the same month.
-- A value above 100% means recorded repayments during the month exceeded new principal disbursements.
-- A value below 100% means recorded repayments were lower than new principal disbursements.
-- Repayments may relate to loans originated in earlier months, so this metric does not measure the repayment performance of loans
    disbursed during the same month.
-- A high ratio can occur when monthly disbursements are low and should not be interpreted as the percentage of the total portfolio
    collected.
-- METRIC 3 — PRINCIPAL REPAYMENT-TO-GROWTH SPREAD
-- Measures the difference between the Principal Repayment Ratio and the Principal Growth Rate, expressed in percentage points.
-- A negative value means the Principal Repayment Ratio is lower than the Principal Growth Rate.
-- A positive value means the Principal Repayment Ratio is higher than the Principal Growth Rate.
-- The metric compares two ratios with different denominators and is a comparative indicator rather than a direct measure of
    portfolio expansion or contraction.
-- Net principal flow determines whether recorded principal activity increased or decreased the aggregate outstanding portfolio
    during the month.
-- METRIC 4 — REPAYMENT-TO-OPENING OUTSTANDING RATIO
-- Measures monthly principal repayments relative to the outstanding principal balance at the beginning of the month.
-- It indicates the scale of monthly principal repayment activity relative to the portfolio carried forward from the preceding month.
-- A higher value indicates greater repayment volume relative to the opening portfolio but does not establish that the same
    proportion of individual loans was repaid or that overdue loans were resolved.
-- A value cannot be calculated when opening outstanding principal is zero.
-- METRIC 5 — POST-MATURITY OUTSTANDING PRINCIPAL AND LOAN COUNT
-- Measures the amount of principal remaining on loans that have passed their contractual maturity dates and the number of loans
    contributing to that exposure.
-- The principal amount indicates the monetary scale of the identified exposure, while the loan count indicates how many loans
    contribute to it.
-- These measures identify outstanding contractual maturity exposure but do not independently establish the reasons for
    non-repayment or the institution's overall solvency.
-- METRIC 6 — POST-MATURITY OUTSTANDING RATIO
-- Measures post-maturity outstanding principal as a percentage of closing outstanding principal at each reporting month-end.
-- A rising ratio indicates that post-maturity exposure represents an increasing share of the closing principal portfolio.
-- The ratio can increase because post-maturity exposure rises, because the overall outstanding portfolio contracts, or because
    both occur.
-- The ratio is not a default rate or a measure of the proportion of borrowers in arrears.
-- A value cannot be calculated when closing outstanding principal is zero.
-- INTERPRETATION AND LIMITATIONS
-- Monthly disbursements and repayments describe activity occurring within the reporting month, while opening and closing
    outstanding principal describe the reconstructed portfolio position.
-- Monthly repayment totals are not matched to the maturity status of individual loans in the aggregate repayment metrics.
-- Changes in post-maturity exposure may reflect repayments against already-matured loans, loans newly passing their maturity dates,
    and other changes in outstanding principal.
-- The aggregate measures do not independently explain the contribution of each of these movements.
-- The model assumes recorded repayments are valid principal reductions and does not independently assess collection effectiveness,
    credit-loss provisioning, interest accruals, write-offs, restructuring, or recoverability.
-- RESULTS AND VALIDATION
-- Across the reporting period, total principal disbursed was 1,112,318.94 and total principal repaid was 862,215.98, producing net
    principal flow of 250,102.96.
-- The December 2025 closing outstanding principal was 250,102.96.
-- At December 2025, post-maturity outstanding principal was 155,251.17 across 701 loans, representing 62.07% of closing outstanding
    principal.
-- In November 2025, closing outstanding principal was 363,868.79 and post-maturity outstanding principal was 135,407.71,
    representing 37.21% of closing outstanding principal.
-- In December 2025, repayments substantially exceeded new disbursements, reducing closing outstanding principal while post-maturity
    outstanding principal increased.
-- The increase in the post-maturity ratio from 37.21% in November to 62.07% in December indicates that post-maturity exposure
    represented a substantially larger share of the closing portfolio at year-end.
-- These results identify a portfolio pattern requiring further investigation; they do not, by themselves, establish the cause of
    the change or the institution's overall financial condition.
-- FUTURE ENHANCEMENT
-- Loan-Level Maturity Exposure Movement Analysis could distinguish repayments against loans already past maturity, loans newly
    passing maturity, and other changes in outstanding principal, reconciling these movements to changes in monthly post-maturity
    exposure.
*/
-- Top 10 borrowers by total principal
WITH loan_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(l.principal_amount) AS total_principal_borrowed,
        COUNT(*)                AS loan_count,
        AVG(l.principal_amount) AS avg_loan_amount
    FROM gold.vw_loan l
    WHERE l.disbursement_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    ),
repayment_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(r.repayment_amount) AS total_repaid,
        COUNT(*)                AS repayment_count,
        AVG(r.repayment_amount) AS avg_repayment_amount
    FROM gold.vw_repayment r
    INNER JOIN gold.vw_loan l ON
            r.loan_id = l.loan_id
    WHERE r.repayment_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    )
SELECT --TOP 10
    l.ocb_customer_id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.phone_number,
    c.email,
    l.total_principal_borrowed,
    l.loan_count,
    l.avg_loan_amount,
    COALESCE(r.total_repaid, 0)    AS total_repaid,
    COALESCE(r.repayment_count, 0) AS repayment_count,
    r.avg_repayment_amount
FROM loan_summary l
INNER JOIN gold.vw_customer c ON
        l.ocb_customer_id = c.ocb_customer_id
LEFT JOIN repayment_summary r ON
        l.ocb_customer_id = r.ocb_customer_id
ORDER BY total_principal_borrowed DESC;
GO

-- Top 10 borrowers by total outstanding principal
WITH loan_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(l.principal_amount) AS total_principal_borrowed,
        COUNT(*)                AS loan_count,
        AVG(l.principal_amount) AS avg_loan_amount
    FROM gold.vw_loan l
    WHERE l.disbursement_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    ),
repayment_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(r.repayment_amount) AS total_repaid,
        COUNT(*)                AS repayment_count,
        AVG(r.repayment_amount) AS avg_repayment_amount
    FROM gold.vw_repayment r
    INNER JOIN gold.vw_loan l ON
            r.loan_id = l.loan_id
    WHERE r.repayment_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    )
SELECT TOP 10
    l.ocb_customer_id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.phone_number,
    c.email,
    l.total_principal_borrowed - COALESCE(r.total_repaid, 0) AS total_outstanding_principal,
    l.total_principal_borrowed,
    l.loan_count,
    l.avg_loan_amount,
    COALESCE(r.total_repaid, 0)                              AS total_repaid,
    COALESCE(r.repayment_count, 0)                           AS repayment_count,
    r.avg_repayment_amount
FROM loan_summary l
INNER JOIN gold.vw_customer c ON
        l.ocb_customer_id = c.ocb_customer_id
LEFT JOIN repayment_summary r ON
        l.ocb_customer_id = r.ocb_customer_id
WHERE l.total_principal_borrowed - COALESCE(r.total_repaid, 0) > 0
ORDER BY total_outstanding_principal DESC;
GO

-- Top 10 borrowers by post-maturity outstanding debt
WITH loan_balances
AS (
    SELECT
        l.loan_id,
        l.ocb_customer_id,
        l.principal_amount,
        l.maturity_date,
        l.principal_amount - COALESCE(SUM(r.repayment_amount), 0) AS outstanding_principal
    FROM gold.vw_loan l
    LEFT JOIN gold.vw_repayment r ON
            l.loan_id = r.loan_id
                AND r.repayment_timestamp < '2026-01-01'
    WHERE l.disbursement_timestamp < '2026-01-01'
    GROUP BY l.loan_id,
        l.ocb_customer_id,
        l.principal_amount,
        l.maturity_date
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        SUM(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN outstanding_principal
                ELSE 0
                END) AS post_maturity_outstanding,
        COUNT(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN loan_id
                END) AS post_maturity_loan_count,
        AVG(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN outstanding_principal
                END) AS avg_post_maturity_outstanding
    FROM loan_balances
    GROUP BY ocb_customer_id
    )
SELECT TOP 10
    s.ocb_customer_id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.phone_number,
    c.email,
    s.post_maturity_outstanding,
    s.post_maturity_loan_count,
    s.avg_post_maturity_outstanding
FROM customer_summary s
INNER JOIN gold.vw_customer c ON
        s.ocb_customer_id = c.ocb_customer_id
WHERE s.post_maturity_outstanding > 0
ORDER BY s.post_maturity_outstanding DESC;
GO

/*
====================================================================================================================================
    Oman Remit Institutional Monitoring
====================================================================================================================================
*/
-- 1. Overall Temporal Activity Analysis
CREATE
        OR

ALTER VIEW intelligence.vw_oman_remit_institutional_monitoring
AS
WITH monthly_totals
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120)
    ),
monthly_medians
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120)) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_summary
AS (
    SELECT
        t.*,
        m.median_remittance_value
    FROM monthly_totals t
    INNER JOIN monthly_medians m ON
            t.year_month = m.year_month
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_summary
    )
SELECT
    year_month,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes;
GO

-- 2. Remittance Type Activity
WITH remittance_type_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_type,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120),
        remittance_type
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_type,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120),
            remittance_type
            ) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_remittance_value
    FROM remittance_type_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND a.remittance_type = m.remittance_type
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY remittance_type ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            PARTITION BY remittance_type ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            PARTITION BY remittance_type ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_activity
    )
SELECT
    year_month,
    remittance_type,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes
ORDER BY remittance_type,
    year_month;
GO

-- 3. Remittance Channel Activity
WITH channel_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_transaction_channel,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120),
        remittance_transaction_channel
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_transaction_channel,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120),
            remittance_transaction_channel
            ) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_remittance_value
    FROM channel_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND a.remittance_transaction_channel = m.remittance_transaction_channel
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY remittance_transaction_channel ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            PARTITION BY remittance_transaction_channel ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            PARTITION BY remittance_transaction_channel ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_activity
    )
SELECT
    year_month,
    remittance_transaction_channel,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes
ORDER BY remittance_transaction_channel,
    year_month;
GO

-- 4. Remittance Origin Country Activity
WITH country_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_origin_country,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120),
        remittance_origin_country
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_origin_country,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120),
            remittance_origin_country
            ) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_remittance_value
    FROM country_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND (
                a.remittance_origin_country = m.remittance_origin_country
                    OR (
                    a.remittance_origin_country IS NULL
                        AND m.remittance_origin_country IS NULL
                    )
                )
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY remittance_origin_country ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            PARTITION BY remittance_origin_country ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            PARTITION BY remittance_origin_country ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_activity
    )
SELECT
    year_month,
    remittance_origin_country,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes
ORDER BY remittance_origin_country,
    year_month;
GO

-- 5. Oman Remit FATF Origin-Risk Monitoring
CREATE
        OR

ALTER VIEW intelligence.vw_oman_remit_fatf_monitoring
AS
SELECT
    ocb_customer_id,
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    remittance_origin_country,
    remittance_status,
    remittance_type,
    CASE 
        WHEN remittance_origin_country = 'cote d''ivoire'
                AND CAST(remittance_timestamp AS DATE) >= '2024-10-01'
            THEN 1
        WHEN remittance_origin_country = 'nigeria'
                AND CAST(remittance_timestamp AS DATE) BETWEEN '2023-02-01'
                AND '2025-09-30'
            THEN 1
        WHEN remittance_origin_country = 'south africa'
                AND CAST(remittance_timestamp AS DATE) BETWEEN '2023-02-01'
                AND '2025-09-30'
            THEN 1
        WHEN remittance_origin_country = 'united arab emirates'
                AND CAST(remittance_timestamp AS DATE) < '2024-02-01'
            THEN 1
        ELSE 0
        END AS remittance_origin_risk_flag
FROM gold.vw_remittance; 
GO

-- 6. Remittance Region Activity
WITH region_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_location_region,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120),
        remittance_location_region
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_location_region,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120),
            remittance_location_region
            ) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_remittance_value
    FROM region_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND (
                a.remittance_location_region = m.remittance_location_region
                    OR (
                    a.remittance_location_region IS NULL
                        AND m.remittance_location_region IS NULL
                    )
                )
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY remittance_location_region ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            PARTITION BY remittance_location_region ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            PARTITION BY remittance_location_region ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_activity
    )
SELECT
    year_month,
    remittance_location_region,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes
ORDER BY remittance_location_region,
    year_month;
GO

-- 7. Remittance Town Activity
WITH town_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_location_town,
        COUNT(*)                                    AS total_remittance_count,
        SUM(remittance_amount)                      AS total_remittance_value,
        AVG(remittance_amount)                      AS average_remittance_value,
        COUNT(DISTINCT ocb_customer_id)             AS distinct_customers
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120),
        remittance_location_town
    ),
median_calc
AS (
    SELECT DISTINCT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        remittance_location_town,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY remittance_amount
            ) OVER (
            PARTITION BY CONVERT(CHAR(7), remittance_timestamp, 120),
            remittance_location_town
            ) AS median_remittance_value
    FROM gold.vw_remittance
    WHERE remittance_status = 'successful'
    ),
monthly_activity
AS (
    SELECT
        a.*,
        m.median_remittance_value
    FROM town_analysis a
    INNER JOIN median_calc m ON
            a.year_month = m.year_month
                AND (
                a.remittance_location_town = m.remittance_location_town
                    OR (
                    a.remittance_location_town IS NULL
                        AND m.remittance_location_town IS NULL
                    )
                )
    ),
monthly_changes
AS (
    SELECT
        *,
        LAG(distinct_customers) OVER (
            PARTITION BY remittance_location_town ORDER BY year_month
            ) AS previous_distinct_customers,
        LAG(total_remittance_count) OVER (
            PARTITION BY remittance_location_town ORDER BY year_month
            ) AS previous_remittance_count,
        LAG(total_remittance_value) OVER (
            PARTITION BY remittance_location_town ORDER BY year_month
            ) AS previous_remittance_value
    FROM monthly_activity
    )
SELECT
    year_month,
    remittance_location_town,
    distinct_customers,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))                                                                              AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3))                                                                            AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))                                                                             AS median_remittance_value,
    CAST(ROUND((distinct_customers - previous_distinct_customers) * 100.0 / NULLIF(previous_distinct_customers, 0), 3) AS DECIMAL(19, 3)) AS customers_mom_change_pct,
    CAST(ROUND((total_remittance_count - previous_remittance_count) * 100.0 / NULLIF(previous_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS remittance_count_mom_change_pct,
    CAST(ROUND((total_remittance_value - previous_remittance_value) * 100.0 / NULLIF(previous_remittance_value, 0), 3) AS DECIMAL(19, 3)) AS remittance_value_mom_change_pct
FROM monthly_changes
ORDER BY remittance_location_town,
    year_month;
GO

-- 8. Successful vs Failed vs Rejected Remittance Rates
WITH remittance_outcome_analysis
AS (
    SELECT
        CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
        COUNT(*)                                    AS total_remittance_count,
        SUM(CASE 
                WHEN remittance_status = 'successful'
                    THEN 1
                ELSE 0
                END) AS successful_remittances,
        SUM(CASE 
                WHEN remittance_status = 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_remittances,
        SUM(CASE 
                WHEN remittance_status = 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_remittances
    FROM gold.vw_remittance
    GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120)
    )
SELECT
    year_month,
    total_remittance_count,
    successful_remittances,
    CAST(ROUND(100.0 * successful_remittances / NULLIF(total_remittance_count, 0), 3) AS DECIMAL(19, 3))                      AS successful_rate_pct,
    failed_remittances,
    CAST(ROUND(100.0 * failed_remittances / NULLIF(total_remittance_count, 0), 3) AS DECIMAL(19, 3))                          AS failure_rate_pct,
    rejected_remittances,
    CAST(ROUND(100.0 * rejected_remittances / NULLIF(total_remittance_count, 0), 3) AS DECIMAL(19, 3))                        AS rejection_rate_pct,
    CAST(ROUND(100.0 * (failed_remittances + rejected_remittances) / NULLIF(total_remittance_count, 0), 3) AS DECIMAL(19, 3)) AS overall_unsuccessful_rate_pct
FROM remittance_outcome_analysis
ORDER BY year_month;
GO

-- 9. Customer Activity Analysis: Top 10 by Successful Remittance Value
WITH customer_remittance_analysis
AS (
    SELECT
        r.ocb_customer_id,
        c.first_name,
        c.last_name,
        c.date_of_birth,
        c.phone_number,
        c.email,
        r.remittance_amount,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY r.remittance_amount
            ) OVER (PARTITION BY r.ocb_customer_id) AS median_remittance_value
    FROM gold.vw_remittance r
    INNER JOIN gold.vw_customer c ON
            r.ocb_customer_id = c.ocb_customer_id
    WHERE r.remittance_status = 'successful'
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email,
        COUNT(*)                     AS total_remittance_count,
        SUM(remittance_amount)       AS total_remittance_value,
        AVG(remittance_amount)       AS average_remittance_value,
        MAX(median_remittance_value) AS median_remittance_value
    FROM customer_remittance_analysis
    GROUP BY ocb_customer_id,
        first_name,
        last_name,
        date_of_birth,
        phone_number,
        email
    )
SELECT TOP 10
    ocb_customer_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))   AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3)) AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))  AS median_remittance_value
FROM customer_summary
ORDER BY total_remittance_value DESC;
GO



