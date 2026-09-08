# WP-2.3-T01 — Define Database Schemas

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T01
**Status:** **APPROVED**
**Decision Type:** Physical database architecture

---

## 1. Purpose

This ticket defines the SQL Server database schema structure for the OCB Platform.

The purpose is to translate the logical entities established in **WP-2.2** into physical schema ownership boundaries without prematurely defining detailed table structures that belong to subsequent WP-2.3 tickets.

The schema design must preserve:

* institutional ownership;
* entity boundaries;
* financial-core separation;
* OCB identity-resolution responsibility;
* controlled reference-data ownership;
* clear dependency boundaries;
* the established customer–wallet relationship.

---

# 2. Database Boundary

The platform will operate within a single SQL Server database:

```text
OCB_PLATFORM
```

The database contains multiple schemas representing distinct architectural responsibilities.

The schemas are **not separate databases** and are not intended to represent separate systems.

They are SQL Server namespaces used to establish ownership and responsibility within the OCB Platform database.

---

# 3. Authoritative Schema Set

The authoritative schema set is:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

| Schema       | Responsibility                                                  |
| ------------ | --------------------------------------------------------------- |
| `ocb`        | OCB-owned identity resolution and OCB control objects           |
| `ananse`     | Ananse-owned institutional customer and transaction activity    |
| `sikacredit` | SikaCredit-owned institutional customer and lending activity    |
| `oman_remit` | Oman Remit-owned institutional customer and remittance activity |
| `wallet`     | Wallet objects and wallet-associated financial-state structures |
| `ledger`     | Financial ledger and posting structures                         |
| `ref`        | Shared controlled reference data                                |

---

# 4. `ocb` Schema

## Responsibility

The `ocb` schema contains objects directly owned by OCB.

Its primary responsibility at this stage is **cross-institutional identity resolution**.

### Initial tables

```text
ocb.customer
ocb.customer_identity
```

Corresponding logical entities:

```text
OCB_CUSTOMER
OCB_CUSTOMER_IDENTITY
```

### Boundary

`ocb.customer` represents the OCB-resolved customer identity.

`ocb.customer_identity` records the relationship between an OCB identity and source-system customer identities.

The schema does **not** replace or absorb:

```text
ananse.customer
sikacredit.customer
oman_remit.customer
```

Those remain source-owned institutional records.

---

# 5. `ananse` Schema

## Responsibility

The `ananse` schema contains data representing activities and entities owned by Ananse Telecom.

### Initial tables

```text
ananse.customer
ananse.transaction
```

Corresponding logical entities:

```text
ANANSE_CUSTOMER
ANANSE_TRANSACTION
```

### Boundary

This schema owns Ananse's institutional customer and transaction activity.

It does **not** own the wallet table.

The distinction is deliberate:

```text
ananse.transaction
        ≠
wallet.wallet
```

A transaction is an institutional activity.

A wallet is a separate financial object maintained within the financial-core boundary.

---

# 6. `sikacredit` Schema

## Responsibility

The `sikacredit` schema contains data representing activities and entities owned by SikaCredit.

### Initial tables

```text
sikacredit.customer
sikacredit.loan
sikacredit.repayment
```

Corresponding logical entities:

```text
SIKACREDIT_CUSTOMER
SIKACREDIT_LOAN
SIKACREDIT_REPAYMENT
```

### Boundary

The schema owns:

* SikaCredit customers;
* loans;
* repayments.

It does not own Ananse wallets or ledger structures resulting from financial consequences.

---

# 7. `oman_remit` Schema

## Responsibility

The `oman_remit` schema contains data representing activities and entities owned by Oman Remit.

### Initial tables

```text
oman_remit.customer
oman_remit.remittance
```

Corresponding logical entities:

```text
OMAN_REMIT_CUSTOMER
OMAN_REMIT_REMITTANCE
```

### Boundary

The schema owns Oman Remit's:

* customer records;
* remittance activity.

It does not own the receiving wallet or financial ledger structures.

---

# 8. `wallet` Schema

## Responsibility

The `wallet` schema contains wallet objects and wallet-associated financial-state structures.

### Initial table

```text
wallet.wallet
```

Corresponding logical entity:

```text
ANANSE_WALLET
```

### Boundary

The wallet remains separate from the Ananse institutional schema.

This is deliberate because the wallet represents a financial object rather than merely an Ananse activity record.

The physical relationship established by the deployment model is:

```text
ananse.customer
       │
       │ customer_id
       ↓
wallet.wallet
       │
       │ wallet_id
       ↓
ananse.transaction
```

The wallet therefore retains an explicit relationship to its owning Ananse customer.

This does **not** move the wallet into the `ananse` schema.

The distinction remains:

```text
Ananse schema
    └── institutional activity

Wallet schema
    └── wallet / financial object
```

The wallet's customer relationship is therefore a **controlled cross-schema dependency**, not a change in schema ownership.

---

# 9. `ledger` Schema

## Responsibility

The `ledger` schema contains the financial accounting structures used to represent financial consequences and postings.

### Initial status

No detailed ledger table structures are locked by T01.

The ledger structures will be defined in:

**WP-2.3-T04 — Define Ledger Structures**

### Boundary

The ledger is separate from institutional activity.

For example:

```text
ananse.transaction
```

is not itself:

```text
ledger.entry
```

Likewise:

```text
sikacredit.repayment
```

is not itself a ledger posting.

The relationship between institutional activity, financial consequence, and ledger posting will be defined through the subsequent financial-core design.

---

# 10. `ref` Schema

## Responsibility

