USE [ocb_platform];
GO

CREATE SCHEMA intelligence;
GO

-- Signal 1: global anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_global_score
AS
WITH global_median_agg
AS (
    SELECT
        ocb_customer_id,
        transaction_id,
        transaction_amount,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount ASC
            ) OVER () AS global_median
    FROM gold.vw_transaction
    ),
absolute_deviation
AS (
    SELECT
        *,
        ABS(transaction_amount - global_median) AS deviation_from_median
    FROM global_median_agg
    ),
mad_computation
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY deviation_from_median ASC
            ) OVER () AS global_mad
    FROM absolute_deviation
    ),
mad_deviation_score_computation
AS (
    SELECT
        *,
        ABS(transaction_amount - global_median) / global_mad AS global_mad_deviation_score
    FROM mad_computation
    )
/*
,mad_deviation_score_percentiles AS
(
    SELECT TOP 1
        MIN(mad_deviation_score) OVER() AS min_mds,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p50,
        AVG(mad_deviation_score) OVER() AS avg_mds,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p75,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p90,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p95,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY mad_deviation_score ASC) OVER() AS p99,
        MAX(mad_deviation_score) OVER() AS max_mds
    FROM mad_deviation_score_computation
)
*/
SELECT
    *
FROM mad_deviation_score_computation;
GO

-- Signal 2: customer anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_customer_score
AS
WITH customer_txn_median_agg
AS (
    SELECT
        ocb_customer_id,
        transaction_id,
        transaction_amount,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount ASC
            ) OVER (PARTITION BY ocb_customer_id) AS customer_median
    FROM gold.vw_transaction
    ),
absolute_deviation
AS (
    SELECT
        *,
        ABS(transaction_amount - customer_median) AS deviation_from_median
    FROM customer_txn_median_agg
    ),
mad_computation
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY deviation_from_median ASC
            ) OVER (PARTITION BY ocb_customer_id) AS customer_mad
    FROM absolute_deviation
    ),
mad_deviation_score_computation
AS (
    SELECT
        *,
        ABS(transaction_amount - customer_median) / NULLIF(customer_mad, 0) AS customer_mad_deviation_score
    FROM mad_computation
    )
SELECT
    *
FROM mad_deviation_score_computation;
GO

-- Signal 3: transaction-type anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_transaction_type_score
AS
WITH transaction_type_median
AS (
    SELECT
        ocb_customer_id,
        transaction_id,
        transaction_type,
        transaction_amount,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY transaction_amount ASC
            ) OVER (PARTITION BY transaction_type) AS txn_type_median
    FROM gold.vw_transaction
    ),
absolute_deviation
AS (
    SELECT
        *,
        ABS(transaction_amount - txn_type_median) AS deviation_from_median
    FROM transaction_type_median
    ),
mad_computation
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY deviation_from_median ASC
            ) OVER (PARTITION BY transaction_type) AS txn_type_mad
    FROM absolute_deviation
    ),
mad_deviation_score_computation
AS (
    SELECT
        *,
        deviation_from_median / NULLIF(txn_type_mad, 0) AS txn_type_mad_deviation_score
    FROM mad_computation
    )
SELECT
    *
FROM mad_deviation_score_computation;
GO

-- Signal 4: temporal anomaly score
CREATE
        OR

ALTER VIEW intelligence.vw_signal_velocity_score
AS
WITH previous_transaction_timestamp
AS (
    SELECT
        ocb_customer_id,
        transaction_id,
        LAG(transaction_timestamp, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp ASC
            ) AS previous_txn_timestamp,
        transaction_timestamp
    FROM gold.vw_transaction
    ),
transaction_interval
AS (
    SELECT
        *,
        DATEDIFF_BIG(SECOND, previous_txn_timestamp, transaction_timestamp) / 60.0 AS txn_interval_mins
    FROM previous_transaction_timestamp
    ),
transaction_interval_median
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY txn_interval_mins ASC
            ) OVER () AS txn_interval_mins_median
    FROM transaction_interval
    ),
absolute_deviation
AS (
    SELECT
        *,
        ABS(txn_interval_mins - txn_interval_mins_median) AS deviation_from_median
    FROM transaction_interval_median
    ),
mad_computation
AS (
    SELECT
        *,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY deviation_from_median ASC
            ) OVER () AS txn_velocity_mad
    FROM absolute_deviation
    ),
mad_deviation_score_computation
AS (
    SELECT
        *,
        CASE 
            WHEN txn_interval_mins < txn_interval_mins_median
                THEN (txn_interval_mins_median - txn_interval_mins) / NULLIF(txn_velocity_mad, 0)
            ELSE deviation_from_median / NULLIF(txn_velocity_mad, 0)
            END AS txn_velocity_anomaly_score
    FROM mad_computation
    )
SELECT
    *
FROM mad_deviation_score_computation
WHERE txn_interval_mins < txn_interval_mins_median;
GO

