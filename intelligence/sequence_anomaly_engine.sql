USE [ocb_platform];
GO

-- 1. Cash In_P2P_Cash Out (CIP2PCO sequence duration) Score
CREATE
        OR

ALTER VIEW intelligence.vw_cip2pco_sequence_duration_score
AS
WITH filtered_txns
AS (
    SELECT
        vt.ocb_customer_id,
        vt.transaction_id,
        vt.transaction_timestamp,
        vt.transaction_type,
        vt.transaction_amount
    FROM gold.vw_transaction vt
    WHERE vt.transaction_type IN (
            'cash in',
            'p2p transfer',
            'cash out'
            )
    ),
ordered_txns
AS (
    SELECT
        ocb_customer_id,
        transaction_timestamp AS txn1_time,
        transaction_type      AS txn1_type,
        LEAD(transaction_timestamp, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_time,
        LEAD(transaction_type, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_type,
        LEAD(transaction_timestamp, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_time,
        LEAD(transaction_type, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_type
    FROM filtered_txns
    ),
sequence_duration
AS (
    SELECT
        *,
        CAST(DATEDIFF_BIG(MILLISECOND, txn1_time, txn3_time) / 60000.0 AS DECIMAL(18, 4)) AS sequence_duration_mins
    FROM ordered_txns
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    ),
median_calc
AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY sequence_duration_mins
            ) OVER () AS median_duration_mins
    FROM sequence_duration
    ),
median_value
AS (
    SELECT
        MAX(median_duration_mins) AS median_duration_mins
    FROM median_calc
    ),
absolute_deviations
AS (
    SELECT
        sd.ocb_customer_id,
        sd.txn1_time,
        sd.txn2_time,
        sd.txn3_time,
        sd.sequence_duration_mins,
        mv.median_duration_mins,
        ABS(sd.sequence_duration_mins - mv.median_duration_mins) AS absolute_deviation
    FROM sequence_duration sd
    CROSS JOIN median_value mv
    ),
mad_calc
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_duration_mins
    FROM absolute_deviations
    )
SELECT
    ad.*,
    c.mad_duration_mins,
    CASE 
        WHEN ad.sequence_duration_mins < ad.median_duration_mins
                AND c.mad_duration_mins > 0
            THEN (ad.median_duration_mins - ad.sequence_duration_mins) / c.mad_duration_mins
        ELSE 0
        END AS cip2pco_sequence_duration_score
FROM absolute_deviations ad
CROSS JOIN mad_calc c;
GO

-- 2. CIP2PCO Sequence Recurrence Duration Score
CREATE
        OR

ALTER VIEW intelligence.vw_cip2pco_recurrence_score
AS
WITH filtered_txns
AS (
    SELECT
        vt.ocb_customer_id,
        vt.transaction_id,
        vt.transaction_timestamp,
        vt.transaction_type
    FROM gold.vw_transaction AS vt
    WHERE vt.transaction_type IN (
            'cash in',
            'p2p transfer',
            'cash out'
            )
    ),
sequence_events
AS (
    SELECT
        ocb_customer_id,
        transaction_id        AS txn1_transaction_id,
        transaction_timestamp AS txn1_timestamp,
        transaction_type      AS txn1_type,
        LEAD(transaction_id, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_transaction_id,
        LEAD(transaction_timestamp, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_timestamp,
        LEAD(transaction_type, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_type,
        LEAD(transaction_id, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_transaction_id,
        LEAD(transaction_timestamp, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_timestamp,
        LEAD(transaction_type, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_type
    FROM filtered_txns
    ),
qualified_sequences
AS (
    SELECT
        ocb_customer_id,
        txn1_transaction_id,
        txn1_timestamp,
        txn2_transaction_id,
        txn2_timestamp,
        txn3_transaction_id,
        txn3_timestamp
    FROM sequence_events
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    ),
sequence_recurrence
AS (
    SELECT
        ocb_customer_id,
        txn1_transaction_id,
        txn1_timestamp,
        txn2_transaction_id,
        txn2_timestamp,
        txn3_transaction_id,
        txn3_timestamp,
        LEAD(txn1_transaction_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn1_transaction_id,
        LEAD(txn1_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn1_timestamp,
        LEAD(txn2_transaction_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn2_transaction_id,
        LEAD(txn2_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn2_timestamp,
        LEAD(txn3_transaction_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn3_transaction_id,
        LEAD(txn3_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY txn1_timestamp,
                txn1_transaction_id
            ) AS next_sequence_txn3_timestamp
    FROM qualified_sequences
    ),
recurrence_population
AS (
    SELECT
        ocb_customer_id,
        txn1_transaction_id,
        txn1_timestamp,
        txn2_transaction_id,
        txn2_timestamp,
        txn3_transaction_id,
        txn3_timestamp,
        next_sequence_txn1_transaction_id,
        next_sequence_txn1_timestamp,
        next_sequence_txn2_transaction_id,
        next_sequence_txn2_timestamp,
        next_sequence_txn3_transaction_id,
        next_sequence_txn3_timestamp,
        DATEDIFF_BIG(SECOND, txn3_timestamp, next_sequence_txn1_timestamp) / 60.00 AS recurrence_gap_minutes
    FROM sequence_recurrence
    WHERE next_sequence_txn1_timestamp IS NOT NULL
    ),
median_calc
AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_gap_minutes
            ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
    ),
median_value
AS (
    SELECT
        MAX(median_recurrence_gap_minutes) AS median_recurrence_gap_minutes
    FROM median_calc
    ),
absolute_deviations
AS (
    SELECT
        rp.*,
        mv.median_recurrence_gap_minutes,
        ABS(rp.recurrence_gap_minutes - mv.median_recurrence_gap_minutes) AS absolute_deviation
    FROM recurrence_population AS rp
    CROSS JOIN median_value AS mv
    ),
mad_calc
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_recurrence_gap_minutes
    FROM absolute_deviations
    )
SELECT
    ad.ocb_customer_id,
    ad.txn1_transaction_id,
    ad.txn1_timestamp,
    ad.txn2_transaction_id,
    ad.txn2_timestamp,
    ad.txn3_transaction_id,
    ad.txn3_timestamp,
    ad.next_sequence_txn1_transaction_id,
    ad.next_sequence_txn1_timestamp,
    ad.next_sequence_txn2_transaction_id,
    ad.next_sequence_txn2_timestamp,
    ad.next_sequence_txn3_transaction_id,
    ad.next_sequence_txn3_timestamp,
    ad.recurrence_gap_minutes,
    ad.median_recurrence_gap_minutes,
    mc.mad_recurrence_gap_minutes,
    CASE 
        WHEN ad.recurrence_gap_minutes < ad.median_recurrence_gap_minutes
                AND mc.mad_recurrence_gap_minutes > 0
            THEN (ad.median_recurrence_gap_minutes - ad.recurrence_gap_minutes) / mc.mad_recurrence_gap_minutes
        ELSE 0
        END AS cip2pco_recurrence_score
FROM absolute_deviations AS ad
CROSS JOIN mad_calc AS mc;
GO

-- 3. CIP2PCO Sequence Outflow Conversion Ratio (SOCR)
CREATE
        OR

ALTER VIEW intelligence.vw_cip2pco_socr_score
AS
WITH filtered_txns
AS (
    SELECT
        vt.ocb_customer_id,
        vt.transaction_id,
        vt.transaction_timestamp,
        vt.transaction_type,
        vt.transaction_amount
    FROM gold.vw_transaction AS vt
    WHERE vt.transaction_type IN (
            'cash in',
            'p2p transfer',
            'cash out'
            )
    ),
sequence_events
AS (
    SELECT
        ocb_customer_id,
        transaction_timestamp AS txn1_timestamp,
        transaction_type      AS txn1_type,
        transaction_amount    AS txn1_amount,
        LEAD(transaction_timestamp, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_timestamp,
        LEAD(transaction_type, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_type,
        LEAD(transaction_amount, 1) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn2_amount,
        LEAD(transaction_timestamp, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_timestamp,
        LEAD(transaction_type, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_type,
        LEAD(transaction_amount, 2) OVER (
            PARTITION BY ocb_customer_id ORDER BY transaction_timestamp,
                transaction_id
            ) AS txn3_amount
    FROM filtered_txns
    ),
qualified_sequences
AS (
    SELECT
        ocb_customer_id,
        txn1_timestamp,
        txn2_timestamp,
        txn3_timestamp,
        txn1_amount AS cash_in_value,
        txn2_amount AS p2p_value,
        txn3_amount AS cash_out_value
    FROM sequence_events
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    ),
log_socr
AS (
    SELECT
        ocb_customer_id,
        txn1_timestamp,
        txn2_timestamp,
        txn3_timestamp,
        cash_in_value,
        p2p_value,
        cash_out_value,
        (p2p_value + cash_out_value) / NULLIF(cash_in_value, 0) AS socr,
        LOG((p2p_value + cash_out_value) / NULLIF(cash_in_value, 0)) AS log_socr
    FROM qualified_sequences
    ),
median_layer
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_socr
            ) OVER () AS median_log_socr
    FROM log_socr
    ),
deviations
AS (
    SELECT
        l.log_socr,
        m.median_log_socr,
        ABS(l.log_socr - m.median_log_socr) AS absolute_deviation
    FROM log_socr l
    CROSS JOIN median_layer m
    ),
mad_layer
AS (
    SELECT DISTINCT
        median_log_socr,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_log_socr
    FROM deviations
    )
SELECT
    l.ocb_customer_id,
    l.txn1_timestamp,
    l.txn2_timestamp,
    l.txn3_timestamp,
    l.cash_in_value,
    l.p2p_value,
    l.cash_out_value,
    l.socr,
    l.log_socr,
    m.median_log_socr,
    m.mad_log_socr,
    CASE 
        WHEN l.log_socr > m.median_log_socr
            THEN (l.log_socr - m.median_log_socr) / NULLIF(m.mad_log_socr, 0)
        ELSE 0
        END AS cip2pco_socr_score
FROM log_socr l
CROSS JOIN mad_layer m;
GO

/*
-- WP5.3 Sequence Anomaly Engine — CIP2PCO Process Documentation
-- CIP2PCO was defined as Cash In → P2P Transfer → Cash Out.
-- The engine identified three consecutive qualifying transactions per customer.
-- Three independent signals were evaluated: Sequence Duration, Sequence Recurrence, and Sequence Outflow Conversion Ratio (SOCR).
-- Sequence Duration measured the time from the initiating Cash In to the subsequent Cash Out.
-- Duration scores used the population median and Median Absolute Deviation (MAD).
-- Sequences shorter than the median received positive scores.
-- Sequences at or above the median received zero.
-- Score-band validation showed that higher scores corresponded to shorter sequences.
-- Sequence Recurrence measured the time between one sequence's Cash Out and the next qualifying sequence's Cash In.
-- Recurrence was calculated only after the complete qualifying sequence population had been established.
-- The next sequence was identified at sequence grain, not from individual transactions.
-- Recurrence scores used the population median and MAD.
-- Gaps shorter than the median received positive scores.
-- Gaps at or above the median received zero.
-- Higher recurrence scores corresponded to shorter inter-sequence gaps.
-- SOCR was defined as (P2P Transfer Value + Cash Out Value) / Cash In Value.
-- The raw SOCR was initially capped at 1.0.
-- This approach was rejected because 85.48% of qualifying sequences reached the artificial ceiling.
-- The cap concealed meaningful variation among ratios exceeding 1.0.
-- The raw SOCR was therefore transformed using SQL Server LOG().
-- The logarithm preserved the ordering of ratios without imposing an artificial ceiling.
-- Log-SOCR scores used the population median and MAD.
-- Values above the median received positive scores.
-- Values at or below the median received zero.
-- Across 22,704 qualifying sequences, SOCR scores ranged from 0 to 4.82596.
-- Score-band validation showed progressively higher SOCR and log-SOCR values.
-- No material overlap was observed between adjacent score bands.
-- The scoring mechanism preserved variation across the observed conversion ratios.
-- Raw SOCR can exceed 1.0 because transaction order does not prove fund provenance.
-- The P2P Transfer and Cash Out may not have been funded exclusively by the initiating Cash In.
-- SOCR therefore measures observed outflow value relative to the initiating Cash In.
-- It does not directly measure the proportion of that Cash In converted.
-- It does not establish that funds were laundered.
-- No rolling-balance reconstruction or fund-provenance attribution was introduced.
-- No account-balance exhaustion logic was introduced.
-- CIP2PCO is a sequence-pattern engine, not a ledger or balance-reconstruction engine.
-- All three signals were evaluated independently at sequence grain.
-- Their scores were not combined into a single CIP2PCO risk score.
-- No universal anomaly-score thresholds were established.
-- Score bands were used to validate scoring behaviour and separation.
-- A qualifying sequence or high score does not establish fraud or suspicious activity.
-- A high SOCR does not establish inherently higher risk.
-- The final engine measures three dimensions of sequence behaviour.
-- Duration measures how quickly a qualifying sequence completes.
-- Recurrence measures how quickly the next qualifying sequence begins.
-- SOCR measures observed P2P Transfer and Cash Out value relative to the initiating Cash In.
-- CIP2PCO was validated at sequence grain using these three independent anomaly signals.
*/
-- Combined Duration + Recurrence + SOCR
SELECT
    d.ocb_customer_id,
    txn1_transaction_id,
    d.txn1_time AS txn1_timestamp,
    d.txn2_time AS txn2_timestamp,
    d.txn3_time AS txn3_timestamp,
    d.sequence_duration_mins,
    d.cip2pco_sequence_duration_score,
    r.next_sequence_txn1_transaction_id,
    r.next_sequence_txn1_timestamp,
    r.next_sequence_txn2_transaction_id,
    r.next_sequence_txn2_timestamp,
    r.next_sequence_txn3_transaction_id,
    r.next_sequence_txn3_timestamp,
    r.recurrence_gap_minutes,
    r.cip2pco_recurrence_score,
    s.cash_in_value,
    s.p2p_value,
    s.cash_out_value,
    s.socr,
    s.log_socr,
    s.cip2pco_socr_score
FROM intelligence.vw_cip2pco_sequence_duration_score AS d
LEFT JOIN intelligence.vw_cip2pco_recurrence_score AS r ON
        r.ocb_customer_id = d.ocb_customer_id
            AND r.txn1_timestamp = d.txn1_time
            AND r.txn2_timestamp = d.txn2_time
            AND r.txn3_timestamp = d.txn3_time
LEFT JOIN intelligence.vw_cip2pco_socr_score AS s ON
        s.ocb_customer_id = d.ocb_customer_id
            AND s.txn1_timestamp = d.txn1_time
            AND s.txn2_timestamp = d.txn2_time
            AND s.txn3_timestamp = d.txn3_time
ORDER BY d.ocb_customer_id,
    d.txn1_time,
    txn1_transaction_id;
GO

-- Loan → withdrawal
-- 1. loan_cashout_rapidity_score
CREATE
        OR

ALTER VIEW intelligence.vw_loan_cashout_rapidity_score
AS
WITH loan_cash_out
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        t.transaction_id,
        t.transaction_timestamp                                                                                        AS cash_out_timestamp,
        t.transaction_amount                                                                                           AS cash_out_amt,
        CAST(DATEDIFF_BIG(MILLISECOND, l.disbursement_timestamp, t.transaction_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS cash_out_delay_minutes,
        ROW_NUMBER() OVER (
            PARTITION BY l.loan_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_transaction t ON
            l.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= l.disbursement_timestamp
                AND t.transaction_type = 'cash out'
    ),
sequence_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_delay_minutes
    FROM loan_cash_out
    WHERE rn = 1
    ),
deduplicated_sequences
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            transaction_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS transaction_rn
    FROM sequence_population
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_delay_minutes
    FROM deduplicated_sequences
    WHERE transaction_rn = 1
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cash_out_delay_minutes
            ) OVER () AS median_delay_minutes
    FROM clean_population
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(cp.cash_out_delay_minutes - m.median_delay_minutes)
            ) OVER () AS mad_delay_minutes
    FROM clean_population cp
    CROSS JOIN median_stage m
    )
SELECT
    cp.ocb_customer_id,
    cp.loan_id,
    cp.disbursement_timestamp,
    cp.principal_amount,
    cp.transaction_id,
    cp.cash_out_timestamp,
    cp.cash_out_amt,
    cp.cash_out_delay_minutes,
    m.median_delay_minutes,
    d.mad_delay_minutes,
    CASE 
        WHEN cp.cash_out_delay_minutes < m.median_delay_minutes
                AND d.mad_delay_minutes > 0
            THEN (m.median_delay_minutes - cp.cash_out_delay_minutes) / d.mad_delay_minutes
        ELSE 0
        END AS loan_cashout_rapidity_score
FROM clean_population cp
CROSS JOIN median_stage m
CROSS JOIN mad_stage d;
GO

-- 2. loan amount (loan to cashout)
CREATE
        OR

ALTER VIEW intelligence.vw_loan_cashout_amount_ratio_score
AS
WITH loan_cash_out
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        t.transaction_id,
        t.transaction_timestamp                              AS cash_out_timestamp,
        t.transaction_amount                                 AS cash_out_amt,
        t.transaction_amount / NULLIF(l.principal_amount, 0) AS cash_out_to_loan_ratio,
        ROW_NUMBER() OVER (
            PARTITION BY l.loan_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_transaction t ON
            l.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= l.disbursement_timestamp
                AND t.transaction_type = 'cash out'
    ),
sequence_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_to_loan_ratio,
        LOG(cash_out_to_loan_ratio) AS log_cash_out_to_loan_ratio
    FROM loan_cash_out
    WHERE rn = 1
            AND cash_out_to_loan_ratio > 0
    ),
deduplicated_sequences
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            transaction_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS transaction_rn
    FROM sequence_population
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_to_loan_ratio,
        log_cash_out_to_loan_ratio
    FROM deduplicated_sequences
    WHERE transaction_rn = 1
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_cash_out_to_loan_ratio
            ) OVER () AS median_log_ratio
    FROM clean_population
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(cp.log_cash_out_to_loan_ratio - m.median_log_ratio)
            ) OVER () AS mad_log_ratio
    FROM clean_population cp
    CROSS JOIN median_stage m
    )
SELECT
    cp.ocb_customer_id,
    cp.loan_id,
    cp.disbursement_timestamp,
    cp.principal_amount,
    cp.transaction_id,
    cp.cash_out_timestamp,
    cp.cash_out_amt,
    cp.cash_out_to_loan_ratio,
    cp.log_cash_out_to_loan_ratio,
    m.median_log_ratio,
    d.mad_log_ratio,
    CASE 
        WHEN cp.log_cash_out_to_loan_ratio > m.median_log_ratio
                AND d.mad_log_ratio > 0
            THEN (cp.log_cash_out_to_loan_ratio - m.median_log_ratio) / d.mad_log_ratio
        ELSE 0
        END AS amount_ratio_score
FROM clean_population cp
CROSS JOIN median_stage m
CROSS JOIN mad_stage d;
GO

-- 3. Loan → Cash Out recurrence
CREATE
        OR

ALTER VIEW intelligence.vw_loan_cashout_recurrence_score
AS
WITH loan_cash_out
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        t.transaction_id,
        t.transaction_timestamp AS cash_out_timestamp,
        t.transaction_amount    AS cash_out_amount,
        ROW_NUMBER() OVER (
            PARTITION BY l.ocb_customer_id,
            l.loan_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS cash_out_rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_transaction t ON
            l.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= l.disbursement_timestamp
                AND t.transaction_type = 'Cash Out'
    ),
sequence_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amount
    FROM loan_cash_out
    WHERE cash_out_rn = 1
    ),
deduplicated_sequences
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            transaction_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS transaction_rn
    FROM sequence_population
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amount
    FROM deduplicated_sequences
    WHERE transaction_rn = 1
    ),
sequence_recurrence
AS (
    SELECT
        *,
        LEAD(disbursement_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY disbursement_timestamp,
                loan_id
            ) AS next_sequence_loan_timestamp,
    LEAD(loan_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY disbursement_timestamp,
                loan_id
            ) AS next_sequence_loan_id
    FROM clean_population
    ),
recurrence_interval
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amount,
        next_sequence_loan_id,
        next_sequence_loan_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, cash_out_timestamp, next_sequence_loan_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS recurrence_gap_minutes
    FROM sequence_recurrence
    ),
recurrence_population
AS (
    SELECT
        *
    FROM recurrence_interval
    WHERE next_sequence_loan_timestamp IS NOT NULL
    ),
median_calc
AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_gap_minutes
            ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
    ),
median_value
AS (
    SELECT
        MAX(median_recurrence_gap_minutes) AS median_recurrence_gap_minutes
    FROM median_calc
    ),
absolute_deviations
AS (
    SELECT
        rp.*,
        mv.median_recurrence_gap_minutes,
        ABS(rp.recurrence_gap_minutes - mv.median_recurrence_gap_minutes) AS absolute_deviation
    FROM recurrence_population rp
    CROSS JOIN median_value mv
    ),
mad_calc
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_recurrence_gap_minutes
    FROM absolute_deviations
    )
SELECT
    ad.*,
    mc.mad_recurrence_gap_minutes,
    CASE 
        WHEN ad.recurrence_gap_minutes < ad.median_recurrence_gap_minutes
                AND mc.mad_recurrence_gap_minutes > 0
            THEN (ad.median_recurrence_gap_minutes - ad.recurrence_gap_minutes) / mc.mad_recurrence_gap_minutes
        ELSE 0
        END AS loan_cashout_recurrence_score
FROM absolute_deviations ad
CROSS JOIN mad_calc mc;
GO

/*
-- WP 5.3 Loan → Cash Out Process Documentation
-- Loan → Cash Out was defined as the sequence of a loan disbursement followed by a subsequent Cash Out transaction
    for the same customer.
-- The sequence population was constructed by joining loans to subsequent Cash Out transactions within each
    customer and applying deterministic one-to-one attribution controls.
-- For each loan, the first subsequent Cash Out was retained.
-- For each Cash Out, the most recent preceding loan was retained.
-- This deduplication was applied before calculating sequence-level signals to prevent one loan or Cash Out from
    generating multiple analytical sequences.
-- The resulting clean population provides a consistent sequence grain across all three signals.
-- The engine was evaluated using three independent signals: Rapidity, Amount Ratio, and Recurrence.
-- Loan → Cash Out is not inherently anomalous because withdrawing loan proceeds is an expected customer behaviour.
-- The analytical phenomenon of interest is the timing, relative value, and repetition of qualifying Loan → Cash Out
    sequences, particularly where the Cash Out occurs unusually quickly, is unusually large relative to the loan
    principal, or the pattern repeatedly occurs at unusually short intervals.
-- Rapidity measures the elapsed time between the loan disbursement timestamp and the subsequent Cash Out timestamp.
-- Rapidity was measured in minutes using the elapsed time between the two timestamps.
-- Rapidity was scored using the population median and MAD, with shorter-than-median Loan → Cash Out delays
    receiving positive scores and delays at or above the median receiving zero.
-- The rapidity score therefore increases as the observed Loan → Cash Out sequence becomes progressively faster
    relative to the population.
-- Amount Ratio was defined as Cash Out Value / Loan Principal Amount.
-- The raw amount ratio was transformed using the natural logarithm through SQL Server LOG() to represent
    proportional differences on a logarithmic scale.
-- Amount Ratio was scored using the population median and MAD of the log-ratios, with values above the population
    median receiving positive scores and values at or below the median receiving zero.
-- A ratio above 1.0 indicates that the observed Cash Out amount exceeds the associated loan principal.
-- The amount ratio establishes a temporal and customer association between the loan and Cash Out, but does not
    establish that the loan proceeds funded the Cash Out.
-- Accordingly, the amount ratio is interpreted as observed Cash Out value relative to observed loan principal,
    rather than as direct evidence of how the loan proceeds were used.
-- Recurrence measures the time interval between successive qualifying Loan → Cash Out sequences exhibited by the
    same customer.
-- Recurrence was identified using LEAD() over the chronologically ordered, deduplicated qualifying sequences for
    each customer, ordered by loan disbursement timestamp and loan_id.
-- The recurrence interval was measured from the current sequence's Cash Out timestamp to the next qualifying
    sequence's loan disbursement timestamp for the same customer.
-- The recurrence interval therefore measures the time between the Cash Out of one qualifying sequence and the
    loan disbursement of the next qualifying sequence.
-- Overlapping qualifying sequences remain eligible for recurrence analysis. The next loan may be disbursed before
    the current sequence's Cash Out occurs; this does not invalidate either qualifying sequence or the recurrent
    behaviour.
-- When the next loan is disbursed before the current sequence's Cash Out, the recurrence interval is negative,
    reflecting temporal overlap between successive qualifying sequences rather than an absence of recurrence.
-- The final qualifying sequence for a customer has no subsequent sequence and is therefore excluded from recurrence
    interval scoring.
-- Recurrence was scored using the population median and MAD, with intervals below the median receiving positive
    scores and intervals at or above the median receiving zero, provided the MAD is greater than zero.
-- The recurrence score therefore measures the temporal spacing between successive qualifying Loan → Cash Out
    sequences rather than simply counting how many sequences occurred.
-- The three behavioural signals were evaluated independently as sequence-level anomaly constructs.
-- The three signals were not mathematically combined into a single Loan → Cash Out risk score.
-- No universal score thresholds were established. Score distributions and bands were used to validate the behaviour
    and integrity of the individual scoring mechanisms.
-- The analysis does not establish that a qualifying sequence, a high rapidity score, a high amount ratio, or repeated
    sequences are fraudulent, suspicious, or inherently higher risk.
-- The final Loan → Cash Out engine therefore provides three independent dimensions of intelligence: how rapidly
    the Cash Out follows the loan disbursement, how large the observed Cash Out is relative to the loan principal,
    and how the customer repeats the qualifying sequence over time.
-- The Loan → Cash Out engine was evaluated using these three independent behavioural anomaly signals.
*/
-- Combining all Loan → Cash Out signals
WITH rapidity
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp,
        principal_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_delay_minutes,
        loan_cashout_rapidity_score
    FROM intelligence.vw_loan_cashout_rapidity_score
    ),
