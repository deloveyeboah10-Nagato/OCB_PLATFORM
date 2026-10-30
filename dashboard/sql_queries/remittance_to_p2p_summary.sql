-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH fatf_flagged_remittances AS
(
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
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
        ra.inbound_remittance_to_p2p_rapidity_score,
        vc.inbound_remittance_to_p2p_value_correspondence_score,
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
    CONVERT(CHAR(7), s.remittance_timestamp, 120) AS year_month,
    COUNT(DISTINCT s.remittance_id) AS sequence_count,

    SUM(CASE
        WHEN s.inbound_remittance_to_p2p_rapidity_score > 0 THEN 1
        ELSE 0
    END) AS rapidity_positive_count,

    MAX(s.inbound_remittance_to_p2p_rapidity_score)
        AS rapidity_max_score,

    SUM(CASE
        WHEN s.inbound_remittance_to_p2p_value_correspondence_score > 0 THEN 1
        ELSE 0
    END) AS value_correspondence_positive_count,

    MAX(s.inbound_remittance_to_p2p_value_correspondence_score)
        AS value_correspondence_max_score,

    SUM(CASE
        WHEN s.inbound_remittance_to_p2p_recurrence_score > 0 THEN 1
        ELSE 0
    END) AS recurrence_positive_count,

    MAX(s.inbound_remittance_to_p2p_recurrence_score)
        AS recurrence_max_score

FROM remittance_p2p_signals AS s

INNER JOIN fatf_flagged_remittances AS f
    ON f.ocb_customer_id = s.ocb_customer_id
   AND f.remittance_id = s.remittance_id
   AND f.remittance_timestamp = s.remittance_timestamp

WHERE s.first_p2p_transfer_id IS NOT NULL

GROUP BY
    s.ocb_customer_id,
    CONVERT(CHAR(7), s.remittance_timestamp, 120)

ORDER BY
    sequence_count DESC,
    s.ocb_customer_id;
