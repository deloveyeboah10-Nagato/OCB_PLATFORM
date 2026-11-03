# OCB PLATFORM v1.0.0

## GOLD / ANALYTICAL MODEL

**Programme:** OCB Platform v1.0.0  
**Work Package:** Gold / Analytical Model  
**Component:** Gold Analytical Layer  
**Purpose:** Establish workload-driven analytical structures over trusted Silver data  
**Implementation Status:** Initial Gold analytical foundation implemented as views

---

# 1. PURPOSE

This Document establishes the analytical structures required to support OCB's current intelligence workloads.

The Gold layer provides reusable analytical representations of trusted Silver data for:

- Financial intelligence and supervisory monitoring.
- Transaction and customer behaviour analysis.
- Fraud and anomaly investigation.
- AML and transaction-monitoring analysis.
- Lending and credit-risk analysis.
- Repayment analysis.
- Remittance and cross-institution analysis.
- Regulatory reporting and institutional comparison.

Gold is workload-driven. A Silver table, reference table, candidate fact, or candidate dimension does not automatically require a corresponding Gold structure.

The initial Gold foundation consists of reusable analytical views. Additional structures are introduced only when an identifiable analytical requirement justifies them.

This work package establishes the analytical interface over Silver data. It does not establish the final dimensional warehouse or OLAP schema, which belongs to Programme 4.

---

# 2. ARCHITECTURAL PRINCIPLE

The decision to create a Gold structure follows the analytical requirement rather than the physical existence of a source table.

```text
INTELLIGENCE QUESTION
        |
        v
ANALYTICAL WORKLOAD
        |
        v
REQUIRED ANALYTICAL GRAIN
        |
        v
EVALUATE TRUSTED SILVER DATA
        |
        v
Can Silver support the workload directly?
        |
        +-----------------------+
        |                       |
       YES                      NO
        |                       |
        v                       v
Use Silver directly      Create a justified
where appropriate        Gold structure
        |                       |
        +-----------+-----------+
                    |
                    v
             ANALYTICAL OUTPUT
```

Gold must provide a clear analytical benefit, such as reusable business logic, integration, a stable analytical interface, or justified performance optimization.

It must not duplicate Silver merely to create another layer of storage.

---

# 3. INITIAL GOLD ANALYTICAL FOUNDATION

The initial Gold foundation consists of six analytical views.

| Structure | Grain | Primary purpose |
|---|---|---|
| `gold.vw_customer` | One row per canonical OCB customer | Customer-level and cross-institution analysis |
| `gold.vw_institution` | One row per participating institution | Institutional classification and comparison |
| `gold.vw_transaction` | One row per Ananse transaction | Transaction intelligence and behavioural analysis |
| `gold.vw_loan` | One row per SikaCredit loan | Loan origination and credit-exposure analysis |
| `gold.vw_repayment` | One row per SikaCredit repayment event | Repayment behaviour and credit-risk analysis |
| `gold.vw_remittance` | One row per Oman Remit remittance | Remittance and cross-border analysis |

These views constitute the initial Gold analytical interface.

Each view retains the natural grain of its underlying business process. Aggregation, behavioural calculations, and cross-domain analysis are performed according to the requirements of the consuming workload.

The six views are not intended to represent the complete set of analytical structures that OCB may eventually require.

---

# 4. CUSTOMER ANALYTICAL VIEW

**Structure:** `gold.vw_customer`  
**Source:** `silver.ocb_customer_unified`  
**Grain:** One row per canonical OCB customer  
**Analytical key:** `ocb_customer_id`

## Purpose

Provides the canonical customer representation used to organize customer-level analysis across Ananse Telecom, SikaCredit, and Oman Remit.

## Core attributes

- `ocb_customer_key`
- `first_name`
- `last_name`
- `date_of_birth`
- `phone_number`
- `email`

The customer view provides a reusable analytical representation of the canonical OCB customer.

Source-specific identity relationships remain governed by `silver.ocb_customer_identity`. The customer view does not independently perform identity resolution or redefine the validated identity mapping.

The view supports customer-level analysis by providing the common analytical identity required to associate activity across the participating institutions.

---

# 5. INSTITUTION ANALYTICAL VIEW

**Structure:** `gold.vw_institution`  
**Source:** `silver.ocb_institution`  
**Grain:** One row per participating institution or source domain

## Participating institutions

- Ananse Telecom.
- SikaCredit.
- Oman Remit.

## Purpose

Provides a common institutional classification for analytical workloads requiring institutional identification, comparison, or grouping.

The view contains only institutional attributes supported by the implemented model and justified by analytical requirements.

It does not introduce unsupported institutional metadata or imply that the participating institutions share operational databases, accounts, or transaction-processing infrastructure.

