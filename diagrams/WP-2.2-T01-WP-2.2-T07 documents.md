# WP-2.2-T01 — Define Relational Entities

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T01
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the relational entities required to represent the OCB Platform's institutional activity, cross-institutional identity, and financial-domain structure.

The entities are defined according to the **final post-T01 architectural decisions** established during WP-2.2.

The model distinguishes:

* OCB's resolved identity;
* institutional customer identities;
* institutional activities;
* Ananse wallets;
* SikaCredit loans and repayments;
* Oman Remit remittances.

The model does not merge institutional activities merely because they may ultimately produce a financial consequence.

---

# 2. Relational Entity Set

The OCB Platform logical model contains the following relational entities:

| Domain     | Entity                  |
| ---------- | ----------------------- |
| OCB        | `OCB_CUSTOMER`          |
| OCB        | `OCB_CUSTOMER_IDENTITY` |
| Ananse     | `ANANSE_CUSTOMER`       |
| Ananse     | `ANANSE_WALLET`         |
| Ananse     | `ANANSE_TRANSACTION`    |
| SikaCredit | `SIKACREDIT_CUSTOMER`   |
| SikaCredit | `SIKACREDIT_LOAN`       |
| SikaCredit | `SIKACREDIT_REPAYMENT`  |
| Oman Remit | `OMAN_REMIT_CUSTOMER`   |
| Oman Remit | `OMAN_REMIT_REMITTANCE` |

These are the authoritative relational entities for the current logical model.

---

# 3. OCB Entities

## 3.1 `OCB_CUSTOMER`

Represents OCB's **resolved cross-institutional identity**.

It is not a duplicate of any institutional customer record.

Its purpose is to provide a stable OCB identity to which source-system identities can be resolved.

Primary identifier:

```text
ocb_customer_id
```

The entity does not automatically own the demographic attributes held by the source institutions.

OCB may derive analytical customer attributes later where required.

---

## 3.2 `OCB_CUSTOMER_IDENTITY`

Represents the mapping between an OCB-resolved identity and an institutional customer identity.

The entity preserves the distinction between:

```text
source_entity
source_customer_id
```

and:

```text
ocb_customer_id
```

Primary identifier:

```text
(source_entity, source_customer_id)
```

This allows one OCB customer to be associated with customer identities held by multiple institutions without replacing those institutional identities.

---

# 4. Ananse Entities

## 4.1 `ANANSE_CUSTOMER`

Represents the customer record maintained by Ananse.

The entity owns Ananse's customer-level attributes, including identifying and demographic information maintained by the institution.

Primary identifier:

```text
customer_id
```

The Ananse customer is distinct from both the Ananse wallet and Ananse transaction.

---

## 4.2 `ANANSE_WALLET`

Represents the Ananse wallet.

The wallet is a separate financial object from the customer and from individual transactions.

Primary identifier:

```text
wallet_id
```

A customer may have a wallet, and a wallet may accumulate many financial activities over time.

Wallet state and ledger consequences are handled through the financial architecture rather than being conflated with the customer entity.

---

## 4.3 `ANANSE_TRANSACTION`

Represents an individual Ananse transaction/activity record.

Primary identifier:

```text
transaction_id
```

The transaction records the activity occurring through the Ananse platform.

It is associated with:

```text
customer_id
wallet_id
```

and contains transaction-level attributes such as:

* transaction type;
* transaction status;
* transaction timestamp;
* transaction location;
* transaction channel;
* device identifier;
* amount;
* currency.

The transaction is the authoritative Ananse activity record for the logical model.

---

# 5. SikaCredit Entities

## 5.1 `SIKACREDIT_CUSTOMER`

Represents the customer record maintained by SikaCredit.

Primary identifier:

```text
customer_id
```

Customer-level attributes remain owned by the SikaCredit customer entity.

---

## 5.2 `SIKACREDIT_LOAN`

Represents a loan issued by SikaCredit.

Primary identifier:

```text
loan_id
```

The loan represents the lending relationship and its associated loan-level financial attributes.

A loan may have multiple repayment records.

---

## 5.3 `SIKACREDIT_REPAYMENT`

Represents an individual repayment against a SikaCredit loan.

Primary identifier:

```text
repayment_id
```

The repayment contains repayment-level information such as:

```text
loan_id
repayment_amount
repayment_timestamp
repayment_location
```

Repayments are therefore represented as separate records rather than as repeating attributes within the loan entity.

This explicitly supports:

```text
one loan
    ↓
multiple repayments
```

---

# 6. Oman Remit Entities

## 6.1 `OMAN_REMIT_CUSTOMER`

Represents the customer record maintained by Oman Remit.

Primary identifier:

```text
customer_id
```

Customer-level attributes remain owned by the Oman Remit customer entity.

No separate sender identifier is required where the remittance's `customer_id` already identifies the Oman Remit customer initiating the activity.

---

## 6.2 `OMAN_REMIT_REMITTANCE`

Represents an individual remittance activity.

Primary identifier:

```text
remittance_id
```

The remittance contains remittance-level attributes including:

* customer identifier;
* remittance status;
* remittance timestamp;
* transaction location;
* amount;
* currency;
* origin country;
* destination country;
* transaction channel.

The receiving party is not represented as a separate Oman Remit customer merely because the remittance ultimately results in funds reaching an Ananse account.

---

# 7. Entity Separation Principles

The following distinctions are mandatory:

```text
ANANSE_CUSTOMER ≠ ANANSE_WALLET
```

```text
ANANSE_WALLET ≠ ANANSE_TRANSACTION
```

```text
ANANSE_CUSTOMER ≠ ANANSE_TRANSACTION
```

```text
SIKACREDIT_CUSTOMER ≠ SIKACREDIT_LOAN
```

```text
SIKACREDIT_LOAN ≠ SIKACREDIT_REPAYMENT
```

```text
OMAN_REMIT_CUSTOMER ≠ OMAN_REMIT_REMITTANCE
```

Likewise:

```text
ANANSE_CUSTOMER
≠
SIKACREDIT_CUSTOMER
≠
OMAN_REMIT_CUSTOMER
```

even where OCB subsequently determines that these institutional identities belong to the same real-world customer.

---

# 8. Identity Resolution Boundary

OCB does not replace institutional customer identities.

The logical relationship is:

```text
                 OCB_CUSTOMER
                       │
                       │
                       ▼
             OCB_CUSTOMER_IDENTITY
                 │       │       │
                 ▼       ▼       ▼
              ANANSE   SIKA    OMAN
             CUSTOMER  CUSTOMER  REMIT
```

Institutional customer records remain source-owned.

OCB resolves identities across those source records.

Any consolidated or derived customer attributes required for OCB analysis are produced downstream rather than forcing the institutional customer entities to surrender ownership of their attributes.

---

# 9. Financial-Core Boundary

Institutional activity ultimately participates in the financial architecture:

```text
INSTITUTIONAL ACTIVITY
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
ANANSE WALLET
        ↓
FINANCIAL STATE
```

The institutional entities describe the **source activities**.

They are not merged into the wallet or ledger merely because their activities can produce financial consequences.

The financial-core objects are therefore treated separately from the institutional activity entities.

---

# 10. Cross-Institutional Remittance Relationship

An Oman Remit remittance may ultimately result in funds being received through an Ananse wallet.

However, this does not mean that:

```text
OMAN_REMIT_REMITTANCE
```

should directly become a child of:

```text
ANANSE_WALLET
```

The cross-institutional financial relationship will be represented through the financial-consequence and ledger architecture where the appropriate linkage is established.

No unsupported relational entity or foreign key is introduced merely to represent the business narrative.

---

# 11. Final Entity Register

