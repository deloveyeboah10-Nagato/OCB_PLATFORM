USE [ocb_platform];
GO

-- Debt Recycling
-- 1. Repayment Deficiency Score
CREATE
        OR

ALTER VIEW intelligence.vw_repayment_deficiency_score
AS
WITH loan_sequence
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.maturity_date,
        l.principal_amount,
        LEAD(l.loan_id) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_id,
        LEAD(l.disbursement_timestamp) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_timestamp
    FROM gold.vw_loan l
    ),
repayment_deficiency
AS (
    SELECT
        ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.maturity_date,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp,
        1.0 - (COALESCE(SUM(r.repayment_amount), 0) / NULLIF(ls.principal_amount, 0)) AS repayment_deficiency_ratio
    FROM loan_sequence ls
    LEFT JOIN gold.vw_repayment r ON
            r.loan_id = ls.loan_id
                AND r.repayment_timestamp >= ls.disbursement_timestamp
                AND r.repayment_timestamp < ls.next_loan_timestamp
    WHERE ls.next_loan_id IS NOT NULL
    GROUP BY ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.maturity_date,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp
    ),
debt_recycling_population
AS (
    SELECT
        *
    FROM repayment_deficiency
    WHERE repayment_deficiency_ratio > 0
    ),
distribution
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY repayment_deficiency_ratio
            ) OVER () AS median_deficiency
    FROM debt_recycling_population
    ),
mad_base
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY ABS(drp.repayment_deficiency_ratio - d.median_deficiency)
            ) OVER () AS mad_deficiency
    FROM debt_recycling_population drp
    CROSS JOIN distribution d
    )
SELECT
    drp.ocb_customer_id,
    drp.loan_id,
    drp.disbursement_timestamp,
    drp.maturity_date,
    drp.principal_amount,
    drp.next_loan_id,
    drp.next_loan_timestamp,
    drp.repayment_deficiency_ratio,
    d.median_deficiency,
    m.mad_deficiency,
    CASE 
        WHEN drp.repayment_deficiency_ratio > d.median_deficiency
            THEN (drp.repayment_deficiency_ratio - d.median_deficiency) / NULLIF(m.mad_deficiency, 0)
        ELSE 0
        END AS repayment_deficiency_mad_score
FROM debt_recycling_population drp
CROSS JOIN distribution d
CROSS JOIN mad_base m;
GO

-- 2. Re-borrowing Rapidity Score
CREATE
        OR

ALTER VIEW intelligence.vw_reborrowing_rapidity_score
AS
WITH loan_sequence
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.maturity_date,
        l.principal_amount,
        LEAD(l.loan_id) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_id,
        LEAD(l.disbursement_timestamp) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_timestamp
    FROM gold.vw_loan l
    ),
repayment_position
AS (
    SELECT
        ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.maturity_date,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp,
        COALESCE(SUM(r.repayment_amount), 0) AS total_repaid_before_next_loan,
        MAX(r.repayment_timestamp)           AS latest_repayment_timestamp
    FROM loan_sequence ls
    LEFT JOIN gold.vw_repayment r ON
            r.loan_id = ls.loan_id
                AND r.repayment_timestamp >= ls.disbursement_timestamp
                AND r.repayment_timestamp < ls.next_loan_timestamp
    WHERE ls.next_loan_id IS NOT NULL
    GROUP BY ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.maturity_date,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp
    ),
debt_recycling_population
AS (
    SELECT
        rp.*,
        1.0 - (rp.total_repaid_before_next_loan / NULLIF(rp.principal_amount, 0)) AS repayment_deficiency_ratio,
        rp.disbursement_timestamp                                                 AS rapidity_anchor_timestamp
    FROM repayment_position rp
    WHERE 1.0 - (rp.total_repaid_before_next_loan / NULLIF(rp.principal_amount, 0)) > 0
    ),
rapidity
AS (
    SELECT
        drp.*,
        CAST(DATEDIFF_BIG(MILLISECOND, drp.rapidity_anchor_timestamp, drp.next_loan_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS reborrowing_delay_minutes
    FROM debt_recycling_population drp
    ),
distribution
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY reborrowing_delay_minutes
            ) OVER () AS median_reborrowing_delay
    FROM rapidity
    ),
