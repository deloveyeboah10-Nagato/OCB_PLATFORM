USE [ocb_platform];
GO

-- DOMESTIC FUNDING → OUTBOUND EXTERNAL FLOW
-- 1. Funding-to-Remittance Rapidity Score
CREATE
        OR

ALTER VIEW intelligence.vw_cashin_remittance_rapidity_score
AS
WITH cashin_sequences
AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_id        AS cash_in_id,
        t.transaction_timestamp AS cash_in_timestamp,
        t.transaction_amount    AS cash_in_amount,
        LEAD(t.transaction_timestamp) OVER (
            PARTITION BY t.ocb_customer_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS next_cash_in_timestamp
    FROM gold.vw_transaction AS t
    WHERE t.transaction_type = 'cash in'
    ),
cashin_remittance_profile
AS (
    SELECT
        c.ocb_customer_id,
        c.cash_in_id,
        c.cash_in_timestamp,
        c.cash_in_amount,
        c.next_cash_in_timestamp,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent,
        ROW_NUMBER() OVER (
            PARTITION BY c.ocb_customer_id,
            c.cash_in_id ORDER BY r.remittance_timestamp,
                r.remittance_id
            ) AS remittance_sequence_number
    FROM cashin_sequences AS c
    INNER JOIN gold.vw_remittance AS r ON
            r.ocb_customer_id = c.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= c.cash_in_timestamp
                AND (
                c.next_cash_in_timestamp IS NULL
                    OR r.remittance_timestamp < c.next_cash_in_timestamp
                )
    ),
first_remittance
AS (
    SELECT
        ocb_customer_id,
        cash_in_id,
        cash_in_timestamp,
        cash_in_amount,
        next_cash_in_timestamp,
        remittance_id                                                                                        AS first_remittance_id,
        remittance_timestamp                                                                                 AS first_remittance_timestamp,
        remittance_amount_sent                                                                               AS first_remittance_amount_sent,
        CAST(DATEDIFF_BIG(MILLISECOND, cash_in_timestamp, remittance_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS cashin_remittance_delay_minutes
    FROM cashin_remittance_profile
    WHERE remittance_sequence_number = 1
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY cashin_remittance_delay_minutes
            ) OVER () AS median_delay_minutes
    FROM first_remittance
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(f.cashin_remittance_delay_minutes - m.median_delay_minutes)
            ) OVER () AS mad_delay_minutes
    FROM first_remittance AS f
    CROSS JOIN median_stage AS m
    ),
rapidity_scores
AS (
    SELECT
        f.*,
        m.median_delay_minutes,
        d.mad_delay_minutes,
        CASE 
            WHEN d.mad_delay_minutes > 0
                    AND f.cashin_remittance_delay_minutes < m.median_delay_minutes
                THEN (m.median_delay_minutes - f.cashin_remittance_delay_minutes) / d.mad_delay_minutes
            ELSE 0
            END AS funding_remittance_rapidity_score
    FROM first_remittance AS f
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
    )
SELECT
    ocb_customer_id,
    cash_in_id,
    cash_in_timestamp,
    cash_in_amount,
    next_cash_in_timestamp,
    first_remittance_id,
    first_remittance_timestamp,
    first_remittance_amount_sent,
    cashin_remittance_delay_minutes,
    median_delay_minutes,
    mad_delay_minutes,
    funding_remittance_rapidity_score
FROM rapidity_scores;
GO

-- 2. Funding-to-Remittance Value Correspondence Score
CREATE
        OR

ALTER VIEW intelligence.vw_cashin_remittance_value_correspondence_score
AS
WITH cashin_sequences
AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_id        AS cash_in_id,
        t.transaction_timestamp AS cash_in_timestamp,
        t.transaction_amount    AS cash_in_amount,
        LEAD(t.transaction_timestamp) OVER (
            PARTITION BY t.ocb_customer_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS next_cash_in_timestamp
    FROM gold.vw_transaction AS t
    WHERE t.transaction_type = 'cash in'
    ),
cashin_remittance_profile
AS (
    SELECT
        c.ocb_customer_id,
        c.cash_in_id,
        c.cash_in_timestamp,
        c.cash_in_amount,
        c.next_cash_in_timestamp,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent
    FROM cashin_sequences AS c
    INNER JOIN gold.vw_remittance AS r ON
            r.ocb_customer_id = c.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= c.cash_in_timestamp
                AND (
                c.next_cash_in_timestamp IS NULL
                    OR r.remittance_timestamp < c.next_cash_in_timestamp
                )
    ),
remittance_sequence_totals
AS (
    SELECT
        ocb_customer_id,
        cash_in_id,
        cash_in_timestamp,
        cash_in_amount,
        next_cash_in_timestamp,
        COUNT(remittance_id)        AS remittance_count,
        SUM(remittance_amount_sent) AS total_remittance_amount_sent
    FROM cashin_remittance_profile
    GROUP BY ocb_customer_id,
        cash_in_id,
        cash_in_timestamp,
        cash_in_amount,
        next_cash_in_timestamp
    ),
value_correspondence
AS (
    SELECT
        *,
        total_remittance_amount_sent / NULLIF(cash_in_amount, 0) AS funding_remittance_ratio
    FROM remittance_sequence_totals
    ),
log_value_ratio
AS (
    SELECT
        *,
        LOG(funding_remittance_ratio) AS log_funding_remittance_ratio
    FROM value_correspondence
    WHERE funding_remittance_ratio > 0
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_funding_remittance_ratio
            ) OVER () AS median_log_ratio
    FROM log_value_ratio
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(l.log_funding_remittance_ratio - m.median_log_ratio)
            ) OVER () AS mad_log_ratio
    FROM log_value_ratio AS l
    CROSS JOIN median_stage AS m
    ),
value_correspondence_scores
AS (
    SELECT
        l.*,
        m.median_log_ratio,
        d.mad_log_ratio,
        CASE 
            WHEN d.mad_log_ratio > 0
                    AND l.log_funding_remittance_ratio > m.median_log_ratio
                THEN (l.log_funding_remittance_ratio - m.median_log_ratio) / d.mad_log_ratio
            ELSE 0
            END AS funding_remittance_value_correspondence_score
    FROM log_value_ratio AS l
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
    )
SELECT
    ocb_customer_id,
    cash_in_id,
    cash_in_timestamp,
    cash_in_amount,
    next_cash_in_timestamp,
    remittance_count,
    total_remittance_amount_sent,
    funding_remittance_ratio,
    log_funding_remittance_ratio,
    median_log_ratio,
    mad_log_ratio,
    funding_remittance_value_correspondence_score
FROM value_correspondence_scores;
GO

-- 3. Recurrent Funding-to-Remittance Behaviour
CREATE
        OR