| Entity                  | Purpose                                     | Primary Identifier                    |
| ----------------------- | ------------------------------------------- | ------------------------------------- |
| `OCB_CUSTOMER`          | OCB-resolved cross-institutional identity   | `ocb_customer_id`                     |
| `OCB_CUSTOMER_IDENTITY` | Source-to-OCB identity mapping              | `(source_entity, source_customer_id)` |
| `ANANSE_CUSTOMER`       | Ananse customer identity and attributes     | `customer_id`                         |
| `ANANSE_WALLET`         | Ananse wallet                               | `wallet_id`                           |
| `ANANSE_TRANSACTION`    | Ananse transaction/activity                 | `transaction_id`                      |
| `SIKACREDIT_CUSTOMER`   | SikaCredit customer identity and attributes | `customer_id`                         |
| `SIKACREDIT_LOAN`       | SikaCredit loan                             | `loan_id`                             |
| `SIKACREDIT_REPAYMENT`  | Individual loan repayment                   | `repayment_id`                        |
| `OMAN_REMIT_CUSTOMER`   | Oman Remit customer identity and attributes | `customer_id`                         |
| `OMAN_REMIT_REMITTANCE` | Oman Remit remittance activity              | `remittance_id`                       |

---

# 12. Supersession of Previous T01

This revised T01 supersedes the earlier WP-2.2-T01 entity definition.

The later WP-2.2 architectural decisions are now consolidated into the authoritative entity model above.

Subsequent WP-2.2 tickets must use this entity register as their baseline.

No subsequent ticket may silently introduce, remove, merge, or split an entity without explicitly revisiting the entity definition.

---

## Final Decision

The authoritative relational entity model for OCB Platform v1.0.0 is the **post-T01 model consolidated in this revised T01**.

**WP-2.2-T01 — REVISED AND LOCKED.**




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



# WP-2.2-T04 — Define Foreign-Key Relationships

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T04
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the foreign-key relationships between the relational entities established in **WP-2.2-T01**, using the attributes and primary identifiers defined in **WP-2.2-T02** and **WP-2.2-T03**.

Foreign keys establish explicit relational dependencies between entities.

---

# 2. OCB Relationships

## 2.1 `OCB_CUSTOMER_IDENTITY` → `OCB_CUSTOMER`

```text
OCB_CUSTOMER_IDENTITY.ocb_customer_id
        ↓
OCB_CUSTOMER.ocb_customer_id
```

| Child Entity            | FK                | Parent Entity  | PK                |
| ----------------------- | ----------------- | -------------- | ----------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER` | `ocb_customer_id` |

This associates a source-system identity with its resolved OCB identity.

---

# 3. Ananse Relationships

## 3.1 `ANANSE_TRANSACTION` → `ANANSE_CUSTOMER`

```text
ANANSE_TRANSACTION.customer_id
        ↓
ANANSE_CUSTOMER.customer_id
```

| Child Entity         | FK            | Parent Entity     | PK            |
| -------------------- | ------------- | ----------------- | ------------- |
| `ANANSE_TRANSACTION` | `customer_id` | `ANANSE_CUSTOMER` | `customer_id` |

Each Ananse transaction is associated with an Ananse customer.

---

## 3.2 `ANANSE_TRANSACTION` → `ANANSE_WALLET`

```text
ANANSE_TRANSACTION.wallet_id
        ↓
ANANSE_WALLET.wallet_id
```

| Child Entity         | FK          | Parent Entity   | PK          |
| -------------------- | ----------- | --------------- | ----------- |
| `ANANSE_TRANSACTION` | `wallet_id` | `ANANSE_WALLET` | `wallet_id` |

Each Ananse transaction is associated with the wallet through which the activity occurs.

---

# 4. SikaCredit Relationships

## 4.1 `SIKACREDIT_LOAN` → `SIKACREDIT_CUSTOMER`

```text
SIKACREDIT_LOAN.customer_id
        ↓
SIKACREDIT_CUSTOMER.customer_id
```

| Child Entity      | FK            | Parent Entity         | PK            |
| ----------------- | ------------- | --------------------- | ------------- |
| `SIKACREDIT_LOAN` | `customer_id` | `SIKACREDIT_CUSTOMER` | `customer_id` |

Each SikaCredit loan belongs to a SikaCredit customer.

---

## 4.2 `SIKACREDIT_REPAYMENT` → `SIKACREDIT_LOAN`

```text
SIKACREDIT_REPAYMENT.loan_id
        ↓
SIKACREDIT_LOAN.loan_id
```

| Child Entity           | FK        | Parent Entity     | PK        |
| ---------------------- | --------- | ----------------- | --------- |
| `SIKACREDIT_REPAYMENT` | `loan_id` | `SIKACREDIT_LOAN` | `loan_id` |

Each repayment is associated with the loan against which it was made.

---

# 5. Oman Remit Relationships

## 5.1 `OMAN_REMIT_REMITTANCE` → `OMAN_REMIT_CUSTOMER`

```text
OMAN_REMIT_REMITTANCE.customer_id
        ↓
OMAN_REMIT_CUSTOMER.customer_id
```

| Child Entity            | FK            | Parent Entity         | PK            |
| ----------------------- | ------------- | --------------------- | ------------- |
| `OMAN_REMIT_REMITTANCE` | `customer_id` | `OMAN_REMIT_CUSTOMER` | `customer_id` |

Each Oman Remit remittance is associated with the Oman Remit customer initiating it.

---

# 6. Complete Foreign-Key Register

| Child Entity            | Foreign Key       | Parent Entity         | Parent Key        |
| ----------------------- | ----------------- | --------------------- | ----------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER`        | `ocb_customer_id` |
| `ANANSE_TRANSACTION`    | `customer_id`     | `ANANSE_CUSTOMER`     | `customer_id`     |
| `ANANSE_TRANSACTION`    | `wallet_id`       | `ANANSE_WALLET`       | `wallet_id`       |
| `SIKACREDIT_LOAN`       | `customer_id`     | `SIKACREDIT_CUSTOMER` | `customer_id`     |
| `SIKACREDIT_REPAYMENT`  | `loan_id`         | `SIKACREDIT_LOAN`     | `loan_id`         |
| `OMAN_REMIT_REMITTANCE` | `customer_id`     | `OMAN_REMIT_CUSTOMER` | `customer_id`     |

---

# 7. Relationships Deliberately Not Modelled

The following relationships are **not established as direct foreign keys** at this stage.

### 7.1 Institutional customers → `OCB_CUSTOMER`

There is no direct:

```text
ANANSE_CUSTOMER.ocb_customer_id
```

or equivalent column in the institutional customer entities.

The mapping is maintained through:

```text
OCB_CUSTOMER_IDENTITY
```

This preserves source-system ownership and keeps OCB identity resolution separate from institutional records.

---

### 7.2 Oman Remit → Ananse Wallet

No direct FK is created between:

```text
OMAN_REMIT_REMITTANCE
```

and:

```text
ANANSE_WALLET
```

The eventual financial consequence and ledger posting provide the appropriate architectural boundary for cross-institutional financial linkage.

---

### 7.3 SikaCredit → Ananse Wallet

No direct FK is created between SikaCredit loan/repayment entities and Ananse wallets.

The institutional lending activity produces financial consequences that are handled through the financial-core architecture.

---

### 7.4 Ananse Transaction → OCB Customer

No direct FK is placed from:

```text
ANANSE_TRANSACTION
```

to:

```text
OCB_CUSTOMER
```

The institutional transaction remains linked to its source customer.

OCB resolves the source customer to `ocb_customer_id` through the identity-mapping layer.

---

# 8. Relationship Integrity Principle

Foreign keys represent **actual ownership or dependency relationships**, not merely relationships that may be useful for analytical joins.

Therefore:

```text
Institutional entity
        ↓
Institutional identity
```

is represented directly where appropriate, while:

```text
Institutional identity
        ↓
OCB resolved identity
```

is represented through the dedicated identity-resolution object.

