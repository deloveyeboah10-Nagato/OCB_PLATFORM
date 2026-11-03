USE [ocb_platform];
GO

/*
===================================================================================================================================
### **WP5.3 — Cross-Institution Financial Behaviour**

Explore customers appearing across:

* Ananse Telecom
* SikaCredit
* Oman Remit

This includes:

- Institutional Participation Baseline
Who participates in one, two, or all three institutions.
- Institutional Combination Behaviour
What financial activity those participation groups generate.
- Activity Intensity by Participation Group
Whether multi-institution customers are individually more active within each domain.
- Cross-Institution Temporal Relationships
Whether activities across institutions occur close together in time.
====================================================================================================================================
*/
-- Institutional Participation Baseline
WITH all_customers
AS (
    SELECT DISTINCT
        ocb_customer_id,
        'ananse telecom' AS entity
    FROM gold.vw_transaction
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'sika credit' AS entity
    FROM gold.vw_loan
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'oman remit' AS entity
    FROM gold.vw_remittance
    ),
customer_flag
AS (
    SELECT
        ocb_customer_id,
        MAX(CASE 
                WHEN entity = 'ananse telecom'
                    THEN 1
                ELSE 0
                END) AS ananse_flag,
        MAX(CASE 
                WHEN entity = 'sika credit'
                    THEN 1
                ELSE 0
                END) AS sikacredit_flag,
        MAX(CASE 
                WHEN entity = 'oman remit'
                    THEN 1
                ELSE 0
                END) AS omanremit_flag
    FROM all_customers
    GROUP BY ocb_customer_id
    ),
customer_agg
AS (
    SELECT
        COUNT(CASE 
                WHEN ananse_flag = 1
                        AND sikacredit_flag = 0
                        AND omanremit_flag = 0
                    THEN '1'
                END) AS ananse_only,
        COUNT(CASE 
                WHEN ananse_flag = 0
                        AND sikacredit_flag = 1
                        AND omanremit_flag = 0
                    THEN '1'
                END) AS sikacredit_only,
        COUNT(CASE 
                WHEN ananse_flag = 0
                        AND sikacredit_flag = 0
                        AND omanremit_flag = 1
                    THEN '1'
                END) AS oman_remit_only,
        COUNT(CASE 
                WHEN ananse_flag = 1
                        AND sikacredit_flag = 1
                        AND omanremit_flag = 0
                    THEN '1'
                END) AS ananse_sikacredit_only,
        COUNT(CASE 
                WHEN ananse_flag = 1
                        AND sikacredit_flag = 0
                        AND omanremit_flag = 1
                    THEN '1'
                END) AS ananse_oman_remit_only,
        COUNT(CASE 
                WHEN ananse_flag = 0
                        AND sikacredit_flag = 1
                        AND omanremit_flag = 1
                    THEN '1'
                END) AS sikacredit_oman_remit_only,
        COUNT(CASE 
                WHEN ananse_flag = 1
                        AND sikacredit_flag = 1
                        AND omanremit_flag = 1
                    THEN '1'
                END) AS all_three
    FROM customer_flag
    ),
population_total
AS (
    SELECT
        ananse_only + sikacredit_only + oman_remit_only + ananse_sikacredit_only + ananse_oman_remit_only + sikacredit_oman_remit_only + all_three AS overall
    FROM customer_agg
    )