The institutional view provides an analytical classification layer, not an operational integration mechanism.

---

# 6. TRANSACTION ANALYTICAL VIEW

**Structure:** `gold.vw_transaction`  
**Source:** `silver.ananse_transaction`  
**Grain:** One row per Ananse transaction  
**Analytical key:** `transaction_id`

## Purpose

Provides the transaction-level analytical interface for Ananse Telecom.

It supports:

- Transaction-volume analysis.
- Transaction-value analysis.
- Customer activity analysis.
- Transaction-type analysis.
- Channel analysis.
- Transaction-status analysis.
- Temporal analysis.
- Geographic analysis.
- Device-related analysis where supported.
- Anomaly and risk analysis.

## Core relationships

- `ocb_customer_id`
- `wallet_id`

## Core attributes and measures

- `transaction_timestamp`
- `transaction_amount`
- `transaction_type`
- `transaction_channel`
- `transaction_status`
- Currency.
- Location.
- Region.
- Town.
- `device_id`

The precise column names must remain consistent with the implemented Gold view.

## Grain preservation

The view retains one row per transaction.

It does not pre-aggregate transactions by customer, wallet, day, month, quarter, channel, or another analytical grouping.

This preserves the ability to investigate individual events and construct workload-specific aggregations without losing transaction-level detail.

Wallet activity is analysed through transaction events and their `wallet_id` relationships. A separate wallet-activity view is not required because the current wallet structure does not represent an independent wallet-event history.

---

# 7. LOAN ANALYTICAL VIEW

**Structure:** `gold.vw_loan`  
**Source:** `silver.sikacredit_loan`  
**Grain:** One row per SikaCredit loan  
**Analytical key:** `loan_id`

## Purpose

Provides the loan-level analytical interface for lending and credit-exposure workloads.

It supports:

- Loan origination analysis.
- Principal-disbursement analysis.
- Credit-exposure analysis.
- Interest-rate analysis.
- Loan-type analysis.
- Maturity analysis.
- Customer credit analysis.
- Geographic analysis.
- Cross-institution customer analysis.

## Core relationship

- `ocb_customer_id`

## Core attributes and measures

- `loan_type`
- `principal_amount`
- `interest_rate`
- `disbursement_timestamp`
- `maturity_date`
- Currency.
- Location.
- Region.
- Town.

The view retains one row per loan.

Loans remain separate from repayments because loan origination and repayment are different business processes with different natural grains.

A loan may have multiple repayment events. Joining loans directly to repayments can therefore multiply loan-level values unless the analysis explicitly accounts for the resulting relationship.

Loan-level measures must be calculated at the loan grain or aggregated from a correctly controlled loan-level result.

---

# 8. REPAYMENT ANALYTICAL VIEW

**Structure:** `gold.vw_repayment`  
**Source:** `silver.sikacredit_repayment`  
**Grain:** One row per SikaCredit repayment event  
**Analytical key:** `repayment_id`

## Purpose

Provides the repayment-event analytical interface for credit and repayment-monitoring workloads.

It supports:

- Repayment-volume analysis.
- Repayment-value analysis.
- Repayment-timing analysis.
- Customer repayment behaviour.
- Loan-level repayment analysis.
- Credit-risk analysis.

## Core relationships

- `loan_id`
- `ocb_customer_id`

## Core attributes and measures

- `repayment_amount`
- `repayment_timestamp`
- Location.
- Region.
- Town.

The repayment view preserves the repayment-event grain.

The `loan_id` relationship connects a repayment to its corresponding loan. The `ocb_customer_id` provides the customer identity inherited through that loan relationship.

The view does not treat a repayment as a separate loan or duplicate loan origination records.

Analytical calculations involving both loans and repayments must account for their different grains to avoid overstating principal or repayment values.

---

# 9. REMITTANCE ANALYTICAL VIEW

**Structure:** `gold.vw_remittance`  
**Source:** `silver.oman_remit_remittance`  
**Grain:** One row per Oman Remit remittance  
**Analytical key:** `remittance_id`

## Purpose

Provides the remittance-level analytical interface for remittance and cross-border intelligence.

It supports:

- Remittance-volume analysis.
- Remittance-value analysis.
- Inbound and outbound flow analysis.
- Origin-country analysis.
- Customer remittance behaviour.
- Channel analysis.
- Geographic analysis.
- Cross-border financial intelligence.

## Core relationship

- `ocb_customer_id`

## Core attributes and measures

- Origin country.
- `remittance_type`
- `remittance_status`
- `remittance_timestamp`
- `remittance_amount`
- Currency.
- Location.
- Region.
- Town.
- Channel.

The exact column names must remain consistent with the implemented Gold view.

