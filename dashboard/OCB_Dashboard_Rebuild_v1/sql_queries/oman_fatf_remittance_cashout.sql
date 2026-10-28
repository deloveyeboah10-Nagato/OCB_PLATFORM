-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH remittance_cashout_signals
AS (
    SELECT
        orf.ocb_customer_id,
        orf.remittance_id,
        CONVERT(CHAR(7), orf.remittance_timestamp, 120) AS year_month,
        orf.remittance_timestamp,
        orf.remittance_amount,
        orf.remittance_origin_country,
        orf.transaction_id,
        orf.cash_out_timestamp,
        orf.cash_out_amt,
        orf.remittance_cashout_origin_risk_flag,
        a.cash_out_to_remittance_ratio,
        a.remittance_cashout_amt_score,
        ra.cash_out_delay_minutes,
        ra.remittance_cashout_rapidity_score,
        re.recurrence_gap_minutes,
        re.remittance_cashout_recurrence_score
    FROM intelligence.remittance_cashout_origin_risk_flag orf
    LEFT JOIN intelligence.remittance_cashout_amt_score a ON
            a.ocb_customer_id = orf.ocb_customer_id
                AND a.remittance_id = orf.remittance_id
    LEFT JOIN intelligence.remittance_cashout_rapidity_score ra ON
            ra.ocb_customer_id = orf.ocb_customer_id
                AND ra.remittance_id = orf.remittance_id
    LEFT JOIN intelligence.vw_remittance_cashout_recurrence_score re ON
            re.ocb_customer_id = orf.ocb_customer_id
                AND re.next_sequence_remittance_timestamp = orf.remittance_timestamp
    )
SELECT
    rc.*
FROM remittance_cashout_signals rc
INNER JOIN gold.vw_transaction t ON
        rc.ocb_customer_id = t.ocb_customer_id
            AND rc.transaction_id = t.transaction_id
INNER JOIN gold.vw_remittance r ON
        rc.ocb_customer_id = r.ocb_customer_id
            AND rc.remittance_id = r.remittance_id
WHERE rc.remittance_cashout_origin_risk_flag = 1
        AND rc.year_month BETWEEN '{START_MONTH}' AND '{END_MONTH}'
        AND t.transaction_status = 'successful'
        AND r.remittance_type = 'remittance_received';
