# WP-2.2-T05 — Define Cardinality

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T05
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the cardinality of the foreign-key relationships established in **WP-2.2-T04**.

Cardinality describes how many records in one entity may relate to records in another entity.

The cardinalities below reflect the operational meaning of the entities and their established grain.

---

# 2. OCB Cardinality

## 2.1 `OCB_CUSTOMER` → `OCB_CUSTOMER_IDENTITY`

**Cardinality:**

```text
OCB_CUSTOMER 1 ──── 0..N OCB_CUSTOMER_IDENTITY
```

One OCB-resolved customer may have zero, one, or multiple source-system identities.

For example:

```text
OCB-C-001
   │
   ├── ANANSE / AN-C-001
   ├── SIKA / SC-C-017
   └── OMAN / OR-C-044
```

A source identity maps to one OCB customer.

Therefore the inverse relationship is:

```text
OCB_CUSTOMER_IDENTITY N ──── 1 OCB_CUSTOMER
```

---

# 3. Ananse Cardinality

## 3.1 `ANANSE_CUSTOMER` → `ANANSE_TRANSACTION`

**Cardinality:**

```text
ANANSE_CUSTOMER 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse customer may have zero, one, or many transactions.

Each transaction belongs to one Ananse customer.

---

## 3.2 `ANANSE_WALLET` → `ANANSE_TRANSACTION`

**Cardinality:**

```text
ANANSE_WALLET 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse wallet may have zero, one, or many transactions.

Each transaction is associated with one wallet.

The model therefore separates:

```text
Customer
   │
   └── Wallet
         │
         └── Transactions
```

without treating those three objects as one entity.

---

# 4. SikaCredit Cardinality

## 4.1 `SIKACREDIT_CUSTOMER` → `SIKACREDIT_LOAN`

**Cardinality:**

```text
SIKACREDIT_CUSTOMER 1 ──── 0..N SIKACREDIT_LOAN
```

One SikaCredit customer may have zero, one, or multiple loans.

Each loan belongs to one SikaCredit customer.

---

## 4.2 `SIKACREDIT_LOAN` → `SIKACREDIT_REPAYMENT`

**Cardinality:**

```text
SIKACREDIT_LOAN 1 ──── 0..N SIKACREDIT_REPAYMENT
```

One loan may have zero, one, or multiple repayments.

Each repayment belongs to one loan.

This supports the previously established repayment model:

```text
LOAN
 │
 ├── REPAYMENT 1
 ├── REPAYMENT 2
 ├── REPAYMENT 3
 └── ...
```

A loan may legitimately have no repayment yet.

---

# 5. Oman Remit Cardinality

## 5.1 `OMAN_REMIT_CUSTOMER` → `OMAN_REMIT_REMITTANCE`

**Cardinality:**

```text
OMAN_REMIT_CUSTOMER 1 ──── 0..N OMAN_REMIT_REMITTANCE
```

One Oman Remit customer may initiate zero, one, or multiple remittances.

Each remittance belongs to one Oman Remit customer.

---

# 6. Complete Cardinality Register

| Parent Entity         | Child Entity            | Cardinality |
| --------------------- | ----------------------- | ----------- |
| `OCB_CUSTOMER`        | `OCB_CUSTOMER_IDENTITY` | `1 : 0..N`  |
| `ANANSE_CUSTOMER`     | `ANANSE_TRANSACTION`    | `1 : 0..N`  |
| `ANANSE_WALLET`       | `ANANSE_TRANSACTION`    | `1 : 0..N`  |
| `SIKACREDIT_CUSTOMER` | `SIKACREDIT_LOAN`       | `1 : 0..N`  |
| `SIKACREDIT_LOAN`     | `SIKACREDIT_REPAYMENT`  | `1 : 0..N`  |
| `OMAN_REMIT_CUSTOMER` | `OMAN_REMIT_REMITTANCE` | `1 : 0..N`  |

---

# 7. Relationship Participation

The cardinalities above describe the maximum and minimum participation permitted by the logical model.

### Customer entities

A customer may exist before any activity occurs:

```text
customer → 0..N activities
```

Therefore the child-side participation is optional.

### Wallet

A wallet may exist before its first transaction:

```text
wallet → 0..N transactions
```

### Loan

A loan may exist before any repayment:

```text
loan → 0..N repayments
```

This is particularly important because a newly disbursed loan does not necessarily have a repayment immediately.

---

# 8. Cross-Institutional Cardinality

OCB identity resolution does not impose a one-to-one relationship between institutional customers and OCB customers.

The intended structure is:

```text
                    OCB_CUSTOMER
                         1
                         │
                       0..N
                         │
              OCB_CUSTOMER_IDENTITY
```

A single OCB customer may therefore resolve to multiple institutional identities.

However, each individual source identity represented by:

```text
(source_entity, source_customer_id)
```

maps to **one** `ocb_customer_id`.

---

# 9. Relationships Not Given Cardinality

No cardinality is established between the institutional activities and the downstream financial-core objects in this ticket.

In particular, this ticket does **not** create direct relationships between:

* Oman Remit and Ananse Wallet;
* SikaCredit and Ananse Wallet;
* institutional transactions and OCB Customer;
* institutional activities and ledger entries.

Those relationships belong to the financial-consequence and ledger architecture and will be defined at the appropriate stage.

---

# 10. Final Decision

The authoritative cardinalities for the current logical model are:

```text
OCB_CUSTOMER
    1 ──── 0..N
OCB_CUSTOMER_IDENTITY

ANANSE_CUSTOMER
    1 ──── 0..N
ANANSE_TRANSACTION

ANANSE_WALLET
    1 ──── 0..N
ANANSE_TRANSACTION

SIKACREDIT_CUSTOMER
    1 ──── 0..N
SIKACREDIT_LOAN

SIKACREDIT_LOAN
    1 ──── 0..N
SIKACREDIT_REPAYMENT

OMAN_REMIT_CUSTOMER
    1 ──── 0..N
OMAN_REMIT_REMITTANCE
```

**WP-2.2-T05 — REVISED AND LOCKED.**
