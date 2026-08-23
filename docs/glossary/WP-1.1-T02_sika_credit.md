**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.1 — Institutional Domain Boundaries

**Ticket:** WP-1.1-T02

**Status:** **REVISED / LOCKED**

**Decision Type:** Institutional domain definition — SikaCredit

---

# SikaCredit

| Field                        | Definition                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Term**                     | SikaCredit                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **Definition**               | An independent simulated financial institution representing the digital-lending domain within the OCB Platform v1.0.0. SikaCredit owns and operates its simulated lending domain and remains authoritative for the institutional lending activity, loan objects, and financial state arising within that domain.                                                                                                                                                                                                                                                                                              |
| **Context**                  | SikaCredit is one of the independent institutional domains observed by OCB. Its domain covers simulated digital-lending activity and the associated operational financial information that falls within the defined OCB observation boundary.                                                                                                                                                                                                                                                                                                                                                                 |
| **System / Domain**          | SikaCredit — Digital Lending                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Ownership**                | SikaCredit owns the operational meaning, lending activity, loan relationships, financial consequences, and authoritative lending state within its simulated domain. OCB observes defined information originating from SikaCredit and may represent relevant information analytically, but does not become the operational owner or source of truth for SikaCredit's lending activity or loan state.                                                                                                                                                                                                           |
| **Related Concepts**         | Digital lending; loan; customer; borrower role; principal; loan disbursement; loan repayment; outstanding loan obligation; loan state; observation boundary; financial intelligence                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **Financial Significance**   | The SikaCredit domain contains the digital-lending activity recognised by OCB through the approved v1.0.0 financial events: Loan Disbursement and Loan Repayment. Successful disbursement establishes the applicable loan obligation, while successful repayment reduces the outstanding obligation.                                                                                                                                                                                                                                                                                                          |
| **Analytical Significance**  | Observable SikaCredit lending activity provides the basis for analysis of loan exposure, disbursement activity, repayment behaviour, outstanding obligations, delinquency, default-related conditions, portfolio behaviour, institutional monitoring, and regulatory investigation. Analytical representation does not alter the underlying SikaCredit financial truth.                                                                                                                                                                                                                                       |
| **Implementation Reference** | To be established through subsequent operational-data, lending, financial-state, ledger, and logical/physical data-model work. No physical database object is defined by this domain entry.                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **Status**                   | **Defined**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| **Notes / Boundary**         | SikaCredit is institutionally independent from OCB and from the other simulated financial institutions. Only information falling within the defined OCB observation boundary is observable by OCB. OCB does not reproduce SikaCredit's complete internal credit-decision, loan-processing, servicing, settlement, or other institutional architecture merely because those mechanisms may exist within the source domain. The v1.0.0 model recognises Loan Disbursement and Loan Repayment as authoritative financial events without implying that they exhaust SikaCredit's real-world operational activity. |

## Lifecycle

SikaCredit exists as an independent institutional domain throughout the v1.0.0 simulation period. Its lending activity and associated financial states may change over time without changing the identity or institutional ownership of the domain.

Individual loans may progress through their applicable lending lifecycle, including disbursement, repayment, and eventual closure or other defined terminal state. The detailed loan-state model is established separately.

## Authoritative System

SikaCredit's simulated operational lending domain is authoritative for its own lending activity, loan objects, financial consequences, and operational loan state.

OCB's representations are observational, resolved, derived, or analytical representations and do not replace SikaCredit's authority.

Loan default, delinquency, and closure are not treated as independent authoritative financial events. They are derived or lifecycle states determined from authoritative loan and repayment information and applicable rules.

## Relationships

The SikaCredit institutional domain contains the source-owned financial objects and activity required to represent its approved OCB-observable lending activity.

Conceptually:

```text
SIKACREDIT
     │
     ├── Customer
     │       │
     │       └── Borrower Role
     │
     └── Loan
            │
            ├── Loan Disbursement
            └── Loan Repayment
```

The **Customer** is the cross-institutional participant concept used by OCB. The borrower is treated as a role associated with the Customer rather than as a separate first-class entity.

The Loan remains a SikaCredit-owned financial obligation. OCB observes the relevant loan activity and financial consequences within its defined observation boundary.

## T02 Boundary

This ticket defines SikaCredit as an independent institutional domain and establishes its ownership, authority, financial significance, analytical significance, and OCB observation boundary.

It does not define:

* physical database schemas;
* tables or columns;
* primary or foreign keys;
* detailed loan attributes;
* credit-decision workflows;
* lending-system architecture;
* institutional integration mechanisms;
* ledger implementation.

Those concerns are addressed by subsequent work packages.

**Core Principle**

> **SikaCredit remains authoritative for its own lending domain and loan state; OCB observes and analytically represents only the information that falls within its defined observation boundary.**
