USE [ocb_platform];
GO

/*
====================================================================================================================================
### **P5.2.1 — Lending Portfolio Behaviour**

**SikaCredit**

Explore:
* loan volume and value
* principal distribution
* number of loans per customer
* repeat borrowing
* borrowing frequency
* cumulative borrowing value
* average loan size
* loan timing/seasonality
* loan duration/maturity characteristics
* borrowing activity over time
* changes in customer borrowing patterns
* customer concentration
* loan geographic dimensions where useful
* changes in lending activity over time

**Purpose:** establish the structure of the SikaCredit lending population.
====================================================================================================================================
*/
-- distinct population analysis
SELECT DISTINCT
    vl.customer_id
FROM gold.vw_loan vl;

SELECT DISTINCT
    vl.disbursement_location_region
FROM gold.vw_loan vl;

SELECT DISTINCT
    vl.disbursement_location_town
FROM gold.vw_loan vl;

-- portfolio-level baseline
WITH portfolio_level_baseline
AS (
    SELECT
        COUNT(DISTINCT vl.customer_id) AS distinct_customers,
        COUNT(*)                       AS total_loan_volume,
        SUM(vl.principal_amount)       AS total_principal_value,
        AVG(vl.principal_amount)       AS avg_principal_value,
        MIN(vl.principal_amount)       AS min_principal_value,
        MAX(vl.principal_amount)       AS max_principal_value,
        MIN(disbursement_timestamp)    AS observation_start_date,
        MAX(disbursement_timestamp)    AS observation_end_date
    FROM gold.vw_loan vl
    )
SELECT DISTINCT
    pb.distinct_customers,
    pb.total_loan_volume,
    pb.total_principal_value,
    pb.avg_principal_value,
    pb.min_principal_value,
    pb.max_principal_value,
    pb.observation_start_date,
    pb.observation_end_date,
    PERCENTILE_CONT(0.25) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS p25,
    PERCENTILE_CONT(0.5) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS median,
    PERCENTILE_CONT(0.75) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS p75,
    PERCENTILE_CONT(0.90) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS p90,
    PERCENTILE_CONT(0.95) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS p95,
    PERCENTILE_CONT(0.99) WITHIN
GROUP (
        ORDER BY vl.principal_amount
        ) OVER () AS p99
FROM gold.vw_loan vl
CROSS JOIN portfolio_level_baseline pb;

-- loan duration to maturity
WITH contractual_duration
AS (
    SELECT
        vl.loan_id,
        vl.customer_id,
        vl.principal_amount,
        vl.disbursement_timestamp,
        vl.maturity_date,
        DATEDIFF(DAY, disbursement_timestamp, maturity_date) AS loan_duration_days
    FROM gold.vw_loan vl
    ),
quartile_analysis
AS (
    SELECT DISTINCT
        MIN(loan_duration_days) OVER () AS min_duration_population,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS p25_population,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS median_population,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS p75_population,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS p90_population,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS p95_population,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY loan_duration_days
            ) OVER () AS p99_population,
        MAX(loan_duration_days) OVER () AS max_duration_population,
        AVG(loan_duration_days) OVER () AS avg_duration_population
    FROM contractual_duration
    )
SELECT
    cd.*,
    qa.*
FROM contractual_duration cd
CROSS JOIN quartile_analysis qa;

-- inter-loan interval profile
WITH previous_loan_timestamp
AS (
    SELECT
        vl.loan_id,
        vl.customer_id,
        vl.principal_amount,
        vl.disbursement_timestamp,
        LAG(disbursement_timestamp, 1) OVER (
            PARTITION BY customer_id ORDER BY disbursement_timestamp
            ) AS previous_timestmp
    FROM gold.vw_loan vl
    ),
inter_loan_interval
AS (
    SELECT
        customer_id,
        loan_id,
        principal_amount,
        previous_timestmp,
        disbursement_timestamp,
        DATEDIFF_BIG(SECOND, previous_timestmp, disbursement_timestamp) / 86400.00 AS days_from_previous_loan
    FROM previous_loan_timestamp
    WHERE previous_timestmp IS NOT NULL
    ),
quartile_analysis
AS (
    SELECT TOP 1
        MIN(days_from_previous_loan) OVER () AS min_interval_population,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS p25_population,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS median_population,
        AVG(days_from_previous_loan) OVER () AS avg_interval_population,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS p75_population,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS p90_population,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS p95_population,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY days_from_previous_loan
            ) OVER () AS p99_population,
        MAX(days_from_previous_loan) OVER () AS max_interval_population
    FROM inter_loan_interval
    )
SELECT
    li.*,
    qa.*
FROM inter_loan_interval li
CROSS JOIN quartile_analysis qa;

-- customer borrowing span
WITH first_last_loan
AS (
    SELECT
        vl.customer_id,
        COUNT(*)                       AS total_loan_volume,
        SUM(vl.principal_amount)       AS total_loan_value,
        MIN(vl.disbursement_timestamp) AS first_loan_date,
        MAX(vl.disbursement_timestamp) AS latest_loan_date
    FROM gold.vw_loan vl
    GROUP BY vl.customer_id
    ),
borrowing_span
AS (
    SELECT
        *,
        DATEDIFF_BIG(SECOND, first_loan_date, latest_loan_date) / 86400.00 AS observed_borrowing_span_days
    FROM first_last_loan
    WHERE DATEDIFF_BIG(SECOND, first_loan_date, latest_loan_date) / 86400.00 > 0
    ),
quartile_analysis
AS (
    SELECT TOP 1
        MIN(observed_borrowing_span_days) OVER () AS min_borrowing_span_population,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS p25_population,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS median_population,
        AVG(observed_borrowing_span_days) OVER () AS avg_borrowing_span_population,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS p75_population,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS p90_population,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS p95_population,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY observed_borrowing_span_days
            ) OVER () AS p99_population,
        MAX(observed_borrowing_span_days) OVER () AS max_borrowing_span_population
    FROM borrowing_span
    )
SELECT
    bs.*,
    qa.*
FROM borrowing_span bs
CROSS JOIN quartile_analysis qa;

-- quarter-year loan disbursement profile
WITH loan_qrtr_aggregation
AS (
    SELECT
        YEAR(vl.disbursement_timestamp)              AS loan_yr,
        DATEPART(QUARTER, vl.disbursement_timestamp) AS loan_qrtr,
        COUNT(DISTINCT customer_id)                  AS distinct_customers,
        COUNT(*)                                     AS quarterly_loan_volume,
        SUM(vl.principal_amount)                     AS quarterly_loan_value,
        AVG(vl.principal_amount)                     AS quarterly_avg_value
    FROM gold.vw_loan vl
    GROUP BY YEAR(vl.disbursement_timestamp),
        DATEPART(QUARTER, vl.disbursement_timestamp)
    )
SELECT
    *,
    SUM(quarterly_loan_volume) OVER (PARTITION BY loan_yr)                                                         AS yearly_loan_volume,
    SUM(quarterly_loan_value) OVER (PARTITION BY loan_yr)                                                          AS yearly_loan_value,
    AVG(quarterly_avg_value) OVER (PARTITION BY loan_yr)                                                           AS yearly_avg_value,
    ROUND(100.00 * CAST(quarterly_loan_value AS FLOAT) / SUM(quarterly_loan_value) OVER (PARTITION BY loan_yr), 2) AS qrtr_loan_distribution
FROM loan_qrtr_aggregation
ORDER BY loan_yr ASC,
    loan_qrtr ASC;

-- borrowing activity over time
SELECT
    YEAR(vl.disbursement_timestamp) AS loan_yr,
    COUNT(DISTINCT vl.customer_id)  AS active_customers,
    COUNT(*)                        AS total_loan_volume,
    SUM(vl.principal_amount)        AS total_loan_value,
    AVG(vl.principal_amount)        AS avg_loan_value,
    ROUND(CAST(COUNT(*) AS FLOAT) / COUNT(DISTINCT vl.customer_id), 2) avg_loan_volume_per_active_customer,
    ROUND(CAST(SUM(vl.principal_amount) AS FLOAT) / COUNT(DISTINCT vl.customer_id), 2) avg_loan_value_per_active_customer
FROM gold.vw_loan vl
GROUP BY YEAR(vl.disbursement_timestamp);

-- lending by disbursement region 
WITH disbursement_region_agg
AS (
    SELECT
        vl.disbursement_location_region,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(*)                    AS regional_principal_volume,
        SUM(vl.principal_amount)    AS regional_principal_value,
        AVG(vl.principal_amount)    AS regional_avg_value
    FROM gold.vw_loan vl
    GROUP BY vl.disbursement_location_region
    )
SELECT
    *,
    SUM(regional_principal_volume) OVER ()                                                               AS total_portfolio_principal_volume,
    ROUND(CAST(100.00 * regional_principal_volume AS FLOAT) / SUM(regional_principal_volume) OVER (), 2) AS percentage_total_portfolio_principal_volume,
    SUM(regional_principal_value) OVER () total_portfolio_principal_value,
    ROUND(CAST(100.00 * regional_principal_value AS FLOAT) / SUM(regional_principal_value) OVER (), 2)   AS percentage_total_portfolio_principal_value
FROM disbursement_region_agg
ORDER BY percentage_total_portfolio_principal_value DESC;

-- Customer Concentration based on customer tier
WITH customer_agg
AS (
    SELECT
        vl.customer_id,
        COUNT(*)                 AS total_loan_volume,
        SUM(vl.principal_amount) AS total_loan_value
    FROM gold.vw_loan vl
    GROUP BY vl.customer_id
    ),
