# WP-2.2-T05 — Define Cardinality

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T05
**Status:** **REVISED / RECONCILED / LOCKED**
**Decision Type:** Logical data-model definition

---

# 1. Purpose

This ticket defines the cardinality of the foreign-key relationships established in **WP-2.2-T04**.

The cardinalities are reconciled with the **approved WP-2.4 physical database deployment**.

Cardinality describes the permitted number of related records between a parent entity and its dependent child records.

This ticket therefore covers **all 12 foreign-key relationships physically implemented in WP-2.4**.

The authoritative physical deployment defines the following 12 relationships:

1. `ocb.customer_identity → ocb.customer`
2. `ananse.transaction → ananse.customer`
3. `ananse.transaction → wallet.wallet`
4. `wallet.wallet → ananse.customer`
5. `ananse.transaction → ref.transaction_type`
6. `ananse.transaction → ref.transaction_status`
7. `ananse.transaction → ref.transaction_channel`
8. `ananse.transaction → ref.currency`
9. `sikacredit.loan → sikacredit.customer`
10. `sikacredit.repayment → sikacredit.loan`
11. `oman_remit.remittance → oman_remit.customer`
12. `oman_remit.remittance → ref.country`

The physical deployment explicitly confirms **12 implemented foreign-key relationships**.

---

# 2. Cardinality Convention

This ticket uses the following notation:

```text
1      = exactly one
0..1   = zero or one
0..N   = zero, one, or many
1..N   = one or many
```

For each FK relationship, the parent may exist independently of child records unless the logical model explicitly requires otherwise.

Therefore, a typical parent-to-child relationship is represented as:

```text
PARENT 1 ──── 0..N CHILD
```

This means:

* one child must reference one valid parent;
* one parent may be referenced by zero, one, or many child records.

---

# 3. OCB Cardinality

## 3.1 `OCB_CUSTOMER` → `OCB_CUSTOMER_IDENTITY`

**FK:**

```text
ocb.customer_identity.ocb_customer_id
        ↓
ocb.customer.ocb_customer_id
```

**Cardinality:**

```text
OCB_CUSTOMER 1 ──── 0..N OCB_CUSTOMER_IDENTITY
```

One OCB-resolved customer may have zero, one, or multiple source-system identities.

Each source-system identity maps to exactly one OCB-resolved customer.

Therefore:

```text
OCB_CUSTOMER_IDENTITY N ──── 1 OCB_CUSTOMER
```

Example:

```text
OCB-C-001
   │
   ├── ANANSE / AN-C-001
   ├── SIKACREDIT / SC-C-017
   └── OMAN_REMIT / OR-C-044
```

The source identity remains uniquely identified by:

```text
(source_entity, source_customer_id)
```

---

# 4. Ananse Cardinality

## 4.1 `ANANSE_CUSTOMER` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.customer_id
        ↓
ananse.customer.customer_id
```

**Cardinality:**

```text
ANANSE_CUSTOMER 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse customer may have zero, one, or many transactions.

Each transaction belongs to exactly one Ananse customer.

---

## 4.2 `ANANSE_WALLET` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.wallet_id
        ↓
wallet.wallet.wallet_id
```

**Cardinality:**

```text
ANANSE_WALLET 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse wallet may have zero, one, or many transactions.

Each transaction is associated with exactly one wallet.

---

## 4.3 `ANANSE_CUSTOMER` → `ANANSE_WALLET`

**FK:**

```text
wallet.wallet.customer_id
        ↓
ananse.customer.customer_id
```

**Cardinality:**

```text
ANANSE_CUSTOMER 1 ──── 0..N ANANSE_WALLET
```

One Ananse customer may have zero, one, or multiple wallets.

Each wallet belongs to exactly one Ananse customer.

The physical deployment explicitly implements this relationship through:

```text
wallet.wallet.customer_id
        →
ananse.customer.customer_id
```

This relationship is therefore part of the authoritative logical model and must not be omitted from the cardinality model.

The resulting Ananse structure is:

```text
ANANSE_CUSTOMER
      │
      ├───────────────┐
      │               │
      ▼               ▼
ANANSE_WALLET   ANANSE_TRANSACTION
      │               ▲
      │               │
      └───────────────┘
```

More precisely:

```text
CUSTOMER
   │
   ├── 0..N WALLET
   │
   └── 0..N TRANSACTION

WALLET
   │
   └── 0..N TRANSACTION
```

---