mad_base
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY ABS(r.reborrowing_delay_minutes - d.median_reborrowing_delay)
            ) OVER () AS mad_reborrowing_delay
    FROM rapidity r
    CROSS JOIN distribution d
    )
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.disbursement_timestamp,
    r.maturity_date,
    r.principal_amount,
    r.next_loan_id,
    r.next_loan_timestamp,
    r.total_repaid_before_next_loan,
    r.repayment_deficiency_ratio,
    r.rapidity_anchor_timestamp,
    r.latest_repayment_timestamp,
    r.reborrowing_delay_minutes,
    d.median_reborrowing_delay,
    m.mad_reborrowing_delay,
    CASE 
        WHEN r.reborrowing_delay_minutes < d.median_reborrowing_delay
            THEN (d.median_reborrowing_delay - r.reborrowing_delay_minutes) / NULLIF(m.mad_reborrowing_delay, 0)
        ELSE 0
        END AS reborrowing_rapidity_mad_score
FROM rapidity r
CROSS JOIN distribution d
CROSS JOIN mad_base m;
GO

-- 3. Debt Recycling Recurrence Score
CREATE
        OR

ALTER VIEW intelligence.vw_debt_recycling_recurrence_score
AS
WITH loan_sequence
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.principal_amount,
        LEAD(l.loan_id) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_id,
        LEAD(l.disbursement_timestamp) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_timestamp
    FROM gold.vw_loan l
    ),
repayment_deficiency
AS (
    SELECT
        ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp,
        1.0 - (COALESCE(SUM(r.repayment_amount), 0) / NULLIF(ls.principal_amount, 0)) AS repayment_deficiency_ratio
    FROM loan_sequence ls
    LEFT JOIN gold.vw_repayment r ON
            r.loan_id = ls.loan_id
                AND r.repayment_timestamp >= ls.disbursement_timestamp
                AND r.repayment_timestamp < ls.next_loan_timestamp
    WHERE ls.next_loan_id IS NOT NULL
    GROUP BY ls.ocb_customer_id,
        ls.loan_id,
        ls.disbursement_timestamp,
        ls.principal_amount,
        ls.next_loan_id,
        ls.next_loan_timestamp
    ),
debt_recycling_population
AS (
    SELECT
        *
    FROM repayment_deficiency
    WHERE repayment_deficiency_ratio > 0
    ),
qualified_recycling_events
AS (
    SELECT
        drp.ocb_customer_id,
        drp.loan_id,
        drp.next_loan_id,
        drp.disbursement_timestamp,
        drp.next_loan_timestamp,
        drp.repayment_deficiency_ratio,
        LEAD(drp.next_loan_timestamp) OVER (
            PARTITION BY drp.ocb_customer_id ORDER BY drp.next_loan_timestamp,
                drp.next_loan_id
            ) AS next_recycling_event_timestamp
    FROM debt_recycling_population drp
    ),
recurrence
AS (
    SELECT
        qre.ocb_customer_id,
        qre.loan_id,
        qre.next_loan_id,
        qre.disbursement_timestamp,
        qre.next_loan_timestamp,
        qre.repayment_deficiency_ratio,
        qre.next_recycling_event_timestamp,
        CAST(DATEDIFF_BIG(MILLISECOND, qre.next_loan_timestamp, qre.next_recycling_event_timestamp) / 60000.0 AS DECIMAL(18, 4)) AS recycling_recurrence_gap_minutes
    FROM qualified_recycling_events qre
    WHERE qre.next_recycling_event_timestamp IS NOT NULL
    ),
distribution
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY recycling_recurrence_gap_minutes
            ) OVER () AS median_recurrence_gap
    FROM recurrence
    ),
mad_base
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.50) WITHIN
    GROUP (
            ORDER BY ABS(r.recycling_recurrence_gap_minutes - d.median_recurrence_gap)
            ) OVER () AS mad_recurrence_gap
    FROM recurrence r
    CROSS JOIN distribution d
    )
SELECT
    r.ocb_customer_id,
    r.loan_id,
    r.next_loan_id,
    r.disbursement_timestamp,
    r.next_loan_timestamp,
    r.repayment_deficiency_ratio,
    r.next_recycling_event_timestamp,
    r.recycling_recurrence_gap_minutes,
    d.median_recurrence_gap,
    m.mad_recurrence_gap,
    CASE 
        WHEN r.recycling_recurrence_gap_minutes < d.median_recurrence_gap
            THEN (d.median_recurrence_gap - r.recycling_recurrence_gap_minutes) / NULLIF(m.mad_recurrence_gap, 0)
        ELSE 0
        END AS debt_recycling_recurrence_mad_score
FROM recurrence r
CROSS JOIN distribution d
CROSS JOIN mad_base m;
GO

