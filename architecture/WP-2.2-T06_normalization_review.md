# WP-2.2-T06 — Review Normalization

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T06
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model validation

---

# 1. Purpose

This ticket reviews the logical relational model established through **WP-2.2-T01 to T05** for structural normalization, attribute dependency, repeating groups, unnecessary duplication, and consistency with the **approved physical deployment structure**.

The review is performed against the **corrected post-T01 model** and the reconciled attribute and foreign-key definitions established in:

* **WP-2.2-T02 — Define Attributes**
* **WP-2.2-T03 — Define Primary Identifiers**
* **WP-2.2-T04 — Define Foreign-Key Relationships**
* **WP-2.2-T05 — Define Cardinality**

The review distinguishes between:

1. the **logical entity model** and its normalization characteristics; and
2. deliberate **physical-source attributes retained for deployment and analytical purposes**.

The objective is not to claim theoretical purity where the physical deployment deliberately retains source-level descriptive attributes.

The objective is to confirm that:

* entities have coherent business grains;
* attributes remain with their owning entities;
* repeating groups are eliminated;
* relational dependencies are explicit;
* foreign-key relationships are structurally sound;
* source-owned attributes are not improperly consolidated;
* physical deployment decisions are accurately reflected in the logical baseline.

---

# 2. Normalization Standard

The logical model is evaluated using a **3NF-oriented relational design standard**.

The review considers the following principles:

1. Each entity represents a defined business object or relationship.
2. Each attribute represents a single logical value.
3. Attributes belong to the grain of the entity in which they are stored.
4. Non-key attributes depend on the entity's identifying key.
5. Repeating groups and arbitrary multi-valued attributes are represented as related records.
6. Relationships between entities are represented through explicit foreign keys where required.
7. Source-owned attributes are not unnecessarily transferred between institutional entities.
8. Deliberate physical duplication is explicitly identified rather than incorrectly classified as normalization.

The standard is therefore:

> **Normalized logical entity boundaries, with explicitly documented physical-source attributes where required by the approved deployment.**

---

# 3. OCB Normalization Review

## 3.1 `OCB_CUSTOMER`

```text
PK:
ocb_customer_id
```

`OCB_CUSTOMER` represents the OCB-resolved cross-institutional identity.

It does not contain:

* Ananse demographic attributes;
* SikaCredit demographic attributes;
* Oman Remit demographic attributes;
* transaction attributes;
* loan attributes;
* remittance attributes.

This preserves a clear identity boundary.

**Result: ✅ Normalized.**

---

## 3.2 `OCB_CUSTOMER_IDENTITY`

```text
PK:
(source_entity, source_customer_id)

FK:
ocb_customer_id
```

The entity represents the mapping between an institutional source identity and the corresponding OCB-resolved identity.

The composite primary key ensures that:

```text
(source_entity, source_customer_id)
```

identifies one source-system customer identity.

The `ocb_customer_id` attribute establishes the relationship to the OCB-resolved identity.

No institutional customer demographic attributes are duplicated into this mapping entity.

**Result: ✅ Normalized.**

---

# 4. Ananse Normalization Review

## 4.1 `ANANSE_CUSTOMER`

```text
PK:
customer_id
```

The entity contains only Ananse customer-level attributes.

Customer attributes such as:

```text
first_name
last_name
date_of_birth
nationality
occupation
phone_number
email
created_at
```

belong to the customer grain.

Transaction-level and wallet-level attributes are not embedded within the customer entity.

**Result: ✅ Normalized.**

---

## 4.2 `ANANSE_WALLET`

```text
PK:
wallet_id

FK:
customer_id
```

The wallet is represented as a distinct financial object.

The relationship:

```text
ANANSE_WALLET.customer_id
        ↓
ANANSE_CUSTOMER.customer_id
```

establishes wallet ownership by the Ananse customer.

Wallet attributes are not embedded in the customer or transaction entities.

**Result: ✅ Normalized.**

---

## 4.3 `ANANSE_TRANSACTION`

```text
PK:
transaction_id

FKs:
customer_id
wallet_id
transaction_type_id
transaction_status_id
transaction_channel_id
currency_id
```

The transaction entity represents one transaction/activity record.