amount_ratio
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        transaction_id,
        cash_out_to_loan_ratio,
        log_cash_out_to_loan_ratio,
        amount_ratio_score
    FROM intelligence.vw_loan_cashout_amount_ratio_score
    ),
recurrence
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        transaction_id,
        recurrence_gap_minutes,
        loan_cashout_recurrence_score
    FROM intelligence.vw_loan_cashout_recurrence_score
    )
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.disbursement_timestamp,
    r.principal_amount,
    r.transaction_id,
    r.cash_out_timestamp,
    r.cash_out_amt,
    r.cash_out_delay_minutes,
    r.loan_cashout_rapidity_score,
    a.cash_out_to_loan_ratio,
    a.log_cash_out_to_loan_ratio,
    a.amount_ratio_score,
    rc.recurrence_gap_minutes,
    rc.loan_cashout_recurrence_score
FROM rapidity r
LEFT JOIN amount_ratio a ON
        r.ocb_customer_id = a.ocb_customer_id
            AND r.loan_id = a.loan_id
            AND r.transaction_id = a.transaction_id
LEFT JOIN recurrence rc ON
        r.ocb_customer_id = rc.ocb_customer_id
            AND r.loan_id = rc.loan_id
            AND r.transaction_id = rc.transaction_id
ORDER BY r.ocb_customer_id,
    r.disbursement_timestamp,
    r.loan_id;
