## WP-2.2-T06 — Review Normalization

This ticket is a **review**, not a redesign. We take the entities, attributes, keys, FKs, and cardinalities already locked in T01–T05 and test whether the logical model introduces obvious normalization problems.

### 1. Ananse

```text
ANANSE_CUSTOMER
       │
       │ 1:M
       ▼
ANANSE_TRANSACTION
       ▲
       │ M:1
       │
ANANSE_WALLET
```

This is appropriately separated because:

* customer attributes describe the **customer**;
* wallet attributes describe the **wallet**;
* transaction attributes describe the **transaction**.

Therefore, customer and wallet attributes do not have to be repeatedly stored on every transaction.

**Assessment: Normalized.**

---

### 2. SikaCredit

```text
SIKACREDIT_CUSTOMER
        │
        │ 1:M
        ▼
SIKACREDIT_LOAN
        │
        │ 1:M
        ▼
SIKACREDIT_REPAYMENT
```

This is particularly important because one loan can have multiple repayments.

Putting repayment attributes directly into the loan entity would create repeating groups or force an artificial limit on the number of repayments.

The current structure avoids that.

**Assessment: Normalized.**

---

### 3. Oman Remit

```text
OMAN_REMIT_CUSTOMER
        │
        │ 1:M
        ▼
OMAN_REMIT_REMITTANCE
```

Customer attributes remain at customer grain, while remittance attributes remain at remittance grain.

**Assessment: Normalized.**

---

### 4. OCB Identity

```text
OCB_CUSTOMER
      │
      │ 1:M
      ▼
OCB_CUSTOMER_IDENTITY
```

The identity mapping is separated because one OCB identity may correspond to multiple institutional identities.

The composite key:

```text
(source_entity, source_customer_id)
```

uniquely identifies the source identity.

`ocb_customer_id` identifies the OCB-resolved identity to which that source identity maps.

**Assessment: Normalized.**

---

# 5. Functional Dependency Review

The principal dependencies are:

```text
ocb_customer_id
    → OCB customer identity
```

```text
(source_entity, source_customer_id)
    → ocb_customer_id
```

```text
customer_id
    → customer attributes
```

```text
transaction_id
    → transaction attributes
```

```text
wallet_id
    → wallet attributes
```

```text
loan_id
    → loan attributes
```

```text
repayment_id
    → repayment attributes
```

```text
remittance_id
    → remittance attributes
```

These dependencies align with the entity grains established in T01–T05.

---

# 6. Repeating Groups

No confirmed repeating groups remain.

In particular:

```text
SIKACREDIT_LOAN
        │
        ├── repayment 1
        ├── repayment 2
        └── repayment 3
```

is represented through separate repayment rows rather than repeating repayment columns inside the loan record.

**Result: Pass.**

---

# 7. Partial Dependencies

No confirmed partial dependencies exist within the current entity structures.

The principal composite key is:

```text
OCB_CUSTOMER_IDENTITY
PK = (source_entity, source_customer_id)
```

Both components are required to identify the source identity.

`ocb_customer_id` is not part of that primary key and therefore does not create a partial dependency within the composite key.

**Result: Pass.**

---

# 8. Transitive Dependencies

Customer attributes are not stored in transaction, loan, repayment, or remittance entities.

For example, the model does **not** do this:

```text
ANANSE_TRANSACTION
------------------
transaction_id
customer_id
customer_name
customer_phone
...
```

Instead:

```text
ANANSE_CUSTOMER
----------------
customer_id
customer_name
customer_phone
...
```

and:

```text
ANANSE_TRANSACTION
------------------
transaction_id
customer_id
...
```

This prevents customer attributes from being transitively dependent on the transaction identifier.

**Result: Pass.**

---

# 9. Deliberate Denormalization

No deliberate denormalization is introduced at the logical-model level.

The model remains focused on representing the underlying entities and their relationships.

Analytical or performance-oriented denormalization may occur later in the Gold/analytical layer where justified, but that is outside this normalization review.

---

# 10. Oman Remit → Ananse Wallet

The unresolved cross-institutional relationship is **not treated as a normalization defect**.

The issue is currently one of **relationship definition**, not normalization.

We deliberately do not add an artificial `wallet_id` merely to force the relationship into the model.

---

# 11. Normalization Decision

The logical model passes the normalization review.

The current structure:

* separates different entity grains;
* removes repeating groups;
* avoids unnecessary attribute duplication;
* preserves functional dependencies;
* avoids confirmed partial dependencies;
* avoids confirmed transitive dependencies;
* keeps cross-institutional identity resolution explicit;
* does not introduce unnecessary denormalization.

### Final status

**WP-2.2-T06 — COMPLETE**

The logical model is considered sufficiently normalized for the scope of OCB Platform v1.0.0.