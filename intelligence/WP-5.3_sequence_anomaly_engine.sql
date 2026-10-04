USE [ocb_platform];
GO

-- sequence anomaly engine
-- existence of sequence events
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
   -- WHERE transaction_channel <> 'QR'
    ),
total_sequence_duration_mins_calc
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
        DATEDIFF_BIG(SECOND, txn1_time, txn3_time) / 60.00 AS total_sequence_duration_mins,
        txn1_amt+txn2_amt+txn3_amt AS total_sequence_amt
    FROM ordered_txns
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
    )
SELECT
    *
FROM total_sequence_duration_mins_calc
ORDER BY total_sequence_duration_mins aSC

SELECT * FROM gold.vw_transaction
where transaction_channel = 'qr'

-- frequency
WITH ordered_txns AS (
    SELECT
        vt.customer_id,
        vt.transaction_timestamp,
        vt.transaction_type,

        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn2_type,

        LEAD(vt.transaction_type, 2) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn3_type

    FROM gold.vw_transaction vt
),

sequence_events AS (
    SELECT
        customer_id,
        transaction_timestamp AS sequence_timestamp
    FROM ordered_txns
    WHERE transaction_type = 'cash in'
      AND txn2_type = 'p2p transfer'
      AND txn3_type = 'cash out'
),

customer_sequence_frequency AS (
    SELECT
        customer_id,
        COUNT(*) AS sequence_count,
        MIN(sequence_timestamp) AS first_sequence_timestamp,
        MAX(sequence_timestamp) AS last_sequence_timestamp
    FROM sequence_events
    GROUP BY customer_id
)

SELECT
    customer_id,
    sequence_count,
    first_sequence_timestamp,
    last_sequence_timestamp
FROM customer_sequence_frequency
ORDER BY sequence_count DESC, customer_id;

-- sequence recurrence duration
WITH sequence_events AS (
    SELECT
        vt.customer_id,

        vt.transaction_timestamp AS txn1_timestamp,
        vt.transaction_type AS txn1_type,

        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn2_timestamp,

        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn2_type,

        LEAD(vt.transaction_timestamp, 2) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn3_timestamp,

        LEAD(vt.transaction_type, 2) OVER (
            PARTITION BY vt.customer_id
            ORDER BY vt.transaction_timestamp
        ) AS txn3_type

    FROM gold.vw_transaction AS vt
),

qualified_sequences AS (
    SELECT
        customer_id,
        txn1_timestamp,
        txn2_timestamp,
        txn3_timestamp
    FROM sequence_events
    WHERE txn1_type = 'Cash In'
      AND txn2_type = 'P2P Transfer'
      AND txn3_type = 'Cash Out'
),

sequence_recurrence AS (
    SELECT
        customer_id,
        txn1_timestamp,
        txn2_timestamp,
        txn3_timestamp,

        LEAD(txn1_timestamp) OVER (
            PARTITION BY customer_id
            ORDER BY txn1_timestamp
        ) AS next_sequence_txn1_timestamp
    FROM qualified_sequences
)

SELECT
    customer_id,

    txn1_timestamp,
    txn2_timestamp,
    txn3_timestamp,

    next_sequence_txn1_timestamp,

    DATEDIFF(
        SECOND,
        txn3_timestamp,
        next_sequence_txn1_timestamp
    ) AS recurrence_gap_seconds,

    DATEDIFF(
        MINUTE,
        txn3_timestamp,
        next_sequence_txn1_timestamp
    ) AS recurrence_gap_minutes,

    DATEDIFF(
        HOUR,
        txn3_timestamp,
        next_sequence_txn1_timestamp
    ) AS recurrence_gap_hours,

    DATEDIFF(
        DAY,
        txn3_timestamp,
        next_sequence_txn1_timestamp
    ) AS recurrence_gap_days

FROM sequence_recurrence

WHERE next_sequence_txn1_timestamp IS NOT NULL

ORDER BY
    customer_id,
    recurrence_gap_minutes;
