GO

--  Remittance Cash Out sequence
-- 1. Remittance Cash Out rapidity
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_cashout_rapidity_score
AS
WITH candidate_pairs
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        t.transaction_id,
        t.transaction_timestamp AS cash_out_timestamp,
        t.transaction_amount    AS cash_out_amt,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            r.remittance_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS cash_out_rn,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            t.transaction_id ORDER BY r.remittance_timestamp DESC,
                r.remittance_id DESC
            ) AS remittance_rn
    FROM gold.vw_remittance r
    INNER JOIN gold.vw_transaction t ON
            r.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= r.remittance_timestamp
                AND t.transaction_type = 'Cash Out'
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        CAST(DATEDIFF_BIG(MILLISECOND, remittance_timestamp, cash_out_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS cash_out_delay_minutes
    FROM candidate_pairs
    WHERE cash_out_rn = 1
            AND remittance_rn = 1
    ),
transformed
AS (
    SELECT
        *,
        LOG(cash_out_delay_minutes) AS log_delay
    FROM clean_population
    WHERE cash_out_delay_minutes > 0
    ),
median_value
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY log_delay
            ) OVER () AS median_log_delay
    FROM transformed
    ),
deviations
AS (
    SELECT
        t.*,
        m.median_log_delay,
        ABS(t.log_delay - m.median_log_delay) AS absolute_deviation
    FROM transformed t
    CROSS JOIN median_value m
    ),
