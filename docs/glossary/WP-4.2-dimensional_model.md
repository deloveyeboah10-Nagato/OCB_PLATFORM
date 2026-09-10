# OCB PLATFORM v1.0.0

## WORK PACKAGE 4.2 — DIMENSIONAL MODEL

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-4.2 — Dimensional Model
**Component:** Analytical Warehouse & OLAP Model
**Purpose:** Define the analytical fact and dimension structures required to support cross-institutional financial analysis, behavioural analysis, risk analysis, temporal analysis, and supervisory intelligence.
**Implementation Status:** Logical model validated; physical implementation pending.

---

## 1. Purpose

The OCB analytical warehouse uses a dimensional model to provide a consistent analytical interface over the validated Silver source data.

The model is designed around **business events and their measurable activity**, rather than around individual analytical techniques.

The foundational analytical facts represent the four currently established financial event grains:

1. Ananse Telecom transactions
2. SikaCredit loans
3. SikaCredit repayments
4. Oman Remit remittances

Dimensions provide the descriptive and contextual attributes required to analyse these events consistently across institutions and domains.

The model is intentionally limited to structures justified by the current analytical requirements. Derived intelligence such as anomaly scores, velocity measures, behavioural indicators, liquidity pressure, and risk scores will be calculated from the foundational analytical facts rather than being introduced as separate fact tables at this stage.

---

# 2. Dimensional Modelling Principles

The following principles govern the model.

### 2.1 Facts represent business events

Each fact table must have a clearly defined and stable grain.

A fact row represents an actual event recorded in the source financial system.

The warehouse does not manufacture additional financial events for analytical convenience.

### 2.2 Transactions remain the source of financial truth

Analytical measures must ultimately trace back to the underlying source events.

Failed transactions do not become successful financial activity merely because they exist in the source transaction population.

### 2.3 `ocb_customer_id` is the analytical customer key

`ocb_customer_id` is the canonical OCB-wide customer identifier.

Source-system customer identifiers remain available for lineage and source-specific analysis but are not used as the primary cross-domain analytical customer key.

`cross_domain_id` is retained as an identity-resolution and validation control. It is not the primary OLAP customer key.

### 2.4 Event timestamps remain available

Time dimensions provide calendar context, while fact tables retain the precise event timestamp required for temporal analysis.

This distinction is important because analytical workloads may require both:

* calendar aggregation — day, month, quarter, year; and
* event sequencing — transaction intervals, velocity, time between repayment events, and other temporal measures.

### 2.5 Dimensions are not created merely because a field is categorical

A field becomes a separate dimension only where doing so provides a meaningful and reusable analytical structure.

Consequently, not every categorical source attribute receives its own dimension.

---

# 3. Foundational Fact Tables

## 3.1 `fact_transaction`

**Grain:** One row per Ananse Telecom transaction.

The transaction fact represents individual mobile-money financial events originating from Ananse Telecom.

Typical analytical measures include:

* transaction amount
* transaction counts
* successful transaction volume
* failed transaction volume where analytically required
* transaction frequency
* transaction timing
* aggregated transaction value

The fact is associated with the customer responsible for the transaction, the transaction date/time, institution, transaction channel, transaction type, and physical transaction location.

### Primary analytical relationships

* Customer → `dim_customer`
* Time → `dim_time`
* Institution → `dim_institution`
* Channel → `dim_channel`
* Transaction type → `dim_transaction_type`
* Location → `dim_geography`

---

## 3.2 `fact_loan`

**Grain:** One row per SikaCredit loan.

The loan fact represents the creation/disbursement of an individual digital loan.

The fact supports analysis of lending activity, loan values, borrower behaviour, institutional lending activity, and the relationship between lending and subsequent repayment activity.

### Primary analytical relationships

* Customer → `dim_customer`
* Time → `dim_time`
* Institution → `dim_institution`
* Disbursement location → `dim_geography`

The loan identifier remains the natural business reference for the individual loan.

A separate `dim_loan` is **not** introduced in the current model. Loan-specific analytical attributes belong with the loan fact unless future analytical requirements demonstrate a genuine need for a separate loan dimension.

---

## 3.3 `fact_repayment`

**Grain:** One row per SikaCredit repayment.

The repayment fact represents an individual repayment event against a SikaCredit loan.

Each repayment retains a reference to the originating `loan_id`. This establishes the relationship between repayment activity and the loan without introducing a separate `dim_loan`.

The fact also retains the resolved `ocb_customer_id`, allowing direct cross-domain customer analysis while preserving the underlying loan relationship.

### Primary analytical relationships

* Customer → `dim_customer`
* Time → `dim_time`
* Institution → `dim_institution`
* Repayment location → `dim_geography`
* Loan → `loan_id` reference

The repayment fact therefore supports both:

* repayment-level analysis; and
* analysis of repayment behaviour relative to the originating loan.

---

## 3.4 `fact_remittance`

**Grain:** One row per Oman Remit remittance.

The remittance fact represents an individual cross-border remittance event.

The fact supports analysis of remittance volume, value, frequency, channels, remittance classifications, geographic activity, and origin-country exposure.

### Primary analytical relationships

* Customer → `dim_customer`
* Time → `dim_time`
* Institution → `dim_institution`
* Channel → `dim_channel`
* Location → `dim_geography`
* Origin country → `dim_country`

`remittance_type` remains an attribute of the remittance fact in v1.0.0. A separate dimension is not introduced because the current analytical requirements do not establish sufficient justification for one.

---

# 4. Conformed Dimensions

## 4.1 `dim_customer`

**Purpose:** Provide the canonical OCB-wide customer context used across all financial domains.

The dimension is keyed by `ocb_customer_id`.

It provides customer attributes required for cross-institutional and cross-domain analysis.