customers_ranked
AS (
    SELECT
        *,
        --SUM(total_loan_volume) OVER() AS overall_portfolio_loan_volume,
        --SUM(total_loan_value) OVER() AS overall_portfolio_loan_value,
        CUME_DIST() OVER (
            ORDER BY total_loan_value DESC
            ) AS cume_dist_score_loan_value,
        CUME_DIST() OVER (
            ORDER BY total_loan_volume DESC
            ) AS cume_dist_score_loan_volume
    FROM customer_agg
    ),
loan_portfolio_customer_tier
AS (
    SELECT
        customer_id,
        total_loan_volume,
        --overall_portfolio_loan_volume,
        total_loan_value,
        -- overall_portfolio_loan_value,
        ROUND(cume_dist_score_loan_value * 100.00, 1)  AS loan_value_percentile_rank,
        ROUND(cume_dist_score_loan_volume * 100.00, 1) AS loan_volume_percentile_rank,
        CASE 
            WHEN ROUND(cume_dist_score_loan_value * 100.00, 1) <= 1.0
                THEN 'TOP 1%'
            WHEN ROUND(cume_dist_score_loan_value * 100.00, 1) <= 5.0
                THEN 'TOP 5%'
            WHEN ROUND(cume_dist_score_loan_value * 100.00, 1) <= 10.0
                THEN 'TOP 10%'
            WHEN ROUND(cume_dist_score_loan_value * 100.00, 1) <= 20.0
                THEN 'TOP 20%'
            ELSE 'BOTTOM 80%'
            END AS customer_tier_loan_value,
        CASE 
            WHEN ROUND(cume_dist_score_loan_volume * 100.00, 1) <= 1.0
                THEN 'TOP 1%'
            WHEN ROUND(cume_dist_score_loan_volume * 100.00, 1) <= 5.0
                THEN 'TOP 5%'
            WHEN ROUND(cume_dist_score_loan_volume * 100.00, 1) <= 10.0
                THEN 'TOP 10%'
            WHEN ROUND(cume_dist_score_loan_volume * 100.00, 1) <= 20.0
                THEN 'TOP 20%'
            ELSE 'BOTTOM 80%'
            END AS customer_tier_loan_volume
    FROM customers_ranked
    )
SELECT
    customer_id,
    total_loan_value,
    loan_value_percentile_rank,
    customer_tier_loan_value,
    SUM(total_loan_value) OVER (PARTITION BY customer_tier_loan_value) AS tier_portfolio_loan_value,
/*
SUM(CASE customer_tier_loan_value
      WHEN 'TOP 1%' THEN total_loan_value 
      WHEN 'TOP 5%' THEN total_loan_value 
      WHEN 'TOP 10%' THEN total_loan_value 
      WHEN 'TOP 20%' THEN total_loan_value 
      ELSE total_loan_value
   END) OVER(PARTITION BY customer_tier_loan_value) AS tier_portfolio_loan_value, 
*/
    total_loan_volume,
    loan_volume_percentile_rank,
    customer_tier_loan_volume,
    SUM(total_loan_volume) OVER (PARTITION BY customer_tier_loan_volume) AS tier_portfolio_loan_volume
FROM loan_portfolio_customer_tier
ORDER BY loan_value_percentile_rank ASC;

-- cumulative concentration of loan portfolio
WITH customer_agg
AS (
    SELECT
        vl.customer_id,
        COUNT(*)                 AS total_loan_volume,
        SUM(vl.principal_amount) AS total_loan_value
    FROM gold.vw_loan vl
    GROUP BY vl.customer_id
    ),
customer_concentration
AS (
    SELECT
        customer_id,
        total_loan_volume,
        total_loan_value,
        SUM(total_loan_value) OVER () AS total_portfolio_loan_value,
        SUM(total_loan_value) OVER (
            ORDER BY total_loan_value DESC ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS cumulative_loan_value,
        ROUND(100.00 * total_loan_value / SUM(total_loan_value) OVER (), 2) AS portfolio_share_pct,
        ROUND(100.00 * SUM(total_loan_value) OVER (
                ORDER BY total_loan_value DESC ROWS BETWEEN UNBOUNDED PRECEDING
                        AND CURRENT ROW
                ) / SUM(total_loan_value) OVER (), 2) AS cumulative_portfolio_share_pct
    FROM customer_agg
    )
SELECT
    *
FROM customer_concentration
ORDER BY total_loan_value DESC;

-- loan portfolio summary
WITH customer_agg
AS (
    SELECT
        vl.customer_id,
        SUM(vl.principal_amount) AS total_loan_value
    FROM gold.vw_loan vl
    GROUP BY vl.customer_id
    ),
ranked_customers
AS (
    SELECT
        customer_id,
        total_loan_value,
        RANK() OVER (
            ORDER BY total_loan_value DESC
            ) AS customer_rank
    FROM customer_agg
    )
SELECT
    COUNT(*)              AS total_customers,
    SUM(total_loan_value) AS total_portfolio_value,
    SUM(CASE 
            WHEN customer_rank <= 1
                THEN total_loan_value
            ELSE 0
            END) AS top_1_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank <= 1
                        THEN total_loan_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_loan_value), 2) AS top_1_customer_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 5
                THEN total_loan_value
            ELSE 0
            END) AS top_5_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank <= 5
                        THEN total_loan_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_loan_value), 2) AS top_5_customer_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 10
                THEN total_loan_value
            ELSE 0
            END) AS top_10_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank <= 10
                        THEN total_loan_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_loan_value), 2) AS top_10_customer_share_pct
FROM ranked_customers;

/*
P5.2.1 — Lending Portfolio Behaviour
Notes
-----------------------------------------------------------------------------------------------------------------------------------
The SikaCredit lending portfolio contains 867 loans issued to 489 distinct customers, with total principal value of 1,112,318.94
over the observation period from 4 April 2023 to 1 December 2025.
Principal values range from 170.00 to 12,445.97. The median principal value is 951.18, compared with an average of 1,282.95,
indicating that higher-value loans pull the arithmetic mean above the median. The principal distribution therefore contains a
meaningful upper-value tail.
Contractual loan duration ranges from 30 to 120 days. The median contractual duration is 74 days, with the 25th and 75th percentiles
at 50 and 97 days respectively. The analysis represents contractual loan term, not actual repayment duration.
Loan activity increased substantially across the observation period. Annual principal value increased from 64,232.45 in 2023,
to 242,046.24 in 2024, and 806,040.25 in 2025. Quarterly analysis shows recurring concentration in the second half of each observed
year. Q3 and Q4 together account for approximately 70–80% of annual principal value, with Q4 representing the largest quarterly
share in each year. Because 2023 begins in April, 2025 ends in December, and the portfolio grows substantially over time, this is
treated as recurring temporal concentration rather than definitive seasonality.
Repeat borrowing occurs with relatively long intervals between loans, while observed borrowing spans extend from 34 to 874 days.
Borrowing activity expanded sharply over time, with 2025 showing higher loans and principal value per active customer than 2024.
Regional analysis shows that Greater Accra is the largest lending region, accounting for 28.37% of loan volume and 30.35% of
principal value. Ashanti follows at 13.26% of volume and 12.59% of value, with the remaining lending distributed across the other
observed regions. Greater Accra's share of principal value exceeds its share of loan volume, indicating a comparatively higher
average principal among its loans.
Customer concentration was examined through two complementary views. The percentile-band analysis distributes customers into
mutually exclusive concentration bands and measures the portfolio value and volume attributable to each band. The cumulative
concentration analysis shows that the largest individual borrower accounts for 1.26% of total portfolio principal, the top 5
borrowers account for 4.75%, and the top 10 borrowers account for 8.31%. Therefore, 91.69% of portfolio principal lies outside the
top 10 borrowers.
Loan type analysis was not performed because gold.vw_loan does not expose a loan-type attribute. No loan type was inferred from
other fields such as loan ID, duration, interest rate, or principal value.
-----------------------------------------------------------------------------------------------------------------------------------
Conclusions
-----------------------------------------------------------------------------------------------------------------------------------
The SikaCredit lending population is characterized by rapidly expanding lending activity, moderate contractual loan terms, a
right-tailed principal distribution, recurring second-half concentration, and relatively distributed customer-level principal
exposure.
The portfolio expanded considerably between 2023 and 2025, both in loan volume and principal value. Loan terms are concentrated
around the approximately two-to-three-month range, while principal values show a broader upper tail.
Lending activity is geographically distributed across Ghana but concentrated in Greater Accra relative to other regions. Temporal
analysis identifies persistent second-half concentration, although the available observation periods and strong portfolio growth
prevent this from being classified as definitive seasonality.
Customer concentration is comparatively dispersed at the top of the portfolio: the largest borrower represents only 1.26% of total
principal, while the top 10 account for 8.31%. This indicates that observed lending exposure is not dominated by a small number of
borrowers.
The analysis establishes the structural behaviour of the SikaCredit lending portfolio. It does not classify borrowers by credit
risk, repayment performance, or default behaviour; those questions are addressed by subsequent borrowing and repayment workloads.
*/
/*
===================================================================================================================================
### **P5.2.3 — Repayment Behaviour**

**SikaCredit**

Explore:
* repayment frequency
* repayment volumes and values
* repayment amounts
* repayment timing
* customer repayment patterns
* repayment concentration
* temporal changes in repayment behaviour
* repayment geographic dimensions where useful

**Purpose:** understand repayment activity independently before linking it back to individual loans.
===================================================================================================================================
*/
-- Repayment Baseline
WITH repayment_baseline
AS (
    SELECT
        COUNT(DISTINCT vrp.ocb_customer_id) AS distinct_customers,
        COUNT(*)                            AS total_repayment_volume,
        SUM(vrp.repayment_amount)           AS total_repayment_value,
        AVG(vrp.repayment_amount)           AS avg_repayment_value,
        MIN(vrp.repayment_amount)           AS min_repayment_value,
        MAX(vrp.repayment_amount)           AS max_repayment_value,
        MIN(vrp.repayment_timestamp)        AS observation_start_date,
        MAX(vrp.repayment_timestamp)        AS observation_end_date
    FROM gold.vw_repayment vrp
    ),