mad_value
AS (
    SELECT TOP 1
        median_log_delay,
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_log_delay
    FROM deviations
    ),
scored
AS (
    SELECT
        d.ocb_customer_id,
        d.remittance_id,
        d.remittance_timestamp,
        d.remittance_amount,
        d.transaction_id,
        d.cash_out_timestamp,
        d.cash_out_amt,
        d.cash_out_delay_minutes,
        d.log_delay,
        m.median_log_delay,
        m.mad_log_delay,
        CASE 
            WHEN d.log_delay < m.median_log_delay
                THEN (m.median_log_delay - d.log_delay) / NULLIF(m.mad_log_delay, 0)
            ELSE 0
            END AS remittance_cashout_rapidity_score
    FROM deviations d
    CROSS JOIN mad_value m
    )
SELECT
    ocb_customer_id,
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    transaction_id,
    cash_out_timestamp,
    cash_out_amt,
    cash_out_delay_minutes,
    log_delay,
    median_log_delay,
    mad_log_delay,
    remittance_cashout_rapidity_score
FROM scored;
GO

-- 2. Remittance CashOut Recurrence
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_cashout_recurrence_score
AS
WITH candidate_pairs
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        t.transaction_id,
        t.transaction_timestamp AS cash_out_timestamp,
        t.transaction_amount    AS cash_out_amt,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            r.remittance_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS cash_out_rn,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            t.transaction_id ORDER BY r.remittance_timestamp DESC,
                r.remittance_id DESC
            ) AS remittance_rn
    FROM gold.vw_remittance r
    INNER JOIN gold.vw_transaction t ON
            r.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= r.remittance_timestamp
                AND t.transaction_type = 'Cash Out'
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt
    FROM candidate_pairs
    WHERE cash_out_rn = 1
            AND remittance_rn = 1
    ),
