WITH customer_transaction_analysis
AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_amount,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY t.transaction_amount
            ) OVER (PARTITION BY t.ocb_customer_id) AS median_transaction_value
    FROM gold.vw_transaction t
    WHERE t.transaction_status = 'successful'
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)                      AS total_transaction_count,
        SUM(transaction_amount)       AS total_transaction_value,
        AVG(transaction_amount)       AS average_transaction_value,
        MAX(median_transaction_value) AS median_transaction_value
    FROM customer_transaction_analysis
    GROUP BY ocb_customer_id
    )
SELECT TOP 10
    ocb_customer_id,
    CAST(ROUND(total_transaction_count * 1.0, 3) AS DECIMAL(19, 3)) AS total_transaction_count,
    CAST(ROUND(total_transaction_value, 3) AS DECIMAL(19, 3))       AS total_transaction_value,
    CAST(ROUND(average_transaction_value, 3) AS DECIMAL(19, 3))     AS average_transaction_value,
    CAST(ROUND(median_transaction_value, 3) AS DECIMAL(19, 3))      AS median_transaction_value
FROM customer_summary
ORDER BY total_transaction_value DESC;
