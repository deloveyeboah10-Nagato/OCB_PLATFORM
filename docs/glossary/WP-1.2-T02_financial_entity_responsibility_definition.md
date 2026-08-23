**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.2 — Financial Entity Model

**Ticket:** WP-1.2-T02

**Status:** **REVISED / RECONCILED**

**Decision Type:** Financial entity responsibility, ownership, authority, and lifecycle definitions

---

# Financial Entity Responsibility Definitions

## Purpose

This document establishes the business meaning, ownership, lifecycle, authoritative source, and analytical responsibility of the financial entities and identity concepts required by the OCB Platform v1.0.0 entity model.

The definitions have been reconciled against:

* the approved OCB Financial Event Catalogue;
* OCB Financial Event Semantics;
* OCB Financial Event / State Relationships;
* OCB Financial Correction and Reversal Semantics;
* the approved financial state model;
* the current conceptual and logical data model; and
* the defined OCB identity-resolution approach.

This document defines **business responsibility and entity semantics**.

It does not define physical database structures, schemas, columns, keys, normalization, ETL implementation, or institutional integration mechanisms.

---

# 1. Entity Responsibility Principle

OCB does not own the financial entities operated by Ananse Telecom, SikaCredit, or Oman Remit.

Each institutional domain remains authoritative for its own financial activity and financial state.

OCB performs three distinct functions:

```text
Institutional Financial Activity
            ↓
Source-Owned Financial Entities
            ↓
OCB Observation
            ↓
Identity Resolution / Analytical Correlation
            ↓
Cross-Institution Intelligence
```

The distinction between **source-owned entities**, **OCB analytical identity**, and **observable reference concepts** is therefore fundamental to the v1.0.0 model.

---

# 2. Institution

## Definition

An **Institution** represents an independent simulated institutional domain participating in the OCB financial ecosystem.

The v1.0.0 institutional domains are:

* Ananse Telecom;
* SikaCredit;
* Oman Remit.

## Responsibility

Institution establishes the ownership and authoritative-domain context of observable financial activity.

Each institution owns its own:

* customers;
* financial entities;
* financial events;
* financial state;
* business rules; and
* operational processes.

OCB does not operate or reproduce those institutional systems.

## Lifecycle

Institutional existence is established for the simulation and remains stable during the v1.0.0 operating period.

Financial activity within an institution may change over time without changing the institutional identity.

## Authoritative System

The originating institution's simulated operational domain is authoritative for its own financial activity and financial state.

## Relationships

An institution provides the domain context within which its source-owned financial entities and financial events exist.

## v1.0.0 Entity Treatment

Institution remains a **conceptual institutional boundary**, rather than a required first-class cross-institutional financial entity in the current relational model.

Its purpose is to establish ownership and source context rather than to impose a generic cross-institution financial-account architecture.

---

# 3. Customer

The term **Customer** must be distinguished between source-owned institutional customers and the OCB-resolved analytical identity.

## 3.1 Institutional Customer

### Definition

An **Institutional Customer** is a customer record owned by a specific originating institution.

Examples include:

```text
Ananse Customer
SikaCredit Customer
Oman Remit Customer
```

An institutional customer identifier is meaningful within its originating institutional domain.

### Ownership

The originating institution owns the customer relationship and its customer record.

### Authoritative System

The originating institution is authoritative for its institutional customer record and source-owned customer attributes.

### Relationships

An institutional customer may participate in the financial activity of its originating institution, including:

* wallet activity;
* transactions;
* loans;
* loan repayments; and
* remittance activity,

where applicable to that institutional domain.

### Lifecycle

The institutional customer relationship may be established, changed, suspended, or closed according to the originating institution's business processes.

The lifecycle of the institutional customer does not determine the lifecycle of the corresponding OCB identity.

---

# 4. OCB Customer

## Definition

**OCB Customer** represents the resolved cross-institutional identity used by OCB to correlate source-owned customer records for analytical and supervisory purposes.

It is an OCB modelling construct.

It is **not a replacement for institutional customer records**.

## Responsibility

OCB Customer provides the common analytical identity through which OCB may associate independently sourced financial activity where identity resolution establishes that relationship.

