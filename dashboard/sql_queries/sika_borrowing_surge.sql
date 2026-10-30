-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

SELECT
    ocb_customer_id,
    disbursement_timestamp,
    principal_amount,
    borrower_type,
    monthly_borrowing_frequency,
    reborrowing_rapidity_mad_score,
    debt_recycling_recurrence_mad_score
FROM intelligence.vw_sikacredit_borrowing_surge
WHERE disbursement_timestamp >= '{START_DATE}'
        AND disbursement_timestamp < '{END_EXCLUSIVE}'
ORDER BY ocb_customer_id,
    disbursement_timestamp;