sequence_recurrence
AS (
    SELECT
        *,
        LEAD(remittance_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY remittance_timestamp,
                remittance_id
            ) AS next_sequence_remittance_timestamp
    FROM clean_population
    ),
recurrence_interval
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        next_sequence_remittance_timestamp,
        DATEDIFF_BIG(SECOND, cash_out_timestamp, next_sequence_remittance_timestamp) / 60.00 AS recurrence_gap_minutes
    FROM sequence_recurrence
    ),
recurrence_population
AS (
    SELECT
        *
    FROM recurrence_interval
    WHERE next_sequence_remittance_timestamp IS NOT NULL
    ),
median_calc
AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_gap_minutes
            ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
    ),
median_value
AS (
    SELECT
        MAX(median_recurrence_gap_minutes) AS median_recurrence_gap_minutes
    FROM median_calc
    ),
absolute_deviations
AS (
    SELECT
        rp.*,
        mv.median_recurrence_gap_minutes,
        ABS(rp.recurrence_gap_minutes - mv.median_recurrence_gap_minutes) AS absolute_deviation
    FROM recurrence_population rp
    CROSS JOIN median_value mv
    ),
mad_calc
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_recurrence_gap_minutes
    FROM absolute_deviations
    )
SELECT
    ad.*,
    mc.mad_recurrence_gap_minutes,
    CASE 
        WHEN ad.recurrence_gap_minutes < ad.median_recurrence_gap_minutes
                AND mc.mad_recurrence_gap_minutes > 0
            THEN (ad.median_recurrence_gap_minutes - ad.recurrence_gap_minutes) / mc.mad_recurrence_gap_minutes
        ELSE 0
        END AS remittance_cashout_recurrence_score
