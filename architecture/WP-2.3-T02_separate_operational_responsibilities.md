# WP-2.3-T02 — Separate Operational Responsibilities

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T02
**Status:** **APPROVED**

---

## 1. Purpose

This ticket defines the operational responsibility of each database schema established in **WP-2.3-T01**.

The purpose is to distinguish:

* which institution owns an entity or activity;
* which schema contains the corresponding database objects;
* which structures represent institutional activity;
* which structures represent financial state or financial posting.

**Schema separation does not automatically imply separate institutional ownership.**

In particular, the `wallet` schema contains **Ananse-owned wallet objects** even though those objects are physically separated from the `ananse` schema.

---

# 2. Responsibility Model

| Schema       | Operational Responsibility                             |
| ------------ | ------------------------------------------------------ |
| `ocb`        | OCB identity resolution                                |
| `ananse`     | Ananse customer and transaction activity               |
| `sikacredit` | SikaCredit customer and lending activity               |
| `oman_remit` | Oman Remit customer and remittance activity            |
| `wallet`     | **Ananse-owned wallet and associated financial state** |
| `ledger`     | Financial ledger and postings                          |
| `ref`        | Shared controlled reference data                       |

---

# 3. `ocb` Schema

### Owns

* OCB-resolved customer identity.
* Source-to-OCB identity mappings.
* OCB-specific identity-resolution control structures.

### Does not own

* Ananse source customer records.
* SikaCredit source customer records.
* Oman Remit source customer records.
* Institutional transaction, loan, repayment, or remittance activity.

OCB resolves identities across institutional sources but does not replace the source systems' authoritative customer records.

---

# 4. `ananse` Schema

### Owns

* Ananse customer records.
* Ananse transaction activity.

### Does not contain

* Wallet tables.
* Ledger tables.
* SikaCredit activity.
* Oman Remit activity.
* OCB identity-resolution tables.

The physical separation of the wallet does **not** mean that Ananse does not own the wallet.

---

# 5. `sikacredit` Schema

### Owns

* SikaCredit customer records.
* Loan records.
* Repayment records.

SikaCredit is authoritative for its lending activity.

### Does not own

* Ananse wallets.
* Ananse transactions.
* Oman Remit remittances.
* OCB identity-resolution records.
* Ledger postings.

---

# 6. `oman_remit` Schema

### Owns

* Oman Remit customer records.
* Remittance records.

Oman Remit is authoritative for its remittance activity.

### Does not own

* Ananse customer records.
* Ananse transactions.
* Ananse wallets.
* SikaCredit loans or repayments.
* Ledger postings.
* OCB identity-resolution records.

---

# 7. `wallet` Schema

### Ownership

The wallet is an **Ananse-owned financial object**.

The `wallet` schema is therefore not an independent institutional domain.

It is a physical database boundary used because wallet and financial-state structures have a distinct architectural responsibility from Ananse's transaction activity.

### Owns

* Ananse wallet records.
* Wallet financial-state structures.

### Does not own

* The originating transaction activity.
* SikaCredit lending activity.
* Oman Remit remittance activity.
* OCB identity-resolution records.

The distinction is therefore:

```text id="o8t2pm"
Ananse ownership
       │
       ├── customer
       ├── transaction
       └── wallet
```

while the SQL Server schema organization is:

```text id="3sk1mi"
ananse
├── customer
└── transaction

wallet
└── wallet
```

**Ownership and schema placement are deliberately not identical concepts.**

---

# 8. `ledger` Schema

### Owns

* Ledger structures.
* Financial postings.
* Financial accounting consequences.

### Does not own

* Source institutional activities.
* Customer records.
* Loans.
* Repayments.
* Remittances.
* Wallet ownership.

The ledger represents the **financial consequence of activity**, rather than replacing the originating activity.

Detailed ledger structures are defined in:

**WP-2.3-T04 — Define Ledger Structures.**

---

# 9. `ref` Schema

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

# 10. Institutional Ownership Model

The institutional ownership model is:

```text id="xqgcsp"
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

The financial architecture then provides the separate ledger responsibility:

```text id="s7y2bg"
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

For Ananse, the financial state includes the **Ananse-owned wallet**.

---

# 11. Physical Schema vs Institutional Ownership

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

# 12. Cross-Schema Access

Schemas may reference or query objects in other schemas where the relationship is architecturally justified.

However:

> **Cross-schema access does not transfer ownership.**

For example:

```text id="3d8a2r"
ananse.transaction
        ↓
financial consequence
        ↓
ledger
        ↓
wallet.wallet
```

The transaction remains Ananse-owned.

The wallet remains Ananse-owned.

The ledger remains a financial-core structure.

These are separate responsibilities even though they participate in the same financial flow.

---

# 13. Responsibility Matrix

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

---

# 14. Final Responsibility Boundaries

The authoritative model is:

```text id="b1t7gj"
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

With physical schema separation:

```text id="4ykqzq"
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

---

# 15. Decision

The platform will distinguish **institutional ownership** from **physical SQL Server schema placement**.

The critical decision is:

> **Ananse owns the wallet. The wallet is nevertheless placed in a separate `wallet` schema because wallet/financial-state structures have a distinct architectural responsibility from Ananse's institutional transaction activity.**

No schema boundary transfers institutional ownership unless explicitly stated.