-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH fatf_flagged_remittances AS
(
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        remittance_origin_country,
        remittance_status,
        remittance_type,
        remittance_origin_risk_flag
    FROM intelligence.vw_oman_remit_fatf_monitoring
    WHERE remittance_origin_risk_flag = 1
      AND remittance_type = 'remittance_received'
      AND remittance_status = 'successful'
      AND remittance_timestamp >= '{START_DATE}'
      AND remittance_timestamp < '{END_EXCLUSIVE}'
),
remittance_p2p_signals AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        ra.first_p2p_transfer_id,
        r.remittance_amount,
        r.remittance_origin_country,
        ra.elapsed_minutes,
        ra.inbound_remittance_to_p2p_rapidity_score,
        vc.p2p_to_remittance_value_ratio,
        vc.inbound_remittance_to_p2p_value_correspondence_score,
        re.recurrence_interval_minutes,
        re.inbound_remittance_to_p2p_recurrence_score

    FROM gold.vw_remittance AS r

    LEFT JOIN intelligence.vw_remittance_p2p_rapidity_score AS ra
        ON ra.ocb_customer_id = r.ocb_customer_id
       AND ra.remittance_id = r.remittance_id

    LEFT JOIN intelligence.vw_remittance_p2p_value_correspondence_score AS vc
        ON vc.ocb_customer_id = r.ocb_customer_id
       AND vc.remittance_id = r.remittance_id

    LEFT JOIN intelligence.vw_remittance_p2p_recurrence_score AS re
        ON re.ocb_customer_id = r.ocb_customer_id
       AND re.sequence_1_remittance_id = r.remittance_id

    WHERE r.remittance_type = 'remittance_received'
      AND r.remittance_status = 'successful'
      AND r.remittance_timestamp >= '{START_DATE}'
      AND r.remittance_timestamp < '{END_EXCLUSIVE}'
)
SELECT
    s.ocb_customer_id,
    s.remittance_id,
    s.remittance_timestamp,
    s.remittance_amount,
    s.first_p2p_transfer_id,
    s.remittance_origin_country,
    f.remittance_origin_risk_flag,
    s.elapsed_minutes,
    s.inbound_remittance_to_p2p_rapidity_score,
    s.p2p_to_remittance_value_ratio,
    s.inbound_remittance_to_p2p_value_correspondence_score,
    s.recurrence_interval_minutes,
    s.inbound_remittance_to_p2p_recurrence_score

FROM remittance_p2p_signals AS s

INNER JOIN fatf_flagged_remittances AS f
    ON f.ocb_customer_id = s.ocb_customer_id
   AND f.remittance_id = s.remittance_id
   AND f.remittance_timestamp = s.remittance_timestamp

WHERE s.first_p2p_transfer_id IS NOT NULL
ORDER BY
    s.ocb_customer_id;
