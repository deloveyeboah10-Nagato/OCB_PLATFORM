WITH q4_2024_outbound AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        r.remittance_origin_country
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_sent'
      AND r.remittance_status = 'successful'
      AND r.remittance_timestamp >= ?
      AND r.remittance_timestamp < ?
)
SELECT
    q.ocb_customer_id,
    rp.loan_id,
    rp.loan_timestamp,
    q.remittance_id,
    q.remittance_timestamp,
    rp.credit_to_remittance_rapidity_score,
    vc.credit_to_remittance_value_correspondence_score,
    rc.credit_to_remittance_recurrence_score
FROM q4_2024_outbound AS q
LEFT JOIN intelligence.vw_credit_to_remittance_rapidity_score AS rp
    ON rp.remittance_id = q.remittance_id
   AND rp.ocb_customer_id = q.ocb_customer_id
LEFT JOIN intelligence.vw_credit_to_remittance_value_correspondence_score AS vc
    ON vc.remittance_id = q.remittance_id
   AND vc.ocb_customer_id = q.ocb_customer_id
LEFT JOIN intelligence.vw_credit_to_remittance_recurrence_score AS rc
    ON rc.next_remittance_id = q.remittance_id
   AND rc.ocb_customer_id = q.ocb_customer_id
WHERE rp.loan_id IS NOT NULL
ORDER BY
    q.ocb_customer_id,
    q.remittance_timestamp,
    q.remittance_id;
