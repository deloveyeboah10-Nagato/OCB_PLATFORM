# WP-2.2-T05 — Define Cardinality

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T05
**Status:** **COMPLETE**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

WP-2.2-T05 defines the cardinality of the foreign-key relationships established in WP-2.2-T04.

Cardinality describes how many records in one entity may relate to records in another entity.

The relationships are evaluated from the **parent to child** perspective.

---

# 2. Cardinality Principles

### 2.1 Parent-child relationships

Where a child contains a foreign key referencing a parent, the normal relationship is:

```text
ONE parent → MANY children
```

unless the business rules establish a one-to-one restriction.

### 2.2 Foreign keys do not automatically determine business cardinality

A foreign key establishes referential dependency, but the business model determines whether the relationship is:

* 1:1
* 1:M
* M:M

### 2.3 Many-to-many relationships require an associative structure

No direct M:M relationship is implemented where the current model does not contain the required associative entity.

---

# 3. OCB Identity Cardinality

## 3.1 OCB Customer → OCB Customer Identity

**Relationship:**

```text
OCB_CUSTOMER
     │
     │ 1 : M
     ▼
OCB_CUSTOMER_IDENTITY
```

### Cardinality

**One OCB customer → Many source identities**

An OCB customer may have identities across multiple institutions.

Example:

```text
OCB-C-104
   │
   ├── ANANSE / AN-C-104
   ├── SIKACREDIT / SC-C-104
   └── OMAN_REMIT / OR-C-883
```

Therefore:

**`OCB_CUSTOMER 1 : M OCB_CUSTOMER_IDENTITY`**

---

# 4. Ananse Cardinality

## 4.1 Ananse Customer → Ananse Transaction

**Relationship:**

```text
ANANSE_CUSTOMER
       │
       │ 1 : M
       ▼
ANANSE_TRANSACTION
```

### Cardinality

**One customer → Many transactions**

A customer may perform zero, one, or many transactions.

A transaction belongs to one identified Ananse customer under the current model.

Therefore:

**`ANANSE_CUSTOMER 1 : M ANANSE_TRANSACTION`**

---

## 4.2 Ananse Wallet → Ananse Transaction

**Relationship:**

```text
ANANSE_WALLET
      │
      │ 1 : M
      ▼
ANANSE_TRANSACTION
```

### Cardinality

**One wallet → Many transactions**

A wallet may have zero, one, or many transactions.

Each transaction is associated with one wallet under the current model.

Therefore:

**`ANANSE_WALLET 1 : M ANANSE_TRANSACTION`**

---

# 5. SikaCredit Cardinality

## 5.1 SikaCredit Customer → SikaCredit Loan

**Relationship:**

```text
SIKACREDIT_CUSTOMER
        │
        │ 1 : M
        ▼
SIKACREDIT_LOAN
```

### Cardinality

**One customer → Many loans**

A customer may have multiple loans over time.

Each loan belongs to one SikaCredit customer.

Therefore:

**`SIKACREDIT_CUSTOMER 1 : M SIKACREDIT_LOAN`**

---

## 5.2 SikaCredit Loan → SikaCredit Repayment

**Relationship:**

```text
SIKACREDIT_LOAN
       │
       │ 1 : M
       ▼
SIKACREDIT_REPAYMENT
```

### Cardinality

**One loan → Many repayments**

A loan may have zero, one, or many repayments.

Each repayment belongs to one loan.

Example:

```text
LOAN-5001
   │
   ├── REPAYMENT-7001
   ├── REPAYMENT-7002
   └── REPAYMENT-7003
```

Therefore:

**`SIKACREDIT_LOAN 1 : M SIKACREDIT_REPAYMENT`**

This explicitly supports the repayment model established in T02.

---

# 6. Oman Remit Cardinality

## 6.1 Oman Remit Customer → Oman Remit Remittance

**Relationship:**

```text
OMAN_REMIT_CUSTOMER
        │
        │ 1 : M
        ▼
OMAN_REMIT_REMITTANCE
```

### Cardinality

**One customer → Many remittances**

A customer may initiate zero, one, or many remittances.

Each remittance is associated with one Oman Remit customer under the current model.

Therefore:

**`OMAN_REMIT_CUSTOMER 1 : M OMAN_REMIT_REMITTANCE`**

---

# 7. Consolidated Cardinality Register

| Parent Entity         | Child Entity            | Cardinality |
| --------------------- | ----------------------- | ----------- |
| `OCB_CUSTOMER`        | `OCB_CUSTOMER_IDENTITY` | **1:M**     |
| `ANANSE_CUSTOMER`     | `ANANSE_TRANSACTION`    | **1:M**     |
| `ANANSE_WALLET`       | `ANANSE_TRANSACTION`    | **1:M**     |
| `SIKACREDIT_CUSTOMER` | `SIKACREDIT_LOAN`       | **1:M**     |
| `SIKACREDIT_LOAN`     | `SIKACREDIT_REPAYMENT`  | **1:M**     |
| `OMAN_REMIT_CUSTOMER` | `OMAN_REMIT_REMITTANCE` | **1:M**     |

There are currently **no confirmed many-to-many relationships** in the logical model.

---

# 8. Oman Remit → Ananse Wallet

The business architecture establishes that Oman Remit remittances can result in funds entering Ananse wallets.

However, the current logical model does not contain a defined foreign key connecting:

```text
OMAN_REMIT_REMITTANCE
```

to:

```text
ANANSE_WALLET
```

Therefore, **no cardinality is locked for this relationship at T05**.

This is deliberate.

We will not infer a cardinality simply from the fact that money ultimately moves between the institutions.

The linkage mechanism must first be defined.

---

# 9. Participation / Optionality

The current model permits the following parent-side optionality:

| Relationship                     | Parent may have no child records? |
| -------------------------------- | --------------------------------- |
| OCB Customer → Identity          | Yes                               |
| Ananse Customer → Transaction    | Yes                               |
| Ananse Wallet → Transaction      | Yes                               |
| SikaCredit Customer → Loan       | Yes                               |
| SikaCredit Loan → Repayment      | Yes                               |
| Oman Remit Customer → Remittance | Yes                               |

This means the parent entity can exist independently of a child activity record.

On the child side, the foreign-key relationships defined in T04 establish that each child record references an applicable parent record.

---

# 10. Final Decisions

WP-2.2-T05 establishes six confirmed **1:M relationships**:

```text
OCB_CUSTOMER
      1
      │
      M
OCB_CUSTOMER_IDENTITY


ANANSE_CUSTOMER
      1
      │
      M
ANANSE_TRANSACTION
      M
      │
      1
ANANSE_WALLET


SIKACREDIT_CUSTOMER
      1
      │
      M
SIKACREDIT_LOAN
      1
      │
      M
SIKACREDIT_REPAYMENT


OMAN_REMIT_CUSTOMER
      1
      │
      M
OMAN_REMIT_REMITTANCE
```

No many-to-many relationship is currently confirmed.

The Oman Remit → Ananse Wallet relationship remains intentionally unresolved.

**WP-2.2-T05 — COMPLETE.**