Conceptually:

```text
Source Customer
      ↓
Identity Resolution
      ↓
OCB Customer
```

## Ownership

Institutional customer records remain owned by their respective institutions.

OCB owns only the analytical representation of the resolved identity within the sandbox.

## Authoritative System

The originating institutions remain authoritative for their respective source customer records.

The OCB identity is authoritative only for the controlled cross-institutional analytical correlation represented within the OCB model.

## Relationships

An OCB Customer may resolve to multiple source customer identities:

```text
OCB Customer
     │
     ├── Ananse Customer
     ├── SikaCredit Customer
     └── Oman Remit Customer
```

The existence of the OCB identity does not imply that every institution has a corresponding customer relationship.

## Lifecycle

The OCB identity remains distinct from the lifecycle of any individual institutional customer relationship.

Source relationships may begin, change, or terminate while the resolved OCB identity remains analytically identifiable.

## Boundary

OCB Customer is a **controlled identity-resolution construct**, not a production national identity system and not a universal customer master.

---

# 5. OCB Customer Identity

## Definition

**OCB Customer Identity** represents the controlled relationship between an OCB Customer and a source-owned institutional customer identity.

Conceptually:

```text
OCB Customer
     │
     ↓
OCB Customer Identity
     │
     ↓
Source Institution + Source Customer ID
```

## Responsibility

This relationship allows OCB to resolve and correlate source customer identities without replacing or modifying the originating institutions' customer records.

## Ownership

The mapping is an OCB analytical construct.

The underlying source customer identifiers remain authoritative to their originating institutions.

## Analytical Significance

Supports:

* cross-institution customer analysis;
* exposure aggregation;
* behavioural correlation;
* investigation;
* transaction tracing;
* institutional relationship analysis.

## Attribute Ownership

Source-owned demographic and descriptive attributes remain attributable to the originating source.

OCB may resolve identity using source information and may derive analytical attributes according to OCB-defined logic.

OCB-derived attributes do not become source-owned attributes merely because they are produced from source data.

---

# 6. Wallet

## Definition

A **Wallet** is a source-owned Ananse Telecom financial entity representing a mobile-money value-holding position.

## Responsibility

The Wallet provides the financial state against which applicable Ananse financial events produce value changes.

The authoritative Ananse financial events affecting the wallet are:

* Cash-in;
* Cash-out;
* P2P Transfer; and
* Merchant Payment.

## Ownership

Ananse Telecom owns the operational wallet and its authoritative financial state.

OCB observes relevant wallet information but does not operate the wallet.

## Lifecycle

A Wallet may be created, become active, and subsequently become inactive or closed.

Its historical financial activity remains relevant after the wallet ceases active operation.

## Authoritative System

Ananse Telecom's simulated operational financial domain is authoritative for wallet state and wallet-related financial consequences.

## Relationships

A Wallet is associated with the relevant Ananse institutional customer and participates in applicable Ananse financial events.

Conceptually:

```text
Ananse Customer
       │
       └── Wallet
              │
              └── Ananse Transactions
```

## Financial Significance

Wallet state represents the customer-side financial position affected by successful wallet financial events.

Failed wallet-affecting events do not change wallet financial state.

---

# 7. Loan

## Definition

A **Loan** is a source-owned SikaCredit financial entity representing a digital lending obligation.

## Responsibility

The Loan represents the financial obligation established through SikaCredit lending activity and affected by:

* Loan Disbursement;
* Loan Repayment.

## Ownership

SikaCredit owns the operational loan relationship, loan state, and authoritative financial information associated with the loan.

## Lifecycle

A Loan may progress through multiple business and financial states, including origination, disbursement, repayment, and eventual closure or another defined terminal state.

The precise state-transition semantics are governed by the financial state model and later lending-rule design.

## Important Boundary

Loan lifecycle states must not be confused with authoritative financial events.

For example:

```text
Loan Default
Loan Closure
Loan Delinquency
```

may represent derived or lifecycle states rather than independent financial events.

## Authoritative System

SikaCredit's simulated operational financial domain is authoritative for the loan and its operational financial state.