ALTER VIEW intelligence.vw_cashin_remittance_recurrence_score
AS
WITH cashin_sequences
AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_id        AS cash_in_id,
        t.transaction_timestamp AS cash_in_timestamp,
        t.transaction_amount    AS cash_in_amount,
        LEAD(t.transaction_timestamp) OVER (
            PARTITION BY t.ocb_customer_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS next_cash_in_timestamp,
        LEAD(t.transaction_id) OVER (
            PARTITION BY t.ocb_customer_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS next_cash_in_id
    FROM gold.vw_transaction AS t
    WHERE t.transaction_type = 'cash in'
    ),
cashin_remittance_sequences
AS (
    SELECT
        c.ocb_customer_id,
        c.cash_in_id,
        c.cash_in_timestamp,
        c.cash_in_amount,
        c.next_cash_in_id,
        c.next_cash_in_timestamp,
        MAX(r.remittance_timestamp) AS last_remittance_timestamp,
        COUNT(r.remittance_id)      AS remittance_count
    FROM cashin_sequences AS c
    INNER JOIN gold.vw_remittance AS r ON
            r.ocb_customer_id = c.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= c.cash_in_timestamp
                AND (
                c.next_cash_in_timestamp IS NULL
                    OR r.remittance_timestamp < c.next_cash_in_timestamp
                )
    GROUP BY c.ocb_customer_id,
        c.cash_in_id,
        c.cash_in_timestamp,
        c.cash_in_amount,
        c.next_cash_in_id,
        c.next_cash_in_timestamp
    ),
recurrence_population
AS (
    SELECT
        ocb_customer_id,
        cash_in_id,
        cash_in_timestamp,
        cash_in_amount,
        last_remittance_timestamp,
        next_cash_in_id,
        next_cash_in_timestamp,
        remittance_count,
        CAST(DATEDIFF_BIG(MILLISECOND, last_remittance_timestamp, next_cash_in_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS recurrence_gap_minutes
    FROM cashin_remittance_sequences
    WHERE next_cash_in_timestamp IS NOT NULL
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_gap_minutes
            ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(rp.recurrence_gap_minutes - m.median_recurrence_gap_minutes)
            ) OVER () AS mad_recurrence_gap_minutes
    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
    ),
recurrence_scores
AS (
    SELECT
        rp.*,
        m.median_recurrence_gap_minutes,
        d.mad_recurrence_gap_minutes,
        CASE 
            WHEN d.mad_recurrence_gap_minutes > 0
                    AND rp.recurrence_gap_minutes < m.median_recurrence_gap_minutes
                THEN (m.median_recurrence_gap_minutes - rp.recurrence_gap_minutes) / d.mad_recurrence_gap_minutes
            ELSE 0
            END AS funding_remittance_recurrence_score
    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
    )
SELECT
    ocb_customer_id,
    cash_in_id,
    cash_in_timestamp,
    cash_in_amount,
    last_remittance_timestamp,
    next_cash_in_id,
    next_cash_in_timestamp,
    remittance_count,
    recurrence_gap_minutes,
    median_recurrence_gap_minutes,
    mad_recurrence_gap_minutes,
    funding_remittance_recurrence_score
FROM recurrence_scores;
GO

/*
-- WP5.3 Funding → Remittance Intelligence Engine — Process Documentation
-- The Funding → Remittance Intelligence Engine evaluates temporal and value relationships
-- between domestic Cash In transactions and outbound Remittance Sent events for the same
-- OCB customer.
-- The engine comprises three independent signals: Funding → Remittance Rapidity,
-- Funding → Remittance Value Correspondence, and Funding → Remittance Recurrence.
-- The three signals measure distinct dimensions of the observed financial behaviour and are
-- not mathematically combined into a single Funding → Remittance risk score.
-- Each Cash In transaction defines the start of a sequence for the corresponding OCB customer.
-- Sequences are ordered chronologically by cash-in timestamp and transaction ID.
-- Each sequence ends immediately before the next Cash In transaction for the same customer.
-- The final sequence extends to the end of the available data.
-- A qualifying Remittance Sent event must occur at or after the sequence's cash-in timestamp
-- and before the next cash-in timestamp, where a subsequent cash-in exists.
-- Remittance events are assigned to sequences according to these temporal boundaries.
-- A sequence may contain multiple outbound remittance events.
-- This sequence-based design captures multiple outbound remittance events following a cash-in
-- rather than restricting the analysis to a single matched remittance event.
-- Sequences without a qualifying Remittance Sent event are excluded from the signal populations.
-- Funding → Remittance Rapidity measures the elapsed time between a Cash In transaction and
-- the first Remittance Sent event within its sequence.
-- The first remittance is identified by ordering qualifying remittance events by timestamp
-- and remittance ID.
-- The elapsed interval is measured in minutes using the cash-in timestamp and the first
-- remittance timestamp.
-- The rapidity population consists of cash-in sequences containing at least one qualifying
-- outbound remittance event.
-- The population median of the elapsed intervals establishes the reference level for typical
-- funding-to-remittance timing.
-- The Median Absolute Deviation (MAD) measures the population's dispersion around the median.
-- Elapsed intervals shorter than the population median receive positive rapidity scores
-- where the population MAD is greater than zero.
-- The rapidity score is calculated as the difference between the population median and the
-- observed elapsed interval, divided by the population MAD.
-- Elapsed intervals at or above the population median receive zero scores.
-- Where the population MAD is zero, the rapidity score is zero.
-- The rapidity score therefore increases as the first outbound remittance occurs more quickly
-- following a cash-in relative to the observed population.
-- Funding → Remittance Value Correspondence evaluates the relationship between the cash-in
-- amount and the total outbound remittance value observed within the corresponding sequence.
-- All qualifying Remittance Sent amounts within the sequence are aggregated.
-- The funding-to-remittance value ratio is calculated by dividing the total remittance amount
-- by the cash-in amount.
-- Sequences with a zero cash-in amount or a non-positive value ratio are excluded from the
-- log-ratio scoring population.
-- The natural logarithm of the funding-to-remittance value ratio is used to transform the
-- ratio before calculating the population reference statistics.
-- The population median of the log ratios establishes the reference level for typical
-- funding-to-remittance value correspondence.
-- The Median Absolute Deviation (MAD) measures the dispersion of the log ratios around
-- the population median.
-- Log ratios above the population median receive positive value-correspondence scores
-- where the population MAD is greater than zero.
-- The score is calculated as the difference between the observed log ratio and the population
-- median log ratio, divided by the MAD of the log ratios.
-- Log ratios at or below the population median receive zero scores.
-- Where the population MAD is zero, the value-correspondence score is zero.
-- The score therefore increases as aggregate outbound remittance value becomes larger relative
-- to the cash-in amount compared with the observed population.
-- The ratio is not capped at one because aggregate remittance value may exceed the amount
-- of an individual cash-in.
-- A ratio above one does not establish that the cash-in directly funded the excess remittance
-- value, since customers may have had pre-existing balances or other sources of funds.
-- Funding → Remittance Recurrence measures the interval between the last Remittance Sent
-- event in a cash-in sequence and the next Cash In transaction for the same customer.
-- The last remittance is identified using the maximum remittance timestamp within the sequence.
-- The next cash-in transaction establishes the start of the subsequent sequence.
-- The recurrence interval is measured in minutes from the last remittance timestamp to the
-- next cash-in timestamp.
-- The recurrence population includes qualifying sequences that contain at least one remittance
-- and have a subsequent cash-in transaction.
-- Sequences without a subsequent cash-in transaction are excluded from recurrence scoring.
-- The population median of the recurrence intervals establishes the reference level for typical
-- intervals between the end of outbound remittance activity and the next cash-in.
-- The Median Absolute Deviation (MAD) measures the dispersion of recurrence intervals around
-- the population median.
-- Recurrence intervals shorter than the population median receive positive recurrence scores
-- where the population MAD is greater than zero.
-- The score is calculated as the difference between the population median and the observed
-- recurrence interval, divided by the population MAD.
-- Recurrence intervals at or above the population median receive zero scores.
-- Where the population MAD is zero, the recurrence score is zero.
-- The recurrence score therefore increases as the interval between the last remittance in one
-- sequence and the next cash-in becomes shorter relative to the observed population.
-- Rapidity measures the timing of the first outbound remittance following a cash-in.
-- Value Correspondence measures aggregate outbound remittance value relative to the cash-in.
-- Recurrence measures the interval between the last outbound remittance in one sequence and
-- the next cash-in.
-- The three signals represent distinct temporal and value dimensions of Funding → Remittance
-- behaviour and are evaluated independently.
-- Their scoring populations are related but not identical because each signal has different
-- eligibility requirements.
-- No universal score thresholds are established.
-- Score distributions and bands are used to validate the behaviour and integrity of the
-- individual scoring mechanisms.
-- A high signal score or repeated occurrence of this behaviour does not, by itself, establish
-- fraud, suspicious activity, or inherently higher risk.
-- The analytical phenomenon of interest is repeated domestic funding followed by outbound
-- remittance activity, particularly where the observed timing or aggregate values are unusual
-- relative to the population.
-- Such behaviour may provide a basis for further financial-behaviour and transaction-risk
-- investigation.
-- Temporal sequence membership does not prove that a particular cash-in funded a particular
-- remittance.
-- The engine establishes behavioural associations from observed event timing and value;
-- it does not establish direct fund tracing or causation.
*/
-- Signal Combination
SELECT
    r.ocb_customer_id,
    r.cash_in_id                   AS transaction_id,
    r.cash_in_timestamp,
    r.cash_in_amount,
    r.first_remittance_id          AS remittance_id,
    r.first_remittance_timestamp   AS remittance_timestamp,
    r.first_remittance_amount_sent AS remittance_amount_sent,
    -- Funding-to-Remittance Temporal Proximity
    r.cashin_remittance_delay_minutes,
    r.funding_remittance_rapidity_score,
    -- Funding-to-Remittance Value Correspondence
    v.remittance_count,
    v.total_remittance_amount_sent,
    v.funding_remittance_ratio,
    v.log_funding_remittance_ratio,
    v.funding_remittance_value_correspondence_score,
    -- Recurrent Funding-to-Remittance Behaviour
    s.next_cash_in_id              AS next_sequence_transaction_id,
    s.next_cash_in_timestamp       AS next_sequence_cash_in_timestamp,
    s.recurrence_gap_minutes,
    s.funding_remittance_recurrence_score
FROM intelligence.vw_cashin_remittance_rapidity_score AS r
LEFT JOIN intelligence.vw_cashin_remittance_value_correspondence_score AS v ON
        r.ocb_customer_id = v.ocb_customer_id
            AND r.cash_in_id = v.cash_in_id
LEFT JOIN intelligence.vw_cashin_remittance_recurrence_score AS s ON
        r.ocb_customer_id = s.ocb_customer_id
            AND r.cash_in_id = s.cash_in_id;
GO

-- Domestic credit → outbound remittance  
-- Credit-to-Remittance Rapidity Score
CREATE
        OR

ALTER VIEW intelligence.vw_credit_to_remittance_rapidity_score
AS
WITH loan_remittance_profile
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent,
        ROW_NUMBER() OVER (
            PARTITION BY l.ocb_customer_id,
            l.loan_id ORDER BY r.remittance_timestamp ASC,
                r.remittance_id ASC
            ) AS loan_rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_remittance r ON
            l.ocb_customer_id = r.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= l.disbursement_timestamp
    ),
first_remittance_per_loan_disbursed
AS (
    SELECT
        *
    FROM loan_remittance_profile
    WHERE loan_rn = 1
    ),
deduplicated_remittances
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            remittance_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS remittance_rn
    FROM first_remittance_per_loan_disbursed
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp AS loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent
    FROM deduplicated_remittances
    WHERE remittance_rn = 1
    ),