-- Signal combination
WITH combined_signals
AS (
    SELECT
        g.transaction_id,
        g.global_mad_deviation_score,
        c.customer_mad_deviation_score,
        t.txn_type_mad_deviation_score,
        v.txn_velocity_anomaly_score
    FROM intelligence.vw_signal_global_score g
    JOIN intelligence.vw_signal_customer_score c ON
            g.transaction_id = c.transaction_id
    JOIN intelligence.vw_signal_transaction_type_score t ON
            g.transaction_id = t.transaction_id
    JOIN intelligence.vw_signal_velocity_score v ON
            g.transaction_id = v.transaction_id
    ),
p95_percentile_overlap
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY global_mad_deviation_score
            ) OVER () AS global_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY customer_mad_deviation_score
            ) OVER () AS customer_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY txn_type_mad_deviation_score
            ) OVER () AS type_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY txn_velocity_anomaly_score
            ) OVER () AS velocity_p95
    FROM combined_signals
    )
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE 
            WHEN global_mad_deviation_score >= global_p95
                THEN 1
            ELSE 0
            END) AS global_high,
    SUM(CASE 
            WHEN customer_mad_deviation_score >= customer_p95
                THEN 1
            ELSE 0
            END) AS customer_high,
    SUM(CASE 
            WHEN txn_type_mad_deviation_score >= type_p95
                THEN 1
            ELSE 0
            END) AS type_high,
    SUM(CASE 
            WHEN txn_velocity_anomaly_score >= velocity_p95
                THEN 1
            ELSE 0
            END) AS velocity_high,
    SUM(CASE 
            WHEN global_mad_deviation_score >= global_p95
                    AND customer_mad_deviation_score >= customer_p95
                THEN 1
            ELSE 0
            END) AS global_customer_overlap,
    SUM(CASE 
            WHEN global_mad_deviation_score >= global_p95
                    AND customer_mad_deviation_score >= customer_p95
                    AND txn_type_mad_deviation_score >= type_p95
                THEN 1
            ELSE 0
            END) AS three_signal_overlap,
    SUM(CASE 
            WHEN global_mad_deviation_score >= global_p95
                    AND customer_mad_deviation_score >= customer_p95
                    AND txn_type_mad_deviation_score >= type_p95
                    AND txn_velocity_anomaly_score >= velocity_p95
                THEN 1
            ELSE 0
            END) AS four_signal_overlap
FROM combined_signals
CROSS JOIN p95_percentile_overlap;

-- Specific signal combination analysis
WITH combined_signals
AS (
    SELECT
        g.transaction_id,
        g.global_mad_deviation_score,
        c.customer_mad_deviation_score,
        t.txn_type_mad_deviation_score,
        v.txn_velocity_anomaly_score
    FROM intelligence.vw_signal_global_score g
    JOIN intelligence.vw_signal_customer_score c ON
            g.transaction_id = c.transaction_id
    JOIN intelligence.vw_signal_transaction_type_score t ON
            g.transaction_id = t.transaction_id
    JOIN intelligence.vw_signal_velocity_score v ON
            g.transaction_id = v.transaction_id
    ),
p95_thresholds
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY global_mad_deviation_score
            ) OVER () AS global_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY customer_mad_deviation_score
            ) OVER () AS customer_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY txn_type_mad_deviation_score
            ) OVER () AS type_p95,
        PERCENTILE_CONT(0.95) WITHIN
    GROUP (
            ORDER BY txn_velocity_anomaly_score
            ) OVER () AS velocity_p95
    FROM combined_signals
    )
