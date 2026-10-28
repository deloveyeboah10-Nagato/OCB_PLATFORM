-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

WITH customer_population
AS (
    SELECT ocb_customer_id,
        year_month,
        transaction_count_mom_change AS transaction_count_change,
        transaction_value_mom_change AS transaction_value_change,
        transaction_count_mom_change_pct,
        transaction_value_mom_change_pct
    FROM intelligence.vw_ananse_customer_transaction_analysis
    WHERE year_month BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    ),
duration_sequences
AS (
    SELECT
        *
    FROM intelligence.vw_cip2pco_sequence_duration_score
    WHERE txn3_time >= '{START_DATE}'
            AND txn3_time < '{END_EXCLUSIVE}'
    ),
recurrence_sequences
AS (
    SELECT
        *
    FROM intelligence.vw_cip2pco_recurrence_score
    WHERE txn3_timestamp >= '{START_DATE}'
            AND txn3_timestamp < '{END_EXCLUSIVE}'
    ),
socr_sequences
AS (
    SELECT
        *
    FROM intelligence.vw_cip2pco_socr_score
    WHERE txn3_timestamp >= '{START_DATE}'
            AND txn3_timestamp < '{END_EXCLUSIVE}'
    ),
cip2pco_sequences
AS (
    SELECT
        d.ocb_customer_id,
        d.txn1_time AS cash_in_timestamp,
        d.txn2_time AS p2p_timestamp,
        d.txn3_time AS cash_out_timestamp,
        d.sequence_duration_mins,
        d.cip2pco_sequence_duration_score,
        r.recurrence_gap_minutes,
        r.cip2pco_recurrence_score,
        s.cash_in_value,
        s.p2p_value,
        s.cash_out_value,
        s.socr,
        s.cip2pco_socr_score
    FROM duration_sequences AS d
    LEFT JOIN recurrence_sequences AS r ON
            d.ocb_customer_id = r.ocb_customer_id
                AND d.txn1_time = r.txn1_timestamp
                AND d.txn2_time = r.txn2_timestamp
                AND d.txn3_time = r.txn3_timestamp
    LEFT JOIN socr_sequences AS s ON
            d.ocb_customer_id = s.ocb_customer_id
                AND d.txn1_time = s.txn1_timestamp
                AND d.txn2_time = s.txn2_timestamp
                AND d.txn3_time = s.txn3_timestamp
    )
SELECT
    s.ocb_customer_id,
    CONVERT(CHAR(7), s.cash_out_timestamp, 120) AS year_month,
    -- Customer-month monitoring metrics
    c.transaction_count_change,
    c.transaction_value_change,
    c.transaction_count_mom_change_pct,
    c.transaction_value_mom_change_pct,
    -- CIP2PCO sequence details
    s.cash_in_timestamp,
    s.p2p_timestamp,
    s.cash_out_timestamp,
    -- CIP2PCO signals
    s.sequence_duration_mins,
    s.cip2pco_sequence_duration_score,
    s.recurrence_gap_minutes,
    s.cip2pco_recurrence_score,
    s.socr,
    s.cip2pco_socr_score
FROM cip2pco_sequences AS s
INNER JOIN customer_population AS c ON
        s.ocb_customer_id = c.ocb_customer_id
ORDER BY c.transaction_value_change DESC,
    s.ocb_customer_id,
    s.cash_out_timestamp;
