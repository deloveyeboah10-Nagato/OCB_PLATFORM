USE [ocb_platform];
GO

/*
==================================================================================================================================
### **Task 5.1.1 — Transaction Population Profile**

Using `gold.vw_transaction`, establish:

* total transactions
* distinct customers
* distinct transaction IDs
* transaction date range
* total transaction value
* average transaction value
* transaction types
* channels
* statuses
* geographic fields available

**Deliverable:** baseline profile of the transaction population.
==================================================================================================================================
*/
-- Baseline Profile of Gold transaction population
SELECT
    COUNT(*) total_transaction_count,
    COUNT(DISTINCT vt.transaction_id) distinct_transaction_id_count,
    COUNT(DISTINCT vt.customer_id) distinct_customer_count,
    CAST(MIN(vt.transaction_timestamp) AS DATE) earliest_date,
    CAST(MAX(vt.transaction_timestamp) AS DATE) latest_date,
    CAST(SUM(vt.transaction_amount) AS DECIMAL(18, 4)) total_transaction_value,
    CAST(AVG(vt.transaction_amount) AS DECIMAL(14, 4)) average_transaction_value
FROM gold.vw_transaction vt;

-- median analysis
SELECT DISTINCT
    PERCENTILE_CONT(0.25) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS q1,
    PERCENTILE_CONT(0.5) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS median,
    PERCENTILE_CONT(0.75) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS q3,
    PERCENTILE_CONT(0.75) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () - PERCENTILE_CONT(0.25) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () iqr,
    PERCENTILE_CONT(0.90) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS q90,
    PERCENTILE_CONT(0.95) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS q95,
    PERCENTILE_CONT(0.99) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS q99,
    PERCENTILE_CONT(1) WITHIN
GROUP (
        ORDER BY transaction_amount
        ) OVER () AS maximum
FROM gold.vw_transaction

-- distinct population analysis
SELECT DISTINCT
    vt.customer_id
FROM gold.vw_transaction vt;

SELECT DISTINCT
    vt.transaction_type
FROM gold.vw_transaction vt;

SELECT DISTINCT
    vt.transaction_channel
FROM gold.vw_transaction vt;

SELECT DISTINCT
    vt.transaction_status
FROM gold.vw_transaction vt;

SELECT DISTINCT
    vt.transaction_location_region
FROM gold.vw_transaction vt;

SELECT DISTINCT
    vt.transaction_location_town
FROM gold.vw_transaction vt;

/*
P5.1.1 — Transaction Population Profile
Conclusions
The Gold transaction population has a clean one-row-per-transaction grain.
772,381 total rows.
772,381 distinct transaction IDs.
This validates the intended Gold grain.
The dataset provides a three-year transaction history.
2023-01-04 → 2025-12-31.
This gives enough temporal coverage for later behavioural and seasonal analysis.
Transaction activity covers 2,997 customers.

Transaction values are right-skewed.

Mean: ~1,689
Median: 1,145
P90: ~4,012
P95: ~5,277
P99: ~8,434
Maximum: ~19,580

The mean being substantially above the median indicates that a relatively small number of higher-value transactions pull the
average upward.
High-value transactions should not automatically be treated as suspicious.
The distribution establishes a statistical baseline. It does not establish a fraud threshold.
Intelligence relevance:
This gives us the population baseline against which later customer-level or transaction-level behaviour can be compared.

P5.1.1 conclusion:
The transaction population is structurally consistent, spans three years and 2,997 customers, and exhibits a positively skewed
transaction-value distribution. These characteristics establish the baseline population and value distribution required for
subsequent behavioural analysis.
*/
/*
==================================================================================================================================
### **Task 5.1.2 — Transaction-Type & Channel Behaviour**

Analyse transaction volume and value by:

* transaction type
* channel
* type × channel

Determine which combinations dominate activity.

**Deliverable:** transaction behaviour profile.
==================================================================================================================================
*/
-- Transaction Behaviour Profile
SELECT
    vt.transaction_type,
    COUNT(*)                   AS transaction_volume,
    SUM(vt.transaction_amount) AS transaction_value
FROM gold.vw_transaction vt
GROUP BY vt.transaction_type
ORDER BY transaction_type ASC;

SELECT
    vt.transaction_channel,
    COUNT(*)                   AS transaction_volume,
    SUM(vt.transaction_amount) AS transaction_value
FROM gold.vw_transaction vt
GROUP BY vt.transaction_channel
ORDER BY transaction_channel ASC;

SELECT
    vt.transaction_type,
    vt.transaction_channel,
    COUNT(*)                   AS transaction_volume,
    SUM(vt.transaction_amount) AS transaction_value
FROM gold.vw_transaction vt
GROUP BY vt.transaction_type,
    vt.transaction_channel
ORDER BY transaction_value DESC,
    transaction_volume DESC;

/*
P5.1.2 — Transaction-Type & Channel Behaviour
Conclusions
Transaction type is materially differentiated.
Type	Volume	Value
Cash in	256,320	323.0m
Cash out	215,433	410.8m
Merchant payment	127,558	424.9m
P2P transfer	173,070	145.5m

Volume and Value tell different stories.
For example:
Cash-in has the highest transaction volume.
Merchant payment has the highest aggregate value.
P2P has relatively high volume but substantially lower aggregate value.

Transaction type materially affects the financial profile. Channel behaviour is remarkably balanced. All eight channels have
roughly 96k–97k transactions. 
That means:
There is no obvious volume-dominant channel in this synthetic population.
And the aggregate values are similarly close.
The type × channel combinations are all represented.
All 32 combinations exist.
Intelligence relevance:
Transaction type and channel provide important contextual dimensions, but the current aggregate results do not themselves identify
suspicious behaviour.

P5.1.2 conclusion:
Transaction behaviour varies materially by transaction type, with differences between transaction volume and aggregate financial
value, while transaction channels exhibit relatively balanced activity. Transaction type therefore provides stronger behavioural
differentiation than channel at the aggregate population level, but neither dimension independently establishes anomalous
behaviour.
*/
/*
==================================================================================================================================
### **Task 5.1.3 — Transaction Status Behaviour**

Analyse:

* successful vs failed vs rejected activity
* failure rates by transaction type
* failure rates by channel
* failure concentration across customers

**Deliverable:** understanding of normal/expected failed activity.
==================================================================================================================================
*/
-- successful vs failed vs rejected activity
SELECT
    vt.transaction_status,
    COUNT(*)                              AS transaction_count,
    SUM(vt.transaction_amount)            AS transaction_amount,
    SUM(vt.transaction_amount) / COUNT(*) AS average_transaction_value
FROM gold.vw_transaction vt
GROUP BY vt.transaction_status
ORDER BY transaction_count DESC;

-- failure vs rejected rates by transaction type
SELECT
    vt.transaction_type,
    COUNT(*) AS transaction_count,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_aggregate,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_aggregate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(5, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(5, 2)) AS rejection_rate
FROM gold.vw_transaction vt
GROUP BY vt.transaction_type
ORDER BY failure_rate DESC,
    rejection_rate DESC,
    transaction_count DESC;

-- failure vs rejected rates by channel
SELECT
    vt.transaction_channel,
    COUNT(*) AS transaction_count,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_aggregate,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_aggregate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
FROM gold.vw_transaction vt
GROUP BY vt.transaction_channel
ORDER BY failure_rate DESC,
    rejection_rate DESC,
    transaction_count DESC;

-- failure vs rejected concentration across customers
WITH customer_failure_profile
AS (
    SELECT
        vt.customer_id,
        COUNT(*) AS total_transaction_count,
        SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_aggregate,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'failed'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
        SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_aggregate,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'rejected'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id
    ),
concentration_behaviour
AS (
    SELECT
        fp.customer_id,
        fp.total_transaction_count,
        SUM(fp.failed_aggregate) OVER ()                                                                       AS overall_failed_transactions,
        SUM(fp.rejected_aggregate) OVER ()                                                                     AS overall_rejected_transactions,
        fp.failed_aggregate                                                                                    AS failed_transactions,
        fp.rejected_aggregate                                                                                  AS rejected_transactions,
        fp.failure_rate,
        fp.rejection_rate,
        CAST(100.00 * fp.failed_aggregate / NULLIF(SUM(fp.failed_aggregate) OVER (), 0) AS DECIMAL(12, 2))     AS customer_failure_contribution,
        CAST(100.00 * fp.rejected_aggregate / NULLIF(SUM(fp.rejected_aggregate) OVER (), 0) AS DECIMAL(12, 2)) AS customer_rejection_contribution
    FROM customer_failure_profile fp
    )
SELECT
    customer_id,
    total_transaction_count,
    failed_transactions,
    rejected_transactions,
    failure_rate,
    rejection_rate,
    customer_failure_contribution,
    customer_rejection_contribution
FROM concentration_behaviour
ORDER BY customer_failure_contribution DESC,
    total_transaction_count DESC;

/*
P5.1.3 — Transaction Status Behaviour

Overall status distribution
Status	Count	Approx. share
Successful	727,746	94.22%
Failed	28,900	3.74%
Rejected	15,735	2.04%

An overwhelming majority of transactions are successful.Nonetheless, failed and rejected transactions still remain separate
analytical categories. Failure behaviour by transaction type is remarkably stable.
Failure rates:
Cash out: 3.75%
P2P: 3.74%
Cash in: 3.74%
Merchant payment: 3.74%

That's almost identical. The transaction type does not appear to explain much of the variation in failure rate. The same applies
to rejection rates; they're clustered around ~2%. Channel failure rates are also tightly clustered.
Approximately:3.64%–3.86%. Again, very little aggregate differentiation.
Therefore: Channel is not a strong explanation for overall failure-rate variation in this dataset. However, Customer behaviour is
completely different.
For example:
AN-C002020
790 transactions
295 failed
37.34% failure rate

Whereas another high-volume customers had:
AN-C002616
1,703 transactions
62 failed
3.64% failure rate

Failure behaviour by transaction type is remarkably stable. Failure rates:
Cash out: 3.75%
P2P: 3.74%
Cash in: 3.74%
Merchant payment: 3.74%

That's almost identical. The transaction type does not appear to explain much of the variation in failure rate. The same applies
to rejection rates; they're clustered around ~2%. Channel failure rates are also tightly clustered. Approximately: 3.64%–3.86%
Again, very little aggregate differentiation. Therefore: Channel is not a strong explanation for overall failure-rate variation
in this dataset. Customer behaviour is completely different.
For example:
AN-C002020
790 transactions
295 failed
37.34% failure rate

while other high-volume customers had:
AN-C002616
1,703 transactions
62 failed
3.64% failure rate

Both customers are active. But their failure behaviour is radically different. And then there were also low-volume customers
with high rates.
For example:
AN-C000718
55 transactions
26 failed
47.27% failure rate

There are three distinct dimensions:
transaction volume vs failure count vs failure rate
These must not be collapsed into one measure.
Customer concentration adds another layer.
The final query calculates each customer's contribution to the total failed/rejected population.
Letting us ask:
Who contributes disproportionately to the system's failed transactions? rather than merely: Who has the highest failure rate?
A customer with: 300 failures / 800 transactions and a customer with: 10 failures / 20 transactions, both have high failure rates,
but their operational significance is completely different.

P5.1.3 conclusion:
Transaction outcomes are predominantly successful, with failed and rejected transactions representing smaller but analytically
distinct populations. Failure and rejection rates are relatively stable across transaction types and channels, whereas
customer-level behaviour exhibits substantially greater variation. Some customers demonstrate both high failure volumes and
elevated failure rates, while others exhibit high rates at much lower transaction volumes. This indicates that customer-level
failure behaviour provides greater differentiation for subsequent intelligence analysis than aggregate transaction type or channel
alone.
*/
/*
==================================================================================================================================
# Phase 2 — Temporal behaviour

### **Task 5.1.4 — Time-of-Day & Day-of-Week Behaviour**

Analyse transaction activity by:
* hour
* day of week
* hour × day of week


Hourly profile
Produce one row per hour of day containing:
hour
transaction_count
transaction_value
average_transaction_value
failed_transactions
rejected_transactions
failure_rate
rejection_rate

5.1.4.2 — Day-of-week profile
Produce one row per day of week containing the same measures.

**Deliverable:** temporal baseline.
==================================================================================================================================
*/
-- Hourly Profile
SELECT
    DATEPART(HOUR, vt.transaction_timestamp) AS transaction_hour,
    COUNT(*) total_transaction_count,
    SUM(vt.transaction_amount)               AS total_transaction_value,
    AVG(vt.transaction_amount)               AS average_transaction_value,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_transactions,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_transactions,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
