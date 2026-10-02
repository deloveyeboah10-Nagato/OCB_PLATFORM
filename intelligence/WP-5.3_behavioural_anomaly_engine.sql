USE [ocb_platform];
GO


-- Unusual Overnight Transactions Behavioural Engine

-- vw_signal_overnight_rapidity_score
CREATE OR ALTER VIEW intelligence.vw_signal_overnight_rapidity_score
AS
WITH overnight_transactions
AS (
    SELECT
        customer_id,
        transaction_timestamp,
        CAST(CASE 
                WHEN DATEPART(HOUR, transaction_timestamp) >= 23
                    THEN CAST(transaction_timestamp AS DATE)
                ELSE DATEADD(DAY, - 1, CAST(transaction_timestamp AS DATE))
                END AS DATE) AS overnight_date
    FROM gold.vw_transaction
    WHERE DATEPART(HOUR, transaction_timestamp) >= 23
            OR DATEPART(HOUR, transaction_timestamp) < 5
    ),
rapid_intervals
AS (
    SELECT
        customer_id,
        overnight_date,
        transaction_timestamp,
        LAG(transaction_timestamp) OVER (
            PARTITION BY customer_id,
            overnight_date ORDER BY transaction_timestamp
            ) AS previous_transaction_timestamp
    FROM overnight_transactions
    ),
interval_data
AS (
    SELECT
        customer_id,
        overnight_date,
        transaction_timestamp,
        DATEDIFF(SECOND, previous_transaction_timestamp, transaction_timestamp) / 60.0 AS interval_minutes
    FROM rapid_intervals
    WHERE previous_transaction_timestamp IS NOT NULL
    ),
median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY interval_minutes
            ) OVER () AS population_median
    FROM interval_data
    ),
deviations
AS (
    SELECT
        i.*,
        m.population_median,
        CASE 
            WHEN i.interval_minutes < m.population_median
                THEN m.population_median - i.interval_minutes
            ELSE 0
            END AS lower_tail_deviation
    FROM interval_data AS i
    CROSS JOIN median_calc AS m
    ),
mad_calc
AS (
    SELECT DISTINCT
        population_median,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(interval_minutes - population_median)
            ) OVER () AS population_mad
    FROM deviations
    )
SELECT
    d.customer_id,
    d.overnight_date,
    d.transaction_timestamp,
    d.interval_minutes,
    d.population_median,
    m.population_mad,
    CASE 
        WHEN d.interval_minutes < d.population_median
                AND m.population_mad > 0
            THEN d.lower_tail_deviation / m.population_mad
        ELSE 0
        END AS overnight_rapidity_mad_score
FROM deviations AS d
CROSS JOIN mad_calc AS m;
GO

-- vw_signal_overnight_value_score
CREATE OR ALTER VIEW intelligence.vw_signal_overnight_value_score
AS
WITH overnight_transactions
AS (
    SELECT
        customer_id,
        transaction_timestamp,
        transaction_amount,
        CAST(CASE 
                WHEN DATEPART(HOUR, transaction_timestamp) >= 23
                    THEN CAST(transaction_timestamp AS DATE)
                ELSE DATEADD(DAY, - 1, CAST(transaction_timestamp AS DATE))
                END AS DATE) AS overnight_date
    FROM gold.vw_transaction
    WHERE DATEPART(HOUR, transaction_timestamp) >= 23
            OR DATEPART(HOUR, transaction_timestamp) < 5
    ),
customer_night
AS (
    SELECT
        customer_id,
        overnight_date,
        COUNT(*)                AS overnight_txn_count,
        SUM(transaction_amount) AS overnight_total_value,
        MAX(transaction_amount) AS largest_transaction_value
    FROM overnight_transactions
    GROUP BY customer_id,
        overnight_date
    HAVING COUNT(*) >= 2
    ),
median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY overnight_total_value
            ) OVER () AS population_median
    FROM customer_night
    ),
deviations
AS (
    SELECT
        cn.*,
        mc.population_median,
        ABS(cn.overnight_total_value - mc.population_median) AS absolute_deviation
    FROM customer_night AS cn
    CROSS JOIN median_calc AS mc
    ),
mad_calc
AS (
    SELECT DISTINCT
        population_median,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS population_mad
    FROM deviations
    )
SELECT
    d.customer_id,
    d.overnight_date,
    d.overnight_txn_count,
    d.overnight_total_value,
    d.largest_transaction_value,
    d.largest_transaction_value / NULLIF(d.overnight_total_value, 0) AS largest_transaction_share,
    d.population_median,
    m.population_mad,
    CASE 
        WHEN d.overnight_total_value > d.population_median
                AND m.population_mad > 0
            THEN (d.overnight_total_value - d.population_median) / m.population_mad
        ELSE 0
        END AS overnight_value_mad_score
FROM deviations AS d
CROSS JOIN mad_calc AS m;
GO

-- S02 combination query
SELECT
    r.customer_id,
    r.overnight_date,
    v.overnight_txn_count,
    v.overnight_total_value,
    v.largest_transaction_value,
    v.largest_transaction_share,
    MIN(r.interval_minutes)             AS minimum_interval_minutes,
    MAX(r.overnight_rapidity_mad_score) AS overnight_rapidity_mad_score,
    v.overnight_value_mad_score
