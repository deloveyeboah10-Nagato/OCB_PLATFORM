USE [ocb_platform];
GO

-- Unusual Overnight Transactions Behavioural Engine
-- 1. vw_signal_overnight_rapidity_score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_overnight_rapidity_score
AS
WITH overnight_transactions
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
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
        transaction_id,
        ocb_customer_id,
        overnight_date,
        transaction_timestamp,
        LAG(transaction_timestamp) OVER (
            PARTITION BY ocb_customer_id,
            overnight_date ORDER BY transaction_timestamp,
                transaction_id
            ) AS previous_transaction_timestamp
    FROM overnight_transactions
    ),
interval_data
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        overnight_date,
        transaction_timestamp,
        CAST(DATEDIFF_BIG(SECOND, previous_transaction_timestamp, transaction_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS interval_minutes
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
    d.ocb_customer_id,
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

-- Unusual Overnight Transactions Behavioural Engine
-- 2. vw_signal_overnight_value_score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_overnight_value_score
AS
WITH normal_hours
AS (
    SELECT
        ocb_customer_id,
        CAST(transaction_timestamp AS DATE) AS normal_date,
        SUM(transaction_amount)             AS normal_daily_value
    FROM gold.vw_transaction
    WHERE DATEPART(HOUR, transaction_timestamp) >= 6
            AND DATEPART(HOUR, transaction_timestamp) < 23
    GROUP BY ocb_customer_id,
        CAST(transaction_timestamp AS DATE)
    ),
customer_normal_baseline
AS (
    SELECT DISTINCT
        ocb_customer_id,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY normal_daily_value
            ) OVER (PARTITION BY ocb_customer_id) AS normal_hours_median_value
    FROM normal_hours
    ),
overnight_transactions
AS (
    SELECT
        ocb_customer_id,
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
        ocb_customer_id,
        overnight_date,
        COUNT(*)                AS overnight_txn_count,
        SUM(transaction_amount) AS overnight_total_value,
        MAX(transaction_amount) AS largest_transaction_value
    FROM overnight_transactions
    GROUP BY ocb_customer_id,
        overnight_date
    HAVING COUNT(*) >= 2
    ),
residuals
AS (
    SELECT
        cn.ocb_customer_id,
        cn.overnight_date,
        cn.overnight_txn_count,
        cn.overnight_total_value,
        cn.largest_transaction_value,
        b.normal_hours_median_value,
        cn.overnight_total_value - b.normal_hours_median_value AS value_residual
    FROM customer_night AS cn
    INNER JOIN customer_normal_baseline AS b ON
            cn.ocb_customer_id = b.ocb_customer_id
    ),
median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY value_residual
            ) OVER () AS population_median
    FROM residuals
    ),