SELECT
    pt.overall,
    ca.ananse_only,
    ROUND(100.0 * CAST(ca.ananse_only AS FLOAT) / pt.overall, 2)                AS ananse_only_pct,
    ca.sikacredit_only,
    ROUND(100.0 * CAST(ca.sikacredit_only AS FLOAT) / pt.overall, 2)            AS sikacredit_only_pct,
    ca.oman_remit_only,
    ROUND(100.0 * CAST(ca.oman_remit_only AS FLOAT) / pt.overall, 2)            AS oman_remit_only_pct,
    ca.ananse_sikacredit_only,
    ROUND(100.0 * CAST(ca.ananse_sikacredit_only AS FLOAT) / pt.overall, 2)     AS ananse_sikacredit_only_pct,
    ca.ananse_oman_remit_only,
    ROUND(100.0 * CAST(ca.ananse_oman_remit_only AS FLOAT) / pt.overall, 2)     AS ananse_oman_remit_only_pct,
    ca.sikacredit_oman_remit_only,
    ROUND(100.0 * CAST(ca.sikacredit_oman_remit_only AS FLOAT) / pt.overall, 2) AS sikacredit_oman_remit_only_pct,
    ca.all_three,
    ROUND(100.0 * CAST(ca.all_three AS FLOAT) / pt.overall, 2)                  AS all_three_pct
FROM customer_agg ca
CROSS JOIN population_total pt;

-- Institutional Combination Behaviour
WITH all_customers
AS (
    SELECT DISTINCT
        ocb_customer_id,
        'ananse telecom' AS entity
    FROM gold.vw_transaction
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'sika credit' AS entity
    FROM gold.vw_loan
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'oman remit' AS entity
    FROM gold.vw_remittance
    ),
customer_flag
AS (
    SELECT
        ocb_customer_id,
        MAX(CASE 
                WHEN entity = 'ananse telecom'
                    THEN 1
                ELSE 0
                END) AS ananse_flag,
        MAX(CASE 
                WHEN entity = 'sika credit'
                    THEN 1
                ELSE 0
                END) AS sikacredit_flag,
        MAX(CASE 
                WHEN entity = 'oman remit'
                    THEN 1
                ELSE 0
                END) AS omanremit_flag
    FROM all_customers
    GROUP BY ocb_customer_id
    ),
customer_group
AS (
    SELECT
        ocb_customer_id,
        CASE 
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 0
                THEN 'ananse only'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 0
                THEN 'sika credit only'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 1
                THEN 'oman remit only'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 0
                THEN 'ananse + sika credit'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 1
                THEN 'ananse + oman remit'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 1
                THEN 'sika credit + oman remit'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 1
                THEN 'all three'
            END AS participation_group
    FROM customer_flag
    ),
transaction_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)                AS transaction_count,
        SUM(transaction_amount) AS total_transaction_value
    FROM gold.vw_transaction
    GROUP BY ocb_customer_id
    ),
loan_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)              AS loan_count,
        SUM(principal_amount) AS total_loan_principal
    FROM gold.vw_loan
    GROUP BY ocb_customer_id
    ),
repayment_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)              AS repayment_event_count,
        SUM(repayment_amount) AS total_repayment_value
    FROM gold.vw_repayment
    GROUP BY ocb_customer_id
    ),
remittance_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)               AS remittance_count,
        SUM(remittance_amount) AS total_remittance_value
    FROM gold.vw_remittance
    GROUP BY ocb_customer_id
    )
SELECT
    cg.participation_group,
    COUNT(*)                                     AS customer_count,
    SUM(COALESCE(ta.transaction_count, 0))       AS transaction_count,
    SUM(COALESCE(la.loan_count, 0))              AS loan_count,
    SUM(COALESCE(ra.repayment_event_count, 0))   AS repayment_event_count,
    SUM(COALESCE(rma.remittance_count, 0))       AS remittance_count,
    SUM(COALESCE(ta.total_transaction_value, 0)) AS total_transaction_value,
    SUM(COALESCE(la.total_loan_principal, 0))    AS total_loan_principal,
    SUM(COALESCE(ra.total_repayment_value, 0))   AS total_repayment_value,
    SUM(COALESCE(rma.total_remittance_value, 0)) AS total_remittance_value
FROM customer_group cg
LEFT JOIN transaction_activity ta ON
        cg.ocb_customer_id = ta.ocb_customer_id
LEFT JOIN loan_activity la ON
        cg.ocb_customer_id = la.ocb_customer_id
LEFT JOIN repayment_activity ra ON
        cg.ocb_customer_id = ra.ocb_customer_id
