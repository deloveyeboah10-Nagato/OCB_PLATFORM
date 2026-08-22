# WP-2.2-T02 — Define Attributes

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T02
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the attributes belonging to each relational entity established in **WP-2.2-T01**.

Attributes remain at the grain of the entity that owns them.

Institutional customer attributes remain institution-owned. OCB does not automatically duplicate or consolidate those attributes into `OCB_CUSTOMER`.

---

# 2. OCB Attributes

## 2.1 `OCB_CUSTOMER`

`OCB_CUSTOMER` represents OCB's resolved cross-institutional identity.

| Attribute         | Status  |
| ----------------- | ------- |
| `ocb_customer_id` | 🔒 LOCK |

No institutional demographic attributes are duplicated into this entity.

OCB may derive consolidated or analytical attributes downstream where required.

---

## 2.2 `OCB_CUSTOMER_IDENTITY`

`OCB_CUSTOMER_IDENTITY` represents the mapping between an institutional customer identity and the OCB-resolved identity.

| Attribute            | Status  |
| -------------------- | ------- |
| `ocb_customer_id`    | 🔒 LOCK |
| `source_entity`      | 🔒 LOCK |
| `source_customer_id` | 🔒 LOCK |

The source identity is identified by the combination:

```text
(source_entity, source_customer_id)
```

No additional identity-resolution attributes such as resolution confidence or resolution method are introduced at this stage.

---

# 3. Ananse Attributes

## 3.1 `ANANSE_CUSTOMER`

Represents the customer record maintained by Ananse.

| Attribute       | Status  |
| --------------- | ------- |
| `customer_id`   | 🔒 LOCK |
| `first_name`    | 🔒 LOCK |
| `last_name`     | 🔒 LOCK |
| `date_of_birth` | 🔒 LOCK |
| `nationality`   | 🔒 LOCK |
| `occupation`    | 🔒 LOCK |
| `phone_number`  | 🔒 LOCK |
| `email`         | 🔒 LOCK |
| `created_at`    | 🔒 LOCK |

Customer-level attributes remain within the customer entity.

---

## 3.2 `ANANSE_WALLET`

Represents an Ananse wallet.

| Attribute   | Status  |
| ----------- | ------- |
| `wallet_id` | 🔒 LOCK |

The wallet remains a distinct object from both the customer and transaction.

---

## 3.3 `ANANSE_TRANSACTION`

Represents an individual Ananse transaction/activity.

| Attribute               | Status                 |
| ----------------------- | ---------------------- |
| `transaction_id`        | 🔒 LOCK                |
| `customer_id`           | 🔒 LOCK                |
| `wallet_id`             | 🔒 LOCK                |
| `transaction_type`      | 🔒 LOCK                |
| `transaction_status`    | 🔒 LOCK                |
| `transaction_timestamp` | 🔒 LOCK                |
| `transaction_location`  | 🔒 LOCK                |
| `transaction_channel`   | 🔒 LOCK                |
| `device_id`             | 🔒 **RESTORED / LOCK** |
| `amount`                | 🔒 LOCK                |
| `currency`              | 🔒 LOCK                |

`device_id` is explicitly included because device-level information is relevant to transaction intelligence and anomaly analysis.

Its omission from the previous version of T02 was an error and is corrected here.

---

# 4. SikaCredit Attributes

## 4.1 `SIKACREDIT_CUSTOMER`

Represents the customer record maintained by SikaCredit.

| Attribute       | Status  |
| --------------- | ------- |
| `customer_id`   | 🔒 LOCK |
| `first_name`    | 🔒 LOCK |
| `last_name`     | 🔒 LOCK |
| `date_of_birth` | 🔒 LOCK |
| `nationality`   | 🔒 LOCK |
| `occupation`    | 🔒 LOCK |
| `phone_number`  | 🔒 LOCK |
| `email`         | 🔒 LOCK |
| `created_at`    | 🔒 LOCK |

No separate customer `status` attribute is introduced.

Customer status can be inferred later from relevant institutional activity where required.

---

## 4.2 `SIKACREDIT_LOAN`

Represents a loan issued by SikaCredit.

| Attribute                | Status  |
| ------------------------ | ------- |
| `loan_id`                | 🔒 LOCK |
| `customer_id`            | 🔒 LOCK |
| `disbursement_timestamp` | 🔒 LOCK |
| `disbursement_location`  | 🔒 LOCK |
| `maturity_date`          | 🔒 LOCK |
| `principal_amount`       | 🔒 LOCK |
| `interest_rate`          | 🔒 LOCK |
| `currency`               | 🔒 LOCK |

The model intentionally excludes:

