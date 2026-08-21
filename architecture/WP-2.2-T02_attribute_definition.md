# WP-2.2-T02 — Attribute Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Operational Data Architecture
**Ticket:** WP-2.2-T02
**Status:** **COMPLETE**
**Decision Type:** Logical attribute definition

---

## 1. Purpose

WP-2.2-T02 defines the attributes required for the principal institutional objects within the OCB Platform's operational data architecture.

The objective is to establish a **minimal, semantically explicit attribute set** for OCB, Ananse, SikaCredit, and Oman Remit before relationships, cardinalities, physical tables, or implementation structures are defined.

The ticket does **not** define:

* physical database schemas;
* indexes;
* ETL implementation;
* analytical dimensions;
* derived intelligence measures;
* financial-consequence structures;
* ledger structures;
* wallet financial-state calculations;
* cross-institutional analytical joins.

Those are handled by subsequent design and implementation work.

---

# 2. Attribute Design Principles

The following principles govern the decisions in this ticket.

### 2.1 Source ownership

Institutional attributes remain with the institution that owns the underlying business record.

OCB therefore maintains its resolved identity rather than copying institutional customer profiles into the OCB identity object.

### 2.2 Minimum sufficient modelling

An attribute is included only where it has a defined business or analytical purpose.

Potentially useful real-world fields are not automatically included merely because they could exist in a production system.

### 2.3 Semantic precision

Where two attributes describe materially different activities, they are named separately rather than hidden behind a generic attribute.

For example:

```text
disbursement_location
repayment_location
```

is preferred to:

```text
transaction_location
```

for SikaCredit because the two locations describe different financial activities.

### 2.4 Avoid redundant identifiers

Identifiers are not duplicated when the existing institutional identifier already establishes the required relationship.

### 2.5 Derived relationships remain derivable

Relationships that can be established reliably through existing identifiers and joins do not need to be duplicated as source attributes.

### 2.6 Activity attributes must describe actual activities

Generic event attributes are not introduced merely because the institution produces events.

The model should represent the actual business activity and its meaningful attributes.

---

# 3. OCB Identity

OCB's role is to provide a **cross-institutional resolved identity**.

OCB does not own the underlying institutional customer profiles.

## 3.1 OCB Customer Identity

| Attribute            | Purpose                                                |
| -------------------- | ------------------------------------------------------ |
| `ocb_customer_id`    | Unique OCB-resolved identity                           |
| `source_entity`      | Institution owning the source identity                 |
| `source_customer_id` | Customer identifier assigned by the source institution |

The conceptual structure is:

```text
OCB_CUSTOMER_IDENTITY

ocb_customer_id
source_entity
source_customer_id
```

The OCB identity object therefore establishes the relationship between an OCB-resolved customer and the corresponding institutional customer identity.

### Explicitly excluded from OCB identity

The following are **not OCB-owned identity attributes**:

* `first_name`
* `last_name`
* `date_of_birth`
* `nationality`
* `occupation`
* `phone_number`
* `email`
* source-specific customer status
* source-specific creation timestamps

These remain institution-owned and may be incorporated into downstream analytical representations where required.

---

# 4. Ananse

Ananse represents the mobile-money institutional domain.

The attribute set combines the institution's customer and transaction information for the purpose of defining the institutional data boundary.

## 4.1 Ananse attributes

| Attribute               | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| `customer_id`           | Ananse customer identifier                     |
| `first_name`            | Customer first name                            |
| `last_name`             | Customer last name                             |
| `date_of_birth`         | Customer date of birth                         |
| `nationality`           | Customer nationality                           |
| `occupation`            | Customer occupation                            |
| `phone_number`          | Customer telephone identifier                  |
| `email`                 | Customer email                                 |
| `created_at`            | Customer creation timestamp                    |
| `status`                | Ananse customer status                         |
| `transaction_id`        | Unique Ananse transaction identifier           |
| `wallet_id`             | Wallet associated with the transaction         |
| `transaction_type`      | Type of transaction                            |
| `transaction_status`    | Transaction outcome/status                     |
| `transaction_timestamp` | Time of transaction                            |
| `transaction_location`  | Location associated with the transaction       |
| `transaction_channel`   | Channel through which the transaction occurred |
| `amount`                | Transaction monetary amount                    |
| `currency`              | Currency of transaction                        |

### Explicit exclusions

The following were considered and excluded:

* `wallet_type`
* `source_transaction_id`
* `counterparty_reference`

The wallet is a **separate object** and is not redefined by this ticket.

---

# 5. SikaCredit

SikaCredit represents the digital-lending institutional domain.

Its core financial object is the loan, with repayment represented separately because a single loan may have multiple repayments.

## 5.1 SikaCredit customer and loan attributes

| Attribute                | Purpose                               |
| ------------------------ | ------------------------------------- |
| `customer_id`            | SikaCredit customer identifier        |
| `first_name`             | Customer first name                   |
| `last_name`              | Customer last name                    |
| `date_of_birth`          | Customer date of birth                |
| `nationality`            | Customer nationality                  |
| `occupation`             | Customer occupation                   |
| `phone_number`           | Customer telephone identifier         |
| `email`                  | Customer email                        |
| `created_at`             | Customer creation timestamp           |
| `loan_id`                | Unique loan identifier                |
| `disbursement_timestamp` | Time the loan was disbursed           |
| `disbursement_location`  | Location where the loan was disbursed |
| `maturity_date`          | Contractual loan maturity date        |
| `principal_amount`       | Original principal amount             |
| `interest_rate`          | Applicable loan interest rate         |
| `currency`               | Currency of the loan                  |