LEFT JOIN remittance_activity rma ON
        cg.ocb_customer_id = rma.ocb_customer_id
GROUP BY cg.participation_group
ORDER BY customer_count DESC;

-- Activity Intensity by Institutional Participation
WITH all_customers
AS (
    SELECT DISTINCT
        ocb_customer_id,
        'ananse telecom' AS entity
    FROM gold.vw_transaction
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'sika credit' AS entity
    FROM gold.vw_loan
    
    UNION ALL
    
    SELECT DISTINCT
        ocb_customer_id,
        'oman remit' AS entity
    FROM gold.vw_remittance
    ),
customer_flag
AS (
    SELECT
        ocb_customer_id,
        MAX(CASE 
                WHEN entity = 'ananse telecom'
                    THEN 1
                ELSE 0
                END) AS ananse_flag,
        MAX(CASE 
                WHEN entity = 'sika credit'
                    THEN 1
                ELSE 0
                END) AS sikacredit_flag,
        MAX(CASE 
                WHEN entity = 'oman remit'
                    THEN 1
                ELSE 0
                END) AS omanremit_flag
    FROM all_customers
    GROUP BY ocb_customer_id
    ),
participation_group
AS (
    SELECT
        ocb_customer_id,
        CASE 
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 0
                THEN 'ananse only'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 0
                THEN 'sika credit only'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 1
                THEN 'oman remit only'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 0
                THEN 'ananse + sika credit'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 0
                    AND omanremit_flag = 1
                THEN 'ananse + oman remit'
            WHEN ananse_flag = 0
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 1
                THEN 'sika credit + oman remit'
            WHEN ananse_flag = 1
                    AND sikacredit_flag = 1
                    AND omanremit_flag = 1
                THEN 'all three'
            END AS participation_group
    FROM customer_flag
    ),
transaction_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)                AS transaction_count,
        SUM(transaction_amount) AS transaction_value
    FROM gold.vw_transaction
    GROUP BY ocb_customer_id
    ),
loan_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)              AS loan_count,
        SUM(principal_amount) AS loan_principal
    FROM gold.vw_loan
    GROUP BY ocb_customer_id
    ),
repayment_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)              AS repayment_event_count,
        SUM(repayment_amount) AS repayment_value
    FROM gold.vw_repayment
    GROUP BY ocb_customer_id
    ),
remittance_activity
AS (
    SELECT
        ocb_customer_id,
        COUNT(*)               AS remittance_count,
        SUM(remittance_amount) AS remittance_value
    FROM gold.vw_remittance
    GROUP BY ocb_customer_id
    ),
customer_activity
AS (
    SELECT
        pg.ocb_customer_id,
        pg.participation_group,
        ta.transaction_count,
        ta.transaction_value,
        la.loan_count,
        la.loan_principal,
        ra.repayment_event_count,
        ra.repayment_value,
        rm.remittance_count,
        rm.remittance_value
    FROM participation_group pg
    LEFT JOIN transaction_activity ta ON
            pg.ocb_customer_id = ta.ocb_customer_id
    LEFT JOIN loan_activity la ON
            pg.ocb_customer_id = la.ocb_customer_id
    LEFT JOIN repayment_activity ra ON
            pg.ocb_customer_id = ra.ocb_customer_id
    LEFT JOIN remittance_activity rm ON
            pg.ocb_customer_id = rm.ocb_customer_id
    )