/*
-- WP5.3 Credit Behaviour Anomaly Engine — Debt Recycling Process Documentation
-- Debt Recycling was defined as the behaviour of a customer taking a subsequent loan while the preceding loan
    remained partially or fully unrepaid.
-- The Debt Recycling population was constructed by ordering loans chronologically within each customer and
    identifying the immediate subsequent loan using LEAD().
-- Repayments were attributed to the preceding loan through the loan_id relationship provided by the repayment data.
-- Only repayments occurring after the preceding loan's disbursement and before the subsequent loan's disbursement
    were considered when determining the repayment position at the point of re-borrowing.
-- The repayment position was expressed as Repayment Deficiency:
    1 - (total repayment against the preceding loan before the subsequent loan / preceding loan principal).
-- A repayment deficiency greater than zero defined the Debt Recycling population.
-- Customers who fully repaid or over-repaid the preceding loan before taking the subsequent loan were therefore
    excluded from the Debt Recycling population.
-- Loan maturity was not used as an exclusion condition because taking a subsequent loan while an earlier loan
    remains outstanding is relevant to the Debt Recycling behaviour regardless of whether the preceding loan has
    reached its maturity date.
-- The resulting population represents customers who re-borrowed while carrying an outstanding obligation from
    the preceding loan.
-- The Debt Recycling behaviour was evaluated using three independent signals: Repayment Deficiency,
    Re-borrowing Rapidity, and Debt Recycling Recurrence.
-- Repayment Deficiency measures how much of the preceding loan remained unrepaid when the subsequent loan was
    issued.
-- Repayment Deficiency was scored using the population median and MAD calculated only within the Debt Recycling
    population.
-- Values at or below the population median received zero, while values above the median received positive scores.
-- The Repayment Deficiency score therefore increases as the customer's outstanding repayment position at
    re-borrowing becomes progressively more deficient relative to the Debt Recycling population.
-- Re-borrowing Rapidity measures how quickly the customer takes the subsequent loan while still carrying the
    repayment deficiency from the preceding loan.
-- Where repayments existed against the preceding loan before the subsequent loan, the latest such repayment
    timestamp was used as the temporal anchor.
-- Where no repayment existed before the subsequent loan, the preceding loan's disbursement timestamp was used
    as the fallback anchor.
-- The elapsed time between the selected anchor timestamp and the subsequent loan's disbursement timestamp was
    used as the re-borrowing delay.
-- Re-borrowing Rapidity was scored using the population median and MAD, with shorter-than-median delays receiving
    positive scores and longer delays receiving zero.
-- The rapidity score therefore increases as the customer re-borrows more quickly while still carrying the
    outstanding obligation.
-- Debt Recycling Recurrence measures how quickly the customer repeats the qualifying Debt Recycling behaviour.
-- Recurrence was calculated only from qualifying Debt Recycling transitions rather than from all successive loans.
-- A qualifying transition was defined as:
    Loan A → insufficient repayment → Loan B.
-- A subsequent qualifying transition was defined as:
    Loan B → insufficient repayment → Loan C.
-- This prevents ordinary repeated borrowing from being interpreted as Debt Recycling Recurrence when the preceding
    loan had already been fully repaid.
-- The recurrence interval was measured between the disbursement timestamp of the current qualifying subsequent
    loan and the disbursement timestamp of the next qualifying subsequent loan.
-- The next qualifying recycling event was identified using LEAD() over chronologically ordered qualifying
    transitions for each customer.
-- The final qualifying Debt Recycling event for a customer has no subsequent qualifying event and was therefore
    excluded from recurrence scoring.
-- Debt Recycling Recurrence was scored using the population median and MAD, with shorter inter-event gaps
    receiving positive scores and longer gaps receiving zero.
-- The recurrence score therefore measures how quickly the customer repeats the Debt Recycling behaviour rather
    than simply counting the number of loans taken.
-- The three signals were evaluated independently as credit-behaviour anomaly constructs.
-- The three signals were not mathematically combined into a single Debt Recycling risk score.
-- No universal score thresholds were established. Score distributions and bands were used to validate the
    behaviour and integrity of the individual scoring mechanisms.
-- The analysis does not establish that a qualifying Debt Recycling transition, high repayment deficiency,
    rapid re-borrowing, repeated recycling behaviour, or high signal score is fraudulent, suspicious, or
    inherently higher risk.
-- The analytical phenomenon of interest is repeated re-borrowing while previous credit obligations remain
    outstanding, particularly where the repayment deficiency is unusually high, re-borrowing occurs unusually
    quickly, or the behaviour repeats at unusually short intervals.
-- Repeated Debt Recycling may indicate a customer repeatedly relying on new credit while carrying unresolved
    obligations and therefore provides a basis for further credit-risk investigation.
-- The final Debt Recycling construct therefore provides three independent dimensions of credit-behaviour
    intelligence: how deficient the preceding loan's repayment position was at re-borrowing, how rapidly the
    customer re-borrowed while that deficiency remained, and how quickly the Debt Recycling behaviour was repeated.
-- The Debt Recycling construct was validated at credit-behaviour transition grain using these three independent
    anomaly signals.
*/
-- Combining all signals
-- Debt Recycling Combined
SELECT
    rd.ocb_customer_id,
    rd.loan_id,
    rd.next_loan_id,
    rd.disbursement_timestamp,
    rd.next_loan_timestamp,
    rd.principal_amount,
    rd.repayment_deficiency_ratio,
    rd.repayment_deficiency_mad_score,
    rr.total_repaid_before_next_loan,
    rr.rapidity_anchor_timestamp,
    rr.latest_repayment_timestamp,
    rr.reborrowing_delay_minutes,
    rr.reborrowing_rapidity_mad_score,
    COALESCE(rc.next_recycling_event_timestamp, NULL)   AS next_recycling_event_timestamp,
    COALESCE(rc.recycling_recurrence_gap_minutes, NULL) AS recycling_recurrence_gap_minutes,
    COALESCE(rc.debt_recycling_recurrence_mad_score, 0) AS debt_recycling_recurrence_mad_score