Cross-institutional financial consequences are not forced into institutional foreign-key relationships.

---

# 9. Final Decision

The six foreign-key relationships defined in this document constitute the authoritative FK baseline for the current logical model.

They are:

```text
OCB_CUSTOMER_IDENTITY → OCB_CUSTOMER

ANANSE_TRANSACTION → ANANSE_CUSTOMER
ANANSE_TRANSACTION → ANANSE_WALLET

SIKACREDIT_LOAN → SIKACREDIT_CUSTOMER
SIKACREDIT_REPAYMENT → SIKACREDIT_LOAN

OMAN_REMIT_REMITTANCE → OMAN_REMIT_CUSTOMER
```

No additional cross-institutional foreign keys are introduced at the logical-model stage without an explicit architectural decision.

**WP-2.2-T04 — REVISED AND LOCKED.**



# WP-2.2-T05 — Define Cardinality

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T05
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the cardinality of the foreign-key relationships established in **WP-2.2-T04**.

Cardinality describes how many records in one entity may relate to records in another entity.

The cardinalities below reflect the operational meaning of the entities and their established grain.

---

# 2. OCB Cardinality

## 2.1 `OCB_CUSTOMER` → `OCB_CUSTOMER_IDENTITY`

**Cardinality:**

```text
OCB_CUSTOMER 1 ──── 0..N OCB_CUSTOMER_IDENTITY
```

One OCB-resolved customer may have zero, one, or multiple source-system identities.

For example:

```text
OCB-C-001
   │
   ├── ANANSE / AN-C-001
   ├── SIKA / SC-C-017
   └── OMAN / OR-C-044
```

A source identity maps to one OCB customer.

Therefore the inverse relationship is:

```text
OCB_CUSTOMER_IDENTITY N ──── 1 OCB_CUSTOMER
```

---

# 3. Ananse Cardinality

## 3.1 `ANANSE_CUSTOMER` → `ANANSE_TRANSACTION`

**Cardinality:**

```text
ANANSE_CUSTOMER 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse customer may have zero, one, or many transactions.

Each transaction belongs to one Ananse customer.

---

## 3.2 `ANANSE_WALLET` → `ANANSE_TRANSACTION`

**Cardinality:**

```text
ANANSE_WALLET 1 ──── 0..N ANANSE_TRANSACTION
```

One Ananse wallet may have zero, one, or many transactions.

Each transaction is associated with one wallet.

The model therefore separates:

```text
Customer
   │
   └── Wallet
         │
         └── Transactions
```

without treating those three objects as one entity.

---

# 4. SikaCredit Cardinality

## 4.1 `SIKACREDIT_CUSTOMER` → `SIKACREDIT_LOAN`

**Cardinality:**

```text
SIKACREDIT_CUSTOMER 1 ──── 0..N SIKACREDIT_LOAN
```

One SikaCredit customer may have zero, one, or multiple loans.

Each loan belongs to one SikaCredit customer.

---

## 4.2 `SIKACREDIT_LOAN` → `SIKACREDIT_REPAYMENT`

**Cardinality:**

```text
SIKACREDIT_LOAN 1 ──── 0..N SIKACREDIT_REPAYMENT
```

One loan may have zero, one, or multiple repayments.

Each repayment belongs to one loan.

This supports the previously established repayment model:

```text
LOAN
 │
 ├── REPAYMENT 1
 ├── REPAYMENT 2
 ├── REPAYMENT 3
 └── ...
```

A loan may legitimately have no repayment yet.

---

# 5. Oman Remit Cardinality

## 5.1 `OMAN_REMIT_CUSTOMER` → `OMAN_REMIT_REMITTANCE`

**Cardinality:**

```text
OMAN_REMIT_CUSTOMER 1 ──── 0..N OMAN_REMIT_REMITTANCE
```

One Oman Remit customer may initiate zero, one, or multiple remittances.

Each remittance belongs to one Oman Remit customer.

---

# 6. Complete Cardinality Register

| Parent Entity         | Child Entity            | Cardinality |
| --------------------- | ----------------------- | ----------- |
| `OCB_CUSTOMER`        | `OCB_CUSTOMER_IDENTITY` | `1 : 0..N`  |
| `ANANSE_CUSTOMER`     | `ANANSE_TRANSACTION`    | `1 : 0..N`  |
| `ANANSE_WALLET`       | `ANANSE_TRANSACTION`    | `1 : 0..N`  |
| `SIKACREDIT_CUSTOMER` | `SIKACREDIT_LOAN`       | `1 : 0..N`  |
| `SIKACREDIT_LOAN`     | `SIKACREDIT_REPAYMENT`  | `1 : 0..N`  |
| `OMAN_REMIT_CUSTOMER` | `OMAN_REMIT_REMITTANCE` | `1 : 0..N`  |

---

# 7. Relationship Participation

The cardinalities above describe the maximum and minimum participation permitted by the logical model.

### Customer entities

A customer may exist before any activity occurs:

```text
customer → 0..N activities
```

Therefore the child-side participation is optional.

### Wallet

A wallet may exist before its first transaction:

```text
wallet → 0..N transactions
```

### Loan

A loan may exist before any repayment:

```text
loan → 0..N repayments
```

This is particularly important because a newly disbursed loan does not necessarily have a repayment immediately.

---

# 8. Cross-Institutional Cardinality

OCB identity resolution does not impose a one-to-one relationship between institutional customers and OCB customers.

The intended structure is:

```text
                    OCB_CUSTOMER
                         1
                         │
                       0..N
                         │
              OCB_CUSTOMER_IDENTITY
```

A single OCB customer may therefore resolve to multiple institutional identities.

However, each individual source identity represented by:

```text
(source_entity, source_customer_id)
```

maps to **one** `ocb_customer_id`.

---

# 9. Relationships Not Given Cardinality

No cardinality is established between the institutional activities and the downstream financial-core objects in this ticket.

In particular, this ticket does **not** create direct relationships between:

* Oman Remit and Ananse Wallet;
* SikaCredit and Ananse Wallet;
* institutional transactions and OCB Customer;
* institutional activities and ledger entries.

Those relationships belong to the financial-consequence and ledger architecture and will be defined at the appropriate stage.

---

# 10. Final Decision

The authoritative cardinalities for the current logical model are:

```text
OCB_CUSTOMER
    1 ──── 0..N
OCB_CUSTOMER_IDENTITY

ANANSE_CUSTOMER
    1 ──── 0..N
ANANSE_TRANSACTION

ANANSE_WALLET
    1 ──── 0..N
ANANSE_TRANSACTION

SIKACREDIT_CUSTOMER
    1 ──── 0..N
SIKACREDIT_LOAN

SIKACREDIT_LOAN
    1 ──── 0..N
SIKACREDIT_REPAYMENT

OMAN_REMIT_CUSTOMER
    1 ──── 0..N
OMAN_REMIT_REMITTANCE
```

**WP-2.2-T05 — REVISED AND LOCKED.**



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



# WP-2.2-T07 — Logical Model Consistency Review

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T07
**Status:** **REVISED / LOCKED**
**Decision Type:** Logical data-model validation

---

## 1. Purpose

This ticket performs the final consistency review of the logical relational model established through **WP-2.2-T01 to T06**.

The review confirms that:

* entities are consistent with their defined purpose;
* attributes belong to the correct entity and grain;
* primary identifiers are consistent;
* foreign keys reference the correct parent entities;
* cardinalities agree with the FK structure;
* normalization decisions agree with the entity model;
* no contradictory relational logic remains.

This is a **consistency validation**, not an opportunity to introduce new entities or attributes.

---

# 2. Entity Consistency

The authoritative entity set is:

```text
OCB_CUSTOMER
OCB_CUSTOMER_IDENTITY

ANANSE_CUSTOMER
ANANSE_WALLET
ANANSE_TRANSACTION

