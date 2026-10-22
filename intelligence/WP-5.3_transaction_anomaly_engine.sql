USE [ocb_platform];
GO

-- Create Schema for the views
IF NOT EXISTS (
        SELECT
            *
        FROM sys.schemas
        WHERE name = N'intelligence'
        )
BEGIN
    EXEC ('CREATE SCHEMA intelligence;')
END
GO

-- 1. global anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_global_score
AS
WITH transaction_population
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        transaction_timestamp,
        transaction_type,
        transaction_amount,
        LOG(1.0 + transaction_amount) AS log_transaction_amount
    FROM gold.vw_transaction
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_transaction_amount
            ) OVER () AS global_median
    FROM transaction_population
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(log_transaction_amount - global_median) AS absolute_deviation
    FROM median_calc
    ),
mad_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS global_mad
    FROM absolute_deviations
    )
SELECT
    transaction_id,
    ocb_customer_id,
    transaction_timestamp,
    transaction_type,
    transaction_amount,
    log_transaction_amount,
    global_median,
    global_mad,
    CASE 
        WHEN global_mad > 0
                AND log_transaction_amount > global_median
            THEN (log_transaction_amount - global_median) / global_mad
        ELSE 0
        END AS global_amount_score
FROM mad_calc;
GO

-- 2. customer anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_customer_score
AS
WITH monthly_customer_activity
AS (
    SELECT
        ocb_customer_id,
        CONVERT(CHAR(7), transaction_timestamp, 120) AS year_month,
        SUM(transaction_amount)                      AS monthly_transaction_value
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
    AND transaction_status='successful'
    GROUP BY ocb_customer_id,
        CONVERT(CHAR(7), transaction_timestamp, 120)
    ),
log_transformed
AS (
    SELECT
        ocb_customer_id,
        year_month,
        monthly_transaction_value,
        LOG(1.0 + monthly_transaction_value) AS log_monthly_transaction_value
    FROM monthly_customer_activity
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_monthly_transaction_value
            ) OVER (PARTITION BY ocb_customer_id) AS customer_median
    FROM log_transformed
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(log_monthly_transaction_value - customer_median) AS absolute_deviation
    FROM median_calc
    ),
mad_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER (PARTITION BY ocb_customer_id) AS customer_mad
    FROM absolute_deviations
    )
SELECT
    ocb_customer_id,
    year_month,
    monthly_transaction_value,
    log_monthly_transaction_value,
    customer_median,
    customer_mad,
    CASE 
        WHEN customer_mad > 0
                AND log_monthly_transaction_value > customer_median
            THEN (log_monthly_transaction_value - customer_median) / customer_mad
        ELSE 0
        END AS customer_amount_score
FROM mad_calc;
GO

-- 3. transaction-type anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_transaction_type_score
AS
WITH transaction_population
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        transaction_timestamp,
        transaction_type,
        transaction_amount,
        LOG(1.0 + transaction_amount) AS log_transaction_amount
    FROM gold.vw_transaction
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_transaction_amount
            ) OVER (PARTITION BY transaction_type) AS txn_type_median
    FROM transaction_population
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(log_transaction_amount - txn_type_median) AS absolute_deviation
    FROM median_calc
    ),
mad_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER (PARTITION BY transaction_type) AS txn_type_mad
    FROM absolute_deviations
    )
SELECT
    transaction_id,
    ocb_customer_id,
    transaction_timestamp,
    transaction_type,
    transaction_amount,
    log_transaction_amount,
    txn_type_median,
    txn_type_mad,
    CASE 
        WHEN txn_type_mad > 0
                AND log_transaction_amount > txn_type_median
            THEN (log_transaction_amount - txn_type_median) / txn_type_mad
        ELSE 0
        END AS transaction_type_amount_score
FROM mad_calc;
GO

-- 4. temporal anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_velocity_score
AS
WITH transaction_sequence
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        transaction_timestamp,
        transaction_type,
        transaction_amount,
        LAG(transaction_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS previous_transaction_timestamp
    FROM gold.vw_transaction
    ),
transaction_intervals
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        transaction_timestamp,
        transaction_type,
        transaction_amount,
        previous_transaction_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, previous_transaction_timestamp, transaction_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS txn_interval_mins
    FROM transaction_sequence
    WHERE previous_transaction_timestamp IS NOT NULL
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY txn_interval_mins
            ) OVER () AS txn_interval_mins_median
    FROM transaction_intervals
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(txn_interval_mins - txn_interval_mins_median) AS absolute_deviation
    FROM median_calc
    ),
mad_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS txn_interval_mins_mad
    FROM absolute_deviations
    )
SELECT
    transaction_id,
    ocb_customer_id,
    transaction_timestamp,
    transaction_type,
    transaction_amount,
    previous_transaction_timestamp,
    txn_interval_mins,
    txn_interval_mins_median,
    txn_interval_mins_mad,
    CASE 
        WHEN txn_interval_mins < txn_interval_mins_median
                AND txn_interval_mins_mad > 0
            THEN (txn_interval_mins_median - txn_interval_mins) / txn_interval_mins_mad
        ELSE 0
        END AS velocity_score