FROM intelligence.vw_repayment_deficiency_score rd
INNER JOIN intelligence.vw_reborrowing_rapidity_score rr ON
        rr.ocb_customer_id = rd.ocb_customer_id
            AND rr.loan_id = rd.loan_id
            AND rr.next_loan_id = rd.next_loan_id
LEFT JOIN intelligence.vw_debt_recycling_recurrence_score rc ON
        rc.ocb_customer_id = rd.ocb_customer_id
            AND rc.loan_id = rd.loan_id
            AND rc.next_loan_id = rd.next_loan_id;
GO

-- Credit Size Escalation
-- 1. Credit Value Escalation
CREATE
        OR

ALTER VIEW intelligence.vw_credit_value_escaltion_score
AS
WITH loan_profile
AS (
    SELECT
        l.ocb_customer_id,
        YEAR(l.disbursement_timestamp)                                                    AS loan_year,
        DATEFROMPARTS(YEAR(l.disbursement_timestamp), MONTH(l.disbursement_timestamp), 1) AS loan_date,
        l.loan_id,
        SUM(l.principal_amount)                                                           AS principal_loan_amount
    FROM gold.vw_loan l
    GROUP BY l.ocb_customer_id,
        YEAR(l.disbursement_timestamp),
        DATEFROMPARTS(YEAR(l.disbursement_timestamp), MONTH(l.disbursement_timestamp), 1),
        l.loan_id
    ),
median_loan_calc
AS (
    SELECT DISTINCT
        ocb_customer_id,
        loan_year,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY principal_loan_amount
            ) OVER (
            PARTITION BY ocb_customer_id,
            loan_year
            ) AS baseline_median_loan
    FROM loan_profile
    ),
lagged_baseline_median
AS (
    SELECT
        *,
        LAG(baseline_median_loan) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_year
            ) AS historical_baseline_median
    FROM median_loan_calc
    ),
residual_calc
AS (
    SELECT
        lp.ocb_customer_id,
        lp.loan_id,
        lp.loan_year,
        lp.loan_date,
        lp.principal_loan_amount,
        bm.baseline_median_loan,
        bm.historical_baseline_median,
        lp.principal_loan_amount - bm.historical_baseline_median AS residual_loan
    FROM loan_profile lp
    INNER JOIN lagged_baseline_median bm ON
            lp.ocb_customer_id = bm.ocb_customer_id
                AND lp.loan_year = bm.loan_year
    ),
residual_median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY residual_loan
            ) OVER () AS residual_median
    FROM residual_calc
    WHERE residual_loan IS NOT NULL
    ),
residual_deviation_calc
AS (
    SELECT
        rc.*,
        rmc.residual_median,
        ABS(rc.residual_loan - rmc.residual_median) AS absolute_deviation
    FROM residual_calc rc
    CROSS JOIN residual_median_calc rmc
    WHERE rc.residual_loan IS NOT NULL
    ),
residual_mad_calc
AS (
    SELECT DISTINCT
        residual_median,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS residual_mad
    FROM residual_deviation_calc
    )
SELECT
    rc.ocb_customer_id,
    rc.loan_id,
    rc.loan_year,
    rc.loan_date,
    rc.principal_loan_amount,
    rc.baseline_median_loan,
    rc.historical_baseline_median,
    rc.residual_loan,
    rc.residual_median,
    rmc.residual_mad,
    CASE 
        WHEN rc.residual_loan > rc.residual_median
                AND rmc.residual_mad > 0
            THEN (rc.residual_loan - rc.residual_median) / rmc.residual_mad
        ELSE 0
        END AS loan_escalation_mad_score