quartile_analysis
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS p25,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS median,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS p75,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS p90,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS p95,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY vrp.repayment_amount
            ) OVER () AS p99
    FROM gold.vw_repayment vrp
    )
SELECT
    rb.*,
    qa.*
FROM repayment_baseline rb
CROSS JOIN quartile_analysis qa;

-- customer repayment frequency
WITH repayment_span
AS (
    SELECT
        vrp.ocb_customer_id,
        COUNT(*)                                                                                   AS total_repayment_volume,
        MIN(vrp.repayment_timestamp)                                                               AS first_repayment_timestamp,
        MAX(vrp.repayment_timestamp)                                                               AS last_repayment_timestamp,
        DATEDIFF_BIG(SECOND, MIN(vrp.repayment_timestamp), MAX(vrp.repayment_timestamp)) / 86400.0 AS observed_repayment_span_days
    FROM gold.vw_repayment vrp
    GROUP BY vrp.ocb_customer_id
    ),
previous_repayment
AS (
    SELECT
        vrp.ocb_customer_id,
        vrp.repayment_timestamp AS current_rp_timestamp,
        LAG(vrp.repayment_timestamp, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY vrp.repayment_timestamp
            ) AS prev_rp_timestamp
    FROM gold.vw_repayment vrp
    ),
inter_repayment_interval
AS (
    SELECT
        rs.ocb_customer_id,
        rs.first_repayment_timestamp,
        rs.last_repayment_timestamp,
        rs.observed_repayment_span_days,
        rs.total_repayment_volume,
        pr.prev_rp_timestamp,
        pr.current_rp_timestamp,
        DATEDIFF_BIG(SECOND, prev_rp_timestamp, current_rp_timestamp) / 86400.00 AS inter_rp_interval_days
    FROM previous_repayment pr
    RIGHT JOIN repayment_span rs ON
            pr.ocb_customer_id = rs.ocb_customer_id
    WHERE prev_rp_timestamp IS NOT NULL
    ),
quartile_analysis
AS (
    SELECT TOP 1
        MIN(inter_rp_interval_days) OVER () AS min_interval_population,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS p25_population,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS median_population,
        AVG(inter_rp_interval_days) OVER () AS avg_interval_population,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS p75_population,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS p90_population,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS p95_population,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY inter_rp_interval_days
            ) OVER () AS p99_population,
        MAX(inter_rp_interval_days) OVER () AS max_interval_population
    FROM inter_repayment_interval
    )
SELECT
    ri.*,
    qa.*
FROM inter_repayment_interval ri
CROSS JOIN quartile_analysis qa;

-- Temporal Repayment Behaviour
WITH year_month_agg
AS (
    SELECT
        DATEFROMPARTS(YEAR(vrp.repayment_timestamp), MONTH(vrp.repayment_timestamp), 1) AS rp_month,
        COUNT(DISTINCT vrp.ocb_customer_id)                                             AS active_customers,
        COUNT(*)                                                                        AS monthly_repayment_volume,
        SUM(vrp.repayment_amount)                                                       AS monthly_repayment_value,
        AVG(vrp.repayment_amount)                                                       AS monthly_repayment_avg
    FROM gold.vw_repayment vrp
    GROUP BY DATEFROMPARTS(YEAR(vrp.repayment_timestamp), MONTH(vrp.repayment_timestamp), 1)
    ),
previous_repayment_agg
AS (
    SELECT
        rp_month,
        active_customers,
        LAG(active_customers, 1) OVER (
            ORDER BY rp_month
            ) AS previous_active_customers,
        monthly_repayment_volume,
        LAG(monthly_repayment_volume, 1) OVER (
            ORDER BY rp_month
            ) AS previous_repayment_volume,
        monthly_repayment_value,
        LAG(monthly_repayment_value, 1) OVER (
            ORDER BY rp_month
            ) AS previous_repayment_value,
        monthly_repayment_avg,
        LAG(monthly_repayment_avg, 1) OVER (
            ORDER BY rp_month
            ) AS previous_repayment_avg
    FROM year_month_agg
    )
SELECT
    rp_month,
    previous_active_customers,
    active_customers,
    ROUND(CAST(active_customers - previous_active_customers AS FLOAT) / NULLIF(previous_active_customers, 0) * 100.00, 2)         AS active_customers_mom_pct_chg,
    previous_repayment_volume,
    monthly_repayment_volume,
    ROUND(CAST(monthly_repayment_volume - previous_repayment_volume AS FLOAT) / NULLIF(previous_repayment_volume, 0) * 100.00, 2) AS repayment_volume_mom_pct_chg,
    previous_repayment_value,
    monthly_repayment_value,
    ROUND(CAST(monthly_repayment_value - previous_repayment_value AS FLOAT) / NULLIF(previous_repayment_value, 0) * 100.00, 2)    AS repayment_value_mom_pct_chg,
    previous_repayment_avg,
    monthly_repayment_avg,
    ROUND(CAST(monthly_repayment_avg - previous_repayment_avg AS FLOAT) / NULLIF(previous_repayment_avg, 0) * 100.00, 2)          AS repayment_avg_mom_pct_chg
FROM previous_repayment_agg
ORDER BY rp_month;

-- Repayment Concentration
WITH customer_agg
AS (
    SELECT
        vrp.ocb_customer_id,
        COUNT(*)                  AS total_rp_volume,
        SUM(vrp.repayment_amount) AS total_rp_value
    FROM gold.vw_repayment vrp
    GROUP BY vrp.ocb_customer_id
    )
SELECT
    *,
    ROUND(CAST(100.00 * total_rp_value AS FLOAT) / SUM(total_rp_value) OVER (), 2) AS portfolio_share_pct,
    SUM(total_rp_value) OVER (
        ORDER BY total_rp_value DESC ROWS UNBOUNDED PRECEDING
        ) AS cumulative_rp_value,
    ROUND(100.00 * CAST(SUM(total_rp_value) OVER (
                ORDER BY total_rp_value DESC ROWS UNBOUNDED PRECEDING
                ) AS FLOAT) / SUM(total_rp_value) OVER (), 2) AS cumulative_portfolio_share_pct,
    SUM(total_rp_value) OVER () AS overall_portfolio_rp_value
FROM customer_agg
ORDER BY portfolio_share_pct DESC;

-- repayment top N summary
WITH customer_agg
AS (
    SELECT
        vrp.ocb_customer_id,
        COUNT(*)                  AS total_rp_volume,
        SUM(vrp.repayment_amount) AS total_rp_value
    FROM gold.vw_repayment vrp
    GROUP BY vrp.ocb_customer_id
    ),
ranked_customers
AS (
    SELECT
        ocb_customer_id,
        total_rp_volume,
        total_rp_value,
        RANK() OVER (
            ORDER BY total_rp_value DESC
            ) AS customer_rank_rp_value
    FROM customer_agg
    )
SELECT
    COUNT(*)             AS total_customers,
    SUM(total_rp_volume) AS total_portfolio_volume,
    SUM(total_rp_value)  AS total_portfolio_value,
    SUM(CASE 
            WHEN customer_rank_rp_value <= 1
                THEN total_rp_value
            ELSE 0
            END) AS top_1_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank_rp_value <= 1
                        THEN total_rp_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_rp_value), 2) AS top_1_customer_share_pct,
    SUM(CASE 
            WHEN customer_rank_rp_value <= 5
                THEN total_rp_value
            ELSE 0
            END) AS top_5_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank_rp_value <= 5
                        THEN total_rp_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_rp_value), 2) AS top_5_customer_share_pct,
    SUM(CASE 
            WHEN customer_rank_rp_value <= 10
                THEN total_rp_value
            ELSE 0
            END) AS top_10_customer_value,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN customer_rank_rp_value <= 10
                        THEN total_rp_value
                    ELSE 0
                    END) AS FLOAT) / SUM(total_rp_value), 2) AS top_10_customer_share_pct
FROM ranked_customers;

-- Repayment Geographic Behaviour
WITH repayment_region_agg
AS (
    SELECT
        vrp.repayment_location_region,
        COUNT(DISTINCT ocb_customer_id) AS distinct_customers,
        COUNT(*)                        AS regional_rp_volume,
        SUM(vrp.repayment_amount)       AS regional_rp_value,
        AVG(vrp.repayment_amount)       AS regional_rp_avg
    FROM gold.vw_repayment vrp
    GROUP BY vrp.repayment_location_region
    )
SELECT
    *,
    SUM(regional_rp_volume) OVER ()                                                        AS total_portfolio_rp_volume,
    ROUND(CAST(100.00 * regional_rp_volume AS FLOAT) / SUM(regional_rp_volume) OVER (), 2) AS percentage_total_portfolio_rp_volume,
    SUM(regional_rp_value) OVER () total_portfolio_rp_value,
    ROUND(CAST(100.00 * regional_rp_value AS FLOAT) / SUM(regional_rp_value) OVER (), 2)   AS percentage_total_portfolio_rp_value
FROM repayment_region_agg
ORDER BY percentage_total_portfolio_rp_value DESC;

