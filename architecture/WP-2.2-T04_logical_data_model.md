# WP-2.2-T04 — Define Foreign-Key Relationships

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T04
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the foreign-key relationships between the relational entities established in **WP-2.2-T01**, using the attributes and primary identifiers defined in **WP-2.2-T02** and **WP-2.2-T03**.

Foreign keys establish explicit relational dependencies between entities.

---

# 2. OCB Relationships

## 2.1 `OCB_CUSTOMER_IDENTITY` → `OCB_CUSTOMER`

```text
OCB_CUSTOMER_IDENTITY.ocb_customer_id
        ↓
OCB_CUSTOMER.ocb_customer_id
```

| Child Entity            | FK                | Parent Entity  | PK                |
| ----------------------- | ----------------- | -------------- | ----------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER` | `ocb_customer_id` |

This associates a source-system identity with its resolved OCB identity.

---

# 3. Ananse Relationships

## 3.1 `ANANSE_TRANSACTION` → `ANANSE_CUSTOMER`

```text
ANANSE_TRANSACTION.customer_id
        ↓
ANANSE_CUSTOMER.customer_id
```

| Child Entity         | FK            | Parent Entity     | PK            |
| -------------------- | ------------- | ----------------- | ------------- |
| `ANANSE_TRANSACTION` | `customer_id` | `ANANSE_CUSTOMER` | `customer_id` |

Each Ananse transaction is associated with an Ananse customer.

---

## 3.2 `ANANSE_TRANSACTION` → `ANANSE_WALLET`

```text
ANANSE_TRANSACTION.wallet_id
        ↓
ANANSE_WALLET.wallet_id
```

| Child Entity         | FK          | Parent Entity   | PK          |
| -------------------- | ----------- | --------------- | ----------- |
| `ANANSE_TRANSACTION` | `wallet_id` | `ANANSE_WALLET` | `wallet_id` |

Each Ananse transaction is associated with the wallet through which the activity occurs.

---

# 4. SikaCredit Relationships

## 4.1 `SIKACREDIT_LOAN` → `SIKACREDIT_CUSTOMER`

```text
SIKACREDIT_LOAN.customer_id
        ↓
SIKACREDIT_CUSTOMER.customer_id
```

| Child Entity      | FK            | Parent Entity         | PK            |
| ----------------- | ------------- | --------------------- | ------------- |
| `SIKACREDIT_LOAN` | `customer_id` | `SIKACREDIT_CUSTOMER` | `customer_id` |

Each SikaCredit loan belongs to a SikaCredit customer.

---

## 4.2 `SIKACREDIT_REPAYMENT` → `SIKACREDIT_LOAN`

```text
SIKACREDIT_REPAYMENT.loan_id
        ↓
SIKACREDIT_LOAN.loan_id
```

| Child Entity           | FK        | Parent Entity     | PK        |
| ---------------------- | --------- | ----------------- | --------- |
| `SIKACREDIT_REPAYMENT` | `loan_id` | `SIKACREDIT_LOAN` | `loan_id` |

Each repayment is associated with the loan against which it was made.

---

# 5. Oman Remit Relationships

## 5.1 `OMAN_REMIT_REMITTANCE` → `OMAN_REMIT_CUSTOMER`

```text
OMAN_REMIT_REMITTANCE.customer_id
        ↓
OMAN_REMIT_CUSTOMER.customer_id
```

| Child Entity            | FK            | Parent Entity         | PK            |
| ----------------------- | ------------- | --------------------- | ------------- |
| `OMAN_REMIT_REMITTANCE` | `customer_id` | `OMAN_REMIT_CUSTOMER` | `customer_id` |

Each Oman Remit remittance is associated with the Oman Remit customer initiating it.

---

# 6. Complete Foreign-Key Register

| Child Entity            | Foreign Key       | Parent Entity         | Parent Key        |
| ----------------------- | ----------------- | --------------------- | ----------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER`        | `ocb_customer_id` |
| `ANANSE_TRANSACTION`    | `customer_id`     | `ANANSE_CUSTOMER`     | `customer_id`     |
| `ANANSE_TRANSACTION`    | `wallet_id`       | `ANANSE_WALLET`       | `wallet_id`       |
| `SIKACREDIT_LOAN`       | `customer_id`     | `SIKACREDIT_CUSTOMER` | `customer_id`     |
| `SIKACREDIT_REPAYMENT`  | `loan_id`         | `SIKACREDIT_LOAN`     | `loan_id`         |
| `OMAN_REMIT_REMITTANCE` | `customer_id`     | `OMAN_REMIT_CUSTOMER` | `customer_id`     |

---

# 7. Relationships Deliberately Not Modelled

The following relationships are **not established as direct foreign keys** at this stage.

### 7.1 Institutional customers → `OCB_CUSTOMER`

There is no direct:

```text
ANANSE_CUSTOMER.ocb_customer_id
```

or equivalent column in the institutional customer entities.

The mapping is maintained through:

```text
OCB_CUSTOMER_IDENTITY
```

This preserves source-system ownership and keeps OCB identity resolution separate from institutional records.

---

### 7.2 Oman Remit → Ananse Wallet

No direct FK is created between:

```text
OMAN_REMIT_REMITTANCE
```

and:

```text
ANANSE_WALLET
```

The eventual financial consequence and ledger posting provide the appropriate architectural boundary for cross-institutional financial linkage.

---

### 7.3 SikaCredit → Ananse Wallet

No direct FK is created between SikaCredit loan/repayment entities and Ananse wallets.

The institutional lending activity produces financial consequences that are handled through the financial-core architecture.

---

### 7.4 Ananse Transaction → OCB Customer

No direct FK is placed from:

```text
ANANSE_TRANSACTION
```

to:

```text
OCB_CUSTOMER
```

The institutional transaction remains linked to its source customer.

OCB resolves the source customer to `ocb_customer_id` through the identity-mapping layer.

---

# 8. Relationship Integrity Principle

Foreign keys represent **actual ownership or dependency relationships**, not merely relationships that may be useful for analytical joins.

Therefore:

```text
Institutional entity
        ↓
Institutional identity
```

is represented directly where appropriate, while:

```text
Institutional identity
        ↓
OCB resolved identity
```

is represented through the dedicated identity-resolution object.

Cross-institutional financial consequences are not forced into institutional foreign-key relationships.

---

# 9. Final Decision

The six foreign-key relationships defined in this document constitute the authoritative FK baseline for the current logical model.

They are:

```text
OCB_CUSTOMER_IDENTITY → OCB_CUSTOMER

ANANSE_TRANSACTION → ANANSE_CUSTOMER
ANANSE_TRANSACTION → ANANSE_WALLET

SIKACREDIT_LOAN → SIKACREDIT_CUSTOMER
SIKACREDIT_REPAYMENT → SIKACREDIT_LOAN

OMAN_REMIT_REMITTANCE → OMAN_REMIT_CUSTOMER
```

No additional cross-institutional foreign keys are introduced at the logical-model stage without an explicit architectural decision.

**WP-2.2-T04 — REVISED AND LOCKED.**