SELECT
    participation_group,
    COUNT(*) AS customer_count,
    SUM(CASE 
            WHEN transaction_count IS NOT NULL
                THEN 1
            ELSE 0
            END) AS transaction_customers,
    AVG(CASE 
            WHEN transaction_count IS NOT NULL
                THEN CAST(transaction_count AS FLOAT)
            END) AS avg_transactions_per_active_customer,
    AVG(CASE 
            WHEN transaction_count IS NOT NULL
                THEN transaction_value
            END) AS avg_transaction_value_per_active_customer,
    SUM(CASE 
            WHEN loan_count IS NOT NULL
                THEN 1
            ELSE 0
            END) AS loan_customers,
    AVG(CASE 
            WHEN loan_count IS NOT NULL
                THEN CAST(loan_count AS FLOAT)
            END) AS avg_loans_per_active_customer,
    AVG(CASE 
            WHEN loan_count IS NOT NULL
                THEN loan_principal
            END) AS avg_loan_principal_per_active_customer,
    SUM(CASE 
            WHEN repayment_event_count IS NOT NULL
                THEN 1
            ELSE 0
            END) AS repayment_customers,
    AVG(CASE 
            WHEN repayment_event_count IS NOT NULL
                THEN CAST(repayment_event_count AS FLOAT)
            END) AS avg_repayment_events_per_active_customer,
    AVG(CASE 
            WHEN repayment_event_count IS NOT NULL
                THEN repayment_value
            END) AS avg_repayment_value_per_active_customer,
    SUM(CASE 
            WHEN remittance_count IS NOT NULL
                THEN 1
            ELSE 0
            END) AS remittance_customers,
    AVG(CASE 
            WHEN remittance_count IS NOT NULL
                THEN CAST(remittance_count AS FLOAT)
            END) AS avg_remittances_per_active_customer,
    AVG(CASE 
            WHEN remittance_count IS NOT NULL
                THEN remittance_value
            END) AS avg_remittance_value_per_active_customer
FROM customer_activity
GROUP BY participation_group
ORDER BY CASE participation_group
        WHEN 'ananse only'
            THEN 1
        WHEN 'sika credit only'
            THEN 2
        WHEN 'oman remit only'
            THEN 3
        WHEN 'ananse + sika credit'
            THEN 4
        WHEN 'ananse + oman remit'
            THEN 5
        WHEN 'sika credit + oman remit'
            THEN 6
        WHEN 'all three'
            THEN 7
        END;

-- Cross-Institution Temporal Relationships
WITH customer_events
AS (
    SELECT
        ocb_customer_id,
        transaction_timestamp AS event_timestamp,
        'ananse transaction'  AS event_type
    FROM gold.vw_transaction
    
    UNION ALL
    
    SELECT
        ocb_customer_id,
        disbursement_timestamp,
        'sika credit loan'
    FROM gold.vw_loan
    
    UNION ALL
    
    SELECT
        ocb_customer_id,
        remittance_timestamp,
        'oman remit'
    FROM gold.vw_remittance
    
    UNION ALL
    
    SELECT
        ocb_customer_id,
        repayment_timestamp,
        'repayment'
    FROM gold.vw_repayment
    ),
sequenced_events
AS (
    SELECT
        ocb_customer_id,
        event_type,
        event_timestamp,
        LEAD(event_type) OVER (
            PARTITION BY ocb_customer_id ORDER BY event_timestamp
            ) AS next_event_type,
        LEAD(event_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY event_timestamp
            ) AS next_event_timestamp
    FROM customer_events
    ),
temporal_sequences
AS (
    SELECT
        CASE 
            WHEN event_type = 'ananse transaction'
                    AND next_event_type = 'sika credit loan'
                THEN 'ananse transaction -> sika credit loan'
            WHEN event_type = 'sika credit loan'
                    AND next_event_type = 'ananse transaction'
                THEN 'sika credit loan -> ananse transaction'
            WHEN event_type = 'ananse transaction'
                    AND next_event_type = 'oman remit'
                THEN 'ananse transaction -> oman remit'
            WHEN event_type = 'oman remit'
                    AND next_event_type = 'ananse transaction'
                THEN 'oman remit -> ananse transaction'
            WHEN event_type = 'sika credit loan'
                    AND next_event_type = 'repayment'
                THEN 'sika credit loan -> repayment'
            END AS relationship,
        ocb_customer_id,
        DATEDIFF(SECOND, event_timestamp, next_event_timestamp) / 86400.0 AS gap_days
    FROM sequenced_events
    WHERE (
            event_type = 'ananse transaction'
                AND next_event_type = 'sika credit loan'
            )
            OR (
            event_type = 'sika credit loan'
                AND next_event_type = 'ananse transaction'
            )
            OR (
            event_type = 'ananse transaction'
                AND next_event_type = 'oman remit'
            )
            OR (
            event_type = 'oman remit'
                AND next_event_type = 'ananse transaction'
            )
            OR (
            event_type = 'sika credit loan'
                AND next_event_type = 'repayment'
            )
    ),
