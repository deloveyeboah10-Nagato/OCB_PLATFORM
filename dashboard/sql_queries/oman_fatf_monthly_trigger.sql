SELECT
    CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
    COUNT(*) AS flagged_inbound_count,
    SUM(CASE WHEN remittance_status = 'successful' THEN remittance_amount ELSE 0 END) AS flagged_successful_value
FROM intelligence.vw_oman_remit_fatf_monitoring
WHERE remittance_origin_risk_flag = 1
  AND remittance_type = 'remittance_received'
GROUP BY CONVERT(CHAR(7), remittance_timestamp, 120)
ORDER BY year_month;