FROM residual_deviation_calc rc
INNER JOIN residual_mad_calc rmc ON
        rc.residual_median = rmc.residual_median;
GO

-- 2. Escalation Recurrence
CREATE
        OR

ALTER VIEW intelligence.vw_credit_escalation_recurrence_score
AS
WITH loan_profile
AS (
    SELECT
        l.ocb_customer_id,
        YEAR(l.disbursement_timestamp)                                                    AS loan_year,
        DATEFROMPARTS(YEAR(l.disbursement_timestamp), MONTH(l.disbursement_timestamp), 1) AS loan_date,
        l.loan_id,
        SUM(l.principal_amount)                                                           AS principal_loan_amount
    FROM gold.vw_loan l
    GROUP BY l.ocb_customer_id,
        YEAR(l.disbursement_timestamp),
        DATEFROMPARTS(YEAR(l.disbursement_timestamp), MONTH(l.disbursement_timestamp), 1),
        l.loan_id
    ),
median_loan_calc
AS (
    SELECT DISTINCT
        ocb_customer_id,
        loan_year,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY principal_loan_amount
            ) OVER (
            PARTITION BY ocb_customer_id,
            loan_year
            ) AS baseline_median_loan
    FROM loan_profile
    ),
lagged_baseline_median
AS (
    SELECT
        *,
        LAG(baseline_median_loan) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_year
            ) AS historical_baseline_median
    FROM median_loan_calc
    ),
residual_calc
AS (
    SELECT
        lp.ocb_customer_id,
        lp.loan_id,
        lp.loan_year,
        lp.loan_date,
        lp.principal_loan_amount,
        bm.baseline_median_loan,
        bm.historical_baseline_median,
        lp.principal_loan_amount - bm.historical_baseline_median AS residual_loan
    FROM loan_profile lp
    INNER JOIN lagged_baseline_median bm ON
            lp.ocb_customer_id = bm.ocb_customer_id
                AND lp.loan_year = bm.loan_year
    ),
residual_median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY residual_loan
            ) OVER () AS residual_median
    FROM residual_calc
    WHERE residual_loan IS NOT NULL
    ),
residual_deviation_calc
AS (
    SELECT
        rc.*,
        rmc.residual_median,
        ABS(rc.residual_loan - rmc.residual_median) AS absolute_deviation
    FROM residual_calc rc
    CROSS JOIN residual_median_calc rmc
    WHERE rc.residual_loan IS NOT NULL
    ),
residual_mad_calc
AS (
    SELECT DISTINCT
        residual_median,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS residual_mad
    FROM residual_deviation_calc
    ),
escalation_events
AS (
    SELECT
        rc.ocb_customer_id,
        rc.loan_id,
        rc.loan_year,
        rc.loan_date,
        rc.principal_loan_amount,
        rc.historical_baseline_median,
        rc.residual_loan,
        rc.residual_median,
        rmc.residual_mad,
        CASE 
            WHEN rc.residual_loan > rc.residual_median
                    AND rmc.residual_mad > 0
                THEN (rc.residual_loan - rc.residual_median) / rmc.residual_mad
            ELSE 0
            END AS loan_escalation_mad_score
    FROM residual_deviation_calc rc
    INNER JOIN residual_mad_calc rmc ON
            rc.residual_median = rmc.residual_median
    ),
qualifying_escalations
AS (
    SELECT
        *,
        LEAD(loan_date) OVER (
            PARTITION BY ocb_customer_id ORDER BY loan_date,
                loan_id
            ) AS next_escalation_date
    FROM escalation_events
    WHERE loan_escalation_mad_score > 0
    ),
recurrence_calc
AS (
    SELECT
        ocb_customer_id,
        loan_id,
        loan_date,
        principal_loan_amount,
        historical_baseline_median,
        residual_loan,
        loan_escalation_mad_score,
        next_escalation_date,
        DATEDIFF_BIG(DAY, loan_date, next_escalation_date) AS escalation_recurrence_gap_days
    FROM qualifying_escalations
    WHERE next_escalation_date IS NOT NULL
    ),
recurrence_median_calc
AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY escalation_recurrence_gap_days
            ) OVER () AS recurrence_median
    FROM recurrence_calc
    ),
recurrence_deviation_calc
AS (
    SELECT
        rc.*,
        rmc.recurrence_median,
        ABS(rc.escalation_recurrence_gap_days - rmc.recurrence_median) AS absolute_deviation
    FROM recurrence_calc rc
    CROSS JOIN recurrence_median_calc rmc
    ),
