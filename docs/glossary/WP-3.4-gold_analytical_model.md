# OCB PLATFORM v1.0.0

## WORK PACKAGE 3.4 — GOLD / ANALYTICAL MODEL

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-3.4 — Gold / Analytical Model
**Component:** Gold Analytical Layer
**Purpose:** Establish workload-driven analytical structures over trusted Silver data
**Implementation Status:** Defined — Initial Gold foundation implemented as analytical views

---

# 1. Purpose

WP-3.4 establishes the **Gold analytical structures required by the current analytical workload**.

The Gold layer transforms trusted Silver data into reusable analytical structures supporting OCB intelligence, reporting, risk, AML, fraud, behavioural, and cross-institution analysis.

Gold is **workload-driven**.

The existence of a Silver table, candidate fact, dimension, or reference structure does not automatically require a corresponding Gold structure.

The initial Gold foundation is implemented as **reusable analytical views** over trusted Silver data.

These views establish the analytical grains and attributes from which additional structures may be derived where justified by actual workloads.

---

# 2. Gold Architectural Principle

```text
OCB Intelligence Questions
        ↓
Analytical Workloads
        ↓
Required Analytical Grain
        ↓
Evaluate Trusted Silver Data
        ↓
Can Silver support the workload directly?
        ├── YES
        │    ↓
        │  Use Silver directly
        │
        └── NO
             ↓
       Create justified
       Gold analytical structure
```

Gold therefore does not exist to duplicate Silver.

It exists to provide an analytical abstraction, transformation, integration, or optimization where the workload benefits from one.

---

# 3. Initial Gold Analytical Foundation

The initial Gold analytical foundation consists of six analytical views.

| Gold Structure        | Grain                                               | Primary Analytical Purpose                        |
| --------------------- | --------------------------------------------------- | ------------------------------------------------- |
| `gold.vw_customer`    | One row per canonical OCB customer                  | Customer-level and cross-institution analysis     |
| `gold.vw_institution` | One row per participating institution/source domain | Institutional activity and comparison             |
| `gold.vw_transaction` | One row per Ananse transaction                      | Transaction intelligence and behavioural analysis |
| `gold.vw_loan`        | One row per SikaCredit loan                         | Lending and credit-exposure analysis              |
| `gold.vw_repayment`   | One row per SikaCredit repayment event              | Repayment and credit-risk analysis                |
| `gold.vw_remittance`  | One row per Oman Remit remittance                   | Remittance and cross-border analysis              |

These six views constitute the **initial Gold analytical interface**.

They are not the final dimensional or OLAP warehouse model.

---

# 4. Customer Analytical View

**Structure:** `gold.vw_customer`
**Source:** `silver.ocb_customer_unified`
**Grain:** One row per canonical OCB customer
**Primary Key:** `ocb_customer_id`

### Purpose

Provides a reusable customer-level analytical structure for aggregating and comparing activity across ANANSE TELECOM, SIKACREDIT, and OMAN REMIT.

### Core Attributes

* `ocb_customer_key`
* `first_name`
* `last_name`
* `date_of_birth`
* `phone_number`
* `email`

The view represents the canonical OCB customer.

Source-specific identity relationships remain governed by `silver.ocb_customer_identity` and are not unnecessarily reproduced as analytical customer attributes.

---

# 5. Institution Analytical View

**Structure:** `gold.vw_institution`
**Source:** silver.ocb_institution
**Grain:** One row per participating institution/source domain

### Current Institutions

* ANANSE TELECOM
* SIKACREDIT
* OMAN REMIT

### Purpose

Provides a common analytical classification for institutional activity and cross-institution comparison.

Only institution attributes justified by analytical requirements are included.

Unsupported institutional metadata is not introduced merely to enrich the view.

---

# 6. Transaction Analytical View

**Structure:** `gold.vw_transaction`
**Source:** `silver.ananse_transaction`
**Grain:** One row per Ananse transaction
**Primary Key:** `transaction_id`

### Purpose

Supports:

* transaction-volume analysis;
* transaction-value analysis;
* customer behaviour analysis;
* transaction-type analysis;
* channel analysis;
* status analysis;
* temporal analysis;
* geographic analysis;
* device-related analysis where justified;
* anomaly and risk analysis.

### Customer and Wallet Relationships

* `ocb_customer_id`
* `wallet_id`

### Core Attributes and Measures

* `transaction_timestamp`
* `transaction_amount`
* `transaction_type`
* `transaction_channel`
* `transaction_status`
* `currency`
* `location`
* `region`
* `town`
* `device_id`

The transaction view preserves the atomic transaction grain.

