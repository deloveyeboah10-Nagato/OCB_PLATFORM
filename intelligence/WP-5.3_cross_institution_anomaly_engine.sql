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
            AND t.transaction_status = 'successful'
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
                AND r.remittance_status = 'successful'
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
CREATE OR ALTER VIEW intelligence.vw_cashin_remittance_value_correspondence_score
AS
WITH cashin_sequences AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_id        AS cash_in_id,
        t.transaction_timestamp AS cash_in_timestamp,
        t.transaction_amount    AS cash_in_amount,
        LEAD(t.transaction_timestamp) OVER (
            PARTITION BY t.ocb_customer_id
            ORDER BY t.transaction_timestamp, t.transaction_id
        ) AS next_cash_in_timestamp
    FROM gold.vw_transaction AS t
    WHERE t.transaction_type = 'cash in'
      AND t.transaction_status = 'successful'
),
cashin_remittance_profile AS (
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
    INNER JOIN gold.vw_remittance AS r
        ON r.ocb_customer_id = c.ocb_customer_id
       AND r.remittance_type = 'remittance_sent'
       AND r.remittance_status = 'successful'
       AND r.remittance_timestamp >= c.cash_in_timestamp
       AND (
            c.next_cash_in_timestamp IS NULL
            OR r.remittance_timestamp < c.next_cash_in_timestamp
       )
),
value_correspondence AS (
    SELECT
        *,
        remittance_amount_sent
            / NULLIF(cash_in_amount, 0) AS funding_remittance_ratio
    FROM cashin_remittance_profile
),
log_value_ratio AS (
    SELECT
        *,
        LOG(funding_remittance_ratio) AS log_funding_remittance_ratio
    FROM value_correspondence
    WHERE funding_remittance_ratio > 0
),
median_stage AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY log_funding_remittance_ratio
        ) OVER () AS median_log_ratio
    FROM log_value_ratio
),
mad_stage AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY ABS(
                l.log_funding_remittance_ratio - m.median_log_ratio
            )
        ) OVER () AS mad_log_ratio
    FROM log_value_ratio AS l
    CROSS JOIN median_stage AS m
),
value_correspondence_scores AS (
    SELECT
        l.*,
        m.median_log_ratio,
        d.mad_log_ratio,
        CASE
            WHEN d.mad_log_ratio > 0
             AND l.log_funding_remittance_ratio > m.median_log_ratio
            THEN (
                l.log_funding_remittance_ratio - m.median_log_ratio
            ) / d.mad_log_ratio
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
    remittance_id,
    remittance_timestamp,
    remittance_amount_sent,
    funding_remittance_ratio,
    log_funding_remittance_ratio,
    median_log_ratio,
    mad_log_ratio,
    funding_remittance_value_correspondence_score
FROM value_correspondence_scores;
GO

-- 3. Recurrent Funding-to-Remittance Behaviour
CREATE OR ALTER VIEW intelligence.vw_cashin_remittance_recurrence_score
AS
WITH cashin_sequences AS (
    SELECT
        t.ocb_customer_id,
        t.transaction_id        AS cash_in_id,
        t.transaction_timestamp AS cash_in_timestamp,
        t.transaction_amount    AS cash_in_amount,
        LEAD(t.transaction_timestamp) OVER (
            PARTITION BY t.ocb_customer_id
            ORDER BY t.transaction_timestamp, t.transaction_id
        ) AS next_cash_in_timestamp,
        LEAD(t.transaction_id) OVER (
            PARTITION BY t.ocb_customer_id
            ORDER BY t.transaction_timestamp, t.transaction_id
        ) AS next_cash_in_id
    FROM gold.vw_transaction AS t
    WHERE t.transaction_type = 'cash in'
      AND t.transaction_status = 'successful'
),
remittance_sequences AS (
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        LEAD(r.remittance_timestamp) OVER (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_timestamp,
        LEAD(r.remittance_id) OVER (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_id,
        LEAD(r.remittance_amount) OVER (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_amount
    FROM gold.vw_remittance AS r
    WHERE r.remittance_status = 'successful'
      AND r.remittance_type = 'remittance_sent'
),
recurrence_population AS (
    SELECT
        c.ocb_customer_id,
        c.cash_in_id,
        c.cash_in_timestamp,
        c.cash_in_amount,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        c.next_cash_in_id,
        c.next_cash_in_timestamp,
        r.next_remittance_id,
        r.next_remittance_timestamp,
        r.next_remittance_amount,
        CAST(
            DATEDIFF_BIG(
                MILLISECOND,
                r.remittance_timestamp,
                r.next_remittance_timestamp
            ) / 60000.0 AS DECIMAL(18, 4)
        ) AS recurrence_gap_minutes
    FROM cashin_sequences AS c
    INNER JOIN remittance_sequences AS r
        ON r.ocb_customer_id = c.ocb_customer_id
       AND r.remittance_timestamp >= c.cash_in_timestamp
       AND (
            c.next_cash_in_timestamp IS NULL
            OR r.remittance_timestamp < c.next_cash_in_timestamp
       )
    INNER JOIN cashin_sequences AS c2
        ON c2.ocb_customer_id = c.ocb_customer_id
       AND c2.cash_in_id = c.next_cash_in_id
       AND c2.cash_in_timestamp < r.next_remittance_timestamp
       AND (
            c2.next_cash_in_timestamp IS NULL
            OR r.next_remittance_timestamp < c2.next_cash_in_timestamp
       )
    WHERE r.next_remittance_timestamp IS NOT NULL
),
median_stage AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY recurrence_gap_minutes
        ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
),
mad_stage AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (
            ORDER BY ABS(
                rp.recurrence_gap_minutes
                    - m.median_recurrence_gap_minutes
            )
        ) OVER () AS mad_recurrence_gap_minutes
    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
),
recurrence_scores AS (
    SELECT
        rp.*,
        m.median_recurrence_gap_minutes,
        d.mad_recurrence_gap_minutes,
        CASE
            WHEN d.mad_recurrence_gap_minutes > 0
             AND rp.recurrence_gap_minutes
                    < m.median_recurrence_gap_minutes
            THEN (
                m.median_recurrence_gap_minutes
                    - rp.recurrence_gap_minutes
            ) / d.mad_recurrence_gap_minutes
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
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    next_cash_in_id,
    next_cash_in_timestamp,
    next_remittance_id,
    next_remittance_timestamp,
    next_remittance_amount,
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
-- Each successful Cash In transaction defines the start of a sequence for the corresponding
-- OCB customer. Sequences are ordered chronologically by cash-in timestamp and transaction ID.
-- Each sequence ends immediately before the next successful Cash In transaction for the same
-- customer. The final sequence extends to the end of the available data.
-- A qualifying Remittance Sent event must be successful and occur at or after the sequence's
-- cash-in timestamp and before the next cash-in timestamp, where a subsequent cash-in exists.
-- Remittance events are assigned to sequences according to these temporal boundaries.
-- A sequence may contain multiple outbound remittance events.
-- Sequences without a qualifying Remittance Sent event are excluded from the signal populations.
-- Temporal sequence membership establishes a behavioural association between cash-in and
-- remittance events but does not prove direct funding or causation.
-- Funding → Remittance Rapidity measures the elapsed time between a Cash In transaction and
-- the first successful Remittance Sent event within its sequence.
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
-- Funding → Remittance Value Correspondence evaluates the relationship between an individual
-- cash-in amount and each qualifying outbound remittance amount observed within its sequence.
-- Each qualifying remittance is retained as an individual cash-in/remittance event pair.
-- Remittance amounts are not aggregated into a sequence-level total.
-- The funding-to-remittance value ratio is calculated by dividing the individual remittance
-- amount by the associated cash-in amount.
-- Event pairs with a zero cash-in amount or a non-positive value ratio are excluded from the
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
-- The score therefore increases as an individual outbound remittance amount becomes larger
-- relative to its associated cash-in amount compared with the observed population.
-- The ratio is not capped at one because an individual remittance amount may exceed the amount
-- of the associated cash-in.
-- A ratio above one does not establish that the cash-in directly funded the excess remittance
-- value, since customers may have had pre-existing balances or other sources of funds.
-- Funding → Remittance Recurrence measures the interval between two consecutive successful
-- outbound remittance events associated with successive cash-in sequences for the same customer.
-- The current remittance is associated with a cash-in sequence and the next successful
-- remittance is identified using LEAD() over the customer's chronologically ordered remittances.
-- The recurrence pattern requires the following event order:
-- Cash In 1 → Remittance 1 → Cash In 2 → Remittance 2.
-- Remittance 1 must occur at or after Cash In 1 and before Cash In 2.
-- Cash In 2 must occur before Remittance 2.
-- Where a subsequent Cash In 3 exists, Remittance 2 must occur before Cash In 3.
-- These conditions establish two successive cash-in/remittance cycles for the recurrence
-- population rather than treating any two consecutive remittances as sufficient evidence.
-- The recurrence interval is measured in minutes from Remittance 1 to Remittance 2.
-- The population median of the recurrence intervals establishes the reference level for typical
-- intervals between remittances across qualifying successive funding-to-remittance cycles.
-- The Median Absolute Deviation (MAD) measures the dispersion of recurrence intervals around
-- the population median.
-- Recurrence intervals shorter than the population median receive positive recurrence scores
-- where the population MAD is greater than zero.
-- The score is calculated as the difference between the population median and the observed
-- recurrence interval, divided by the population MAD.
-- Recurrence intervals at or above the population median receive zero scores.
-- Where the population MAD is zero, the recurrence score is zero.
-- The recurrence score therefore increases as the interval between Remittance 1 and Remittance 2
-- becomes shorter relative to the observed population.
-- Rapidity measures the timing of the first outbound remittance following a cash-in.
-- Value Correspondence measures each outbound remittance amount relative to its associated cash-in.
-- Recurrence measures the interval between consecutive remittances within successive
-- cash-in/remittance cycles.
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
-- remittance activity, particularly where the observed timing or individual remittance values
-- are unusual relative to the population.
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

    -- Funding-to-Remittance Rapidity
    r.funding_remittance_rapidity_score,

    -- Funding-to-Remittance Value Correspondence
    v.funding_remittance_value_correspondence_score,

    -- Recurrent Funding-to-Remittance Behaviour
    s.funding_remittance_recurrence_score

FROM intelligence.vw_cashin_remittance_rapidity_score AS r

LEFT JOIN intelligence.vw_cashin_remittance_value_correspondence_score AS v
    ON v.ocb_customer_id = r.ocb_customer_id
   AND v.cash_in_id = r.cash_in_id
   AND v.remittance_id = r.first_remittance_id

LEFT JOIN intelligence.vw_cashin_remittance_recurrence_score AS s
    ON s.ocb_customer_id = r.ocb_customer_id
   AND s.cash_in_id = r.cash_in_id
   AND s.remittance_id = r.first_remittance_id;
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
                AND r.remittance_status = 'successful'
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

-- 2. Credit-to-Remittance Value Correspondence Score
CREATE OR ALTER VIEW intelligence.vw_credit_to_remittance_value_correspondence_score
AS
WITH loan_sequences AS
(
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp AS loan_timestamp,
        l.principal_amount,

        LEAD(l.disbursement_timestamp) OVER
        (
            PARTITION BY l.ocb_customer_id
            ORDER BY l.disbursement_timestamp, l.loan_id
        ) AS next_loan_timestamp

    FROM gold.vw_loan AS l
),
loan_remittance_profile AS
(
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.loan_timestamp,
        l.principal_amount,
        l.next_loan_timestamp,

        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount AS remittance_amount_sent

    FROM loan_sequences AS l

    INNER JOIN gold.vw_remittance AS r
        ON r.ocb_customer_id = l.ocb_customer_id
       AND r.remittance_type = 'remittance_sent'
       AND r.remittance_status = 'successful'
       AND r.remittance_timestamp >= l.loan_timestamp
       AND (
            l.next_loan_timestamp IS NULL
            OR r.remittance_timestamp < l.next_loan_timestamp
       )
),
value_correspondence AS
(
    SELECT
        ocb_customer_id,
        loan_id,
        loan_timestamp,
        principal_amount,
        next_loan_timestamp,
        remittance_id,
        remittance_timestamp,
        remittance_amount_sent,

        remittance_amount_sent
            / NULLIF(principal_amount, 0) AS remittance_to_loan_ratio

    FROM loan_remittance_profile
    WHERE principal_amount > 0
      AND remittance_amount_sent > 0
),
log_value_ratio AS
(
    SELECT
        *,
        LOG(remittance_to_loan_ratio) AS log_remittance_to_loan_ratio

    FROM value_correspondence
    WHERE remittance_to_loan_ratio > 0
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY log_remittance_to_loan_ratio
        ) OVER () AS median_log_ratio

    FROM log_value_ratio
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS(
                l.log_remittance_to_loan_ratio - m.median_log_ratio
            )
        ) OVER () AS mad_log_ratio

    FROM log_value_ratio AS l
    CROSS JOIN median_stage AS m
),
value_correspondence_scores AS
(
    SELECT
        l.*,
        m.median_log_ratio,
        d.mad_log_ratio,

        CASE
            WHEN d.mad_log_ratio > 0
             AND l.log_remittance_to_loan_ratio > m.median_log_ratio
            THEN (
                l.log_remittance_to_loan_ratio - m.median_log_ratio
            ) / d.mad_log_ratio
            ELSE 0
        END AS credit_to_remittance_value_correspondence_score

    FROM log_value_ratio AS l
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    loan_id,
    loan_timestamp,
    principal_amount,
    next_loan_timestamp,
    remittance_id,
    remittance_timestamp,
    remittance_amount_sent,
    remittance_to_loan_ratio,
    log_remittance_to_loan_ratio,
    median_log_ratio,
    mad_log_ratio,
    credit_to_remittance_value_correspondence_score

FROM value_correspondence_scores;
GO

-- 3. Credit-to-Remittance Recurrence Score
CREATE OR ALTER VIEW intelligence.vw_credit_to_remittance_recurrence_score
AS
WITH loan_sequences AS
(
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp AS loan_timestamp,
        l.principal_amount,

        LEAD(l.loan_id) OVER
        (
            PARTITION BY l.ocb_customer_id
            ORDER BY l.disbursement_timestamp, l.loan_id
        ) AS next_loan_id,

        LEAD(l.disbursement_timestamp) OVER
        (
            PARTITION BY l.ocb_customer_id
            ORDER BY l.disbursement_timestamp, l.loan_id
        ) AS next_loan_timestamp

    FROM gold.vw_loan AS l
),
remittance_sequences AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,

        LEAD(r.remittance_id) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_id,

        LEAD(r.remittance_timestamp) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_timestamp

    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_sent'
      AND r.remittance_status = 'successful'
),
loan_remittance_sequences AS
(
    SELECT
        l1.ocb_customer_id,

        l1.loan_id,
        l1.loan_timestamp,
        l1.principal_amount,

        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,

        l2.loan_id AS next_loan_id,
        l2.loan_timestamp AS next_loan_timestamp,

        r.next_remittance_id,
        r.next_remittance_timestamp

    FROM loan_sequences AS l1

    INNER JOIN remittance_sequences AS r
        ON r.ocb_customer_id = l1.ocb_customer_id
       AND r.remittance_timestamp >= l1.loan_timestamp
       AND r.remittance_timestamp < l1.next_loan_timestamp

    INNER JOIN loan_sequences AS l2
        ON l2.ocb_customer_id = l1.ocb_customer_id
       AND l2.loan_id = l1.next_loan_id
       AND r.next_remittance_timestamp > l2.loan_timestamp
       AND (
            l2.next_loan_timestamp IS NULL
            OR r.next_remittance_timestamp < l2.next_loan_timestamp
       )

    WHERE l1.next_loan_timestamp IS NOT NULL
      AND r.next_remittance_timestamp IS NOT NULL
),
recurrence_population AS
(
    SELECT
        *,
        CAST(
            DATEDIFF_BIG(
                MILLISECOND,
                remittance_timestamp,
                next_remittance_timestamp
            ) / 60000.0
            AS DECIMAL(18, 4)
        ) AS credit_to_remittance_recurrence_minutes

    FROM loan_remittance_sequences
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY credit_to_remittance_recurrence_minutes
        ) OVER () AS median_recurrence_minutes

    FROM recurrence_population
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS(
                rp.credit_to_remittance_recurrence_minutes
                - m.median_recurrence_minutes
            )
        ) OVER () AS mad_recurrence_minutes

    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
),
recurrence_scores AS
(
    SELECT
        rp.*,
        m.median_recurrence_minutes,
        d.mad_recurrence_minutes,

        CASE
            WHEN d.mad_recurrence_minutes > 0
             AND rp.credit_to_remittance_recurrence_minutes
                 < m.median_recurrence_minutes
            THEN (
                m.median_recurrence_minutes
                - rp.credit_to_remittance_recurrence_minutes
            ) / d.mad_recurrence_minutes
            ELSE 0
        END AS credit_to_remittance_recurrence_score

    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    loan_id,
    loan_timestamp,
    principal_amount,
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    next_loan_id,
    next_loan_timestamp,
    next_remittance_id,
    next_remittance_timestamp,
    credit_to_remittance_recurrence_minutes,
    median_recurrence_minutes,
    mad_recurrence_minutes,
    credit_to_remittance_recurrence_score

FROM recurrence_scores;
GO

/*
-- WP5.3 Credit → Remittance Intelligence Engine — Process Documentation
-- Credit → Remittance Intelligence identifies Loan Disbursement → Remittance Sent sequences within the same OCB customer.
-- The engine comprises three independent signals: Credit → Remittance Rapidity, Credit → Remittance Value Correspondence, and
    Credit → Remittance Recurrence.
-- A complete sequence consists of a SikaCredit loan disbursement followed by a successful Oman Remit outbound remittance for the same OCB
    customer.
-- The remittance timestamp must be greater than or equal to the loan disbursement timestamp.
-- Credit → Remittance Rapidity identifies the earliest subsequent successful outbound remittance for each loan, ordered by remittance
    timestamp and remittance ID.
-- Where multiple loans match the same remittance, the latest loan is retained, ordered by disbursement timestamp and loan ID.
-- This produces a deduplicated population of matched loan–remittance sequences for rapidity scoring.
-- Credit → Remittance Rapidity measures the interval between loan disbursement and matched remittance.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD).
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.
-- Credit → Remittance Value Correspondence measures each individual remittance amount relative to the associated loan principal.
-- The remittance-to-loan ratio is calculated by dividing the individual remittance amount by the loan principal.
-- The natural logarithm of the ratio is used for scoring.
-- Loan disbursements are ordered by timestamp and loan ID using LEAD() to identify the next loan disbursement timestamp.
-- Each loan is associated with every successful outbound remittance occurring at or after its disbursement and before the next loan
    disbursement, where a subsequent loan exists.
-- Where no subsequent loan exists, qualifying remittances are retained through the available remittance history.
-- Value correspondence therefore retains individual loan–remittance event pairs rather than selecting only the first remittance or
    aggregating remittance amounts within a loan window.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate larger individual remittances relative to loan principals compared with the observed population.
-- Credit → Remittance Recurrence measures the interval between successive successful outbound remittances within a qualifying
    loan-disbursement sequence.
-- Successive outbound remittances are identified using LEAD() within each customer, ordered by remittance timestamp and remittance ID.
-- The recurrence pattern consists of Loan 1 → Remittance 1 → Loan 2 → Remittance 2.
-- Remittance 1 must occur within Loan 1's disbursement window.
-- Remittance 2 must occur after Loan 2's disbursement and before Loan 3's disbursement, where a subsequent loan exists.
-- The recurrence interval runs from Remittance 1 to Remittance 2.
-- This measures the interval between successive remittances across the qualifying loan-disbursement sequence.
-- Recurrence scoring uses the population median and MAD of the recurrence intervals.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher recurrence scores relative to the observed population.
-- The three signals measure timing, relative value, and recurrence independently.
-- They are not mathematically combined into a single Credit → Remittance risk score.
-- No universal score thresholds were established.
-- Score distributions and bands were used to validate each scoring mechanism.
-- The engine highlights rapid remittance after borrowing, unusually large individual remittances relative to loan principals, and repeated
    remittance activity across successive loan-disbursement sequences at short intervals.
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

    -- Credit-to-Remittance Rapidity
    r.loan_remittance_minutes,
    r.credit_to_remittance_rapidity_score,

    -- Credit-to-Remittance Value Correspondence
    v.remittance_to_loan_ratio,
    v.log_remittance_to_loan_ratio,
    v.credit_to_remittance_value_correspondence_score,

    -- Credit-to-Remittance Recurrence
    s.next_loan_id,
    s.credit_to_remittance_recurrence_minutes,
    s.credit_to_remittance_recurrence_score

FROM intelligence.vw_credit_to_remittance_rapidity_score AS r

LEFT JOIN intelligence.vw_credit_to_remittance_value_correspondence_score AS v
    ON v.ocb_customer_id = r.ocb_customer_id
   AND v.loan_id = r.loan_id
   AND v.remittance_id = r.remittance_id

LEFT JOIN intelligence.vw_credit_to_remittance_recurrence_score AS s
    ON s.ocb_customer_id = r.ocb_customer_id
   AND s.loan_id = r.loan_id
   AND s.remittance_id = r.remittance_id;
GO


-- Inbound Remittance-to-Loan Repayment
-- 1. Inbound Remittance-to-Loan Repayment Rapidity Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_rapidity_score
AS
WITH inbound_remittances AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount AS inbound_remittance_amount,

        LEAD(rm.remittance_timestamp) OVER
        (
            PARTITION BY rm.ocb_customer_id
            ORDER BY rm.remittance_timestamp, rm.remittance_id
        ) AS next_remittance_timestamp

    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
      AND rm.remittance_status = 'successful'
),
repayment_sequences AS
(
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

        ROW_NUMBER() OVER
        (
            PARTITION BY rm.ocb_customer_id, rm.remittance_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS repayment_sequence_number

    FROM inbound_remittances AS rm

    INNER JOIN gold.vw_repayment AS rp
        ON rp.ocb_customer_id = rm.ocb_customer_id
       AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
       AND (
            rm.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < rm.next_remittance_timestamp
       )
),
first_repayments AS
(
    SELECT
        ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount,
        next_remittance_timestamp,
        loan_id,
        repayment_id,
        repayment_timestamp,
        repayment_amount,

        CAST(
            DATEDIFF_BIG(
                MILLISECOND,
                inbound_remittance_timestamp,
                repayment_timestamp
            ) / 60000.0
            AS DECIMAL(18, 4)
        ) AS remittance_repayment_delay_minutes

    FROM repayment_sequences
    WHERE repayment_sequence_number = 1
),
rapidity_statistics AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY remittance_repayment_delay_minutes
        ) OVER () AS median_delay_minutes

    FROM first_repayments
),
rapidity_mad AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS(
                fr.remittance_repayment_delay_minutes
                - rs.median_delay_minutes
            )
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
        THEN
            (rs.median_delay_minutes - fr.remittance_repayment_delay_minutes)
            / rm.mad_delay_minutes
        ELSE 0
    END AS remittance_repayment_rapidity_score

FROM first_repayments AS fr
CROSS JOIN rapidity_statistics AS rs
CROSS JOIN rapidity_mad AS rm;
GO


-- 2. Inbound Remittance-to-Repayment Value Correspondence Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_value_correspondence_score
AS
WITH inbound_remittances AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount AS inbound_remittance_amount,

        LEAD(rm.remittance_timestamp) OVER
        (
            PARTITION BY rm.ocb_customer_id
            ORDER BY rm.remittance_timestamp, rm.remittance_id
        ) AS next_remittance_timestamp

    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
      AND rm.remittance_status = 'successful'
),
remittance_repayment_profile AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.inbound_remittance_timestamp,
        rm.inbound_remittance_amount,
        rm.next_remittance_timestamp,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount

    FROM inbound_remittances AS rm

    INNER JOIN gold.vw_repayment AS rp
        ON rp.ocb_customer_id = rm.ocb_customer_id
       AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
       AND (
            rm.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < rm.next_remittance_timestamp
       )
),
value_correspondence AS
(
    SELECT
        ocb_customer_id,
        remittance_id,
        inbound_remittance_timestamp,
        inbound_remittance_amount,
        next_remittance_timestamp,
        repayment_id,
        repayment_timestamp,
        repayment_amount,

        repayment_amount
            / NULLIF(inbound_remittance_amount, 0)
            AS repayment_correspondence_ratio

    FROM remittance_repayment_profile
    WHERE inbound_remittance_amount > 0
      AND repayment_amount > 0
),
log_value_ratio AS
(
    SELECT
        *,
        LOG(repayment_correspondence_ratio) AS log_value_ratio

    FROM value_correspondence
    WHERE repayment_correspondence_ratio > 0
),
median_deviation AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY log_value_ratio
        ) OVER () AS median_log_value_ratio

    FROM log_value_ratio
),
absolute_deviations AS
(
    SELECT
        a.*,
        m.median_log_value_ratio,
        ABS(a.log_value_ratio - m.median_log_value_ratio)
            AS absolute_deviation

    FROM log_value_ratio AS a
    CROSS JOIN median_deviation AS m
),
mad_calculation AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY absolute_deviation
        ) OVER () AS mad_value_difference

    FROM absolute_deviations
),
value_correspondence_scores AS
(
    SELECT
        a.*,
        m.mad_value_difference,

        CASE
            WHEN m.mad_value_difference > 0
             AND a.log_value_ratio > a.median_log_value_ratio
            THEN
                (a.log_value_ratio - a.median_log_value_ratio)
                / m.mad_value_difference
            ELSE 0
        END AS remittance_repayment_value_correspondence_score

    FROM absolute_deviations AS a
    CROSS JOIN mad_calculation AS m
)
SELECT
    ocb_customer_id,
    remittance_id,
    inbound_remittance_timestamp,
    inbound_remittance_amount,
    next_remittance_timestamp,
    repayment_id,
    repayment_timestamp,
    repayment_amount,
    repayment_correspondence_ratio,
    log_value_ratio,
    median_log_value_ratio,
    absolute_deviation,
    mad_value_difference,
    remittance_repayment_value_correspondence_score

FROM value_correspondence_scores;
GO


-- 3. Inbound Remittance-to-Repayment Recurrence Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_recurrence_score
AS
WITH remittance_sequences AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,

        LEAD(r.remittance_id) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_id,

        LEAD(r.remittance_timestamp) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_timestamp

    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
      AND r.remittance_status = 'successful'
),
repayment_sequences AS
(
    SELECT
        rp.ocb_customer_id,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        rp.loan_id,

        LEAD(rp.repayment_id) OVER
        (
            PARTITION BY rp.ocb_customer_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS next_repayment_id,

        LEAD(rp.repayment_timestamp) OVER
        (
            PARTITION BY rp.ocb_customer_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS next_repayment_timestamp

    FROM gold.vw_repayment AS rp
),
remittance_repayment_sequences AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        rp.loan_id,
        r.next_remittance_id,
        r.next_remittance_timestamp,
        rp.next_repayment_id,
        rp.next_repayment_timestamp

    FROM remittance_sequences AS r

    INNER JOIN repayment_sequences AS rp
        ON rp.ocb_customer_id = r.ocb_customer_id
       AND rp.repayment_timestamp >= r.remittance_timestamp
       AND (
            r.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < r.next_remittance_timestamp
       )

    WHERE r.next_remittance_timestamp IS NOT NULL
      AND rp.next_repayment_timestamp IS NOT NULL
      AND r.next_remittance_timestamp < rp.next_repayment_timestamp
),
recurrence_population AS
(
    SELECT
        *,

        CAST(
            DATEDIFF_BIG(
                MILLISECOND,
                repayment_timestamp,
                next_repayment_timestamp
            ) / 60000.0
            AS DECIMAL(18, 4)
        ) AS recurrence_gap_minutes

    FROM remittance_repayment_sequences
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY recurrence_gap_minutes
        ) OVER () AS median_recurrence_gap_minutes

    FROM recurrence_population
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS(
                rp.recurrence_gap_minutes
                - m.median_recurrence_gap_minutes
            )
        ) OVER () AS mad_recurrence_gap_minutes

    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
),
recurrence_scores AS
(
    SELECT
        rp.*,
        m.median_recurrence_gap_minutes,
        d.mad_recurrence_gap_minutes,

        CASE
            WHEN d.mad_recurrence_gap_minutes > 0
             AND rp.recurrence_gap_minutes < m.median_recurrence_gap_minutes
            THEN
                (
                    m.median_recurrence_gap_minutes
                    - rp.recurrence_gap_minutes
                ) / d.mad_recurrence_gap_minutes
            ELSE 0
        END AS inbound_remittance_to_repayment_recurrence_score

    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    repayment_id,
    repayment_timestamp,
    repayment_amount,
    loan_id,
    next_remittance_id,
    next_remittance_timestamp,
    next_repayment_id,
    next_repayment_timestamp,
    recurrence_gap_minutes,
    median_recurrence_gap_minutes,
    mad_recurrence_gap_minutes,
    inbound_remittance_to_repayment_recurrence_score

FROM recurrence_scores;
GO

/*
-- WP5.3 Inbound Remittance → P2P Redistribution Intelligence Engine — Process Documentation
-- Inbound Remittance → P2P Redistribution Intelligence identifies P2P transfer activity following inbound remittances received by
    the same OCB customer.
-- The engine comprises three independent signals: Inbound Remittance → P2P Rapidity, Inbound Remittance → P2P Value Correspondence,
    and Inbound Remittance → P2P Recurrence.
-- A complete sequence consists of an inbound remittance received by an OCB customer followed by one or more successful P2P
    transfers by that same customer.
-- The P2P transfer timestamp must be greater than or equal to the inbound remittance timestamp.
-- Each inbound remittance defines a sequence that ends immediately before the customer's next inbound remittance.
-- Where no subsequent inbound remittance exists, the sequence includes all subsequent successful P2P transfers available in the
    dataset.
-- Inbound Remittance → P2P Rapidity measures the interval between inbound remittance receipt and the first subsequent successful
    P2P transfer in the sequence.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD) of elapsed minutes.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.
-- Inbound Remittance → P2P Value Correspondence measures each individual P2P transfer amount relative to the associated inbound
    remittance amount.
-- Each successful P2P transfer within a remittance sequence is evaluated as an individual event; transfer amounts are not
    aggregated across the sequence.
-- The P2P-to-remittance ratio is calculated by dividing the individual P2P transfer amount by the inbound remittance amount.
-- The natural logarithm of the ratio is used for scoring.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate greater individual P2P transfer values relative to inbound remittance amounts compared with the observed
    population.
-- The P2P-to-remittance ratio may exceed one because customers may have existing balances, additional inflows, or other available
    funds.
-- Inbound Remittance → P2P Recurrence measures the interval between the completion of one remittance-to-P2P sequence and the
    initiation of the next sequence.
-- Successive sequences are identified using LEAD() within each customer.
-- Sequences are ordered by inbound remittance timestamp and remittance ID.
-- The sequence endpoint is the timestamp of the last successful P2P transfer associated with the current inbound remittance.
-- The recurrence interval runs from the current sequence's last P2P transfer to the next inbound remittance timestamp.
-- This measures the gap between one sequence's completion and the next sequence's initiation.
-- Sequences without a subsequent inbound remittance are excluded from recurrence calculations.
-- Sequences without a successful P2P transfer endpoint are also excluded from recurrence calculations.
-- Recurrence scoring uses the population median and MAD of the recurrence intervals.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher recurrence scores relative to the observed population.
-- The three signals measure timing, individual-event relative value, and recurrence independently.
-- They are not mathematically combined into a single Inbound Remittance → P2P Redistribution risk score.
-- No universal score thresholds were established.
-- The engine highlights rapid P2P activity after inbound remittance receipt, unusually large individual P2P transfer values
    relative
    to inbound remittance amounts, and repeated sequences at short intervals.
-- These patterns may support further financial-behaviour and transaction-risk investigation.
-- The engine provides cross-institutional intelligence on behavioural relationships between inbound remittance activity and
    subsequent P2P redistribution.
*/

-- Combined Signals
WITH combined_signal_scores AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.inbound_remittance_timestamp,
        r.first_p2p_transfer_id,
        r.first_p2p_transfer_timestamp,
        r.elapsed_minutes,
        r.inbound_remittance_to_p2p_rapidity_score,

        v.inbound_remittance_amount,

        v.p2p_to_remittance_value_ratio,
        v.inbound_remittance_to_p2p_value_correspondence_score,

        c.sequence_1_endpoint_timestamp,
        c.sequence_2_start_timestamp,
        c.recurrence_interval_minutes,
        c.inbound_remittance_to_p2p_recurrence_score

    FROM intelligence.vw_remittance_p2p_rapidity_score AS r

    LEFT JOIN intelligence.vw_remittance_p2p_value_correspondence_score AS v
        ON r.ocb_customer_id = v.ocb_customer_id
       AND r.remittance_id = v.remittance_id

    LEFT JOIN intelligence.vw_remittance_p2p_recurrence_score AS c
        ON r.ocb_customer_id = c.ocb_customer_id
       AND r.remittance_id = c.sequence_1_remittance_id
)
SELECT *
FROM combined_signal_scores;
GO