rapidity
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent,
        CAST(DATEDIFF_BIG(MILLISECOND, loan_timestamp, remittance_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS loan_remittance_minutes
    FROM clean_population
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY loan_remittance_minutes
            ) OVER () AS median_loan_remittance_minutes
    FROM rapidity
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(r.loan_remittance_minutes - m.median_loan_remittance_minutes)
            ) OVER () AS mad_loan_remittance_minutes
    FROM rapidity r
    CROSS JOIN median_stage m
    )
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.loan_timestamp,
    r.principal_amount,
    r.remittance_id,
    r.remittance_timestamp,
    r.remittance_amount_sent,
    r.loan_remittance_minutes,
    m.median_loan_remittance_minutes,
    d.mad_loan_remittance_minutes,
    CASE 
        WHEN r.loan_remittance_minutes < m.median_loan_remittance_minutes
                AND d.mad_loan_remittance_minutes > 0
            THEN (m.median_loan_remittance_minutes - r.loan_remittance_minutes) / d.mad_loan_remittance_minutes
        ELSE 0
        END AS credit_to_remittance_rapidity_score
FROM rapidity r
CROSS JOIN median_stage m
CROSS JOIN mad_stage d;
GO

-- Credit-to-Remittance Value
CREATE
        OR

ALTER VIEW intelligence.vw_credit_to_remittance_value_correspondence_score
AS
WITH loan_remittance_profile
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent,
        ROW_NUMBER() OVER (
            PARTITION BY l.ocb_customer_id,
            l.loan_id ORDER BY r.remittance_timestamp ASC,
                r.remittance_id ASC
            ) AS loan_rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_remittance r ON
            l.ocb_customer_id = r.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= l.disbursement_timestamp
    ),
first_remittance_per_loan_disbursed
AS (
    SELECT
        *
    FROM loan_remittance_profile
    WHERE loan_rn = 1
    ),
deduplicated_remittances
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            remittance_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS remittance_rn
    FROM first_remittance_per_loan_disbursed
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp AS loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent
    FROM deduplicated_remittances
    WHERE remittance_rn = 1
    ),