FROM absolute_deviations ad
CROSS JOIN mad_calc mc;
GO

-- 3. Remittance Cashout Corresponding value
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_cashout_amt_score
AS
WITH candidate_pairs
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        t.transaction_id,
        t.transaction_timestamp AS cash_out_timestamp,
        t.transaction_amount    AS cash_out_amt,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            r.remittance_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS cash_out_rn,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            t.transaction_id ORDER BY r.remittance_timestamp DESC,
                r.remittance_id DESC
            ) AS remittance_rn
    FROM gold.vw_remittance r
    INNER JOIN gold.vw_transaction t ON
            r.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= r.remittance_timestamp
                AND t.transaction_type = 'Cash Out'
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt
    FROM candidate_pairs
    WHERE cash_out_rn = 1
            AND remittance_rn = 1
    ),
amount_relationship
AS (
    SELECT
        *,
        cash_out_amt / NULLIF(remittance_amount, 0) AS cash_out_to_remittance_ratio
    FROM clean_population
    ),
log_relationship
AS (
    SELECT
        *,
        LOG(cash_out_to_remittance_ratio) AS log_cash_out_to_remittance_ratio
    FROM amount_relationship
    WHERE cash_out_to_remittance_ratio > 0
    ),
median_calc
AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_cash_out_to_remittance_ratio
            ) OVER () AS median_log_ratio
    FROM log_relationship
    ),
