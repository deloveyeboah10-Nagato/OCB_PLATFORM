-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

SELECT ocb_customer_id,
    CONVERT(CHAR(7), disbursement_timestamp, 120) AS year_month,
    SUM(principal_amount)                         AS principal_disbursed,
    COUNT(*)                                      AS principal_disbursed_count
FROM gold.vw_loan
WHERE CONVERT(CHAR(7), disbursement_timestamp, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
GROUP BY ocb_customer_id,
    CONVERT(CHAR(7), disbursement_timestamp, 120)
ORDER BY principal_disbursed DESC;
