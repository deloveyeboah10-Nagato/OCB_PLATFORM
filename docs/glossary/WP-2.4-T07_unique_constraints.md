# T06 — Unique Constraint Decision Record

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.4 — Physical Database Implementation
**Ticket:** WP-2.4-T07
**Status:** **APPROVED**
**Decision Type:** Unique Constraint and Observability Boundary

---

## 1. Decision

No additional `UNIQUE` constraints will be implemented in the OCB Platform v1.0.0 operational schema beyond uniqueness already provided by the existing primary keys.

The absence of additional unique constraints on customer contact and device attributes is **intentional**.

---

## 2. Approved Uniqueness

The following values are already required to be unique through their primary-key definitions:

| Object                  | Attribute(s)                          | Uniqueness mechanism  |
| ----------------------- | ------------------------------------- | --------------------- |
| `ocb.customer`          | `ocb_customer_id`                     | Primary Key           |
| `ocb.customer_identity` | `source_entity`, `source_customer_id` | Composite Primary Key |
| `ananse.customer`       | `customer_id`                         | Primary Key           |
| `ananse.transaction`    | `transaction_id`                      | Primary Key           |
| `wallet.wallet`         | `wallet_id`                           | Primary Key           |
| `sikacredit.customer`   | `customer_id`                         | Primary Key           |
| `sikacredit.loan`       | `loan_id`                             | Primary Key           |
| `sikacredit.repayment`  | `repayment_id`                        | Primary Key           |
| `oman_remit.customer`   | `customer_id`                         | Primary Key           |
| `oman_remit.remittance` | `remittance_id`                       | Primary Key           |
| Reference tables        | Reference code                        | Primary Key           |

No separate `UNIQUE` constraint is required where the primary key already establishes the required uniqueness.

---

## 3. Attributes Intentionally Not Made Unique

The following attributes will **not** receive physical `UNIQUE` constraints in v1.0.0:

* `email`
* `phone_number`
* `device_id`

This is an architectural decision rather than an omission.

---

## 4. Email

`email` is not assumed to represent an exclusively owned customer identity.

Multiple customers may legitimately share an email address, including circumstances such as:

* family or household use;
* business or organisational addresses;
* shared administrative addresses;
* source-system data practices;
* other legitimate shared-contact arrangements.

Therefore:

```text
email ≠ guaranteed unique customer identifier
```

OCB will preserve repeated email values where they occur in source data.

Multiple customers associated with the same email may subsequently be used as an analytical relationship or exception condition.

---

## 5. Phone Number

`phone_number` is similarly not treated as an immutable unique customer identifier.

A telephone number may be:

* shared;
* reassigned;
* transferred between users;
* associated with different customer records over time.

Therefore, a database-level uniqueness rule could incorrectly reject legitimate source observations and could obscure relationships that may be relevant to regulatory or financial-crime analysis.

---

## 6. Device ID

`device_id` is intentionally **not** subject to a database-level uniqueness constraint.

The OCB regulatory model may establish a rule that a registered device should be associated with one customer account at a given point in time.

However, the database must remain capable of representing observations such as:

```text
Device A
   │
   ├── Customer 001
   └── Customer 002
```

Such an association may result from legitimate circumstances, including:

* device reassignment;
* family use;
* shared-device use;
* changes in account ownership;
* other operational circumstances.

It may also represent a potentially significant regulatory or fraud indicator.

Therefore, OCB will **observe and analyse the relationship rather than prevent its storage.**

---

## 7. Regulatory Intelligence Boundary

The distinction is:

```text
SOURCE / OPERATIONAL DATA
        ↓
Preserve observed relationships
        ↓
ANALYTICAL DETECTION
        ↓
Apply OCB regulatory rules
        ↓
Identify exceptions / unusual relationships
        ↓
Risk or investigation intelligence
```

For example, a later analytical rule may identify:

```text
COUNT(DISTINCT customer_id)
        per device_id
              >
              1
```

as a potential device-account association exception.

The database constraint layer therefore does not attempt to enforce every regulatory or fraud-detection rule.

---

## 8. Architectural Principle

OCB v1.0.0 distinguishes between **data integrity** and **intelligence detection**.

A relationship that is unusual or potentially prohibited from a regulatory perspective is not necessarily invalid data.

Therefore:

> **OCB should not enforce uniqueness where multiple occurrences may themselves constitute useful regulatory or financial-crime intelligence.**

Applying a database uniqueness constraint could prevent the platform from representing the very relationship it is intended to detect.

---

## 9. Consequence of the Decision

### Positive consequences

The decision allows OCB to:

* preserve source observations;
* detect shared attributes;
* identify multiple customers associated with a device;
* analyse potentially suspicious relationships;
* distinguish legitimate relationships from anomalous ones;
* apply regulatory rules analytically rather than destroying evidence at ingestion/storage.

### Trade-off

The operational schema will permit relationships that may later be considered unusual or non-compliant.

This is intentional.

The responsibility for determining whether such relationships are suspicious, exceptional, or permissible belongs to the **analytical and regulatory-intelligence layer**, not the basic relational integrity layer.

---

## 10. T06 Constraint Boundary

The approved v1.0.0 constraint architecture is therefore:

```text
PRIMARY KEYS
    ↓
Identity / row uniqueness

FOREIGN KEYS
    ↓
Referential integrity

CHECK CONSTRAINTS
    ↓
Basic domain integrity

UNIQUE CONSTRAINTS
    ↓
No additional constraints approved

ANALYTICAL / REGULATORY RULES
    ↓
Detection of unusual or prohibited relationships
```

This completes the unique-constraint decision for T06.

**Status: APPROVED.**