## Relationships

A Loan is associated with:

* SikaCredit;
* an institutional customer acting as borrower; and
* applicable loan financial events.

Borrower is a **Customer role**, not a separate first-class entity.

---

# 8. Remittance

## Definition

A **Remittance** is a source-owned Oman Remit financial entity representing an observable remittance activity involving a sender and beneficiary.

## Responsibility

The Remittance represents the authoritative Oman Remit financial activity recognised by OCB.

The approved v1.0.0 financial event is:

```text
Remittance
```

Sender and beneficiary are roles within the remittance activity.

## Ownership

Oman Remit owns the operational remittance relationship and its authoritative financial information.

OCB observes the relevant financial activity without reproducing Oman Remit's internal processing or settlement architecture.

## Lifecycle

The remittance event may have a successful outcome within the v1.0.0 observable financial model.

Failed internal remittance processing is not currently represented as an independent OCB financial event.

## Authoritative System

Oman Remit's simulated operational domain is authoritative for the remittance information crossing the OCB observation boundary.

## Relationships

A Remittance may reference the relevant customer/participant identities required for OCB intelligence.

Sender and beneficiary remain **roles**, rather than independent first-class OCB entities.

## Financial Significance

A successful Remittance establishes the relevant beneficiary-side financial consequence within the OCB observation boundary.

---

# 9. Merchant

## Definition

A **Merchant** is an observable source-domain reference associated with Ananse Merchant Payment activity.

## v1.0.0 Treatment

Merchant is **not a required first-class OCB relational financial entity in the current v1.0.0 logical model**.

It remains a valid business concept because Merchant Payment semantics identify a merchant as the destination/reference associated with the activity.

## Boundary

OCB may observe merchant information where it is required by an approved analytical or intelligence question.

However, OCB does not currently model:

* merchant accounts;
* merchant settlement;
* merchant float;
* acquiring architecture;
* merchant operational management.

## Authoritative System

Ananse Telecom remains authoritative for underlying merchant information.

Any OCB representation is observational rather than operational.

## Future Consideration

A Merchant entity may be introduced if an approved requirement establishes the need for persistent merchant-level identity, attribution, investigation, concentration analysis, or related intelligence.

Such introduction must be reconciled with the logical model and governance process.

---

# 10. Agent

## Definition

An **Agent** is an observable source-domain reference associated with Ananse agent-mediated activity.

## v1.0.0 Treatment

Agent is **not a required first-class OCB relational financial entity in the current v1.0.0 logical model**.

It remains a valid source-domain concept, particularly in relation to agent-mediated Cash-in and Cash-out activity.

## Boundary

OCB does not model:

* agent float;
* agent liquidity;
* commissions;
* settlement;
* agent network management;
* other internal agent operations.

Agent information may be observed where required by an approved analytical or intelligence question.

## Authoritative System

Ananse Telecom remains authoritative for the underlying agent relationship and agent information.

## Future Consideration

A persistent Agent entity may be introduced only where an approved requirement establishes sufficient analytical or intelligence value.

Geographic information must likewise be justified by an approved analytical requirement rather than assumed as universally necessary.

---

# 11. Deliberately Excluded First-Class Entities

The following concepts remain excluded from the v1.0.0 first-class entity model.

| Concept           | Treatment                 | Reason                                                                                                                       |
| ----------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Financial Account | Ledger/accounting concept | Required for later ledger representation where appropriate, but not justified as a generic cross-institution business entity |
| Borrower          | Customer role             | A borrower is a Customer participating in SikaCredit lending activity                                                        |
| Sender            | Remittance role           | Sender is a role within Remittance activity                                                                                  |
| Beneficiary       | Remittance role           | Beneficiary is a role within Remittance activity                                                                             |
| P2P Send          | Financial leg             | Sender-side financial leg of P2P Transfer                                                                                    |
| P2P Receive       | Financial leg             | Receiver-side financial leg of P2P Transfer                                                                                  |
| Loan Default      | Derived state             | Derived from loan obligations, repayment information, deadlines, and applicable rules                                        |
| Loan Closure      | Lifecycle state           | Derived financial/lifecycle condition rather than independent financial event                                                |
| Settlement        | Status/consequence        | Not an independent v1.0.0 financial event                                                                                    |
| Correction        | Institutional control     | Originating-institution control mechanism                                                                                    |
| Reversal          | Future event concept      | Not required by the v1.0.0 observable financial architecture                                                                 |
| Adjustment        | Undefined concept         | Insufficiently defined financial meaning for controlled v1.0.0 modelling                                                     |

