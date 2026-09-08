# WP-2.2-T02 — Define Attributes

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T02
**Status:** **REVISED / RECONCILED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the attributes belonging to each relational entity established in **WP-2.2-T01**.

The attribute model is reconciled with the **approved WP-2.4 physical table deployment**.

Attributes remain at the grain of the entity that owns them.

Institutional customer attributes remain institution-owned. OCB does not automatically duplicate or consolidate those attributes into `OCB_CUSTOMER`.

Where an attribute exists to establish a relational foreign-key relationship, that attribute is explicitly identified as an FK attribute.

The logical model therefore distinguishes:

* primary identifiers;
* foreign-key identifiers;
* institutional and business attributes;
* descriptive attributes associated with reference identifiers.

---

# 2. OCB Attributes

## 2.1 `OCB_CUSTOMER`

`OCB_CUSTOMER` represents OCB's resolved cross-institutional identity.

It does not duplicate institutional demographic attributes.

| Attribute         | Role               | Status  |
| ----------------- | ------------------ | ------- |
| `ocb_customer_id` | Primary identifier | 🔒 LOCK |

`ocb_customer_id` is the primary key of `ocb.customer`.

It is generated independently of the institutional customer identifiers.

---

## 2.2 `OCB_CUSTOMER_IDENTITY`

`OCB_CUSTOMER_IDENTITY` represents the mapping between an institutional customer identity and the OCB-resolved identity.

| Attribute            | Role                                         | Status  |
| -------------------- | -------------------------------------------- | ------- |
| `ocb_customer_id`    | Foreign key → `ocb.customer.ocb_customer_id` | 🔒 LOCK |
| `source_entity`      | Source-system identifier                     | 🔒 LOCK |
| `source_customer_id` | Institutional customer identifier            | 🔒 LOCK |
| `created_at`         | Mapping creation timestamp                   | 🔒 LOCK |

The source identity is identified by:

```text
(source_entity, source_customer_id)
```

The composite key remains the primary key of `ocb.customer_identity`.

The relationship is:

```text
ocb.customer
      │
      │ ocb_customer_id
      ▼
ocb.customer_identity
```

No additional identity-resolution attributes such as resolution confidence or resolution method are introduced.

---

# 3. Ananse Attributes

## 3.1 `ANANSE_CUSTOMER`

Represents the customer record maintained by Ananse.

| Attribute       | Role                        | Status  |
| --------------- | --------------------------- | ------- |
| `customer_id`   | Primary identifier          | 🔒 LOCK |
| `first_name`    | Customer attribute          | 🔒 LOCK |
| `last_name`     | Customer attribute          | 🔒 LOCK |
| `date_of_birth` | Customer attribute          | 🔒 LOCK |
| `nationality`   | Customer attribute          | 🔒 LOCK |
| `occupation`    | Customer attribute          | 🔒 LOCK |
| `phone_number`  | Customer attribute          | 🔒 LOCK |
| `email`         | Customer attribute          | 🔒 LOCK |
| `created_at`    | Customer creation timestamp | 🔒 LOCK |

Customer-level attributes remain within the Ananse customer entity.

---

## 3.2 `ANANSE_WALLET`

Represents an Ananse wallet belonging to an Ananse customer.

| Attribute     | Role                                        | Status  |
| ------------- | ------------------------------------------- | ------- |
| `wallet_id`   | Primary identifier                          | 🔒 LOCK |
| `customer_id` | Foreign key → `ananse.customer.customer_id` | 🔒 LOCK |

The wallet is explicitly associated with its owning Ananse customer.

The relationship is:

```text
ANANSE_CUSTOMER
      │
      │ customer_id
      ▼
ANANSE_WALLET
      │
      │ wallet_id
      ▼
ANANSE_TRANSACTION
```

The wallet remains a distinct financial object from the customer and from individual transactions.

---

## 3.3 `ANANSE_TRANSACTION`

Represents an individual Ananse transaction/activity.

| Attribute                | Role                                                           | Status  |
| ------------------------ | -------------------------------------------------------------- | ------- |
| `transaction_id`         | Primary identifier                                             | 🔒 LOCK |
| `customer_id`            | Foreign key → `ananse.customer.customer_id`                    | 🔒 LOCK |
| `wallet_id`              | Foreign key → `wallet.wallet.wallet_id`                        | 🔒 LOCK |
| `transaction_type_id`    | Foreign key → `ref.transaction_type.transaction_type_id`       | 🔒 LOCK |
| `transaction_status_id`  | Foreign key → `ref.transaction_status.transaction_status_id`   | 🔒 LOCK |
| `transaction_channel_id` | Foreign key → `ref.transaction_channel.transaction_channel_id` | 🔒 LOCK |
| `currency_id`            | Foreign key → `ref.currency.currency_id`                       | 🔒 LOCK |
| `transaction_type`       | Transaction business/descriptive attribute                     | 🔒 LOCK |
| `transaction_status`     | Transaction business/descriptive attribute                     | 🔒 LOCK |
| `transaction_timestamp`  | Transaction timestamp                                          | 🔒 LOCK |
| `transaction_location`   | Transaction location                                           | 🔒 LOCK |
| `transaction_channel`    | Transaction business/descriptive attribute                     | 🔒 LOCK |
| `device_id`              | Device identifier                                              | 🔒 LOCK |
| `amount`                 | Transaction amount                                             | 🔒 LOCK |
| `currency`               | Transaction currency/business attribute                        | 🔒 LOCK |

