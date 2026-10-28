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