-- Inbound Remittance-to-Loan Repayment
-- 1. Inbound Remittance-to-Loan Repayment Rapidity Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_rapidity_score
AS
WITH remittance_sequences AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount AS inbound_remittance_amount,
        LEAD(rm.remittance_timestamp) OVER
        (
            PARTITION BY rm.ocb_customer_id
            ORDER BY rm.remittance_timestamp, rm.remittance_id
        ) AS next_remittance_timestamp
    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
      AND rm.remittance_status = 'successful'
),
remittance_repayment_profile AS
(
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
        ROW_NUMBER() OVER
        (
            PARTITION BY rm.ocb_customer_id, rm.remittance_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS repayment_sequence_number
    FROM remittance_sequences AS rm
    INNER JOIN gold.vw_repayment AS rp
        ON rp.ocb_customer_id = rm.ocb_customer_id
       AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
       AND
       (
            rm.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < rm.next_remittance_timestamp
       )
),
first_repayments AS
(
    SELECT
        *,
        CAST
        (
            DATEDIFF_BIG
            (
                MILLISECOND,
                inbound_remittance_timestamp,
                repayment_timestamp
            ) / 60000.0
            AS DECIMAL(18, 4)
        ) AS remittance_repayment_delay_minutes
    FROM remittance_repayment_profile
    WHERE repayment_sequence_number = 1
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY remittance_repayment_delay_minutes
        ) OVER () AS median_delay_minutes
    FROM first_repayments
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS
            (
                f.remittance_repayment_delay_minutes
                - m.median_delay_minutes
            )
        ) OVER () AS mad_delay_minutes
    FROM first_repayments AS f
    CROSS JOIN median_stage AS m
),
rapidity_scores AS
(
    SELECT
        f.*,
        m.median_delay_minutes,
        d.mad_delay_minutes,
        CASE
            WHEN d.mad_delay_minutes > 0
             AND f.remittance_repayment_delay_minutes < m.median_delay_minutes
            THEN
                (m.median_delay_minutes - f.remittance_repayment_delay_minutes)
                / d.mad_delay_minutes
            ELSE 0
        END AS remittance_repayment_rapidity_score
    FROM first_repayments AS f
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    remittance_id,
    inbound_remittance_timestamp,
    inbound_remittance_amount,
    next_remittance_timestamp,
    loan_id,
    repayment_id,
    repayment_timestamp,
    repayment_amount,
    remittance_repayment_delay_minutes,
    median_delay_minutes,
    mad_delay_minutes,
    remittance_repayment_rapidity_score
FROM rapidity_scores;
GO


-- 2. Inbound Remittance-to-Repayment Value Correspondence Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_value_correspondence_score
AS
WITH remittance_sequences AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.remittance_timestamp AS inbound_remittance_timestamp,
        rm.remittance_amount AS inbound_remittance_amount,
        LEAD(rm.remittance_timestamp) OVER
        (
            PARTITION BY rm.ocb_customer_id
            ORDER BY rm.remittance_timestamp, rm.remittance_id
        ) AS next_remittance_timestamp
    FROM gold.vw_remittance AS rm
    WHERE rm.remittance_type = 'remittance_received'
      AND rm.remittance_status = 'successful'
),
remittance_repayment_profile AS
(
    SELECT
        rm.ocb_customer_id,
        rm.remittance_id,
        rm.inbound_remittance_timestamp,
        rm.inbound_remittance_amount,
        rm.next_remittance_timestamp,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        rp.repayment_amount
            / NULLIF(rm.inbound_remittance_amount, 0)
            AS repayment_correspondence_ratio
    FROM remittance_sequences AS rm
    INNER JOIN gold.vw_repayment AS rp
        ON rp.ocb_customer_id = rm.ocb_customer_id
       AND rp.repayment_timestamp >= rm.inbound_remittance_timestamp
       AND
       (
            rm.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < rm.next_remittance_timestamp
       )
),
log_value_ratio AS
(
    SELECT
        *,
        LOG(repayment_correspondence_ratio) AS log_value_ratio
    FROM remittance_repayment_profile
    WHERE repayment_correspondence_ratio > 0
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY log_value_ratio
        ) OVER () AS median_log_value_ratio
    FROM log_value_ratio
),
absolute_deviations AS
(
    SELECT
        v.*,
        m.median_log_value_ratio,
        ABS(v.log_value_ratio - m.median_log_value_ratio)
            AS absolute_deviation
    FROM log_value_ratio AS v
    CROSS JOIN median_stage AS m
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY absolute_deviation
        ) OVER () AS mad_value_difference
    FROM absolute_deviations
),
value_correspondence_scores AS
(
    SELECT
        v.*,
        d.mad_value_difference,
        CASE
            WHEN d.mad_value_difference > 0
             AND v.log_value_ratio > v.median_log_value_ratio
            THEN
                (v.log_value_ratio - v.median_log_value_ratio)
                / d.mad_value_difference
            ELSE 0
        END AS remittance_repayment_value_correspondence_score
    FROM absolute_deviations AS v
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    remittance_id,
    inbound_remittance_timestamp,
    inbound_remittance_amount,
    next_remittance_timestamp,
    repayment_id,
    repayment_timestamp,
    repayment_amount,
    repayment_correspondence_ratio,
    log_value_ratio,
    median_log_value_ratio,
    absolute_deviation,
    mad_value_difference,
    remittance_repayment_value_correspondence_score
FROM value_correspondence_scores;
GO


-- 3. Inbound Remittance-to-Repayment Recurrence Score

CREATE OR ALTER VIEW intelligence.vw_remittance_repayment_recurrence_score
AS
WITH remittance_sequences AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        LEAD(r.remittance_id) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_id,
        LEAD(r.remittance_timestamp) OVER
        (
            PARTITION BY r.ocb_customer_id
            ORDER BY r.remittance_timestamp, r.remittance_id
        ) AS next_remittance_timestamp
    FROM gold.vw_remittance AS r
    WHERE r.remittance_type = 'remittance_received'
      AND r.remittance_status = 'successful'
),
repayment_sequences AS
(
    SELECT
        rp.ocb_customer_id,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        rp.loan_id,
        LEAD(rp.repayment_id) OVER
        (
            PARTITION BY rp.ocb_customer_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS next_repayment_id,
        LEAD(rp.repayment_timestamp) OVER
        (
            PARTITION BY rp.ocb_customer_id
            ORDER BY rp.repayment_timestamp, rp.repayment_id
        ) AS next_repayment_timestamp
    FROM gold.vw_repayment AS rp
),
remittance_repayment_sequences AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_timestamp,
        r.remittance_amount,
        rp.repayment_id,
        rp.repayment_timestamp,
        rp.repayment_amount,
        rp.loan_id,
        r.next_remittance_id,
        r.next_remittance_timestamp,
        rp.next_repayment_id,
        rp.next_repayment_timestamp
    FROM remittance_sequences AS r
    INNER JOIN repayment_sequences AS rp
        ON rp.ocb_customer_id = r.ocb_customer_id
       AND rp.repayment_timestamp >= r.remittance_timestamp
       AND
       (
            r.next_remittance_timestamp IS NULL
            OR rp.repayment_timestamp < r.next_remittance_timestamp
       )
    WHERE r.next_remittance_timestamp IS NOT NULL
      AND rp.next_repayment_timestamp IS NOT NULL
      AND r.next_remittance_timestamp < rp.next_repayment_timestamp
),
recurrence_population AS
(
    SELECT
        *,
        CAST
        (
            DATEDIFF_BIG
            (
                MILLISECOND,
                repayment_timestamp,
                next_repayment_timestamp
            ) / 60000.0
            AS DECIMAL(18, 4)
        ) AS recurrence_gap_minutes
    FROM remittance_repayment_sequences
),
median_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY recurrence_gap_minutes
        ) OVER () AS median_recurrence_gap_minutes
    FROM recurrence_population
),
mad_stage AS
(
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP
        (
            ORDER BY ABS
            (
                rp.recurrence_gap_minutes
                - m.median_recurrence_gap_minutes
            )
        ) OVER () AS mad_recurrence_gap_minutes
    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
),
recurrence_scores AS
(
    SELECT
        rp.*,
        m.median_recurrence_gap_minutes,
        d.mad_recurrence_gap_minutes,
        CASE
            WHEN d.mad_recurrence_gap_minutes > 0
             AND rp.recurrence_gap_minutes < m.median_recurrence_gap_minutes
            THEN
                (
                    m.median_recurrence_gap_minutes
                    - rp.recurrence_gap_minutes
                ) / d.mad_recurrence_gap_minutes
            ELSE 0
        END AS inbound_remittance_to_repayment_recurrence_score
    FROM recurrence_population AS rp
    CROSS JOIN median_stage AS m
    CROSS JOIN mad_stage AS d
)
SELECT
    ocb_customer_id,
    remittance_id,
    remittance_timestamp,
    remittance_amount,
    repayment_id,
    repayment_timestamp,
    repayment_amount,
    loan_id,
    next_remittance_id,
    next_remittance_timestamp,
    next_repayment_id,
    next_repayment_timestamp,
    recurrence_gap_minutes,
    median_recurrence_gap_minutes,
    mad_recurrence_gap_minutes,
    inbound_remittance_to_repayment_recurrence_score