median_value
AS (
    SELECT
        MAX(median_log_ratio) AS median_log_ratio
    FROM median_calc
    ),
absolute_deviations
AS (
    SELECT
        lr.*,
        mv.median_log_ratio,
        ABS(lr.log_cash_out_to_remittance_ratio - mv.median_log_ratio) AS absolute_deviation
    FROM log_relationship lr
    CROSS JOIN median_value mv
    ),
mad_calc
AS (
    SELECT TOP 1
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_log_ratio
    FROM absolute_deviations
    )
SELECT
    ad.ocb_customer_id,
    ad.remittance_id,
    ad.remittance_timestamp,
    ad.remittance_amount,
    ad.transaction_id,
    ad.cash_out_timestamp,
    ad.cash_out_amt,
    ad.cash_out_to_remittance_ratio,
    ad.log_cash_out_to_remittance_ratio,
    ad.median_log_ratio,
    mc.mad_log_ratio,
    CASE 
        WHEN ad.log_cash_out_to_remittance_ratio > ad.median_log_ratio
            THEN (ad.log_cash_out_to_remittance_ratio - ad.median_log_ratio) / NULLIF(mc.mad_log_ratio, 0)
        ELSE 0
        END AS remittance_cashout_amt_score
FROM absolute_deviations ad
CROSS JOIN mad_calc mc;
GO

-- 4. Remittance Cashout Origin risk flag
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_cashout_origin_risk_flag
AS
WITH candidate_pairs
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        r.remittance_origin_country,
        t.transaction_id,
        t.transaction_timestamp AS cash_out_timestamp,
        t.transaction_amount    AS cash_out_amt,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            r.remittance_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS cash_out_rn,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            t.transaction_id ORDER BY r.remittance_timestamp DESC,
                r.remittance_id DESC
            ) AS remittance_rn
    FROM gold.vw_remittance r
    INNER JOIN gold.vw_transaction t ON
            r.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_timestamp >= r.remittance_timestamp
                AND t.transaction_type = 'Cash Out'
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        remittance_origin_country,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt
    FROM candidate_pairs
    WHERE cash_out_rn = 1
            AND remittance_rn = 1
    )
SELECT
    *,
    CASE 
        WHEN remittance_origin_country = 'cote d''ivoire'
                AND CAST(remittance_timestamp AS DATE) >= '2024-10-01'
            THEN 1
        WHEN remittance_origin_country = 'nigeria'
                AND CAST(remittance_timestamp AS DATE) BETWEEN '2023-02-01'
                AND '2025-09-30'
            THEN 1
        WHEN remittance_origin_country = 'south africa'
                AND CAST(remittance_timestamp AS DATE) BETWEEN '2023-02-01'
                AND '2025-09-30'
            THEN 1
        WHEN remittance_origin_country = 'united arab emirates'
                AND CAST(remittance_timestamp AS DATE) < '2024-02-01'
            THEN 1
        ELSE 0
        END AS remittance_cashout_origin_risk_flag
FROM clean_population;
GO

