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