FROM recurrence_scores;
GO

/*
-- WP5.3 Inbound Remittance → Loan Repayment Intelligence Engine — Process Documentation
-- Inbound Remittance → Loan Repayment Intelligence identifies loan repayment activity following inbound remittances received by
-- the same OCB customer.
-- The engine comprises three independent signals: Inbound Remittance → Loan Repayment Rapidity, Inbound Remittance → Loan
-- Repayment Value Correspondence, and Inbound Remittance → Loan Repayment Recurrence.

-- A complete sequence consists of an inbound remittance received by an OCB customer followed by one or more loan repayments by
-- that same customer.
-- The loan repayment timestamp must be greater than or equal to the inbound remittance timestamp.
-- Each inbound remittance defines a sequence that ends immediately before the customer's next inbound remittance.
-- Where no subsequent inbound remittance exists, the sequence includes all subsequent loan repayments available in the dataset.

-- Inbound Remittance → Loan Repayment Rapidity measures the interval between inbound remittance receipt and the first subsequent
-- loan repayment in the sequence.
-- Rapidity scoring uses the population median and Median Absolute Deviation (MAD) of elapsed minutes.
-- Intervals below the median receive positive scores when MAD is greater than zero.
-- Intervals at or above the median receive zero scores.
-- Shorter intervals therefore produce higher rapidity scores relative to the observed population.

-- Inbound Remittance → Loan Repayment Value Correspondence measures the total value of loan repayments within a sequence
-- relative to the inbound remittance amount.
-- The loan-repayment-to-remittance ratio is calculated by dividing the total qualifying loan repayment value by the inbound
-- remittance amount.
-- The natural logarithm of the ratio is used for scoring.
-- Value correspondence scoring uses the population median and MAD of the log ratios.
-- Log ratios above the median receive positive scores when MAD is greater than zero.
-- Log ratios at or below the median receive zero scores.
-- Higher scores indicate greater loan repayment value relative to inbound remittance amounts compared with the observed
-- population.
-- The loan-repayment-to-remittance ratio may exceed one because customers may have existing balances, additional inflows, or
-- other available funds.
-- The ratio measures value correspondence within the defined sequence and does not establish that the inbound remittance
-- directly funded the loan repayments.

-- Inbound Remittance → Loan Repayment Recurrence measures the interval between the completion of one remittance-to-repayment
-- sequence and the initiation of the next sequence.
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
-- to inbound remittance amounts, and repeated sequences at short intervals.
-- These patterns may support further financial-behaviour and transaction-risk investigation.
-- The engine provides cross-institutional intelligence on behavioural relationships between inbound remittance activity and
-- subsequent loan repayment activity.
*/

-- Combined Signals
WITH combined_signal_scores AS
(
    SELECT
        r.ocb_customer_id,
        r.remittance_id,
        r.remittance_repayment_delay_minutes,
        r.remittance_repayment_rapidity_score,

        v.repayment_correspondence_ratio,
        v.remittance_repayment_value_correspondence_score,

        c.recurrence_gap_minutes,
        c.inbound_remittance_to_repayment_recurrence_score

    FROM intelligence.vw_remittance_repayment_rapidity_score AS r

    LEFT JOIN intelligence.vw_remittance_repayment_value_correspondence_score AS v
        ON r.ocb_customer_id = v.ocb_customer_id
       AND r.remittance_id = v.remittance_id

    LEFT JOIN intelligence.vw_remittance_repayment_recurrence_score AS c
        ON r.ocb_customer_id = c.ocb_customer_id
       AND r.remittance_id = c.next_remittance_id
)
SELECT *
FROM combined_signal_scores;
GO


