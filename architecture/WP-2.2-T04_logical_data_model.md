# WP-2.2-T04 — Define Foreign-Key Relationships

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T04
**Status:** **COMPLETE**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

WP-2.2-T04 defines the foreign-key relationships between the relational entities established in WP-2.2.

The purpose is to establish which entities depend on the identifiers of other entities before cardinalities and normalization are reviewed.

This ticket does not define:

* relationship cardinality;
* normalization;
* physical database constraints;
* indexes;
* analytical joins;
* derived relationships that have not yet been established as relational dependencies.

---

# 2. Foreign-Key Design Principles

### 2.1 Foreign keys represent established relational dependencies

A foreign key is introduced only where one entity's record depends on an identifiable record in another entity.

### 2.2 Institutional customer identifiers remain institution-specific

The `customer_id` used by Ananse, SikaCredit, and Oman Remit represents each institution's own customer identity.

These identifiers are not assumed to be interchangeable.

### 2.3 OCB identity resolution is handled through the identity-mapping entity

OCB does not directly replace institutional customer identifiers.

Instead:

```text
OCB_CUSTOMER
      │
      ▼
OCB_CUSTOMER_IDENTITY
      │
      ├── ANANSE customer identity
      ├── SIKACREDIT customer identity
      └── OMAN REMIT customer identity
```

The identity-mapping entity therefore provides the cross-institutional identity bridge.

### 2.4 Do not manufacture foreign keys

A relationship is not converted into a foreign key merely because the business process conceptually connects two institutions.

The required linking attribute must first exist and have a defined semantic meaning.

---

# 3. OCB Identity Relationships

## 3.1 OCB Customer Identity → OCB Customer

**Child entity:**

`OCB_CUSTOMER_IDENTITY`

**Foreign key:**

`ocb_customer_id`

**Parent entity:**

`OCB_CUSTOMER`

```text
OCB_CUSTOMER
    │
    │ ocb_customer_id
    ▼
OCB_CUSTOMER_IDENTITY
```

The foreign key establishes which OCB-resolved customer an institutional identity belongs to.

The identity mapping retains:

```text
source_entity
source_customer_id
ocb_customer_id
```

The composite primary key remains:

```text
(source_entity, source_customer_id)
```

---

# 4. Ananse Relationships

## 4.1 Ananse Transaction → Ananse Customer

**Child entity:**

`ANANSE_TRANSACTION`

**Foreign key:**

`customer_id`

**Parent entity:**

`ANANSE_CUSTOMER`

```text
ANANSE_CUSTOMER
       │
       ▼
ANANSE_TRANSACTION
```

The relationship identifies the Ananse customer associated with a transaction.

---

## 4.2 Ananse Transaction → Ananse Wallet

**Child entity:**

`ANANSE_TRANSACTION`

**Foreign key:**

`wallet_id`

**Parent entity:**

`ANANSE_WALLET`

```text
ANANSE_WALLET
      │
      ▼
ANANSE_TRANSACTION
```

The relationship identifies the wallet associated with the transaction.

The wallet remains a distinct object from both the customer and transaction.

---

# 5. SikaCredit Relationships

## 5.1 SikaCredit Loan → SikaCredit Customer

**Child entity:**

`SIKACREDIT_LOAN`

**Foreign key:**

`customer_id`

**Parent entity:**

`SIKACREDIT_CUSTOMER`

```text
SIKACREDIT_CUSTOMER
        │
        ▼
SIKACREDIT_LOAN
```

The relationship identifies the customer to whom the loan belongs.

---

## 5.2 SikaCredit Repayment → SikaCredit Loan

**Child entity:**

`SIKACREDIT_REPAYMENT`

**Foreign key:**

`loan_id`

**Parent entity:**

`SIKACREDIT_LOAN`

```text
SIKACREDIT_LOAN
       │
       ▼
SIKACREDIT_REPAYMENT
```

This permits multiple repayment records to be associated with a single loan.

Example:

```text
LOAN-5001
    │
    ├── REPAYMENT-7001
    ├── REPAYMENT-7002
    └── REPAYMENT-7003
```

---

# 6. Oman Remit Relationships