/*
P5.2.3 — REPAYMENT BEHAVIOUR
-----------------------------------------------------------------------------------------------------------------------------------
NOTES
-----------------------------------------------------------------------------------------------------------------------------------
- Repayment activity covers 470 customers, 2,683 repayment events and total repayment value of 862,215.98 over the observation
  period from 2023-04-15 to 2025-12-31.
- Repayment amounts range from 6.63 to 5,591.08. The median repayment is 193.27 while the average is 321.36, indicating a
  right-skewed repayment amount distribution driven by higher-value repayments.
- The upper tail is material: P90 is 742.28, P95 is 1,032.32 and P99 is 2,023.25 compared with a maximum of 5,591.08.
- Customer-level repayment intervals have a median of approximately 15.92 days and an average of 38.28 days. The distribution is
  strongly right-skewed, with P90 at approximately 77.60 days, P95 at 185.89 days, P99 at 409.53 days and a maximum of 795.84 days.
- Monthly repayment activity expanded substantially over the observation period. Repayment volume increased from 2 events in April
  2023 to 353 in December 2025, while monthly repayment value increased from 1,078.89 to 124,248.47.
- Repayment activity did not increase monotonically. Monthly contractions and expansions occurred throughout the period, with
  particularly strong expansion in active customers, repayment volume and repayment value during the latter part of 2025.
- The increase in monthly repayment value reflects changes in repayment activity and participation. It does not by itself establish
  improved repayment performance, repayment adequacy or timeliness.
- Repayment value is broadly distributed across the repayment customer population. The highest-value customer accounts for 1.43%
  of total repayment value, the top 5 account for 5.22%, and the top 10 account for 9.07%.
- Therefore, 90.93% of repayment value comes from customers outside the top 10, indicating limited customer-level concentration of
  repayment value.
- Regional repayment behaviour varies materially. Greater Accra contributes the largest regional share at 26.95% of repayment
  volume and 29.44% of repayment value, followed by Ashanti at 14.16% of volume and 13.24% of value.
- Regional volume and value shares are not identical, indicating differences in average repayment amounts across regions. Upper
  West records the highest regional average repayment at approximately 517.65, while Volta records the lowest at approximately
  237.17.
- Regional geographic differences are observable, but the results do not establish geographic risk or independently justify
  town-level investigation. Region-level analysis is sufficient for the current repayment workload.
-----------------------------------------------------------------------------------------------------------------------------------
INTELLIGENCE SIGNALS
-----------------------------------------------------------------------------------------------------------------------------------
- Repayment Amount Skew: repayment amounts are right-skewed, with a relatively small upper tail extending materially beyond the
  median. High-value repayment events may warrant contextual analysis when combined with other behavioural signals.
- Long Repayment Interval Tail: most observed customer repayment intervals are substantially shorter than the extreme tail, but a
  minority of intervals extend to several months or longer. Long gaps can be retained as a behavioural signal for further loan-level
  investigation, but do not independently indicate delinquency.
- Repayment Activity Expansion: repayment participation and event volume increased substantially over the observation period,
  particularly during 2025. This establishes a strong temporal change in repayment activity requiring contextual interpretation
  alongside portfolio growth.
- Low Customer Repayment Concentration: repayment value is broadly distributed, with the top 10 customers contributing only 9.07%
  of total repayment value. No small customer group dominates the repayment-value population.
- Geographic Variation: repayment activity and average repayment amounts vary by region. These differences provide geographic
  segmentation signals for subsequent analysis but do not independently establish geographic risk.
-----------------------------------------------------------------------------------------------------------------------------------
CONCLUSION
-----------------------------------------------------------------------------------------------------------------------------------
Repayment behaviour is characterised by a right-skewed distribution of repayment amounts, a median customer repayment interval of
approximately 15.92 days, substantial growth in repayment activity over the observation period, low customer-level concentration of
repayment value, and observable regional variation. The analysis establishes the shape, frequency, temporal development,
concentration and geographic distribution of repayment activity, but does not determine whether repayments were timely, sufficient
or adequate relative to individual loan obligations. Those questions require linking repayments back to loans and their contractual
characteristics. P5.2.3 is therefore complete and provides the behavioural foundation for P5.2.4 — Loan-to-Repayment Behaviour.
*/
/*
==================================================================================================================================
### **P5.2.4 — Loan-to-Repayment Behaviour**

**SikaCredit**

Explore:
* repayment events per loan
* time from loan origination to repayment
* repayment progression through the loan lifecycle
* observed repayment value relative to loan principal
* repayment timing patterns
* customer-level differences in loan-to-repayment behaviour

**Purpose:** understand the relationship between borrowing and subsequent repayment activity.
===================================================================================================================================
*/
-- Loan-to-Repayment Baseline
WITH repayment_agg
AS (
    SELECT
        rp.loan_id,
        rp.ocb_customer_id,
        COUNT(*)                 AS total_rp_volume,
        SUM(rp.repayment_amount) AS total_rp_value
    FROM gold.vw_repayment rp
    GROUP BY rp.loan_id,
        rp.ocb_customer_id
    )
SELECT
    COUNT(*) AS total_loan_volume,
    SUM(CASE 
            WHEN ra.loan_id IS NOT NULL
                THEN 1
            ELSE 0
            END) AS loans_with_rp,
    SUM(CASE 
            WHEN ra.loan_id IS NULL
                THEN 1
            ELSE 0
            END) AS loans_without_rp,
    ROUND(CAST(100.00 * SUM(CASE 
                    WHEN ra.loan_id IS NOT NULL
                        THEN 1
                    ELSE 0
                    END) AS FLOAT) / COUNT(*), 2) AS loans_with_rp_pct,
    SUM(l.principal_amount) AS total_principal_value,
    SUM(CASE 
            WHEN ra.loan_id IS NOT NULL
                THEN l.principal_amount
            ELSE 0
            END) AS total_principal_with_rp,
    SUM(total_rp_value) AS total_observed_rp_value
FROM gold.vw_loan l
LEFT JOIN repayment_agg ra ON
        l.loan_id = ra.loan_id
            AND l.ocb_customer_id = ra.ocb_customer_id;

-- Repayment Events per Loan
WITH repayment_agg
AS (
    SELECT
        rp.loan_id,
        rp.ocb_customer_id,
        COUNT(*)                 AS total_rp_volume,
        SUM(rp.repayment_amount) AS total_rp_value
    FROM gold.vw_repayment rp
    GROUP BY rp.loan_id,
        rp.ocb_customer_id
    ),
repayment_flag
AS (
    SELECT
        l.loan_id,
        ra.total_rp_volume,
        ra.total_rp_value,
        CASE 
            WHEN ra.total_rp_volume = 1
                THEN '1 rp'
            WHEN ra.total_rp_volume = 2
                THEN '2 rp'
            WHEN ra.total_rp_volume >= 3
                THEN '3+ rp'
            ELSE '0 rp'
            END AS loans_rp_flag
    FROM gold.vw_loan l
    LEFT JOIN repayment_agg ra ON
            l.loan_id = ra.loan_id
                AND l.ocb_customer_id = ra.ocb_customer_id
    ),
rp_distribution
AS (
    SELECT
        *,
        COALESCE(total_rp_volume, 0) AS rp_events
    FROM repayment_flag
    ),
rp_percentiles
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS p25_rp_events,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS median_rp_events,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS p75_rp_events,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS p90_rp_events,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS p95_rp_events,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY rp_events
            ) OVER () AS p99_rp_events
    FROM rp_distribution
    )
SELECT
    COUNT(*) AS total_loans,
    SUM(CASE 
            WHEN loans_rp_flag = '0 rp'
                THEN 1
            ELSE 0
            END) AS loans_0_rp,
    SUM(CASE 
            WHEN loans_rp_flag = '1 rp'
                THEN 1
            ELSE 0
            END) AS loans_1_rp,
    SUM(CASE 
            WHEN loans_rp_flag = '2 rp'
                THEN 1
            ELSE 0
            END) AS loans_2_rp,
    SUM(CASE 
            WHEN loans_rp_flag = '3+ rp'
                THEN 1
            ELSE 0
            END) AS loans_3plus_rp,
    ROUND(100.0 * SUM(CASE 
                WHEN loans_rp_flag = '0 rp'
                    THEN 1
                ELSE 0
                END) / COUNT(*), 2) AS pct_0_rp,
    ROUND(100.0 * SUM(CASE 
                WHEN loans_rp_flag = '1 rp'
                    THEN 1
                ELSE 0
                END) / COUNT(*), 2) AS pct_1_rp,
    ROUND(100.0 * SUM(CASE 
                WHEN loans_rp_flag = '2 rp'
                    THEN 1
                ELSE 0
                END) / COUNT(*), 2) AS pct_2_rp,
    ROUND(100.0 * SUM(CASE 
                WHEN loans_rp_flag = '3+ rp'
                    THEN 1
                ELSE 0
                END) / COUNT(*), 2) AS pct_3plus_rp,
    MIN(rp_events) AS min_rp_events,
    AVG(CAST(rp_events AS FLOAT)) AS avg_rp_events,
    MAX(rp_events) AS max_rp_events,
    MAX(p.p25_rp_events) AS p25_rp_events,
    MAX(p.median_rp_events) AS median_rp_events,
    MAX(p.p75_rp_events) AS p75_rp_events,
    MAX(p.p90_rp_events) AS p90_rp_events,
    MAX(p.p95_rp_events) AS p95_rp_events,
    MAX(p.p99_rp_events) AS p99_rp_events
FROM rp_distribution d
CROSS JOIN rp_percentiles p;

-- Time from Origination to First Repayment
WITH filtered_timestamp
AS (
    SELECT
        l.loan_id,
        l.ocb_customer_id,
        l.disbursement_timestamp,
        rp.repayment_timestamp
    FROM gold.vw_loan l
    LEFT JOIN gold.vw_repayment rp ON
            l.loan_id = rp.loan_id
                AND l.ocb_customer_id = rp.ocb_customer_id
                AND l.disbursement_timestamp <= rp.repayment_timestamp
    ),
