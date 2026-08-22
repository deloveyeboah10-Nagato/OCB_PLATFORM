# WP-2.3-T01 — Define Database Schemas

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T01
**Status:** **APPROVED**

---

## 1. Purpose

This ticket defines the SQL Server database schema structure for the OCB Platform.

The purpose is to translate the logical entities established in WP-2.2 into **physical schema ownership boundaries** without prematurely defining the detailed table structures that belong to subsequent WP-2.3 tickets.

The schema design must preserve:

* institutional ownership;
* entity boundaries;
* financial-core separation;
* OCB identity-resolution responsibility;
* controlled reference-data ownership;
* clear dependency boundaries.

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

The initial schema set is:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

Each schema has a defined responsibility.

| Schema       | Responsibility                                                  |
| ------------ | --------------------------------------------------------------- |
| `ocb`        | OCB-owned identity resolution and OCB control objects           |
| `ananse`     | Ananse-owned institutional customer and transaction activity    |
| `sikacredit` | SikaCredit-owned institutional customer and lending activity    |
| `oman_remit` | Oman Remit-owned institutional customer and remittance activity |
| `wallet`     | Wallet and resulting financial-state objects                    |
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

`ocb.customer_identity` records the relationship between an OCB identity and source-system identities.

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

This schema owns Ananse's institutional activity.

It does **not** own the Ananse wallet.

That distinction is deliberate:

```text
ananse.transaction
        ≠
wallet.wallet
```

A transaction is an institutional activity.

A wallet is a financial object/state.

The resulting financial relationship between them will be implemented through the financial-core architecture defined in later tickets.

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

It does not own Ananse wallets or ledger postings resulting from financial consequences of those activities.

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

The `wallet` schema contains wallet objects and financial-state structures associated with wallets.

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

This is a deliberate architectural decision.

The distinction is:

```text
Ananse
    └── institutional activity

Wallet
    └── financial object / state
```

The wallet therefore must not be moved into:

```text
ananse
```

simply because Ananse owns the wallet operationally.

---

# 9. `ledger` Schema

## Responsibility

The `ledger` schema contains the financial accounting structures used to represent financial consequences and postings.

### Initial status

No detailed tables are locked by T01.

The ledger tables will be defined in:

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

The relationship between institutional activity, financial consequence, and ledger posting will be defined through the financial-event and ledger tickets.

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

No detailed reference tables are locked by T01.

They will be defined in:

**WP-2.3-T05 — Define Reference Structures**

---

# 11. Physical Object Allocation

The current logical-to-physical allocation is:

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

This allows the same logical table name, such as `customer`, to exist within different institutional schemas without ambiguity:

```text
ocb.customer
ananse.customer
sikacredit.customer
oman_remit.customer
```

These are **different tables owned by different domains**.

---

# 12. Why Institutional Customers Remain Separate

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

# 13. Schema Dependency Principle

The schema boundaries do not mean that schemas are isolated islands.

Cross-schema relationships are permitted where they reflect an established architectural dependency.

However, dependencies must be **intentional and controlled**.

The general principle is:

```text
Source-owned operational data
            ↓
Financial event / consequence
            ↓
Ledger
            ↓
Financial state
```

The platform must not create arbitrary cross-schema foreign keys merely because two objects can be analytically joined.

---

# 14. What T01 Does Not Lock

T01 does **not** yet determine:

* every foreign key crossing schemas;
* ledger table structures;
* financial-event table structures;
* wallet-state structures beyond the wallet boundary;
* reference-table structures;
* integration structures;
* indexing;
* partitioning;
* physical optimization;
* ETL/staging schemas.

Those decisions belong to later tickets.

This prevents T01 from becoming a dumping ground for decisions that belong elsewhere.

---

# 15. Schema Architecture

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

---

# 16. Architectural Principle

The schema design follows this rule:

> **A schema represents ownership and responsibility; a table represents a specific entity or structure within that responsibility.**

Therefore:

* `ananse` does not mean "everything financially related to Ananse";
* `wallet` does not mean "everything Ananse does with wallets";
* `ledger` does not mean "all financial events";
* `ocb` does not mean "all data used by OCB."

The schema boundaries follow the **architectural role of the data**, not merely the name of the institution associated with it.

---

# 17. Decision

The proposed SQL Server database schema architecture is:

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
INSTITUTIONAL SCHEMAS
        │
        ├── ocb
        ├── ananse
        ├── sikacredit
        └── oman_remit
                 │
                 ↓
          FINANCIAL CORE
          ├── ledger
          └── wallet

          SHARED CONTROL
                 │
                ref
```