WITH loan_balances
AS (
    SELECT
        l.loan_id,
        l.ocb_customer_id,
        l.principal_amount,
        l.maturity_date,
        l.principal_amount - COALESCE(SUM(r.repayment_amount), 0) AS outstanding_principal
    FROM gold.vw_loan l
    LEFT JOIN gold.vw_repayment r ON
            l.loan_id = r.loan_id
                AND r.repayment_timestamp < '2026-01-01'
    WHERE l.disbursement_timestamp < '2026-01-01'
    GROUP BY l.loan_id,
        l.ocb_customer_id,
        l.principal_amount,
        l.maturity_date
    ),
customer_summary
AS (
    SELECT
        ocb_customer_id,
        SUM(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN outstanding_principal
                ELSE 0
                END) AS post_maturity_outstanding,
        COUNT(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN loan_id
                END) AS post_maturity_loan_count,
        AVG(CASE 
                WHEN maturity_date < '2026-01-01'
                        AND outstanding_principal > 0
                    THEN outstanding_principal
                END) AS avg_post_maturity_outstanding
    FROM loan_balances
    GROUP BY ocb_customer_id
    )
SELECT TOP 10
    s.ocb_customer_id,
    s.post_maturity_outstanding,
    s.post_maturity_loan_count,
    s.avg_post_maturity_outstanding
FROM customer_summary s
WHERE s.post_maturity_outstanding > 0
ORDER BY s.post_maturity_outstanding DESC;