The transaction therefore contains both:

1. relational reference identifiers used to establish controlled relationships with reference tables; and
2. the corresponding descriptive/business attributes physically defined on the transaction table.

The relational reference attributes are:

```text
transaction_type_id
transaction_status_id
transaction_channel_id
currency_id
```

The corresponding descriptive/business attributes are:

```text
transaction_type
transaction_status
transaction_channel
currency
```

`device_id` remains part of the transaction because device-level information is required for transaction intelligence and anomaly analysis.

The transaction has explicit relationships to both its institutional customer and its wallet.

---

# 4. SikaCredit Attributes

## 4.1 `SIKACREDIT_CUSTOMER`

Represents the customer record maintained by SikaCredit.

| Attribute       | Role                        | Status  |
| --------------- | --------------------------- | ------- |
| `customer_id`   | Primary identifier          | 🔒 LOCK |
| `first_name`    | Customer attribute          | 🔒 LOCK |
| `last_name`     | Customer attribute          | 🔒 LOCK |
| `date_of_birth` | Customer attribute          | 🔒 LOCK |
| `nationality`   | Customer attribute          | 🔒 LOCK |
| `occupation`    | Customer attribute          | 🔒 LOCK |
| `phone_number`  | Customer attribute          | 🔒 LOCK |
| `email`         | Customer attribute          | 🔒 LOCK |
| `created_at`    | Customer creation timestamp | 🔒 LOCK |

No separate customer `status` attribute is introduced.

---

## 4.2 `SIKACREDIT_LOAN`

Represents a loan issued by SikaCredit.

| Attribute                | Role                                            | Status  |
| ------------------------ | ----------------------------------------------- | ------- |
| `loan_id`                | Primary identifier                              | 🔒 LOCK |
| `customer_id`            | Foreign key → `sikacredit.customer.customer_id` | 🔒 LOCK |
| `disbursement_timestamp` | Loan disbursement timestamp                     | 🔒 LOCK |
| `disbursement_location`  | Loan disbursement location                      | 🔒 LOCK |
| `maturity_date`          | Loan maturity date                              | 🔒 LOCK |
| `principal_amount`       | Principal amount                                | 🔒 LOCK |
| `interest_rate`          | Interest rate                                   | 🔒 LOCK |
| `currency`               | Loan currency                                   | 🔒 LOCK |

The loan represents the lending relationship and associated loan-level financial attributes.

No currency reference FK is introduced because no such FK exists in the approved physical deployment.

---

## 4.3 `SIKACREDIT_REPAYMENT`

Represents an individual repayment against a SikaCredit loan.

| Attribute             | Role                                    | Status  |
| --------------------- | --------------------------------------- | ------- |
| `repayment_id`        | Primary identifier                      | 🔒 LOCK |
| `loan_id`             | Foreign key → `sikacredit.loan.loan_id` | 🔒 LOCK |
| `repayment_amount`    | Repayment amount                        | 🔒 LOCK |
| `repayment_timestamp` | Repayment timestamp                     | 🔒 LOCK |
| `repayment_location`  | Repayment location                      | 🔒 LOCK |

Repayments are represented as separate records because one loan may have multiple repayments.

---

# 5. Oman Remit Attributes

## 5.1 `OMAN_REMIT_CUSTOMER`

Represents the customer record maintained by Oman Remit.

| Attribute       | Role                        | Status  |
| --------------- | --------------------------- | ------- |
| `customer_id`   | Primary identifier          | 🔒 LOCK |
| `first_name`    | Customer attribute          | 🔒 LOCK |
| `last_name`     | Customer attribute          | 🔒 LOCK |
| `date_of_birth` | Customer attribute          | 🔒 LOCK |
| `nationality`   | Customer attribute          | 🔒 LOCK |
| `occupation`    | Customer attribute          | 🔒 LOCK |
| `phone_number`  | Customer attribute          | 🔒 LOCK |
| `email`         | Customer attribute          | 🔒 LOCK |
| `created_at`    | Customer creation timestamp | 🔒 LOCK |

No customer `status` attribute is maintained.

---

## 5.2 `OMAN_REMIT_REMITTANCE`