disbursement_repayment_interval
AS (
    SELECT
        loan_id,
        ocb_customer_id,
        disbursement_timestamp,
        MIN(repayment_timestamp)                                                          AS first_repayment_timestamp,
        DATEDIFF_BIG(SECOND, disbursement_timestamp, MIN(repayment_timestamp)) / 86400.00 AS days_to_first_repayment
    FROM filtered_timestamp
    GROUP BY loan_id,
        ocb_customer_id,
        disbursement_timestamp
    ),
db_rp_interval_percentiles
AS (
    SELECT TOP 1
        MIN(days_to_first_repayment) OVER () AS min_days_to_first_repayment,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS p25_days_to_first_repayment,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS median_days_to_first_repayment,
        AVG(days_to_first_repayment) OVER () AS avg_days_to_first_repayment,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS p75_days_to_first_repayment,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS p90_days_to_first_repayment,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS p95_days_to_first_repayment,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY days_to_first_repayment
            ) OVER () AS p99_days_to_first_repayment,
        MAX(days_to_first_repayment) OVER () AS max_days_to_first_repayment
    FROM disbursement_repayment_interval
    )
SELECT
    i.ocb_customer_id,
    i.loan_id,
    i.disbursement_timestamp,
    i.first_repayment_timestamp,
    i.days_to_first_repayment,
    COUNT(*) OVER (
        PARTITION BY CASE 
            WHEN i.first_repayment_timestamp IS NULL
                THEN 0
            ELSE 1
            END
        ) AS loans_in_rp_status,
    ROUND(100.0 * COUNT(*) OVER (
            PARTITION BY CASE 
                WHEN i.first_repayment_timestamp IS NULL
                    THEN 0
                ELSE 1
                END
            ) / COUNT(*) OVER (), 2) AS loans_in_rp_status_pct,
    p.*
FROM disbursement_repayment_interval i
CROSS JOIN db_rp_interval_percentiles p
ORDER BY i.loan_id;

-- Repayment Progression loan level
WITH filtered_timestamp
AS (
    SELECT
        l.loan_id,
        l.ocb_customer_id,
        l.disbursement_timestamp,
        rp.repayment_timestamp,
        rp.repayment_amount
    FROM gold.vw_loan l
    LEFT JOIN gold.vw_repayment rp ON
            l.loan_id = rp.loan_id
                AND l.ocb_customer_id = rp.ocb_customer_id
                AND l.disbursement_timestamp <= rp.repayment_timestamp
    ),
loan_repayment_profile
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp
            ) AS rp_sequence,
        SUM(repayment_amount) OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp ASC
            ) AS running_rp_total_value,
        ROUND(CAST(DATEDIFF_BIG(SECOND, disbursement_timestamp, repayment_timestamp) AS FLOAT) / 86400.00, 3) AS days_to_rp,
        LAG(repayment_timestamp, 1) OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp ASC
            ) AS prev_rp_timestamp,
        ROUND(CAST(DATEDIFF_BIG(SECOND, LAG(repayment_timestamp, 1) OVER (
                        PARTITION BY loan_id ORDER BY repayment_timestamp ASC
                        ), repayment_timestamp) AS FLOAT) / 86400.00, 3) AS days_btn_rp
    FROM filtered_timestamp
    )
SELECT
    *
FROM loan_repayment_profile;

-- Repayment Progression Portfolio Summary
WITH filtered_timestamp
AS (
    SELECT
        l.loan_id,
        l.ocb_customer_id,
        l.disbursement_timestamp,
        rp.repayment_timestamp,
        rp.repayment_amount
    FROM gold.vw_loan l
    LEFT JOIN gold.vw_repayment rp ON
            l.loan_id = rp.loan_id
                AND l.ocb_customer_id = rp.ocb_customer_id
                AND l.disbursement_timestamp <= rp.repayment_timestamp
    ),
loan_repayment_profile
AS (
    SELECT
        loan_id,
        ocb_customer_id,
        disbursement_timestamp,
        repayment_timestamp,
        repayment_amount,
        ROW_NUMBER() OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp
            ) AS rp_sequence,
        SUM(repayment_amount) OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS running_rp_total_value,
        ROUND(CAST(DATEDIFF_BIG(SECOND, disbursement_timestamp, repayment_timestamp) AS FLOAT) / 86400.00, 3) AS days_to_rp,
        LAG(repayment_timestamp) OVER (
            PARTITION BY loan_id ORDER BY repayment_timestamp
            ) AS prev_rp_timestamp,
        ROUND(CAST(DATEDIFF_BIG(SECOND, LAG(repayment_timestamp) OVER (
                        PARTITION BY loan_id ORDER BY repayment_timestamp
                        ), repayment_timestamp) AS FLOAT) / 86400.00, 3) AS days_btn_rp
    FROM filtered_timestamp
    ),
sequence_summary
AS (
    SELECT
        rp_sequence,
        COUNT(DISTINCT loan_id) AS loans_reaching_sequence,
        SUM(repayment_amount)   AS repayment_value_at_sequence,
        AVG(repayment_amount)   AS avg_repayment_amount,
        AVG(days_to_rp)         AS avg_days_to_rp,
        AVG(days_btn_rp)        AS avg_days_btn_rp
    FROM loan_repayment_profile
    WHERE repayment_timestamp IS NOT NULL
    GROUP BY rp_sequence
    ),
sequence_medians
AS (
    SELECT DISTINCT
        rp_sequence,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY repayment_amount
            ) OVER (PARTITION BY rp_sequence) AS median_repayment_amount,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY days_to_rp
            ) OVER (PARTITION BY rp_sequence) AS median_days_to_rp
    FROM loan_repayment_profile
    WHERE repayment_timestamp IS NOT NULL
    )
SELECT
    ss.rp_sequence,
    ss.loans_reaching_sequence,
    ss.repayment_value_at_sequence,
    ss.avg_repayment_amount,
    sm.median_repayment_amount,
    ss.avg_days_to_rp,
    sm.median_days_to_rp,
    ss.avg_days_btn_rp,
    SUM(ss.repayment_value_at_sequence) OVER (
        ORDER BY ss.rp_sequence ROWS BETWEEN UNBOUNDED PRECEDING
                AND CURRENT ROW
        ) AS cumulative_observed_repayment_value
FROM sequence_summary ss
JOIN sequence_medians sm ON
        ss.rp_sequence = sm.rp_sequence
ORDER BY ss.rp_sequence;

/*
P5.2.4 — Loan-to-Repayment Behaviour
----------------------------------------------------------------------------------------------------------------------------------
NOTES
----------------------------------------------------------------------------------------------------------------------------------
- P5.2.4 examined the relationship between SikaCredit loan origination and subsequent observed repayment activity at loan level.
- 867 loans were analysed.
- 822 loans (94.81%) had at least one observed repayment occurring on or after loan disbursement.
- 45 loans (5.19%) had no qualifying observed repayment in the available data.
- Repayment-event progression was concentrated at a maximum observed sequence of 5 repayments per loan.
- 65.05% of loans had 3 or more observed repayment events.
- 29.76% had exactly 1 or 2 observed repayment events.
- 5.19% had no observed repayment events.
- Median observed repayment events per loan was 3; average was approximately 3.09.
- Time from disbursement to first observed repayment had a median of approximately 17.24 days and an average of approximately
  19.68 days.
- 75% of loans with a qualifying first repayment had their first observed repayment within approximately 25.29 days; 90% within
  approximately 35.33 days; 99% within approximately 54.84 days.
- Repayment progression showed declining observed repayment amounts across successive repayment sequences.
- Median repayment amount declined from 422.20 at the first observed repayment to 32.05 at the fifth.
- Average repayment amount declined from approximately 582.23 at the first observed repayment to approximately 49.27 at the fifth.
- The number of loans reaching each successive repayment sequence also declined: 822 at sequence 1, 781 at sequence 2, 563 at
  sequence 3, 340 at sequence 4, and 167 at sequence 5.
- Median elapsed time from disbursement increased across repayment sequences: approximately 17.24 days at sequence 1, 33.90 at
  sequence 2, 45.20 at sequence 3, 52.07 at sequence 4, and 61.76 at sequence 5.
- Despite the increasing cumulative elapsed time, the median interval between successive observed repayments contracted from
  approximately 16.91 days at the second repayment to approximately 11.94 days at the fifth.
- Cumulative observed repayment value reached 858,121.43 by the fifth repayment sequence.
- Observed repayment values describe actual repayment events in the dataset and should not be interpreted as contractual repayment
  completion or outstanding-balance measures.
- P5.2.4 did not use maturity date, interest rate, contractual obligations, delinquency rules, or default definitions to assess
  loan performance. Those dimensions are better reserved for a later dedicated credit/loan-performance intelligence workload.
- Customer-level loan-to-repayment analysis was not added because P5.2.2 and P5.2.3 had already covered customer borrowing and
  repayment behaviour, while a further customer-level combination would largely repackage existing findings rather than create a
  distinct exploratory workload.
- P5.2.4 is therefore complete at loan-to-repayment behavioural level.
----------------------------------------------------------------------------------------------------------------------------------
INTELLIGENCE SIGNALS
----------------------------------------------------------------------------------------------------------------------------------
1. Observed Repayment Participation
   94.81% of loans had at least one qualifying observed repayment, while 5.19% had none. This establishes the observed repayment
   population for subsequent analysis but does not establish repayment success or failure.

2. Repayment Sequence Attrition
   The number of loans reaching successive repayment sequences declines materially, from 822 at the first observed repayment to
   167 at the fifth. This indicates a progressively smaller observed population as repayment sequences advance.

3. Declining Observed Repayment Amounts
   Both median and average repayment amounts decline substantially across successive observed repayment sequences. This is a clear
   behavioural pattern in the simulated repayment data.

4. Increasing Elapsed Repayment Timeline
   Median elapsed time from disbursement increases across successive repayment sequences, indicating that later observed
   repayments occur progressively further into the loan lifecycle.

5. Contracting Inter-Repayment Intervals
   Median intervals between successive observed repayments decline from approximately 16.91 days at sequence 2 to approximately
   11.94 days at sequence 5. This indicates that, among loans reaching later repayment sequences, successive observed repayments
   occur at shorter intervals.

6. Repayment Progression Requires Deeper Performance Analysis
   The observed repayment patterns provide potential inputs for a later loan-performance or credit-intelligence workload.
   However, the exploratory evidence alone does not establish whether the observed behaviour represents adequate repayment,
   delinquency, default, or contractual performance.
----------------------------------------------------------------------------------------------------------------------------------
CONCLUSION
----------------------------------------------------------------------------------------------------------------------------------
P5.2.4 established the observed relationship between SikaCredit loan origination and subsequent repayment activity without moving
into credit-performance classification.
The analysis shows that most loans have at least one observed repayment, but the population reaching later repayment sequences
contracts substantially. Among loans that progress through successive repayment events, observed repayment amounts decline while
cumulative elapsed time from disbursement increases. At the same time, the interval between successive observed repayments becomes
shorter.
These findings establish several observable repayment-behaviour patterns that may justify deeper intelligence analysis later,
particularly around loan performance, contractual repayment expectations, and borrower repayment outcomes.
*/
/*
==================================================================================================================================
### **P5.2.5 — Remittance Behaviour**

**Oman Remit**

Explore:
* remittance volume
* remittance value
* send vs receive behaviour
* frequency
* customer concentration
* temporal/seasonal behaviour
* **channel behaviour**
* **origin-country behaviour**
* **region/town/location behaviour**
* channel × remittance direction
* country × remittance direction
* country × channel
* geographic concentration
* repeat vs occasional remittance behaviour
==================================================================================================================================
*/
-- Remittance Baseline
WITH remittance_aggregate
AS (
    SELECT
        COUNT(DISTINCT vrm.customer_id) AS distinct_remittance_customers,
        COUNT(*)                        AS total_remittance_txns,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS avg_remittance_value,
        MIN(vrm.remittance_amount)      AS min_remittance_value,
        MAX(vrm.remittance_amount)      AS max_remittance_value,
        MIN(vrm.remittance_timestamp)   AS earliest_remittance_timestamp,
        MAX(vrm.remittance_timestamp)   AS latest_remittance_timestamp
    FROM gold.vw_remittance vrm
    ),
