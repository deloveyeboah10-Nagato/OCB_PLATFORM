WITH q4_2024_outbound AS (
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
    rp.cash_in_id,
    rp.cash_in_timestamp,
    q.remittance_id,
    q.remittance_timestamp,
    rp.cashin_remittance_delay_minutes,
    rp.funding_remittance_rapidity_score,
    vc.funding_remittance_ratio,
    vc.funding_remittance_value_correspondence_score,
    rc.recurrence_gap_minutes,
    rc.funding_remittance_recurrence_score
FROM q4_2024_outbound AS q
LEFT JOIN intelligence.vw_cashin_remittance_rapidity_score AS rp
    ON rp.first_remittance_id = q.remittance_id
   AND rp.ocb_customer_id = q.ocb_customer_id
LEFT JOIN intelligence.vw_cashin_remittance_value_correspondence_score AS vc
    ON vc.ocb_customer_id = rp.ocb_customer_id
   AND vc.cash_in_id = rp.cash_in_id
   AND vc.cash_in_timestamp = rp.cash_in_timestamp
LEFT JOIN intelligence.vw_cashin_remittance_recurrence_score AS rc
    ON rc.ocb_customer_id = q.ocb_customer_id
   AND rc.next_remittance_id = q.remittance_id
WHERE rp.cash_in_id IS NOT NULL
ORDER BY
    q.ocb_customer_id,
    q.remittance_timestamp,
    q.remittance_id;