The `ref` schema contains controlled reference data shared by multiple operational schemas.

Potential reference domains include:

* transaction types;
* transaction statuses;
* currencies;
* transaction channels;
* countries;
* other controlled classifications.

### Initial status

No detailed reference-table structures are locked by T01.

They will be defined in:

**WP-2.3-T05 — Define Reference Structures**

---

# 11. Physical Object Allocation

The authoritative logical-to-physical allocation is:

| Logical Entity          | Physical Schema | Physical Table      |
| ----------------------- | --------------- | ------------------- |
| `OCB_CUSTOMER`          | `ocb`           | `customer`          |
| `OCB_CUSTOMER_IDENTITY` | `ocb`           | `customer_identity` |
| `ANANSE_CUSTOMER`       | `ananse`        | `customer`          |
| `ANANSE_TRANSACTION`    | `ananse`        | `transaction`       |
| `ANANSE_WALLET`         | `wallet`        | `wallet`            |
| `SIKACREDIT_CUSTOMER`   | `sikacredit`    | `customer`          |
| `SIKACREDIT_LOAN`       | `sikacredit`    | `loan`              |
| `SIKACREDIT_REPAYMENT`  | `sikacredit`    | `repayment`         |
| `OMAN_REMIT_CUSTOMER`   | `oman_remit`    | `customer`          |
| `OMAN_REMIT_REMITTANCE` | `oman_remit`    | `remittance`        |

The wallet remains physically allocated to the `wallet` schema even though it maintains a controlled FK relationship to the Ananse customer.

---

# 12. Physical Customer–Wallet Boundary

The physical deployment establishes an important distinction between **schema ownership** and **relational dependency**.

The wallet is owned by:

```text
wallet.wallet
```

while its customer relationship references:

```text
ananse.customer
```

Therefore:

```text
wallet.wallet
      │
      └── customer_id FK
                ↓
        ananse.customer
```

This is intentional.

A foreign key does not imply that the child table must belong to the same schema as the parent.

The relationship establishes **referential dependency**.

The schema establishes **ownership and architectural responsibility**.

These are separate concepts.

---

# 13. Why Institutional Customers Remain Separate

The existence of:

```text
ananse.customer
sikacredit.customer
oman_remit.customer
```

is intentional.

They represent source-owned institutional customer records.

OCB identity resolution does not eliminate the source records.

Instead:

```text
                    ocb.customer
                         │
                  identity mapping
                         │
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
   ananse.customer  sikacredit.customer  oman_remit.customer
```

This preserves institutional ownership while allowing OCB to resolve cross-institutional identity.

---

# 14. Schema Dependency Principle

The schemas are not isolated islands.

Cross-schema relationships are permitted where they represent an established architectural dependency.

However, dependencies must be **intentional and controlled**.

The key distinction is:

```text
SCHEMA OWNERSHIP
        ≠
FOREIGN-KEY DEPENDENCY
```

For example:

```text
wallet.wallet
      │
      │ FK
      ↓
ananse.customer
```

does not make `wallet` an `ananse` schema object.

It means that the wallet object depends on an Ananse customer for referential integrity.

The platform must not create arbitrary cross-schema foreign keys merely because two objects can be analytically joined.

---

# 15. What T01 Does Not Lock

T01 does **not** yet determine:

* every column-level constraint;
* every foreign key constraint;
* ledger table structures;
* financial-event table structures;
* detailed wallet-state structures;
* reference-table structures;
* indexing;
* partitioning;
* physical optimization;
* ETL/staging schemas.

Those decisions belong to later tickets.

T01 establishes the **schema ownership architecture** within which those decisions must operate.

---

# 16. Schema Architecture

The resulting physical schema architecture is:

```text
OCB_PLATFORM
│
├── ocb
│   ├── customer
│   └── customer_identity
│
├── ananse
│   ├── customer
│   └── transaction
│
├── sikacredit
│   ├── customer
│   ├── loan
│   └── repayment
│
├── oman_remit
│   ├── customer
│   └── remittance
│
├── wallet
│   └── wallet
│
├── ledger
│   └── [defined in T04]
│
└── ref
    └── [defined in T05]
```

With the established customer–wallet dependency:

```text
ananse.customer
       ▲
       │
       │ FK: customer_id
       │
wallet.wallet
       ▲
       │
       │ FK: wallet_id
       │
ananse.transaction
```

This represents relational dependency without collapsing the schema boundaries.

---

# 17. Architectural Principle

The schema design follows this rule:

> **A schema represents ownership and responsibility; a table represents a specific entity or structure within that responsibility.**

Therefore:

* `ananse` does not mean "everything financially related to Ananse";
* `wallet` does not mean "everything Ananse does with wallets";
* `ledger` does not mean "all financial events";
* `ocb` does not mean "all data used by OCB."

The schema boundaries follow the **architectural role of the data**, not merely the name of the institution associated with it.

---

# 18. Decision

The authoritative SQL Server database schema architecture is:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

with the following core separation:

```text
INSTITUTIONAL / CONTROL SCHEMAS
        │
        ├── ocb
        ├── ananse
        ├── sikacredit
        └── oman_remit
                 │
                 │ controlled dependencies
                 ↓
          FINANCIAL CORE
          ├── wallet
          └── ledger

SHARED CONTROL
        │
        └── ref
```

The `wallet` schema remains physically separate from `ananse`, while `wallet.wallet` maintains its established customer dependency through `customer_id`.

No schema is moved, merged, or duplicated by this decision.

**WP-2.3-T01 — APPROVED.**
