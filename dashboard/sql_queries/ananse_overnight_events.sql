-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

WITH customer_outcomes AS (
    SELECT
        ocb_customer_id,
        COUNT(*) AS total_transaction_count,
        SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) AS unsuccessful_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
        AND transaction_timestamp >= '{START_DATE}'
        AND transaction_timestamp < '{END_EXCLUSIVE}'
    GROUP BY ocb_customer_id
),
customer_population AS (
    SELECT *
    FROM customer_outcomes
    ),
overnight_transactions_signals
AS (
    SELECT
        v.ocb_customer_id,
        v.overnight_date,
        v.overnight_total_value,
        v.normal_hours_median_value,
        v.value_residual,
        v.overnight_residual_score,
        r.interval_minutes,
        r.overnight_rapidity_mad_score
    FROM intelligence.vw_signal_overnight_value_score AS v
    LEFT JOIN intelligence.vw_signal_overnight_rapidity_score AS r ON
            v.ocb_customer_id = r.ocb_customer_id
                AND v.overnight_date = r.overnight_date
    WHERE v.overnight_date >= '{START_DATE}'
        AND v.overnight_date < '{END_EXCLUSIVE}'
    )
SELECT
    t50.ocb_customer_id,
    t50.unsuccessful_transactions,
    t50.overall_unsuccessful_rate,
    o.value_residual,
    o.overnight_residual_score,
    o.interval_minutes,
    o.overnight_rapidity_mad_score
FROM customer_population t50
LEFT JOIN overnight_transactions_signals o ON
        t50.ocb_customer_id = o.ocb_customer_id
ORDER BY t50.unsuccessful_transactions DESC,
    t50.overall_unsuccessful_rate DESC,
    t50.ocb_customer_id;
