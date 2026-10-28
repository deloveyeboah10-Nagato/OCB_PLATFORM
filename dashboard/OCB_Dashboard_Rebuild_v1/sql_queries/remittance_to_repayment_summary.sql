-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

WITH february_repayments AS
(
    SELECT
        rp.ocb_customer_id,
        rp.repayment_timestamp
    FROM gold.vw_repayment AS rp
    WHERE rp.repayment_timestamp >= '{START_DATE}'
      AND rp.repayment_timestamp < '{END_EXCLUSIVE}'
),
rapidity_by_customer AS
(
    SELECT
        f.ocb_customer_id,
        COUNT(*) AS rapidity_sequence_count,
        SUM(CASE WHEN rap.remittance_repayment_rapidity_score > 0 THEN 1 ELSE 0 END)
            AS rapidity_positive_sequence_count,
        MAX(rap.remittance_repayment_rapidity_score) AS rapidity_max_score
    FROM february_repayments AS f
    INNER JOIN intelligence.vw_remittance_repayment_rapidity_score AS rap
        ON rap.ocb_customer_id = f.ocb_customer_id
       AND rap.repayment_timestamp = f.repayment_timestamp
    GROUP BY f.ocb_customer_id
),
value_correspondence_by_customer AS
(
    SELECT
        f.ocb_customer_id,
        COUNT(*) AS value_correspondence_sequence_count,
        SUM(CASE WHEN val.remittance_repayment_value_correspondence_score > 0 THEN 1 ELSE 0 END)
            AS value_correspondence_positive_sequence_count,
        MAX(val.remittance_repayment_value_correspondence_score)
            AS value_correspondence_max_score
    FROM february_repayments AS f
    INNER JOIN intelligence.vw_remittance_repayment_value_correspondence_score AS val
        ON val.ocb_customer_id = f.ocb_customer_id
       AND val.repayment_timestamp = f.repayment_timestamp
    GROUP BY f.ocb_customer_id
),
recurrence_by_customer AS
(
    SELECT
        f.ocb_customer_id,
        COUNT(*) AS recurrence_sequence_count,
        SUM(CASE WHEN rec.inbound_remittance_to_repayment_recurrence_score > 0 THEN 1 ELSE 0 END)
            AS recurrence_positive_sequence_count,
        MAX(rec.inbound_remittance_to_repayment_recurrence_score)
            AS recurrence_max_score
    FROM february_repayments AS f
    INNER JOIN intelligence.vw_remittance_repayment_recurrence_score AS rec
        ON rec.ocb_customer_id = f.ocb_customer_id
       AND rec.next_repayment_timestamp = f.repayment_timestamp
    GROUP BY f.ocb_customer_id
)
SELECT
    c.ocb_customer_id,
    COALESCE(rap.rapidity_sequence_count, 0) AS rapidity_sequence_count,
    COALESCE(rap.rapidity_positive_sequence_count, 0) AS rapidity_positive_sequence_count,
    rap.rapidity_max_score,
    COALESCE(val.value_correspondence_sequence_count, 0) AS value_correspondence_sequence_count,
    COALESCE(val.value_correspondence_positive_sequence_count, 0) AS value_correspondence_positive_sequence_count,
    val.value_correspondence_max_score,
    COALESCE(rec.recurrence_sequence_count, 0) AS recurrence_sequence_count,
    COALESCE(rec.recurrence_positive_sequence_count, 0) AS recurrence_positive_sequence_count,
    rec.recurrence_max_score
FROM
(
    SELECT DISTINCT ocb_customer_id
    FROM february_repayments
) AS c
LEFT JOIN rapidity_by_customer AS rap
    ON rap.ocb_customer_id = c.ocb_customer_id
LEFT JOIN value_correspondence_by_customer AS val
    ON val.ocb_customer_id = c.ocb_customer_id
LEFT JOIN recurrence_by_customer AS rec
    ON rec.ocb_customer_id = c.ocb_customer_id
ORDER BY
    COALESCE(rap.rapidity_positive_sequence_count, 0) DESC,
    COALESCE(val.value_correspondence_positive_sequence_count, 0) DESC,
    COALESCE(rec.recurrence_positive_sequence_count, 0) DESC;