WITH ordered_txns
AS (
    SELECT
        vt.customer_id,

        vt.transaction_timestamp AS txn1_time,
        vt.transaction_type      AS txn1_type,
        vt.transaction_channel AS txn1_channel,
        vt.transaction_amount    AS txn1_amt,

        LEAD(vt.transaction_timestamp, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_time,
        LEAD(vt.transaction_type, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_type,
        LEAD(vt.transaction_channel, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_channel,            
        LEAD(vt.transaction_amount, 1) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn2_amt,

        LEAD(vt.transaction_timestamp, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_time,
        LEAD(vt.transaction_type, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_type,
        LEAD(vt.transaction_channel, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_channel,
        LEAD(vt.transaction_amount, 2) OVER (
            PARTITION BY vt.customer_id ORDER BY vt.transaction_timestamp
            ) AS txn3_amt
    FROM gold.vw_transaction vt
   -- WHERE transaction_channel <> 'QR'
    ),
total_sequence_duration_mins_calc
AS (
    SELECT
        customer_id,
        txn1_time,
        txn1_type,
        txn1_channel,
        txn1_amt,
        txn2_time,
        txn2_type,
        txn2_channel,
        txn2_amt,
        txn3_time,
        txn3_type,
        txn3_channel,
        txn3_amt,
        DATEDIFF_BIG(SECOND, txn1_time, txn3_time) / 60.00 AS total_sequence_duration_mins,
        txn1_amt+txn2_amt+txn3_amt AS total_sequence_amt
    FROM ordered_txns
    WHERE txn1_type = 'cash in'
            AND txn2_type = 'p2p transfer'
            AND txn3_type = 'cash out'
            AND txn1_channel<>'qr'
            AND txn2_channel<>'qr'
            AND txn3_channel<>'qr'
    )
SELECT
    *
FROM total_sequence_duration_mins_calc
ORDER BY total_sequence_duration_mins aSC

SELECT
    sum(case when transaction_channel='qr' and transaction_type='merchant payment' then 1 else 0 end) as qr_mp_yes,
    sum(case when transaction_channel='qr' and transaction_type<>'merchant payment' then 1 else 0 end) as qr_mp_no
FROM gold.vw_transaction

SELECT distinct transaction_channel from gold.vw_transaction


/*
i think i have found a bunch of issues with our engines so far
the  pollution is from not separating agent and merchant txns from personal txns
lets begin with the TAE where we had the global score based on the txn value. Merchant payments tend to be large. so when we dont
separate them genuine merchant payments will have a large score, causing us to flag them.
A 4500 txn via a merchant payment channel isnt same as one via a p2p transfer
Even in this sequence anomaly engine (SAE) it is sensible for a merchant or agent to be involved in certain sequences. When we treat
all merchants, agents and personal accounts the same, we will have false positives.
Now the issue is we dont have a merchant or agent ID and all we have are these distinct txn types : p2p transfer
cash out
merchant payment
cash in
and these distinct channels :
qr
agent
api
mobile app
pos
third party
web
ussd
Initially we agreed that the qr channel will be for merchant payments only but i run a simple query and found it heavily polluted

```
SELECT
    sum(case when transaction_channel='qr' and transaction_type='merchant payment' then 1 else 0 end) as qr_mp_yes,
    sum(case when transaction_channel='qr' and transaction_type<>'merchant payment' then 1 else 0 end) as qr_mp_no
FROM gold.vw_transaction

qr_mp_yes	qr_mp_no
15978	81080
```
we can see only 15.9k txns used the logic with 81k polluting it.
No problem though. As this simply means for the TAE we must exclude those 15.9k txns and assume theyre true merchant payments
and deal with anomalous merchant payments differently.

Same with the BAE where we dealt with unusual overnight rapidity and cash out escalation.
These behaviours deal with personal accounts and genuine merchant payments would create false positives.

And same thing with this SAE we are creating.
Good thing here is we are explicit about the txn type we want so we have no worries about it being merchant payment.

I was initially worried about having the Qr and Agent as channels in this and contemplated whether to do a
WHERE transaction type <>'agent' OR transaction type <> 'merchant payment' - but that would exclude txns where
transaction_channel='qr' and transaction_type<>'merchant payment - and as if weve seen, its a large amount
And i think it makes sense to add those specific ones because the SAE is meant to identify smurfing, mules and layering (AML)
And a sequence where txn 1 is cash in via qr channel, and txn2 is p2p via ussd channel and txn3 is cash out via agent, is an example
of a layering and smurfing
so i think it makes sense to keep those.

Next big issue has to do with the SAE.
We now have the sequence duration, interval sequence velocity, frequency. I think another construct to add will be one similar to
what you initally tried to do. But instead, we do an outflow/inflow ratio (cash out+p2p transfer/cash in). Your previous ratios were
incomplete and only considered cashin_p2p ratio or p2p_cash_out ratio
imagine an event where cash in is 1500, p2p is 800 and cash out is 300, if we do a cash-out_cash_in(300/1500)=0.2 but when we add the
p2p, we get ((300+800)/1500)=0.73 - now thats more accurate as the p2p could be a smurfing or to a mule wallet.
But again, we must treat merchant txns differently from personal txns
So the SAE for the cash in-p2p-cash out works out to be sequence duration,interval sequence velocity, frequency and the ratio

these are my thoughts. dont be a yes man and i agree because i suggested it
*/