## 6.1 Oman Remittance → Oman Remit Customer

**Child entity:**

`OMAN_REMIT_REMITTANCE`

**Foreign key:**

`customer_id`

**Parent entity:**

`OMAN_REMIT_CUSTOMER`

```text
OMAN_REMIT_CUSTOMER
        │
        ▼
OMAN_REMIT_REMITTANCE
```

The relationship identifies the Oman Remit customer associated with the remittance.

No separate `sender_customer_id` is introduced because it would duplicate the role already represented by `customer_id`.

---

# 7. Cross-Institutional Identity Relationships

The institutional customer identifiers are not directly linked to one another.

The model instead uses the OCB identity-resolution layer:

```text
                    OCB_CUSTOMER
                         │
                         │
                         ▼
              OCB_CUSTOMER_IDENTITY
                  │        │        │
                  ▼        ▼        ▼
               ANANSE   SIKACREDIT  OMAN
              CUSTOMER   CUSTOMER   REMIT
```

This prevents the model from incorrectly treating:

```text
ANANSE.customer_id
SIKACREDIT.customer_id
OMAN_REMIT.customer_id
```

as the same identifier.

The `OCB_CUSTOMER_IDENTITY` entity is the controlled resolution bridge.

---

# 8. Oman Remit → Ananse Wallet

The business architecture establishes that Oman Remit remittances can ultimately result in funds being received through an Ananse wallet.

However, **no foreign key is introduced at this stage**.

The current Oman Remit attribute set does not contain a defined Ananse wallet identifier.

Therefore, the logical model does not manufacture:

```text
wallet_id
```

inside `OMAN_REMIT_REMITTANCE` simply to force the relationship.

The relationship will be addressed when the relevant cross-institutional linkage and financial-consequence model are defined.

This is an intentional modelling decision, not an omission.

---

# 9. Foreign-Key Register

| Child Entity            | Foreign Key       | Parent Entity         |
| ----------------------- | ----------------- | --------------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER`        |
| `ANANSE_TRANSACTION`    | `customer_id`     | `ANANSE_CUSTOMER`     |
| `ANANSE_TRANSACTION`    | `wallet_id`       | `ANANSE_WALLET`       |
| `SIKACREDIT_LOAN`       | `customer_id`     | `SIKACREDIT_CUSTOMER` |
| `SIKACREDIT_REPAYMENT`  | `loan_id`         | `SIKACREDIT_LOAN`     |
| `OMAN_REMIT_REMITTANCE` | `customer_id`     | `OMAN_REMIT_CUSTOMER` |

---

# 10. Design Decisions

The following decisions are locked by WP-2.2-T04:

1. `OCB_CUSTOMER_IDENTITY.ocb_customer_id` references `OCB_CUSTOMER.ocb_customer_id`.
2. `ANANSE_TRANSACTION.customer_id` references `ANANSE_CUSTOMER.customer_id`.
3. `ANANSE_TRANSACTION.wallet_id` references `ANANSE_WALLET.wallet_id`.
4. `SIKACREDIT_LOAN.customer_id` references `SIKACREDIT_CUSTOMER.customer_id`.
5. `SIKACREDIT_REPAYMENT.loan_id` references `SIKACREDIT_LOAN.loan_id`.
6. `OMAN_REMIT_REMITTANCE.customer_id` references `OMAN_REMIT_CUSTOMER.customer_id`.
7. Institutional customer identifiers remain institution-specific.
8. OCB identity resolution is performed through `OCB_CUSTOMER_IDENTITY`.
9. No sender or receiver customer identifier is introduced into Oman Remit.
10. No `wallet_id` is introduced into Oman Remit solely to manufacture a cross-institutional FK.
11. The Oman Remit → Ananse Wallet relationship remains an explicitly unresolved logical relationship pending the appropriate linkage design.

---

# 11. Final Decision

WP-2.2-T04 establishes the foreign-key dependencies required by the current logical model.

The six confirmed foreign-key relationships are now **locked**.

The Oman Remit → Ananse Wallet relationship is intentionally left unresolved until the appropriate cross-institutional linkage is defined.

**WP-2.2-T04 — COMPLETE.**