Transaction-level attributes remain at transaction grain.

The relational dependencies are explicitly represented through:

```text
customer_id
wallet_id
transaction_type_id
transaction_status_id
transaction_channel_id
currency_id
```

These establish the following relationships:

```text
customer_id
    ↓
ananse.customer

wallet_id
    ↓
wallet.wallet

transaction_type_id
    ↓
ref.transaction_type

transaction_status_id
    ↓
ref.transaction_status

transaction_channel_id
    ↓
ref.transaction_channel

currency_id
    ↓
ref.currency
```

The transaction does not contain customer demographic attributes or wallet-level attributes.

`device_id` remains transaction-level because the device associated with a transaction is an attribute of the activity record rather than the customer or wallet.

**Result: ✅ Normalized entity boundary.**

---

# 5. Reference-Attribute Duplication in `ANANSE_TRANSACTION`

The physical deployment intentionally retains both reference identifiers and corresponding descriptive attributes:

```text
transaction_type_id
transaction_type

transaction_status_id
transaction_status

transaction_channel_id
transaction_channel

currency_id
currency
```

This requires an explicit normalization qualification.

From a strict normalized relational perspective, the descriptive values could be derived through the corresponding reference tables.

For example:

```text
transaction_type_id
        ↓
ref.transaction_type
```

could supply the transaction type description without requiring a second transaction-level descriptive value.

However, the approved physical deployment deliberately retains these descriptive attributes as part of the deployed transaction representation.

Therefore the correct architectural classification is:

> **Deliberate physical redundancy retained for source representation and analytical usability.**

It is **not** evidence that the entity boundaries themselves are incorrectly designed.

Accordingly, the model should not be described as a mathematically pure 3NF implementation at the physical column level.

The logical model remains 3NF-oriented, while the physical deployment contains a documented source-compatible redundancy.

**Result: ⚠️ Intentional physical redundancy — accepted and locked.**

---

# 6. SikaCredit Normalization Review

## 6.1 `SIKACREDIT_CUSTOMER`

```text
PK:
customer_id
```

Customer-level attributes depend on the SikaCredit customer identifier.

Loan and repayment attributes are not stored in the customer entity.

**Result: ✅ Normalized.**

---

## 6.2 `SIKACREDIT_LOAN`

```text
PK:
loan_id

FK:
customer_id
```

Loan-level attributes remain at loan grain:

```text
disbursement_timestamp
disbursement_location
maturity_date
principal_amount
interest_rate
currency
```

The customer relationship is represented through:

```text
customer_id
```

rather than by duplicating customer attributes.

No currency reference FK is introduced because none exists in the approved physical deployment.

**Result: ✅ Normalized.**

---

## 6.3 `SIKACREDIT_REPAYMENT`

```text
PK:
repayment_id

FK:
loan_id
```

Each repayment is represented as an independent record.

This eliminates repeating groups such as:

```text
repayment_1_amount
repayment_1_timestamp

repayment_2_amount
repayment_2_timestamp

repayment_3_amount
repayment_3_timestamp
```

The model therefore supports an arbitrary number of repayments per loan.

**Result: ✅ Normalized.**

---

# 7. Oman Remit Normalization Review

## 7.1 `OMAN_REMIT_CUSTOMER`

```text
PK:
customer_id
```

Customer-level attributes remain within the Oman Remit customer entity.

Remittance-level attributes are not embedded within the customer record.

**Result: ✅ Normalized.**

---

## 7.2 `OMAN_REMIT_REMITTANCE`

```text
PK:
remittance_id

FKs:
customer_id
country_id
```

The remittance entity represents one remittance activity.

The customer relationship is established through:

```text
customer_id
        ↓
oman_remit.customer.customer_id
```

The country reference relationship is established through:

```text
country_id
        ↓
ref.country.country_id
```

The physical deployment also retains:

```text
origin_country
destination_country
currency
transaction_channel
remittance_status
```

as remittance-level attributes.

These remain at the remittance grain and are not repeated customer attributes.

**Result: ✅ Normalized entity boundary, with deliberate physical descriptive attributes retained.**

---

# 8. Repeating-Group Review

No repeating groups are embedded within the current relational entities.

