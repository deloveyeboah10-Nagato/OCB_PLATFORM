-- Adapted from WP-6.3-supervisory_intelligence_investigations.sql; report window applied and TOP 50 cap removed.

SELECT ocb_customer_id,
    year_month,
    previous_transaction_count   AS november_transaction_count,
    total_transaction_count      AS december_transaction_count,
    transaction_count_mom_change AS transaction_count_change,
    previous_transaction_value   AS november_transaction_value,
    total_transaction_value      AS december_transaction_value,
    transaction_value_mom_change AS transaction_value_change,
    transaction_count_mom_change_pct,
    transaction_value_mom_change_pct
FROM intelligence.vw_ananse_customer_transaction_analysis
WHERE year_month BETWEEN '{START_MONTH}' AND '{END_MONTH}'
ORDER BY transaction_value_mom_change DESC;