quartile_analysis
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS p25,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS median,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS p75,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS p90,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS p95,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY vrm.remittance_amount
            ) OVER () AS p99
    FROM gold.vw_remittance vrm
    )
SELECT
    ra.*,
    qa.*
FROM remittance_aggregate ra
CROSS JOIN quartile_analysis qa;

-- remittance type
WITH remittance_agg
AS (
    SELECT
        vrm.remittance_type,
        COUNT(*)                   AS total_remittance_volume,
        SUM(vrm.remittance_amount) AS total_remittance_value,
        AVG(vrm.remittance_amount) AS avg_remittance_value
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_type
    )
SELECT
    *,
    SUM(total_remittance_volume) OVER ()                                                             AS overall_remittance_volume,
    SUM(total_remittance_value) OVER ()                                                              AS overall_remittance_value,
    ROUND(CAST(100.00 * total_remittance_volume AS FLOAT) / SUM(total_remittance_volume) OVER (), 2) AS remittance_volume_pct,
    ROUND(CAST(100.00 * total_remittance_value AS FLOAT) / SUM(total_remittance_value) OVER (), 2)   AS remittance_value_pct
FROM remittance_agg
ORDER BY total_remittance_value DESC;

-- Send vs Receive Behaviour
WITH remittance_agg
AS (
    SELECT
        vrm.customer_id,
        SUM(CASE 
                WHEN vrm.remittance_type = 'remittance_received'
                    THEN 1
                ELSE 0
                END) AS remittance_received,
        SUM(CASE 
                WHEN vrm.remittance_type = 'remittance_sent'
                    THEN 1
                ELSE 0
                END) AS remittance_sent,
        COUNT(*) AS total_remittance_volume,
        SUM(vrm.remittance_amount) AS total_remittance_value,
        SUM(CASE 
                WHEN vrm.remittance_type = 'remittance_received'
                    THEN vrm.remittance_amount
                ELSE 0
                END) AS received_value,
        SUM(CASE 
                WHEN vrm.remittance_type = 'remittance_sent'
                    THEN vrm.remittance_amount
                ELSE 0
                END) AS sent_value
    FROM gold.vw_remittance vrm
    GROUP BY vrm.customer_id
    ),
remit_flag
AS (
    SELECT
        *,
        CASE 
            WHEN remittance_received > 0
                    AND remittance_sent = 0
                THEN 'received_only'
            WHEN remittance_received = 0
                    AND remittance_sent > 0
                THEN 'sent_only'
            ELSE 'both_received_and_sent'
            END AS remit_type_flag
    FROM remittance_agg
    )
SELECT
    remit_type_flag,
    COUNT(*)                                                                                                   AS customer_count,
    ROUND(CAST(100.00 * COUNT(*) AS FLOAT) / SUM(COUNT(*)) OVER (), 2)                                         AS customer_pct,
    SUM(total_remittance_volume)                                                                               AS remittance_volume,
    ROUND(CAST(100.00 * SUM(total_remittance_volume) AS FLOAT) / SUM(SUM(total_remittance_volume)) OVER (), 2) AS remittance_volume_pct,
    SUM(total_remittance_value)                                                                                AS remittance_value,
    ROUND(CAST(100.00 * SUM(total_remittance_value) AS FLOAT) / SUM(SUM(total_remittance_value)) OVER (), 2)   AS remittance_value_pct,
    AVG(total_remittance_value * 1.0 / NULLIF(total_remittance_volume, 0))                                     AS avg_remittance_amount
FROM remit_flag
GROUP BY remit_type_flag
ORDER BY remittance_value DESC;

-- Remittance Frequency
WITH remittance_interval
AS (
    SELECT
        vrm.customer_id,
        vrm.remittance_id,
        vrm.remittance_timestamp,
        LAG(vrm.remittance_timestamp) OVER (
            PARTITION BY vrm.customer_id ORDER BY vrm.remittance_timestamp,
                vrm.remittance_id
            ) AS prev_remit_timestamp
    FROM gold.vw_remittance vrm
    ),
remittance_intervals
AS (
    SELECT
        customer_id,
        remittance_id,
        remittance_timestamp,
        prev_remit_timestamp,
        DATEDIFF_BIG(SECOND, prev_remit_timestamp, remittance_timestamp) / 86400.00 AS remit_interval_days
    FROM remittance_interval
    WHERE prev_remit_timestamp IS NOT NULL
    ),
customer_activity
AS (
    SELECT
        customer_id,
        COUNT(*) AS remittance_event_count
    FROM gold.vw_remittance
    GROUP BY customer_id
    ),
remittance_distribution
AS (
    SELECT TOP 1
        MIN(ri.remit_interval_days) OVER () AS min_remit_interval_days,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS p25,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS median,
        AVG(ri.remit_interval_days) OVER () AS avg_remit_interval_days,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS p75,
        PERCENTILE_CONT(0.90) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS p90,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS p95,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY ri.remit_interval_days
            ) OVER () AS p99,
        MAX(ri.remit_interval_days) OVER () AS max_remit_interval_days
    FROM remittance_intervals ri
    )
SELECT DISTINCT
    COUNT(CASE 
            WHEN ca.remittance_event_count >= 2
                THEN 1
            END) OVER () AS customers_with_2plus_events,
    COUNT(CASE 
            WHEN ca.remittance_event_count = 1
                THEN 1
            END) OVER () AS customers_with_1_event,
    rd.min_remit_interval_days,
    rd.p25,
    rd.median,
    rd.avg_remit_interval_days,
    rd.p75,
    rd.p90,
    rd.p95,
    rd.p99,
    rd.max_remit_interval_days
FROM customer_activity ca
CROSS JOIN remittance_distribution rd;

-- Remittance Concentration
WITH customer_remittance
AS (
    SELECT
        vrm.customer_id,
        COUNT(*)                   AS remittance_transaction_count,
        SUM(vrm.remittance_amount) AS remittance_value
    FROM gold.vw_remittance vrm
    GROUP BY vrm.customer_id
    ),
ranked_customers
AS (
    SELECT
        customer_id,
        remittance_transaction_count,
        remittance_value,
        ROW_NUMBER() OVER (
            ORDER BY remittance_value DESC,
                customer_id
            ) AS customer_rank
    FROM customer_remittance
    ),
population_totals
AS (
    SELECT
        SUM(remittance_transaction_count) AS total_transaction_count,
        SUM(remittance_value)             AS total_remittance_value
    FROM customer_remittance
    ),
concentration
AS (
    SELECT
        rc.customer_rank,
        rc.remittance_transaction_count,
        rc.remittance_value,
        pt.total_transaction_count,
        pt.total_remittance_value
    FROM ranked_customers rc
    CROSS JOIN population_totals pt
    WHERE rc.customer_rank <= 10
    )
