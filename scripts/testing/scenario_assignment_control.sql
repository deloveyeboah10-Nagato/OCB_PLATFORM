USE [ocb_platform];
GO

CREATE TABLE scenario_assignments_control
(
    synthetic_person_id VARCHAR(20) NOT NULL,
    source_entity VARCHAR(50) NOT NULL,
    source_customer_id VARCHAR(100) NOT NULL,
    scenario_id VARCHAR(5) NOT NULL,
    scenario_family NVARCHAR(200) NOT NULL,
    severity VARCHAR(50) NOT NULL,
    difficulty  VARCHAR(100) NOT NULL
);

BULK INSERT scenario_assignments_control
FROM 'C:\Users\REV DELOVE\Desktop\MIKE\DATA ANALYSIS\PROJECTS\SQL\OCB_PLATFORM\simulation\OCB_Simulation_Platform_v1_0_0\control\scenario_assignments.csv' 
WITH (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        TABLOCK
);



WITH scenario_control AS
(
    SELECT 
    t.customer_id,
    t.transaction_id,
    sa.scenario_family,
    sa.severity,
    sa.difficulty,
    transaction_timestamp,
    t.transaction_type,
    t.transaction_amount,
    Lead(transaction_timestamp,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_timestamp,
    Lead(transaction_type,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_txn_type,
    Lead(transaction_amount,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_amt
FROM scenario_assignments_control sa
INNER JOIN gold.vw_transaction t
ON sa.source_customer_id=t.customer_id
AND sa.synthetic_person_id=t.cross_domain_id
AND scenario_id='S02'
),
lead_day_interval AS
(
    SELECT *,
   /* Lead(date_hr,1) OVER (PARTITION BY customer_id ORDER BY date_hr) AS next_time,
    Lead(transaction_amount,1) OVER (PARTITION BY customer_id ORDER BY date_hr) AS next_amt,
    Lead(transaction_type,1) OVER (PARTITION BY customer_id ORDER BY date_hr) AS next_txn_type, */
    DATEDIFF_BIG(SECOND, transaction_timestamp, next_timestamp)/86400.0 AS day_interval 
FROM scenario_control
WHERE DATEPART(HOUR,transaction_timestamp) >= 23 OR DATEPART(HOUR,transaction_timestamp)  <= 2
)
SELECT * FROM lead_day_interval
WHERE day_interval <=1
AND DATEPART(HOUR,next_timestamp) >= 23 OR DATEPART(HOUR,next_timestamp)  <= 2
ORDER BY CASE WHEN severity = 'High' THEN 1
            WHEN severity = 'Medium' THEN 2
            ELSE 3 END ASC,customer_id ASC,transaction_timestamp ASC, day_interval ASC;



WITH scenario_control AS
(
    SELECT 
    t.customer_id,
    t.transaction_id,
    sa.scenario_family,
    sa.severity,
    sa.difficulty,
    transaction_timestamp,
    t.transaction_type,
    t.transaction_amount,
    Lead(transaction_timestamp,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_timestamp,
    Lead(transaction_type,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_txn_type,
    Lead(transaction_amount,1) OVER (PARTITION BY customer_id ORDER BY transaction_timestamp) AS next_amt
FROM scenario_assignments_control sa
INNER JOIN gold.vw_transaction t
ON sa.source_customer_id=t.customer_id
AND sa.synthetic_person_id=t.cross_domain_id
AND scenario_id='S02'
),
lead_day_interval AS
(
    SELECT *,
    DATEDIFF_BIG(SECOND, transaction_timestamp, next_timestamp)/86400.0 AS day_interval 
FROM scenario_control
)
SELECT * FROM lead_day_interval
WHERE DATEDIFF_BIG(SECOND, transaction_timestamp, next_timestamp) <= 10800
ORDER BY CASE WHEN severity = 'High' THEN 1
            WHEN severity = 'Medium' THEN 2
            ELSE 3 END ASC,customer_id ASC,transaction_timestamp ASC, day_interval ASC;

-- S02 Overnight Population Profile
WITH scenario_customers AS
(
    SELECT DISTINCT
        sa.source_customer_id AS customer_id,
        sa.severity,
        sa.difficulty
    FROM scenario_assignments_control sa
    WHERE sa.scenario_id = 'S02'
),
customer_activity AS
(
    SELECT
        sc.customer_id,
        sc.severity,
        sc.difficulty,
        t.transaction_id,
        t.transaction_timestamp,
        t.transaction_amount
    FROM scenario_customers sc
    INNER JOIN gold.vw_transaction t
        ON t.customer_id = sc.customer_id
),
customer_profile AS
(
    SELECT
        customer_id,
        severity,
        difficulty,
        COUNT(*) AS total_transactions,
        SUM(transaction_amount) AS total_amt,
        SUM(
            CASE
                WHEN CAST(transaction_timestamp AS time) >= '23:00:00'
                  OR CAST(transaction_timestamp AS time) <= '02:00:00'
                THEN 1
                ELSE 0
            END
        ) AS overnight_transactions
    FROM customer_activity
    GROUP BY
        customer_id,
        severity,
        difficulty
)
SELECT
    customer_id,
    severity,
    difficulty,
    total_transactions,
    total_amt,
    overnight_transactions,
    ROUND(CAST(100.0*overnight_transactions AS FLOAT)
        / NULLIF(total_transactions, 0) ,3) AS overnight_share
FROM customer_profile
ORDER BY
    CASE
        WHEN severity = 'High' THEN 1
        WHEN severity = 'Medium' THEN 2
        ELSE 3
    END,
    customer_id;

-- S02 Overnight Transaction Intensity
WITH scenario_customers AS
(
    SELECT DISTINCT
        sa.source_customer_id AS customer_id,
        sa.severity,
        sa.difficulty
    FROM scenario_assignments_control sa
    WHERE sa.scenario_id = 'S02'
),
customer_activity AS
(
    SELECT
        sc.customer_id,
        sc.severity,
        sc.difficulty,
        t.transaction_id,
        t.transaction_timestamp,
        t.transaction_amount
    FROM scenario_customers sc
    INNER JOIN gold.vw_transaction t
        ON t.customer_id = sc.customer_id
),
customer_profile AS
(
    SELECT
        customer_id,
        severity,
        difficulty,
        COUNT(*) AS total_transactions,
        SUM(transaction_amount) AS total_amt,

        SUM(
            CASE
                WHEN CAST(transaction_timestamp AS time) >= '23:00:00'
                  OR CAST(transaction_timestamp AS time) <= '02:00:00'
                THEN 1
                ELSE 0
            END
        ) AS overnight_transactions,

        SUM(
            CASE
                WHEN CAST(transaction_timestamp AS time) >= '23:00:00'
                  OR CAST(transaction_timestamp AS time) <= '02:00:00'
                THEN transaction_amount
                ELSE 0
            END
        ) AS overnight_total_amt,

        MIN(
            CASE
                WHEN CAST(transaction_timestamp AS time) >= '23:00:00'
                  OR CAST(transaction_timestamp AS time) <= '02:00:00'
                THEN transaction_amount
            END
        ) AS overnight_min_amt,

        MAX(
            CASE
                WHEN CAST(transaction_timestamp AS time) >= '23:00:00'
                  OR CAST(transaction_timestamp AS time) <= '02:00:00'
                THEN transaction_amount
            END
        ) AS overnight_max_amt

    FROM customer_activity
    GROUP BY
        customer_id,
        severity,
        difficulty
),
overnight_median AS
(
    SELECT DISTINCT
        customer_id,

        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY transaction_amount)
            OVER (PARTITION BY customer_id) AS overnight_median_amt

    FROM customer_activity
    WHERE CAST(transaction_timestamp AS time) >= '23:00:00'
       OR CAST(transaction_timestamp AS time) <= '02:00:00'
)
SELECT
    cp.customer_id,
    cp.severity,
    cp.difficulty,
    cp.total_transactions,
    cp.total_amt,
    cp.overnight_transactions,

    ROUND(
        100.0 * cp.overnight_transactions
        / NULLIF(cp.total_transactions, 0),
        3
    ) AS overnight_share,

    cp.overnight_total_amt,
    ROUND(cp.overnight_min_amt, 2) AS overnight_min_amt,
    ROUND(om.overnight_median_amt, 2) AS overnight_median_amt,
    ROUND(cp.overnight_max_amt, 2) AS overnight_max_amt

FROM customer_profile cp
LEFT JOIN overnight_median om
    ON cp.customer_id = om.customer_id
ORDER BY
    CASE
        WHEN cp.severity = 'High' THEN 1
        WHEN cp.severity = 'Medium' THEN 2
        ELSE 3
    END,
    cp.customer_id;

-- BASELINE PROFILE
WITH scenario_customers AS
(
    SELECT DISTINCT
        sa.source_customer_id AS customer_id,
        sa.severity,
        sa.difficulty
    FROM scenario_assignments_control sa
    WHERE sa.scenario_id = 'S02'
)
SELECT
    sc.customer_id,
    sc.severity,
    sc.difficulty,
    t.transaction_id,
    t.transaction_timestamp,
    t.transaction_type,
    t.transaction_amount
FROM scenario_customers sc
INNER JOIN gold.vw_transaction t
    ON t.customer_id = sc.customer_id
WHERE
    CAST(t.transaction_timestamp AS time) >= '23:00:00'
    OR CAST(t.transaction_timestamp AS time) <= '02:00:00'
ORDER BY
    sc.customer_id,
    t.transaction_timestamp;


WITH s02_customers AS (
    SELECT
        synthetic_person_id,
        source_customer_id,
        severity,
        difficulty
    FROM scenario_assignments_control
    WHERE scenario_id = 'S02'
      AND source_entity = 'ananse'
),

overnight_txns AS (
    SELECT
        s.source_customer_id AS customer_id,
        s.severity,
        s.difficulty,
        t.transaction_id,
        t.transaction_timestamp,
        t.transaction_type,
        t.transaction_amount,

        LAG(t.transaction_timestamp) OVER (
            PARTITION BY t.customer_id
            ORDER BY t.transaction_timestamp
        ) AS previous_timestamp

    FROM s02_customers s
    JOIN gold.vw_transaction t
        ON t.customer_id = s.source_customer_id

    WHERE DATEPART(HOUR, t.transaction_timestamp) >= 23
       OR DATEPART(HOUR, t.transaction_timestamp) <= 5
),

temporal AS (
    SELECT
        *,
        DATEDIFF(
            SECOND,
            previous_timestamp,
            transaction_timestamp
        ) / 60.0 AS gap_minutes,

        CASE
            WHEN DATEPART(HOUR, transaction_timestamp) >= 23
                THEN CAST(transaction_timestamp AS date)
            ELSE DATEADD(
                DAY,
                -1,
                CAST(transaction_timestamp AS date)
            )
        END AS overnight_date

    FROM overnight_txns
)

SELECT
    customer_id,
    severity,
    difficulty,
    overnight_date,
    transaction_id,
    transaction_timestamp,
    transaction_type,
    transaction_amount,
    previous_timestamp,
    gap_minutes

FROM temporal

WHERE gap_minutes <= 120

ORDER BY
    customer_id,
    transaction_timestamp;