SIKACREDIT_CUSTOMER
SIKACREDIT_LOAN
SIKACREDIT_REPAYMENT

OMAN_REMIT_CUSTOMER
OMAN_REMIT_REMITTANCE
```

All entities defined in T01 remain represented through T02–T06.

**Result: ✅ Consistent**

---

# 3. Primary-Key Consistency

| Entity                  | Primary Key                           | Consistency |
| ----------------------- | ------------------------------------- | ----------- |
| `OCB_CUSTOMER`          | `ocb_customer_id`                     | ✅           |
| `OCB_CUSTOMER_IDENTITY` | `(source_entity, source_customer_id)` | ✅           |
| `ANANSE_CUSTOMER`       | `customer_id`                         | ✅           |
| `ANANSE_WALLET`         | `wallet_id`                           | ✅           |
| `ANANSE_TRANSACTION`    | `transaction_id`                      | ✅           |
| `SIKACREDIT_CUSTOMER`   | `customer_id`                         | ✅           |
| `SIKACREDIT_LOAN`       | `loan_id`                             | ✅           |
| `SIKACREDIT_REPAYMENT`  | `repayment_id`                        | ✅           |
| `OMAN_REMIT_CUSTOMER`   | `customer_id`                         | ✅           |
| `OMAN_REMIT_REMITTANCE` | `remittance_id`                       | ✅           |

No entity has conflicting primary-key definitions.

**Result: ✅ Consistent**

---

# 4. Foreign-Key Consistency

The FK structure established in T04 is:

```text
OCB_CUSTOMER_IDENTITY.ocb_customer_id
        ↓
OCB_CUSTOMER.ocb_customer_id
```

```text
ANANSE_TRANSACTION.customer_id
        ↓
ANANSE_CUSTOMER.customer_id
```

```text
ANANSE_TRANSACTION.wallet_id
        ↓
ANANSE_WALLET.wallet_id
```

```text
SIKACREDIT_LOAN.customer_id
        ↓
SIKACREDIT_CUSTOMER.customer_id
```

```text
SIKACREDIT_REPAYMENT.loan_id
        ↓
SIKACREDIT_LOAN.loan_id
```

```text
OMAN_REMIT_REMITTANCE.customer_id
        ↓
OMAN_REMIT_CUSTOMER.customer_id
```

Every FK references the corresponding parent PK.

**Result: ✅ Consistent**

---

# 5. Attribute-to-Entity Consistency

The attributes defined in T02 remain consistent with the entity grain.

### Customer-level

Customer attributes remain within:

```text
ANANSE_CUSTOMER
SIKACREDIT_CUSTOMER
OMAN_REMIT_CUSTOMER
```

### Activity-level

Activity attributes remain within:

```text
ANANSE_TRANSACTION
OMAN_REMIT_REMITTANCE
```

### Lending-level

Loan and repayment attributes remain separated:

```text
SIKACREDIT_LOAN
SIKACREDIT_REPAYMENT
```

### Wallet-level

Wallet remains independently represented:

```text
ANANSE_WALLET
```

### Identity-level

OCB identity mapping remains separated:

```text
OCB_CUSTOMER
OCB_CUSTOMER_IDENTITY
```

**Result: ✅ Consistent**

---

# 6. Cardinality Consistency

The T05 cardinalities agree with the T04 FK structure.

| Relationship                     | Cardinality | Consistent |
| -------------------------------- | ----------: | ---------- |
| OCB Customer → OCB Identity      |  `1 : 0..N` | ✅          |
| Ananse Customer → Transaction    |  `1 : 0..N` | ✅          |
| Ananse Wallet → Transaction      |  `1 : 0..N` | ✅          |
| SikaCredit Customer → Loan       |  `1 : 0..N` | ✅          |
| SikaCredit Loan → Repayment      |  `1 : 0..N` | ✅          |
| Oman Remit Customer → Remittance |  `1 : 0..N` | ✅          |

No relationship has a cardinality that conflicts with its FK structure.

**Result: ✅ Consistent**

---

# 7. Institutional Separation

The three institutional domains remain independent:

```text
ANANSE
├── CUSTOMER
├── WALLET
└── TRANSACTION

SIKACREDIT
├── CUSTOMER
├── LOAN
└── REPAYMENT

OMAN REMIT
├── CUSTOMER
└── REMITTANCE
```

No institutional entity has been incorrectly merged with another institutional entity.

**Result: ✅ Consistent**

---

# 8. Identity Resolution Consistency

OCB identity resolution remains separate from institutional source entities.

The model is:

```text
                    OCB_CUSTOMER
                         │
                         │
                OCB_CUSTOMER_IDENTITY
                    /       |       \
                   /        |        \
             ANANSE     SIKACREDIT   OMAN
            CUSTOMER     CUSTOMER     REMIT
```

The institutional customer entities do not require an `ocb_customer_id` column.

This preserves the source-system boundary established in T01.

**Result: ✅ Consistent**

---

# 9. Wallet Boundary Consistency

The logical model maintains the agreed distinction:

```text
ANANSE_CUSTOMER
       │
       │
ANANSE_WALLET
       │
       │
ANANSE_TRANSACTION
```

The wallet is not merged into Ananse Customer.

The wallet is not merged into Ananse Transaction.

Transactions reference both the customer and wallet because these represent distinct relational objects.

**Result: ✅ Consistent**

---

# 10. SikaCredit Repayment Consistency

The repayment model remains:

```text
SIKACREDIT_CUSTOMER
        │
        └── SIKACREDIT_LOAN
                │
                └── SIKACREDIT_REPAYMENT
```

A loan may therefore have multiple repayment records.

This is consistent with:

* the separate `repayment_id`;
* `loan_id` as FK;
* `repayment_amount`;
* `repayment_timestamp`;
* `repayment_location`;
* the `1 : 0..N` loan-to-repayment cardinality.

**Result: ✅ Consistent**

---

# 11. OCB Financial-Core Boundary

The logical model does not incorrectly force institutional activities into the Ananse wallet or ledger.

The architectural flow remains:

```text
ANANSE ACTIVITY
SIKACREDIT ACTIVITY
OMAN REMIT ACTIVITY
        │
        ↓
FINANCIAL CONSEQUENCE
        │
        ↓
LEDGER POSTING
        │
        ↓
ANANSE WALLET
        │
        ↓
