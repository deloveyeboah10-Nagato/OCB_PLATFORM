-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.


WITH february_repayments AS
(
    SELECT
        rp.ocb_customer_id,
        rp.loan_id,
        rp.repayment_timestamp,
        rp.repayment_amount
    FROM gold.vw_repayment AS rp
    WHERE rp.repayment_timestamp >= '{START_DATE}'
      AND rp.repayment_timestamp < '{END_EXCLUSIVE}'
)
SELECT
    f.ocb_customer_id,
    f.loan_id,
    f.repayment_timestamp,
    f.repayment_amount,
    rap.remittance_repayment_delay_minutes,
    rap.remittance_repayment_rapidity_score,
    val.repayment_correspondence_ratio,
    val.remittance_repayment_value_correspondence_score,
    rec.recurrence_gap_minutes,
    rec.inbound_remittance_to_repayment_recurrence_score
FROM february_repayments AS f
LEFT JOIN intelligence.vw_remittance_repayment_rapidity_score AS rap
    ON rap.ocb_customer_id = f.ocb_customer_id
   AND rap.repayment_timestamp = f.repayment_timestamp
LEFT JOIN intelligence.vw_remittance_repayment_value_correspondence_score AS val
    ON val.ocb_customer_id = f.ocb_customer_id
   AND val.repayment_timestamp = f.repayment_timestamp
LEFT JOIN intelligence.vw_remittance_repayment_recurrence_score AS rec
    ON rec.ocb_customer_id = f.ocb_customer_id
   AND rec.next_repayment_timestamp = f.repayment_timestamp
ORDER BY
    f.ocb_customer_id,
    f.repayment_timestamp;