value_correspondence
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent,
        remittance_amount_sent / NULLIF(principal_amount, 0)      AS remittance_to_loan_ratio,
        LOG(remittance_amount_sent / NULLIF(principal_amount, 0)) AS log_remittance_to_loan_ratio
    FROM clean_population
    WHERE principal_amount > 0
            AND remittance_amount_sent > 0
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_remittance_to_loan_ratio
            ) OVER () AS median_log_ratio
    FROM value_correspondence
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(v.log_remittance_to_loan_ratio - m.median_log_ratio)
            ) OVER () AS mad_log_ratio
    FROM value_correspondence v
    CROSS JOIN median_stage m
    )
SELECT
    v.ocb_customer_id,
    v.loan_id,
    v.loan_timestamp,
    v.principal_amount,
    v.remittance_id,
    v.remittance_timestamp,
    v.remittance_amount_sent,
    v.remittance_to_loan_ratio,
    v.log_remittance_to_loan_ratio,
    m.median_log_ratio,
    d.mad_log_ratio,
    CASE 
        WHEN v.log_remittance_to_loan_ratio > m.median_log_ratio
                AND d.mad_log_ratio > 0
            THEN (v.log_remittance_to_loan_ratio - m.median_log_ratio) / d.mad_log_ratio
        ELSE 0
        END AS credit_to_remittance_value_correspondence_score
FROM value_correspondence v
CROSS JOIN median_stage m
CROSS JOIN mad_stage d;
GO

-- Credit-to-Remittance Recurrence Score.
CREATE
        OR

ALTER VIEW intelligence.vw_credit_to_remittance_recurrence_score
AS
WITH loan_remittance_profile
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent,
        ROW_NUMBER() OVER (
            PARTITION BY l.ocb_customer_id,
            l.loan_id ORDER BY r.remittance_timestamp ASC,
                r.remittance_id ASC
            ) AS loan_rn
    FROM gold.vw_loan l
    INNER JOIN gold.vw_remittance r ON
            l.ocb_customer_id = r.ocb_customer_id
                AND r.remittance_type = 'remittance_sent'
                AND r.remittance_timestamp >= l.disbursement_timestamp
    ),
first_remittance_per_loan_disbursed
AS (
    SELECT
        *
    FROM loan_remittance_profile
    WHERE loan_rn = 1
    ),
deduplicated_remittances
AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ocb_customer_id,
            remittance_id ORDER BY disbursement_timestamp DESC,
                loan_id DESC
            ) AS remittance_rn
    FROM first_remittance_per_loan_disbursed
    ),
clean_population
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        disbursement_timestamp AS loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent
    FROM deduplicated_remittances
    WHERE remittance_rn = 1
    ),
sequenced_credit_remittance
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent,
        LEAD(loan_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_timestamp,
                loan_id
            ) AS next_loan_id,
        LEAD(loan_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_timestamp,
                loan_id
            ) AS next_loan_timestamp,
        LEAD(remittance_id) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_timestamp,
                loan_id
            ) AS next_remittance_id,
        LEAD(remittance_timestamp) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_timestamp,
                loan_id
            ) AS next_remittance_timestamp
    FROM clean_population
    ),
recurrence
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        loan_timestamp,
        principal_amount,
        remittance_id,
        remittance_timestamp,
        next_loan_id,
        next_loan_timestamp,
        next_remittance_id,
        next_remittance_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, remittance_timestamp, next_loan_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS credit_to_remittance_recurrence_minutes
    FROM sequenced_credit_remittance
    ),
median_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY credit_to_remittance_recurrence_minutes
            ) OVER () AS median_recurrence_minutes
    FROM recurrence
    WHERE credit_to_remittance_recurrence_minutes IS NOT NULL
    ),
mad_stage
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(r.credit_to_remittance_recurrence_minutes - m.median_recurrence_minutes)
            ) OVER () AS mad_recurrence_minutes
    FROM recurrence r
    CROSS JOIN median_stage m
    WHERE r.credit_to_remittance_recurrence_minutes IS NOT NULL
    )
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.loan_timestamp,
    r.principal_amount,
    r.remittance_id,
    r.remittance_timestamp,
    r.next_loan_id,
    r.next_loan_timestamp,
    r.next_remittance_id,
    r.next_remittance_timestamp,
    r.credit_to_remittance_recurrence_minutes,
    m.median_recurrence_minutes,
    d.mad_recurrence_minutes,
    CASE 
        WHEN r.credit_to_remittance_recurrence_minutes < m.median_recurrence_minutes
                AND d.mad_recurrence_minutes > 0
            THEN (m.median_recurrence_minutes - r.credit_to_remittance_recurrence_minutes) / d.mad_recurrence_minutes
        ELSE 0
        END AS credit_to_remittance_recurrence_score
FROM recurrence r
CROSS JOIN median_stage m
CROSS JOIN mad_stage d;
GO

/*
-- WP5.3 Credit → Remittance Intelligence Engine — Process Documentation
-- Credit → Remittance Intelligence identifies matched Loan Disbursement → Remittance Sent sequences within the same OCB customer.
-- The engine comprises three independent signals: Credit → Remittance Rapidity, Credit → Remittance Value Correspondence, and
    Credit → Remittance Recurrence.
-- A complete sequence consists of a SikaCredit loan disbursement followed by an Oman Remit outbound remittance for the same OCB
    customer.
-- The remittance timestamp must be greater than or equal to the loan disbursement timestamp.
-- Each loan is matched to the earliest subsequent outbound remittance, ordered by remittance timestamp and remittance ID.
-- Where multiple loans match the same remittance, the latest loan is retained, ordered by disbursement timestamp and loan ID.
-- This produces a one-to-one population of matched sequences.
-- Credit → Remittance Rapidity measures the interval between loan disbursement and matched remittance.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD).
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.
-- Credit → Remittance Value Correspondence measures the remittance amount relative to the loan principal.
-- The remittance-to-loan ratio is calculated by dividing the remittance amount by the loan principal.
-- The natural logarithm of the ratio is used for scoring.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate larger remittances relative to loan principals compared with the observed population.
-- Credit → Remittance Recurrence measures how quickly customers repeat the matched sequence.
-- Successive sequences are identified using LEAD() within each customer.
-- Sequences are ordered by loan disbursement timestamp and loan ID.
-- The recurrence interval runs from the current remittance to the next matched loan disbursement.
-- This measures the gap between one sequence's completion and the next sequence's initiation.
-- The final matched sequence for each customer has no subsequent sequence and is excluded from recurrence calculations.
-- Recurrence scoring uses the population median and MAD of the recurrence intervals.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher recurrence scores relative to the observed population.
-- The three signals measure timing, relative value, and recurrence independently.
-- They are not mathematically combined into a single Credit → Remittance risk score.
-- No universal score thresholds were established.
-- Score distributions and bands were used to validate each scoring mechanism.
-- The engine highlights rapid remittance after borrowing, unusually large remittances relative to loan principals, and repeated
    sequences at short intervals.
-- These patterns may support further financial-behaviour and transaction-risk investigation.
-- The engine provides cross-institutional intelligence on behavioural relationships between digital credit and outbound remittance
    activity.
*/
-- Signal Combination
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.loan_timestamp,
    r.principal_amount,
    r.remittance_id,
    r.remittance_timestamp,
    r.remittance_amount_sent,
    -- Credit-to-Remittance Temporal Proximity
    r.loan_remittance_minutes,
    r.credit_to_remittance_rapidity_score,
    -- Credit-to-Remittance Value Correspondence
    v.remittance_to_loan_ratio,
    v.log_remittance_to_loan_ratio,
    v.credit_to_remittance_value_correspondence_score,
    -- Recurrent Credit-to-Remittance Behaviour
    s.next_loan_id,
    s.credit_to_remittance_recurrence_minutes,
    s.credit_to_remittance_recurrence_score