FINANCIAL STATE
```

The institutional source entities describe the originating activity.

The financial-core architecture describes the resulting financial state.

**Result: ✅ Consistent**

---

# 12. Attribute Exclusion Consistency

The exclusions agreed in T02 remain respected.

The current model does not reintroduce:

* wallet type;
* customer status;
* loan type;
* loan purpose;
* application timestamp;
* approval timestamp;
* sender customer ID;
* receiver ID;
* counterparty reference;
* unnecessary effective dates;
* separate remittance type.

**Result: ✅ Consistent**

---

# 13. Device Identifier Consistency

`device_id` is present in:

```text
ANANSE_TRANSACTION
```

and is treated as a transaction-level attribute.

This is consistent with the requirement to preserve device information for transaction intelligence and analytical use.

**Result: ✅ Consistent**

---

# 14. Final Consistency Assessment

| Area                           | Result             |
| ------------------------------ | ------------------ |
| Entity definitions             | ✅ Consistent       |
| Attributes                     | ✅ Consistent       |
| Primary identifiers            | ✅ Consistent       |
| Foreign keys                   | ✅ Consistent       |
| Cardinalities                  | ✅ Consistent       |
| Normalization                  | ✅ Consistent       |
| Institutional boundaries       | ✅ Consistent       |
| Identity-resolution model      | ✅ Consistent       |
| Wallet model                   | ✅ Consistent       |
| Repayment model                | ✅ Consistent       |
| Financial-core boundary        | ✅ Consistent       |
| Previously excluded attributes | ✅ Not reintroduced |
| Device identifier              | ✅ Present          |

---

# 15. Final Decision

The WP-2.2 logical model has passed its internal consistency review.

The model established through T01–T06 is internally coherent and ready to proceed to the next architectural stage.

No additional entity, attribute, primary key, foreign key, or cardinality is introduced by this ticket.

**WP-2.2-T07 — REVISED AND LOCKED.**




<mxfile host="Electron">
  <diagram name="Page-1" id="tIwOiwJOPqPQzKmRBnyd">
    <mxGraphModel dx="1165" dy="849" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="827" pageHeight="1169" math="0" shadow="0">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
        <UserObject label="" mermaidData="{&#xa;  &quot;data&quot;: &quot;erDiagram\n\n    OCB_CUSTOMER {\n        string ocb_customer_id PK\n    }\n\n    OCB_CUSTOMER_IDENTITY {\n        string source_entity PK\n        string source_customer_id PK\n        string ocb_customer_id FK\n    }\n\n    ANANSE_CUSTOMER {\n        string customer_id PK\n        string first_name\n        string last_name\n        date date_of_birth\n        string nationality\n        string occupation\n        string phone_number\n        string email\n        datetime created_at\n        string status\n    }\n\n    ANANSE_WALLET {\n        string wallet_id PK\n    }\n\n    ANANSE_TRANSACTION {\n        string transaction_id PK\n        string customer_id FK\n        string wallet_id FK\n        string transaction_type\n        string transaction_status\n        datetime transaction_timestamp\n        string transaction_location\n        string transaction_channel\n        decimal amount\n        string currency\n    }\n\n    SIKACREDIT_CUSTOMER {\n        string customer_id PK\n        string first_name\n        string last_name\n        date date_of_birth\n        string nationality\n        string occupation\n        string phone_number\n        string email\n        datetime created_at\n    }\n\n    SIKACREDIT_LOAN {\n        string loan_id PK\n        string customer_id FK\n        datetime disbursement_timestamp\n        string disbursement_location\n        date maturity_date\n        decimal principal_amount\n        decimal interest_rate\n        string currency\n    }\n\n    SIKACREDIT_REPAYMENT {\n        string repayment_id PK\n        string loan_id FK\n        decimal repayment_amount\n        datetime repayment_timestamp\n        string repayment_location\n    }\n\n    OMAN_REMIT_CUSTOMER {\n        string customer_id PK\n        string first_name\n        string last_name\n        date date_of_birth\n        string nationality\n        string occupation\n        string phone_number\n        string email\n        datetime created_at\n    }\n\n    OMAN_REMIT_REMITTANCE {\n        string remittance_id PK\n        string customer_id FK\n        string remittance_status\n        datetime remittance_timestamp\n        string transaction_location\n        decimal amount\n        string currency\n        string origin_country\n        string destination_country\n        string transaction_channel\n    }\n\n    OCB_CUSTOMER ||--o{ OCB_CUSTOMER_IDENTITY : \&quot;resolved identity\&quot;\n\n    ANANSE_CUSTOMER ||--o{ ANANSE_TRANSACTION : \&quot;performs\&quot;\n\n    ANANSE_WALLET ||--o{ ANANSE_TRANSACTION : \&quot;records\&quot;\n\n    SIKACREDIT_CUSTOMER ||--o{ SIKACREDIT_LOAN : \&quot;holds\&quot;\n\n    SIKACREDIT_LOAN ||--o{ SIKACREDIT_REPAYMENT : \&quot;receives\&quot;\n\n    OMAN_REMIT_CUSTOMER ||--o{ OMAN_REMIT_REMITTANCE : \&quot;initiates\&quot;&quot;,&#xa;  &quot;config&quot;: null&#xa;}" id="zpEQAL8-ku0vnQqTyrOA-1">
          <mxCell connectable="0" parent="1" style="group;transparentBounds=1;editIcon=1;lockedGroup=0;groupPadding=10;" vertex="1">
            <mxGeometry as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="OCB_CUSTOMER" mermaidId="n:OCB_CUSTOMER" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="OCB_CUSTOMER" id="zpEQAL8-ku0vnQqTyrOA-2">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="86" width="255" x="41" y="224" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-3" parent="zpEQAL8-ku0vnQqTyrOA-2" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="255" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-4" parent="zpEQAL8-ku0vnQqTyrOA-3" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="65" as="geometry">
            <mxRectangle height="43" width="65" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-5" parent="zpEQAL8-ku0vnQqTyrOA-3" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="ocb_customer_id" vertex="1">
          <mxGeometry height="43" width="147" x="65" as="geometry">
            <mxRectangle height="43" width="147" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-6" parent="zpEQAL8-ku0vnQqTyrOA-3" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="212" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="OCB_CUSTOMER_IDENTITY" mermaidId="n:OCB_CUSTOMER_IDENTITY" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="OCB_CUSTOMER_IDENTITY" id="zpEQAL8-ku0vnQqTyrOA-7">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="172" width="276" x="30" y="773" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-8" parent="zpEQAL8-ku0vnQqTyrOA-7" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="276" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-9" parent="zpEQAL8-ku0vnQqTyrOA-8" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="65" as="geometry">
            <mxRectangle height="43" width="65" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-10" parent="zpEQAL8-ku0vnQqTyrOA-8" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="source_entity" vertex="1">
          <mxGeometry height="43" width="168" x="65" as="geometry">
            <mxRectangle height="43" width="168" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-11" parent="zpEQAL8-ku0vnQqTyrOA-8" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="233" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-12" parent="zpEQAL8-ku0vnQqTyrOA-7" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="276" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-13" parent="zpEQAL8-ku0vnQqTyrOA-12" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="65" as="geometry">
            <mxRectangle height="43" width="65" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-14" parent="zpEQAL8-ku0vnQqTyrOA-12" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="source_customer_id" vertex="1">
          <mxGeometry height="43" width="168" x="65" as="geometry">
            <mxRectangle height="43" width="168" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-15" parent="zpEQAL8-ku0vnQqTyrOA-12" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="233" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-16" parent="zpEQAL8-ku0vnQqTyrOA-7" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="276" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-17" parent="zpEQAL8-ku0vnQqTyrOA-16" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="65" as="geometry">
            <mxRectangle height="43" width="65" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-18" parent="zpEQAL8-ku0vnQqTyrOA-16" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="ocb_customer_id" vertex="1">
          <mxGeometry height="43" width="168" x="65" as="geometry">
            <mxRectangle height="43" width="168" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-19" parent="zpEQAL8-ku0vnQqTyrOA-16" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="233" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="ANANSE_CUSTOMER" mermaidId="n:ANANSE_CUSTOMER" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="ANANSE_CUSTOMER" id="zpEQAL8-ku0vnQqTyrOA-20">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="473" width="265" x="395" y="30" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-21" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-22" parent="zpEQAL8-ku0vnQqTyrOA-21" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-23" parent="zpEQAL8-ku0vnQqTyrOA-21" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-24" parent="zpEQAL8-ku0vnQqTyrOA-21" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-25" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-26" parent="zpEQAL8-ku0vnQqTyrOA-25" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-27" parent="zpEQAL8-ku0vnQqTyrOA-25" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="first_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-28" parent="zpEQAL8-ku0vnQqTyrOA-25" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-29" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-30" parent="zpEQAL8-ku0vnQqTyrOA-29" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-31" parent="zpEQAL8-ku0vnQqTyrOA-29" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="last_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-32" parent="zpEQAL8-ku0vnQqTyrOA-29" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-33" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-34" parent="zpEQAL8-ku0vnQqTyrOA-33" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-35" parent="zpEQAL8-ku0vnQqTyrOA-33" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date_of_birth" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-36" parent="zpEQAL8-ku0vnQqTyrOA-33" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-37" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-38" parent="zpEQAL8-ku0vnQqTyrOA-37" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-39" parent="zpEQAL8-ku0vnQqTyrOA-37" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="nationality" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-40" parent="zpEQAL8-ku0vnQqTyrOA-37" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-41" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-42" parent="zpEQAL8-ku0vnQqTyrOA-41" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-43" parent="zpEQAL8-ku0vnQqTyrOA-41" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="occupation" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-44" parent="zpEQAL8-ku0vnQqTyrOA-41" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-45" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-46" parent="zpEQAL8-ku0vnQqTyrOA-45" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-47" parent="zpEQAL8-ku0vnQqTyrOA-45" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="phone_number" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-48" parent="zpEQAL8-ku0vnQqTyrOA-45" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-49" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-50" parent="zpEQAL8-ku0vnQqTyrOA-49" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-51" parent="zpEQAL8-ku0vnQqTyrOA-49" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="email" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-52" parent="zpEQAL8-ku0vnQqTyrOA-49" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-53" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="387" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-54" parent="zpEQAL8-ku0vnQqTyrOA-53" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-55" parent="zpEQAL8-ku0vnQqTyrOA-53" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="created_at" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-56" parent="zpEQAL8-ku0vnQqTyrOA-53" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-57" parent="zpEQAL8-ku0vnQqTyrOA-20" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="430" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-58" parent="zpEQAL8-ku0vnQqTyrOA-57" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-59" parent="zpEQAL8-ku0vnQqTyrOA-57" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="status" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-60" parent="zpEQAL8-ku0vnQqTyrOA-57" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="ANANSE_WALLET" mermaidId="n:ANANSE_WALLET" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="ANANSE_WALLET" id="zpEQAL8-ku0vnQqTyrOA-61">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="86" width="200" x="740" y="224" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-62" parent="zpEQAL8-ku0vnQqTyrOA-61" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="200" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-63" parent="zpEQAL8-ku0vnQqTyrOA-62" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="65" as="geometry">
            <mxRectangle height="43" width="65" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-64" parent="zpEQAL8-ku0vnQqTyrOA-62" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="wallet_id" vertex="1">
          <mxGeometry height="43" width="92" x="65" as="geometry">
            <mxRectangle height="43" width="92" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-65" parent="zpEQAL8-ku0vnQqTyrOA-62" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="157" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="ANANSE_TRANSACTION" mermaidId="n:ANANSE_TRANSACTION" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="ANANSE_TRANSACTION" id="zpEQAL8-ku0vnQqTyrOA-66">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="473" width="323" x="523" y="622" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-67" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-68" parent="zpEQAL8-ku0vnQqTyrOA-67" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-69" parent="zpEQAL8-ku0vnQqTyrOA-67" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_id" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-70" parent="zpEQAL8-ku0vnQqTyrOA-67" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-71" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-72" parent="zpEQAL8-ku0vnQqTyrOA-71" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-73" parent="zpEQAL8-ku0vnQqTyrOA-71" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-74" parent="zpEQAL8-ku0vnQqTyrOA-71" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-75" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-76" parent="zpEQAL8-ku0vnQqTyrOA-75" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-77" parent="zpEQAL8-ku0vnQqTyrOA-75" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="wallet_id" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-78" parent="zpEQAL8-ku0vnQqTyrOA-75" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-79" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-80" parent="zpEQAL8-ku0vnQqTyrOA-79" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-81" parent="zpEQAL8-ku0vnQqTyrOA-79" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_type" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-82" parent="zpEQAL8-ku0vnQqTyrOA-79" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-83" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-84" parent="zpEQAL8-ku0vnQqTyrOA-83" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-85" parent="zpEQAL8-ku0vnQqTyrOA-83" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_status" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-86" parent="zpEQAL8-ku0vnQqTyrOA-83" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-87" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-88" parent="zpEQAL8-ku0vnQqTyrOA-87" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-89" parent="zpEQAL8-ku0vnQqTyrOA-87" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_timestamp" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-90" parent="zpEQAL8-ku0vnQqTyrOA-87" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-91" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-92" parent="zpEQAL8-ku0vnQqTyrOA-91" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-93" parent="zpEQAL8-ku0vnQqTyrOA-91" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_location" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-94" parent="zpEQAL8-ku0vnQqTyrOA-91" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-95" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-96" parent="zpEQAL8-ku0vnQqTyrOA-95" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-97" parent="zpEQAL8-ku0vnQqTyrOA-95" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_channel" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-98" parent="zpEQAL8-ku0vnQqTyrOA-95" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-99" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="387" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-100" parent="zpEQAL8-ku0vnQqTyrOA-99" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="decimal" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-101" parent="zpEQAL8-ku0vnQqTyrOA-99" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="amount" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-102" parent="zpEQAL8-ku0vnQqTyrOA-99" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-103" parent="zpEQAL8-ku0vnQqTyrOA-66" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="323" y="430" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-104" parent="zpEQAL8-ku0vnQqTyrOA-103" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-105" parent="zpEQAL8-ku0vnQqTyrOA-103" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="currency" vertex="1">
          <mxGeometry height="43" width="190" x="90" as="geometry">
            <mxRectangle height="43" width="190" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-106" parent="zpEQAL8-ku0vnQqTyrOA-103" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="280" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="SIKACREDIT_CUSTOMER" mermaidId="n:SIKACREDIT_CUSTOMER" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="SIKACREDIT_CUSTOMER" id="zpEQAL8-ku0vnQqTyrOA-107">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="430" width="265" x="1070" y="52" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-108" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-109" parent="zpEQAL8-ku0vnQqTyrOA-108" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-110" parent="zpEQAL8-ku0vnQqTyrOA-108" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-111" parent="zpEQAL8-ku0vnQqTyrOA-108" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-112" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-113" parent="zpEQAL8-ku0vnQqTyrOA-112" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-114" parent="zpEQAL8-ku0vnQqTyrOA-112" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="first_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-115" parent="zpEQAL8-ku0vnQqTyrOA-112" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-116" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-117" parent="zpEQAL8-ku0vnQqTyrOA-116" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-118" parent="zpEQAL8-ku0vnQqTyrOA-116" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="last_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-119" parent="zpEQAL8-ku0vnQqTyrOA-116" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-120" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-121" parent="zpEQAL8-ku0vnQqTyrOA-120" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-122" parent="zpEQAL8-ku0vnQqTyrOA-120" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date_of_birth" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-123" parent="zpEQAL8-ku0vnQqTyrOA-120" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-124" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-125" parent="zpEQAL8-ku0vnQqTyrOA-124" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-126" parent="zpEQAL8-ku0vnQqTyrOA-124" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="nationality" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-127" parent="zpEQAL8-ku0vnQqTyrOA-124" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-128" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-129" parent="zpEQAL8-ku0vnQqTyrOA-128" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-130" parent="zpEQAL8-ku0vnQqTyrOA-128" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="occupation" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-131" parent="zpEQAL8-ku0vnQqTyrOA-128" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-132" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-133" parent="zpEQAL8-ku0vnQqTyrOA-132" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-134" parent="zpEQAL8-ku0vnQqTyrOA-132" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="phone_number" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-135" parent="zpEQAL8-ku0vnQqTyrOA-132" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-136" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-137" parent="zpEQAL8-ku0vnQqTyrOA-136" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-138" parent="zpEQAL8-ku0vnQqTyrOA-136" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="email" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-139" parent="zpEQAL8-ku0vnQqTyrOA-136" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-140" parent="zpEQAL8-ku0vnQqTyrOA-107" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="387" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-141" parent="zpEQAL8-ku0vnQqTyrOA-140" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-142" parent="zpEQAL8-ku0vnQqTyrOA-140" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="created_at" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-143" parent="zpEQAL8-ku0vnQqTyrOA-140" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="SIKACREDIT_LOAN" mermaidId="n:SIKACREDIT_LOAN" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="SIKACREDIT_LOAN" id="zpEQAL8-ku0vnQqTyrOA-144">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="387" width="339" x="1033" y="665" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-145" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-146" parent="zpEQAL8-ku0vnQqTyrOA-145" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-147" parent="zpEQAL8-ku0vnQqTyrOA-145" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="loan_id" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-148" parent="zpEQAL8-ku0vnQqTyrOA-145" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-149" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-150" parent="zpEQAL8-ku0vnQqTyrOA-149" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-151" parent="zpEQAL8-ku0vnQqTyrOA-149" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-152" parent="zpEQAL8-ku0vnQqTyrOA-149" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-153" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-154" parent="zpEQAL8-ku0vnQqTyrOA-153" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-155" parent="zpEQAL8-ku0vnQqTyrOA-153" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="disbursement_timestamp" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-156" parent="zpEQAL8-ku0vnQqTyrOA-153" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-157" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-158" parent="zpEQAL8-ku0vnQqTyrOA-157" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-159" parent="zpEQAL8-ku0vnQqTyrOA-157" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="disbursement_location" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-160" parent="zpEQAL8-ku0vnQqTyrOA-157" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-161" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-162" parent="zpEQAL8-ku0vnQqTyrOA-161" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-163" parent="zpEQAL8-ku0vnQqTyrOA-161" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="maturity_date" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-164" parent="zpEQAL8-ku0vnQqTyrOA-161" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-165" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-166" parent="zpEQAL8-ku0vnQqTyrOA-165" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="decimal" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-167" parent="zpEQAL8-ku0vnQqTyrOA-165" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="principal_amount" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-168" parent="zpEQAL8-ku0vnQqTyrOA-165" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-169" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-170" parent="zpEQAL8-ku0vnQqTyrOA-169" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="decimal" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-171" parent="zpEQAL8-ku0vnQqTyrOA-169" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="interest_rate" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-172" parent="zpEQAL8-ku0vnQqTyrOA-169" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-173" parent="zpEQAL8-ku0vnQqTyrOA-144" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="339" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-174" parent="zpEQAL8-ku0vnQqTyrOA-173" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-175" parent="zpEQAL8-ku0vnQqTyrOA-173" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="currency" vertex="1">
          <mxGeometry height="43" width="206" x="90" as="geometry">
            <mxRectangle height="43" width="206" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-176" parent="zpEQAL8-ku0vnQqTyrOA-173" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="296" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="SIKACREDIT_REPAYMENT" mermaidId="n:SIKACREDIT_REPAYMENT" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="SIKACREDIT_REPAYMENT" id="zpEQAL8-ku0vnQqTyrOA-177">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="258" width="320" x="1042" y="1214" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-178" parent="zpEQAL8-ku0vnQqTyrOA-177" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="320" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-179" parent="zpEQAL8-ku0vnQqTyrOA-178" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-180" parent="zpEQAL8-ku0vnQqTyrOA-178" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="repayment_id" vertex="1">
          <mxGeometry height="43" width="187" x="90" as="geometry">
            <mxRectangle height="43" width="187" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-181" parent="zpEQAL8-ku0vnQqTyrOA-178" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="277" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-182" parent="zpEQAL8-ku0vnQqTyrOA-177" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="320" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-183" parent="zpEQAL8-ku0vnQqTyrOA-182" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-184" parent="zpEQAL8-ku0vnQqTyrOA-182" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="loan_id" vertex="1">
          <mxGeometry height="43" width="187" x="90" as="geometry">
            <mxRectangle height="43" width="187" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-185" parent="zpEQAL8-ku0vnQqTyrOA-182" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="277" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-186" parent="zpEQAL8-ku0vnQqTyrOA-177" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="320" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-187" parent="zpEQAL8-ku0vnQqTyrOA-186" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="decimal" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-188" parent="zpEQAL8-ku0vnQqTyrOA-186" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="repayment_amount" vertex="1">
          <mxGeometry height="43" width="187" x="90" as="geometry">
            <mxRectangle height="43" width="187" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-189" parent="zpEQAL8-ku0vnQqTyrOA-186" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="277" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-190" parent="zpEQAL8-ku0vnQqTyrOA-177" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="320" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-191" parent="zpEQAL8-ku0vnQqTyrOA-190" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-192" parent="zpEQAL8-ku0vnQqTyrOA-190" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="repayment_timestamp" vertex="1">
          <mxGeometry height="43" width="187" x="90" as="geometry">
            <mxRectangle height="43" width="187" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-193" parent="zpEQAL8-ku0vnQqTyrOA-190" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="277" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-194" parent="zpEQAL8-ku0vnQqTyrOA-177" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="320" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-195" parent="zpEQAL8-ku0vnQqTyrOA-194" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-196" parent="zpEQAL8-ku0vnQqTyrOA-194" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="repayment_location" vertex="1">
          <mxGeometry height="43" width="187" x="90" as="geometry">
            <mxRectangle height="43" width="187" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-197" parent="zpEQAL8-ku0vnQqTyrOA-194" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="277" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="OMAN_REMIT_CUSTOMER" mermaidId="n:OMAN_REMIT_CUSTOMER" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="OMAN_REMIT_CUSTOMER" id="zpEQAL8-ku0vnQqTyrOA-198">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="430" width="265" x="1480" y="52" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-199" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-200" parent="zpEQAL8-ku0vnQqTyrOA-199" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-201" parent="zpEQAL8-ku0vnQqTyrOA-199" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-202" parent="zpEQAL8-ku0vnQqTyrOA-199" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-203" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-204" parent="zpEQAL8-ku0vnQqTyrOA-203" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-205" parent="zpEQAL8-ku0vnQqTyrOA-203" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="first_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-206" parent="zpEQAL8-ku0vnQqTyrOA-203" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-207" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-208" parent="zpEQAL8-ku0vnQqTyrOA-207" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-209" parent="zpEQAL8-ku0vnQqTyrOA-207" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="last_name" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-210" parent="zpEQAL8-ku0vnQqTyrOA-207" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-211" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-212" parent="zpEQAL8-ku0vnQqTyrOA-211" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-213" parent="zpEQAL8-ku0vnQqTyrOA-211" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="date_of_birth" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-214" parent="zpEQAL8-ku0vnQqTyrOA-211" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-215" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-216" parent="zpEQAL8-ku0vnQqTyrOA-215" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-217" parent="zpEQAL8-ku0vnQqTyrOA-215" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="nationality" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-218" parent="zpEQAL8-ku0vnQqTyrOA-215" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-219" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-220" parent="zpEQAL8-ku0vnQqTyrOA-219" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-221" parent="zpEQAL8-ku0vnQqTyrOA-219" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="occupation" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-222" parent="zpEQAL8-ku0vnQqTyrOA-219" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-223" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-224" parent="zpEQAL8-ku0vnQqTyrOA-223" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-225" parent="zpEQAL8-ku0vnQqTyrOA-223" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="phone_number" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-226" parent="zpEQAL8-ku0vnQqTyrOA-223" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-227" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-228" parent="zpEQAL8-ku0vnQqTyrOA-227" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-229" parent="zpEQAL8-ku0vnQqTyrOA-227" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="email" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-230" parent="zpEQAL8-ku0vnQqTyrOA-227" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-231" parent="zpEQAL8-ku0vnQqTyrOA-198" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="265" y="387" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-232" parent="zpEQAL8-ku0vnQqTyrOA-231" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-233" parent="zpEQAL8-ku0vnQqTyrOA-231" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="created_at" vertex="1">
          <mxGeometry height="43" width="132" x="90" as="geometry">
            <mxRectangle height="43" width="132" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-234" parent="zpEQAL8-ku0vnQqTyrOA-231" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="222" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="OMAN_REMIT_REMITTANCE" mermaidId="n:OMAN_REMIT_REMITTANCE" mermaidBaseStyle="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" mermaidBaseValue="OMAN_REMIT_REMITTANCE" id="zpEQAL8-ku0vnQqTyrOA-235">
          <mxCell parent="zpEQAL8-ku0vnQqTyrOA-1" style="shape=table;startSize=43;container=1;collapsible=0;childLayout=tableLayout;fixedRows=1;rowLines=1;fontSize=16;fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;strokeWidth=1;align=center;resizeLast=1;html=1;fillColor=light-dark(#ECECFF,#1f2020);strokeColor=light-dark(#9370DB,#cccccc);fontColor=light-dark(#333333,#cccccc);" vertex="1">
            <mxGeometry height="473" width="322" x="1452" y="622" as="geometry" />
          </mxCell>
        </UserObject>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-236" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="43" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-237" parent="zpEQAL8-ku0vnQqTyrOA-236" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-238" parent="zpEQAL8-ku0vnQqTyrOA-236" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="remittance_id" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-239" parent="zpEQAL8-ku0vnQqTyrOA-236" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="PK" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-240" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="86" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-241" parent="zpEQAL8-ku0vnQqTyrOA-240" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-242" parent="zpEQAL8-ku0vnQqTyrOA-240" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="customer_id" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-243" parent="zpEQAL8-ku0vnQqTyrOA-240" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="FK" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-244" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="129" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-245" parent="zpEQAL8-ku0vnQqTyrOA-244" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-246" parent="zpEQAL8-ku0vnQqTyrOA-244" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="remittance_status" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-247" parent="zpEQAL8-ku0vnQqTyrOA-244" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-248" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="172" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-249" parent="zpEQAL8-ku0vnQqTyrOA-248" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="datetime" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-250" parent="zpEQAL8-ku0vnQqTyrOA-248" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="remittance_timestamp" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-251" parent="zpEQAL8-ku0vnQqTyrOA-248" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-252" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="215" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-253" parent="zpEQAL8-ku0vnQqTyrOA-252" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-254" parent="zpEQAL8-ku0vnQqTyrOA-252" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_location" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-255" parent="zpEQAL8-ku0vnQqTyrOA-252" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-256" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="258" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-257" parent="zpEQAL8-ku0vnQqTyrOA-256" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="decimal" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-258" parent="zpEQAL8-ku0vnQqTyrOA-256" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="amount" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-259" parent="zpEQAL8-ku0vnQqTyrOA-256" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-260" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="301" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-261" parent="zpEQAL8-ku0vnQqTyrOA-260" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-262" parent="zpEQAL8-ku0vnQqTyrOA-260" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="currency" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-263" parent="zpEQAL8-ku0vnQqTyrOA-260" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-264" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="344" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-265" parent="zpEQAL8-ku0vnQqTyrOA-264" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-266" parent="zpEQAL8-ku0vnQqTyrOA-264" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="origin_country" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-267" parent="zpEQAL8-ku0vnQqTyrOA-264" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-268" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#ffffff,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="387" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-269" parent="zpEQAL8-ku0vnQqTyrOA-268" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-270" parent="zpEQAL8-ku0vnQqTyrOA-268" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="destination_country" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-271" parent="zpEQAL8-ku0vnQqTyrOA-268" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-272" parent="zpEQAL8-ku0vnQqTyrOA-235" style="shape=tableRow;horizontal=0;startSize=0;swimlaneHead=0;swimlaneBody=1;fillColor=light-dark(#F1F1FF,#1f2020);strokeColor=inherit;strokeWidth=1;collapsible=0;dropTarget=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;top=0;left=0;right=0;bottom=0;" vertex="1">
          <mxGeometry height="43" width="322" y="430" as="geometry" />
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-273" parent="zpEQAL8-ku0vnQqTyrOA-272" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="string" vertex="1">
          <mxGeometry height="43" width="90" as="geometry">
            <mxRectangle height="43" width="90" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-274" parent="zpEQAL8-ku0vnQqTyrOA-272" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="transaction_channel" vertex="1">
          <mxGeometry height="43" width="189" x="90" as="geometry">
            <mxRectangle height="43" width="189" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <mxCell id="zpEQAL8-ku0vnQqTyrOA-275" parent="zpEQAL8-ku0vnQqTyrOA-272" style="shape=partialRectangle;connectable=0;fillColor=none;strokeColor=light-dark(#9370DB,#cccccc);strokeWidth=1;fontColor=light-dark(#333333,#cccccc);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;top=1;left=1;bottom=1;right=1;align=left;spacingLeft=8;overflow=hidden;fontSize=16;" value="" vertex="1">
          <mxGeometry height="43" width="43" x="279" as="geometry">
            <mxRectangle height="43" width="43" as="alternateBounds" />
          </mxGeometry>
        </mxCell>
        <UserObject label="&quot;resolved identity&quot;" mermaidId="e:OCB_CUSTOMER-&gt;OCB_CUSTOMER_IDENTITY#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="&quot;resolved identity&quot;" id="zpEQAL8-ku0vnQqTyrOA-276">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-2" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-7">
            <mxGeometry relative="1" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="&quot;performs&quot;" mermaidId="e:ANANSE_CUSTOMER-&gt;ANANSE_TRANSACTION#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.16;entryY=0;" mermaidBaseValue="&quot;performs&quot;" id="zpEQAL8-ku0vnQqTyrOA-277">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-20" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.16;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-66">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="528" y="563" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="&quot;records&quot;" mermaidId="e:ANANSE_WALLET-&gt;ANANSE_TRANSACTION#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.84;entryY=0;" mermaidBaseValue="&quot;records&quot;" id="zpEQAL8-ku0vnQqTyrOA-278">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-61" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.84;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-66">
            <mxGeometry relative="1" as="geometry">
              <Array as="points">
                <mxPoint x="840" y="466" />
              </Array>
            </mxGeometry>
          </mxCell>
        </UserObject>
        <UserObject label="&quot;holds&quot;" mermaidId="e:SIKACREDIT_CUSTOMER-&gt;SIKACREDIT_LOAN#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="&quot;holds&quot;" id="zpEQAL8-ku0vnQqTyrOA-279">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-107" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-144">
            <mxGeometry relative="1" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="&quot;receives&quot;" mermaidId="e:SIKACREDIT_LOAN-&gt;SIKACREDIT_REPAYMENT#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="&quot;receives&quot;" id="zpEQAL8-ku0vnQqTyrOA-280">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-144" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-177">
            <mxGeometry relative="1" as="geometry" />
          </mxCell>
        </UserObject>
        <UserObject label="&quot;initiates&quot;" mermaidId="e:OMAN_REMIT_CUSTOMER-&gt;OMAN_REMIT_REMITTANCE#0" mermaidBaseStyle="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;" mermaidBaseValue="&quot;initiates&quot;" id="zpEQAL8-ku0vnQqTyrOA-281">
          <mxCell edge="1" parent="zpEQAL8-ku0vnQqTyrOA-1" source="zpEQAL8-ku0vnQqTyrOA-198" style="curved=1;startArrow=ERmandOne;startSize=14;endArrow=ERzeroToMany;endSize=14;strokeColor=light-dark(#333333,#cccccc);strokeWidth=1;html=1;fontSize=14;labelBackgroundColor=light-dark(#F8FFEC4D,#2a2a2a4D);fontFamily=Trebuchet MS,Verdana,Arial,sans-serif;fontColor=light-dark(#333333,#cccccc);exitX=0.5;exitY=1;entryX=0.5;entryY=0;rounded=0;" target="zpEQAL8-ku0vnQqTyrOA-235">
            <mxGeometry relative="1" as="geometry" />
          </mxCell>
        </UserObject>
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>