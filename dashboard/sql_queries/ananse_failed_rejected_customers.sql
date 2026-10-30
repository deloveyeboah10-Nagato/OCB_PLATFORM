-- Source metric definition: WP-6.1 customer outcomes; recalculated for selected reporting window.
WITH customer_outcome_analytics AS (
    SELECT
        ocb_customer_id,
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        COUNT(*) AS total_transaction_count,
        SUM(CASE WHEN transaction_status = 'successful' THEN 1 ELSE 0 END) AS successful_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status = 'successful' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS successful_rate,
        SUM(CASE WHEN transaction_status = 'failed' THEN 1 ELSE 0 END) AS failed_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status = 'failed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS failure_rate,
        SUM(CASE WHEN transaction_status = 'rejected' THEN 1 ELSE 0 END) AS rejected_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status = 'rejected' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS rejection_rate,
        SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) AS unsuccessful_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
        AND transaction_timestamp >= '{START_DATE}'
        AND transaction_timestamp < '{END_EXCLUSIVE}'
    GROUP BY ocb_customer_id, CONVERT(CHAR(7), transaction_timestamp, 120)
)
SELECT *
FROM customer_outcome_analytics
ORDER BY unsuccessful_transactions DESC, overall_unsuccessful_rate DESC, ocb_customer_id;