The dimension represents the resolved OCB customer rather than an individual source-system customer record.

### Used by

* `fact_transaction`
* `fact_loan`
* `fact_repayment`
* `fact_remittance`

This is the primary conformed dimension enabling analysis such as:

> How does the financial activity of the same OCB customer differ across Ananse Telecom, SikaCredit, and Oman Remit?

---

## 4.2 `dim_time`

**Purpose:** Provide standard calendar and temporal context for all analytical facts.

The dimension supports aggregation and comparison by:

* date
* day
* week
* month
* quarter
* year
* weekday
* weekend/weekday classification
* other approved calendar attributes

Each fact retains its precise event timestamp in addition to the associated date key.

### Used by

* `fact_transaction`
* `fact_loan`
* `fact_repayment`
* `fact_remittance`

`dim_time` provides calendar context; it does not replace the precise event timestamp required for temporal and sequence analysis.

---

## 4.3 `dim_institution`

**Purpose:** Provide a common analytical representation of the financial institutions participating in the OCB ecosystem.

The dimension allows activity from different source systems to be analysed using a common institutional structure.

### Used by

* `fact_transaction`
* `fact_loan`
* `fact_repayment`
* `fact_remittance`

The institution dimension enables cross-institutional analysis without requiring analysts to interpret source-system names independently.

---

## 4.4 `dim_geography`

**Purpose:** Provide a common representation of the physical location associated with a financial event.

This dimension represents **event/activity location**, not customer residence or customer location.

The current model contains location attributes for:

* Ananse transaction location
* SikaCredit loan disbursement location
* SikaCredit repayment location
* Oman Remit remittance location

The geography dimension therefore provides a reusable analytical structure for region and town-level activity.

### Used by

* `fact_transaction`
* `fact_loan`
* `fact_repayment`
* `fact_remittance`

The same dimension is effectively role-played according to the business event:

* transaction location
* loan disbursement location
* repayment location
* remittance location

No customer-location relationship is implied.

---

# 5. Process and Context Dimensions

## 5.1 `dim_channel`

**Purpose:** Standardise the channel through which applicable financial activity occurs.

The dimension supports channel-level analysis across business processes where channel information exists.

Current applicable domains include:

* Ananse Telecom transactions
* Oman Remit remittances

The dimension is not forced onto facts for which a channel is not currently established in the source model.

### Used by

* `fact_transaction`
* `fact_remittance`

---

## 5.2 `dim_transaction_type`

**Purpose:** Classify Ananse Telecom transaction activity according to its transaction type.

The dimension supports analysis of transaction behaviour by financial transaction category.

It applies specifically to the Ananse transaction process.

### Used by

* `fact_transaction`

`remittance_type` is not incorporated into this dimension because it represents a different business-process classification within Oman Remit.

---

## 5.3 `dim_country`

**Purpose:** Provide geographic country context for cross-border remittance analysis.

In the current model, the relevant country attribute is the **origin country** associated with Oman Remit activity.

### Used by

* `fact_remittance`

No destination-country attribute is introduced because a destination country is not currently established as an observed Silver/Gold attribute.

If future source data introduces destination-country information, its dimensional treatment can be reassessed at that point.

---

# 6. Fact-to-Dimension Relationship Matrix

| Analytical Structure        | Transaction | Loan | Repayment | Remittance |
| --------------------------- | :---------: | :--: | :-------: | :--------: |
| `dim_customer`              |      ✓      |   ✓  |     ✓     |      ✓     |
| `dim_time`                  |      ✓      |   ✓  |     ✓     |      ✓     |
| `dim_institution`           |      ✓      |   ✓  |     ✓     |      ✓     |
| `dim_geography`             |      ✓      |   ✓  |     ✓     |      ✓     |
| `dim_channel`               |      ✓      |   —  |     —     |      ✓     |
| `dim_transaction_type`      |      ✓      |   —  |     —     |      —     |
| `dim_country`               |      —      |   —  |     —     |      ✓     |
| `remittance_type` attribute |      —      |   —  |     —     |      ✓     |
| `loan_id` reference         |      —      |   —  |     ✓     |      —     |

---

# 7. Deliberately Excluded Structures

The following structures are **not part of the v1.0.0 dimensional model**.

### 7.1 `dim_currency`

A separate currency dimension is not required because the current analytical dataset is denominated in GHS.

Monetary measures therefore remain directly associated with their respective facts.

A currency dimension can be introduced if the platform later supports genuinely multi-currency analytical requirements.

### 7.2 `dim_loan`

A separate loan dimension is not currently justified.

The loan itself is an analytical event at the established loan grain, represented by `fact_loan`.

The `loan_id` reference on `fact_repayment` is sufficient to connect repayment events to their originating loan.

### 7.3 `fact_wallet_event`

A separate wallet-event fact is not established because the current source model does not define an independent wallet-event grain distinct from the underlying financial transaction.

Creating such a fact would duplicate event information without providing a sufficiently distinct analytical grain.

### 7.4 Risk, anomaly, velocity and behavioural fact tables

No separate facts are created for:

* anomaly scores
* Z-scores
* velocity
* behavioural scores
* fraud indicators
* liquidity pressure
* risk scores

These are analytical constructs derived from the foundational event facts.

Their eventual implementation belongs to the intelligence workloads of Programme 5 rather than the foundational dimensional model itself.

---

# 8. Final Logical Model

The v1.0.0 analytical warehouse therefore consists of four foundational facts:

```text
fact_transaction
fact_loan
fact_repayment
fact_remittance
```

and the following dimensions/context structures:

```text
dim_customer
dim_time
dim_institution
dim_geography
dim_channel
dim_transaction_type
dim_country
```

with:

```text
remittance_type  → fact_remittance attribute
loan_id          → fact_repayment reference to fact_loan
```