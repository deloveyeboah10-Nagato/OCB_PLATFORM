WITH loan_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(l.principal_amount) AS total_principal_borrowed,
        COUNT(*)                AS loan_count,
        AVG(l.principal_amount) AS avg_loan_amount
    FROM gold.vw_loan l
    WHERE l.disbursement_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    ),
repayment_summary
AS (
    SELECT
        l.ocb_customer_id,
        SUM(r.repayment_amount) AS total_repaid,
        COUNT(*)                AS repayment_count,
        AVG(r.repayment_amount) AS avg_repayment_amount
    FROM gold.vw_repayment r
    INNER JOIN gold.vw_loan l ON
            r.loan_id = l.loan_id
    WHERE r.repayment_timestamp < '2026-01-01'
    GROUP BY l.ocb_customer_id
    )
SELECT TOP 10
    l.ocb_customer_id,
    l.total_principal_borrowed - COALESCE(r.total_repaid, 0) AS total_outstanding_principal,
    l.total_principal_borrowed,
    l.loan_count,
    l.avg_loan_amount,
    COALESCE(r.total_repaid, 0)                              AS total_repaid,
    COALESCE(r.repayment_count, 0)                           AS repayment_count,
    r.avg_repayment_amount
FROM loan_summary l
LEFT JOIN repayment_summary r ON
        l.ocb_customer_id = r.ocb_customer_id
WHERE l.total_principal_borrowed - COALESCE(r.total_repaid, 0) > 0
ORDER BY total_outstanding_principal DESC;