## Remittance classification

The current simulation derives `remittance_type` from the standardized origin country:

| Condition | Classification |
|---|---|
| `remittance_origin_country = 'ghana'` | `remittance_sent` |
| `remittance_origin_country <> 'ghana'` | `remittance_received` |

The classification remains an attribute of the remittance view.

A separate remittance-type view is not required merely to expose this attribute.

This is the implemented project-specific classification rule, not a claim that origin country alone provides a complete classification for every real-world remittance scenario.

---

# 10. ANALYTICAL ATTRIBUTES AND MEASURES

Attributes and measures belong to the analytical structure whose business process they describe.

For example, transaction attributes remain associated with the transaction view:

```text
gold.vw_transaction
    |
    +-- transaction_timestamp
    +-- transaction_amount
    +-- transaction_type
    +-- transaction_channel
    +-- transaction_status
    +-- currency
    +-- geographic attributes
```

Remittance attributes remain associated with the remittance view:

```text
gold.vw_remittance
    |
    +-- remittance_timestamp
    +-- remittance_amount
    +-- remittance_type
    +-- remittance_status
    +-- origin_country
    +-- currency
    +-- channel
    +-- geographic attributes
```

The presence of a descriptive attribute does not automatically justify an independent Gold structure.

The objective is to maintain a lean and composable analytical foundation while avoiding unnecessary duplication.

---

# 11. TEMPORAL ANALYSIS

Event timestamps represent the recorded times of business events.

Examples include:

- `transaction_timestamp`
- `disbursement_timestamp`
- `repayment_timestamp`
- `remittance_timestamp`

These timestamps support daily, weekly, monthly, quarterly, and yearly analysis, as well as period-over-period comparisons and workload-specific rolling windows.

Examples of rolling windows include:

- Seven days.
- Thirty days.
- Ninety days.

A rolling window is an analytical calculation, not an independent dimension.

Similarly, deriving a reporting month or quarter from an event timestamp does not automatically justify a separate Gold time view.

A formal `dim_time` may be introduced under Programme 4 if the final dimensional and OLAP requirements justify it.

---

# 12. ANALYTICAL COMPOSITION

The six foundational views are designed to support analytical composition without forcing different business processes into a single structure.

```text
                  gold.vw_customer
                         |
                  ocb_customer_id
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
 gold.vw_transaction gold.vw_loan gold.vw_remittance
                         |
                       loan_id
                         |
                         v
                  gold.vw_repayment
```

This represents the principal analytical relationships, not an instruction to join every view in every query.

The appropriate joins depend on the analytical question and the grain of the measures being calculated.

For example:

- Customer-level analysis may aggregate each business process to customer grain before combining results.
- Loan analysis may use repayment events to calculate repayment performance.
- Cross-institution analysis may compare activity from separate domains using `ocb_customer_id`.
- Transaction analysis may use `wallet_id` to investigate activity associated with a wallet.

**Cross-domain analysis does not require a generic `financial_activity` view.**

Transactions, loans, repayments, and remittances remain separate analytical structures because they represent different business processes and grains.

---

# 13. ADDITIONAL GOLD STRUCTURES

The six foundational views are the initial analytical interface, not the complete set of structures that may eventually be justified.

Additional structures may be introduced when actual analytical workloads demonstrate a requirement for reusable calculations, aggregation, performance optimization, or specialized analytical outputs.

Potential additions include:

- Analytical views.
- Summary tables.
- Aggregates.
- Customer-activity structures.
- Transaction-velocity calculations.
- Channel-analysis structures.
- Behavioural analytical structures.
- Lending and exposure summaries.
- Cross-institution analytical structures.
- Specialized intelligence-support structures.

Examples of potential derivations include:

```text
gold.vw_transaction
        |
        +-- Transaction summaries
        +-- Customer activity aggregates
        +-- Velocity calculations
        +-- Channel analysis
        +-- Behavioural analysis
```

And:

```text
gold.vw_customer
gold.vw_transaction
gold.vw_loan
gold.vw_repayment
gold.vw_remittance
        |
        +-- Customer activity
        +-- Lending exposure
        +-- Repayment behaviour
        +-- Cross-institution activity
        +-- Customer-level risk analysis
```

These are potential analytical workloads, not a commitment to create every listed structure.

Each additional structure must have a defined purpose, an appropriate grain, and a demonstrated reason to exist independently of the foundational views.

---

# 14. MATERIALIZATION POLICY

The initial Gold foundation is implemented as analytical views.

Additional structures may be materialized when the workload justifies the added storage and maintenance requirements.

Potential justifications include:

- Repeated expensive computations.
- Demonstrated performance limitations.
- High-frequency analytical consumption.
- Reusable precomputed calculations.
- Historical snapshot requirements.
- Workload isolation.
- Other documented architectural requirements.

