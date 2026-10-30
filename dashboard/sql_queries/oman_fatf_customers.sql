-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

SELECT ocb_customer_id,
    CONVERT(CHAR(7), remittance_timestamp, 120) AS year_month,
    COUNT(*) AS flagged_origin_remittance_count,
    COUNT(CASE 
            WHEN remittance_status = 'successful'
                THEN 1
            END) AS successful_count,
    COUNT(CASE 
            WHEN remittance_status = 'failed'
                THEN 1
            END) AS failed_count,
    COUNT(CASE 
            WHEN remittance_status = 'rejected'
                THEN 1
            END) AS rejected_count,
    COALESCE(SUM(CASE 
                WHEN remittance_status = 'successful'
                    THEN remittance_amount
                END), 0) AS successful_amount,
    COALESCE(SUM(CASE 
                WHEN remittance_status = 'failed'
                    THEN remittance_amount
                END), 0) AS failed_amount,
    COALESCE(SUM(CASE 
                WHEN remittance_status = 'rejected'
                    THEN remittance_amount
                END), 0) AS rejected_amount
FROM intelligence.vw_oman_remit_fatf_monitoring
WHERE remittance_origin_risk_flag = 1
        AND remittance_type = 'remittance_received'
        AND remittance_timestamp >= '{START_DATE}'
        AND remittance_timestamp < '{END_EXCLUSIVE}'
GROUP BY ocb_customer_id, CONVERT(CHAR(7), remittance_timestamp, 120)
ORDER BY successful_amount DESC,
    successful_count DESC;
