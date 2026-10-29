-- Source: WP-6.3-supervisory_intelligence_investigations.sql; query preserved from its matching investigation output.

SELECT
    *
FROM intelligence.vw_sikacredit_credit_escalation_customer_signals
WHERE CONVERT(CHAR(7), year_month, 120) BETWEEN '{START_MONTH}' AND '{END_MONTH}'
ORDER BY signal_count DESC,
    ocb_customer_id;