SELECT
    COUNT(*) AS total_transactions,
    -- 2-signal combinations
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.customer_mad_deviation_score >= p.customer_p95
                THEN 1
            ELSE 0
            END) AS global_customer,
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                THEN 1
            ELSE 0
            END) AS global_type,
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS global_velocity,
    SUM(CASE 
            WHEN g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                THEN 1
            ELSE 0
            END) AS customer_type,
    SUM(CASE 
            WHEN g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS customer_velocity,
    SUM(CASE 
            WHEN g.txn_type_mad_deviation_score >= p.type_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS type_velocity,
    -- 3-signal combinations
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                THEN 1
            ELSE 0
            END) AS global_customer_type,
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS global_customer_velocity,
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS global_type_velocity,
    SUM(CASE 
            WHEN g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS customer_type_velocity,
    -- 4-signal combination
    SUM(CASE 
            WHEN g.global_mad_deviation_score >= p.global_p95
                    AND g.customer_mad_deviation_score >= p.customer_p95
                    AND g.txn_type_mad_deviation_score >= p.type_p95
                    AND g.txn_velocity_anomaly_score >= p.velocity_p95
                THEN 1
            ELSE 0
            END) AS all_four
FROM combined_signals g
CROSS JOIN p95_thresholds p;

/*
-- P5.3 Transaction Anomaly Engine — Signal Combination Analysis
-- The four anomaly signals were initially evaluated together using the 95th percentile of each signal as an exploratory
    high-deviation marker.
-- The combined INNER JOIN produced 384,689 transactions from the original 772,381 transaction population because the velocity view
    contains only transactions with intervals below the global interval median; this population reduction is caused by the join
    scope, not by the P95 calculation.
-- Within the 384,689 transaction population, approximately 5% of transactions were above the P95 for each individual signal:
    global = 19,235, customer = 19,235, transaction type = 19,235, velocity = 19,238.
-- Global + Customer overlap was 17,224 transactions, showing substantial overlap between population-level and customer-relative
    value deviation.
-- Global + Transaction Type overlap was 5,179 transactions.
-- Customer + Transaction Type overlap was 4,658 transactions.
-- Global + Velocity overlap was 1,014 transactions.
-- Customer + Velocity overlap was 1,005 transactions.
-- Transaction Type + Velocity overlap was 996 transactions.
-- The three-signal overlaps were: Global + Customer + Type = 4,129; Global + Customer + Velocity = 916;
    Global + Type + Velocity = 276; Customer + Type + Velocity = 247.
-- All four signals exceeded their respective P95 markers for 222 transactions.
-- The overlap results indicate that Global + Customer captures substantial common information, while Velocity overlaps much less
    with the value-based signals and therefore contributes a distinct temporal dimension.
-- The P95 analysis was exploratory and was not adopted as a universal anomaly threshold.
-- The analysis did not establish that a transaction above P95 is fraudulent, suspicious, or inherently higher risk.
-- The analysis did not justify weighting, normalising, or mathematically combining the four signal scores into a single risk score.
-- The results instead support workload-specific signal constructs: Global + Type for transaction-type analysis;
    Global + Rapid Velocity for rapid-activity analysis; and Global + Customer + Type + Rapid Velocity for deeper
    multi-dimensional investigation.
-- Global therefore remains a population-level reference signal rather than a weighting or balancing mechanism.
-- Signal combination is contextual: not every analytical workload requires every signal.
-- Final Transaction Anomaly Engine constructs were subsequently validated at transaction grain using these workload-specific
    combinations.
*/
-- Transaction Anomaly Engine.
-- Global + Customer Anomaly
SELECT
    g.transaction_id,
    c.ocb_customer_id,
    g.transaction_amount,
    g.global_mad_deviation_score,
    c.customer_mad_deviation_score,
    MIN(g.global_mad_deviation_score) OVER () min_global_score,
    MAX(g.global_mad_deviation_score) OVER () max_global_score,
    MIN(c.customer_mad_deviation_score) OVER () min_customer_score,
    MAX(c.customer_mad_deviation_score) OVER () max_customer_score
FROM intelligence.vw_signal_global_score AS g
JOIN intelligence.vw_signal_customer_score AS c ON
        g.transaction_id = c.transaction_id
ORDER BY transaction_id;

-- Global + Transaction Type Anomaly
SELECT
    g.transaction_id,
    t.transaction_type,
    g.transaction_amount,
    g.global_mad_deviation_score,
    t.txn_type_mad_deviation_score,
    MIN(g.global_mad_deviation_score) OVER () min_global_score,
    MAX(g.global_mad_deviation_score) OVER () max_global_score,
    MIN(t.txn_type_mad_deviation_score) OVER () min_txntype_score,
    MAX(t.txn_type_mad_deviation_score) OVER () max_txntype_score
FROM intelligence.vw_signal_global_score AS g
JOIN intelligence.vw_signal_transaction_type_score AS t ON
        g.transaction_id = t.transaction_id
ORDER BY transaction_id;

-- Global + Velocity
SELECT
    g.transaction_id,
    v.txn_interval_mins,
    v.txn_interval_mins_median,
    g.transaction_amount,
    g.global_mad_deviation_score,
    v.txn_velocity_anomaly_score,
    MIN(g.global_mad_deviation_score) OVER () min_global_score,
    MAX(g.global_mad_deviation_score) OVER () max_global_score,
    MIN(v.txn_velocity_anomaly_score) OVER () min_velocity_score,
    MAX(v.txn_velocity_anomaly_score) OVER () max_velocity_score
FROM intelligence.vw_signal_global_score AS g
JOIN intelligence.vw_signal_velocity_score v ON
        g.transaction_id = v.transaction_id;

-- Multi-dimensional
SELECT
    g.transaction_id,
    c.ocb_customer_id,
    g.transaction_amount,
    t.transaction_type,
    v.txn_interval_mins,
    v.txn_interval_mins_median,
    g.global_mad_deviation_score,
    c.customer_mad_deviation_score,
    t.txn_type_mad_deviation_score,
    v.txn_velocity_anomaly_score
FROM intelligence.vw_signal_global_score AS g
JOIN intelligence.vw_signal_customer_score AS c ON
        g.transaction_id = c.transaction_id
JOIN intelligence.vw_signal_velocity_score v ON
        g.transaction_id = v.transaction_id
JOIN intelligence.vw_signal_transaction_type_score AS t ON
        g.transaction_id = t.transaction_id;
