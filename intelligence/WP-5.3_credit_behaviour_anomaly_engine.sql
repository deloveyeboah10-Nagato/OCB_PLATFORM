USE [ocb_platform];
GO


WITH annual_borrowing AS (
    SELECT
        customer_id,
        YEAR(disbursement_timestamp) AS loan_year,
        COUNT(*) AS annual_loan_count,
        SUM(principal_amount) AS annual_loan_value
    FROM gold.vw_loan
    GROUP BY
        customer_id,
        YEAR(disbursement_timestamp)
)
SELECT DISTINCT
    COUNT(*) OVER () AS observation_count,

    MIN(annual_loan_count) OVER () AS min_loan_count,
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS p25_loan_count,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS median_loan_count,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS p75_loan_count,
    PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS p90_loan_count,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS p95_loan_count,
    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY annual_loan_count) OVER () AS p99_loan_count,
    MAX(annual_loan_count) OVER () AS max_loan_count,

    MIN(annual_loan_value) OVER () AS min_loan_value,
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS p25_loan_value,
    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS median_loan_value,
    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS p75_loan_value,
    PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS p90_loan_value,
    PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS p95_loan_value,
    PERCENTILE_CONT(0.99)
        WITHIN GROUP (ORDER BY annual_loan_value) OVER () AS p99_loan_value,
    MAX(annual_loan_value) OVER () AS max_loan_value
FROM annual_borrowing;

-- credit behaviour engine
WITH annual_borrowing AS (
    SELECT
        customer_id,
        YEAR(disbursement_timestamp) AS loan_year,
        SUM(principal_amount) AS annual_loan_value
    FROM gold.vw_loan
    GROUP BY
        customer_id,
        YEAR(disbursement_timestamp)
),
annual_median AS (
    SELECT DISTINCT
        customer_id,
        loan_year,
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (ORDER BY annual_loan_value)
            OVER (
                PARTITION BY customer_id, loan_year
            ) AS annual_median_loan_value
    FROM annual_borrowing
),
lagged_baseline AS (
    SELECT
        customer_id,
        loan_year,
        annual_median_loan_value,
        LAG(annual_median_loan_value)
            OVER (
                PARTITION BY customer_id
                ORDER BY loan_year
            ) AS prev_yr_median_loan_value
    FROM annual_median
),
variance_from_prev_yr AS (
    SELECT
        a.customer_id,
        a.loan_year,
        a.annual_loan_value - b.prev_yr_median_loan_value
            AS loan_value_variance_from_prev_yr
    FROM annual_borrowing AS a
    INNER JOIN lagged_baseline AS b
        ON a.customer_id = b.customer_id
       AND a.loan_year = b.loan_year
    WHERE b.prev_yr_median_loan_value IS NOT NULL
),
population_median AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50)
            WITHIN GROUP (
                ORDER BY loan_value_variance_from_prev_yr
            ) OVER () AS median_variance
    FROM variance_from_prev_yr
),
absolute_deviation AS (
    SELECT
        v.loan_value_variance_from_prev_yr,
        p.median_variance,
        ABS(
            v.loan_value_variance_from_prev_yr - p.median_variance
        ) AS deviation
    FROM variance_from_prev_yr AS v
    INNER JOIN population_median AS p
        ON 1 = 1
)
SELECT DISTINCT
    COUNT(*) OVER () AS observation_count,

    MIN(loan_value_variance_from_prev_yr) OVER () AS min_variance,

    PERCENTILE_CONT(0.25)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS p25_variance,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS median_variance,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS p75_variance,

    PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS p90_variance,

    PERCENTILE_CONT(0.95)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS p95_variance,

    PERCENTILE_CONT(0.99)
        WITHIN GROUP (
            ORDER BY loan_value_variance_from_prev_yr
        ) OVER () AS p99_variance,

    MAX(loan_value_variance_from_prev_yr) OVER () AS max_variance,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY deviation) OVER () AS mad_variance

FROM absolute_deviation;