deviations
AS (
    SELECT
        r.*,
        m.population_median,
        ABS(r.value_residual - m.population_median) AS absolute_deviation
    FROM residuals AS r
    CROSS JOIN median_calc AS m
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
    d.ocb_customer_id,
    d.overnight_date,
    d.overnight_txn_count,
    d.overnight_total_value,
    d.largest_transaction_value,
    d.normal_hours_median_value,
    d.value_residual,
    d.population_median,
    m.population_mad,
    CASE 
        WHEN d.value_residual > 0
                AND m.population_mad > 0
            THEN d.value_residual / m.population_mad
        ELSE 0
        END AS overnight_residual_score
FROM deviations AS d
CROSS JOIN mad_calc AS m;
GO

/*
-- WP5.3 Behavioural Anomaly Engine — Overnight Behaviour
-- The Overnight Behaviour component combines two signals:
-- Overnight Rapidity and Overnight Residual Value.
-- The overnight window is defined as 23:00–04:59.
-- Transactions at or after 23:00 retain their calendar date as overnight_date.
-- Transactions before 05:00 are assigned to the preceding calendar date.
-- This groups late-night and early-morning transactions into one overnight period.
-- OVERNIGHT RAPIDITY
-- Measures intervals between consecutive transactions for the same customer
-- within the same overnight_date.
-- LAG() retrieves the preceding transaction timestamp, ordered by timestamp
-- and transaction_id.
-- Inter-transaction intervals are measured in minutes and compared with the
-- global population median and Median Absolute Deviation (MAD).
-- Only intervals below the population median receive a positive MAD score.
-- Intervals at or above the median receive a score of zero.
-- OVERNIGHT RESIDUAL VALUE
-- Establishes a customer-specific baseline using daily transaction totals
-- recorded during normal hours, defined as 06:00–22:59.
-- The median of these daily totals represents the customer's typical
-- normal-hours transaction value.
-- Overnight transactions are aggregated by customer and overnight_date.
-- Only overnight periods containing at least two transactions are retained.
-- The overnight residual is overnight total value minus the customer's
-- median daily normal-hours value.
-- Positive residuals indicate overnight value exceeding the customer's
-- established normal-hours baseline.
-- Only positive residuals receive a positive score against the global
-- residual population using MAD.
-- Non-positive residuals receive a score of zero.
-- SIGNAL COMBINATION
-- The signals are assembled at customer + overnight_date grain wherever
-- the relevant overnight event exists.
-- Rapidity originates at transaction-interval grain and must be aggregated
-- when assembled with the event-level value signal.
-- The combination is an evidence assembly, not a mathematical composite score.
-- No weighting, normalisation, or unified overnight risk score is introduced.
-- All observed transaction types, including Merchant Payment, remain eligible.
-- Merchant Payment was assessed as a potential source of population
-- contamination, but its presence alone does not establish material distortion.
-- Available data does not reliably identify merchant roles to justify
-- a separate baseline.
-- Channel is not used as a merchant proxy because QR and Agent are
-- not merchant-exclusive.
-- The component identifies unusual overnight transaction speed and value.
-- These signals do not independently establish fraud, money laundering,
-- or other prohibited activity.
-- Their outputs provide behavioural evidence for subsequent intelligence
-- interpretation and investigation.
*/
-- S02 Overnight Behaviour Signal Combination
SELECT
    r.ocb_customer_id,
    r.overnight_date,
    v.overnight_txn_count,
    v.overnight_total_value,
    v.largest_transaction_value,
    MIN(r.interval_minutes)             AS minimum_interval_minutes,
    MAX(r.overnight_rapidity_mad_score) AS overnight_rapidity_mad_score,
    v.value_residual,
    v.population_median                 AS value_population_median,
    v.overnight_residual_score
FROM intelligence.vw_signal_overnight_rapidity_score AS r
LEFT JOIN intelligence.vw_signal_overnight_value_score AS v ON
        r.ocb_customer_id = v.ocb_customer_id
            AND r.overnight_date = v.overnight_date
GROUP BY r.ocb_customer_id,
    r.overnight_date,
    v.overnight_txn_count,
    v.overnight_total_value,
    v.largest_transaction_value,
    v.value_residual,
    v.population_median,
    v.overnight_residual_score
ORDER BY overnight_rapidity_mad_score DESC,
    v.overnight_residual_score DESC;
GO

-- Customer-Specific Cash-Out Escalation Anomaly Engine
-- 1. vw_cashout_escalation_score
CREATE
        OR

ALTER VIEW intelligence.vw_cashout_escalation_score
AS
WITH monthly_cash_out
AS (
    SELECT
        ocb_customer_id,
        DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1) AS year_month,
        YEAR(transaction_timestamp)                                                 AS txn_yr,
        COUNT(*)                                                                    AS cash_out_txns,
        SUM(transaction_amount)                                                     AS cash_out_value
    FROM gold.vw_transaction
    WHERE transaction_type = 'cash out'
    GROUP BY ocb_customer_id,
        DATEFROMPARTS(YEAR(transaction_timestamp), MONTH(transaction_timestamp), 1),
        YEAR(transaction_timestamp)
    ),
annual_percentile_analysis
AS (
    SELECT DISTINCT
        ocb_customer_id,
        txn_yr,
        AVG(cash_out_txns) OVER (
            PARTITION BY ocb_customer_id,
            txn_yr
            ) AS annual_avg_txns,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cash_out_txns
            ) OVER (
            PARTITION BY ocb_customer_id,
            txn_yr
            ) AS annual_median_monthly_txns,
        AVG(cash_out_value) OVER (
            PARTITION BY ocb_customer_id,
            txn_yr
            ) AS annual_avg_value,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cash_out_value
            ) OVER (
            PARTITION BY ocb_customer_id,
            txn_yr
            ) AS annual_median_monthly_value
    FROM monthly_cash_out
    ),