It does not pre-aggregate transactions into customer, daily, monthly, quarterly, or other summary grains.

---

# 7. Loan Analytical View

**Structure:** `gold.vw_loan`
**Source:** `silver.sikacredit_loan`
**Grain:** One row per SikaCredit loan
**Primary Key:** `loan_id`

### Purpose

Supports:

* loan origination analysis;
* credit-exposure analysis;
* principal-value analysis;
* interest-rate analysis;
* loan-type analysis;
* maturity analysis;
* customer credit analysis;
* geographic analysis;
* cross-institution exposure analysis.

### Customer Relationship

* `ocb_customer_id`

### Core Attributes and Measures

* `loan_type`
* `principal_amount`
* `interest_rate`
* `disbursement_timestamp`
* `maturity_date`
* `currency`
* `location`
* `region`
* `town`

Loans remain separate from repayment events because they represent a different business process and analytical grain.

---

# 8. Repayment Analytical View

**Structure:** `gold.vw_repayment`
**Source:** `silver.sikacredit_repayment`
**Grain:** One row per SikaCredit repayment event
**Primary Key:** `repayment_id`

### Purpose

Supports:

* repayment-volume analysis;
* repayment-value analysis;
* repayment timing;
* customer repayment behaviour;
* loan-level repayment analysis;
* credit-risk analysis.

### Relationships

* `loan_id`
* `ocb_customer_id`

### Core Attributes and Measures

* `repayment_amount`
* `repayment_timestamp`
* `location`
* `region`
* `town`

Repayments remain separate from loans because multiple repayment events may relate to a single loan.

---

# 9. Remittance Analytical View

**Structure:** `gold.vw_remittance`
**Source:** `silver.oman_remit_remittance`
**Grain:** One row per Oman Remit remittance
**Primary Key:** `remittance_id`

### Purpose

Supports:

* remittance-volume analysis;
* remittance-value analysis;
* inbound/outbound flow analysis;
* origin-country analysis;
* customer remittance behaviour;
* channel analysis;
* geographic analysis;
* cross-border financial intelligence.

### Customer Relationship

* `ocb_customer_id`

### Core Attributes and Measures

* `origin_country`
* `remittance_type`
* `remittance_status`
* `remittance_timestamp`
* `remittance_amount`
* `currency`
* `location`
* `region`
* `town`
* `channel`

`remittance_type` remains an attribute of the remittance analytical structure.

The current classification is:

```text
origin_country = Ghana
        ↓
remittance_sent

origin_country ≠ Ghana
        ↓
remittance_received
```

No separate remittance-type analytical structure is required.

---

# 10. Analytical Attributes and Measures

Attributes and measures belong to the analytical structure whose business process they describe.

For example:

```text
gold.vw_transaction
    ├── transaction_timestamp
    ├── transaction_amount
    ├── transaction_type
    ├── transaction_channel
    ├── transaction_status
    ├── currency
    └── geographic attributes
```

and:

```text
gold.vw_remittance
    ├── origin_country
    ├── remittance_type
    ├── remittance_status
    ├── remittance_timestamp
    ├── remittance_amount
    ├── currency
    └── geographic attributes
```

These attributes do not automatically become independent Gold structures.

The objective is to keep the analytical interface **lean, composable, and reusable**.

---

# 11. Temporal Analysis

Event timestamps are factual observations describing when business events occur.

Examples include:

```text
transaction_timestamp
disbursement_timestamp
repayment_timestamp
remittance_timestamp
```

These timestamps support:

* daily analysis;
* weekly analysis;
* monthly analysis;
* quarterly analysis;
* yearly analysis;
* period-over-period analysis;
* rolling 7-day windows;
* rolling 30-day windows;
* rolling 90-day windows;
* other workload-specific time windows.

A rolling window is an **analytical calculation**, not an independent dimension.

Calendar attributes derived from timestamps likewise do not automatically require a Gold time view.

A formal `dim_time` may be introduced under Programme 4 if the dimensional/OLAP workload justifies it.

---

# 12. Analytical Composition

The six foundational views are designed to be composable.

```text
                         gold.vw_customer
                                │
                         ocb_customer_id
                                │
             ┌──────────────────┼──────────────────┐
             │                  │                  │
             ▼                  ▼                  ▼
   gold.vw_transaction    gold.vw_loan     gold.vw_remittance
                                │
                                loan_id
                                │
                                ▼
                         gold.vw_repayment
```

This allows analytical workloads to combine customer, transaction, lending, repayment, and remittance information according to the question being investigated.

No generic `financial_activity` structure is required merely to achieve cross-domain analysis.

---

