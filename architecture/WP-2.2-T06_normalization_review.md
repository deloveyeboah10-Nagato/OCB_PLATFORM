# WP-2.2-T06 — Review Normalization

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T06
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model validation

---

## 1. Purpose

This ticket reviews the logical relational model established through **WP-2.2-T01 to T05** for structural normalization and unnecessary duplication.

The review confirms that each entity represents a coherent business object or relationship, attributes remain at the appropriate grain, and repeating groups are not embedded within single records.

The review is performed against the **corrected post-T01 model**.

---

# 2. Normalization Standard

The logical model is designed to satisfy the practical requirements of **Third Normal Form (3NF)**:

1. Each entity represents a defined object or relationship.
2. Each attribute contains a single logical value.
3. Non-key attributes depend on the whole primary key.
4. Non-key attributes do not depend on other non-key attributes.
5. Repeating groups and multi-valued attributes are represented through related records rather than repeated columns.

The objective is not theoretical normalization for its own sake.

The objective is to preserve:

* clear entity ownership;
* correct grain;
* historical integrity;
* analytical usability;
* controlled relational coupling.

---

# 3. OCB Normalization Review

## 3.1 `OCB_CUSTOMER`

```text
PK: ocb_customer_id
```

The entity contains only the OCB-resolved identity.

No institutional demographic attributes are duplicated here.

**Result: Normalized.**

---

## 3.2 `OCB_CUSTOMER_IDENTITY`

```text
PK: (source_entity, source_customer_id)
FK: ocb_customer_id
```

The source-system identity is represented once and mapped to the corresponding OCB identity.

The composite key prevents the same source identity from being represented repeatedly.

**Result: Normalized.**

---

# 4. Ananse Normalization Review

## 4.1 `ANANSE_CUSTOMER`

```text
PK: customer_id
```

Customer attributes depend on the Ananse customer identifier.

Transaction-level attributes are not stored here.

**Result: Normalized.**

---

## 4.2 `ANANSE_WALLET`

```text
PK: wallet_id
```

The wallet is maintained as a separate entity rather than embedding wallet information into customer or transaction records.

**Result: Normalized.**

---

## 4.3 `ANANSE_TRANSACTION`

```text
PK: transaction_id
FK: customer_id
FK: wallet_id
```

Transaction-specific attributes depend on the transaction identifier.

The transaction does not repeat customer demographic information or wallet-level information.

`device_id` remains a transaction-level attribute because the device associated with an individual transaction is part of the activity record.

**Result: Normalized.**

---

# 5. SikaCredit Normalization Review

## 5.1 `SIKACREDIT_CUSTOMER`

```text
PK: customer_id
```

Customer attributes depend on the customer identifier.

Loan and repayment attributes are not embedded in the customer entity.

**Result: Normalized.**

---

## 5.2 `SIKACREDIT_LOAN`

```text
PK: loan_id
FK: customer_id
```

Loan-level attributes depend on the loan identifier.

Customer attributes are referenced through `customer_id` rather than duplicated.

**Result: Normalized.**

---

## 5.3 `SIKACREDIT_REPAYMENT`

```text
PK: repayment_id
FK: loan_id
```

Each repayment is represented as an independent record.

This prevents repeating repayment columns such as:

```text
repayment_1_amount
repayment_2_amount
repayment_3_amount
```

and supports an arbitrary number of repayments against a loan.

**Result: Normalized.**

---

# 6. Oman Remit Normalization Review

## 6.1 `OMAN_REMIT_CUSTOMER`

```text
PK: customer_id
```

Customer-level attributes depend on the customer identifier.

Remittance-level attributes are not duplicated within the customer entity.

**Result: Normalized.**

---

## 6.2 `OMAN_REMIT_REMITTANCE`

```text
PK: remittance_id
FK: customer_id
```

Remittance-specific attributes depend on the remittance identifier.

Customer information is referenced through the customer relationship rather than duplicated.

**Result: Normalized.**

---

# 7. Repeating-Group Review

The model deliberately avoids repeating groups.

For example, SikaCredit repayments are not represented as:

```text
loan_id
repayment_1_amount
repayment_1_timestamp
repayment_2_amount
repayment_2_timestamp
...
```

Instead:

```text
SIKACREDIT_LOAN
        │
        └── SIKACREDIT_REPAYMENT
                │
                ├── repayment_id
                ├── loan_id
                ├── repayment_amount
                ├── repayment_timestamp
                └── repayment_location
```

This preserves the one-repayment-per-record grain.

---

# 8. Customer Attribute Duplication

The fact that each institutional customer entity contains similar attribute names does not constitute an unintended normalization violation.

For example:

```text
ANANSE_CUSTOMER.first_name
SIKACREDIT_CUSTOMER.first_name
OMAN_REMIT_CUSTOMER.first_name
```

represent **source-owned attributes belonging to different institutional entities**.

They are not duplicate rows within a single relational entity.

OCB identity resolution may later determine that those records represent the same real-world customer, but that does not transfer ownership of the source attributes to OCB.

**Result: Intentional duplication across independent source domains.**

---

# 9. Cross-Institutional Identity Review

The model avoids placing institutional customer attributes directly inside `OCB_CUSTOMER`.

Instead:

```text
OCB_CUSTOMER
      │
      └── OCB_CUSTOMER_IDENTITY
              │
              ├── ANANSE customer
              ├── SikaCredit customer
              └── Oman Remit customer
```

This prevents OCB from becoming a duplicate institutional customer table.

Derived OCB analytical attributes may be created downstream when required.

**Result: Normalized and consistent with the identity-resolution boundary.**

---

# 10. Historical and Transactional Integrity

The model does not overwrite historical transaction activity with current customer attributes.

Customer records and activities are separated so that:

* customer attributes remain customer-level;
* transactions remain transaction-level;
* loans remain loan-level;
* repayments remain repayment-level;
* remittances remain remittance-level.

This supports the platform's principle that financial activity remains historically observable.

---

# 11. Normalization Exceptions

No intentional denormalization is introduced in the current logical model.

Any later denormalization for analytical performance must occur downstream of the logical source model and must not alter the authoritative operational grain.

---

# 12. Final Normalization Assessment

| Entity                  | Assessment   |
| ----------------------- | ------------ |
| `OCB_CUSTOMER`          | ✅ Normalized |
| `OCB_CUSTOMER_IDENTITY` | ✅ Normalized |
| `ANANSE_CUSTOMER`       | ✅ Normalized |
| `ANANSE_WALLET`         | ✅ Normalized |
| `ANANSE_TRANSACTION`    | ✅ Normalized |
| `SIKACREDIT_CUSTOMER`   | ✅ Normalized |
| `SIKACREDIT_LOAN`       | ✅ Normalized |
| `SIKACREDIT_REPAYMENT`  | ✅ Normalized |
| `OMAN_REMIT_CUSTOMER`   | ✅ Normalized |
| `OMAN_REMIT_REMITTANCE` | ✅ Normalized |

The logical model satisfies the intended **3NF-oriented design standard**.

---

# 13. Final Decision

The normalization review confirms that the corrected WP-2.2 logical model:

* maintains clear entity boundaries;
* preserves entity grain;
* avoids repeating groups;
* separates customers from activities;
* separates loans from repayments;
* separates wallets from transactions;
* maintains source ownership of institutional attributes;
* uses identity mapping rather than duplicating institutional identity into OCB;
* introduces no intentional operational denormalization.

No normalization changes are required at this stage.

**WP-2.2-T06 — REVISED AND LOCKED.**