/*
-- WP5.3 Sequence Anomaly Engine — Remittance → Cash Out Process Documentation
-- Remittance → Cash Out was defined as the sequence of an incoming remittance followed by a subsequent Cash Out
    transaction for the same customer.
-- The sequence population was constructed by joining remittances to subsequent Cash Out transactions within each
    customer and applying deterministic one-to-one attribution controls.
-- For each remittance, the first subsequent Cash Out was retained.
-- For each Cash Out, the most recent preceding remittance was retained.
-- This deduplication was applied before calculating sequence-level signals to prevent one remittance or Cash Out
    from generating multiple analytical sequences.
-- The resulting clean population provides a consistent sequence grain across all four signals.
-- The engine was evaluated using four independent signals: Rapidity, Amount Relationship, Recurrence / Velocity,
    and Origin Risk.
-- Remittance → Cash Out is not inherently anomalous because cashing out incoming remittance funds is an expected
    customer behaviour.
-- The analytical phenomenon of interest is repeated rapid conversion of incoming cross-border funds into cash,
    particularly where the behaviour is unusually rapid, unusually large relative to the incoming remittance,
    repeatedly performed at unusually short intervals, or occurs within a relevant origin-risk context.
-- Rapidity measures the elapsed time between the remittance timestamp and the subsequent Cash Out timestamp.
-- The rapidity distribution was strongly right-skewed, with most observations occurring at longer delays and a
    smaller population of very rapid conversions.
-- Rapidity was therefore transformed using the natural logarithm through SQL Server LOG() before calculating the
    population median and MAD.
-- Rapidity was scored using the population median and MAD, with shorter-than-median remittance-to-Cash Out delays
    receiving positive scores and longer delays receiving zero.
-- The rapidity score therefore increases as the observed Remittance → Cash Out conversion becomes progressively
    faster relative to the population.
-- Amount Relationship was defined as Cash Out Value / Remittance Value.
-- The raw amount relationship was highly right-skewed, with some Cash Out values substantially exceeding the
    corresponding remittance value.
-- The amount relationship was therefore transformed using the natural logarithm through SQL Server LOG(), while
    preserving the ordering of the underlying ratio.
-- Amount Relationship was scored using the population median and MAD, with values above the population median
    receiving positive scores and values at or below the median receiving zero.
-- A ratio above 1.0 does not establish that the Cash Out was funded by the remittance, because the sequence
    definition establishes temporal and customer association but does not establish fund provenance.
-- Accordingly, the amount relationship is interpreted as observed Cash Out value relative to observed remittance
    value, rather than as a direct measure of the proportion of the remittance that was converted to cash.
-- Recurrence / Velocity measures the elapsed time between one qualifying Remittance → Cash Out sequence and the
    next qualifying sequence for the same customer.
-- The recurrence interval is measured from the Cash Out timestamp of the current qualifying sequence to the
    remittance timestamp of the customer's next qualifying sequence.
-- The recurrence interval therefore measures the time elapsed between the endpoint of Sequence 1 and the startpoint
    of Sequence 2, rather than the time between consecutive remittance timestamps.
-- The next qualifying sequence is identified using LEAD() over the chronologically ordered, deduplicated qualifying
    sequence population for each customer.
-- LEAD() is applied after the qualifying Remittance → Cash Out sequences have been established, ensuring that
    recurrence is calculated between complete qualifying sequences rather than individual remittance events.
-- The final qualifying sequence for a customer has no subsequent sequence and is therefore excluded from recurrence
    scoring.
-- Recurrence was scored using the population median and MAD, with shorter inter-sequence gaps receiving positive
    scores and longer gaps receiving zero.
-- The recurrence score therefore measures how quickly the customer repeats the qualifying Remittance → Cash Out
    pattern after completing the preceding sequence, rather than simply counting how many sequences occurred.
-- Origin Risk was defined as a contextual, binary, time-aware flag based on the FATF grey list (jurisdictions under
    increased monitoring) using the historical risk periods.
-- Origin Risk does not use MAD because it is not a continuous behavioural signal.
-- The flag is set to 1 when the remittance originated from a jurisdiction that was subject to the defined risk
    condition at the time of the remittance and 0 otherwise.
-- The historical risk periods applied were: Nigeria and South Africa from February 2023 through September 2025,
    United Arab Emirates before February 2024, and Côte d'Ivoire from October 2024 onward.
-- The origin-risk periods were applied against the remittance timestamp rather than assigning a permanent country
    risk classification across the entire dataset.
-- The resulting population validation confirmed that the time boundaries produced the expected transitions between
    risk_flag = 1 and risk_flag = 0 for each applicable jurisdiction.
-- The three behavioural signals were evaluated independently as sequence-level anomaly constructs, while Origin
    Risk was retained as a separate contextual signal.
-- The four signals were not mathematically combined into a single Remittance → Cash Out risk score.
-- No universal score thresholds were established. Score distributions and bands were used to validate the behaviour
    and integrity of the individual scoring mechanisms.
-- The analysis does not establish that a qualifying sequence, a high signal score, a high amount relationship,
    repeated sequence, or origin-risk flag is fraudulent, suspicious, or inherently higher risk.
-- The final Remittance → Cash Out engine therefore provides four independent dimensions of intelligence: how
    rapidly the conversion occurs, how large the observed Cash Out is relative to the remittance, how quickly the
    pattern repeats after the preceding Cash Out, and whether the remittance origin carried the defined contextual
    risk at the time.
-- The Remittance → Cash Out engine was validated at sequence grain using three independent behavioural anomaly
    signals and one contextual binary signal.
*/
-- Combined Remittance → Cash Out Signals
WITH rapidity
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        cash_out_delay_minutes,
        log_delay,
        median_log_delay,
        mad_log_delay,
        remittance_cashout_rapidity_score
    FROM intelligence.vw_remittance_cashout_rapidity_score
    ),
recurrence
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        remittance_timestamp,
        remittance_amount,
        transaction_id,
        cash_out_timestamp,
        cash_out_amt,
        next_sequence_remittance_timestamp,
        recurrence_gap_minutes,
        median_recurrence_gap_minutes,
        absolute_deviation,
        mad_recurrence_gap_minutes,
        remittance_cashout_recurrence_score
    FROM intelligence.vw_remittance_cashout_recurrence_score
    ),
amount
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        transaction_id,
        cash_out_to_remittance_ratio,
        log_cash_out_to_remittance_ratio,
        median_log_ratio,
        mad_log_ratio,
        remittance_cashout_amt_score
    FROM intelligence.vw_remittance_cashout_amt_score
    ),
origin
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        transaction_id,
        remittance_origin_country,
        remittance_cashout_origin_risk_flag
    FROM intelligence.vw_remittance_cashout_origin_risk_flag
    )
SELECT
    -- Sequence identifiers
    r.ocb_customer_id,
    r.remittance_id,
    r.remittance_timestamp,
    r.remittance_amount,
    r.transaction_id,
    r.cash_out_timestamp,
    r.cash_out_amt,
    -- Signal 1: Rapidity
    r.cash_out_delay_minutes,
    r.remittance_cashout_rapidity_score,
    -- Signal 2: Amount Relationship
    a.cash_out_to_remittance_ratio,
    a.remittance_cashout_amt_score,
    -- Signal 3: Recurrence / Velocity
    rc.next_sequence_remittance_timestamp,
    rc.recurrence_gap_minutes,
    rc.remittance_cashout_recurrence_score,
    -- Signal 4: Origin Risk
    o.remittance_origin_country,
    o.remittance_cashout_origin_risk_flag
FROM rapidity r
LEFT JOIN recurrence rc ON
        r.ocb_customer_id = rc.ocb_customer_id
            AND r.remittance_id = rc.remittance_id
            AND r.transaction_id = rc.transaction_id
LEFT JOIN amount a ON
        r.ocb_customer_id = a.ocb_customer_id
            AND r.remittance_id = a.remittance_id
            AND r.transaction_id = a.transaction_id
LEFT JOIN origin o ON
        r.ocb_customer_id = o.ocb_customer_id
            AND r.remittance_id = o.remittance_id
            AND r.transaction_id = o.transaction_id
ORDER BY r.ocb_customer_id,
    r.remittance_timestamp,
    r.remittance_id;
GO



