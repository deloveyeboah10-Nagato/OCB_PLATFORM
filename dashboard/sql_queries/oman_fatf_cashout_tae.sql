-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH FATF_flag
AS (
    SELECT
        orf.ocb_customer_id,
        orf.remittance_id,
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
    WHERE orf.remittance_cashout_origin_risk_flag = 1
            AND orf.remittance_timestamp >= '{START_DATE}'
            AND orf.remittance_timestamp < '{END_EXCLUSIVE}'
            AND EXISTS (
            SELECT
                1
            FROM gold.vw_transaction t
            WHERE t.ocb_customer_id = orf.ocb_customer_id
                    AND t.transaction_id = orf.transaction_id
                    AND t.transaction_status = 'successful'
                    AND t.transaction_type = 'cash out'
            )
            AND EXISTS (
            SELECT
                1
            FROM gold.vw_remittance r
            WHERE r.ocb_customer_id = orf.ocb_customer_id
                    AND r.remittance_id = orf.remittance_id
                    AND r.remittance_type = 'remittance_received'
            )
    )
SELECT
    fl.ocb_customer_id,
    fl.remittance_id,
    fl.remittance_timestamp,
    fl.remittance_origin_country,
    fl.remittance_amount,
    fl.cash_out_timestamp,
    fl.cash_out_amt,
    fl.cash_out_to_remittance_ratio,
    fl.remittance_cashout_amt_score,
    fl.cash_out_delay_minutes,
    fl.remittance_cashout_rapidity_score,
    fl.recurrence_gap_minutes,
    fl.remittance_cashout_recurrence_score,
    fl.remittance_cashout_origin_risk_flag,
    ty.transaction_type_amount_score
FROM FATF_flag fl
INNER JOIN intelligence.vw_signal_transaction_type_score ty ON
        ty.ocb_customer_id = fl.ocb_customer_id
            AND ty.transaction_id = fl.transaction_id
            AND ty.transaction_type = 'cash out'
            AND ty.transaction_type_amount_score > 0;
