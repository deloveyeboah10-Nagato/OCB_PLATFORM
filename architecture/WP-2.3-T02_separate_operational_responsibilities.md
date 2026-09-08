# WP-2.3-T02 — Separate Operational Responsibilities

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T02
**Status:** **APPROVED**
**Decision Type:** Operational responsibility definition

---

## 1. Purpose

This ticket defines the operational responsibility of each database schema established in **WP-2.3-T01**.

The purpose is to distinguish:

* which institution owns an entity or activity;
* which schema contains the corresponding database objects;
* which structures represent institutional activity;
* which structures represent wallets and financial state;
* which structures represent financial events and ledger postings;
* which structures provide shared platform control.

**Schema separation does not automatically imply separate institutional ownership.**

In particular, the `wallet` schema contains **Ananse-owned wallet objects** even though those objects are physically separated from the `ananse` schema.

---

# 2. Responsibility Model

| Schema       | Operational Responsibility                                        |
| ------------ | ----------------------------------------------------------------- |
| `ocb`        | OCB identity resolution and OCB-owned control structures          |
| `ananse`     | Ananse customer and transaction activity                          |
| `sikacredit` | SikaCredit customer and lending activity                          |
| `oman_remit` | Oman Remit customer and remittance activity                       |
| `wallet`     | **Ananse-owned wallet and associated financial-state structures** |
| `ledger`     | Financial ledger and posting structures                           |
| `ref`        | Shared controlled reference data                                  |

---

# 3. `ocb` Schema

### Owns

* OCB-resolved customer identities;
* source-to-OCB identity mappings;
* OCB-specific identity-resolution control structures.

### Does not own

* Ananse source customer records;
* SikaCredit source customer records;
* Oman Remit source customer records;
* institutional transaction, loan, repayment, or remittance activity;
* Ananse wallet records.

OCB resolves identities across institutional sources but does not replace the source systems' authoritative customer records.

---

# 4. `ananse` Schema

### Owns

* Ananse customer records;
* Ananse transaction activity.

### Does not contain

* wallet tables;
* ledger tables;
* SikaCredit activity;
* Oman Remit activity;
* OCB identity-resolution tables.

The physical separation of the wallet does **not** mean that Ananse does not own the wallet.

Ananse ownership is therefore broader than the physical contents of the `ananse` SQL Server schema.

---

# 5. `sikacredit` Schema

### Owns

* SikaCredit customer records;
* loan records;
* repayment records.

SikaCredit is authoritative for its lending activity.

### Does not own

* Ananse wallets;
* Ananse transactions;
* Oman Remit remittances;
* OCB identity-resolution records;
* ledger postings.

---

# 6. `oman_remit` Schema

### Owns

* Oman Remit customer records;
* remittance records.

Oman Remit is authoritative for its remittance activity.

### Does not own

* Ananse customer records;
* Ananse transactions;
* Ananse wallets;
* SikaCredit loans or repayments;
* ledger postings;
* OCB identity-resolution records.

---

# 7. `wallet` Schema

### Ownership

The wallet is an **Ananse-owned financial object**.

The `wallet` schema is therefore **not an independent institutional domain**.

It is a physical database boundary used because wallet and financial-state structures have a distinct architectural responsibility from Ananse's transaction activity.

### Owns

* Ananse wallet records;
* wallet financial-state structures associated with those wallets.

### Does not own

* originating transaction activity;
* SikaCredit lending activity;
* Oman Remit remittance activity;
* OCB identity-resolution records;
* ledger postings.

The institutional ownership model is:

```text
ANANSE
├── customer
├── transaction
└── wallet
```

while the SQL Server schema organization is:

```text
ananse
├── customer
└── transaction

wallet
└── wallet
```

**Ownership and schema placement are deliberately not identical concepts.**

---

# 8. Wallet Relational Boundary

The physical model establishes a controlled relationship between the Ananse customer and the Ananse-owned wallet.

```text
ananse.customer
       │
       │ customer_id
       ↓
wallet.wallet
```

The wallet therefore remains physically located in the `wallet` schema while maintaining its customer dependency on `ananse.customer`.

This distinction is important:

```text
Institutional ownership
        ≠
SQL Server schema placement
        ≠
Foreign-key dependency
```

A foreign key from `wallet.wallet` to `ananse.customer` does not transfer ownership of the wallet to the `ananse` schema.

---

# 9. `ledger` Schema

### Owns

* ledger structures;
* ledger entries;
* financial postings;
* accounting representation of financial consequences.

### Does not own

* source institutional activities;
* customer records;
* loans;
* repayments;
* remittances;
* wallet ownership.

The ledger represents the **accounting/posting representation of financial consequences**, rather than replacing the originating institutional activity.

For example:

```text
ananse.transaction
        │
        ↓
financial consequence
        │
        ↓
ledger posting
```