Represents an individual Oman Remit remittance activity.

| Attribute              | Role                                            | Status  |
| ---------------------- | ----------------------------------------------- | ------- |
| `remittance_id`        | Primary identifier                              | 🔒 LOCK |
| `customer_id`          | Foreign key → `oman_remit.customer.customer_id` | 🔒 LOCK |
| `country_id`           | Foreign key → `ref.country.country_id`          | 🔒 LOCK |
| `remittance_status`    | Remittance status                               | 🔒 LOCK |
| `remittance_timestamp` | Remittance timestamp                            | 🔒 LOCK |
| `transaction_location` | Transaction location                            | 🔒 LOCK |
| `amount`               | Remittance amount                               | 🔒 LOCK |
| `currency`             | Remittance currency                             | 🔒 LOCK |
| `origin_country`       | Origin-country attribute                        | 🔒 LOCK |
| `destination_country`  | Destination-country attribute                   | 🔒 LOCK |
| `transaction_channel`  | Transaction channel                             | 🔒 LOCK |

`country_id` is included because the physical deployment establishes a foreign-key relationship from `oman_remit.remittance` to `ref.country`.

The existing:

```text
origin_country
destination_country
```

attributes remain part of the physical source representation.

No separate sender customer identifier, receiver identifier, counterparty reference, or remittance type is introduced.

---

# 6. Complete Attribute Register

| Entity                  | Attributes                                                                                                                                                                                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `OCB_CUSTOMER`          | `ocb_customer_id`                                                                                                                                                                                                                                                                          |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id`, `source_entity`, `source_customer_id`, `created_at`                                                                                                                                                                                                                     |
| `ANANSE_CUSTOMER`       | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                                                                                                              |
| `ANANSE_WALLET`         | `wallet_id`, `customer_id`                                                                                                                                                                                                                                                                 |
| `ANANSE_TRANSACTION`    | `transaction_id`, `customer_id`, `wallet_id`, `transaction_type_id`, `transaction_status_id`, `transaction_channel_id`, `currency_id`, `transaction_type`, `transaction_status`, `transaction_timestamp`, `transaction_location`, `transaction_channel`, `device_id`, `amount`, `currency` |
| `SIKACREDIT_CUSTOMER`   | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                                                                                                              |
| `SIKACREDIT_LOAN`       | `loan_id`, `customer_id`, `disbursement_timestamp`, `disbursement_location`, `maturity_date`, `principal_amount`, `interest_rate`, `currency`                                                                                                                                              |
| `SIKACREDIT_REPAYMENT`  | `repayment_id`, `loan_id`, `repayment_amount`, `repayment_timestamp`, `repayment_location`                                                                                                                                                                                                 |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                                                                                                              |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`, `customer_id`, `country_id`, `remittance_status`, `remittance_timestamp`, `transaction_location`, `amount`, `currency`, `origin_country`, `destination_country`, `transaction_channel`                                                                                    |

---

# 7. Primary-Key Register

The authoritative primary keys are:

| Entity                  | Primary Key                           |
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

# 8. Foreign-Key Register

The authoritative physical foreign-key relationships are:

|  # | Child Entity            | FK Attribute             | Parent Entity             | Parent Attribute         |
| -: | ----------------------- | ------------------------ | ------------------------- | ------------------------ |
|  1 | `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id`        | `OCB_CUSTOMER`            | `ocb_customer_id`        |
|  2 | `ANANSE_WALLET`         | `customer_id`            | `ANANSE_CUSTOMER`         | `customer_id`            |
|  3 | `ANANSE_TRANSACTION`    | `customer_id`            | `ANANSE_CUSTOMER`         | `customer_id`            |
|  4 | `ANANSE_TRANSACTION`    | `wallet_id`              | `ANANSE_WALLET`           | `wallet_id`              |
|  5 | `ANANSE_TRANSACTION`    | `transaction_type_id`    | `REF_TRANSACTION_TYPE`    | `transaction_type_id`    |
|  6 | `ANANSE_TRANSACTION`    | `transaction_status_id`  | `REF_TRANSACTION_STATUS`  | `transaction_status_id`  |
|  7 | `ANANSE_TRANSACTION`    | `transaction_channel_id` | `REF_TRANSACTION_CHANNEL` | `transaction_channel_id` |
|  8 | `ANANSE_TRANSACTION`    | `currency_id`            | `REF_CURRENCY`            | `currency_id`            |
|  9 | `SIKACREDIT_LOAN`       | `customer_id`            | `SIKACREDIT_CUSTOMER`     | `customer_id`            |
| 10 | `SIKACREDIT_REPAYMENT`  | `loan_id`                | `SIKACREDIT_LOAN`         | `loan_id`                |
| 11 | `OMAN_REMIT_REMITTANCE` | `customer_id`            | `OMAN_REMIT_CUSTOMER`     | `customer_id`            |
| 12 | `OMAN_REMIT_REMITTANCE` | `country_id`             | `REF_COUNTRY`             | `country_id`             |

