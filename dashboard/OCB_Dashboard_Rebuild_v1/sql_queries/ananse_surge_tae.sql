-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

WITH transaction_level
AS (
    SELECT
        t.transaction_id,
        t.ocb_customer_id,
        CONVERT(CHAR(7), t.transaction_timestamp, 120) AS year_month,
        t.transaction_timestamp,
        t.transaction_type,
        t.transaction_amount,
        -- Global Amount
        g.log_transaction_amount,
        g.global_amount_score,
        -- Velocity
        v.txn_interval_mins,
        v.velocity_score
    FROM gold.vw_transaction AS t
    LEFT JOIN intelligence.vw_signal_global_score AS g ON
            t.transaction_id = g.transaction_id
                AND t.ocb_customer_id = g.ocb_customer_id
    LEFT JOIN intelligence.vw_signal_velocity_score AS v ON
            t.transaction_id = v.transaction_id
                AND t.ocb_customer_id = v.ocb_customer_id
    WHERE t.transaction_status = 'successful'
            AND t.transaction_type <> 'merchant payment'
    ),
customer_population
AS (
    SELECT ocb_customer_id,
        year_month,
        previous_transaction_count   AS november_transaction_count,
        total_transaction_count      AS december_transaction_count,
        transaction_count_mom_change AS transaction_count_change,
        previous_transaction_value   AS november_transaction_value,
        total_transaction_value      AS december_transaction_value,
        transaction_value_mom_change AS transaction_value_change,
        transaction_count_mom_change_pct,
        transaction_value_mom_change_pct
    FROM intelligence.vw_ananse_customer_transaction_analysis
    WHERE year_month BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    ),
customer_month_signals
AS (
    SELECT
        t50.ocb_customer_id,
        t50.year_month,
        t50.november_transaction_count,
        t50.december_transaction_count,
        t50.transaction_count_change,
        t50.november_transaction_value,
        t50.december_transaction_value,
        t50.transaction_value_change,
        t50.transaction_count_mom_change_pct,
        t50.transaction_value_mom_change_pct,
        cs.log_monthly_transaction_value,
        cs.customer_amount_score
    FROM customer_population t50
    INNER JOIN intelligence.vw_signal_customer_score cs ON
            t50.ocb_customer_id = cs.ocb_customer_id
                AND t50.year_month = cs.year_month
    )
SELECT
    t.ocb_customer_id,
    t.year_month,
    t.transaction_id,
    c.november_transaction_count,
    c.december_transaction_count,
    c.transaction_count_change,
    c.november_transaction_value,
    c.december_transaction_value,
    c.transaction_value_change,
    -- Transaction-level signals
    t.global_amount_score,
    t.velocity_score,
    -- Customer-month signals
    c.customer_amount_score
FROM transaction_level AS t
INNER JOIN customer_month_signals AS c ON
        t.ocb_customer_id = c.ocb_customer_id
            AND t.year_month = c.year_month;