* `loan_type`;
* application timestamp;
* approval timestamp;
* loan purpose;
* unnecessary effective-from/effective-to attributes.

---

## 4.3 `SIKACREDIT_REPAYMENT`

Represents an individual repayment against a SikaCredit loan.

| Attribute             | Status  |
| --------------------- | ------- |
| `repayment_id`        | 🔒 LOCK |
| `loan_id`             | 🔒 LOCK |
| `repayment_amount`    | 🔒 LOCK |
| `repayment_timestamp` | 🔒 LOCK |
| `repayment_location`  | 🔒 LOCK |

Repayments are represented as separate records because one loan may have multiple repayments.

---

# 5. Oman Remit Attributes

## 5.1 `OMAN_REMIT_CUSTOMER`

Represents the customer record maintained by Oman Remit.

| Attribute       | Status  |
| --------------- | ------- |
| `customer_id`   | 🔒 LOCK |
| `first_name`    | 🔒 LOCK |
| `last_name`     | 🔒 LOCK |
| `date_of_birth` | 🔒 LOCK |
| `nationality`   | 🔒 LOCK |
| `occupation`    | 🔒 LOCK |
| `phone_number`  | 🔒 LOCK |
| `email`         | 🔒 LOCK |
| `created_at`    | 🔒 LOCK |

No customer `status` attribute is maintained.

---

## 5.2 `OMAN_REMIT_REMITTANCE`

Represents an individual Oman Remit remittance activity.

| Attribute              | Status  |
| ---------------------- | ------- |
| `remittance_id`        | 🔒 LOCK |
| `customer_id`          | 🔒 LOCK |
| `remittance_status`    | 🔒 LOCK |
| `remittance_timestamp` | 🔒 LOCK |
| `transaction_location` | 🔒 LOCK |
| `amount`               | 🔒 LOCK |
| `currency`             | 🔒 LOCK |
| `origin_country`       | 🔒 LOCK |
| `destination_country`  | 🔒 LOCK |
| `transaction_channel`  | 🔒 LOCK |

The following are intentionally excluded:

* `sender_customer_id`;
* receiver identifier;
* `counterparty_reference`;
* separate `remittance_type`.

`customer_id` already identifies the Oman Remit customer associated with the remittance.

---

# 6. Complete Attribute Register

| Entity                  | Attributes                                                                                                                                                                                        |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `OCB_CUSTOMER`          | `ocb_customer_id`                                                                                                                                                                                 |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id`, `source_entity`, `source_customer_id`                                                                                                                                          |
| `ANANSE_CUSTOMER`       | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                     |
| `ANANSE_WALLET`         | `wallet_id`                                                                                                                                                                                       |
| `ANANSE_TRANSACTION`    | `transaction_id`, `customer_id`, `wallet_id`, `transaction_type`, `transaction_status`, `transaction_timestamp`, `transaction_location`, `transaction_channel`, `device_id`, `amount`, `currency` |
| `SIKACREDIT_CUSTOMER`   | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                     |
| `SIKACREDIT_LOAN`       | `loan_id`, `customer_id`, `disbursement_timestamp`, `disbursement_location`, `maturity_date`, `principal_amount`, `interest_rate`, `currency`                                                     |
| `SIKACREDIT_REPAYMENT`  | `repayment_id`, `loan_id`, `repayment_amount`, `repayment_timestamp`, `repayment_location`                                                                                                        |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`, `first_name`, `last_name`, `date_of_birth`, `nationality`, `occupation`, `phone_number`, `email`, `created_at`                                                                     |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`, `customer_id`, `remittance_status`, `remittance_timestamp`, `transaction_location`, `amount`, `currency`, `origin_country`, `destination_country`, `transaction_channel`         |

---

# 7. Attribute Ownership Principle

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

OCB's role is to resolve identities across these source identities.

Where OCB requires a derived demographic or analytical attribute, it may resolve the relevant institutional identities and apply its own derivation logic without altering source ownership.

---

# 8. Excluded Attributes

The following previously considered attributes are intentionally not part of the locked model:

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
* unnecessary effective-from/effective-to fields.

### Oman Remit

* customer status;
* sender customer ID;
* receiver ID;
* counterparty reference;
* separate remittance type.

These exclusions are deliberate design decisions.

---

# 9. Final Decision

The attribute set defined in this document is the authoritative attribute baseline for the relational entities established in **WP-2.2-T01**.

`device_id` is explicitly restored to `ANANSE_TRANSACTION`.

All subsequent WP-2.2 tickets must use this attribute register unless an explicit architectural decision reopens the model.

**WP-2.2-T02 — REVISED AND LOCKED.**