recurrence_mad_calc
AS (
    SELECT DISTINCT
        recurrence_median,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY absolute_deviation
            ) OVER () AS recurrence_mad
    FROM recurrence_deviation_calc
    )
SELECT
    rc.ocb_customer_id,
    rc.loan_id,
    rc.loan_date,
    rc.principal_loan_amount,
    rc.historical_baseline_median,
    rc.residual_loan,
    rc.loan_escalation_mad_score,
    rc.next_escalation_date,
    rc.escalation_recurrence_gap_days,
    rc.recurrence_median,
    rmc.recurrence_mad,
    CASE 
        WHEN rc.escalation_recurrence_gap_days < rc.recurrence_median
                AND rmc.recurrence_mad > 0
            THEN (rc.recurrence_median - rc.escalation_recurrence_gap_days) / rmc.recurrence_mad
        ELSE 0
        END AS escalation_recurrence_mad_score
FROM recurrence_deviation_calc rc
INNER JOIN recurrence_mad_calc rmc ON
        rc.recurrence_median = rmc.recurrence_median;
GO

-- 3. CREDIT OBLIGATION ESCALATION
CREATE
        OR

ALTER VIEW intelligence.vw_credit_obligation_escalation_flag
AS
WITH loan_sequence
AS (
    SELECT
        l.ocb_customer_id,
        l.loan_id,
        l.disbursement_timestamp,
        l.maturity_date,
        l.principal_amount,
        LEAD(l.loan_id) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_id,
        LEAD(l.disbursement_timestamp) OVER (
            PARTITION BY l.ocb_customer_id ORDER BY l.disbursement_timestamp,
                l.loan_id
            ) AS next_loan_timestamp
    FROM gold.vw_loan l
    ),
loan_windows
AS (
    SELECT
        ls.*,
        CASE 
            WHEN ls.next_loan_timestamp < ls.maturity_date
                THEN ls.next_loan_id
            END AS pre_maturity_loan_id,
        CASE 
            WHEN ls.next_loan_timestamp < ls.maturity_date
                THEN ls.next_loan_timestamp
            END AS pre_maturity_loan_timestamp
    FROM loan_sequence ls
    ),
repayment_status
AS (
    SELECT
        lw.ocb_customer_id,
        lw.loan_id,
        lw.disbursement_timestamp,
        lw.maturity_date,
        lw.principal_amount,
        lw.pre_maturity_loan_id,
        lw.pre_maturity_loan_timestamp,
        lw.next_loan_id,
        lw.next_loan_timestamp,
        COALESCE(SUM(CASE 
                    WHEN r.repayment_timestamp <= lw.maturity_date
                        THEN r.repayment_amount
                    ELSE 0
                    END), 0) AS repaid_by_maturity,
        COALESCE(SUM(CASE 
                    WHEN lw.pre_maturity_loan_timestamp IS NOT NULL
                            AND r.repayment_timestamp <= lw.pre_maturity_loan_timestamp
                        THEN r.repayment_amount
                    ELSE 0
                    END), 0) AS repaid_by_pre_maturity_loan
    FROM loan_windows lw
    LEFT JOIN gold.vw_repayment r ON
            r.loan_id = lw.loan_id
                AND r.repayment_timestamp >= lw.disbursement_timestamp
    GROUP BY lw.ocb_customer_id,
        lw.loan_id,
        lw.disbursement_timestamp,
        lw.maturity_date,
        lw.principal_amount,
        lw.pre_maturity_loan_id,
        lw.pre_maturity_loan_timestamp,
        lw.next_loan_id,
        lw.next_loan_timestamp
    ),
obligation_status
AS (
    SELECT
        rs.*,
        rs.principal_amount - rs.repaid_by_pre_maturity_loan AS outstanding_at_pre_maturity_loan,
        rs.principal_amount - rs.repaid_by_maturity          AS outstanding_at_maturity
    FROM repayment_status rs
    ),
strike_events
AS (
    SELECT
        os.*,
        CASE 
            WHEN os.pre_maturity_loan_id IS NOT NULL
                    AND os.outstanding_at_pre_maturity_loan > 0
                THEN 1
            ELSE 0
            END AS strike_1_pre_maturity_reborrowing,
        CASE 
            WHEN os.outstanding_at_maturity > 0
                THEN 1
            ELSE 0
            END AS strike_2_maturity_breach,
        CASE 
            WHEN os.outstanding_at_maturity > 0
                    AND EXISTS (
                    SELECT
                        1
                    FROM gold.vw_loan post
                    WHERE post.ocb_customer_id = os.ocb_customer_id
                            AND post.disbursement_timestamp > os.maturity_date
                    )
                THEN 1
            ELSE 0
            END AS strike_3_post_maturity_reborrowing
    FROM obligation_status os
    )