The strongest example is SikaCredit repayment activity.

The model uses:

```text
SIKACREDIT_LOAN
        │
        └── SIKACREDIT_REPAYMENT
```

rather than embedding multiple repayment columns within the loan.

Likewise:

```text
ANANSE_CUSTOMER
        │
        └── ANANSE_WALLET
                │
                └── ANANSE_TRANSACTION
```

represents customer, wallet, and transaction activity at their respective grains.

**Result: ✅ No repeating groups identified.**

---

# 9. Foreign-Key Normalization Review

The physical deployment contains **12 authoritative foreign-key relationships**.

These relationships are structurally consistent with the logical entity boundaries.

| #  | Child Entity            | FK Attribute             | Parent Entity             | Parent Key               |
| -- | ----------------------- | ------------------------ | ------------------------- | ------------------------ |
| 1  | `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id`        | `OCB_CUSTOMER`            | `ocb_customer_id`        |
| 2  | `ANANSE_TRANSACTION`    | `customer_id`            | `ANANSE_CUSTOMER`         | `customer_id`            |
| 3  | `ANANSE_WALLET`         | `customer_id`            | `ANANSE_CUSTOMER`         | `customer_id`            |
| 4  | `ANANSE_TRANSACTION`    | `wallet_id`              | `ANANSE_WALLET`           | `wallet_id`              |
| 5  | `ANANSE_TRANSACTION`    | `transaction_type_id`    | `REF_TRANSACTION_TYPE`    | `transaction_type_id`    |
| 6  | `ANANSE_TRANSACTION`    | `transaction_status_id`  | `REF_TRANSACTION_STATUS`  | `transaction_status_id`  |
| 7  | `ANANSE_TRANSACTION`    | `transaction_channel_id` | `REF_TRANSACTION_CHANNEL` | `transaction_channel_id` |
| 8  | `ANANSE_TRANSACTION`    | `currency_id`            | `REF_CURRENCY`            | `currency_id`            |
| 9  | `SIKACREDIT_LOAN`       | `customer_id`            | `SIKACREDIT_CUSTOMER`     | `customer_id`            |
| 10 | `SIKACREDIT_REPAYMENT`  | `loan_id`                | `SIKACREDIT_LOAN`         | `loan_id`                |
| 11 | `OMAN_REMIT_REMITTANCE` | `customer_id`            | `OMAN_REMIT_CUSTOMER`     | `customer_id`            |
| 12 | `OMAN_REMIT_REMITTANCE` | `country_id`             | `REF_COUNTRY`             | `country_id`             |

**Total: 12 authoritative foreign-key relationships.**

These relationships do not introduce repeating groups or inappropriate entity coupling.

**Result: ✅ Structurally normalized relationships.**

---

# 10. Institutional Customer Attribute Duplication

The existence of similarly named attributes across institutional customer entities is intentional.

For example:

```text
ANANSE_CUSTOMER.first_name

SIKACREDIT_CUSTOMER.first_name

OMAN_REMIT_CUSTOMER.first_name
```

does not represent duplicate attributes within a single entity.

Each belongs to a separate institutional source domain.

The entities represent:

```text
ANANSE customer
SIKACREDIT customer
OMAN_REMIT customer
```

rather than a single consolidated operational customer record.

Therefore these attributes remain institution-owned.

**Result: ✅ Intentional cross-domain duplication — accepted.**

---

# 11. Cross-Institutional Identity Normalization

The model does not place:

```text
ocb_customer_id
```

directly into the institutional customer entities.

Instead:

```text
OCB_CUSTOMER
      │
      │ 1 : 0..N
      ▼
OCB_CUSTOMER_IDENTITY
      │
      ├── ANANSE customer identity
      ├── SIKACREDIT customer identity
      └── OMAN_REMIT customer identity
```

This preserves the distinction between:

* institutional customer identity; and
* OCB-resolved identity.

It also prevents the OCB customer entity from becoming a duplicate of the institutional customer tables.

**Result: ✅ Normalized identity boundary.**

---

# 12. Historical and Transactional Grain

The model preserves the independent grain of each financial object.

```text
Customer
    ↓
Wallet
    ↓
Transaction
```

and:

