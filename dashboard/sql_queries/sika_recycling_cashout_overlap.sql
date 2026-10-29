-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

WITH customer_population
AS (
    SELECT ocb_customer_id,
        CONVERT(CHAR(7), disbursement_timestamp, 120) AS year_month,
        SUM(principal_amount)                         AS principal_disbursed,
        COUNT(*)                                      AS principal_disbursed_count
    FROM gold.vw_loan
    WHERE CONVERT(CHAR(7), disbursement_timestamp, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    GROUP BY ocb_customer_id,
        CONVERT(CHAR(7), disbursement_timestamp, 120)
    ),
amount_ratio_score
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        transaction_id,
        cash_out_amt,
        cash_out_to_loan_ratio,
        amount_ratio_score
    FROM intelligence.vw_loan_cashout_amount_ratio_score
    WHERE CONVERT(CHAR(7), disbursement_timestamp, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    ),
rapidity_score
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        transaction_id,
        cash_out_delay_minutes,
        loan_cashout_rapidity_score
    FROM intelligence.vw_loan_cashout_rapidity_score
    WHERE CONVERT(CHAR(7), disbursement_timestamp, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    ),
recurrence_score
AS (
    SELECT
        ocb_customer_id,
        next_sequence_loan_id,
        next_sequence_loan_timestamp,
        recurrence_gap_minutes,
        loan_cashout_recurrence_score
    FROM intelligence.vw_loan_cashout_recurrence_score
    WHERE CONVERT(CHAR(7), next_sequence_loan_timestamp, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
    ),
loan_cashout_signals
AS (
    SELECT
        ar.ocb_customer_id,
        ar.loan_id,
        ar.disbursement_timestamp,
        ar.transaction_id,
        ar.cash_out_amt,
        ar.cash_out_to_loan_ratio,
        ar.amount_ratio_score,
        ra.cash_out_delay_minutes,
        ra.loan_cashout_rapidity_score,
        re.recurrence_gap_minutes,
        re.loan_cashout_recurrence_score
    FROM amount_ratio_score ar
    LEFT JOIN rapidity_score ra ON
            ar.ocb_customer_id = ra.ocb_customer_id
                AND ar.loan_id = ra.loan_id
                AND ar.disbursement_timestamp = ra.disbursement_timestamp
    LEFT JOIN recurrence_score re ON
            ar.ocb_customer_id = re.ocb_customer_id
                AND ar.loan_id = re.next_sequence_loan_id
                AND ar.disbursement_timestamp = re.next_sequence_loan_timestamp
    INNER JOIN gold.vw_transaction t ON
            ar.transaction_id = t.transaction_id
                AND t.transaction_status = 'successful'
    )
SELECT
    t50.ocb_customer_id,
    t50.principal_disbursed,
    dr.reborrowing_rapidity_flag,
    dr.recycling_recurrence_flag,
    dr.repayment_deficiency_flag,
    COUNT(CASE 
            WHEN lc.amount_ratio_score > 0
                THEN 1
            END) AS elevated_amount_ratio_signal_count,
    COUNT(CASE 
            WHEN lc.loan_cashout_rapidity_score > 0
                THEN 1
            END) AS elevated_rapidity_signal_count,
    COUNT(CASE 
            WHEN lc.loan_cashout_recurrence_score > 0
                THEN 1
            END) AS elevated_recurrence_signal_count,
    COALESCE(dr.reborrowing_rapidity_flag, 0) + COALESCE(dr.recycling_recurrence_flag, 0) + COALESCE(dr.repayment_deficiency_flag, 0) + COUNT(CASE 
            WHEN lc.amount_ratio_score > 0
                THEN 1
            END) + COUNT(CASE 
            WHEN lc.loan_cashout_rapidity_score > 0
                THEN 1
            END) + COUNT(CASE 
            WHEN lc.loan_cashout_recurrence_score > 0
                THEN 1
            END) AS total_signal_count
FROM customer_population t50
LEFT JOIN loan_cashout_signals lc ON
        t50.ocb_customer_id = lc.ocb_customer_id
            AND t50.year_month = CONVERT(CHAR(7), lc.disbursement_timestamp, 120)
LEFT JOIN intelligence.vw_sikacredit_debt_recycling_customer_signals dr ON
        t50.ocb_customer_id = dr.ocb_customer_id
            AND t50.year_month = dr.year_month
GROUP BY t50.year_month,
    t50.ocb_customer_id,
    t50.principal_disbursed,
    t50.principal_disbursed_count,
    dr.reborrowing_rapidity_flag,
    dr.recycling_recurrence_flag,
    dr.repayment_deficiency_flag
ORDER BY t50.principal_disbursed DESC;
