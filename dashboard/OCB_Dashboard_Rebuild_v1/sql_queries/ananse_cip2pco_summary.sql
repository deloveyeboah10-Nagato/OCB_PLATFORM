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
        d.cip2pco_sequence_duration_score,
        r.cip2pco_recurrence_score,
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
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        COUNT(*) AS cip2pco_sequence_count,
        SUM(CASE 
                WHEN cip2pco_sequence_duration_score > 0
                    THEN 1
                ELSE 0
                END) AS duration_score_count,
        MAX(cip2pco_sequence_duration_score) AS max_duration_score,
        SUM(CASE 
                WHEN cip2pco_recurrence_score > 0
                    THEN 1
                ELSE 0
                END) AS recurrence_score_count,
        MAX(cip2pco_recurrence_score) AS max_recurrence_score,
        SUM(CASE 
                WHEN cip2pco_socr_score > 0
                    THEN 1
                ELSE 0
                END) AS socr_score_count,
        MAX(cip2pco_socr_score) AS max_socr_score
    FROM cip2pco_sequences
    GROUP BY ocb_customer_id
    )
SELECT
    t.ocb_customer_id,
    t.year_month,
    t.transaction_count_change,
    t.transaction_value_change,
    t.transaction_count_mom_change_pct,
    t.transaction_value_mom_change_pct,
    COALESCE(c.cip2pco_sequence_count, 0) AS cip2pco_sequence_count,
    COALESCE(c.duration_score_count, 0)   AS duration_score_count,
    c.max_duration_score,
    COALESCE(c.recurrence_score_count, 0) AS recurrence_score_count,
    c.max_recurrence_score,
    COALESCE(c.socr_score_count, 0)       AS socr_score_count,
    c.max_socr_score
FROM customer_population AS t
LEFT JOIN customer_summary AS c ON
        t.ocb_customer_id = c.ocb_customer_id
ORDER BY t.transaction_value_change DESC;
