-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

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
customer_population AS (
    SELECT ocb_customer_id,
        year_month,
        unsuccessful_transactions,
        overall_unsuccessful_rate
    FROM customer_outcomes
    ),
value_signal_summary
AS (
    SELECT
        ocb_customer_id,
        CONVERT(CHAR(7), overnight_date, 120) AS year_month,
        COUNT(CASE 
                WHEN overnight_residual_score > 0
                    THEN 1
                END) AS positive_value_signal_count,
        MAX(overnight_residual_score) AS max_value_signal_score
    FROM intelligence.vw_signal_overnight_value_score
    WHERE overnight_date >= '{START_DATE}'
        AND overnight_date < '{END_EXCLUSIVE}'
    GROUP BY ocb_customer_id, CONVERT(CHAR(7), overnight_date, 120)
    ),
rapidity_signal_summary
AS (
    SELECT
        ocb_customer_id,
        CONVERT(CHAR(7), overnight_date, 120) AS year_month,
        COUNT(CASE 
                WHEN overnight_rapidity_mad_score > 0
                    THEN 1
                END) AS positive_rapidity_signal_count,
        MAX(overnight_rapidity_mad_score) AS max_rapidity_signal_score
    FROM intelligence.vw_signal_overnight_rapidity_score
    WHERE overnight_date >= '{START_DATE}'
        AND overnight_date < '{END_EXCLUSIVE}'
    GROUP BY ocb_customer_id, CONVERT(CHAR(7), overnight_date, 120)
    )
SELECT
    t.ocb_customer_id,
    t.year_month,
    t.unsuccessful_transactions,
    t.overall_unsuccessful_rate,
    COALESCE(v.positive_value_signal_count, 0)    AS positive_value_signal_count,
    v.max_value_signal_score,
    COALESCE(r.positive_rapidity_signal_count, 0) AS positive_rapidity_signal_count,
    r.max_rapidity_signal_score
FROM customer_population AS t
LEFT JOIN value_signal_summary AS v ON
        t.ocb_customer_id = v.ocb_customer_id
        AND t.year_month = v.year_month
LEFT JOIN rapidity_signal_summary AS r ON
        t.ocb_customer_id = r.ocb_customer_id
        AND t.year_month = r.year_month
ORDER BY t.unsuccessful_transactions DESC,
    t.overall_unsuccessful_rate DESC,
    t.ocb_customer_id;