## 5.2 SikaCredit repayment

Repayment is represented as a separate object because the relationship is naturally one-to-many:

```text
LOAN
  │
  └──────< REPAYMENT
```

### Repayment attributes

| Attribute             | Purpose                               |
| --------------------- | ------------------------------------- |
| `repayment_id`        | Unique repayment identifier           |
| `loan_id`             | Loan to which the repayment relates   |
| `repayment_amount`    | Amount paid in the repayment activity |
| `repayment_timestamp` | Time the repayment occurred           |
| `repayment_location`  | Location where the repayment was made |

This structure allows multiple repayment records to exist against a single loan without forcing multiple repayments into a single loan record.

### Explicit exclusions

The following were considered and excluded:

* `loan_type`
* `loan_status` as a separate attribute from customer `status`
* application timestamp
* approval timestamp
* loan purpose
* generic `loan_event_id`
* generic `event_type`
* generic `event_status`
* generic `event_timestamp`
* generic `amount`

The model uses the semantically specific loan and repayment attributes instead.

---

# 6. Oman Remit

Oman Remit represents the cross-border remittance institutional domain.

## 6.1 Oman Remit attributes

| Attribute              | Purpose                                             |
| ---------------------- | --------------------------------------------------- |
| `customer_id`          | Oman Remit customer identifier                      |
| `first_name`           | Customer first name                                 |
| `last_name`            | Customer last name                                  |
| `date_of_birth`        | Customer date of birth                              |
| `nationality`          | Customer nationality                                |
| `occupation`           | Customer occupation                                 |
| `phone_number`         | Customer telephone identifier                       |
| `email`                | Customer email                                      |
| `created_at`           | Customer creation timestamp                         |
| `remittance_id`        | Unique remittance identifier                        |
| `remittance_status`    | Status of the remittance                            |
| `remittance_timestamp` | Time of remittance activity                         |
| `transaction_location` | Location associated with the remittance transaction |
| `amount`               | Remittance monetary amount                          |
| `currency`             | Remittance currency                                 |
| `origin_country`       | Country from which the remittance originates        |
| `destination_country`  | Destination country                                 |
| `transaction_channel`  | Channel through which the remittance was conducted  |

### Explicit exclusions

The following were deliberately excluded:

* `status` for the Oman Remit customer
* `sender_customer_id`
* `receiver_customer_id`
* `remittance_type`
* `counterparty_reference`

The sender is already represented by the Oman Remit `customer_id` where the customer is the originating party.

The receiving relationship can subsequently be established through the institutional records and Ananse account/customer relationships rather than duplicating another identifier in Oman Remit.

Customer status can similarly be derived where required for analytical use.

---

# 7. Consolidated Attribute Inventory

The resulting institutional model is:

```text
                    OCB
                     │
          ocb_customer_id
          source_entity
          source_customer_id
                     │
        ┌────────────┼─────────────┐
        ▼            ▼             ▼
     ANANSE      SIKACREDIT     OMAN REMIT
```

### Ananse

```text
customer_id
first_name
last_name
date_of_birth
nationality
occupation
phone_number
email
created_at
status

transaction_id
wallet_id
transaction_type
transaction_status
transaction_timestamp
transaction_location
transaction_channel
amount
currency
```

### SikaCredit

```text
customer_id
first_name
last_name
date_of_birth
nationality
occupation
phone_number
email
created_at

loan_id
disbursement_timestamp
disbursement_location
maturity_date
principal_amount
interest_rate
currency
```

### SikaCredit Repayment

```text
repayment_id
loan_id
repayment_amount
repayment_timestamp
repayment_location
```

### Oman Remit

```text
customer_id
first_name
last_name
date_of_birth
nationality
occupation
phone_number
email
created_at

remittance_id
remittance_status
remittance_timestamp
transaction_location
amount
currency
origin_country
destination_country
transaction_channel
```

---

# 8. Financial-Core Boundary

This ticket does **not** introduce separate institutional copies of the financial-core concepts.

The institutional activities ultimately feed the common financial chain:

```text
ANANSE TRANSACTION ────────────┐
                               │
SIKACREDIT LOAN / REPAYMENT ───┼──► FINANCIAL CONSEQUENCE
                               │             │
OMAN REMIT REMITTANCE ─────────┘             ▼
                                       LEDGER POSTING
                                             │
                                             ▼
                                      FINANCIAL STATE
```

Financial consequence, ledger posting, and resulting financial state are therefore not duplicated as separate Ananse, SikaCredit, or Oman Remit attribute sets.

---

# 9. Final Decisions

WP-2.2-T02 establishes the following:

1. **OCB owns the resolved cross-institutional identity, not institutional customer profiles.**
2. **Ananse, SikaCredit, and Oman Remit retain their own institutional customer attributes.**
3. **Ananse transaction attributes are explicitly defined.**
4. **SikaCredit loan and repayment activities are distinguished.**
5. **SikaCredit disbursement and repayment locations are separately represented.**
6. **Oman Remit remittance attributes are explicitly defined.**
7. **Redundant sender/receiver identifiers and generic counterparty references are excluded.**
8. **Generic event attributes are excluded where a more semantically precise business attribute exists.**
9. **Financial consequence, ledger, and financial state remain within the shared financial-core boundary.**
10. **No additional attributes are implied by this ticket merely because they could exist in a production system.**

## T02 Status

**WP-2.2-T02 — COMPLETE**

The attribute layer is now sufficiently defined to proceed to **WP-2.2-T03 — Relationships and Cardinalities**.
