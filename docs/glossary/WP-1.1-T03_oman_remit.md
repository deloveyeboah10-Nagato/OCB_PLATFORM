**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.1 — Institutional Domain Boundaries

**Ticket:** WP-1.1-T03

**Status:** **REVISED / LOCKED**

**Decision Type:** Institutional domain definition — Oman Remit

---

# Oman Remit

| Field                        | Definition                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Term**                     | Oman Remit                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **Definition**               | An independent simulated financial institution representing the cross-border remittance domain within the OCB Platform v1.0.0. Oman Remit owns and operates its simulated remittance domain and remains authoritative for the institutional remittance activity, remittance relationships, and financial state arising within that domain and within the defined OCB observation boundary.                                                                                                                                                                                                                                     |
| **Context**                  | Oman Remit is one of the independent institutional domains observed by OCB. Its domain covers simulated cross-border remittance activity and the associated operational financial information that falls within the defined OCB observation boundary.                                                                                                                                                                                                                                                                                                                                                                          |
| **System / Domain**          | Oman Remit — Cross-Border Remittance                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **Ownership**                | Oman Remit owns the operational meaning, remittance activity, participant relationships, financial consequences, and authoritative financial information within its simulated domain. OCB observes defined information originating from Oman Remit and may resolve identities or represent relevant financial consequences analytically, but does not become the operational owner or source of truth for Oman Remit's financial activity.                                                                                                                                                                                     |
| **Related Concepts**         | Remittance; customer; sender role; beneficiary role; originating participant; receiving participant; origin country; destination country; currency; exchange rate; remittance status; beneficiary financial position; observation boundary; financial intelligence                                                                                                                                                                                                                                                                                                                                                             |
| **Financial Significance**   | The Oman Remit domain contains the cross-border remittance activity recognised by OCB through the approved v1.0.0 financial event: **Remittance**. A successful Remittance establishes the corresponding beneficiary financial consequence and increases the beneficiary financial position represented within the defined OCB observation boundary.                                                                                                                                                                                                                                                                           |
| **Analytical Significance**  | Observable Oman Remit activity provides the basis for analysis of remittance behaviour, remittance value, cross-border flows, geographic and destination concentration, currency-related activity where applicable, anomalous activity, institutional monitoring, and regulatory investigation. Analytical representation does not alter the underlying Oman Remit financial truth.                                                                                                                                                                                                                                            |
| **Implementation Reference** | To be established through subsequent Oman Remit operational-data, remittance, financial-state, ledger, and logical/physical data-model work. No physical database object is defined by this domain entry.                                                                                                                                                                                                                                                                                                                                                                                                                      |
| **Status**                   | **Defined**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| **Notes / Boundary**         | Oman Remit is institutionally independent from OCB and from the other simulated financial institutions. Only information falling within the defined OCB observation boundary is observable by OCB. OCB does not reproduce Oman Remit's complete internal remittance-processing, settlement, withdrawal, correspondent, payment-network, or other institutional architecture merely because such mechanisms may exist within the source domain. The v1.0.0 model recognises **Remittance** as the sole authoritative Oman Remit financial event without implying that it exhausts Oman Remit's real-world operational activity. |

## Lifecycle

Oman Remit exists as an independent institutional domain throughout the v1.0.0 simulation period. Its remittance activity and associated financial information may change over time without changing the identity or institutional ownership of the domain.

Individual remittance activity may have lifecycle outcomes, including successful or unsuccessful outcomes, but initiation, processing, receipt, settlement, and failure are not modelled as separate authoritative financial-event types in v1.0.0.

## Authoritative System

Oman Remit's simulated operational financial domain is authoritative for its own remittance activity, participant relationships, financial consequences, and applicable institutional financial state.

Within the OCB observation boundary, a successful Remittance establishes the corresponding **Beneficiary Financial Position**.

OCB's representations are observational, resolved, derived, or analytical representations and do not replace Oman Remit's authority.

## Relationships

The Oman Remit institutional domain contains the source-owned activity required to represent its approved OCB-observable remittance activity.

Conceptually:

```text
OMAN REMIT
     │
     ├── Customer
     │
     └── Remittance
            │
            ├── Sender Role
            │
            └── Beneficiary Role
                     │
                     ↓
          Beneficiary Financial Position
```

Sender and beneficiary are participant roles within the remittance activity rather than independent first-class OCB entities.

The Beneficiary Financial Position is a conceptual financial position within the Oman Remit domain. It is not introduced as a separate OCB-owned operational entity.

## Cross-Domain Boundary

A successful Oman Remit Remittance may be associated, after OCB identity resolution, with financial activity observed in another institutional domain.

However:

```text
Oman Remit Remittance
          ≠
Automatic Ananse Wallet Credit
```

A cross-domain analytical relationship does not automatically mutate the authoritative financial state of another institution.

If Ananse subsequently records an actual wallet-affecting financial event associated with the value, that activity remains an **Ananse-authoritative** event or financial consequence and must be represented according to the Ananse domain model.

This preserves institutional ownership and prevents double counting or the creation of an implied shared financial account.

## T03 Boundary

This ticket defines Oman Remit as an independent institutional domain and establishes its ownership, authority, financial significance, analytical significance, and OCB observation boundary.

It does not define:

* physical database schemas;
* tables or columns;
* primary or foreign keys;
* detailed remittance attributes;
* correspondent relationships;
* settlement architecture;
* withdrawal mechanisms;
* payment-network infrastructure;
* institutional integration mechanisms;
* ledger implementation.

Those concerns are addressed by subsequent work packages where explicitly required.

**Core Principle**

> **Oman Remit remains authoritative for its own remittance domain; OCB observes and analytically represents only the information that falls within its defined observation boundary, without inventing or assuming unmodelled settlement or cross-institutional state mechanisms.**