---

# 12. Entity Ownership Model

The resulting ownership model is:

```text
                  OCB PLATFORM
                       │
          ┌────────────┴────────────┐
          │                         │
     OCB Customer          OCB Customer Identity
          │                         │
          └────────────┬────────────┘
                       │
                Identity Resolution
                       │
       ┌───────────────┼────────────────┐
       │               │                │
       ▼               ▼                ▼
   ANANSE          SIKACREDIT       OMAN REMIT
       │               │                │
   Customer           Customer        Customer
       │               │                │
     Wallet           Loan         Remittance
       │               │
  Transaction       Repayment
```

The institutions remain owners of their respective source financial domains.

OCB provides the analytical identity and supervisory correlation layer.

---

# 13. Relationship to Financial Events

Entity responsibility must remain consistent with the approved financial-event model.

```text
Ananse Telecom
├── Cash-in
├── Cash-out
├── P2P Transfer
└── Merchant Payment

SikaCredit
├── Loan Disbursement
└── Loan Repayment

Oman Remit
└── Remittance
```

The events operate against the relevant source-owned financial entities.

```text
Financial Event
       ↓
Successful Financial Consequence
       ↓
Source-Owned Financial State
       ↓
OCB Observation
       ↓
Analytical Intelligence
```

OCB therefore does not create a second independent financial truth merely to analyse the source institution's financial activity.

---

# 14. T02 Boundary

These definitions establish:

* business meaning;
* ownership;
* authoritative source;
* lifecycle responsibility;
* analytical responsibility;
* entity-versus-role distinctions; and
* the OCB/source-domain boundary.

They do not define:

* physical database schemas;
* tables;
* columns;
* primary keys;
* foreign keys;
* cardinalities;
* normalization;
* indexes;
* ETL mechanisms;
* institutional integration;
* ledger implementation.

Those concerns belong to subsequent engineering work.

---

# 15. Reconciliation Decision

The following changes are established through this revision:

| Area                  | Decision                                                                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------- |
| Institution           | Retained as a conceptual institutional boundary, not required as a first-class relational financial entity |
| Customer              | Split conceptually into source-owned institutional customers and OCB-resolved customer identity            |
| OCB Customer          | Explicitly recognised as the cross-institution analytical identity                                         |
| OCB Customer Identity | Explicitly recognised as the source-to-OCB identity relationship                                           |
| Wallet                | Retained as an Ananse source-owned financial entity                                                        |
| Loan                  | Retained as a SikaCredit source-owned financial entity                                                     |
| Remittance            | Explicitly recognised as an Oman Remit source-owned financial entity                                       |
| Merchant              | Downgraded to observable source-domain reference; not current first-class relational entity                |
| Agent                 | Downgraded to observable source-domain reference; not current first-class relational entity                |
| Sender                | Remains a Remittance role                                                                                  |
| Beneficiary           | Remains a Remittance role                                                                                  |
| Borrower              | Remains a Customer role                                                                                    |
| Financial Account     | Remains a ledger/accounting concept rather than a generic business entity                                  |

---

# 16. Status

**Status: REVISED / RECONCILED**

WP-1.2-T02 has been reconciled against the approved financial-event semantics, financial state model, correction/reversal semantics, and current conceptual and logical data model.

The revised definitions establish the responsibility and ownership boundaries required for subsequent entity-relationship and attribute modelling.

Any material change to these responsibilities must be reconciled against the approved event model, state model, and logical data model and, where architecturally significant, processed through the applicable governance mechanism.

---

## Core Principle

> **Source institutions own their financial truth; OCB resolves identity and observes that truth for cross-institution intelligence without collapsing institutional ownership or reproducing unnecessary operational architecture.**