FROM intelligence.vw_credit_to_remittance_rapidity_score AS r
LEFT JOIN intelligence.vw_credit_to_remittance_value_correspondence_score AS v ON
        r.ocb_customer_id = v.ocb_customer_id
            AND r.loan_id = v.loan_id
LEFT JOIN intelligence.vw_credit_to_remittance_recurrence_score AS s ON
        r.ocb_customer_id = s.ocb_customer_id
            AND r.loan_id = s.loan_id;
GO

-- INBOUND REMITTANCE → P2P REDISTRIBUTION
-- 1. Inbound Remittance-to-P2P Rapidity Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_p2p_rapidity_score
AS
WITH inbound_remittances
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp AS inbound_remittance_timestamp,
        LEAD(r.remittance_timestamp) OVER (
            PARTITION BY r.ocb_customer_id ORDER BY r.remittance_timestamp,
                r.remittance_id
            ) AS next_inbound_remittance_timestamp
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
    ),
remittance_p2ptransfer_profile
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.inbound_remittance_timestamp,
        t.transaction_id        AS p2p_transfer_id,
        t.transaction_timestamp AS p2p_transfer_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY r.ocb_customer_id,
            r.remittance_id ORDER BY t.transaction_timestamp,
                t.transaction_id
            ) AS p2p_sequence_number
    FROM inbound_remittances AS r
    INNER JOIN gold.vw_transaction AS t ON
            r.ocb_customer_id = t.ocb_customer_id
                AND t.transaction_type = 'p2p transfer'
                AND t.transaction_timestamp >= r.inbound_remittance_timestamp
                AND (
                r.next_inbound_remittance_timestamp IS NULL
                    OR t.transaction_timestamp < r.next_inbound_remittance_timestamp
                )
    ),
first_p2p
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        p2p_transfer_id                                                                                                   AS first_p2p_transfer_id,
        p2p_transfer_timestamp                                                                                            AS first_p2p_transfer_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, inbound_remittance_timestamp, p2p_transfer_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS elapsed_minutes
    FROM remittance_p2ptransfer_profile
    WHERE p2p_sequence_number = 1
    ),
median_elapsed
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY elapsed_minutes
            ) OVER () AS median_elapsed_minutes
    FROM first_p2p
    ),
absolute_deviations
AS (
    SELECT
        f.*,
        m.median_elapsed_minutes,
        ABS(f.elapsed_minutes - m.median_elapsed_minutes) AS absolute_deviation
    FROM first_p2p AS f
    CROSS JOIN median_elapsed AS m
    ),
mad_calculation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_elapsed_minutes
    FROM absolute_deviations
    ),
rapidity_scores
AS (
    SELECT
        a.*,
        m.mad_elapsed_minutes,
        CASE 
            WHEN m.mad_elapsed_minutes > 0
                    AND a.elapsed_minutes < a.median_elapsed_minutes
                THEN (a.median_elapsed_minutes - a.elapsed_minutes) / m.mad_elapsed_minutes
            ELSE 0
            END AS inbound_remittance_to_p2p_rapidity_score
    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
    )
SELECT
    ocb_customer_id,
    remittance_id,
    inbound_remittance_timestamp,
    first_p2p_transfer_id,
    first_p2p_transfer_timestamp,
    elapsed_minutes,
    median_elapsed_minutes,
    mad_elapsed_minutes,
    inbound_remittance_to_p2p_rapidity_score
FROM rapidity_scores;
GO

-- 2. Inbound Remittance-to-P2P Value Correspondence Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_p2p_value_correspondence_score
AS
WITH inbound_remittances
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp AS inbound_remittance_timestamp,
        r.remittance_amount    AS inbound_remittance_amount,
        LEAD(r.remittance_timestamp) OVER (
            PARTITION BY r.ocb_customer_id ORDER BY r.remittance_timestamp,
                r.remittance_id
            ) AS next_inbound_remittance_timestamp
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
    ),
remittance_p2ptransfer_profile
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.inbound_remittance_timestamp,
        r.inbound_remittance_amount,
        r.next_inbound_remittance_timestamp,
        t.transaction_id        AS p2p_transfer_id,
        t.transaction_timestamp AS p2p_transfer_timestamp,
        t.transaction_amount    AS p2p_transfer_amount
    FROM inbound_remittances AS r
    INNER JOIN gold.vw_transaction AS t ON
            t.ocb_customer_id = r.ocb_customer_id
                AND t.transaction_type = 'p2p transfer'
                AND t.transaction_timestamp >= r.inbound_remittance_timestamp
                AND (
                r.next_inbound_remittance_timestamp IS NULL
                    OR t.transaction_timestamp < r.next_inbound_remittance_timestamp
                )
    ),
p2p_sequence_totals
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount,
        COUNT(p2p_transfer_id)   AS p2p_transfer_count,
        SUM(p2p_transfer_amount) AS total_p2p_transfer_amount
    FROM remittance_p2ptransfer_profile
    GROUP BY ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount
    ),
value_correspondence
AS (
    SELECT
        *,
        total_p2p_transfer_amount / NULLIF(inbound_remittance_amount, 0) AS p2p_to_remittance_value_ratio
    FROM p2p_sequence_totals
    ),
log_value_ratio
AS (
    SELECT
        *,
        LOG(p2p_to_remittance_value_ratio) AS log_value_ratio
    FROM value_correspondence
    WHERE p2p_to_remittance_value_ratio > 0
    ),
median_deviation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_value_ratio
            ) OVER () AS median_log_value_ratio
    FROM log_value_ratio
    ),
absolute_deviations
AS (
    SELECT
        a.*,
        m.median_log_value_ratio,
        ABS(a.log_value_ratio - m.median_log_value_ratio) AS absolute_deviation
    FROM log_value_ratio AS a
    CROSS JOIN median_deviation AS m
    ),
mad_calculation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_value_difference
    FROM absolute_deviations
    ),