**Total authoritative foreign-key relationships: 12.**

---

# 9. Attribute Ownership Principle

Institutional attributes remain owned by their respective source entities.

```text
ANANSE_CUSTOMER
        │
        └── Ananse-owned customer attributes

SIKACREDIT_CUSTOMER
        │
        └── SikaCredit-owned customer attributes

OMAN_REMIT_CUSTOMER
        │
        └── Oman Remit-owned customer attributes
```

OCB's identity layer does not replace these institutional identities.

The existence of `ocb_customer_id` does not transfer ownership of institutional attributes to OCB.

Where OCB requires derived analytical attributes, these may be produced downstream without altering source ownership.

---

# 10. Reference-Identifier Principle

Reference identifiers are relational attributes used to establish controlled relationships with reference entities.

For Ananse transactions:

```text
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

For Oman Remit:

```text
country_id
        ↓
ref.country
```

The physical model also retains the corresponding descriptive/business attributes where defined.

This ticket records the physical implementation as deployed.

It does not independently redesign the reference model or remove the descriptive attributes.

Any future normalization of these attributes requires an explicit architectural decision.

---

# 11. Entity Relationship Attribute Boundary

The principal FK relationships are represented as follows:

```text
OCB_CUSTOMER
      │
      │ ocb_customer_id
      ▼
OCB_CUSTOMER_IDENTITY
```

```text
ANANSE_CUSTOMER
      │
      │ customer_id
      ▼
ANANSE_WALLET
      │
      │ wallet_id
      ▼
ANANSE_TRANSACTION
```

The transaction also retains a direct customer relationship:

```text
ANANSE_CUSTOMER
      │
      │ customer_id
      ▼
ANANSE_TRANSACTION
```

Thus both the transaction's customer relationship and wallet relationship are explicit in the physical model.

For SikaCredit:

```text
SIKACREDIT_CUSTOMER
        │
        │ customer_id
        ▼
SIKACREDIT_LOAN
        │
        │ loan_id
        ▼
SIKACREDIT_REPAYMENT
```

For Oman Remit:

```text
OMAN_REMIT_CUSTOMER
        │
        │ customer_id
        ▼
OMAN_REMIT_REMITTANCE
        │
        │ country_id
        ▼
REF_COUNTRY
```

---

# 12. Excluded Attributes

The following remain intentionally outside the locked model.

### OCB

* consolidated demographic attributes;
* resolution confidence;
* resolution method.

### Ananse

* wallet type;
* customer status.

### SikaCredit

* loan type;
* loan purpose;
* application timestamp;
* approval timestamp;
* unnecessary effective-from/effective-to fields;
* currency reference FK not present in the approved physical deployment.

### Oman Remit

* customer status;
* sender customer ID;
* receiver ID;
* counterparty reference;
* separate remittance type.

These exclusions remain deliberate design decisions.

---

# 13. Reconciliation With WP-2.4 Physical Deployment

This revision explicitly reconciles WP-2.2-T02 with the current physical database structure.

The following attributes are recognized as physical foreign-key attributes:

```text
OCB_CUSTOMER_IDENTITY.ocb_customer_id

ANANSE_WALLET.customer_id

ANANSE_TRANSACTION.customer_id
ANANSE_TRANSACTION.wallet_id
ANANSE_TRANSACTION.transaction_type_id
ANANSE_TRANSACTION.transaction_status_id
ANANSE_TRANSACTION.transaction_channel_id
ANANSE_TRANSACTION.currency_id

SIKACREDIT_LOAN.customer_id
SIKACREDIT_REPAYMENT.loan_id

OMAN_REMIT_REMITTANCE.customer_id
OMAN_REMIT_REMITTANCE.country_id
```

No new entity is introduced by this reconciliation.

No existing entity is removed.

No institutional customer identity is replaced by the OCB identity.

The logical attribute model is therefore aligned to the **12-FK physical relational structure**.

---

# 14. Final Decision

The attribute set defined in this document is the authoritative logical attribute baseline for the relational entities established in **WP-2.2-T01**.

It is reconciled with the **WP-2.4 physical table deployment**, including its implemented primary-key and foreign-key structure.

`device_id` remains explicitly included in `ANANSE_TRANSACTION`.

`ANANSE_WALLET.customer_id` is explicitly included as the wallet-to-customer FK.

The Ananse transaction reference identifiers and Oman Remit `country_id` are explicitly included as physical FK attributes.

No additional attributes are implied beyond those documented here.

All subsequent WP-2.2 tickets must use this reconciled attribute register unless an explicit architectural decision reopens the model.

**WP-2.2-T02 — REVISED, RECONCILED AND LOCKED.**
