-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH q4_2024_outbound AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount
    FROM gold.vw_remittance AS r
    WHERE r.remittance_status = 'successful'
      AND r.remittance_type = 'remittance_sent'
      AND r.remittance_timestamp >= '2024-10-01'
      AND r.remittance_timestamp <  '2025-01-01'
),
qualifying_sequences AS (
    SELECT
        q.ocb_customer_id,
        q.remittance_id,

        rp.cash_in_id,
        rp.funding_remittance_rapidity_score,

        vc.funding_remittance_value_correspondence_score,

        rc.funding_remittance_recurrence_score
    FROM q4_2024_outbound AS q

    INNER JOIN intelligence.vw_cashin_remittance_rapidity_score AS rp
        ON rp.ocb_customer_id = q.ocb_customer_id
       AND rp.first_remittance_id = q.remittance_id

    LEFT JOIN intelligence.vw_cashin_remittance_value_correspondence_score AS vc
        ON vc.ocb_customer_id = q.ocb_customer_id
       AND q.remittance_timestamp >= vc.cash_in_timestamp
       AND (
            vc.next_cash_in_timestamp IS NULL
            OR q.remittance_timestamp < vc.next_cash_in_timestamp
       )

    LEFT JOIN intelligence.vw_cashin_remittance_recurrence_score AS rc
        ON rc.ocb_customer_id = q.ocb_customer_id
       AND rc.next_remittance_id = q.remittance_id
)
SELECT
    ocb_customer_id,

    COUNT(*) AS qualifying_sequence_count,

    SUM(CASE
        WHEN funding_remittance_rapidity_score > 0 THEN 1
        ELSE 0
    END) AS positive_rapidity_signal_count,

    SUM(CASE
        WHEN funding_remittance_value_correspondence_score > 0 THEN 1
        ELSE 0
    END) AS positive_value_correspondence_signal_count,

    SUM(CASE
        WHEN funding_remittance_recurrence_score > 0 THEN 1
        ELSE 0
    END) AS positive_recurrence_signal_count,

    MAX(funding_remittance_rapidity_score)
        AS max_rapidity_score,

    MAX(funding_remittance_value_correspondence_score)
        AS max_value_correspondence_score,

    MAX(funding_remittance_recurrence_score)
        AS max_recurrence_score

FROM qualifying_sequences
GROUP BY ocb_customer_id
ORDER BY qualifying_sequence_count DESC, ocb_customer_id;