lagged_annual_baseline
AS (
    SELECT
        ocb_customer_id,
        txn_yr,
        LAG(annual_median_monthly_txns, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn_yr
            ) AS prev_yr_median_txns,
        annual_median_monthly_txns,
        LAG(annual_median_monthly_value, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn_yr
            ) AS prev_yr_median_value,
        annual_median_monthly_value
    FROM annual_percentile_analysis
    ),
variance_from_prev_yr
AS (
    SELECT
        c.ocb_customer_id,
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
            c.ocb_customer_id = b.ocb_customer_id
                AND c.txn_yr = b.txn_yr
    WHERE b.prev_yr_median_txns IS NOT NULL
    ),
population_median
AS (
    SELECT DISTINCT
        ocb_customer_id,
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
        v.ocb_customer_id,
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
            v.ocb_customer_id = m.ocb_customer_id
                AND v.year_month = m.year_month
    ),
mad_calc
AS (
    SELECT DISTINCT
        ocb_customer_id,
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
    d.ocb_customer_id,
    d.year_month,
    d.volume_variance_from_prev_yr,
    d.median_volume_variance,
    d.volume_deviation,
    CASE 
        WHEN d.volume_variance_from_prev_yr > 0
                AND m.mad_volume_variance > 0
            THEN d.volume_variance_from_prev_yr / m.mad_volume_variance
        ELSE 0
        END AS volume_escalation_score,
    d.value_variance_from_prev_yr,
    d.median_value_variance,
    d.value_deviation,
    CASE 
        WHEN d.value_variance_from_prev_yr > 0
                AND m.mad_value_variance > 0
            THEN d.value_variance_from_prev_yr / m.mad_value_variance
        ELSE 0
        END AS value_escalation_score
FROM absolute_deviation d
INNER JOIN mad_calc m ON
        d.ocb_customer_id = m.ocb_customer_id
            AND d.year_month = m.year_month;
GO

/*
-- WP5.3 Behavioural Anomaly Engine — Cash Out Escalation
-- Cash Out Escalation measures changes in customer Cash Out behaviour at customer + month grain across two
    independent dimensions: transaction volume and transaction value.
-- Monthly Cash Out activity is aggregated by customer and month to establish the behavioural unit used for the
    escalation analysis.
-- For each observed customer-year, the median monthly Cash Out transaction count and median monthly Cash Out value
    are calculated to represent the customer's typical monthly behaviour for that year.
-- The previous observed year's customer-specific median is used as the baseline for each current observed year.
-- LAG() is used to carry the previous observed Cash Out year into the current year's monthly observations.
-- This means the signal compares a customer's current monthly behaviour against the customer's previous observed
    Cash Out behaviour rather than against a global population baseline.
-- Where a customer has no Cash Out activity in an intervening calendar year, the previous observed Cash Out year is
    used as the available historical baseline.
-- Volume escalation is calculated as current monthly Cash Out transaction count minus the previous observed year's
    customer median transaction count.
-- Value escalation is calculated as current monthly Cash Out value minus the previous observed year's customer median
    transaction value.
-- The resulting residuals are evaluated against population-level median and MAD measures to provide a robust scale
    for unusual escalation.
-- Cash Out Escalation is explicitly directional: only positive residuals receive a positive score.
-- Months at or below the customer's previous observed baseline receive a score of zero.
-- Volume and value remain separate signals because increased Cash Out frequency and increased Cash Out value represent
    different behavioural dimensions and can escalate independently.
-- Cash Out Escalation is a customer trajectory signal rather than a transaction-level anomaly signal.
-- The signal therefore identifies material upward changes in a customer's Cash Out behaviour relative to their own
    historical pattern.
-- The resulting scores provide behavioural escalation evidence and do not independently establish fraud, money
    laundering, or other prohibited activity.
*/