FROM gold.vw_transaction vt
GROUP BY DATEPART(HOUR, vt.transaction_timestamp)
ORDER BY transaction_hour;

-- Day of the Week Profile
SET DATEFIRST 1;-- Start from Monday.

SELECT
    DATEPART(WEEKDAY, vt.transaction_timestamp) AS transaction_weekday,
    COUNT(*) total_transaction_count,
    SUM(vt.transaction_amount)                  AS total_transaction_value,
    AVG(vt.transaction_amount)                  AS average_transaction_value,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_transactions,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_transactions,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
FROM gold.vw_transaction vt
GROUP BY DATEPART(WEEKDAY, vt.transaction_timestamp)
ORDER BY transaction_weekday ASC;

/*
Note:
--------------------------------------------------------------------------------------------------------------------------------
Hourly volume is strongly time-dependent
There are three broad regimes:
Hours	Approx. volume
00–05	~5.7–5.9k/hour
06–08	~20.5k/hour
09–20	~47–48k/hour
21–23	~33.1–33.5k/hour

So transaction activity is not uniformly distributed throughout the day.
That's important because a fraud-monitoring system shouldn't compare a 03:00 transaction against the same baseline as a
14:00 transaction. A transaction occurring during a low-activity period may have different contextual significance than one occurring during peak
activity. Failure behaviour is more interesting than volume. The highest hourly failure rates are:
04:00   4.4100%
00:00   4.1832%
05:00   4.0859%
01:00   3.9553%
...
23:00   3.6374%
02:00   3.1659%
03:00   3.2303%

Comparing that with the overall failure rate from P5.1.3: ~3.74%, we can see that some hours are above baseline,
particularly around midnight/early morning.
Day-of-week results are much flatter
The weekday failure rates:
Monday      3.7247%
Tuesday     3.7351%
Wednesday   3.7712%
Thursday    3.7279%
Friday      3.7227%
Saturday    3.7221%
Sunday      3.7818%

That's remarkably tight.
Highest:
Sunday = 3.7818%
Lowest:
Saturday = 3.7221%
Difference:
~0.06 percentage points.
That is not a compelling day-of-week effect based on this profile alone. Volume, however, does vary:
Monday       98,316
Tuesday      99,541
Wednesday   110,521
Thursday    109,900
Friday      109,088
Saturday    120,523
Sunday      124,492
So there's a strong difference in transaction volume, while failure rates remain relatively stable.

P5.1.4 Conclusion
-----------------------------------------------------------------------------------------------------------------------------
Transaction activity exhibits substantial intraday variation, with significantly lower volumes during
overnight/early-morning hours and sustained higher volumes during daytime/evening periods. Failure rates also vary by hour,
with elevated rates around midnight and 04:00–05:00, while weekday failure rates remain relatively stable despite differences in
transaction volume.
Major finding: time-of-day matters substantially for transaction volume.
Secondary finding: failure/rejection behaviour varies somewhat by hour, with some early-morning concentrations.
Weak finding: day-of-week appears much less important for failure behaviour.
No intelligence signal yet.
*/
/*
==================================================================================================================================
### **Task 5.1.5 — Monthly & Seasonal Behaviour**
Analyse activity across:
* month
* quarter
* year

Identify recurring patterns and major changes.
Monthly profile
One row per calendar month across the full 2023–2025 period.
Include:
year
month number
month name
transaction count
transaction value
average transaction value
failed transactions
rejected transactions
failure rate
rejection rate

Year-over-year monthly comparison
Determine whether the same calendar months behave differently across 2023, 2024 and 2025.

Seasonal profile
Aggregate the data into Q1, Q2, Q3, Q4 and compare:
volume
value
average transaction value
failure rate
rejection rate

**Deliverable:** longer-term temporal baseline.
==================================================================================================================================
*/
-- Monthly Profile
SELECT
    DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1) AS year_month,
    COUNT(*) total_transaction_count,
    SUM(vt.transaction_amount) total_transaction_value,
    AVG(vt.transaction_amount) average_transaction_value,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_transactions,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_transactions,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
FROM gold.vw_transaction vt
GROUP BY DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1)
ORDER BY year_month ASC;

-- Month-over-month comparison
WITH failure_vs_rejection_analysis
AS (
    SELECT
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1) AS year_month,
        SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'failed'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'rejected'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
    FROM gold.vw_transaction vt
    GROUP BY DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1)
    ),