SELECT
    SUM(CASE 
            WHEN customer_rank = 1
                THEN remittance_transaction_count
            ELSE 0
            END) AS top_1_transaction_count,
    SUM(CASE 
            WHEN customer_rank <= 5
                THEN remittance_transaction_count
            ELSE 0
            END) AS top_5_transaction_count,
    SUM(CASE 
            WHEN customer_rank <= 10
                THEN remittance_transaction_count
            ELSE 0
            END) AS top_10_transaction_count,
    SUM(CASE 
            WHEN customer_rank = 1
                THEN remittance_value
            ELSE 0
            END) AS top_1_remittance_value,
    SUM(CASE 
            WHEN customer_rank <= 5
                THEN remittance_value
            ELSE 0
            END) AS top_5_remittance_value,
    SUM(CASE 
            WHEN customer_rank <= 10
                THEN remittance_value
            ELSE 0
            END) AS top_10_remittance_value,
    MAX(total_transaction_count) AS total_transaction_count,
    MAX(total_remittance_value) AS total_remittance_value,
    SUM(CASE 
            WHEN customer_rank = 1
                THEN remittance_transaction_count
            ELSE 0
            END) * 100.0 / MAX(total_transaction_count) AS top_1_transaction_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 5
                THEN remittance_transaction_count
            ELSE 0
            END) * 100.0 / MAX(total_transaction_count) AS top_5_transaction_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 10
                THEN remittance_transaction_count
            ELSE 0
            END) * 100.0 / MAX(total_transaction_count) AS top_10_transaction_share_pct,
    SUM(CASE 
            WHEN customer_rank = 1
                THEN remittance_value
            ELSE 0
            END) * 100.0 / MAX(total_remittance_value) AS top_1_value_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 5
                THEN remittance_value
            ELSE 0
            END) * 100.0 / MAX(total_remittance_value) AS top_5_value_share_pct,
    SUM(CASE 
            WHEN customer_rank <= 10
                THEN remittance_value
            ELSE 0
            END) * 100.0 / MAX(total_remittance_value) AS top_10_value_share_pct,
    (
        MAX(total_remittance_value) - SUM(CASE 
                WHEN customer_rank <= 10
                    THEN remittance_value
                ELSE 0
                END)
        ) * 100.0 / MAX(total_remittance_value) AS outside_top_10_value_share_pct
FROM concentration;

--Temporal Remittance Behaviour
WITH monthly_remittance
AS (
    SELECT
        YEAR(vrm.remittance_timestamp)  AS YEAR,
        MONTH(vrm.remittance_timestamp) AS MONTH,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        COUNT(DISTINCT vrm.customer_id) AS active_customers,
        AVG(vrm.remittance_amount)      AS average_remittance_amount
    FROM gold.vw_remittance vrm
    GROUP BY YEAR(vrm.remittance_timestamp),
        MONTH(vrm.remittance_timestamp)
    ),
annual_totals
AS (
    SELECT
        YEAR(vrm.remittance_timestamp) AS YEAR,
        COUNT(*)                       AS annual_transaction_count,
        SUM(vrm.remittance_amount)     AS annual_remittance_value
    FROM gold.vw_remittance vrm
    GROUP BY YEAR(vrm.remittance_timestamp)
    )
SELECT
    mr.YEAR,
    mr.MONTH,
    mr.remittance_transaction_count,
    mr.total_remittance_value,
    mr.active_customers,
    mr.average_remittance_amount,
    mr.remittance_transaction_count * 100.0 / AT.annual_transaction_count AS annual_volume_share_pct,
    mr.total_remittance_value * 100.0 / AT.annual_remittance_value        AS annual_value_share_pct
FROM monthly_remittance mr
INNER JOIN annual_totals AT ON
        mr.YEAR = AT.YEAR
ORDER BY mr.YEAR,
    mr.MONTH;

-- Remittance Channel Behaviour
WITH channel_remittance
AS (
    SELECT
        vrm.remittance_transaction_channel,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS average_remittance_amount,
        COUNT(DISTINCT vrm.customer_id) AS active_customers
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_transaction_channel
    ),
population_totals
AS (
    SELECT
        COUNT(*)                   AS total_transaction_count,
        SUM(vrm.remittance_amount) AS total_remittance_value
    FROM gold.vw_remittance vrm
    )
SELECT
    cr.remittance_transaction_channel,
    cr.remittance_transaction_count,
    cr.total_remittance_value,
    cr.average_remittance_amount,
    cr.active_customers,
    cr.remittance_transaction_count * 100.0 / pt.total_transaction_count AS transaction_volume_share_pct,
    cr.total_remittance_value * 100.0 / pt.total_remittance_value        AS remittance_value_share_pct
FROM channel_remittance cr
CROSS JOIN population_totals pt
ORDER BY cr.remittance_transaction_count DESC;

-- Channel × Remittance Direction
WITH channel_type
AS (
    SELECT
        vrm.remittance_transaction_channel,
        vrm.remittance_type,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS average_remittance_amount,
        COUNT(DISTINCT vrm.customer_id) AS active_customers
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_transaction_channel,
        vrm.remittance_type
    ),
channel_totals
AS (
    SELECT
        vrm.remittance_transaction_channel,
        COUNT(*)                                AS channel_transaction_count,
        SUM(vrm.remittance_amount)              AS channel_remittance_value,
        SUM(SUM(vrm.remittance_amount)) OVER () AS overall_remittance_value,
        (
            SELECT
                SUM(remittance_transaction_count)
            FROM channel_type
            ) AS overall_remittance_volume
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_transaction_channel
    )
SELECT
    ct.remittance_transaction_channel,
    ct.remittance_type,
    ct.remittance_transaction_count,
    ct.total_remittance_value,
    ct.average_remittance_amount,
    ct.active_customers,
    ROUND(CAST(ct.remittance_transaction_count AS FLOAT) * 100.0 / cht.channel_transaction_count, 2) AS channel_volume_share_pct,
    ROUND(CAST(ct.total_remittance_value AS FLOAT) * 100.0 / cht.channel_remittance_value, 2)        AS channel_value_share_pct,
    ROUND(CAST(ct.remittance_transaction_count AS FLOAT) * 100.0 / cht.overall_remittance_volume, 2) AS overall_channel_volume_pct,
    ROUND(CAST(ct.total_remittance_value AS FLOAT) * 100.0 / cht.overall_remittance_value, 2)        AS overall_channel_value_pct
FROM channel_type ct
INNER JOIN channel_totals cht ON
        ct.remittance_transaction_channel = cht.remittance_transaction_channel
ORDER BY ct.remittance_transaction_channel,
    ct.remittance_type;

-- Geographic Behviour
WITH country_remittance
AS (
    SELECT
        vrm.remittance_origin_country,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS average_remittance_amount,
        COUNT(DISTINCT vrm.customer_id) AS active_customers
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_origin_country
    ),
population_totals
AS (
    SELECT
        COUNT(*)                   AS total_transaction_count,
        SUM(vrm.remittance_amount) AS total_remittance_value
    FROM gold.vw_remittance vrm
    )
SELECT
    cr.remittance_origin_country,
    cr.remittance_transaction_count,
    cr.total_remittance_value,
    cr.average_remittance_amount,
    cr.active_customers,
    ROUND(CAST(cr.remittance_transaction_count AS FLOAT) * 100.0 / pt.total_transaction_count, 2) AS transaction_volume_share_pct,
    ROUND(CAST(cr.total_remittance_value AS FLOAT) * 100.0 / pt.total_remittance_value, 2)        AS remittance_value_share_pct
FROM country_remittance cr
CROSS JOIN population_totals pt
ORDER BY cr.remittance_transaction_count DESC;

-- Origin Country × Remittance Direction
WITH country_type
AS (
    SELECT
        vrm.remittance_origin_country,
        vrm.remittance_type,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS average_remittance_amount,
        COUNT(DISTINCT vrm.customer_id) AS active_customers
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_origin_country,
        vrm.remittance_type
    ),
country_totals
AS (
    SELECT
        vrm.remittance_origin_country,
        COUNT(*)                   AS country_transaction_count,
        SUM(vrm.remittance_amount) AS country_remittance_value
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_origin_country
    ),
population_totals
AS (
    SELECT
        COUNT(*)                   AS overall_transaction_count,
        SUM(vrm.remittance_amount) AS overall_remittance_value
    FROM gold.vw_remittance vrm
    )
SELECT
    ct.remittance_origin_country,
    ct.remittance_type,
    ct.remittance_transaction_count,
    ct.total_remittance_value,
    ct.average_remittance_amount,
    ct.active_customers,
    ROUND(CAST(ct.remittance_transaction_count AS FLOAT) * 100.0 / COT.country_transaction_count, 2) AS country_volume_share_pct,
    ROUND(CAST(ct.total_remittance_value AS FLOAT) * 100.0 / COT.country_remittance_value, 2)        AS country_value_share_pct,
    ROUND(CAST(ct.remittance_transaction_count AS FLOAT) * 100.0 / pt.overall_transaction_count, 2)  AS overall_volume_share_pct,
    ROUND(CAST(ct.total_remittance_value AS FLOAT) * 100.0 / pt.overall_remittance_value, 2)         AS overall_value_share_pct
FROM country_type ct
INNER JOIN country_totals COT ON
        ct.remittance_origin_country = COT.remittance_origin_country
CROSS JOIN population_totals pt
ORDER BY ct.remittance_origin_country,
    ct.remittance_type;

-- Origin Country × Channel
WITH country_channel
AS (
    SELECT
        vrm.remittance_origin_country,
        vrm.remittance_transaction_channel,
        COUNT(*)                        AS remittance_transaction_count,
        SUM(vrm.remittance_amount)      AS total_remittance_value,
        AVG(vrm.remittance_amount)      AS average_remittance_amount,
        COUNT(DISTINCT vrm.customer_id) AS active_customers
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_origin_country,
        vrm.remittance_transaction_channel
    ),
country_totals
AS (
    SELECT
        vrm.remittance_origin_country,
        COUNT(*)                   AS country_transaction_count,
        SUM(vrm.remittance_amount) AS country_remittance_value
    FROM gold.vw_remittance vrm
    GROUP BY vrm.remittance_origin_country
    ),