# 5. Ananse Reference-Data Cardinality

The Ananse transaction contains four physical reference foreign keys.

These relationships are also included in the authoritative cardinality model.

---

## 5.1 `REF_TRANSACTION_TYPE` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.transaction_type_id
        ↓
ref.transaction_type.transaction_type_id
```

**Cardinality:**

```text
REF_TRANSACTION_TYPE 1 ──── 0..N ANANSE_TRANSACTION
```

One transaction type may be referenced by zero, one, or many Ananse transactions.

Each Ananse transaction references exactly one transaction type.

---

## 5.2 `REF_TRANSACTION_STATUS` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.transaction_status_id
        ↓
ref.transaction_status.transaction_status_id
```

**Cardinality:**

```text
REF_TRANSACTION_STATUS 1 ──── 0..N ANANSE_TRANSACTION
```

One transaction status may be referenced by zero, one, or many Ananse transactions.

Each Ananse transaction references exactly one transaction status.

---

## 5.3 `REF_TRANSACTION_CHANNEL` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.transaction_channel_id
        ↓
ref.transaction_channel.transaction_channel_id
```

**Cardinality:**

```text
REF_TRANSACTION_CHANNEL 1 ──── 0..N ANANSE_TRANSACTION
```

One transaction channel may be referenced by zero, one, or many Ananse transactions.

Each Ananse transaction references exactly one transaction channel.

---

## 5.4 `REF_CURRENCY` → `ANANSE_TRANSACTION`

**FK:**

```text
ananse.transaction.currency_id
        ↓
ref.currency.currency_id
```

**Cardinality:**

```text
REF_CURRENCY 1 ──── 0..N ANANSE_TRANSACTION
```

One currency may be referenced by zero, one, or many Ananse transactions.

Each Ananse transaction references exactly one currency.

---

# 6. SikaCredit Cardinality

## 6.1 `SIKACREDIT_CUSTOMER` → `SIKACREDIT_LOAN`

**FK:**

```text
sikacredit.loan.customer_id
        ↓
sikacredit.customer.customer_id
```

**Cardinality:**

```text
SIKACREDIT_CUSTOMER 1 ──── 0..N SIKACREDIT_LOAN
```

One SikaCredit customer may have zero, one, or multiple loans.

Each loan belongs to exactly one SikaCredit customer.

---

## 6.2 `SIKACREDIT_LOAN` → `SIKACREDIT_REPAYMENT`

**FK:**

```text
sikacredit.repayment.loan_id
        ↓
sikacredit.loan.loan_id
```

**Cardinality:**

```text
SIKACREDIT_LOAN 1 ──── 0..N SIKACREDIT_REPAYMENT
```

One SikaCredit loan may have zero, one, or multiple repayments.

Each repayment belongs to exactly one loan.

A loan may therefore exist without a repayment:

```text
LOAN
 │
 ├── 0 repayments
 │
 └── or many repayments
```

This supports the required lending lifecycle.

---

# 7. Oman Remit Cardinality

## 7.1 `OMAN_REMIT_CUSTOMER` → `OMAN_REMIT_REMITTANCE`

**FK:**

```text
oman_remit.remittance.customer_id
        ↓
oman_remit.customer.customer_id
```

**Cardinality:**

```text
OMAN_REMIT_CUSTOMER 1 ──── 0..N OMAN_REMIT_REMITTANCE
```

One Oman Remit customer may initiate zero, one, or multiple remittances.

Each remittance belongs to exactly one Oman Remit customer.

---

## 7.2 `REF_COUNTRY` → `OMAN_REMIT_REMITTANCE`

**FK:**

```text
oman_remit.remittance.country_id
        ↓
ref.country.country_id
```

**Cardinality:**

```text
REF_COUNTRY 1 ──── 0..N OMAN_REMIT_REMITTANCE
```

One reference country may be associated with zero, one, or many Oman Remit remittances.

Each remittance references exactly one country through `country_id`.

### Important physical-model interpretation

The physical deployment explicitly defines:

```text
oman_remit.remittance.country_id
        →
