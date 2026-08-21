# WP-2.2-T01 — Define Relational Entities

## 1. Purpose

Translate the approved conceptual entities established in WP-1.3 and WP-2.1 into relational entities that will form the basis of the logical data model.

This ticket does not redefine the business domain or rediscover entities. It establishes the relational representation required for subsequent decisions concerning attributes, identifiers, foreign keys, cardinality, normalization, and the logical ERD.

---

## 2. Relational Entity Set

| Relational Entity | Conceptual Source | Domain | Purpose |
|---|---|---|---|
| `customer` | Customer | Cross-domain | Represents the customer/actor participating across the simulated institutions. |
| `wallet` | Wallet | Ananse Telecom | Represents a distinct mobile-money financial object associated with a customer. |
| `transaction` | Transaction | Ananse Telecom | Represents observable mobile-money financial activity. |
| `loan` | Loan | SikaCredit | Represents a lending position in which the customer participates as borrower. |
| `remittance` | Remittance | Oman Remit | Represents an observable remittance activity. |
| `beneficiary_financial_position` | Beneficiary Financial Position | Oman Remit | Represents the financial position associated with the beneficiary side of a remittance. |
| `ledger_entry` | Ledger Entry | Cross-domain Accounting | Represents an accounting consequence arising from authoritative financial activity. |

---

## 3. Institutional Ownership

The relational representation preserves the institutional boundaries established in WP-2.1.

| Entity | Owning / Operating Domain |
|---|---|
| `customer` | Cross-institutional actor representation |
| `wallet` | Ananse Telecom |
| `transaction` | Ananse Telecom |
| `loan` | SikaCredit |
| `remittance` | Oman Remit |
| `beneficiary_financial_position` | Oman Remit |
| `ledger_entry` | Cross-domain accounting model |

The existence of these entities within the OCB analytical model does not imply shared operational infrastructure between the institutions.

No shared operational database, account system, ledger, or payment infrastructure is assumed.

---

## 4. Entity Separation Principles

The relational model preserves the following distinctions:

- `customer` is not a `wallet`.
- `wallet` is not a `transaction`.
- `loan` is not a `customer`.
- `remittance` is not a `customer`.
- `ledger_entry` is not a `transaction`.
- `ledger_entry` does not replace the originating financial object or event.

These distinctions are necessary to preserve business meaning, institutional ownership, temporal/event history, and accounting consequences as separate modelling concerns.

---

## 5. Scope of This Ticket

This ticket establishes **what relational entities exist**.

It does not yet determine:

- attributes or columns;
- data types;
- primary keys;
- foreign keys;
- cardinality;
- normalization;
- indexes;
- physical SQL Server implementation.

Those decisions are addressed by subsequent WP-2.2 tickets.

---

## 6. Relationship to Subsequent Logical Modelling

The relational entity set established here provides the foundation for:

| Ticket | Subsequent Decision |
|---|---|
| WP-2.2-T02 | Relational attributes |
| WP-2.2-T03 | Primary identifiers |
| WP-2.2-T04 | Foreign-key relationships |
| WP-2.2-T05 | Cardinality |
| WP-2.2-T06 | Normalization |
| WP-2.2-T07 | Logical ERD |

The logical ERD is therefore an output of the completed relational modelling decisions rather than a replacement for them.

---

## 7. Completion Criterion

WP-2.2-T01 is complete when every approved conceptual entity has an explicit relational counterpart and no new business entities have been invented or previously established entities duplicated.

**Status: Approved**