month_on_month_analysis
AS (
    SELECT
        a.*,
        LAG(a.failed_transactions, 1) OVER (
            ORDER BY a.year_month ASC
            ) AS previous_month_failed_txns,
        CAST(100.00 * (
                a.failed_transactions - LAG(a.failed_transactions, 1) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.failed_transactions, 1) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS MoM_percent_change_failed_txns,
        CAST(100.00 * (
                a.rejected_transactions - LAG(a.rejected_transactions, 1) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.rejected_transactions, 1) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS MoM_percent_change_rejected_txns,
        CAST(100.00 * (
                a.failure_rate - LAG(a.failure_rate, 1) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.failure_rate, 1) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS MoM_percent_change_failure_rate,
        CAST(100.00 * (
                a.rejection_rate - LAG(a.rejection_rate, 1) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.rejection_rate, 1) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS MoM_percent_change_rejection_rate
    FROM failure_vs_rejection_analysis a
    )
SELECT
    mma.year_month,
    mma.failed_transactions,
    mma.failure_rate,
    mma.MoM_percent_change_failed_txns,
    mma.MoM_percent_change_failure_rate,
    CASE 
        WHEN mma.MoM_percent_change_failure_rate > 0
            THEN 'Increase'
        WHEN mma.MoM_percent_change_failure_rate < 0
            THEN 'Decrease'
        ELSE 'No Change'
        END AS failure_rate_flag,
    mma.rejected_transactions,
    mma.rejection_rate,
    mma.MoM_percent_change_rejected_txns,
    mma.MoM_percent_change_rejection_rate,
    CASE 
        WHEN mma.MoM_percent_change_rejection_rate > 0
            THEN 'Increase'
        WHEN mma.MoM_percent_change_rejection_rate < 0
            THEN 'Decrease'
        ELSE 'No Change'
        END AS rejection_rate_flag
FROM month_on_month_analysis mma
ORDER BY year_month ASC;

-- Year-on-year monthly analysis
WITH failure_vs_rejection_analysis
AS (
    SELECT
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1) AS year_month,
        SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'failed'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
        CAST(100.00 * SUM(CASE vt.transaction_status
                    WHEN 'rejected'
                        THEN 1
                    ELSE 0
                    END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
    FROM gold.vw_transaction vt
    GROUP BY DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1)
    ),
year_on_year_analysis
AS (
    SELECT
        a.*,
        LAG(a.failed_transactions, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS previous_year_failed_txns,
        LAG(a.rejected_transactions, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS previous_year_rejected_txns,
        LAG(a.failure_rate, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS previous_year_failure_rate,
        LAG(a.rejection_rate, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS previous_year_rejection_rate,
        CAST(100.00 * (
                a.failed_transactions - LAG(a.failed_transactions, 12) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.failed_transactions, 12) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS YoY_percent_change_failed_txns,
        CAST(100.00 * (
                a.rejected_transactions - LAG(a.rejected_transactions, 12) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.rejected_transactions, 12) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS YoY_percent_change_rejected_txns,
        a.failure_rate - LAG(a.failure_rate, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS YoY_pp_change_failure_rate,
        a.rejection_rate - LAG(a.rejection_rate, 12) OVER (
            ORDER BY a.year_month ASC
            ) AS YoY_pp_change_rejection_rate,
        CAST(100.00 * (
                a.failure_rate - LAG(a.failure_rate, 12) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.failure_rate, 12) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS YoY_percent_change_failure_rate,
        CAST(100.00 * (
                a.rejection_rate - LAG(a.rejection_rate, 12) OVER (
                    ORDER BY a.year_month ASC
                    )
                ) / NULLIF(LAG(a.rejection_rate, 12) OVER (
                    ORDER BY a.year_month ASC
                    ), 0) AS DECIMAL(12, 2)) AS YoY_percent_change_rejection_rate
    FROM failure_vs_rejection_analysis a
    )
SELECT
    yya.year_month,
    yya.previous_year_failed_txns,
    yya.failed_transactions,
    yya.previous_year_failure_rate,
    yya.failure_rate,
    yya.YoY_percent_change_failed_txns,
    yya.YoY_percent_change_failure_rate,
    yya.YoY_pp_change_failure_rate,
    yya.previous_year_rejected_txns,
    yya.rejected_transactions,
    yya.previous_year_rejection_rate,
    yya.rejection_rate,
    yya.YoY_percent_change_rejected_txns,
    yya.YoY_percent_change_rejection_rate,
    yya.YoY_pp_change_rejection_rate
FROM year_on_year_analysis yya
ORDER BY year_month ASC;

-- Seasonal profile
SELECT
    DATEPART(QUARTER, vt.transaction_timestamp) AS quarter,
    COUNT(*)                                    AS total_transaction_count,
    SUM(vt.transaction_amount)                  AS total_transaction_value,
    AVG(vt.transaction_amount)                  AS average_transaction_value,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_transactions,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_transactions,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS failure_rate,
    CAST(100.00 * SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) / COUNT(*) AS DECIMAL(12, 2)) AS rejection_rate
FROM GOLD.vw_transaction vt
GROUP BY DATEPART(QUARTER, vt.transaction_timestamp)
ORDER BY quarter ASC;

/*
# P5.1.5 — Monthly & Seasonal Behaviour

Note
----------------------------------------------------------------------------------------------------------------------------------
Transaction activity increased substantially across the three-year observation period, with transaction volume and total
transaction value rising over time.Monthly transaction volume showed a strong upward trend, with December consistently
representing a high-activity period. Average transaction value remained relatively stable throughout the period, indicating that
growth in total transaction value was driven primarily by increased transaction volume rather than major changes in average
transaction size.
Monthly failure and rejection counts increased alongside overall transaction volume; therefore, absolute outcome counts must be
interpreted together with their corresponding rates. Monthly failure rates remained broadly stable despite substantial transaction
population growth. Rejection rates also remained within a relatively narrow range, although individual months showed some variation.
Month-over-month analysis identified short-term fluctuations in transaction outcomes but did not by itself establish persistent
deterioration.
Quarterly analysis showed clear growth from Q1 through Q4, with Q4 recording the highest transaction volume and value.The quarterly
seasonal profile confirmed that Q4 activity was substantially higher than Q1, while average transaction value changed only
modestly. Quarterly failure rates remained stable at approximately 3.7–3.8%, while rejection rates remained approximately
2.0–2.1%. Therefore, higher quarterly activity was not accompanied by a comparable deterioration in transaction outcomes.
Year-over-year analysis showed large increases in absolute failed and rejected transactions, particularly during 2024 and 2025.
However, failure and rejection rates generally changed much less than the corresponding transaction counts. YoY percentage changes
based on very small early-period baselines can be disproportionately large and should therefore be interpreted cautiously.
Percentage change in a rate and percentage-point change in a rate represent different analytical measures and should not be
treated as interchangeable. Temporal increases in transaction activity do not independently establish fraud, operational failure,
or financial risk. They provide a baseline for identifying deviations in subsequent behavioural analysis.

Conclusion
---------------------------------------------------------------------------------------------------------------------------------
The transaction population exhibits strong temporal growth and clear quarterly seasonality in transaction activity and value,
particularly during Q4. However, average transaction values and transaction outcome rates remain comparatively stable as the
population expands.
The increase in absolute failed and rejected transactions is therefore largely consistent with overall
transaction growth rather than evidence of equivalent deterioration in transaction performance.
*/
/*
==================================================================================================================================
## P5.1.6 — Customer Temporal Behaviour

### Objective
Analyse **how individual customers behave over time**, rather than only looking at population-level temporal trends.

### Your task
Using `gold.vw_transaction`, investigate customer-level temporal behaviour across the 2023–2025 period.

Your analysis should establish:
1. **Customer activity span**
2. **Transaction frequency over time**
3. **Customer activity consistency**
4. **Customer transaction value behaviour**
5. **Customer outcome behaviour**

### Analytical question
> **Which customers demonstrate unusually concentrated, persistent, or changing transaction activity over time?**

**Deliverable:** customer-level temporal baseline.
==================================================================================================================================
*/
-- Customer activity span
SELECT
    vt.customer_id,
    CAST(MIN(vt.transaction_timestamp) AS DATE)                                                 AS first_transaction_date,
    CAST(MAX(vt.transaction_timestamp) AS DATE)                                                 AS last_transaction_date,
    COUNT(DISTINCT DATETRUNC(MONTH, vt.transaction_timestamp))                                  AS active_mths,
    COUNT(DISTINCT DATETRUNC(HOUR, vt.transaction_timestamp))                                   AS active_hrs,
    DATEDIFF_BIG(SECOND, MIN(vt.transaction_timestamp), MAX(vt.transaction_timestamp)) / 3600.0 AS elapsed_hours
FROM gold.vw_transaction vt
GROUP BY vt.customer_id
ORDER BY first_transaction_date ASC,
    last_transaction_date ASC,
    elapsed_hours DESC;

-- Total transactions per customer
SELECT
    vt.customer_id,
    COUNT(*) AS total_transactions_per_customer
FROM gold.vw_transaction vt
GROUP BY vt.customer_id
ORDER BY total_transactions_per_customer DESC;

-- Identify customers with concentrated versus sustained activity
SELECT
    z.customer_id,
    z.total_transaction_count,
    z.active_months,
    z.transaction_lifespan_months,
    ROUND(CAST(z.active_months AS FLOAT) / NULLIF(z.transaction_lifespan_months, 0), 2) activity_intensity_ratio,
    ROUND(CAST(z.total_transaction_count AS FLOAT) / NULLIF(z.active_months, 0), 2) transaction_density_ratio
FROM (
    SELECT
        vt.customer_id,
        DATEDIFF(MONTH, CAST(MIN(vt.transaction_timestamp) AS DATE), CAST(MAX(vt.transaction_timestamp) AS DATE)) + 1 AS transaction_lifespan_months,
        COUNT(DISTINCT DATETRUNC(MONTH, vt.transaction_timestamp))                                                    AS active_months,
        COUNT(*)                                                                                                      AS total_transaction_count
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id
    ) z

-- Customer transaction value behaviour
SELECT
    vt.customer_id,
    COUNT(*)                   AS total_transaction_count,
    SUM(vt.transaction_amount) AS total_transaction_value,
    AVG(vt.transaction_amount) AS average_transaction_value
FROM gold.vw_transaction vt
GROUP BY vt.customer_id
ORDER BY total_transaction_value DESC,
    average_transaction_value DESC;

-- Customer outcome behaviour
WITH customer_outcome_analytics
AS (
    SELECT
        vt.customer_id,
        COUNT(*) AS total_transaction_count,
        SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS failed_transactions,
        ROUND(CAST(100.00 * SUM(CASE vt.transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 2) AS failure_rate,
        SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS rejected_transactions,
        ROUND(CAST(100.00 * SUM(CASE vt.transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 2) AS rejection_rate
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id
    )
SELECT
    *
FROM customer_outcome_analytics;

-- temporal customer behaviour change (count, sum and average)
WITH customer_monthly_transaction_profile
AS (
    SELECT
        vt.customer_id,
        DATETRUNC(MONTH, vt.transaction_timestamp) AS current_year_month,
        COUNT(*)                                   AS current_month_txns,
        SUM(vt.transaction_amount) current_month_total_value,
        AVG(vt.transaction_amount) current_month_avg_value
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        DATETRUNC(MONTH, vt.transaction_timestamp)
    )
SELECT
    tp.customer_id,
    tp.current_year_month,
    tp.current_month_txns,
    LAG(tp.current_month_txns, 1) OVER (
        PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
        ) AS previous_month_txns,
    ROUND(tp.current_month_txns - LAG(tp.current_month_txns, 1) OVER (
            PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
            ), 2) AS txn_pt_chg,
    tp.current_month_total_value,
    LAG(tp.current_month_total_value, 1) OVER (
        PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
        ) AS previous_month_total_value,
    ROUND(tp.current_month_total_value - LAG(tp.current_month_total_value, 1) OVER (
            PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
            ), 2) AS total_value_pt_chg,
    tp.current_month_avg_value,
    LAG(tp.current_month_avg_value, 1) OVER (
        PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
        ) AS previous_month_avg_value,
    ROUND(tp.current_month_avg_value - LAG(tp.current_month_avg_value, 1) OVER (
            PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
            ), 2) AS avg_value_pt_chg
FROM customer_monthly_transaction_profile tp
ORDER BY tp.customer_id ASC,
    current_year_month ASC;

-- temporal customer behaviour change (failed and rejected)
WITH customer_monthly_transaction_profile
AS (
    SELECT
        vt.customer_id,
        DATETRUNC(MONTH, vt.transaction_timestamp) AS current_year_month,
        SUM(CASE vt.transaction_status
                WHEN 'failed'
                    THEN 1
                ELSE 0
                END) AS current_month_failed_txns,
        ROUND(CAST(100.00 * SUM(CASE vt.transaction_status
                        WHEN 'failed'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 2) AS current_month_failure_rate,
        SUM(CASE vt.transaction_status
                WHEN 'rejected'
                    THEN 1
                ELSE 0
                END) AS current_month_rejected_txns,
        ROUND(CAST(100.00 * SUM(CASE vt.transaction_status
                        WHEN 'rejected'
                            THEN 1
                        ELSE 0
                        END) AS FLOAT) / COUNT(*), 2) AS current_month_rejection_rate
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        DATETRUNC(MONTH, vt.transaction_timestamp)
    )
SELECT
    tp.customer_id,
    tp.current_year_month,
    tp.current_month_failed_txns,
    tp.current_month_failure_rate,
    LAG(tp.current_month_failure_rate, 1) OVER (
        PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
        ) AS previous_month_failure_rate,
    ROUND(tp.current_month_failure_rate - LAG(tp.current_month_failure_rate, 1) OVER (
            PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
            ), 2) AS failure_rate_pt_change,
    tp.current_month_rejected_txns,
    tp.current_month_rejection_rate,
    LAG(tp.current_month_rejection_rate, 1) OVER (
        PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
        ) AS previous_month_rejection_rate,
    ROUND(tp.current_month_rejection_rate - LAG(tp.current_month_rejection_rate, 1) OVER (
            PARTITION BY tp.customer_id ORDER BY tp.current_year_month ASC
            ), 2) AS rejection_rate_pt_change
FROM customer_monthly_transaction_profile tp
ORDER BY customer_id ASC,
    current_year_month ASC;

/*
# P5.1.6 — Customer temporal Behaviour

Note
---------------------------------------------------------------------------------------------------------------------------------
Customer activity spans vary substantially. Some customers show sustained activity across most of their observed period, while
others transact during shorter or more concentrated periods. Active-month intensity distinguishes customers with continuous
activity from those whose transactions are concentrated into a smaller portion of their observed activity span. Transaction
density also varies materially between customers. High transaction counts are therefore not uniformly distributed across the
customer population.
Customer transaction value differs from transaction frequency. Customers with similar transaction counts can
generate materially different total transaction values because of differences in average transaction size. Customer-level failure
and rejection behaviour varies considerably more than the aggregate population rates observed earlier. Some customers exhibit
consistently low outcome rates, while others show isolated or repeated periods of elevated failures or rejections.
Monthly temporal comparisons reveal changes in customer behaviour that are not visible from cumulative customer totals alone.
Customers can experience sharp increases or decreases in transaction frequency, total transaction value, and average transaction
value between observed months.
Changes in failure and rejection rates can also be substantial. However, large rate changes can result from very
small monthly transaction volumes. Rate changes must therefore be interpreted together with the underlying transaction count.The
temporal comparison uses the previous observed customer month. Where a customer has no transactions in an intervening calendar
month, `LAG()` compares the current month with the previous available customer-month observation. Dormancy and reactivation are
treated separately in the later dedicated workload.
No fraud or risk threshold is assigned at this stage. The purpose of this
workload is to establish customer-level temporal behaviour that can later support intelligence signal design.

Conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Customer-level temporal analysis demonstrates substantial variation in how customers use the transaction system over time.
Customers differ not only in their overall transaction frequency and value, but also in the continuity, intensity, and direction
of their activity.
Monthly comparison further shows that customer behaviour can change materially between observed periods. Increases in transaction
frequency do not necessarily correspond to increases in average transaction value, while changes in failure and rejection rates
can occur independently of transaction-volume changes.
The analysis therefore establishes an important baseline for later financial intelligence: customer behaviour must be evaluated
across multiple dimensions and over time rather than through cumulative transaction totals alone.
Transaction volume, transaction value, average transaction size, and outcome behaviour provide complementary signals, while the
magnitude and persistence of changes require contextual interpretation before they can be treated as intelligence indicators.
*/
/*
==================================================================================================================================
## P5.1.7 — Transaction Frequency

### Your task
Using `gold.vw_transaction`, produce a customer-level frequency profile containing:

1. `customer_id`
2. Total transaction count
3. Observed activity span in days
4. Average transactions per active day
5. Maximum transactions in a single day
6. Number of distinct active days

Investigate the distribution of transaction frequency across customers.

### Deliverable: frequency baseline.

Include the **top 10 customers by maximum transactions in a single day**, and their other frequency metrics.
==================================================================================================================================
*/
WITH customer_daily_txns
AS (
    SELECT
        vt.customer_id,
        CAST(vt.transaction_timestamp AS DATE) _day_,
        COUNT(*) AS daily_txns
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        CAST(vt.transaction_timestamp AS DATE)
    ),
transaction_frequency_metrics
AS (
    SELECT
        dt.customer_id,
        SUM(dt.daily_txns) OVER (PARTITION BY dt.customer_id) AS total_transaction_count,
        MAX(dt.daily_txns) OVER (PARTITION BY dt.customer_id) AS max_txns_per_day,
        (DATEDIFF(DAY, MIN(dt._day_) OVER (PARTITION BY dt.customer_id), MAX(dt._day_) OVER (PARTITION BY dt.customer_id))) + 1 calendar_span_days,
        COUNT(dt._day_) OVER (PARTITION BY dt.customer_id)    AS active_days,
        ROUND(CAST(SUM(dt.daily_txns) OVER (PARTITION BY dt.customer_id) AS FLOAT) / COUNT(dt._day_) OVER (PARTITION BY dt.customer_id), 2) avg_txns_per_active_day,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id ORDER BY customer_id
            ) rank_
    FROM customer_daily_txns dt
    )
SELECT TOP 10
    fm.customer_id,
    fm.total_transaction_count,
    fm.avg_txns_per_active_day,
    fm.max_txns_per_day,
    fm.calendar_span_days,
    fm.active_days
FROM transaction_frequency_metrics fm
WHERE rank_ = 1
--ORDER BY avg_txns_per_active_day DESC;
ORDER BY max_txns_per_day DESC;

/*
# P5.1.7 — Transaction Frequency

Note
---------------------------------------------------------------------------------------------------------------------------------
Customer transaction frequency varies substantially across the population. Total transaction counts identify customers with
high overall activity, but do not describe how that activity is distributed across the customer's observed period. Active days
and calendar span provide additional context for distinguishing sustained activity from more concentrated activity.
Average transactions per active day also varies between customers. Some customers maintain relatively high transaction frequency
across a large number of active days, while others generate a similar total number of transactions across fewer active days.
Maximum transactions per day provides a further distinction by identifying the highest level of daily concentration for each
customer
The comparison between average transactions per active day and maximum transactions per day shows that sustained frequency and
peak daily activity are not necessarily exhibited by the same customers. A customer can have a relatively ordinary average daily
frequency while producing a substantially higher transaction count on an individual day. Conversely, a customer can maintain a
relatively high average frequency without having the highest single-day peak.
Calendar span and active days therefore provide important context when interpreting transaction frequency. A high total transaction
count does not necessarily indicate unusually frequent behaviour, just as a high maximum daily count does not necessarily represent
sustained activity.
No fraud or risk threshold is assigned at this stage. The purpose of this workload is to establish a customer-level
transaction-frequency baseline and distinguish overall, sustained, and peak daily activity before examining shorter time-window
transaction velocity.

Conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Customer-level transaction frequency demonstrates meaningful variation in how transaction activity is distributed across the
observed population. Total transaction count, average transactions per active day, and maximum transactions per day capture
different aspects of customer activity and should not be treated as interchangeable measures.
The results show that customers with the highest average transaction frequency are not necessarily the customers with the highest
single-day transaction peaks. This demonstrates that cumulative frequency can conceal concentrated daily activity, while a single
daily peak does not establish sustained high-frequency behaviour.
The analysis therefore establishes transaction frequency as a multi-dimensional behavioural measure. Total activity, active-day
coverage, average daily frequency, and maximum daily frequency provide complementary views of customer behaviour and establish
the baseline for the subsequent transaction-velocity analysis.
*/
/*
===================================================================================================================================
### **Task 5.1.8 — Transaction Velocity**

Analyse the time between successive transactions for the same customer.
Determine:
* typical inter-transaction intervals
* unusually short intervals
* transaction clustering
For each customer, determine:
customer_id
The maximum number of transactions occurring within any 10-minute window
The timestamp/window associated with that maximum, where practical

**Ground truth:** **S01 — High Transaction Velocity**

**Deliverable:** evidence-based velocity analysis.
==================================================================================================================================
*/
-- inter-transaction intervals
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        LAG(vt.transaction_timestamp) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS previous_txn_timestamp,
        vt.transaction_timestamp AS current_txn_timestamp
    FROM gold.vw_transaction vt
    ),
txn_interval
AS (
    SELECT
        customer_id,
        previous_txn_timestamp,
        current_txn_timestamp,
        DATEDIFF_BIG(SECOND, previous_txn_timestamp, current_txn_timestamp) AS interval_seconds
    FROM ordered_txns
    WHERE previous_txn_timestamp IS NOT NULL
    )
SELECT
    customer_id,
    MIN(interval_seconds) / 3600.0 AS min_txn_interval_hrs,
    MAX(interval_seconds) / 3600.0 AS max_txn_interval_hrs,
    AVG(interval_seconds) / 3600.0 AS avg_txn_interval_hrs
FROM txn_interval
GROUP BY customer_id
ORDER BY min_txn_interval_hrs ASC;

-- transaction clustering
WITH customer_txns
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp
    FROM gold.vw_transaction vt
    ),
ten_minute_windows
AS (
    SELECT
        t1.customer_id,
        t1.transaction_timestamp AS window_start,
        COUNT(*)                 AS transactions_in_10min
    FROM customer_txns t1
    JOIN customer_txns t2 ON
            t1.customer_id = t2.customer_id
                AND t2.transaction_timestamp >= t1.transaction_timestamp
                AND t2.transaction_timestamp <= DATEADD(MINUTE, 10, t1.transaction_timestamp)
    GROUP BY t1.customer_id,
        t1.transaction_timestamp
    )
SELECT
    customer_id,
    MAX(transactions_in_10min) AS max_txns_in_10min
FROM ten_minute_windows
GROUP BY customer_id
ORDER BY max_txns_in_10min DESC,
    customer_id ASC;

/*
# P5.1.8 — Transaction Velocity.

Note
---------------------------------------------------------------------------------------------------------------------------------
Transaction velocity varies substantially across customers. Inter-transaction interval analysis shows that the time separating
consecutive transactions ranges from effectively simultaneous activity to periods spanning hundreds or thousands of hours.
Several customers recorded minimum intervals of zero seconds, while others recorded minimum intervals of only a few seconds,
demonstrating that very rapid consecutive transaction activity exists within the population.
Minimum, average, and maximum intervals provide different views of customer behaviour. A customer can have an extremely short
minimum interval while maintaining a much longer average interval across their transaction history. Rapid individual transactions
therefore do not necessarily indicate consistently high transaction velocity.
Transaction clustering further identifies periods where transaction activity becomes concentrated within a 10-minute period. The
highest observed concentration was four transactions within 10 minutes, with several customers recording three transactions and
many recording two. This complements the inter-transaction analysis by showing not only how quickly individual transactions can
occur, but also how multiple transactions can become concentrated within a short period.
The results distinguish transaction velocity from the transaction frequency analysed in P5.1.7. Frequency describes how often
customers transact across their activity history, while velocity examines how closely transactions occur in time.
No fraud or risk threshold is assigned at this stage. The purpose of this workload is to establish the temporal characteristics
of transaction activity that can later support S01 High Transaction Velocity signal development.

Conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Customer transaction velocity demonstrates meaningful variation across the population. Transactions can occur within seconds of
one another, while customers may also experience long intervals between transactions across their wider activity history.
The clustering analysis confirms that short periods of concentrated transaction activity occur across the population, with up to
four transactions observed within a 10-minute window.
The analysis therefore establishes transaction velocity as a distinct behavioural dimension from overall transaction frequency.
Inter-transaction intervals and short-period clustering provide complementary views of rapid transaction activity and establish a
baseline for subsequent financial intelligence analysis.
*/
/*
===================================================================================================================================
### Work package task
P5.1.9 — Unusual-Hour Behaviour
Analyze whether customers exhibit transaction activity during **unusual hours**, using the transaction timestamp.

The analysis should establish:

1. **Hourly transaction distribution**
2. **Customer unusual-hour activity**
3. **Compare unusual-hour activity with normal-hour activity**

===================================================================================================================================
*/
-- Hourly transaction distribution 
WITH txns_by_hr
AS (
    SELECT
        DATEPART(HOUR, vt.transaction_timestamp) AS date_hour,
        COUNT(*)                                 AS total_txn_count_by_hr,
        SUM(vt.transaction_amount)               AS total_txn_value_by_hr
    FROM gold.vw_transaction vt
    GROUP BY DATEPART(HOUR, vt.transaction_timestamp)
    )
SELECT
    *,
    SUM(total_txn_count_by_hr) OVER () total_txns,
    ROUND(CAST(total_txn_count_by_hr AS FLOAT) / SUM(total_txn_count_by_hr) OVER (), 4) AS activity_proportion_by_hr
FROM txns_by_hr
ORDER BY total_txn_value_by_hr DESC;

-- Hourly analysis by hour-family
WITH txns_by_hr
AS (
    SELECT
        DATETRUNC(HOUR, vt.transaction_timestamp) AS date_hour,
        COUNT(*)                                  AS total_txn_count_by_hr,
        SUM(vt.transaction_amount)                AS total_txn_value_by_hr
    FROM gold.vw_transaction vt
    GROUP BY DATETRUNC(HOUR, vt.transaction_timestamp)
    )
SELECT
    *,
    SUM(total_txn_count_by_hr) OVER (PARTITION BY DATEPART(HOUR, date_hour))                         AS total_txns_for_clock_hour,
    AVG(total_txn_count_by_hr) OVER (PARTITION BY DATEPART(HOUR, date_hour))                         AS avg_txns_for_clock_hour,
    total_txn_count_by_hr - AVG(total_txn_count_by_hr) OVER (PARTITION BY DATEPART(HOUR, date_hour)) AS txn_deviation_from_hour_avg
FROM txns_by_hr
ORDER BY date_hour;

-- Customer unusual-hour activity thats below the average
WITH hourly_volume
AS (
    SELECT
        DATEPART(HOUR, vt.transaction_timestamp) AS date_hour,
        COUNT(*)                                 AS txns_by_hr
    FROM gold.vw_transaction vt
    GROUP BY DATEPART(HOUR, vt.transaction_timestamp)
    ),
dynamic_threshold
AS (
    SELECT
        date_hour
    FROM hourly_volume
    WHERE txns_by_hr < (
            SELECT
                AVG(txns_by_hr)
            FROM hourly_volume
            )
    )
SELECT
    vt.customer_id,
    dt.date_hour AS unusual_hour,
    COUNT(*)     AS unusual_txns
FROM dynamic_threshold dt
LEFT JOIN gold.vw_transaction vt ON
        dt.date_hour = DATEPART(HOUR, vt.transaction_timestamp)
GROUP BY vt.customer_id,
    dt.date_hour
ORDER BY customer_id ASC,
    unusual_txns DESC;

-- Customer unusual-hour activity thats above the average
WITH hourly_volume
AS (
    SELECT
        DATEPART(HOUR, vt.transaction_timestamp) AS date_hour,
        COUNT(*)                                 AS txns_by_hr
    FROM gold.vw_transaction vt
    GROUP BY DATEPART(HOUR, vt.transaction_timestamp)
    ),
dynamic_threshold
AS (
    SELECT
        date_hour
    FROM hourly_volume
    WHERE txns_by_hr > (
            SELECT
                AVG(txns_by_hr)
            FROM hourly_volume
            )
    )
SELECT
    vt.customer_id,
    dt.date_hour AS unusual_hour,
    COUNT(*)     AS unusual_txns
FROM dynamic_threshold dt
LEFT JOIN gold.vw_transaction vt ON
        dt.date_hour = DATEPART(HOUR, vt.transaction_timestamp)
GROUP BY vt.customer_id,
    dt.date_hour
ORDER BY customer_id ASC,
    unusual_txns DESC;

-- Customer unusual-hour activity thats below each customer's top 5 normal frequency
WITH txn_frequency_rank
AS (
    SELECT
        vt.customer_id,
        DATEPART(HOUR, vt.transaction_timestamp) AS date_hour,
        COUNT(*)                                 AS txn_volume,
        RANK() OVER (
            PARTITION BY vt.customer_id ORDER BY COUNT(*) DESC
            ) AS hr_rank
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        DATEPART(HOUR, vt.transaction_timestamp)
    ),
unusual_frequency_hours
AS (
    SELECT
        *
    FROM txn_frequency_rank
    WHERE hr_rank > 5
    )
SELECT
    fh.customer_id,
    COUNT(*) total_unusual_txns
FROM unusual_frequency_hours fh
LEFT JOIN gold.vw_transaction vt ON
        fh.customer_id = vt.customer_id
            AND fh.date_hour = DATEPART(HOUR, vt.transaction_timestamp)
GROUP BY fh.customer_id
ORDER BY customer_id;

/*
----------------------------------------------------------------------------------------------------------------------------------
Note
----------------------------------------------------------------------------------------------------------------------------------
Transaction activity varies substantially across the 24-hour period. The hourly population profile shows that transaction volumes
are highest during the daytime and evening hours, particularly between approximately 17:00 and 20:00. Activity declines noticeably
during the late evening and early morning periods, with the lowest volumes occurring between approximately 00:00 and 05:00.
The hourly distribution therefore establishes a clear baseline for normal population-level transaction activity by clock hour.
The difference between high-volume daytime hours and low-volume overnight hours is substantial, indicating that transaction timing
is an important behavioural dimension within the dataset.
The analysis was also extended to the calendar-date and clock-hour level, allowing each individual hourly observation to be
compared with other observations belonging to the same clock-hour family. This provides a more appropriate reference than comparing
every hour against a single population-wide average, because each clock hour has its own typical level of activity.
Deviation from the clock-hour average provides an additional descriptive view of whether a particular date-hour observation was
above or below the activity normally observed for that clock hour. This helps identify periods of elevated or reduced activity
relative to their own temporal baseline, although the deviation is not treated as a fraud or risk threshold.
Customer-level profiling further shows that activity occurring during lower-volume and higher volume_hours on beyond a baseline
average can represent a substantial portion of an individual customers' transaction histories. However, this doesnt mean that
population-level volume hours should automatically be interpreted as unusual behaviour for every customer.
The analysis therefore distinguishes between **low and high population activity by clock hour** and **unusual activity for an
individual customer**. A clock hour may be relatively quiet across the overall population while still representing normal behaviour
for a particular customer.
The purpose of this workload is to establish the temporal baseline and identify how transaction activity is distributed across
clock hours. More detailed customer-specific unusual-hour detection can be developed later as part of the formal signal
analysis.
---------------------------------------------------------------------------------------------------------------------------------
## Conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Transaction activity follows a clear intraday pattern, with substantially higher volumes during daytime and evening hours and
materially lower activity during the early-morning period.
Comparing each calendar-hour observation with its own clock-hour history provides a useful descriptive baseline for identifying
periods of relatively elevated or reduced activity without confusing naturally low-volume hours with abnormal behaviour.
The analysis establishes transaction timing as an important behavioural dimension and provides the temporal baseline required for
subsequent Unusual-Hour Behaviour signal development.
*/
/*
=====================================================================================================================================
### **Task 5.1.10 — Dormancy & Reactivation**

**Ground truth:** **S04 — Dormant Customer Reactivation**

**Objective:**
Analyse periods of inactivity in customer transaction behaviour and examine what happens when customers resume
activity after those periods.

### Workload
1. **Customer Transaction Gaps**
2. **Dormancy Periods**
3. **Reactivation Behaviour**
4. **Before vs After Reactivation**

==================================================================================================================================
*/
-- Customer Transaction Gaps
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        LAG(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS previous_txn_timestamp,
        vt.transaction_timestamp AS current_txn_timestamp
    FROM gold.vw_transaction vt
    ),
txn_gap_hrs
AS (
    SELECT
        customer_id,
        previous_txn_timestamp,
        current_txn_timestamp,
        DATEDIFF_BIG(SECOND, previous_txn_timestamp, current_txn_timestamp) / 3600.0 AS txn_gap_hrs
    FROM ordered_txns
    )
-- Dormancy Periods
SELECT DISTINCT
    customer_id,
    MIN(txn_gap_hrs) OVER (PARTITION BY customer_id) AS min_txn_gap_hrs,
    MAX(txn_gap_hrs) OVER (PARTITION BY customer_id) AS max_txn_gap_hrs,
    AVG(txn_gap_hrs) OVER (PARTITION BY customer_id) AS avg_txn_gap_hrs,
    PERCENTILE_CONT(0.99) WITHIN
GROUP (
        ORDER BY txn_gap_hrs
        ) OVER (PARTITION BY customer_id) AS p99_txn_gap_hrs,
    COUNT(*) OVER (PARTITION BY customer_id) AS gap_total
FROM txn_gap_hrs;
GO

-- Reactivation Behaviour
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp AS current_txn_timestamp,
        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_timestamp,
        LEAD(vt.transaction_amount, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_amt,
        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_type,
        LEAD(vt.transaction_channel, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_channel,
        LEAD(vt.transaction_status, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_status
    FROM gold.vw_transaction vt
    ),
txn_gap_hrs
AS (
    SELECT
        customer_id,
        current_txn_timestamp,
        DATEDIFF_BIG(SECOND, current_txn_timestamp, reactivation_txn_timestamp) / 3600.0 AS reactivation_txn_gap_hrs,
        reactivation_txn_timestamp,
        reactivation_txn_amt,
        reactivation_txn_type,
        reactivation_txn_channel,
        reactivation_txn_status
    FROM ordered_txns
    ),
reactivation_threshold
AS -- P99 is used as a data-derived baseline to identify extended transaction gaps for further reactivation analysis.
    (
    SELECT DISTINCT
        customer_id,
        reactivation_txn_timestamp,
        --PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY reactivation_txn_gap_hrs ASC) OVER() AS p90,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY reactivation_txn_gap_hrs ASC
            ) OVER (PARTITION BY YEAR(reactivation_txn_timestamp)) AS p99
    FROM txn_gap_hrs
    ),
comparison_metrics
AS (
    SELECT
        customer_id,
        reactivation_txn_timestamp,
        p99,
        MIN(p99) OVER () AS min_p99,
        MAX(p99) OVER () AS max_p99,
        AVG(p99) OVER () AS avg_p99
    FROM reactivation_threshold
    ),
reactivation_txn_profile
AS (
    SELECT
        gh.customer_id,
        gh.current_txn_timestamp,
        gh.reactivation_txn_gap_hrs,
        cm.p99,
        cm.avg_p99,
        cm.min_p99,
        cm.max_p99,
        gh.reactivation_txn_timestamp,
        gh.reactivation_txn_amt,
        gh.reactivation_txn_type,
        gh.reactivation_txn_channel,
        gh.reactivation_txn_status
    FROM txn_gap_hrs gh
    LEFT JOIN comparison_metrics cm ON
            gh.customer_id = cm.customer_id
                AND gh.reactivation_txn_timestamp = cm.reactivation_txn_timestamp
    WHERE gh.reactivation_txn_gap_hrs >= cm.p99
    )
SELECT
    *
FROM reactivation_txn_profile;

-- Before vs After Reactivation (transaction_amount, transaction type,transaction_channel,transaction_status)
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp AS previous_txn_timestamp,
        vt.transaction_amount    AS previous_txn_amt,
        vt.transaction_type      AS previous_txn_type,
        vt.transaction_channel   AS previous_txn_channel,
        vt.transaction_status    AS previous_txn_status,
        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_timestamp,
        LEAD(vt.transaction_amount, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_amt,
        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_type,
        LEAD(vt.transaction_channel, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_channel,
        LEAD(vt.transaction_status, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS reactivation_txn_status
    FROM gold.vw_transaction vt
    ),
txn_gap_hrs
AS (
    SELECT
        customer_id,
        previous_txn_timestamp,
        previous_txn_amt,
        previous_txn_type,
        previous_txn_channel,
        previous_txn_status,
        DATEDIFF_BIG(SECOND, previous_txn_timestamp, reactivation_txn_timestamp) / 3600.0 AS reactivation_txn_gap_hrs,
        reactivation_txn_timestamp,
        reactivation_txn_amt,
        reactivation_txn_type,
        reactivation_txn_channel,
        reactivation_txn_status
    FROM ordered_txns
    ),
reactivation_threshold
AS -- P99 is used as a data-derived baseline to identify extended transaction gaps for further reactivation analysis.
    (
    SELECT DISTINCT
        customer_id,
        reactivation_txn_timestamp,
        --PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY reactivation_txn_gap_hrs ASC) OVER() p90,
        PERCENTILE_CONT(0.99) WITHIN
    GROUP (
            ORDER BY reactivation_txn_gap_hrs ASC
            ) OVER (PARTITION BY YEAR(reactivation_txn_timestamp)) AS p99
    FROM txn_gap_hrs
    )
SELECT
    gh.customer_id,
    gh.previous_txn_timestamp,
    gh.previous_txn_amt,
    gh.previous_txn_type,
    gh.previous_txn_channel,
    gh.previous_txn_status,
    gh.reactivation_txn_gap_hrs,
    rt.p99,
    gh.reactivation_txn_timestamp,
    gh.reactivation_txn_amt,
    gh.reactivation_txn_type,
    gh.reactivation_txn_channel,
    gh.reactivation_txn_status,
    LEAD(gh.reactivation_txn_timestamp, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS nxt_txn_timestamp,
    LEAD(gh.reactivation_txn_amt, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS nxt_txn_amt,
    LEAD(gh.reactivation_txn_type, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS nxt_txn_type,
    LEAD(gh.reactivation_txn_channel, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS nxt_txn_channel,
    LEAD(gh.reactivation_txn_status, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS nxt_txn_status,
    gh.previous_txn_amt - LEAD(gh.reactivation_txn_amt, 1) OVER (
        PARTITION BY gh.customer_id ORDER BY gh.reactivation_txn_timestamp
        ) AS prevnxt_amnt_chg
FROM txn_gap_hrs gh
LEFT JOIN reactivation_threshold rt ON
        gh.customer_id = rt.customer_id
            AND gh.reactivation_txn_timestamp = rt.reactivation_txn_timestamp
WHERE gh.reactivation_txn_gap_hrs >= rt.p99;

/*
P5.1.10 — Dormancy & Reactivation

Note
---------------------------------------------------------------------------------------------------------------------------------
Extended transaction gaps exist across the customer population.
Customer transaction gaps range from seconds to periods spanning several months.

Dormancy behaviour varies substantially by customer.
Some customers transact frequently with occasional long gaps, while others
have consistently long intervals between transactions.

A data-derived P99 threshold was used rather than an arbitrary fixed dormancy
period.

Year        P99 Gap        Approx. Days
2023        707.4 hrs      29.5 days
2024        658.7 hrs      27.4 days
2025        565.6 hrs      23.6 days

This gives an analytical baseline of approximately 24–30 days for exceptionally
extended transaction gaps within the observed population.

Reactivation behaviour was observed.
Transactions occurring after gaps exceeding the applicable annual P99 threshold
demonstrate that customers can return to activity following extended periods
of inactivity.

The year-specific thresholds also reflect changes in transaction behaviour
across the observation period, supporting a year-specific rather than a single
global baseline.

Intelligence relevance:
Dormancy and reactivation provide a meaningful temporal behavioural dimension.
The P99 baseline identifies exceptionally extended inactivity within the
observed population, but does not independently establish suspicious or
fraudulent behaviour.

P5.1.10 conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Dormancy and reactivation are established as useful analytical dimensions,
with extended inactivity occurring across the population and subsequent
reactivation events being observable. The year-specific P99 transaction-gap
baseline provides an empirical starting point of approximately 24–30 days
for subsequent financial intelligence analysis.
*/
/*
==================================================================================================================================
P5.1.11 — Cash-Out Behaviour & Escalation

Workload questions

Cash-out population
How many cash-out transactions?
What is their aggregate value?
What is the average cash-out value?

Cash-out over time
How does cash-out volume/value change monthly?
Is there a visible upward/downward pattern?

Cash-out escalation
Does the population show periods where cash-out activity increases materially?
Is there evidence of increasing cash-out activity that warrants deeper customer-level investigation later?

**Ground truth:** **S05 — Unusual Cash-Out Escalation**
**Deliverable:** cash-out escalation analysis.
==================================================================================================================================
*/
WITH cashout_txn_profile
AS (
    SELECT
        vt.customer_id,
        DATETRUNC(MONTH, vt.transaction_timestamp) AS month_year,
        --COUNT(*) OVER(PARTITION BY customer_id) AS overrall_txns,
        COUNT(*)                                   AS txns_per_mth,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN 1
                ELSE 0
                END) AS cash_out_count,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS cash_out_total,
        AVG(CASE 
                WHEN vt.transaction_type = 'cash out'
                    THEN vt.transaction_amount
                END) AS cash_out_avg
    FROM gold.vw_transaction vt
    GROUP BY customer_id,
        DATETRUNC(MONTH, transaction_timestamp)
    )
SELECT
    *,
    ROUND(CAST(cash_out_count AS FLOAT) / NULLIF(txns_per_mth, 0), 2) AS cash_out_to_txns_ratio
FROM cashout_txn_profile
ORDER BY customer_id,
    month_year;

/*
P5.1.11 — Cash-Out Behaviour & Escalation

Note
---------------------------------------------------------------------------------------------------------------------------------
Cash-out activity is present throughout the transaction population and varies
substantially across customers and over time.

Customer-level cash-out behaviour is not uniform.
Some customers show occasional cash-out transactions within otherwise low-volume
activity, while others exhibit sustained periods of substantially higher
cash-out frequency and value.

Cash-out activity can increase materially over a customer's observed history.
For example, some customers progress from a small number of monthly cash-outs
to substantially higher monthly cash-out counts and values.

Cash-out transaction share also varies across customer-month periods.
Some months contain no cash-out activity, while in other months cash-out
transactions represent a substantial proportion of the customer's total
transaction activity.

Cash-out value and cash-out volume do not always move proportionally.
Periods with similar cash-out counts can contain materially different aggregate
cash-out values because individual transaction amounts vary.

Intelligence relevance:
Cash-out behaviour provides a meaningful behavioural dimension for financial
intelligence analysis. Sustained increases in cash-out activity may warrant
deeper customer-level investigation when combined with other behavioural
dimensions, but increased cash-out activity alone does not establish suspicious
or fraudulent behaviour.

P5.1.11 conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Cash-out behaviour varies materially across customers and over time, with
observable periods of increased cash-out frequency and value. Cash-out
escalation is therefore established as a useful behavioural dimension for
subsequent financial intelligence analysis.
*/
/*
===================================================================================================================================
## P5.1.12 — Failed Transaction Clustering
Analyse repeated failures by:
* customer
* time
* transaction type
* channel

### Objective
Determine whether **failed transactions cluster together in time** for individual customers.
This is **temporal clustering**, not failure frequency.

**Ground truth:** **S09 — Repeated Failed Transactions**

**Deliverable:** failed-transaction behavioural analysis.

===================================================================================================================================
*/
WITH failed_txn_profile
AS (
    SELECT
        vt.customer_id,
        vt.transaction_id,
        LAG(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp ASC
            ) previous_failed_txn_timestamp,
        vt.transaction_timestamp AS current_failed_txn_timestamp,
        vt.transaction_type,
        vt.transaction_channel
    FROM gold.vw_transaction vt
    WHERE vt.transaction_status = 'failed'
    ),
failed_txn_interval
AS (
    SELECT
        tp.customer_id,
        tp.transaction_id,
        tp.previous_failed_txn_timestamp,
        DATEDIFF_BIG(SECOND, tp.previous_failed_txn_timestamp, tp.current_failed_txn_timestamp) / 60.00 AS mins_since_previous_failed,
        tp.current_failed_txn_timestamp,
        tp.transaction_type,
        tp.transaction_channel
    FROM failed_txn_profile tp
    ),
failed_txn_quartiles
AS (
    SELECT
        customer_id,
        transaction_id,
        previous_failed_txn_timestamp,
        mins_since_previous_failed,
        current_failed_txn_timestamp,
        MIN(mins_since_previous_failed) OVER (PARTITION BY customer_id) AS min_interval,
        MAX(mins_since_previous_failed) OVER (PARTITION BY customer_id) AS max_interval,
        AVG(mins_since_previous_failed) OVER (PARTITION BY customer_id) AS avg_interval,
        PERCENTILE_CONT(0.001) WITHIN
    GROUP (
            ORDER BY mins_since_previous_failed ASC
            ) OVER (PARTITION BY customer_id) p1_interval,
        PERCENTILE_CONT(0.10) WITHIN
    GROUP (
            ORDER BY mins_since_previous_failed ASC
            ) OVER (PARTITION BY customer_id) p10_interval,
        PERCENTILE_CONT(0.25) WITHIN
    GROUP (
            ORDER BY mins_since_previous_failed ASC
            ) OVER (PARTITION BY customer_id) p25_interval,
        PERCENTILE_CONT(0.5) WITHIN
    GROUP (
            ORDER BY mins_since_previous_failed ASC
            ) OVER (PARTITION BY customer_id) median_interval,
        PERCENTILE_CONT(0.75) WITHIN
    GROUP (
            ORDER BY mins_since_previous_failed ASC
            ) OVER (PARTITION BY customer_id) p75_interval,
        transaction_type,
        transaction_channel
    FROM failed_txn_interval
    ),
lower_tail_baseline
AS (
    SELECT
        *,
        COUNT(*) OVER (PARTITION BY customer_id) AS p10_interval_count
    FROM failed_txn_quartiles
    WHERE mins_since_previous_failed <= p10_interval
    ),
qualified_nxt_txn
AS (
    SELECT
        b.customer_id,
        b.previous_failed_txn_timestamp,
        b.mins_since_previous_failed,
        b.current_failed_txn_timestamp,
        LEAD(current_failed_txn_timestamp) OVER (
            PARTITION BY customer_id ORDER BY current_failed_txn_timestamp
            ) AS qualified_nxt_timestamp
    FROM lower_tail_baseline b
    )
SELECT
    *,
    DATEDIFF_BIG(SECOND, current_failed_txn_timestamp, qualified_nxt_timestamp) / 60.00 AS P10_qualified_failed_intervals
FROM qualified_nxt_txn
ORDER BY customer_id,
    P10_qualified_failed_intervals;

/*
P5.1.12 — Failed Transaction Clustering

Note
---------------------------------------------------------------------------------------------------------------------------------
Failed transaction intervals vary substantially across customers.
Some customers experience failed transactions separated by long periods,
while others exhibit much shorter recurrence intervals.

A customer-specific P10 lower-tail baseline was used to identify unusually
short failed-transaction intervals relative to each customer's own observed
failed-transaction behaviour.

The lower-tail analysis identified customers with very short failed
transaction intervals, including repeated intervals occurring within minutes.

However, short intervals do not automatically form sustained clusters.
Some lower-tail events occur as isolated close pairs, while others occur
in succession within a relatively concentrated period.

LEAD() analysis of the qualified lower-tail events therefore provided a
useful distinction between isolated short intervals and temporally
concentrated failed-transaction activity.

Intelligence relevance:
---------------------------------------------------------------------------------------------------------------------------------
Failed-transaction clustering provides a meaningful behavioural dimension
for financial intelligence analysis. Repeated short-interval failures may
warrant deeper investigation when combined with other behavioural dimensions,
but short failed-transaction intervals alone do not establish suspicious or
fraudulent behaviour.

P5.1.12 conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Failed transactions exhibit measurable temporal clustering behaviour, with
customer-specific lower-tail analysis identifying unusually short
inter-failure intervals and subsequent analysis demonstrating both isolated
and concentrated patterns. Failed-transaction clustering is therefore
established as a useful behavioural dimension for subsequent financial
intelligence analysis.
*/
/*
===================================================================================================================================
Next — P5.1.13: Rapid Transaction Sequences / S03
Identify ordered transaction patterns occurring within short time windows.
Analyse:
* ordering
* time between events
* amounts
* frequency
* customers exhibiting the pattern
Workload: identify the sequence:
Cash-In → P2P Transfer → Cash-Out for the same customer, in chronological order.

Identify the sequence Frequency & Customer Concentration

**Ground truth:** **S03 — Rapid Cash-In → P2P → Cash-Out**
===================================================================================================================================
*/
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp AS txn1_time,
        vt.transaction_type      AS txn1_type,
        vt.transaction_amount    AS txn1_amt,
        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_time,
        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_type,
        LEAD(vt.transaction_amount, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_amt,
        LEAD(vt.transaction_timestamp, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_time,
        LEAD(vt.transaction_type, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_type,
        LEAD(vt.transaction_amount, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_amt
    FROM gold.vw_transaction vt
    ),
total_sequence_duration_mins
AS (
    SELECT
        customer_id,
        txn1_time,
        txn1_type,
        txn1_amt,
        txn2_time,
        txn2_type,
        txn2_amt,
        txn3_time,
        txn3_type,
        txn3_amt,
        DATEDIFF_BIG(SECOND, txn1_time, txn3_time) / 60.00 AS total_sequence_duration_mins
    FROM ordered_txns
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    )
SELECT -- DISTINCT
    *,
    PERCENTILE_CONT(0.25) WITHIN
GROUP (
        ORDER BY total_sequence_duration_mins ASC
        ) OVER (PARTITION BY customer_id) AS p25,
    PERCENTILE_CONT(0.10) WITHIN
GROUP (
        ORDER BY total_sequence_duration_mins ASC
        ) OVER (PARTITION BY customer_id) AS p10,
    PERCENTILE_CONT(0.01) WITHIN
GROUP (
        ORDER BY total_sequence_duration_mins ASC
        ) OVER (PARTITION BY customer_id) AS p1
FROM total_sequence_duration_mins
ORDER BY total_sequence_duration_mins,
    customer_id,
    txn1_time;

-- Sequence Frequency & Customer Concentration
WITH ordered_txns
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp AS txn1_time,
        vt.transaction_type      AS txn1_type,
        vt.transaction_amount    AS txn1_amt,
        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_time,
        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_type,
        LEAD(vt.transaction_amount, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_amt,
        LEAD(vt.transaction_timestamp, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_time,
        LEAD(vt.transaction_type, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_type,
        LEAD(vt.transaction_amount, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_amt
    FROM gold.vw_transaction vt
    ),
total_sequence_duration_mins
AS (
    SELECT
        customer_id,
        txn1_time,
        txn1_type,
        txn1_amt,
        txn2_time,
        txn2_type,
        txn2_amt,
        txn3_time,
        txn3_type,
        txn3_amt,
        DATEDIFF_BIG(SECOND, txn1_time, txn3_time) / 60.00 AS total_sequence_duration_mins
    FROM ordered_txns
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    )
SELECT
    *,
    COUNT(*) OVER (PARTITION BY customer_id)                          AS count_qualifying_txn,
    txn1_amt + txn2_amt + txn3_amt                                    AS total_sequence_value,
    SUM(txn1_amt) OVER (PARTITION BY customer_id)                     AS cash_in_total,
    SUM(txn2_amt) OVER (PARTITION BY customer_id)                     AS p2p_transfer_total,
    SUM(txn3_amt) OVER (PARTITION BY customer_id)                     AS cash_out_total,
    AVG(total_sequence_duration_mins) OVER (PARTITION BY customer_id) AS avg_sequence_duration,
    MIN(total_sequence_duration_mins) OVER (PARTITION BY customer_id) AS min_sequence_duration,
    MAX(total_sequence_duration_mins) OVER (PARTITION BY customer_id) AS max_sequence_duration
FROM total_sequence_duration_mins
ORDER BY min_sequence_duration ASC;
/*
P5.1.13 — Rapid Transaction Sequence Behaviour

Note
---------------------------------------------------------------------------------------------------------------------------------
Immediate Cash-In → P2P Transfer → Cash-Out sequences are present within
the transaction population.

The sequence is defined using consecutive transactions within each customer's
chronological transaction history. LEAD() identifies the next transaction and
the transaction after that, requiring the three transaction types to occur
in the specified order without an intervening transaction.

Sequence duration varies substantially across the identified population.
Some sequences occur within minutes, while others unfold over substantially
longer periods.

Rapid executions are observable within the population. For example, some
Cash-In → P2P Transfer → Cash-Out sequences are completed within only a few
minutes, demonstrating rapid transactional bursts.

The sequence is also repeated by some customers. Certain customers exhibit
multiple qualifying sequences across their observed transaction history,
while others exhibit substantially fewer occurrences.

Sequence frequency and sequence duration therefore provide complementary
behavioural dimensions. Frequency indicates recurrence of the pattern, while
duration indicates how rapidly the pattern is executed.

No universal temporal threshold is imposed at this stage. Sequence duration
is retained as an analytical measure rather than being used to classify a
sequence as suspicious or fraudulent.

Intelligence relevance:
---------------------------------------------------------------------------------------------------------------------------------
Rapid Cash-In → P2P Transfer → Cash-Out sequences provide a meaningful
behavioural dimension for financial intelligence analysis. Repeated or
rapid execution of the sequence may warrant deeper investigation when
combined with other behavioural dimensions, but sequence occurrence or
rapid execution alone does not establish suspicious or fraudulent behaviour.

P5.1.13 conclusion:
---------------------------------------------------------------------------------------------------------------------------------
Immediate Cash-In → P2P Transfer → Cash-Out sequences occur within the
transaction population, with substantial variation in both recurrence and
elapsed duration. The presence of sequences completed within minutes
demonstrates observable rapid transactional bursts, while repeated
occurrence among some customers establishes the pattern as a meaningful
behavioural dimension for subsequent financial intelligence analysis.
*/
/*
===================================================================================================================================
### **Task 5.1.14 — Compound Transaction Behaviour**

Design a customer-month behaviour
For each customer + month, what transaction types did they use, how many transactions did they make, and how much value was
involved?
Measure how much multi-type behaviour exists
Which specific transaction-type combinations dominate?


**Deliverable:** compound transaction behaviour analysis.
===================================================================================================================================
*/
WITH customer_month_behaviour
AS (
    SELECT
        vt.customer_id,
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1) AS year_month,
        COUNT(*)                                                                          AS total_txn_count,
        SUM(vt.transaction_amount)                                                        AS total_txn_value,
        SUM(CASE vt.transaction_type
                WHEN 'cash in'
                    THEN 1
                ELSE 0
                END) AS cash_in_count,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN 1
                ELSE 0
                END) AS cash_out_count,
        SUM(CASE vt.transaction_type
                WHEN 'p2p transfer'
                    THEN 1
                ELSE 0
                END) AS p2p_transfer_count,
        SUM(CASE vt.transaction_type
                WHEN 'merchant payment'
                    THEN 1
                ELSE 0
                END) AS merchant_payment_count,
        SUM(CASE vt.transaction_type
                WHEN 'cash in'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS cash_in_value,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS cash_out_value,
        SUM(CASE vt.transaction_type
                WHEN 'p2p transfer'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS p2p_transfer_value,
        SUM(CASE vt.transaction_type
                WHEN 'merchant payment'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS merchant_payment_value,
        COUNT(DISTINCT vt.transaction_type) AS distinct_txn_types
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1)
    )
SELECT -- Measure how much multi-type behaviour exists
    distinct_txn_types,
    COUNT(*)                    AS customer_month_count,
    COUNT(DISTINCT customer_id) AS distinct_customer_count
FROM customer_month_behaviour
GROUP BY distinct_txn_types;

-- transaction-type combinations
WITH customer_month_behaviour
AS (
    SELECT
        vt.customer_id,
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1) AS year_month,
        COUNT(*)                                                                          AS total_txn_count,
        SUM(vt.transaction_amount)                                                        AS total_txn_value,
        SUM(CASE vt.transaction_type
                WHEN 'cash in'
                    THEN 1
                ELSE 0
                END) AS cash_in_count,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN 1
                ELSE 0
                END) AS cash_out_count,
        SUM(CASE vt.transaction_type
                WHEN 'p2p transfer'
                    THEN 1
                ELSE 0
                END) AS p2p_transfer_count,
        SUM(CASE vt.transaction_type
                WHEN 'merchant payment'
                    THEN 1
                ELSE 0
                END) AS merchant_payment_count,
        SUM(CASE vt.transaction_type
                WHEN 'cash in'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS cash_in_value,
        SUM(CASE vt.transaction_type
                WHEN 'cash out'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS cash_out_value,
        SUM(CASE vt.transaction_type
                WHEN 'p2p transfer'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS p2p_transfer_value,
        SUM(CASE vt.transaction_type
                WHEN 'merchant payment'
                    THEN vt.transaction_amount
                ELSE 0
                END) AS merchant_payment_value,
        COUNT(DISTINCT vt.transaction_type) AS distinct_txn_types
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        DATEFROMPARTS(YEAR(vt.transaction_timestamp), MONTH(vt.transaction_timestamp), 1)
    ),
txn_type_combinations
AS (
    SELECT
        customer_id,
        CONCAT_WS(' + ', CASE 
                WHEN cash_in_count > 0
                    THEN 'Cash In'
                END, CASE 
                WHEN cash_out_count > 0
                    THEN 'Cash Out'
                END, CASE 
                WHEN p2p_transfer_count > 0
                    THEN 'P2P Transfer'
                END, CASE 
                WHEN merchant_payment_count > 0
                    THEN 'Merchant Payment'
                END) AS txn_type_combo
    FROM customer_month_behaviour
    )
SELECT
    txn_type_combo,
    COUNT(*)                    AS combo_txn_count,
    COUNT(DISTINCT customer_id) AS distinct_customer_count
FROM txn_type_combinations
GROUP BY txn_type_combo
ORDER BY combo_txn_count DESC;

/*
P5.1.14 — Compound Transaction Behaviour

Note:
--------------------------------------------------------------------------------------------------------------------------
Customer transaction activity was analysed at customer-month grain to identify
the extent and composition of compound transaction behaviour.

Stage 1 established the transaction-type composition of each customer-month,
including transaction counts, transaction values, and the number of distinct
transaction types used.

Stage 2 showed that multi-type activity is substantial within the population.
Customer-month observations containing two, three, or four transaction types
substantially exceeded single-type customer-month observations.

Stage 3 identified the specific transaction-type combinations occurring within
customer-month activity. All 15 possible non-empty combinations of the four
observed transaction types were present in the population.

The most common combination was Cash In + Cash Out + P2P Transfer +
Merchant Payment, occurring across 28,582 customer-month observations and
involving 2,583 distinct customers.

Other multi-type combinations were also observed at meaningful frequencies,
including Cash In + Cash Out + P2P Transfer and Cash In + Cash Out +
Merchant Payment.

Transaction-type combinations are treated as unordered compositions of
customer-month activity. Transaction sequence and temporal ordering are not
evaluated in this workload and remain separate from the sequence analysis
performed in P5.1.13.
----------------------------------------------------------------------------------------------------------------------------
Intelligence relevance:
Compound transaction behaviour provides a useful behavioural dimension for
understanding how customers combine different transaction types within the
same activity period.

Specific combinations can provide additional context when evaluated alongside
transaction frequency, velocity, cash-out behaviour, failed transactions,
temporal behaviour, and other intelligence signals. The presence or frequency
of a transaction-type combination alone does not establish suspicious or
fraudulent behaviour.
-------------------------------------------------------------------------------------------------------------------------------
P5.1.14 conclusion:
Compound transaction behaviour is widespread within the transaction
population. Customers frequently combine multiple transaction types within
the same month, with all 15 possible non-empty combinations of the four
observed transaction types represented.

The results establish transaction-type composition as a meaningful behavioural
dimension for subsequent financial intelligence analysis, while preserving
transaction ordering and rapid sequence behaviour as separate analytical
dimensions.
*/
/*
===================================================================================================================================
## P5.1.15 — Transaction Geographic Behaviour

Determine:
* transaction volume and value by region;
* transaction volume and value by town;
* customer distribution across regions and towns;
* number of distinct locations used per customer;
* concentration of customer activity within locations;
* customer movement between transaction locations over time;
* transaction-type behaviour across locations;
* channel behaviour across locations;
* whether particular locations exhibit materially different transaction characteristics;
* whether geographic behaviour provides meaningful differentiation for subsequent financial intelligence.

===================================================================================================================================
*/
-- regional profile
WITH region_txn_profile
AS (
    SELECT
        vt.transaction_location_region,
        COUNT(DISTINCT vt.customer_id) AS distinct_customer,
        COUNT(*)                       AS total_txn_count_region,
        SUM(vt.transaction_amount)     AS total_txn_value
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_region
    ),
total_txns
AS (
    SELECT
        SUM(total_txn_count_region) AS overall_txns,
        SUM(total_txn_value)        AS overall_txn_amt
    FROM region_txn_profile
    )
SELECT
    *,
    ROUND(CAST(100.00 * total_txn_count_region AS FLOAT) / overall_txns, 2) AS region_txn_proportion,
    ROUND(CAST(100.00 * total_txn_value AS FLOAT) / overall_txn_amt, 2)     AS region_txn_amt_proportion
FROM region_txn_profile
CROSS JOIN total_txns
ORDER BY region_txn_proportion DESC;
GO
-- town profile
WITH town_txn_profile
AS (
    SELECT
        vt.transaction_location_town,
        COUNT(DISTINCT vt.customer_id) AS distinct_customer,
        COUNT(*)                       AS total_txn_count_town,
        SUM(vt.transaction_amount)     AS total_txn_value
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_town
    ),
total_txns
AS (
    SELECT
        SUM(total_txn_count_town) AS overall_txns,
        SUM(total_txn_value)      AS overall_txn_amt
    FROM town_txn_profile
    )
SELECT
    *,
    ROUND(CAST(100.00 * total_txn_count_town AS FLOAT) / overall_txns, 2) AS town_txn_proportion,
    ROUND(CAST(100.00 * total_txn_value AS FLOAT) / overall_txn_amt, 2)   AS town_txn_amt_proportion
FROM town_txn_profile
CROSS JOIN total_txns
ORDER BY town_txn_proportion DESC;

-- distinct txn profile and primary region and town
WITH distinct_txn_profile
AS (
    SELECT
        vt.customer_id,
        COUNT(*)                                       AS total_txns,
        SUM(vt.transaction_amount)                     AS total_txn_amt,
        COUNT(DISTINCT vt.transaction_location_region) AS distinct_region,
        COUNT(DISTINCT vt.transaction_location_town)   AS distinct_town
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id
    ),
customer_region_rank
AS (
    SELECT
        vt.customer_id,
        vt.transaction_location_region,
        COUNT(*)                                         AS total_txn_count_region,
        SUM(COUNT(*)) OVER (PARTITION BY vt.customer_id) AS overall_txns,
        ROW_NUMBER() OVER (
            PARTITION BY vt.customer_id ORDER BY COUNT(*) DESC,
                vt.transaction_location_region ASC
            ) AS region_rank
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        vt.transaction_location_region
    ),
primary_region_contribution
AS (
    SELECT
        *,
        ROUND(CAST(total_txn_count_region AS FLOAT) / NULLIF(overall_txns, 0) * 100.00, 2) AS primary_region_proportion
    FROM customer_region_rank
    WHERE region_rank = 1
    ),
customer_town_rank
AS (
    SELECT
        vt.customer_id,
        vt.transaction_location_town,
        COUNT(*)                                         AS total_txn_count_town,
        SUM(COUNT(*)) OVER (PARTITION BY vt.customer_id) AS overall_txns,
        ROW_NUMBER() OVER (
            PARTITION BY vt.customer_id ORDER BY COUNT(*) DESC,
                vt.transaction_location_town ASC
            ) AS town_rank
    FROM gold.vw_transaction vt
    GROUP BY vt.customer_id,
        vt.transaction_location_town
    ),
primary_town_contribution
AS (
    SELECT
        *,
        ROUND(CAST(total_txn_count_town AS FLOAT) / NULLIF(overall_txns, 0) * 100.00, 2) AS primary_town_proportion
    FROM customer_town_rank
    WHERE town_rank = 1
    )
SELECT
    tp.customer_id,
    tp.total_txns,
    tp.total_txn_amt,
    tp.distinct_region,
    pr.transaction_location_region AS primary_region,
    pr.total_txn_count_region      AS total_txns_primary_region,
    pr.primary_region_proportion,
    tp.distinct_town,
    pt.transaction_location_town   AS primary_town,
    pt.total_txn_count_town        AS total_txns_primary_town,
    pt.primary_town_proportion
FROM distinct_txn_profile tp
LEFT JOIN primary_region_contribution pr ON
        tp.customer_id = pr.customer_id
LEFT JOIN primary_town_contribution pt ON
        tp.customer_id = pt.customer_id;
GO

-- transaction-type behaviour across region
WITH region_txn_type
AS (
    SELECT
        vt.transaction_location_region,
        vt.transaction_type,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(*)                    AS txn_type_count,
        SUM(vt.transaction_amount)  AS txn_type_amt
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_region,
        vt.transaction_type
    ),
proportion_analysis
AS (
    SELECT
        transaction_location_region,
        transaction_type,
        distinct_customers,
        txn_type_count,
        SUM(txn_type_count) OVER (PARTITION BY transaction_location_region)                                                    AS txn_type_count_region_overall,
        txn_type_amt,
        SUM(txn_type_amt) OVER (PARTITION BY transaction_location_region)                                                      AS txn_type_amt_region_overall,
        ROUND(CAST(100.00 * txn_type_count AS FLOAT) / SUM(txn_type_count) OVER (PARTITION BY transaction_location_region), 2) AS txn_type_count_region_proportion,
        ROUND(CAST(100.00 * txn_type_amt AS FLOAT) / SUM(txn_type_amt) OVER (PARTITION BY transaction_location_region), 2)     AS txn_type_amt_region_proportion
    FROM region_txn_type
    )
SELECT
    *
FROM proportion_analysis
ORDER BY txn_type_count_region_proportion DESC,
    txn_type_amt_region_proportion DESC;

-- transaction-type behaviour across town
WITH town_txn_type
AS (
    SELECT
        vt.transaction_location_town,
        vt.transaction_type,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(*)                    AS txn_type_count,
        SUM(vt.transaction_amount)  AS txn_type_amt
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_town,
        vt.transaction_type
    ),
proportion_analysis
AS (
    SELECT
        transaction_location_town,
        transaction_type,
        distinct_customers,
        txn_type_count,
        SUM(txn_type_count) OVER (PARTITION BY transaction_location_town)                                                    AS txn_type_count_town_overall,
        txn_type_amt,
        SUM(txn_type_amt) OVER (PARTITION BY transaction_location_town)                                                      AS txn_type_amt_town_overall,
        ROUND(CAST(100.00 * txn_type_count AS FLOAT) / SUM(txn_type_count) OVER (PARTITION BY transaction_location_town), 2) AS txn_type_count_town_proportion,
        ROUND(CAST(100.00 * txn_type_amt AS FLOAT) / SUM(txn_type_amt) OVER (PARTITION BY transaction_location_town), 2)     AS txn_type_amt_town_proportion
    FROM town_txn_type
    )
SELECT
    *
FROM proportion_analysis
ORDER BY txn_type_count_town_proportion DESC,
    txn_type_amt_town_proportion DESC;
GO

-- transaction-channel behaviour across region
WITH region_txn_channel
AS (
    SELECT
        vt.transaction_location_region,
        vt.transaction_channel,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(*)                    AS txn_channel_count,
        SUM(vt.transaction_amount)  AS txn_channel_amt
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_region,
        vt.transaction_channel
    ),
proportion_analysis
AS (
    SELECT
        transaction_location_region,
        transaction_channel,
        distinct_customers,
        txn_channel_count,
        SUM(txn_channel_count) OVER (PARTITION BY transaction_location_region)                                                       AS txn_channel_count_region_overall,
        txn_channel_amt,
        SUM(txn_channel_amt) OVER (PARTITION BY transaction_location_region)                                                         AS txn_channel_amt_region_overall,
        ROUND(CAST(100.00 * txn_channel_count AS FLOAT) / SUM(txn_channel_count) OVER (PARTITION BY transaction_location_region), 2) AS txn_channel_count_region_proportion,
        ROUND(CAST(100.00 * txn_channel_amt AS FLOAT) / SUM(txn_channel_amt) OVER (PARTITION BY transaction_location_region), 2)     AS txn_channel_amt_region_proportion
    FROM region_txn_channel
    )
SELECT
    *
FROM proportion_analysis
ORDER BY txn_channel_count_region_proportion DESC,
    txn_channel_amt_region_proportion DESC;

-- transaction-channel behaviour across town
WITH town_txn_channel
AS (
    SELECT
        vt.transaction_location_town,
        vt.transaction_channel,
        COUNT(DISTINCT customer_id) AS distinct_customers,
        COUNT(*)                    AS txn_channel_count,
        SUM(vt.transaction_amount)  AS txn_channel_amt
    FROM gold.vw_transaction vt
    GROUP BY vt.transaction_location_town,
        vt.transaction_channel
    ),
proportion_analysis
AS (
    SELECT
        transaction_location_town,
        transaction_channel,
        distinct_customers,
        txn_channel_count,
        SUM(txn_channel_count) OVER (PARTITION BY transaction_location_town)                                                       AS txn_channel_count_town_overall,
        txn_channel_amt,
        SUM(txn_channel_amt) OVER (PARTITION BY transaction_location_town)                                                         AS txn_channel_amt_town_overall,
        ROUND(CAST(100.00 * txn_channel_count AS FLOAT) / SUM(txn_channel_count) OVER (PARTITION BY transaction_location_town), 2) AS txn_channel_count_town_proportion,
        ROUND(CAST(100.00 * txn_channel_amt AS FLOAT) / SUM(txn_channel_amt) OVER (PARTITION BY transaction_location_town), 2)     AS txn_channel_amt_town_proportion
    FROM town_txn_channel
    )
SELECT
    *
FROM proportion_analysis
ORDER BY txn_channel_count_town_proportion DESC,
    txn_channel_amt_town_proportion DESC;

/*
P5.1.15 — TRANSACTION GEOGRAPHIC BEHAVIOUR
Component: Transaction-Type Behaviour Across Locations

NOTES
------------------------------------------------------------------------------------------------------------------------
- Transaction-type composition was examined separately within each region and town.
- Within each location, transaction count and transaction value were measured for each transaction type.
- Transaction-type shares were calculated against the total transaction count and total transaction value of
    the corresponding location.
- Across regions, transaction-type composition remained highly consistent:
    * Cash-In represented approximately 32–34% of transaction volume.
    * Cash-Out represented approximately 27–28%.
    * P2P Transfer represented approximately 22–23%.
    * Merchant Payment represented approximately 16–17%.
- Town-level results showed the same general distribution, with only minor variation between locations.
- The relative contribution of each transaction type to transaction value was also broadly consistent across
    regions and towns.
- Cash-In contributed a substantially smaller share of transaction value than transaction volume, while
    Merchant Payment and Cash-Out contributed larger value shares relative to their transaction counts.
- Geographic location therefore does not materially alter the overall transaction-type composition of the
    observed population.
- COUNT(DISTINCT customer) represents customers who performed that transaction type within the location;
    it does not indicate the customer's primary transaction behaviour.

CONCLUSION
------------------------------------------------------------------------------------------------------------------------
Transaction-type behaviour is highly consistent across geographic locations. Region and town do not materially
differentiate the composition of transaction activity, with all locations exhibiting broadly similar proportions
of Cash-In, Cash-Out, P2P Transfer, and Merchant Payment activity.

Geography therefore provides descriptive information about where transaction activity is concentrated, but does
not appear to be a strong differentiator of transaction-type behaviour within this population.
*/
/*
===================================================================================================================================
## P5.1.16 — Device Behaviour
Determine:
* number of distinct devices used per customer;
* customer concentration by device;
* frequency of device changes;
* customers using multiple devices;
* devices associated with multiple customers;
* duration of customer-device relationships;
* transaction activity before and after device changes;
* transaction type and channel behaviour by device;
* temporal characteristics of device changes;
* concentration of transaction activity across devices;
* whether device behaviour exhibits meaningful differentiation across the transaction population.
===================================================================================================================================
*/
-- device profile
SELECT
    vt.device_id,
    COUNT(DISTINCT vt.customer_id)         AS distinct_customers,
    COUNT(vt.device_id) OVER ()            AS total_device_count,
    COUNT(*)                               AS txn_volume,
    COUNT(DISTINCT vt.transaction_type)    AS distinct_txn_types,
    COUNT(DISTINCT vt.transaction_channel) AS distinct_txn_channels,
    SUM(vt.transaction_amount)             AS txn_value,
    AVG(vt.transaction_amount)             AS txn_avg,
    SUM(CASE vt.transaction_status
            WHEN 'successful'
                THEN 1
            ELSE 0
            END) AS successful_count_per_device,
    SUM(CASE vt.transaction_status
            WHEN 'failed'
                THEN 1
            ELSE 0
            END) AS failed_count_per_device,
    SUM(CASE vt.transaction_status
            WHEN 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_count_per_device
FROM gold.vw_transaction vt
GROUP BY vt.device_id

-- shared device profile
SELECT
    vt.device_id,
    COUNT(DISTINCT vt.customer_id)                         AS distinct_customers,
    COUNT(*)                                               AS txn_volume,
    SUM(vt.transaction_amount)                             AS txn_value,
    AVG(vt.transaction_amount)                             AS txn_avg,
    MIN(vt.transaction_timestamp)                          AS first_txn_timestamp,
    MAX(vt.transaction_timestamp)                          AS last_txn_timestamp,
    (DATEDIFF(SECOND, MIN(vt.transaction_timestamp), MAX(vt.transaction_timestamp)) / 86400.00) AS relationship_duration_days,
    COUNT(DISTINCT CAST(vt.transaction_timestamp AS DATE)) AS active_days,
    COUNT(DISTINCT vt.transaction_type)                    AS distinct_txn_types,
    COUNT(DISTINCT vt.transaction_channel)                 AS distinct_txn_channels,
    SUM(CASE 
            WHEN vt.transaction_status = 'successful'
                THEN 1
            ELSE 0
            END) AS successful_count_per_device,
    SUM(CASE 
            WHEN vt.transaction_status = 'failed'
                THEN 1
            ELSE 0
            END) AS failed_count_per_device,
    SUM(CASE 
            WHEN vt.transaction_status = 'rejected'
                THEN 1
            ELSE 0
            END) AS rejected_count_per_device,
    ROUND(CAST(SUM(CASE 
                    WHEN vt.transaction_status = 'failed'
                        THEN 1
                    ELSE 0
                    END) AS FLOAT) / COUNT(*), 3) AS failed_rate,
    ROUND(CAST(SUM(CASE 
                    WHEN vt.transaction_status = 'rejected'
                        THEN 1
                    ELSE 0
                    END) AS FLOAT) / COUNT(*), 3) AS rejected_rate
FROM gold.vw_transaction vt
GROUP BY vt.device_id
HAVING COUNT(DISTINCT vt.customer_id) > 1;

-- frequency of device changes
WITH device_sequence
AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp,
        vt.device_id,
        CASE LAG(vt.device_id, 1) OVER (
                PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp ASC
                )
            WHEN vt.device_id
                THEN 0
            ELSE 1
            END AS has_device_changed
    FROM gold.vw_transaction vt
    )
SELECT
    *
FROM device_sequence
WHERE has_device_changed > 1 -- no device change recorded.


--  temporal characteristics of shared devices
WITH device_sequence AS (
        SELECT
            vt.device_id,
            vt.customer_id,
            vt.transaction_timestamp,
            LAG(vt.customer_id) OVER (
                PARTITION BY vt.device_id ORDER BY vt.transaction_timestamp
                ) AS previous_customer_id,
            LAG(vt.transaction_timestamp) OVER (
                PARTITION BY vt.device_id ORDER BY vt.transaction_timestamp
                ) AS previous_transaction_timestamp
        FROM gold.vw_transaction vt
        )
SELECT
    device_id,
    customer_id,
    transaction_timestamp,
    previous_customer_id,
    previous_transaction_timestamp,
    DATEDIFF(SECOND, previous_transaction_timestamp, transaction_timestamp)/60.0 AS mins_since_previous
FROM device_sequence
WHERE previous_customer_id <> customer_id
AND DATEDIFF(SECOND, previous_transaction_timestamp, transaction_timestamp)/60.0 < 15;


/*
P5.1.16 — Device Behaviour

Notes:
----------------------------------------------------------------------------------------------------------------------------------
- Device-level sequencing showed repeated instances where the same device
was used by different customers in consecutive transactions.
- Several devices exhibited customer switching within very short time
intervals, including intervals of only a few seconds or minutes.
- The behaviour was observed repeatedly across multiple devices and
customer combinations rather than appearing as isolated one-off events.
- This establishes that device_id contains meaningful behavioural structure
within the transaction population.
- Short-interval customer switching was used as an exploratory observation
window only and is not a fraud threshold or classification rule.
- Shared-device behaviour alone does not establish fraudulent activity.
It identifies a behavioural relationship that may warrant further
investigation when combined with other transaction, customer, temporal,
geographic, or risk indicators.

Conclusion:
-----------------------------------------------------------------------------------------------------------------------------------
Device_id provides sufficient evidence of customer-sharing and rapid
customer-switching behaviour to justify its inclusion as a potentially
useful signal in subsequent financial intelligence analysis. Device
behaviour should therefore be carried forward into later intelligence
workloads, where it can be evaluated in combination with other signals
rather than treated as a standalone fraud indicator.
*/