ref.country.country_id
```

as the **origin-country relationship**.

Therefore:

```text
country_id = origin country
```

The destination is Ghana and is **not represented as a second country FK** in the current physical model.

Consequently, the cardinality model must not imply:

```text
country_id → origin AND destination
```

or invent a second country relationship that does not exist physically.

---

# 8. Complete Cardinality Register

The authoritative cardinality register is therefore:

| #  | Parent Entity             | Child Entity            | FK Attribute             | Cardinality |
| -- | ------------------------- | ----------------------- | ------------------------ | ----------- |
| 1  | `OCB_CUSTOMER`            | `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id`        | `1 : 0..N`  |
| 2  | `ANANSE_CUSTOMER`         | `ANANSE_TRANSACTION`    | `customer_id`            | `1 : 0..N`  |
| 3  | `ANANSE_WALLET`           | `ANANSE_TRANSACTION`    | `wallet_id`              | `1 : 0..N`  |
| 4  | `ANANSE_CUSTOMER`         | `ANANSE_WALLET`         | `customer_id`            | `1 : 0..N`  |
| 5  | `REF_TRANSACTION_TYPE`    | `ANANSE_TRANSACTION`    | `transaction_type_id`    | `1 : 0..N`  |
| 6  | `REF_TRANSACTION_STATUS`  | `ANANSE_TRANSACTION`    | `transaction_status_id`  | `1 : 0..N`  |
| 7  | `REF_TRANSACTION_CHANNEL` | `ANANSE_TRANSACTION`    | `transaction_channel_id` | `1 : 0..N`  |
| 8  | `REF_CURRENCY`            | `ANANSE_TRANSACTION`    | `currency_id`            | `1 : 0..N`  |
| 9  | `SIKACREDIT_CUSTOMER`     | `SIKACREDIT_LOAN`       | `customer_id`            | `1 : 0..N`  |
| 10 | `SIKACREDIT_LOAN`         | `SIKACREDIT_REPAYMENT`  | `loan_id`                | `1 : 0..N`  |
| 11 | `OMAN_REMIT_CUSTOMER`     | `OMAN_REMIT_REMITTANCE` | `customer_id`            | `1 : 0..N`  |
| 12 | `REF_COUNTRY`             | `OMAN_REMIT_REMITTANCE` | `country_id`             | `1 : 0..N`  |

**Total authoritative FK relationships represented: 12.**

---

# 9. Cardinality Summary by Domain

## OCB

```text
OCB_CUSTOMER
      1
      │
     0..N
      │
OCB_CUSTOMER_IDENTITY
```

---

## Ananse

```text
                  ANANSE_CUSTOMER
                    1       1
                    │       │
                  0..N    0..N
                    │       │
                    ▼       ▼
             ANANSE_WALLET   ANANSE_TRANSACTION
                    1             ▲
                    │             │
                   0..N           │
                    └─────────────┘
```

Reference relationships:

```text
REF_TRANSACTION_TYPE
        1
        │
       0..N
        │
ANANSE_TRANSACTION


REF_TRANSACTION_STATUS
        1
        │
       0..N
        │
ANANSE_TRANSACTION


REF_TRANSACTION_CHANNEL
        1
        │
       0..N
        │
ANANSE_TRANSACTION


REF_CURRENCY
        1
        │
       0..N
        │
ANANSE_TRANSACTION
```

---

## SikaCredit

```text
SIKACREDIT_CUSTOMER
        1
        │
       0..N
        │
SIKACREDIT_LOAN
        1
        │
       0..N
        │
SIKACREDIT_REPAYMENT
```

---

## Oman Remit

```text
OMAN_REMIT_CUSTOMER
        1
        │
       0..N
        │
OMAN_REMIT_REMITTANCE
        │
       0..N
        ▲
        │
        1
REF_COUNTRY
```

The `REF_COUNTRY` relationship represents the remittance's **origin country** only.

---

# 10. Relationship Participation Rules

The cardinalities establish the following participation rules.

### 10.1 Customers

Institutional customers may exist without current activity.

Therefore:

```text
CUSTOMER → 0..N activity
```

is permitted.

---

### 10.2 Wallets

An Ananse wallet may exist before its first transaction.

Therefore:

```text
WALLET → 0..N TRANSACTION
```

is permitted.

---

### 10.3 Loans

A SikaCredit loan may exist before any repayment has occurred.

Therefore:

```text
LOAN → 0..N REPAYMENT
```

is permitted.

---

### 10.4 Reference Values

A reference value may exist before it is used.

For example:

```text
REF_CURRENCY
```

may contain a currency that is currently referenced by no Ananse transaction.

Therefore:

```text
REFERENCE VALUE → 0..N TRANSACTIONS
```

is appropriate.

The same principle applies to:

* transaction types;
* transaction statuses;
* transaction channels;
* currencies;
* countries.

---

# 11. Cross-Institutional Cardinality

The cardinality model does **not** introduce direct foreign-key relationships between institutional domains.

In particular, it does not establish:

```text
SIKACREDIT → ANANSE_WALLET
```

or:

```text
OMAN_REMIT → ANANSE_WALLET
```

or:

```text
ANANSE_CUSTOMER → OCB_CUSTOMER
```

The OCB customer relationship remains mediated through:

```text
OCB_CUSTOMER
      │
      1
      │
     0..N
      │
