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
        transaction_amount
    FROM gold.vw_transaction
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER () AS global_median
    FROM transaction_population
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(transaction_amount - global_median) AS absolute_deviation
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
    global_median,
    global_mad,
    CASE 
        WHEN global_mad > 0
                AND transaction_amount > global_median
            THEN (transaction_amount - global_median) / global_mad
        ELSE 0
        END AS global_amount_score
FROM mad_calc;
GO

-- 2. customer anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_customer_score
AS
WITH transaction_population
AS (
    SELECT
        transaction_id,
        ocb_customer_id,
        transaction_timestamp,
        transaction_type,
        transaction_amount
    FROM gold.vw_transaction
    WHERE transaction_type <> 'merchant payment'
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (PARTITION BY ocb_customer_id) AS customer_median
    FROM transaction_population
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(transaction_amount - customer_median) AS absolute_deviation
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
    transaction_id,
    ocb_customer_id,
    transaction_timestamp,
    transaction_type,
    transaction_amount,
    customer_median,
    customer_mad,
    CASE 
        WHEN customer_mad > 0
                AND transaction_amount > customer_median
            THEN (transaction_amount - customer_median) / customer_mad
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
        transaction_amount
    FROM gold.vw_transaction
    ),
median_calc
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount
            ) OVER (PARTITION BY transaction_type) AS txn_type_median
    FROM transaction_population
    ),
absolute_deviations
AS (
    SELECT
        *,
        ABS(transaction_amount - txn_type_median) AS absolute_deviation
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
    txn_type_median,
    txn_type_mad,
    CASE 
        WHEN txn_type_mad > 0
                AND transaction_amount > txn_type_median
            THEN (transaction_amount - txn_type_median) / txn_type_mad
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
-- Global Amount was scored using the population median and MAD, with transactions above the global median receiving
-- positive scores when the global MAD was greater than zero. Transactions at or below the median, or where the
-- MAD was not positive, received zero.
-- Customer Amount measures how far a transaction amount exceeds the customer's typical non-merchant transaction
-- amount.
-- Merchant Payments were excluded from the Customer Amount scoring population because payments to wholesalers
-- and large retailers can naturally be substantially larger than a customer's personal transfers and other
-- non-merchant activity. Including these payments could distort the customer's baseline for non-merchant activity.
-- Customer-specific medians and MAD values were calculated independently for each customer using the remaining
-- transaction population.
-- Customer Amount was scored using the customer's median and MAD, with transactions above the customer's median
-- receiving positive scores when the customer MAD was greater than zero. Transactions at or below the median,
-- or where the MAD was not positive, received zero.
-- Merchant Payments were consequently excluded from both the Customer Amount baseline and its scored output.
-- Transaction-Type Amount measures how far a transaction amount exceeds the typical amount for its own transaction
-- type.
-- Separate medians and MAD values were calculated for each transaction type so that transaction amounts were
-- evaluated against transactions of the same type rather than against a shared transaction-type baseline.
-- Transaction-Type Amount was scored using the transaction-type median and MAD, with transactions above the
-- relevant median receiving positive scores when the transaction-type MAD was greater than zero. Transactions at
-- or below the median, or where the MAD was not positive, received zero.
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
-- The MAD > 0 condition prevents division by zero and ensures that a positive anomaly score is only calculated
-- where the relevant population has a positive MAD.
-- The four signals were evaluated together using the 95th percentile of each signal as an exploratory high-deviation
-- marker. This marker was used to examine signal populations and their intersections, not as a universal anomaly
-- threshold.
-- The combination analysis preserved the full transaction population of 772,381 transactions using LEFT JOINs.
-- This was necessary because Customer Amount excludes Merchant Payments and Velocity has a restricted output
-- population consisting only of transactions with preceding intervals below the global median.
-- Global Amount and Transaction-Type Amount each identified 38,620 transactions above their respective P95 markers.
-- Customer Amount identified 32,242 transactions above its P95 marker, while Velocity identified 19,238.
-- Pairwise overlap results were: Global + Customer = 4,684; Global + Transaction Type = 11,206; Global + Velocity
-- = 1,115; Customer + Transaction Type = 10,622; Customer + Velocity = 839; and Transaction Type + Velocity = 1,273.
-- Three-signal overlap results were: Global + Customer + Transaction Type = 4,684; Global + Customer + Velocity
-- = 152; Global + Transaction Type + Velocity = 373; and Customer + Transaction Type + Velocity = 354.
-- All four signals exceeded their respective P95 markers for 152 transactions, representing approximately 0.02%
-- of the full transaction population.
-- The Global + Customer high-deviation population was entirely contained within the Global + Customer + Transaction
-- Type high-deviation population. Within this particular intersection, Transaction-Type Amount did not further
-- narrow the population identified by Global + Customer.
-- The overlap results demonstrate that the four signals identify intersecting but non-identical high-deviation
-- populations. Global Amount provides an overall transaction-value reference, Customer Amount provides a
-- customer-relative reference for non-merchant activity, Transaction-Type Amount provides a transaction-type-
-- relative reference, and Velocity contributes a temporal dimension.
-- The small four-signal intersection identifies transactions that simultaneously exceed all four exploratory
-- P95 markers. It does not establish that these transactions are fraudulent, suspicious, or inherently higher risk.
-- The P95 analysis was exploratory and was not adopted as a universal anomaly threshold.
-- The analysis did not justify weighting, normalising, or mathematically combining the four signal scores into a
-- single risk score.
-- The signals were retained as independent analytical constructs so that each could be interpreted according to
-- its own population, baseline, scoring direction, and analytical purpose.
-- Signal combinations remain contextual. Different analytical workloads may use different combinations depending
-- on whether the investigation concerns overall transaction-value deviation, customer-relative behaviour,
-- transaction-type-relative behaviour, rapid transaction activity, or a combination of these dimensions.
-- Global Amount remains a population-level reference signal rather than a weighting or balancing mechanism.
-- The analysis identifies statistical deviations and transaction-timing patterns; it does not independently
-- establish customer intent, explain the underlying cause of a deviation, or prove financial misconduct.
-- The final Transaction Anomaly Engine therefore provides four independent dimensions of transaction intelligence:
-- overall amount deviation, customer-relative amount deviation, transaction-type-relative amount deviation, and
-- transaction velocity.
-- The Transaction Anomaly Engine was evaluated at transaction grain using the four independent signals and their
-- exploratory high-deviation population intersections.
*/
-- Multi-dimensional signal combination
SELECT
    g.transaction_id,
    c.ocb_customer_id,
    g.transaction_amount,
    t.transaction_type,
    v.txn_interval_mins,
    v.txn_interval_mins_median,
    g.global_amount_score,
    c.customer_amount_score,
    t.transaction_type_amount_score,
    v.velocity_score
FROM intelligence.vw_signal_global_score AS g
LEFT JOIN intelligence.vw_signal_customer_score AS c ON
        g.transaction_id = c.transaction_id
LEFT JOIN intelligence.vw_signal_velocity_score v ON
        g.transaction_id = v.transaction_id
LEFT JOIN intelligence.vw_signal_transaction_type_score AS t ON
        g.transaction_id = t.transaction_id;
GO