```text
Customer
    ↓
Loan
    ↓
Repayment
```

and:

```text
Customer
    ↓
Remittance
```

This prevents activity-level attributes from being stored at customer grain and prevents multiple activities from being collapsed into a single record.

The model therefore supports historical activity analysis without requiring the customer record to represent the state of every historical transaction.

**Result: ✅ Grain preserved.**

---

# 13. Deliberate Physical Redundancy

The normalization review identifies one important deliberate physical characteristic.

The approved deployment retains descriptive attributes alongside reference identifiers where required by the physical source representation.

The principal example is:

```text
ANANSE_TRANSACTION
```

which contains:

```text
transaction_type_id
transaction_type

transaction_status_id
transaction_status

transaction_channel_id
transaction_channel

currency_id
currency
```

Similarly, Oman Remit retains:

```text
country_id
origin_country
destination_country
```

This is treated as **controlled physical redundancy**, not as a failure to define proper entity boundaries.

The redundancy must not be expanded arbitrarily.

No additional duplicate attributes should be introduced merely for convenience without an explicit architectural decision.

---

# 14. Normalization Assessment

| Entity                  | Assessment                                                                |
| ----------------------- | ------------------------------------------------------------------------- |
| `OCB_CUSTOMER`          | ✅ Normalized                                                              |
| `OCB_CUSTOMER_IDENTITY` | ✅ Normalized                                                              |
| `ANANSE_CUSTOMER`       | ✅ Normalized                                                              |
| `ANANSE_WALLET`         | ✅ Normalized                                                              |
| `ANANSE_TRANSACTION`    | ⚠️ Normalized entity boundary; deliberate physical descriptive redundancy |
| `SIKACREDIT_CUSTOMER`   | ✅ Normalized                                                              |
| `SIKACREDIT_LOAN`       | ✅ Normalized                                                              |
| `SIKACREDIT_REPAYMENT`  | ✅ Normalized                                                              |
| `OMAN_REMIT_CUSTOMER`   | ✅ Normalized                                                              |
| `OMAN_REMIT_REMITTANCE` | ⚠️ Normalized entity boundary; deliberate physical descriptive redundancy |

---

# 15. Overall Normalization Conclusion

The logical model satisfies the intended **3NF-oriented entity-design standard**.

Specifically, it:

* maintains coherent entity boundaries;
* preserves entity grain;
* separates customers from activities;
* separates wallets from transactions;
* separates loans from repayments;
* eliminates repeating groups;
* maintains institutional ownership of source attributes;
* uses explicit foreign-key relationships;
* incorporates all **12 authoritative physical FK relationships**;
* maintains a dedicated OCB identity-resolution boundary;
* avoids unnecessary cross-institutional foreign keys.

The model does, however, contain **deliberate physical redundancy** in certain deployed source representations.

Therefore the technically accurate conclusion is:

> **The logical model is 3NF-oriented and structurally normalized, while the approved physical deployment intentionally retains selected descriptive attributes alongside reference identifiers for source compatibility and analytical usability.**

It would be incorrect to describe the deployed physical tables as a completely pure 3NF implementation.

---

# 16. Normalization Changes Required

No entity restructuring is required.

No primary-key changes are required.

No foreign-key changes are required.

No cardinality changes are required.

No repeating-group remediation is required.

The identified physical redundancy is deliberate and accepted under the approved deployment design.

Any future removal of these duplicated descriptive attributes would constitute a **physical-schema change**, not a correction to the logical entity model, and would require explicit architectural review.

---

# 17. Final Decision

The normalization review confirms that the corrected WP-2.2 logical model:

* maintains clear entity boundaries;
* preserves business grain;
* avoids repeating groups;
* separates customers from activities;
* separates wallets from transactions;
* separates loans from repayments;
* preserves source ownership;
* maintains OCB identity resolution separately from institutional customer records;
* incorporates the **12 authoritative foreign-key relationships**;
* introduces no unintended entity-level denormalization.

Selected descriptive/reference redundancy remains intentionally present in the physical deployment and is explicitly accepted as a controlled physical-design decision.

**No logical-model normalization changes are required at this stage.**

**WP-2.2-T06 — REVISED, RECONCILED AND LOCKED.**