Materialization is workload-driven rather than automatic.

A view must not be converted into a physical table merely because it exists or because materialization is generally associated with data warehousing.

The decision must account for the actual workload, freshness requirements, maintenance cost, and performance benefit.

---

# 15. EXPLICITLY REJECTED STRUCTURES

## 15.1 `gold.vw_wallet_activity`

**Decision: Rejected for the current architecture.**

The current Silver wallet structure represents wallet ownership and relationship information. It does not contain an independent wallet-activity event history.

Consequently, there is no separate wallet-activity grain to expose through this view.

Wallet activity is analysed through transaction events using `wallet_id`.

The decision may be reconsidered only if a genuine wallet-event dataset or a demonstrated analytical requirement establishes a distinct wallet-activity grain.

## 15.2 `gold.vw_financial_activity`

**Decision: Rejected for the current architecture.**

Transactions, loans, repayments, and remittances represent different business processes with different natural grains.

Combining them into one generic structure risks obscuring their distinct relationships and creating ambiguous measures or duplicated values.

They therefore remain separate analytical views.

Cross-domain analysis is achieved through appropriate relationships, aggregations, and analytical queries rather than forcing every event into one generic structure.

## 15.3 Standalone Attribute and Reference Views

The following are not included in the initial Gold foundation:

- `gold.vw_transaction_type`
- `gold.vw_transaction_channel`
- `gold.vw_transaction_status`
- `gold.vw_currency`
- `gold.vw_country`
- `gold.vw_remittance_type`
- `gold.vw_time`

Their attributes remain within the relevant analytical structures unless a later workload establishes a specific need for independent structures.

This decision does not prohibit dimensions from being established under Programme 4. It distinguishes the initial Gold analytical interface from the formal dimensional warehouse.

---

# 16. BOUNDARY WITH PROGRAMME 4

This document establishes the workload-driven Gold analytical foundation.

Programme 4 establishes the formal analytical warehouse and dimensional architecture.

The distinction is:

```text

Trusted Silver Data
        |
        v
Initial Gold Analytical Views
        |
        v
Workload-Justified Analytical Structures
        |
        v
PROGRAMME 4
Formal Dimensional Warehouse / OLAP Model
```

Programme 4 determines the final dimensional architecture, including where justified:

- Fact tables.
- Dimension tables.
- Fact-table grain.
- Measures.
- Dimensional keys.
- Conformed dimensions.
- Time dimensions.
- Dimensional relationships.
- Star schemas.
- Other OLAP structures.

Candidate facts and dimensions identified in the Project Control Document are not, by themselves, proof that every proposed structure should be implemented.

Their final existence, grain, keys, measures, dimensions, and relationships must be determined from the analytical requirements and the reconciled data model.

The Gold views provide an analytical foundation for that work. They do not predetermine the final physical dimensional schema.

---

# 17. RELATIONSHIP TO ANALYTICAL INTERFACES

The formal dimensional warehouse and other justified analytical structures may support reusable interfaces for:

- Customer activity.
- Transaction behaviour.
- Transaction velocity.
- Liquidity analysis.
- Lending and credit exposure.
- Repayment monitoring.
- Remittance analysis.
- Institutional monitoring.
- Financial-system pressure monitoring.
- Other defined intelligence workloads.

Depending on the final architecture, these interfaces may consume:

- The formal dimensional warehouse.
- Foundational Gold views.
- Additional Gold analytical views.
- Materialized summaries.
- Aggregates.
- Other justified analytical structures.

The appropriate source depends on the workload, its required grain, the measures involved, and its performance and freshness requirements.

The objective is to provide reliable analytical interfaces without introducing unnecessary intermediate structures.

---

# 18. FINAL IMPLEMENTATION POSITION

This document establishes six foundational Gold analytical views:

```text
gold.vw_customer
gold.vw_institution
gold.vw_transaction
gold.vw_loan
gold.vw_repayment
gold.vw_remittance
```

These views provide reusable analytical representations of trusted Silver data while preserving the natural grain of their respective business processes.

Additional Gold structures are introduced only when a defined workload justifies them.

The formal fact-and-dimension model, star schemas, and OLAP warehouse belong to Programme 4.

The final implementation must remain consistent with the actual Silver schema, identity mapping, source relationships, and implemented Gold view definitions.

---

# 19. GOVERNING PRINCIPLE

> **Gold is a workload-driven analytical layer, not a duplicate storage layer and not the final dimensional warehouse.**

> **Build the smallest reusable analytical structure that reliably supports the workload. Introduce additional structures or materialization only when the requirement justifies their complexity and maintenance cost.**