# 13. Further Gold Structures

The six initial analytical views are **foundational structures**, not the complete universe of possible Gold structures.

Where actual analytical workloads justify additional reuse, performance, or precomputation, further Gold structures may be introduced, including:

1. analytical structures;
2. summary tables;
3. aggregates;
4. analytical views;
5. data marts;
6. precomputed intelligence-support structures.

For example:

```text
gold.vw_transaction
        ↓
        ├── transaction summaries
        ├── customer activity aggregates
        ├── velocity calculations
        ├── channel analysis
        └── behavioural analytical structures
```

And:

```text
gold.vw_customer
gold.vw_transaction
gold.vw_loan
gold.vw_repayment
gold.vw_remittance
        ↓
        ├── customer activity
        ├── liquidity
        ├── lending exposure
        ├── cross-institution activity
        └── customer-level risk analysis
```

These additional structures are **not created speculatively**.

Each must be justified by a demonstrated analytical workload.

---

# 14. Materialization Policy

The initial Gold analytical foundation is implemented as **views**.

Further Gold structures may be materialized where there is a demonstrated requirement.

Potential reasons include:

* repeated expensive computation;
* performance requirements;
* high-frequency analytical consumption;
* precomputation of complex analytical logic;
* historical snapshot requirements;
* workload isolation;
* other documented architectural requirements.

Materialization is therefore **workload-driven**, not automatic.

A view should not be converted into a physical table merely because it exists.

---

# 15. Explicitly Rejected Structures

## 15.1 `gold.vw_wallet_activity`

**Rejected.**

The current Silver wallet structure represents wallet ownership and relationship information but does not contain an independent wallet activity-event history.

There is therefore no independent wallet-activity grain to expose.

Wallet activity is analysed through transaction events using `wallet_id`.

## 15.2 `gold.vw_financial_activity`

**Rejected.**

Transactions, loans, repayments, and remittances represent different business processes and have different natural grains.

They therefore remain separate analytical structures.

## 15.3 Standalone Attribute / Reference Views

The following are not part of the initial Gold analytical foundation:

* `gold.vw_transaction_type`
* `gold.vw_transaction_channel`
* `gold.vw_transaction_status`
* `gold.vw_currency`
* `gold.vw_country`
* `gold.vw_remittance_type`
* `gold.vw_time`

These attributes remain within the relevant analytical views unless a later workload demonstrates that an independent structure is necessary.

---

# 16. Boundary with Programme 4

WP-3.4 establishes the **workload-driven Gold analytical foundation**.

Programme 4 subsequently determines the formal analytical warehouse and OLAP architecture.

The distinction is:

```text
WP-3.4
Trusted Silver Data
        ↓
Initial Gold Analytical Views
        ↓
Further Workload-Justified Structures
        ↓
Programme 4
Formal Warehouse / OLAP Model
```

Programme 4 may establish, where justified:

* fact tables;
* dimension tables;
* dimensional keys;
* conformed dimensions;
* time dimensions;
* dimensional relationships;
* star schemas;
* other OLAP structures.

The candidate fact and dimension structures listed in the Project Control Document are therefore **not treated as a pre-committed physical schema**.

Their final existence, grain, measures, dimensions, keys, and relationships are determined from the actual analytical workloads and final data model.

---

# 17. Relationship to Analytical Interfaces

The formal warehouse model established under Programme 4 can support reusable analytical interfaces for areas such as:

* customer activity;
* transaction behaviour;
* velocity;
* liquidity;
* lending;
* remittances;
* institutional activity;
* other intelligence workloads identified during the programme.

These interfaces may consume:

* the formal dimensional warehouse;
* Gold analytical structures;
* materialized summaries;
* aggregates;
* or other justified analytical structures,

depending on the final architecture and workload requirements.

---

# 18. Final WP-3.4 Position

WP-3.4 establishes Gold analytical structures selected for the current workload, initially implemented as reusable analytical views.

The six foundational views are:

```text
gold.vw_customer
gold.vw_institution
gold.vw_transaction
gold.vw_loan
gold.vw_repayment
gold.vw_remittance
```

They provide reusable analytical grains over trusted Silver data.

Further Gold structures may be derived or materialized only where actual analytical workloads justify them.

The formal fact/dimension model, star schema, and OLAP warehouse are established subsequently under Programme 4.

---

# 19. Governing Principle

> **Gold is a workload-driven analytical layer, not a duplicate storage layer and not the final dimensional warehouse.**

> **Create the smallest reusable analytical structure that effectively supports the workload, and introduce additional materialized or dimensional structures only when the analytical requirement justifies them.**

```
```