The originating transaction remains an Ananse institutional record.

Detailed ledger structures are defined in:

**WP-2.3-T04 — Define Ledger Structures.**

---

# 10. `ref` Schema

### Owns

Shared controlled reference data used by multiple schemas.

Examples include:

* transaction types;
* transaction statuses;
* currencies;
* transaction channels;
* countries;
* other controlled classifications.

The detailed reference structures are defined in:

**WP-2.3-T05 — Define Reference Structures.**

---

# 11. Institutional Ownership Model

The institutional ownership model is:

```text
ANANSE
├── Customer
├── Wallet
└── Transaction

SIKACREDIT
├── Customer
├── Loan
└── Repayment

OMAN REMIT
├── Customer
└── Remittance

OCB
└── Identity Resolution
```

The financial architecture provides the platform-level financial processing structures:

```text
Institutional Activity
        │
        ↓
Financial Consequence
        │
        ↓
Ledger Posting
        │
        ↓
Financial State
```

For Ananse, the relevant financial state includes the **Ananse-owned wallet**.

---

# 12. Physical Schema vs Institutional Ownership

This distinction is fundamental to the design.

| Object               | Institutional Owner         | SQL Server Schema |
| -------------------- | --------------------------- | ----------------- |
| `customer`           | OCB                         | `ocb`             |
| `customer_identity`  | OCB                         | `ocb`             |
| `customer`           | Ananse                      | `ananse`          |
| `transaction`        | Ananse                      | `ananse`          |
| `wallet`             | **Ananse**                  | `wallet`          |
| `customer`           | SikaCredit                  | `sikacredit`      |
| `loan`               | SikaCredit                  | `sikacredit`      |
| `repayment`          | SikaCredit                  | `sikacredit`      |
| `customer`           | Oman Remit                  | `oman_remit`      |
| `remittance`         | Oman Remit                  | `oman_remit`      |
| Ledger structures    | OCB Platform financial core | `ledger`          |
| Reference structures | OCB Platform shared control | `ref`             |

This table resolves the apparent contradiction between **Ananse ownership** and **wallet schema separation**.

---

# 13. Cross-Schema Access

Schemas may reference or query objects in other schemas where the relationship is architecturally justified.

However:

> **Cross-schema access does not transfer ownership.**

For example:

```text
ananse.transaction
        │
        ↓
financial consequence
        │
        ↓
ledger
        │
        ↓
wallet.wallet
```

The transaction remains Ananse-owned.

The wallet remains Ananse-owned.

The ledger remains a financial-core structure.

These objects participate in a common financial flow without becoming part of the same schema or responsibility boundary.

The established wallet customer dependency is similarly controlled:

```text
wallet.wallet
      │
      │ customer_id FK
      ↓
ananse.customer
```

---

# 14. Responsibility Matrix

| Responsibility         | OCB | Ananse | SikaCredit | Oman Remit | Wallet Schema | Ledger | Ref |
| ---------------------- | --: | -----: | ---------: | ---------: | ------------: | -----: | --: |
| Identity resolution    |   ✓ |        |            |            |               |        |     |
| Customer source record |     |      ✓ |          ✓ |          ✓ |               |        |     |
| Transaction activity   |     |      ✓ |            |            |               |        |     |
| Wallet ownership       |     |  **✓** |            |            |               |        |     |
| Wallet financial state |     |  **✓** |            |            |               |        |     |
| Loan activity          |     |        |          ✓ |            |               |        |     |
| Repayment activity     |     |        |          ✓ |            |               |        |     |
| Remittance activity    |     |        |            |          ✓ |               |        |     |
| Ledger postings        |     |        |            |            |               |      ✓ |     |
| Shared reference data  |     |        |            |            |               |        |   ✓ |

The **Wallet Schema** column represents physical placement, while the **Ananse** column represents institutional ownership.

This is intentional.

---

# 15. Final Responsibility Boundaries

The authoritative institutional model is:

```text
OCB
└── Identity Resolution

ANANSE
├── Customer
├── Transaction
└── Wallet

SIKACREDIT
├── Customer
├── Loan
└── Repayment

OMAN REMIT
├── Customer
└── Remittance

OCB PLATFORM FINANCIAL CORE
└── Ledger

OCB PLATFORM SHARED CONTROL
└── Reference Data
```

The physical SQL Server organization is:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

---

# 16. Decision

The platform will distinguish **institutional ownership** from **physical SQL Server schema placement**.

The critical decision is:

> **Ananse owns the wallet. The wallet is nevertheless placed in a separate `wallet` schema because wallet and financial-state structures have a distinct architectural responsibility from Ananse's institutional transaction activity.**

The wallet may therefore maintain a foreign-key dependency on `ananse.customer` without being moved into the `ananse` schema.

No schema boundary transfers institutional ownership unless explicitly stated.

**WP-2.3-T02 — APPROVED.**