value_correspondence_scores
AS (
    SELECT
        a.*,
        m.mad_value_difference,
        CASE 
            WHEN m.mad_value_difference > 0
                    AND a.log_value_ratio > a.median_log_value_ratio
                THEN (a.log_value_ratio - a.median_log_value_ratio) / m.mad_value_difference
            ELSE 0
            END AS inbound_remittance_to_p2p_value_correspondence_score
    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
    )
SELECT
    *
FROM value_correspondence_scores;
GO

-- 3. Inbound Remittance-to-P2P Recurrence Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_p2p_recurrence_score
AS
WITH inbound_remittances
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp AS sequence_start_timestamp,
        LEAD(r.remittance_timestamp) OVER (
            PARTITION BY r.ocb_customer_id ORDER BY r.remittance_timestamp,
                r.remittance_id
            ) AS sequence_2_start_timestamp
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
    ),
remittance_p2p_sequences
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id              AS sequence_1_remittance_id,
        r.sequence_start_timestamp,
        r.sequence_2_start_timestamp,
        MAX(t.transaction_timestamp) AS sequence_1_endpoint_timestamp,
        COUNT(t.transaction_id)      AS sequence_1_p2p_transfer_count
    FROM inbound_remittances AS r
    INNER JOIN gold.vw_transaction AS t ON
            t.ocb_customer_id = r.ocb_customer_id
                AND t.transaction_type = 'p2p transfer'
                AND t.transaction_timestamp >= r.sequence_start_timestamp
                AND (
                r.sequence_2_start_timestamp IS NULL
                    OR t.transaction_timestamp < r.sequence_2_start_timestamp
                )
    GROUP BY r.ocb_customer_id,
        r.remittance_id,
        r.sequence_start_timestamp,
        r.sequence_2_start_timestamp
    ),
sequence_recurrence
AS (
    SELECT
        ocb_customer_id,
        sequence_1_remittance_id,
        sequence_1_endpoint_timestamp,
        sequence_2_start_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, sequence_1_endpoint_timestamp, sequence_2_start_timestamp) AS DECIMAL(18, 4)) AS recurrence_interval_minutes
    FROM remittance_p2p_sequences
    WHERE sequence_2_start_timestamp IS NOT NULL
    ),
median_deviation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_interval_minutes
            ) OVER () AS median_recurrence_interval_minutes
    FROM sequence_recurrence
    ),
absolute_deviations
AS (
    SELECT
        s.*,
        m.median_recurrence_interval_minutes,
        ABS(s.recurrence_interval_minutes - m.median_recurrence_interval_minutes) AS absolute_deviation
    FROM sequence_recurrence AS s
    CROSS JOIN median_deviation AS m
    ),
mad_calculation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_recurrence_interval_minutes
    FROM absolute_deviations
    ),
recurrence_scores
AS (
    SELECT
        a.ocb_customer_id,
        a.sequence_1_remittance_id,
        a.sequence_1_endpoint_timestamp,
        a.sequence_2_start_timestamp,
        a.recurrence_interval_minutes,
        a.median_recurrence_interval_minutes,
        a.absolute_deviation,
        m.mad_recurrence_interval_minutes,
        CASE 
            WHEN m.mad_recurrence_interval_minutes > 0
                    AND a.recurrence_interval_minutes < a.median_recurrence_interval_minutes
                THEN (a.median_recurrence_interval_minutes - a.recurrence_interval_minutes) / m.mad_recurrence_interval_minutes
            ELSE 0
            END AS inbound_remittance_to_p2p_recurrence_score
    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
    )
SELECT
    ocb_customer_id,
    sequence_1_remittance_id,
    sequence_1_endpoint_timestamp,
    sequence_2_start_timestamp,
    recurrence_interval_minutes,
    median_recurrence_interval_minutes,
    absolute_deviation,
    mad_recurrence_interval_minutes,
    inbound_remittance_to_p2p_recurrence_score
FROM recurrence_scores;
GO

/*
-- WP5.3 Inbound Remittance → P2P Redistribution Intelligence Engine — Process Documentation
-- Inbound Remittance → P2P Redistribution Intelligence identifies P2P transfer activity following inbound remittances received by
    the same OCB customer.
-- The engine comprises three independent signals: Inbound Remittance → P2P Rapidity, Inbound Remittance → P2P Value Correspondence,
    and Inbound Remittance → P2P Recurrence.
-- A complete sequence consists of an inbound remittance received by an OCB customer followed by one or more P2P transfers by that
    same customer.
-- The P2P transfer timestamp must be greater than or equal to the inbound remittance timestamp.
-- Each inbound remittance defines a sequence that ends immediately before the customer's next inbound remittance.
-- Where no subsequent inbound remittance exists, the sequence includes all subsequent P2P transfers available in the dataset.
-- Inbound Remittance → P2P Rapidity measures the interval between inbound remittance receipt and the first subsequent P2P transfer
    in the sequence.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD) of elapsed minutes.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.
-- Inbound Remittance → P2P Value Correspondence measures the total value of P2P transfers within a sequence relative to the
    inbound remittance amount.
-- The P2P-to-remittance ratio is calculated by dividing the total P2P transfer value by the inbound remittance amount.
-- The natural logarithm of the ratio is used for scoring.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate greater P2P transfer value relative to inbound remittance amounts compared with the observed population.
-- The P2P-to-remittance ratio may exceed one because customers may have existing balances, additional inflows, or other available
    funds.
-- Inbound Remittance → P2P Recurrence measures the interval between the completion of one remittance-to-P2P sequence and the
    initiation of the next sequence.
-- Successive sequences are identified using LEAD() within each customer.
-- Sequences are ordered by inbound remittance timestamp and remittance ID.
-- The sequence endpoint is the timestamp of the last P2P transfer associated with the current inbound remittance.
-- The recurrence interval runs from the current sequence's last P2P transfer to the next inbound remittance timestamp.
-- This measures the gap between one sequence's completion and the next sequence's initiation.
-- Sequences without a subsequent inbound remittance are excluded from recurrence calculations.
-- Sequences without a P2P transfer endpoint are also excluded from recurrence calculations.
-- Recurrence scoring uses the population median and MAD of the recurrence intervals.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher recurrence scores relative to the observed population.
-- The three signals measure timing, relative value, and recurrence independently.
-- They are not mathematically combined into a single Inbound Remittance → P2P Redistribution risk score.
-- No universal score thresholds were established.
-- The engine highlights rapid P2P activity after inbound remittance receipt, unusually large P2P transfer values relative to
    inbound remittance amounts, and repeated sequences at short intervals.
-- These patterns may support further financial-behaviour and transaction-risk investigation.
-- The engine provides cross-institutional intelligence on behavioural relationships between inbound remittance activity and
    subsequent P2P redistribution.
*/
-- Combined signals
WITH combined_signal_scores
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.inbound_remittance_timestamp,
        r.first_p2p_transfer_timestamp,
        r.elapsed_minutes,
        r.inbound_remittance_to_p2p_rapidity_score,
        v.inbound_remittance_amount,
        v.p2p_to_remittance_value_ratio,
        v.inbound_remittance_to_p2p_value_correspondence_score,
        c.recurrence_interval_minutes,
        c.inbound_remittance_to_p2p_recurrence_score
    FROM intelligence.vw_remittance_p2p_rapidity_score AS r
    LEFT JOIN intelligence.vw_remittance_p2p_value_correspondence_score AS v ON
            r.ocb_customer_id = v.ocb_customer_id
                AND r.remittance_id = v.remittance_id
    LEFT JOIN intelligence.vw_remittance_p2p_recurrence_score AS c ON
            r.ocb_customer_id = c.ocb_customer_id
                AND r.remittance_id = c.sequence_1_remittance_id
    )
