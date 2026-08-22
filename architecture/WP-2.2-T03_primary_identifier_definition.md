# WP-2.2-T03 — Define Primary Identifiers

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T03
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the primary identifiers for all relational entities established in **WP-2.2-T01** and whose attributes were defined in **WP-2.2-T02**.

Each entity has a stable identifier appropriate to its own grain.

Primary identifiers are not required to be globally unique across the entire platform. Their uniqueness is evaluated within the entity in which they are defined.

---

# 2. OCB Primary Identifiers

## 2.1 `OCB_CUSTOMER`

| Entity         | Primary Identifier |
| -------------- | ------------------ |
| `OCB_CUSTOMER` | `ocb_customer_id`  |

`ocb_customer_id` uniquely identifies an OCB-resolved customer identity.

---

## 2.2 `OCB_CUSTOMER_IDENTITY`

| Entity                  | Primary Identifier                    |
| ----------------------- | ------------------------------------- |
| `OCB_CUSTOMER_IDENTITY` | `(source_entity, source_customer_id)` |

The combination of:

```text
source_entity
source_customer_id
```

uniquely identifies an institutional customer identity within the OCB identity-resolution registry.

`ocb_customer_id` is a foreign key to `OCB_CUSTOMER`, not the primary identifier of this mapping entity.

---

# 3. Ananse Primary Identifiers

## 3.1 `ANANSE_CUSTOMER`

| Entity            | Primary Identifier |
| ----------------- | ------------------ |
| `ANANSE_CUSTOMER` | `customer_id`      |

`customer_id` uniquely identifies an Ananse customer.

---

## 3.2 `ANANSE_WALLET`

| Entity          | Primary Identifier |
| --------------- | ------------------ |
| `ANANSE_WALLET` | `wallet_id`        |

`wallet_id` uniquely identifies an Ananse wallet.

---

## 3.3 `ANANSE_TRANSACTION`

| Entity               | Primary Identifier |
| -------------------- | ------------------ |
| `ANANSE_TRANSACTION` | `transaction_id`   |

`transaction_id` uniquely identifies an Ananse transaction/activity record.

The transaction identifier is distinct from both:

```text
customer_id
wallet_id
```

because those identify different objects.

---

# 4. SikaCredit Primary Identifiers

## 4.1 `SIKACREDIT_CUSTOMER`

| Entity                | Primary Identifier |
| --------------------- | ------------------ |
| `SIKACREDIT_CUSTOMER` | `customer_id`      |

`customer_id` uniquely identifies a SikaCredit customer.

---

## 4.2 `SIKACREDIT_LOAN`

| Entity            | Primary Identifier |
| ----------------- | ------------------ |
| `SIKACREDIT_LOAN` | `loan_id`          |

`loan_id` uniquely identifies a SikaCredit loan.

---

## 4.3 `SIKACREDIT_REPAYMENT`

| Entity                 | Primary Identifier |
| ---------------------- | ------------------ |
| `SIKACREDIT_REPAYMENT` | `repayment_id`     |

`repayment_id` uniquely identifies an individual repayment event.

A repayment is therefore independently identifiable while retaining `loan_id` as the identifier of the loan to which it belongs.

---

# 5. Oman Remit Primary Identifiers

## 5.1 `OMAN_REMIT_CUSTOMER`

| Entity                | Primary Identifier |
| --------------------- | ------------------ |
| `OMAN_REMIT_CUSTOMER` | `customer_id`      |

`customer_id` uniquely identifies an Oman Remit customer.

---

## 5.2 `OMAN_REMIT_REMITTANCE`

| Entity                  | Primary Identifier |
| ----------------------- | ------------------ |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`    |

`remittance_id` uniquely identifies an individual Oman Remit remittance activity.

---

# 6. Complete Primary-Key Register

| Entity                  | Primary Key                           | Grain                               |
| ----------------------- | ------------------------------------- | ----------------------------------- |
| `OCB_CUSTOMER`          | `ocb_customer_id`                     | One resolved OCB identity           |
| `OCB_CUSTOMER_IDENTITY` | `(source_entity, source_customer_id)` | One source-system customer identity |
| `ANANSE_CUSTOMER`       | `customer_id`                         | One Ananse customer                 |
| `ANANSE_WALLET`         | `wallet_id`                           | One Ananse wallet                   |
| `ANANSE_TRANSACTION`    | `transaction_id`                      | One Ananse transaction              |
| `SIKACREDIT_CUSTOMER`   | `customer_id`                         | One SikaCredit customer             |
| `SIKACREDIT_LOAN`       | `loan_id`                             | One SikaCredit loan                 |
| `SIKACREDIT_REPAYMENT`  | `repayment_id`                        | One SikaCredit repayment            |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`                         | One Oman Remit customer             |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`                       | One Oman Remit remittance           |

---

# 7. Identifier Principles

### 7.1 Entity-specific identity

Each primary identifier identifies the object represented by its entity.

For example:

```text
customer_id       → customer
wallet_id         → wallet
transaction_id    → transaction
loan_id           → loan
repayment_id      → repayment
remittance_id     → remittance
```

No identifier is reused to represent a different object merely because the objects are related.

---

### 7.2 Customer identifiers remain institution-owned

The same literal value may exist independently in different institutional systems:

```text
ANANSE_CUSTOMER.customer_id
SIKACREDIT_CUSTOMER.customer_id
OMAN_REMIT_CUSTOMER.customer_id
```

These are not assumed to represent the same customer solely because the identifier has the same name or value.

Cross-institutional identity is established through:

```text
OCB_CUSTOMER
        ↓
OCB_CUSTOMER_IDENTITY
```

---

### 7.3 Composite identity for source mapping

`OCB_CUSTOMER_IDENTITY` uses:

```text
(source_entity, source_customer_id)
```

because `source_customer_id` alone is not sufficient to identify a source customer across multiple institutions.

For example:

```text
ANANSE + CUST-001
SIKACREDIT + CUST-001
OMAN_REMIT + CUST-001
```

represent three distinct source identities unless OCB resolves them to the same `ocb_customer_id`.

---

# 8. Final Decision

The primary identifiers defined above are the authoritative identifier baseline for the OCB Platform logical model.

No subsequent logical-model ticket may introduce an alternative primary identifier without explicitly reopening this decision.

**WP-2.2-T03 — REVISED AND LOCKED.**