temporal_statistics
AS (
    SELECT
        relationship,
        ocb_customer_id,
        gap_days,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY gap_days
            ) OVER (PARTITION BY relationship) AS p25_gap_days,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY gap_days
            ) OVER (PARTITION BY relationship) AS median_gap_days,
        AVG(gap_days) OVER (PARTITION BY relationship) AS average_gap_days,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY gap_days
            ) OVER (PARTITION BY relationship) AS p75_gap_days,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY gap_days
            ) OVER (PARTITION BY relationship) AS p90_gap_days
    FROM temporal_sequences
    )
SELECT
    relationship,
    COUNT(DISTINCT ocb_customer_id) AS customers_with_sequence,
    COUNT(*)                        AS qualifying_sequences,
    MIN(gap_days)                   AS min_gap_days,
    MIN(p25_gap_days)               AS p25_gap_days,
    MIN(median_gap_days)            AS median_gap_days,
    MIN(average_gap_days)           AS average_gap_days,
    MIN(p75_gap_days)               AS p75_gap_days,
    MIN(p90_gap_days)               AS p90_gap_days,
    MAX(gap_days)                   AS max_gap_days
FROM temporal_statistics
GROUP BY relationship
ORDER BY CASE relationship
        WHEN 'ananse transaction -> sika credit loan'
            THEN 1
        WHEN 'sika credit loan -> ananse transaction'
            THEN 2
        WHEN 'ananse transaction -> oman remit'
            THEN 3
        WHEN 'oman remit -> ananse transaction'
            THEN 4
        WHEN 'sika credit loan -> repayment'
            THEN 5
        END;