population_totals
AS (
    SELECT
        COUNT(*)                   AS overall_transaction_count,
        SUM(vrm.remittance_amount) AS overall_remittance_value
    FROM gold.vw_remittance vrm
    )
SELECT
    cc.remittance_origin_country,
    cc.remittance_transaction_channel,
    cc.remittance_transaction_count,
    cc.total_remittance_value,
    cc.average_remittance_amount,
    cc.active_customers,
    ROUND(CAST(cc.remittance_transaction_count AS FLOAT) * 100.0 / ct.country_transaction_count, 2) AS country_volume_share_pct,
    ROUND(CAST(cc.total_remittance_value AS FLOAT) * 100.0 / ct.country_remittance_value, 2)        AS country_value_share_pct,
    ROUND(CAST(cc.remittance_transaction_count AS FLOAT) * 100.0 / pt.overall_transaction_count, 2) AS overall_volume_share_pct,
    ROUND(CAST(cc.total_remittance_value AS FLOAT) * 100.0 / pt.overall_remittance_value, 2)        AS overall_value_share_pct
FROM country_channel cc
INNER JOIN country_totals ct ON
        cc.remittance_origin_country = ct.remittance_origin_country
CROSS JOIN population_totals pt
ORDER BY cc.remittance_origin_country,
    cc.remittance_transaction_channel;
/*
P5.2.5 — Remittance Behaviour
----------------------------------------------------------------------------------------------------------------------------------
NOTES
----------------------------------------------------------------------------------------------------------------------------------
- P5.2.5 examined Oman Remit remittance activity across transaction value, remittance direction, customer behaviour, frequency,
  customer concentration, temporal behaviour, channel, and origin country.
- 12,591 remittance transactions were analysed across 496 distinct customers.
- Total observed remittance value was GHS 11,620,120.51.
- Remittance amounts ranged from GHS 50.00 to GHS 13,476.04.
- Median remittance amount was GHS 635.02 compared with an average of approximately GHS 922.89, indicating a right-skewed
  transaction-value distribution.
- The P90, P95 and P99 remittance amounts were approximately GHS 1,918.33, GHS 2,638.95 and GHS 4,611.33 respectively.
- Received remittances accounted for 9,123 transactions, representing 72.46% of transaction volume and 72.40% of total value.
- Sent remittances accounted for 3,468 transactions, representing 27.54% of transaction volume and 27.60% of total value.
- The close alignment between direction-level volume and value shares indicates that the received/sent difference is primarily an
  activity-volume difference rather than a material difference in average transaction size.
- 453 customers (91.33%) both sent and received remittances.
- 39 customers (7.86%) were receive-only and 4 customers (0.81%) were send-only.
- Customers who both sent and received accounted for 98.60% of transactions and 98.63% of total remittance value.
- 492 customers had at least two observed remittance events and therefore had measurable inter-remittance intervals.
- The median inter-remittance interval was approximately 9.91 days, compared with an average of approximately 22.86 days,
  indicating a strongly right-skewed frequency distribution.
- The minimum observed inter-remittance interval was approximately 0.0003 days, or approximately 26 seconds, while the maximum
  exceeded 521 days.
- Customer concentration was relatively low. The top customer represented 1.62% of transaction volume and 1.61% of total value.
- The top five customers represented 6.13% of transaction volume and 6.54% of total value.
- The top ten customers represented 11.49% of transaction volume and 11.95% of total value, leaving 88.05% of total value outside
  the top ten customers.
- Remittance activity expanded substantially across the 2023–2025 observation period, with increasing transaction counts,
  transaction values and active customers.
- December recorded the highest absolute remittance activity in each observed year. December accounted for 23.00% of 2023
  transaction volume, 16.00% of 2024 volume and 12.54% of 2025 volume.
- The increasing absolute December activity alongside declining annual share indicates that overall population growth is an
  important factor. The December pattern should therefore be treated as recurring temporal concentration rather than definitive
  seasonality.
- Average monthly remittance amounts remained broadly stable, generally within approximately GHS 825–990, indicating that
  activity growth was driven primarily by increased transaction frequency and participation rather than major changes in
  transaction size.
- Agent was the largest remittance channel, accounting for 40.41% of transaction volume and 40.74% of total value.
- Mobile app accounted for 24.57% of volume and 24.68% of value, followed by third party at 15.16% and 14.86%, API at 9.95%
  and 9.93%, and web at 9.91% and 9.79%.
- Channel volume and value shares were closely aligned, indicating that channel differences were primarily differences in
  activity volume rather than material differences in transaction size.
- Origin-country analysis showed Ghana as the largest origin-country category at 27.54% of volume and 27.60% of value, followed
  by Nigeria, Côte d'Ivoire and the United States.
- Ghana, Nigeria, Côte d'Ivoire and the United States together accounted for approximately 67.92% of transaction volume and
  68.26% of total remittance value.
- The project specification explicitly defines Oman Remit's country relationship as an origin-country relationship. Ghana is
  the fixed destination and is not represented through a separate destination-country foreign key.
- The documented analytical classification therefore defines Ghana-origin activity as remittance_sent and non-Ghana-origin
  activity as remittance_received.
- The observed dataset conforms to this model: all Ghana-origin transactions are sent, while all foreign-origin transactions
  are received.
- This country-direction relationship is therefore a consequence of the approved source model rather than an unexplained
  analytical anomaly.
- The current Oman Remit source model does not contain a destination-country attribute. Consequently, outbound destination-country
  analysis is not available in P5.2.5.
- Country × channel analysis showed broadly consistent channel distributions across origin countries. Ghana follows the same
  general channel pattern as the foreign origin countries, providing no evidence that a particular channel is responsible for
  Ghana's prominence in the origin-country distribution.
- P5.2.5 remained descriptive and behavioural. No origin country, channel, direction, frequency pattern, transaction value, or
  customer concentration measure was treated as a standalone fraud or AML determination.
- P5.2.5 is therefore complete as an exploratory remittance-behaviour workload.
----------------------------------------------------------------------------------------------------------------------------------
INTELLIGENCE SIGNALS
----------------------------------------------------------------------------------------------------------------------------------
1. Remittance Direction
   Received activity represents approximately 72% of both transaction volume and value, while 91.33% of customers both send and
   receive. Direction therefore provides a useful customer-behaviour dimension for subsequent intelligence analysis.

2. Remittance Frequency
   The median inter-remittance interval of approximately 9.91 days establishes a useful behavioural baseline. Very short
   intervals, prolonged inactivity followed by renewed activity, or material changes from an established customer pattern may
   provide contextual signals for further investigation.

3. Transaction-Value Distribution
   The right-skewed transaction-value distribution and upper percentiles establish a baseline for identifying unusually large
   remittances relative to the broader Oman Remit population. High-value activity alone does not establish suspicious behaviour.

4. Customer Concentration
   The relatively low top-10 concentration indicates that remittance activity is broadly distributed across customers. Customer
   activity and value can nevertheless be retained as contextual features when combined with frequency, direction, channel and
   geographic behaviour.

5. Temporal Concentration
   Recurring high December activity provides a temporal context against which future activity can be compared. The pattern
   should not be treated as definitive seasonality because overall population growth contributes to the observed increase.

6. Channel Behaviour
   Agent and mobile app are the dominant channels, but channel volume and value distributions remain closely aligned across the
   population. Channel is therefore useful as a contextual dimension, particularly when combined with other behavioural
   attributes, rather than as an independent risk indicator.

7. Origin-Country Behaviour
   Origin country provides a useful geographic dimension for cross-border intelligence. However, its interpretation is constrained
   by the approved model in which origin country is explicitly tied to remittance direction and Ghana is the fixed destination.

8. Country-Direction Dependency
   Origin country and remittance direction are not independent dimensions in the current model. Ghana-origin activity represents
   outbound remittances, while non-Ghana origin activity represents inbound remittances. This dependency must be accounted for
   when interpreting country-level intelligence.

9. Country-Channel Behaviour
   Channel distributions remain broadly consistent across origin countries. No particular channel explains or materially
   amplifies the observed Ghana origin-country concentration.

10. Combined Behavioural Signals
    The strongest future intelligence value is likely to come from combinations of attributes rather than isolated measures.
    Customer identity, transaction value, frequency, direction, origin country, channel and temporal behaviour can be combined
    to identify behavioural changes or unusual combinations requiring further review.
----------------------------------------------------------------------------------------------------------------------------------
CONCLUSION
----------------------------------------------------------------------------------------------------------------------------------
P5.2.5 established a broad behavioural baseline for Oman Remit's cross-border remittance activity across value, direction,
customer behaviour, frequency, concentration, time, channel and origin country.
The population is dominated by received activity and customers who both send and receive, while customer concentration remains
relatively low. Remittance activity expanded materially across the observation period, with recurring December concentration, but
the evidence does not justify treating this as definitive seasonality. Channel behaviour is comparatively stable, with agent
activity representing the largest channel and volume and value shares remaining closely aligned.
The origin-country analysis produced an important model-context finding. The project specification explicitly defines
country_id as the remittance origin country, fixes Ghana as the destination, and does not provide a separate destination-country
field. The observed relationship in which Ghana occurs exclusively on sent transactions and foreign countries occur exclusively on
received transactions therefore conforms to the approved Oman Remit model. It should not be interpreted as a data anomaly.
However, the absence of a destination-country attribute means that outbound destination-country intelligence cannot currently be
performed.
Overall, the workload establishes multiple useful behavioural dimensions for later cross-domain intelligence. Frequency,
transaction-value distribution, temporal behaviour, customer concentration, direction, channel and origin country can provide
contextual signals when combined, while the documented country-direction dependency and destination-country limitation must be
preserved when interpreting future Oman Remit intelligence.
*/