FROM mad_calc
WHERE txn_interval_mins < txn_interval_mins_median;
GO

/*
-- WP5.3 Transaction Anomaly Engine — Signal Construction and Combination Analysis
-- The Transaction Anomaly Engine was designed to identify unusual transaction amounts from three value perspectives
-- and one temporal perspective: Global Amount, Customer Amount, Transaction-Type Amount, and Velocity.
-- The four signals were constructed independently to preserve the distinction between population-relative value
-- deviations, customer-relative value deviations, transaction-type-relative value deviations, and transaction
-- timing patterns.
-- Global Amount measures how far a transaction amount exceeds the median transaction amount across the complete
-- transaction population.
-- The Global Amount baseline was calculated using all transaction types in gold.vw_transaction.
-- Individual transaction amounts were transformed using LOG(1.0 + transaction_amount) before calculating the
-- global median and MAD. The original transaction amount was retained alongside its transformed value.
-- Global Amount was scored using the log-transformed transaction amount, global log median, and global MAD,
-- with transactions above the global log median receiving positive scores when the global MAD was greater than
-- zero. Transactions at or below the median, or where the MAD was not positive, received zero.
-- Customer Amount measures how far a customer's successful monthly aggregated non-merchant transaction value exceeds the
-- customer's typical monthly non-merchant transaction value.
-- Merchant Payments were excluded from the Customer Amount scoring population because payments to wholesalers
-- and large retailers can naturally be substantially larger than a customer's personal transfers and other
-- non-merchant activity. Including these payments could distort the customer's baseline for non-merchant activity.
-- Transaction amounts were first aggregated by customer and calendar month to establish the monthly transaction
-- value. The monthly aggregate was then transformed using LOG(1.0 + monthly_transaction_value).
-- Customer-specific medians and MAD values were calculated independently for each customer using the log-transformed
-- monthly transaction values.
-- Customer Amount was scored using the customer's log median and MAD, with customer-month observations above the
-- customer's log median receiving positive scores when the customer MAD was greater than zero. Observations at or
-- below the log median, or where the MAD was not positive, received zero.
-- Merchant Payments were consequently excluded from both the Customer Amount baseline and its scored output.
-- Customer Amount produces one observation per customer per month rather than one observation per transaction.
-- When combined with transaction-level signals, the customer-month value and score are repeated across the
-- customer's transactions within the corresponding month. This preserves the transaction population but does not
-- make the repeated customer-month score a separate anomaly observation for every transaction.
-- Transaction-Type Amount measures how far a transaction amount exceeds the typical amount for its own transaction
-- type.
-- Separate medians and MAD values were calculated for each transaction type using log-transformed individual
-- transaction amounts, so that transaction amounts were evaluated against transactions of the same type rather
-- than against a shared transaction-type baseline.
-- The original transaction amount was retained alongside its log-transformed value.
-- Transaction-Type Amount was scored using the log-transformed transaction amount, transaction-type log median,
-- and transaction-type MAD, with transactions above the relevant log median receiving positive scores when the
-- transaction-type MAD was greater than zero. Transactions at or below the log median, or where the MAD was not
-- positive, received zero.
-- Velocity measures the elapsed time between consecutive transactions belonging to the same customer.
-- The preceding transaction timestamp was identified using LAG() over customer transactions ordered by
-- transaction_timestamp and transaction_id.
-- Transaction timestamp establishes chronological ordering, while transaction_id provides a deterministic
-- secondary ordering when multiple transactions belonging to the same customer share an identical timestamp.
-- This tie-breaker makes the preceding-transaction assignment reproducible without claiming to establish the
-- actual temporal order of transactions sharing the same timestamp.
-- The elapsed interval was calculated in minutes between the preceding transaction and the current transaction.
-- A global median and MAD were calculated over the resulting transaction-interval population.
-- Only transactions with preceding intervals shorter than the global median were retained in the Velocity output.
-- Velocity scores were positive when the interval was below the global median and the global MAD was greater than
-- zero. The score increases as the elapsed interval becomes shorter relative to the population median and MAD.
-- Transactions without a preceding transaction, and transactions whose intervals were at or above the global
-- median, were excluded from the Velocity output.
-- Across the four signals, the scoring direction was intentionally one-sided: unusually high transaction amounts
-- and unusually short transaction intervals received positive scores, while observations that did not meet the
-- relevant directional condition received zero or were excluded by the signal's population definition.
-- The amount-based signals calculate their medians and MAD values in log space. Their resulting scores therefore
-- express deviations in units of the MAD of the log-transformed values, not in currency units or percentages.
-- The LOG(1.0 + amount) transformation reduces the influence of large transaction values on the scale of the
-- distribution while preserving the ordering of non-negative transaction amounts.
-- The MAD > 0 condition prevents division by zero and ensures that a positive anomaly score is only calculated
-- where the relevant population has a positive MAD.
-- The four signals were previously evaluated together using the 95th percentile of each signal as an exploratory
-- high-deviation marker. This marker was used to examine signal populations and their intersections, not as a
-- universal anomaly threshold.
-- The combination analysis preserved the full transaction population of 772,381 transactions using LEFT JOINs.
-- This was necessary because Customer Amount operates at customer-month grain and excludes Merchant Payments,
-- while Velocity has a restricted output population consisting only of transactions with preceding intervals
-- below the global median.
-- Global Amount and Transaction-Type Amount each previously identified 38,620 transactions above their respective
-- P95 markers. Customer Amount previously identified 32,242 observations above its P95 marker, while Velocity
-- previously identified 19,238 transactions.
-- Pairwise overlap results from the previous signal definitions were: Global + Customer = 4,684;
-- Global + Transaction Type = 11,206; Global + Velocity = 1,115; Customer + Transaction Type = 10,622;
-- Customer + Velocity = 839; and Transaction Type + Velocity = 1,273.
-- Three-signal overlap results from the previous signal definitions were: Global + Customer + Transaction Type
-- = 4,684; Global + Customer + Velocity = 152; Global + Transaction Type + Velocity = 373; and
-- Customer + Transaction Type + Velocity = 354.
-- All four signals previously exceeded their respective P95 markers for 152 transactions, representing
-- approximately 0.02% of the full transaction population.
-- These P95 counts and overlap results belong to the previous signal definitions and must not be treated as
-- results of the revised log-transformed amount signals and monthly Customer Amount aggregation.
-- The P95 markers and intersection counts must be recalculated using the revised signal outputs before drawing
-- conclusions about the current overlap between the four signals.
-- The overlap analysis is intended to establish whether the signals identify intersecting or distinct
-- high-deviation populations. Global Amount provides an overall transaction-value reference, Customer Amount
-- provides a customer-relative reference for monthly non-merchant activity, Transaction-Type Amount provides a
-- transaction-type-relative reference, and Velocity contributes a temporal dimension.
-- The intersection of all four signals identifies observations that simultaneously exceed all four exploratory
-- P95 markers. It does not establish that these observations are fraudulent, suspicious, or inherently higher risk.
-- The P95 analysis is exploratory and is not adopted as a universal anomaly threshold.
-- The analysis does not justify weighting, normalising, or mathematically combining the four signal scores into a
-- single risk score.
-- The signals are retained as independent analytical constructs so that each can be interpreted according to its
-- own population, baseline, scoring direction, and analytical purpose.
-- Signal combinations remain contextual. Different analytical workloads may use different combinations depending
-- on whether the investigation concerns overall transaction-value deviation, customer-relative monthly behaviour,
-- transaction-type-relative behaviour, rapid transaction activity, or a combination of these dimensions.
-- Global Amount remains a population-level reference signal rather than a weighting or balancing mechanism.
-- The analysis identifies statistical deviations and transaction-timing patterns; it does not independently
-- establish customer intent, explain the underlying cause of a deviation, or prove financial misconduct.
-- The final Transaction Anomaly Engine therefore provides four independent dimensions of transaction intelligence:
-- overall amount deviation, customer-relative monthly amount deviation, transaction-type-relative amount deviation,
-- and transaction velocity.
-- The Transaction Anomaly Engine is evaluated through its independent signals and their high-deviation population
-- intersections, with the amount-based signals calculated in log space and Customer Amount operating at customer-
-- month grain.
*/
-- Multi-dimensional signal combination
WITH transaction_signal_population
AS (
    SELECT
        g.transaction_id,
        g.ocb_customer_id,
        g.transaction_timestamp,
        CONVERT(CHAR(7), g.transaction_timestamp, 120) AS year_month,
        g.transaction_type,
        g.transaction_amount,
        g.log_transaction_amount,
        g.global_median,
        g.global_mad,
        g.global_amount_score,
        t.txn_type_median,
        t.txn_type_mad,
        t.transaction_type_amount_score,
        v.previous_transaction_timestamp,
        v.txn_interval_mins,
        v.txn_interval_mins_median,
        v.txn_interval_mins_mad,
        v.velocity_score
    FROM intelligence.vw_signal_global_score AS g
    LEFT JOIN intelligence.vw_signal_transaction_type_score AS t ON
            g.transaction_id = t.transaction_id
    LEFT JOIN intelligence.vw_signal_velocity_score AS v ON
            g.transaction_id = v.transaction_id
    ),
combined_signals
AS (
    SELECT
        p.*,
        c.monthly_transaction_value,
        c.log_monthly_transaction_value,
        c.customer_median,
        c.customer_mad,
        c.customer_amount_score
    FROM transaction_signal_population AS p
    LEFT JOIN intelligence.vw_signal_customer_score AS c ON
            p.ocb_customer_id = c.ocb_customer_id
                AND p.year_month = c.year_month
    )
SELECT
    transaction_id,
    ocb_customer_id,
    transaction_timestamp,
    year_month,
    transaction_type,
    transaction_amount,
    -- Global Amount
    log_transaction_amount,
    global_amount_score,
    -- Customer Amount: monthly customer aggregate
    monthly_transaction_value,
    log_monthly_transaction_value,
    customer_amount_score,
    -- Transaction-Type Amount
    transaction_type_amount_score,
    -- Velocity
    txn_interval_mins,
    velocity_score
FROM combined_signals;
GO