/*
WP5.3 — Cross-Institution Financial Behaviour
------------------------------------------------------------------------------------------------------------------------------------
NOTES
-----------------------------------------------------------------------------------------------------------------------------------
- Cross-institution analysis used canonical ocb_customer_id across Ananse Telecom, SikaCredit and Oman Remit, with financial
  participation defined from Gold activity rather than Silver identity records.
- 3,493 customers had observed financial activity across at least one institution. 142 of the 3,635 canonical OCB customers had no
  observed transaction, loan or remittance activity and were excluded from the active participation groups.
- Participation groups: Ananse only 2,590 (74.15%); SikaCredit only 222 (6.36%); Oman Remit only 274 (7.84%); Ananse + SikaCredit
  185 (5.30%); Ananse + Oman Remit 144 (4.12%); SikaCredit + Oman Remit only 0; all three 78 (2.23%). Single-institution
  participation therefore represented 3,086 customers (88.35%), while multi-institution participation represented 407 (11.65%).
- Institutional combination totals reconciled to the established Gold baselines: 772,381 transactions, GHS 1,304,283,653.37
  transaction value, 867 loans, GHS 1,112,318.94 loan principal, 2,683 repayment events, GHS 862,215.98 repayment value, and 12,591
  remittances, GHS 11,620,120.51 remittance value.
- Ananse + SikaCredit customers generated both transaction and lending/repayment activity; Ananse + Oman Remit customers generated
  transaction and remittance activity; all-three customers showed activity across all four financial domains. No customer belonged
  exclusively to SikaCredit + Oman Remit without Ananse.
- Customer-normalized activity did not show that multi-institution participation automatically corresponded to greater intensity
  within a financial domain. Ananse-only customers averaged 260.64 transactions and GHS 439,981.33 transaction value per active
  customer, compared with 247.22 and GHS 423,251.11 for Ananse + SikaCredit, 220.06 and GHS 368,284.17 for Ananse + Oman Remit, and
  255.14 and GHS 428,174.63 for all-three customers.
- Within SikaCredit-active groups, SikaCredit-only customers averaged 1.92 loans and GHS 2,482.49 principal per active customer,
  compared with 1.67 loans and GHS 2,094.39 for Ananse + SikaCredit and 1.69 loans and GHS 2,227.49 for all-three customers.
  Repayment activity showed the same broad pattern, with SikaCredit-only customers averaging 6.14 repayment events and GHS 1,990.27
  repayment value versus 5.31 and GHS 1,673.10 for Ananse + SikaCredit and 5.43 and GHS 1,772.45 for all-three customers.
- Within Oman Remit-active groups, Oman Remit-only customers averaged 27.24 remittances and GHS 24,901.76 remittance value per
  active customer, compared with 22.75 and GHS 21,236.93 for Ananse + Oman Remit and 23.74 and GHS 22,293.83 for all-three customers.
- Cross-institution temporal analysis examined the immediate next event in the combined customer timeline using LEAD(), avoiding the
  row explosion that would result from pairing every event with every later event.
- Ananse transaction -> SikaCredit loan: 227 customers, 352 qualifying sequences, median gap 2.47 days, P75 8.17 days, P90 21.15
  days.
- SikaCredit loan -> Ananse transaction: 212 customers, 316 qualifying sequences, median gap 1.90 days, P75 5.03 days, P90 10.10
  days.
- Ananse transaction -> Oman Remit: 220 customers, 2,858 qualifying sequences, median gap 1.69 days, P75 4.05 days, P90 9.47 days.
- Oman Remit -> Ananse transaction: 221 customers, 2,930 qualifying sequences, median gap 1.43 days, P75 4.12 days, P90 11.30 days.
- SikaCredit loan -> repayment: 310 customers, 514 qualifying sequences, median gap 16.89 days, P75 23.88 days, P90 32.94 days.
- Temporal relationships establish proximity and ordering only. They do not establish causality, financial dependency or risk.
------------------------------------------------------------------------------------------------------------------------------------
INTELLIGENCE SIGNALS
------------------------------------------------------------------------------------------------------------------------------------
1. Institutional participation signal — 11.65% of financially active customers participated across multiple institutions, while
    88.35% were observed in only one institution.
2. Cross-domain breadth signal — multi-institution customers provide observable activity across transaction, lending, repayment and
    remittance domains, creating a broader customer-level supervisory view.
3. Activity intensity signal — multi-institution participation does not automatically correspond to higher activity intensity within
    an individual financial domain; single-institution customers often showed higher domain-specific averages.
4. Cross-institution temporal proximity signal — Ananse/SikaCredit and Ananse/Oman Remit activities frequently occurred within days
    of one another among customers exhibiting the corresponding immediate-next-event relationship.
5. Repayment timing signal — loan-to-repayment activity occurred on a longer timescale, with a median observed gap of 16.89 days
    compared with approximately 1.43–2.47 days for the cross-institution transaction relationships.
6. Cross-domain surveillance opportunity — customers participating across institutions can be examined using combined transaction,
    lending, repayment and remittance evidence, but temporal proximity should be treated as an investigative signal rather than a
    causal or risk determination.
------------------------------------------------------------------------------------------------------------------------------------
CONCLUSION
------------------------------------------------------------------------------------------------------------------------------------
WP5.3 established the cross-institution financial behaviour of customers appearing across Ananse Telecom, SikaCredit and Oman Remit
The financially active population was predominantly single-institution, with 11.65% participating across multiple institutions.
Multi-institution customers demonstrated broader financial activity across domains but did not show systematically higher
customer-level intensity within those domains. Temporal analysis identified close chronological relationships between Ananse
transactions and both SikaCredit lending and Oman Remit activity, while loan-to-repayment activity occurred over a longer observed
interval. These findings establish cross-domain participation, activity intensity and temporal proximity as useful supervisory
intelligence dimensions. The temporal relationships are descriptive and do not establish causality or risk.
*/