SELECT
    *
FROM combined_signal_scores;
GO

-- Inbound Remittance-to-Loan Repayment 
-- 1. Inbound Remittance-to-Loan Repayment Rapidity Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_repayment_rapidity_score
AS
WITH inbound_remittances
AS (
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount    AS inbound_remittance_amount,
        LEAD(rm.remittance_timestamp) OVER (
            PARTITION BY rm.ocb_customer_id ORDER BY rm.remittance_timestamp,
                rm.remittance_id
            ) AS next_remittance_timestamp
    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
    ),
repayment_sequences
AS (
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.inbound_remittance_timestamp,
        rm.inbound_remittance_amount,
        rm.next_remittance_timestamp,
        rp.loan_id,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        ROW_NUMBER() OVER (
            PARTITION BY rm.ocb_customer_id,
            rm.remittance_id ORDER BY rp.repayment_timestamp,
                rp.repayment_id
            ) AS repayment_sequence_number
    FROM inbound_remittances AS rm
    INNER JOIN gold.vw_repayment AS rp ON
            rm.ocb_customer_id = rp.ocb_customer_id
                AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
                AND (
                rp.repayment_timestamp < rm.next_remittance_timestamp
                    OR rm.next_remittance_timestamp IS NULL
                )
    ),
first_repayments
AS (
    SELECT
        *,
        CAST(DATEDIFF_BIG(MILLISECOND, inbound_remittance_timestamp, repayment_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS remittance_repayment_delay_minutes
    FROM repayment_sequences
    WHERE repayment_sequence_number = 1
    ),
rapidity_statistics
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY remittance_repayment_delay_minutes
            ) OVER () AS median_delay_minutes
    FROM first_repayments
    ),
rapidity_mad
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY ABS(fr.remittance_repayment_delay_minutes - rs.median_delay_minutes)
            ) OVER () AS mad_delay_minutes
    FROM first_repayments AS fr
    CROSS JOIN rapidity_statistics AS rs
    )
SELECT
    fr.ocb_customer_id,
    fr.remittance_id,
    fr.inbound_remittance_timestamp,
    fr.inbound_remittance_amount,
    fr.next_remittance_timestamp,
    fr.loan_id,
    fr.repayment_id,
    fr.repayment_timestamp,
    fr.repayment_amount,
    fr.remittance_repayment_delay_minutes,
    rs.median_delay_minutes,
    rm.mad_delay_minutes,
    CASE 
        WHEN rm.mad_delay_minutes > 0
                AND fr.remittance_repayment_delay_minutes < rs.median_delay_minutes
            THEN (rs.median_delay_minutes - fr.remittance_repayment_delay_minutes) / rm.mad_delay_minutes
        ELSE 0
        END AS remittance_repayment_rapidity_score
FROM first_repayments AS fr
CROSS JOIN rapidity_statistics AS rs
CROSS JOIN rapidity_mad AS rm;
GO

-- 2. Inbound Remittance-to-Repayment Value Correspondence Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_repayment_value_correspondence_score
AS
WITH inbound_remittances
AS (
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount    AS inbound_remittance_amount,
        LEAD(rm.remittance_timestamp) OVER (
            PARTITION BY rm.ocb_customer_id ORDER BY rm.remittance_timestamp,
                rm.remittance_id
            ) AS next_remittance_timestamp
    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
    ),
remittance_repayment_profile
AS (
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.inbound_remittance_timestamp,
        rm.inbound_remittance_amount,
        rm.next_remittance_timestamp,
        rp.repayment_id,
        rp.repayment_amount
    FROM inbound_remittances AS rm
    INNER JOIN gold.vw_repayment AS rp ON
            rm.ocb_customer_id = rp.ocb_customer_id
                AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
                AND (
                rm.next_remittance_timestamp IS NULL
                    OR rp.repayment_timestamp < rm.next_remittance_timestamp
                )
    ),
repayment_sequence_totals
AS (
    SELECT
        ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount,
        next_remittance_timestamp,
        COUNT(repayment_id)   AS qualifying_repayment_count,
        SUM(repayment_amount) AS total_qualifying_repayment_amount
    FROM remittance_repayment_profile
    GROUP BY ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount,
        next_remittance_timestamp
    ),
value_correspondence
AS (
    SELECT
        *,
        total_qualifying_repayment_amount / NULLIF(inbound_remittance_amount, 0) AS repayment_correspondence_ratio
    FROM repayment_sequence_totals
    ),
log_value_ratio
AS (
    SELECT
        *,
        LOG(repayment_correspondence_ratio) AS log_value_ratio
    FROM value_correspondence
    WHERE repayment_correspondence_ratio > 0
    ),
median_deviation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY log_value_ratio
            ) OVER () AS median_log_value_ratio
    FROM log_value_ratio
    ),
absolute_deviations
AS (
    SELECT
        a.*,
        m.median_log_value_ratio,
        ABS(a.log_value_ratio - m.median_log_value_ratio) AS absolute_deviation
    FROM log_value_ratio AS a
    CROSS JOIN median_deviation AS m
    ),
mad_calculation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_value_difference
    FROM absolute_deviations
    ),
value_correspondence_scores
AS (
    SELECT
        a.*,
        m.mad_value_difference,
        CASE 
            WHEN m.mad_value_difference > 0
                    AND a.log_value_ratio > a.median_log_value_ratio
                THEN (a.log_value_ratio - a.median_log_value_ratio) / m.mad_value_difference
            ELSE 0
            END AS remittance_repayment_value_correspondence_score
    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
    )
SELECT
    *
FROM value_correspondence_scores;
GO

-- 3. Inbound Remittance-to-repayment Recurrence Score
CREATE
        OR

ALTER VIEW intelligence.vw_remittance_repayment_recurrence_score
AS
WITH inbound_remittances
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp AS sequence_start_timestamp,
        LEAD(r.remittance_timestamp) OVER (
            PARTITION BY r.ocb_customer_id ORDER BY r.remittance_timestamp,
                r.remittance_id
            ) AS sequence_2_start_timestamp
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
    ),
