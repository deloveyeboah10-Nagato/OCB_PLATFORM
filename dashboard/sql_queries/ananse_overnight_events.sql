-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql.
-- Each overnight event carries customer outcome context for the same calendar month,
-- so filtering the packaged event snapshot does not leak full-horizon outcome totals.
WITH customer_outcomes AS (
    SELECT
        ocb_customer_id,
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        COUNT(*) AS total_transaction_count,
        SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) AS unsuccessful_transactions,
        CAST(100.0 * SUM(CASE WHEN transaction_status IN ('failed', 'rejected') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(19, 3)) AS overall_unsuccessful_rate
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
        AND transaction_timestamp >= '{START_DATE}'
        AND transaction_timestamp < '{END_EXCLUSIVE}'
    GROUP BY ocb_customer_id, CONVERT(CHAR(7), transaction_timestamp, 120)
),
overnight_transactions_signals AS (
    SELECT
        v.ocb_customer_id,
        v.overnight_date,
        CONVERT(CHAR(7), v.overnight_date, 120) AS year_month,
        v.overnight_total_value,
        v.normal_hours_median_value,
        v.value_residual,
        v.overnight_residual_score,
        r.interval_minutes,
        r.overnight_rapidity_mad_score
    FROM intelligence.vw_signal_overnight_value_score AS v
    LEFT JOIN intelligence.vw_signal_overnight_rapidity_score AS r
        ON v.ocb_customer_id = r.ocb_customer_id
        AND v.overnight_date = r.overnight_date
    WHERE v.overnight_date >= '{START_DATE}'
        AND v.overnight_date < '{END_EXCLUSIVE}'
)
SELECT
    o.ocb_customer_id,
    o.overnight_date,
    o.year_month,
    COALESCE(t.total_transaction_count, 0) AS total_transaction_count,
    COALESCE(t.unsuccessful_transactions, 0) AS unsuccessful_transactions,
    t.overall_unsuccessful_rate,
    o.value_residual,
    o.overnight_residual_score,
    o.interval_minutes,
    o.overnight_rapidity_mad_score
FROM overnight_transactions_signals AS o
LEFT JOIN customer_outcomes AS t
    ON o.ocb_customer_id = t.ocb_customer_id
    AND o.year_month = t.year_month
ORDER BY o.overnight_date, o.ocb_customer_id;
