**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.2 — Financial Entity Model

**Ticket:** WP-1.2-T01

**Status:** **REVISED / LOCKED**

**Decision Type:** Initial financial entity and observable reference inventory

---

# OCB Initial Financial Entity Inventory

## Purpose

This document establishes the initial inventory of financial entities and observable reference concepts required for the OCB Platform v1.0.0 entity-modelling programme.

The inventory distinguishes between:

* OCB-resolved identity;
* institution-owned financial/domain entities;
* observable reference concepts;
* architectural concepts that provide ownership or domain context but do not constitute independent financial entities;
* deliberately excluded concepts.

Inclusion in this inventory does not by itself establish physical database structures or implementation details. Final entity responsibilities, attributes, relationships, ownership, and lifecycle semantics are established through subsequent modelling work.

---

# 1. Entity Classification

OCB distinguishes the following categories:

```text
Financial Entity Model
        │
        ├── OCB-Resolved Identity
        │
        ├── Institution-Owned Financial / Domain Entities
        │
        ├── Observable Reference Concepts
        │
        └── Architectural / Domain Concepts
```

These categories must not be treated as interchangeable.

An architectural concept may establish ownership or institutional context without becoming a first-class financial entity.

An observable reference concept may be required for intelligence or attribution without requiring an independent financial-accounting representation.

---

# 2. OCB-Resolved Identity

## 2.1 OCB Customer

**Classification:** OCB-resolved identity entity

**Purpose / Justification**

`OCB Customer` represents the cross-institutional identity resolved by OCB where multiple institution-owned customer identities are determined to refer to the same underlying customer.

It provides the identity anchor required for cross-institutional intelligence and investigation.

OCB Customer does not replace the source institution's customer identity and does not imply that all customer attributes are centrally owned by OCB.

The relationship is conceptually:

```text
OCB Customer
      │
      ├── Ananse Customer
      ├── SikaCredit Customer
      └── Oman Remit Customer
```

Institutional customer attributes remain owned by their respective source domains unless explicitly defined as OCB-derived information.

Identity resolution establishes the relationship between identities; it does not collapse institutional source records into a single source-owned customer record.

---

# 3. Institution-Owned Financial / Domain Entities

The following entities remain owned by their respective institutional domains.

| Entity                  | Institution / Domain | Purpose                                                                                                                          |
| ----------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Ananse Customer**     | Ananse Telecom       | Represents the customer identity maintained by Ananse Telecom.                                                                   |
| **Wallet**              | Ananse Telecom       | Represents the mobile-money value-holding entity associated with Ananse financial activity and wallet financial state.           |
| **Transaction**         | Ananse Telecom       | Represents an authoritative Ananse financial event and its associated transaction information.                                   |
| **SikaCredit Customer** | SikaCredit           | Represents the customer identity maintained by SikaCredit.                                                                       |
| **Loan**                | SikaCredit           | Represents the lending obligation required to model loan disbursement, repayment, outstanding exposure, and derived loan states. |
| **Repayment**           | SikaCredit           | Represents the repayment activity associated with a SikaCredit loan.                                                             |
| **Oman Remit Customer** | Oman Remit           | Represents the customer identity maintained by Oman Remit.                                                                       |
| **Remittance**          | Oman Remit           | Represents the authoritative Oman Remit remittance activity and its associated financial consequence.                            |

These entities preserve institutional ownership rather than creating a generic cross-institutional financial model.

---

# 4. Observable Reference Concepts

## 4.1 Merchant

**Classification:** Observable reference concept / candidate entity

Merchant information may be required to attribute Ananse Merchant Payments to merchants and support:

* merchant-level analysis;
* concentration analysis;
* behavioural investigation;
* suspicious-activity analysis.

However, the current v1.0.0 logical model does not establish Merchant as an independent first-class relational entity.

Merchant therefore remains an observable reference concept pending the detailed logical and attribute modelling required to determine whether a separate entity is justified.

OCB does not model the merchant's internal account, ledger, settlement, or operational architecture.

---

## 4.2 Agent

**Classification:** Observable reference concept / candidate entity

Agent information may be required to attribute agent-mediated Ananse activity such as Cash-in and Cash-out and support:

* agent-level analysis;
* concentration analysis;
* investigation;
* geographic analysis where justified.

The existence of agent-mediated activity does not by itself require an independent Agent financial entity.

Agent therefore remains an observable reference concept pending further modelling.

OCB does not model agent float, agent liquidity, agent settlement, or other internal institutional operations.

---

# 5. Architectural / Domain Concepts

## 5.1 Institution

**Classification:** Architectural / domain concept

Institution establishes the ownership and institutional context of OCB-observed financial activity.

The v1.0.0 model recognises:

* Ananse Telecom;
* SikaCredit;
* Oman Remit.