remittance_repayment_sequences
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id             AS sequence_1_remittance_id,
        r.sequence_start_timestamp,
        r.sequence_2_start_timestamp,
        MAX(rp.repayment_timestamp) AS sequence_1_endpoint_timestamp,
        COUNT(rp.repayment_id)      AS sequence_1_repayment_count
    FROM inbound_remittances AS r
    INNER JOIN gold.vw_repayment AS rp ON
            rp.ocb_customer_id = r.ocb_customer_id
                AND rp.repayment_timestamp >= r.sequence_start_timestamp
                AND (
                r.sequence_2_start_timestamp IS NULL
                    OR rp.repayment_timestamp < r.sequence_2_start_timestamp
                )
    GROUP BY r.ocb_customer_id,
        r.remittance_id,
        r.sequence_start_timestamp,
        r.sequence_2_start_timestamp
    ),
sequence_recurrence
AS (
    SELECT
        ocb_customer_id,
        sequence_1_remittance_id,
        sequence_1_endpoint_timestamp,
        sequence_2_start_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, sequence_1_endpoint_timestamp, sequence_2_start_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS recurrence_interval_minutes
    FROM remittance_repayment_sequences
    WHERE sequence_2_start_timestamp IS NOT NULL
    ),
median_deviation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY recurrence_interval_minutes
            ) OVER () AS median_recurrence_interval_minutes
    FROM sequence_recurrence
    ),
absolute_deviations
AS (
    SELECT
        s.*,
        m.median_recurrence_interval_minutes,
        ABS(s.recurrence_interval_minutes - m.median_recurrence_interval_minutes) AS absolute_deviation
    FROM sequence_recurrence AS s
    CROSS JOIN median_deviation AS m
    ),
mad_calculation
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS mad_recurrence_interval_minutes
    FROM absolute_deviations
    ),
recurrence_scores
AS (
    SELECT
        a.ocb_customer_id,
        a.sequence_1_remittance_id,
        a.sequence_1_endpoint_timestamp,
        a.sequence_2_start_timestamp,
        a.recurrence_interval_minutes,
        a.median_recurrence_interval_minutes,
        a.absolute_deviation,
        m.mad_recurrence_interval_minutes,
        CASE 
            WHEN m.mad_recurrence_interval_minutes > 0
                    AND a.recurrence_interval_minutes < a.median_recurrence_interval_minutes
                THEN (a.median_recurrence_interval_minutes - a.recurrence_interval_minutes) / m.mad_recurrence_interval_minutes
            ELSE 0
            END AS inbound_remittance_to_repayment_recurrence_score
    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
    )
SELECT
    ocb_customer_id,
    sequence_1_remittance_id,
    sequence_1_endpoint_timestamp,
    sequence_2_start_timestamp,
    recurrence_interval_minutes,
    median_recurrence_interval_minutes,
    absolute_deviation,
    mad_recurrence_interval_minutes,
    inbound_remittance_to_repayment_recurrence_score
FROM recurrence_scores;
GO

/*
-- WP5.3 Inbound Remittance → Loan Repayment Intelligence Engine — Process Documentation
-- Inbound Remittance → Loan Repayment Intelligence identifies loan repayment activity following inbound remittances received by
    the same OCB customer.
-- The engine comprises three independent signals: Inbound Remittance → Loan Repayment Rapidity, Inbound Remittance → Loan
    Repayment Value Correspondence, and Inbound Remittance → Loan Repayment Recurrence.
-- A complete sequence consists of an inbound remittance received by an OCB customer followed by one or more loan repayments by
    that same customer.
-- The loan repayment timestamp must be greater than or equal to the inbound remittance timestamp.
-- Each inbound remittance defines a sequence that ends immediately before the customer's next inbound remittance.
-- Where no subsequent inbound remittance exists, the sequence includes all subsequent loan repayments available in the dataset.
-- Inbound Remittance → Loan Repayment Rapidity measures the interval between inbound remittance receipt and the first subsequent
    loan repayment in the sequence.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD) of elapsed minutes.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.
-- Inbound Remittance → Loan Repayment Value Correspondence measures the total value of loan repayments within a sequence
    relative to the inbound remittance amount.
-- The loan-repayment-to-remittance ratio is calculated by dividing the total qualifying loan repayment value by the inbound
    remittance amount.
-- The natural logarithm of the ratio is used for scoring.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate greater loan repayment value relative to inbound remittance amounts compared with the observed
    population.
-- The loan-repayment-to-remittance ratio may exceed one because customers may have existing balances, additional inflows, or
    other available funds.
-- The ratio measures value correspondence within the defined sequence and does not establish that the inbound remittance
    directly funded the loan repayments.
-- Inbound Remittance → Loan Repayment Recurrence measures the interval between the completion of one remittance-to-repayment
    sequence and the initiation of the next sequence.
-- Successive sequences are identified using LEAD() within each customer.
-- Sequences are ordered by inbound remittance timestamp and remittance ID.
-- The sequence endpoint is the timestamp of the last loan repayment associated with the current inbound remittance.
-- The recurrence interval runs from the current sequence's last loan repayment to the next inbound remittance timestamp.
-- This measures the gap between one sequence's completion and the next sequence's initiation.
-- Sequences without a subsequent inbound remittance are excluded from recurrence calculations.
-- Sequences without a loan repayment endpoint are also excluded from recurrence calculations.
-- Recurrence scoring uses the population median and MAD of the recurrence intervals.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher recurrence scores relative to the observed population.
-- The three signals measure timing, relative value, and recurrence independently.
-- They are not mathematically combined into a single Inbound Remittance → Loan Repayment risk score.
-- No universal score thresholds were established.
-- The engine highlights rapid loan repayment following inbound remittance receipt, unusually large loan repayment values relative
    to inbound remittance amounts, and repeated sequences at short intervals.
-- These patterns may support further financial-behaviour and transaction-risk investigation.
-- The engine provides cross-institutional intelligence on behavioural relationships between inbound remittance activity and
    subsequent loan repayment activity.
*/
-- Combined signals
-- Combined signals
WITH combined_signal_scores
AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_repayment_delay_minutes,
        r.remittance_repayment_rapidity_score,
        v.repayment_correspondence_ratio,
        v.remittance_repayment_value_correspondence_score,
        c.recurrence_interval_minutes,
        c.inbound_remittance_to_repayment_recurrence_score
    FROM intelligence.vw_remittance_repayment_rapidity_score AS r
    LEFT JOIN intelligence.vw_remittance_repayment_value_correspondence_score AS v ON
            r.ocb_customer_id = v.ocb_customer_id
                AND r.remittance_id = v.remittance_id
    LEFT JOIN intelligence.vw_remittance_repayment_recurrence_score AS c ON
            r.ocb_customer_id = c.ocb_customer_id
                AND r.remittance_id = c.sequence_1_remittance_id
    )
SELECT
    *
FROM combined_signal_scores;
GO



