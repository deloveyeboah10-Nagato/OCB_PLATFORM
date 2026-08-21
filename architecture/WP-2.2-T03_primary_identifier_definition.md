# WP-2.2-T03 — Primary Identifier Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T03
**Status:** **COMPLETE**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

WP-2.2-T03 defines the **primary identifiers** for the relational entities established within WP-2.2.

The purpose is to establish how each entity is uniquely identified before foreign-key relationships and cardinalities are defined.

This ticket does not define:

* foreign-key relationships;
* relationship cardinality;
* physical indexes;
* surrogate keys beyond those explicitly defined;
* analytical keys;
* implementation-specific constraints.

Those are addressed by subsequent tickets.

---

# 2. Primary Identifier Principles

### 2.1 Institutional identifiers are retained

Where an institutional system already provides a meaningful unique identifier, OCB retains that identifier as the primary identifier of the corresponding institutional entity.

Examples:

```text
ANANSE      → customer_id
SIKACREDIT  → customer_id
OMAN REMIT  → customer_id
```

OCB does not replace these source identifiers merely for the sake of uniformity.

### 2.2 OCB identity is independently identified

`ocb_customer_id` uniquely identifies the OCB-resolved customer.

It is therefore the primary identifier of the OCB customer entity.

### 2.3 Identity mappings require composite uniqueness

An OCB customer may correspond to multiple institutional customer identities.

Therefore, `ocb_customer_id` alone cannot uniquely identify an identity-mapping record.

The source identity is uniquely identified by:

```text
(source_entity, source_customer_id)
```

This prevents the same source customer from being represented more than once within the identity mapping.

### 2.4 Activity records require their own identifiers

Transactions, loans, repayments, and remittances are individual business records and therefore receive their own identifiers.

---

# 3. OCB Primary Identifiers

## 3.1 OCB Customer

```text
OCB_CUSTOMER
----------------
ocb_customer_id  PK
```

**Primary Key:** `ocb_customer_id`

This is the canonical identifier for an OCB-resolved customer.

---

## 3.2 OCB Customer Identity

```text
OCB_CUSTOMER_IDENTITY
-------------------------
source_entity       PK
source_customer_id  PK
ocb_customer_id
```

**Composite Primary Key:**

```text
(source_entity, source_customer_id)
```

This represents the unique source-side identity being mapped to an OCB customer.

Example:

```text
source_entity    source_customer_id    ocb_customer_id
-------------    ------------------    --------------
ANANSE           AN-C-104              OCB-C-104
SIKACREDIT       SC-C-104              OCB-C-104
OMAN_REMIT       OR-C-883              OCB-C-104
```

The same `ocb_customer_id` can therefore appear across multiple mapping records.

---

# 4. Ananse Primary Identifiers

| Entity               | Primary Key      |
| -------------------- | ---------------- |
| `ANANSE_CUSTOMER`    | `customer_id`    |
| `ANANSE_WALLET`      | `wallet_id`      |
| `ANANSE_TRANSACTION` | `transaction_id` |

### Interpretation

* `customer_id` uniquely identifies an Ananse customer.
* `wallet_id` uniquely identifies an Ananse wallet.
* `transaction_id` uniquely identifies an Ananse transaction.

The wallet remains a distinct entity and is not conflated with the Ananse customer or transaction.

---

# 5. SikaCredit Primary Identifiers

| Entity                 | Primary Key    |
| ---------------------- | -------------- |
| `SIKACREDIT_CUSTOMER`  | `customer_id`  |
| `SIKACREDIT_LOAN`      | `loan_id`      |
| `SIKACREDIT_REPAYMENT` | `repayment_id` |

### Interpretation

* `customer_id` uniquely identifies a SikaCredit customer.
* `loan_id` uniquely identifies a loan.
* `repayment_id` uniquely identifies an individual repayment.

A single `loan_id` may therefore be associated with multiple `repayment_id` values.

Example:

```text
loan_id     repayment_id
--------    ------------
L-5001      R-7001
L-5001      R-7002
L-5001      R-7003
```

This supports the one-to-many loan-to-repayment structure without placing multiple repayments into a single loan record.

---

# 6. Oman Remit Primary Identifiers

| Entity                  | Primary Key     |
| ----------------------- | --------------- |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`   |
| `OMAN_REMIT_REMITTANCE` | `remittance_id` |

### Interpretation

* `customer_id` uniquely identifies an Oman Remit customer.
* `remittance_id` uniquely identifies an individual remittance.

No separate sender or receiver identifier is introduced at this stage.

The relationship between Oman Remit and the receiving Ananse account/customer will be established through subsequent relational modelling rather than duplicated as an Oman Remit primary identifier.

---

# 7. Consolidated Primary-Key Register

| Entity                  | Primary Identifier                    |
| ----------------------- | ------------------------------------- |
| `OCB_CUSTOMER`          | `ocb_customer_id`                     |
| `OCB_CUSTOMER_IDENTITY` | `(source_entity, source_customer_id)` |
| `ANANSE_CUSTOMER`       | `customer_id`                         |
| `ANANSE_WALLET`         | `wallet_id`                           |
| `ANANSE_TRANSACTION`    | `transaction_id`                      |
| `SIKACREDIT_CUSTOMER`   | `customer_id`                         |
| `SIKACREDIT_LOAN`       | `loan_id`                             |
| `SIKACREDIT_REPAYMENT`  | `repayment_id`                        |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`                         |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`                       |

---

# 8. Design Decision

The logical model will use **natural/institutional identifiers where those identifiers already exist and have defined uniqueness**, rather than introducing unnecessary surrogate identifiers at this stage.

The OCB identity mapping is the principal exception requiring composite identification because its purpose is to represent the relationship between an institutional identity and its OCB-resolved identity.

---

# 9. Final Decision

WP-2.2-T03 establishes the primary identifier for every currently defined relational entity.

The identifiers are now **locked for the logical model**.

**WP-2.2-T03 — COMPLETE.**

**Next:** WP-2.2-T04 — **Define Foreign-Key Relationships**.