OCB_CUSTOMER_IDENTITY
```

The institutional source identities remain institution-owned.

Cross-domain financial relationships are handled through the financial-event, financial-consequence, ledger, and analytical architecture rather than by introducing unsupported operational foreign keys.

---

# 12. Cardinality Does Not Imply Financial Behaviour

Cardinality defines relational participation.

It does **not** determine whether an event is financially successful, whether a balance changes, or whether a transaction produces a financial consequence.

For example:

```text
ANANSE_CUSTOMER
        1
        │
       0..N
        │
ANANSE_TRANSACTION
```

does not mean every transaction changes wallet state.

Transaction status and financial-consequence logic determine whether financial state changes.

Likewise:

```text
SIKACREDIT_LOAN
        1
        │
       0..N
        │
SIKACREDIT_REPAYMENT
```

does not imply that every loan must have a repayment.

---

# 13. Reconciliation With WP-2.4

This ticket is explicitly reconciled with the physical deployment.

The physical SQL implementation establishes 12 foreign-key constraints.

The six relationships that were previously represented in the earlier logical cardinality model remain valid:

```text
OCB_CUSTOMER → OCB_CUSTOMER_IDENTITY

ANANSE_CUSTOMER → ANANSE_TRANSACTION

ANANSE_WALLET → ANANSE_TRANSACTION

SIKACREDIT_CUSTOMER → SIKACREDIT_LOAN

SIKACREDIT_LOAN → SIKACREDIT_REPAYMENT

OMAN_REMIT_CUSTOMER → OMAN_REMIT_REMITTANCE
```

The following six physical relationships are now explicitly incorporated:

```text
ANANSE_CUSTOMER → ANANSE_WALLET

REF_TRANSACTION_TYPE → ANANSE_TRANSACTION

REF_TRANSACTION_STATUS → ANANSE_TRANSACTION

REF_TRANSACTION_CHANNEL → ANANSE_TRANSACTION

REF_CURRENCY → ANANSE_TRANSACTION

REF_COUNTRY → OMAN_REMIT_REMITTANCE
```

Therefore:

```text
6 previous relationships
+
6 physical reference/ownership relationships
=
12 authoritative FK relationships
```

No FK implemented in WP-2.4 is omitted from this cardinality model.

No additional FK is invented beyond the physical deployment.

---

# 14. Final Decision

The cardinalities defined in this ticket constitute the authoritative cardinality baseline for the OCB Platform v1.0.0 logical relational model.

The model recognizes **all 12 foreign-key relationships implemented in WP-2.4**.

The authoritative structure is:

```text
OCB
└── OCB_CUSTOMER
    └── 0..N OCB_CUSTOMER_IDENTITY


ANANSE
├── ANANSE_CUSTOMER
│   ├── 0..N ANANSE_WALLET
│   └── 0..N ANANSE_TRANSACTION
│
└── ANANSE_WALLET
    └── 0..N ANANSE_TRANSACTION

REFERENCE
├── TRANSACTION_TYPE ── 0..N TRANSACTION
├── TRANSACTION_STATUS ── 0..N TRANSACTION
├── TRANSACTION_CHANNEL ── 0..N TRANSACTION
├── CURRENCY ── 0..N TRANSACTION
└── COUNTRY ── 0..N OMAN_REMIT_REMITTANCE


SIKACREDIT
CUSTOMER
└── 0..N LOAN
    └── 0..N REPAYMENT


OMAN_REMIT
CUSTOMER
└── 0..N REMITTANCE
```

The cardinality model is therefore fully aligned with:

* WP-2.2-T01 — Relational Entities;
* WP-2.2-T02 — Attributes;
* WP-2.2-T03 — Primary Identifiers;
* WP-2.2-T04 — Foreign-Key Relationships; and
* WP-2.4 — Physical Database Deployment.

No additional cardinality is implied beyond the documented relational dependencies.

**WP-2.2-T05 — REVISED, RECONCILED AND LOCKED.**
