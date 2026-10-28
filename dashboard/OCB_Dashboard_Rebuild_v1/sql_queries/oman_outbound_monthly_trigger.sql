SELECT
    CONVERT(char(7), r.remittance_timestamp, 120) AS year_month,
    COUNT(*) AS outbound_remittance_count,
    COUNT(DISTINCT r.ocb_customer_id) AS distinct_customers,
    SUM(r.remittance_amount) AS outbound_remittance_value
FROM gold.vw_remittance AS r
WHERE r.remittance_type = 'remittance_sent'
  AND r.remittance_status = 'successful'
  AND r.remittance_timestamp >= '2023-01-01'
  AND r.remittance_timestamp < '2026-01-01'
GROUP BY CONVERT(char(7), r.remittance_timestamp, 120)
ORDER BY year_month;
