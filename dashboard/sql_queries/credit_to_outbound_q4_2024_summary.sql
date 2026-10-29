-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH qualifying_sequences AS
(
    SELECT
        q.ocb_customer_id,
        rp.loan_id,
        q.remittance_id,
        rp.credit_to_remittance_rapidity_score,
        vc.credit_to_remittance_value_correspondence_score,
        rc.credit_to_remittance_recurrence_score
    FROM gold.vw_remittance AS q
    INNER JOIN intelligence.vw_credit_to_remittance_rapidity_score AS rp
        ON rp.remittance_id = q.remittance_id
       AND rp.ocb_customer_id = q.ocb_customer_id
    LEFT JOIN intelligence.vw_credit_to_remittance_value_correspondence_score AS vc
        ON vc.remittance_id = q.remittance_id
       AND vc.ocb_customer_id = q.ocb_customer_id
    LEFT JOIN intelligence.vw_credit_to_remittance_recurrence_score AS rc
        ON rc.next_remittance_id = q.remittance_id
       AND rc.ocb_customer_id = q.ocb_customer_id
    WHERE q.remittance_type = 'remittance_sent'
      AND q.remittance_status = 'successful'
      AND q.remittance_timestamp >= '2024-10-01'
      AND q.remittance_timestamp < '2025-01-01'
)
SELECT
    ocb_customer_id,
    COUNT(*) AS qualifying_sequence_count,
    SUM(CASE
        WHEN credit_to_remittance_rapidity_score > 0 THEN 1
        ELSE 0
    END) AS positive_rapidity_sequence_count,
    MAX(credit_to_remittance_rapidity_score) AS max_rapidity_score,
    SUM(CASE
        WHEN credit_to_remittance_value_correspondence_score > 0 THEN 1
        ELSE 0
    END) AS positive_value_correspondence_sequence_count,
    MAX(credit_to_remittance_value_correspondence_score) AS max_value_correspondence_score,
    SUM(CASE
        WHEN credit_to_remittance_recurrence_score > 0 THEN 1
        ELSE 0
    END) AS positive_recurrence_sequence_count,
    MAX(credit_to_remittance_recurrence_score) AS max_recurrence_score
FROM qualifying_sequences
GROUP BY ocb_customer_id
ORDER BY ocb_customer_id;
