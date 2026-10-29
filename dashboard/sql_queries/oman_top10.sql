WITH customer_remittance_analysis
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_amount,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY r.remittance_amount
            ) OVER (PARTITION BY r.ocb_customer_id) AS median_remittance_value
    FROM gold.vw_remittance r
    WHERE r.remittance_status = 'successful'
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)                     AS total_remittance_count,
        SUM(remittance_amount)       AS total_remittance_value,
        AVG(remittance_amount)       AS average_remittance_value,
        MAX(median_remittance_value) AS median_remittance_value
    FROM customer_remittance_analysis
    GROUP BY ocb_customer_id
    )
SELECT TOP 10
    ocb_customer_id,
    total_remittance_count,
    CAST(ROUND(total_remittance_value, 3) AS DECIMAL(19, 3))   AS total_remittance_value,
    CAST(ROUND(average_remittance_value, 3) AS DECIMAL(19, 3)) AS average_remittance_value,
    CAST(ROUND(median_remittance_value, 3) AS DECIMAL(19, 3))  AS median_remittance_value
FROM customer_summary
ORDER BY total_remittance_value DESC;