FROM intelligence.vw_signal_overnight_rapidity_score AS r
JOIN intelligence.vw_signal_overnight_value_score AS v ON
        r.customer_id = v.customer_id
            AND r.overnight_date = v.overnight_date
GROUP BY r.customer_id,
    r.overnight_date,
    v.overnight_txn_count,
    v.overnight_total_value,
    v.largest_transaction_value,
    v.largest_transaction_share,
    v.overnight_value_mad_score
ORDER BY overnight_rapidity_mad_score DESC,
    overnight_value_mad_score DESC;

-- Customer-Specific Cash-Out Escalation Anomaly Engine

-- cash out profile
SELECT
    customer_id,
    DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1) AS year_month,
    COUNT(*)                                                                    AS cash_out_txns,
    SUM(transaction_amount)                                                     AS cash_out_value,
    AVG(transaction_amount)                                                     AS cash_out_avg
FROM gold.vw_transaction
WHERE transaction_type = 'cash out'
GROUP BY customer_id,
    DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1)
ORDER BY customer_id,
    year_month;
GO

-- vw_cashout_escalation_score (Time series trajectory (using the median) )
CREATE OR ALTER VIEW intelligence.vw_cashout_escalation_score AS
WITH monthly_cash_out
AS (
    SELECT
        customer_id,
        DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1) AS year_month,
        YEAR(transaction_timestamp)                                                 AS txn_yr,
        COUNT(*)                                                                    AS cash_out_txns,
        SUM(transaction_amount)                                                     AS cash_out_value
    FROM gold.vw_transaction
    WHERE transaction_type = 'cash out'
    GROUP BY customer_id,
        DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1),
        YEAR(transaction_timestamp)
    ),
annual_percentile_analysis
AS (
    SELECT DISTINCT
        customer_id,
        txn_yr,
        AVG(cash_out_txns) OVER (
            PARTITION BY customer_id,
            txn_yr
            ) AS annual_avg_txns,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cash_out_txns
            ) OVER (
            PARTITION BY customer_id,
            txn_yr
            ) AS annual_median_monthly_txns,
        AVG(cash_out_value) OVER (
            PARTITION BY customer_id,
            txn_yr
            ) AS annual_avg_value,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cash_out_value
            ) OVER (
            PARTITION BY customer_id,
            txn_yr
            ) AS annual_median_monthly_value
    FROM monthly_cash_out
    ),
lagged_annual_baseline
AS (
    SELECT
        customer_id,
        txn_yr,
        LAG(annual_median_monthly_txns, 1) OVER (
            PARTITION BY customer_id ORDER BY txn_yr
            ) AS prev_yr_median_txns,
        annual_median_monthly_txns,
        LAG(annual_median_monthly_value, 1) OVER (
            PARTITION BY customer_id ORDER BY txn_yr
            ) AS prev_yr_median_value,
        annual_median_monthly_value
    FROM annual_percentile_analysis
    ),
variance_from_prev_yr
AS (
    SELECT
        c.customer_id,
        c.year_month,
        c.txn_yr,
        b.prev_yr_median_txns,
        c.cash_out_txns,
        -- b.current_annual_median_txns,
        c.cash_out_txns - b.prev_yr_median_txns   AS volume_variance_from_prev_yr,
        b.prev_yr_median_value,
        c.cash_out_value,
        --b.current_annual_median_value,
        c.cash_out_value - b.prev_yr_median_value AS value_variance_from_prev_yr
    FROM monthly_cash_out c
    INNER JOIN lagged_annual_baseline b ON
            c.customer_id = b.customer_id
                AND c.txn_yr = b.txn_yr
    WHERE b.prev_yr_median_txns IS NOT NULL
    ),
population_median
AS (
    SELECT DISTINCT
        customer_id,
        year_month,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY volume_variance_from_prev_yr
            ) OVER () AS median_volume_variance,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY value_variance_from_prev_yr
            ) OVER () AS median_value_variance
    FROM variance_from_prev_yr
    ),
absolute_deviation
AS (
    SELECT
        v.customer_id,
        v.year_month,
        txn_yr,
        v.volume_variance_from_prev_yr,
        m.median_volume_variance,
        ABS(v.volume_variance_from_prev_yr - m.median_volume_variance) AS volume_deviation,
        v.value_variance_from_prev_yr,
        m.median_value_variance,
        ABS(v.value_variance_from_prev_yr - m.median_value_variance)   AS value_deviation
    FROM variance_from_prev_yr v
    INNER JOIN population_median m ON
            v.customer_id = m.customer_id
                AND v.year_month = m.year_month
    ),
mad_calc
AS (
    SELECT DISTINCT
        customer_id,
        year_month,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY volume_deviation
            ) OVER () AS mad_volume_variance,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY value_deviation
            ) OVER () AS mad_value_variance
    FROM absolute_deviation
    )
SELECT
    d.customer_id,
    d.year_month,
    d.volume_variance_from_prev_yr,
    d.median_volume_variance,
    d.volume_deviation,
    (d.volume_variance_from_prev_yr - d.median_volume_variance) / m.mad_volume_variance AS volume_escalation_score,
    d.value_variance_from_prev_yr,
    d.median_value_variance,
    d.value_deviation,
    (d.value_variance_from_prev_yr - d.median_value_variance) / m.mad_value_variance AS value_escalation_score
FROM absolute_deviation d
INNER JOIN mad_calc m ON
        d.customer_id = m.customer_id
            AND d.year_month = m.year_month;