SELECT
    ocb_customer_id,
    loan_id,
    disbursement_timestamp,
    maturity_date,
    principal_amount,
    pre_maturity_loan_id,
    pre_maturity_loan_timestamp,
    repaid_by_pre_maturity_loan,
    outstanding_at_pre_maturity_loan,
    repaid_by_maturity,
    outstanding_at_maturity,
    next_loan_id,
    next_loan_timestamp,
    strike_1_pre_maturity_reborrowing,
    strike_2_maturity_breach,
    strike_3_post_maturity_reborrowing,
    strike_1_pre_maturity_reborrowing + strike_2_maturity_breach + strike_3_post_maturity_reborrowing AS total_strikes
FROM strike_events
WHERE strike_1_pre_maturity_reborrowing = 1
        OR strike_2_maturity_breach = 1
        OR strike_3_post_maturity_reborrowing = 1;
GO

/*
-- WP5.3 Credit Behaviour Anomaly Engine — Credit Behaviour Process Documentation
--
-- The Credit Behaviour Anomaly Engine was designed to identify distinct forms of abnormal or escalating lending
    behaviour at customer and loan-event level.
-- The engine evaluates three independent constructs:
    Credit Value Escalation,
    Credit Escalation Recurrence,
    Credit Obligation Escalation.
--
-- The three constructs intentionally measure different dimensions of credit behaviour:
    Credit Value Escalation measures how much larger a current loan is relative to the customer's established
    borrowing scale.
    Credit Escalation Recurrence measures how repeatedly and rapidly that escalation behaviour occurs.
    Credit Obligation Escalation measures whether the customer continues taking credit while previous obligations
    remain unresolved through their contractual lifecycle.
-- CREDIT VALUE ESCALATION
-- Credit Value Escalation was defined as the behaviour of a customer receiving a loan materially larger than the
    customer's established borrowing scale.
-- For each customer and lending year, the median loan principal was used to represent the customer's borrowing
    scale for that year.
-- The historical baseline for each lending year was established using the preceding observed lending year's
    borrowing median.
-- The rolling annual baseline allows the customer's borrowing scale to evolve over time while preventing the
    current lending event from defining its own historical reference.
-- A lending year without activity did not reset the customer's historical borrowing reference. The preceding
    observed lending year remained the baseline for the next observed lending year.
-- Credit Value Escalation was expressed as:
    current loan amount - historical baseline median.
-- A positive residual therefore represents borrowing above the customer's established historical scale.
-- The residual distribution was evaluated using its population median and MAD.
-- Residuals at or below the population median received zero, while residuals above the population median
    received positive scores.
-- The resulting score increases as the current loan departs further above the customer's established borrowing
    scale.
-- MAD was used as the scale of deviation rather than as a universal activation threshold.
-- The analytical phenomenon of interest is progressive expansion of credit size beyond the customer's established
    borrowing pattern.
-- CREDIT ESCALATION RECURRENCE
-- Credit Escalation Recurrence was defined as the repeated occurrence of Credit Value Escalation behaviour by the
    same customer.
-- The recurrence population was constructed exclusively from qualifying Credit Value Escalation events.
-- A qualifying escalation event was defined as a loan with a Credit Value Escalation score greater than zero.
-- Ordinary lending activity that did not qualify as Credit Value Escalation was excluded from the recurrence
    population.
-- This ensures that recurrence measures repetition of escalation behaviour rather than simply counting repeated
    borrowing activity.
-- Qualifying escalation events were ordered chronologically within each customer.
-- The next qualifying escalation event was identified using LEAD() over the ordered escalation events.
-- The recurrence interval was measured between the current qualifying escalation event and the next qualifying
    escalation event.
-- The final qualifying escalation event for a customer has no subsequent qualifying event and was therefore
    excluded from recurrence scoring.
-- Recurrence was scored using the population median and MAD of qualifying inter-event gaps.
-- Inter-event gaps shorter than the population median received positive scores, while gaps at or above the
    population median received zero.
-- The recurrence score therefore increases as Credit Value Escalation behaviour is repeated more quickly.
-- The signal is complementary to Credit Value Escalation rather than a replacement for it.
-- The analytical phenomenon of interest is persistent and repeated expansion of credit size relative to the
    customer's established borrowing scale.
-- CREDIT OBLIGATION ESCALATION
-- Credit Obligation Escalation was defined as the progressive continuation of borrowing while previous credit
    obligations remain unresolved through their contractual lifecycle.
-- The construct was evaluated chronologically at individual loan-obligation grain.
-- Three sequential escalation conditions, referred to as strikes, were evaluated.
-- Strike 1 — Pre-Maturity Re-Borrowing:
    A customer takes a subsequent loan before the preceding loan reaches maturity while the preceding loan still
    has an outstanding balance.
-- The immediate subsequent loan was identified using LEAD() within each customer's chronological loan sequence.
-- Repayments attributable to the preceding loan were evaluated up to the point of subsequent borrowing.
-- An outstanding balance greater than zero at that point generated Strike 1.
-- Strike 2 — Maturity Breach:
    A customer reaches the contractual maturity date of a loan while that loan still has an outstanding balance.
-- Repayments occurring on or before maturity were used to determine the outstanding balance at maturity.
-- An outstanding balance greater than zero at maturity generated Strike 2.
-- Strike 3 — Post-Maturity Re-Borrowing:
    After a loan reaches maturity with an outstanding balance, the customer subsequently takes another loan.
-- Strike 3 therefore requires the Strike 2 condition and the existence of a later loan after the maturity date.
-- The existence of a later post-maturity loan was evaluated across the customer's subsequent lending history rather
    than being restricted to the immediate next loan.
-- This preserves the event sequence where another loan may occur before maturity and an additional loan may occur
    after maturity.
-- The three strikes represent progressive stages of unresolved credit-obligation behaviour rather than mutually
    exclusive conditions.
-- The resulting progression is:
    borrow → remain obligated → reach maturity unresolved → continue borrowing.
-- Strike 1 identifies borrowing while an earlier obligation remains outstanding.
-- Strike 2 identifies failure to clear the obligation by contractual maturity.
-- Strike 3 identifies continued borrowing after the unresolved obligation has passed maturity.
-- Strike 2 followed by Strike 3 therefore represents a meaningful credit-obligation escalation even where
    pre-maturity re-borrowing is not observed.
-- ENGINE INTERPRETATION
-- The three constructs were deliberately maintained as independent analytical signals rather than mathematically
    combining them into a single Credit Behaviour risk score.
-- The constructs answer three different questions:
    Credit Value Escalation — How much bigger is the credit?
    Credit Escalation Recurrence — How repeatedly does the credit size escalate?
    Credit Obligation Escalation — Does the customer continue taking credit despite unresolved obligations?
-- The signals therefore provide complementary dimensions of credit-behaviour intelligence rather than duplicate
    measurements of the same phenomenon.
-- No universal score thresholds were established.
-- Score distributions and observed event patterns were used to validate the integrity and behaviour of the
    individual scoring mechanisms.
-- The analysis does not establish that Credit Value Escalation, Escalation Recurrence, Credit Obligation
    Escalation, any individual strike, or a high signal score is fraudulent, suspicious, or inherently higher risk.
-- The analytical purpose is to identify credit-behaviour patterns that warrant further investigation or
    contextual assessment.
-- Taken together, the three constructs capture three distinct dimensions of progressive credit behaviour:
    increasing credit size,
    repeated credit-size escalation,
    continued borrowing despite unresolved obligations.
-- The Credit Behaviour Anomaly Engine was therefore validated using independent size, recurrence, and obligation
    signals rather than relying on a single composite measure.
*/
-- Combining Credit Escalation Signals
SELECT
    v.ocb_customer_id,
    -- Credit Value Escalation
    v.loan_id,
    v.loan_date,
    v.principal_loan_amount,
    v.baseline_median_loan,
    v.historical_baseline_median,
    v.residual_loan,
    v.loan_escalation_mad_score,
    -- Escalation Recurrence
    r.next_escalation_date,
    r.escalation_recurrence_gap_days,
    r.escalation_recurrence_mad_score,
    -- Credit Obligation Escalation
    o.maturity_date,
    o.principal_amount,
    o.pre_maturity_loan_id,
    o.pre_maturity_loan_timestamp,
    o.repaid_by_pre_maturity_loan,
    o.outstanding_at_pre_maturity_loan,
    o.repaid_by_maturity,
    o.outstanding_at_maturity,
    o.next_loan_id,
    o.next_loan_timestamp,
    o.strike_1_pre_maturity_reborrowing,
    o.strike_2_maturity_breach,
    o.strike_3_post_maturity_reborrowing,
    o.total_strikes
FROM intelligence.vw_credit_obligation_escalation_flag o
LEFT JOIN intelligence.vw_credit_escalation_recurrence_score r ON
        o.ocb_customer_id = r.ocb_customer_id
            AND o.loan_id = r.loan_id
LEFT JOIN intelligence.vw_credit_value_escaltion_score v ON
        o.ocb_customer_id = v.ocb_customer_id
            AND o.loan_id = v.loan_id;
GO