Institution is not therefore required to become a separate first-class financial entity merely to represent institutional ownership.

The ownership relationship is instead reflected through the institution-owned entities and their domain context.

Conceptually:

```text
Institution / Domain
        ↓
Owns / governs
        ↓
Institutional Financial Entity
```

This avoids imposing a generic cross-institutional account or entity architecture that does not reflect the independent source systems.

---

# 6. Deliberately Excluded First-Class Concepts

The following concepts are not treated as first-class OCB financial entities for v1.0.0.

| Concept                      | Treatment                   | Reason                                                                                                                                |
| ---------------------------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Financial Account**        | Ledger/accounting reference | Required where appropriate for organising financial consequences, but not justified as a generic cross-institutional business entity. |
| **Remittance Participant**   | Participant role            | Sender and beneficiary are roles within Remittance activity rather than separate OCB financial entities.                              |
| **Borrower / Loan Receiver** | Customer role               | A separate borrower entity is unnecessary because a SikaCredit Customer can fulfil the borrower role.                                 |
| **Sender**                   | Remittance role             | Sender is a role within a remittance rather than an independent entity.                                                               |
| **Beneficiary**              | Remittance role             | Beneficiary is a role within a remittance rather than an independent entity.                                                          |

These exclusions do not prevent the relevant concepts from being represented through relationships, roles, references, or attributes where required.

---

# 7. Relationship to the Financial Event Model

The entity inventory must remain consistent with the approved WP-1.3 financial-event catalogue.

The authoritative financial events are:

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

These events operate against institution-owned financial entities and their associated identities.

For example:

```text
Ananse Customer
      │
      └── Wallet
             │
             └── Ananse Transaction
                    │
                    ├── Cash-in
                    ├── Cash-out
                    ├── P2P Transfer
                    └── Merchant Payment
```

and:

```text
SikaCredit Customer
        │
        └── Loan
             │
             └── Repayment
```

and:

```text
Oman Remit Customer
        │
        └── Remittance
             │
             ├── Sender role
             └── Beneficiary role
```

The entity model therefore supports the event model without creating separate entities for event consequences or derived states.

---

# 8. Relationship to Financial State

The entity inventory must also remain consistent with WP-1.4.

The authoritative financial states are:

| Financial State                | Relevant Entity                                                 |
| ------------------------------ | --------------------------------------------------------------- |
| Customer Wallet Balance        | Ananse Wallet                                                   |
| Outstanding Loan Principal     | SikaCredit Loan                                                 |
| Beneficiary Financial Position | Oman Remit Remittance / relevant beneficiary financial position |

These states are established from authoritative financial consequences.

Derived states such as:

* active;
* delinquent;
* defaulted;
* closed;

are not independent financial entities.

They are conditions derived from authoritative financial information and applicable rules.

---

# 9. Identity and Demographic Ownership Boundary

OCB's cross-institutional identity model must not be interpreted as central ownership of all customer information.

The distinction is:

```text
Source Institution
       │
       └── Owns source customer identity
                    │
                    ▼
             OCB Identity Resolution
                    │
                    ▼
              OCB Customer
```

Source-owned demographic and identity attributes remain associated with the originating institutional customer record.

Where OCB requires a derived demographic or classification, it may resolve the relevant institutional identity and apply an explicitly defined OCB derivation rule.

Therefore:

```text
Source-owned information
        ≠
OCB-derived information
        ≠
OCB identity resolution
```

These must remain distinguishable throughout subsequent modelling.

---

# 10. Scope Boundary

This inventory does not define:

* physical database tables;
* schemas;
* columns;
* primary keys;
* foreign keys;
* indexes;
* ledger implementation;
* ETL implementation;
* identity-resolution algorithms;
* analytical calculations.

Those concerns belong to subsequent work packages.

The purpose of T01 is to establish the controlled conceptual inventory from which those later decisions can be made.

---

# 11. Status

**Status: REVISED / LOCKED**

The initial financial entity inventory has been reconciled against the current WP-1.3 financial-event model, WP-1.4 financial-state model, and the current WP-2.1 and WP-2.2 conceptual and logical modelling decisions.

The inventory establishes:

1. OCB-resolved identity as distinct from source-owned institutional customer identities;
2. institution-owned financial/domain entities;
3. Merchant and Agent as observable reference concepts rather than prematurely approved entities;
4. Institution as an architectural/domain concept rather than a required first-class financial entity;
5. deliberate exclusions for generic accounts and participant/role concepts.

Further entity additions or material reclassification must be justified by an approved v1.0.0 business or intelligence requirement and reconciled with the existing event, state, and logical models.

---

# Core Principle

> **OCB resolves identities across institutional domains without collapsing institutional ownership; financial entities represent the domain objects that matter to OCB, while observable references and architectural concepts must not be promoted to first-class entities without a demonstrated need.**
