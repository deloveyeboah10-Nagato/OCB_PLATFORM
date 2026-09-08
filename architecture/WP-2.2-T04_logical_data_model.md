# WP-2.2-T04 — Define Foreign-Key Relationships

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T04
**Status:** **REVISED / RECONCILED / LOCKED**
**Decision Type:** Logical data-model definition

---

## 1. Purpose

This ticket defines the foreign-key relationships between the relational entities established in **WP-2.2-T01**, using the attributes and primary identifiers defined in **WP-2.2-T02** and **WP-2.2-T03**.

The relationships defined here are reconciled with the **approved WP-2.4 physical table deployment**.

Foreign keys establish explicit relational dependencies between deployed tables.

The authoritative physical model currently contains **twelve (12) foreign-key relationships**.

These relationships include:

* institutional entity relationships;
* OCB identity-resolution relationships;
* Ananse transaction relationships;
* reference-data relationships.

No analytical relationship is treated as a foreign key unless the relationship is explicitly implemented in the physical database.

---

# 2. OCB Relationships

## 2.1 `OCB_CUSTOMER_IDENTITY` → `OCB_CUSTOMER`

The OCB identity-mapping table references the OCB-resolved customer.

```text
OCB_CUSTOMER_IDENTITY.ocb_customer_id
                ↓
OCB_CUSTOMER.ocb_customer_id
```

| Child Entity            | FK Attribute      | Parent Entity  | Parent Key        |
| ----------------------- | ----------------- | -------------- | ----------------- |
| `OCB_CUSTOMER_IDENTITY` | `ocb_customer_id` | `OCB_CUSTOMER` | `ocb_customer_id` |

This relationship associates an institutional source identity with its resolved OCB customer identity.

The FK does not make `ocb_customer_id` the primary identifier of `OCB_CUSTOMER_IDENTITY`.

The primary key of the identity-mapping entity remains:

```text
(source_entity, source_customer_id)
```

---

# 3. Ananse Relationships

## 3.1 `ANANSE_WALLET` → `ANANSE_CUSTOMER`

An Ananse wallet is associated with its owning Ananse customer.

```text
ANANSE_WALLET.customer_id
          ↓
ANANSE_CUSTOMER.customer_id
```

| Child Entity    | FK Attribute  | Parent Entity     | Parent Key    |
| --------------- | ------------- | ----------------- | ------------- |
| `ANANSE_WALLET` | `customer_id` | `ANANSE_CUSTOMER` | `customer_id` |

This establishes the customer-to-wallet relationship in the physical model.

The relationship is:

```text
ANANSE_CUSTOMER
      │
      │ customer_id
      ▼
ANANSE_WALLET
```

---

## 3.2 `ANANSE_TRANSACTION` → `ANANSE_CUSTOMER`

An Ananse transaction is associated with its institutional customer.

```text
ANANSE_TRANSACTION.customer_id
          ↓
ANANSE_CUSTOMER.customer_id
```

| Child Entity         | FK Attribute  | Parent Entity     | Parent Key    |
| -------------------- | ------------- | ----------------- | ------------- |
| `ANANSE_TRANSACTION` | `customer_id` | `ANANSE_CUSTOMER` | `customer_id` |

This relationship preserves the direct institutional ownership of the transaction by the Ananse customer.

---

## 3.3 `ANANSE_TRANSACTION` → `ANANSE_WALLET`

An Ananse transaction is associated with the wallet through which the activity occurs.

```text
ANANSE_TRANSACTION.wallet_id
          ↓
ANANSE_WALLET.wallet_id
```

| Child Entity         | FK Attribute | Parent Entity   | Parent Key  |
| -------------------- | ------------ | --------------- | ----------- |
| `ANANSE_TRANSACTION` | `wallet_id`  | `ANANSE_WALLET` | `wallet_id` |

The resulting relational structure is:

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

The transaction also retains its direct `customer_id` relationship to `ANANSE_CUSTOMER`.

---

## 3.4 `ANANSE_TRANSACTION` → `REF_TRANSACTION_TYPE`

The transaction references the controlled transaction-type reference entity.

```text
ANANSE_TRANSACTION.transaction_type_id
          ↓
REF_TRANSACTION_TYPE.transaction_type_id
```

| Child Entity         | FK Attribute          | Parent Entity          | Parent Key            |
| -------------------- | --------------------- | ---------------------- | --------------------- |
| `ANANSE_TRANSACTION` | `transaction_type_id` | `REF_TRANSACTION_TYPE` | `transaction_type_id` |

This establishes controlled referential integrity for transaction-type identifiers.

---

## 3.5 `ANANSE_TRANSACTION` → `REF_TRANSACTION_STATUS`

The transaction references the controlled transaction-status reference entity.

```text
ANANSE_TRANSACTION.transaction_status_id
          ↓
REF_TRANSACTION_STATUS.transaction_status_id
```

| Child Entity         | FK Attribute            | Parent Entity            | Parent Key              |
| -------------------- | ----------------------- | ------------------------ | ----------------------- |
| `ANANSE_TRANSACTION` | `transaction_status_id` | `REF_TRANSACTION_STATUS` | `transaction_status_id` |

This establishes controlled referential integrity for transaction-status identifiers.

---

## 3.6 `ANANSE_TRANSACTION` → `REF_TRANSACTION_CHANNEL`

The transaction references the controlled transaction-channel reference entity.

```text
ANANSE_TRANSACTION.transaction_channel_id
          ↓
REF_TRANSACTION_CHANNEL.transaction_channel_id
```

| Child Entity         | FK Attribute             | Parent Entity             | Parent Key               |
| -------------------- | ------------------------ | ------------------------- | ------------------------ |
| `ANANSE_TRANSACTION` | `transaction_channel_id` | `REF_TRANSACTION_CHANNEL` | `transaction_channel_id` |

This establishes controlled referential integrity for transaction-channel identifiers.

---

## 3.7 `ANANSE_TRANSACTION` → `REF_CURRENCY`

The transaction references the controlled currency reference entity.

```text
ANANSE_TRANSACTION.currency_id
          ↓
REF_CURRENCY.currency_id
```

| Child Entity         | FK Attribute  | Parent Entity  | Parent Key    |
| -------------------- | ------------- | -------------- | ------------- |
| `ANANSE_TRANSACTION` | `currency_id` | `REF_CURRENCY` | `currency_id` |

This establishes controlled referential integrity for the transaction currency identifier.

The physical transaction table also retains the descriptive `currency` attribute.

---

# 4. SikaCredit Relationships

## 4.1 `SIKACREDIT_LOAN` → `SIKACREDIT_CUSTOMER`

A SikaCredit loan belongs to a SikaCredit customer.

```text
SIKACREDIT_LOAN.customer_id
          ↓
SIKACREDIT_CUSTOMER.customer_id
```

| Child Entity      | FK Attribute  | Parent Entity         | Parent Key    |
| ----------------- | ------------- | --------------------- | ------------- |
| `SIKACREDIT_LOAN` | `customer_id` | `SIKACREDIT_CUSTOMER` | `customer_id` |

This establishes the customer-to-loan relationship.

---

## 4.2 `SIKACREDIT_REPAYMENT` → `SIKACREDIT_LOAN`

A SikaCredit repayment is associated with the loan against which it was made.

```text
SIKACREDIT_REPAYMENT.loan_id
          ↓
SIKACREDIT_LOAN.loan_id
```

| Child Entity           | FK Attribute | Parent Entity     | Parent Key |
| ---------------------- | ------------ | ----------------- | ---------- |
| `SIKACREDIT_REPAYMENT` | `loan_id`    | `SIKACREDIT_LOAN` | `loan_id`  |

The resulting relationship is:

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

One loan may therefore have multiple repayment records.

---

# 5. Oman Remit Relationships

## 5.1 `OMAN_REMIT_REMITTANCE` → `OMAN_REMIT_CUSTOMER`

An Oman Remit remittance is associated with the Oman Remit customer initiating the activity.

```text
OMAN_REMIT_REMITTANCE.customer_id
          ↓
OMAN_REMIT_CUSTOMER.customer_id
```

| Child Entity            | FK Attribute  | Parent Entity         | Parent Key    |
| ----------------------- | ------------- | --------------------- | ------------- |
| `OMAN_REMIT_REMITTANCE` | `customer_id` | `OMAN_REMIT_CUSTOMER` | `customer_id` |

This preserves the source-system ownership of the remittance activity.

---

## 5.2 `OMAN_REMIT_REMITTANCE` → `REF_COUNTRY`

The Oman Remit remittance references the controlled country reference entity.

```text
OMAN_REMIT_REMITTANCE.country_id
          ↓
REF_COUNTRY.country_id
```

| Child Entity            | FK Attribute | Parent Entity | Parent Key   |
| ----------------------- | ------------ | ------------- | ------------ |
| `OMAN_REMIT_REMITTANCE` | `country_id` | `REF_COUNTRY` | `country_id` |

This relationship is explicitly implemented in the physical deployment.

The remittance also retains:

```text
origin_country
destination_country
```

as physical descriptive/business attributes.

The presence of `country_id` does not automatically imply that either of those descriptive attributes is removed from the source representation.

---

# 6. Complete Foreign-Key Register

The following twelve relationships constitute the **authoritative FK register** for the current physical deployment.

|  # | Child Entity            | Foreign-Key Attribute    | Parent Entity             | Parent Key               |
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

**Total authoritative FK relationships: 12.**

---

# 7. Relationship Classification

The twelve FK relationships can be grouped into four structural categories.

## 7.1 OCB identity relationship

```text
OCB_CUSTOMER_IDENTITY
        ↓
OCB_CUSTOMER
```

**1 FK**

---

## 7.2 Ananse institutional and reference relationships

```text
ANANSE_CUSTOMER
        ↓
ANANSE_WALLET
        ↓
ANANSE_TRANSACTION
```

with additional transaction references:

```text
ANANSE_TRANSACTION
        ├── REF_TRANSACTION_TYPE
        ├── REF_TRANSACTION_STATUS
        ├── REF_TRANSACTION_CHANNEL
        └── REF_CURRENCY
```

**6 FKs**

---

## 7.3 SikaCredit institutional relationships

```text
SIKACREDIT_CUSTOMER
        ↓
SIKACREDIT_LOAN
        ↓
SIKACREDIT_REPAYMENT
```

**2 FKs**

---

## 7.4 Oman Remit institutional and reference relationships

```text
OMAN_REMIT_CUSTOMER
        ↓
OMAN_REMIT_REMITTANCE
        ↓
REF_COUNTRY
```

**2 FKs**

---

Therefore:

```text
1 + 6 + 2 + 2 = 11
```

The remaining relationship is the direct Ananse transaction-to-customer relationship already included within the six Ananse FKs:

```text
ANANSE_TRANSACTION → ANANSE_CUSTOMER
```

Accordingly, the complete physical FK count remains:

```text
12 FKs
```

---

# 8. Relationships Deliberately Not Modelled

The following relationships are **not established as direct foreign keys** in the current physical deployment.

## 8.1 Institutional customers → `OCB_CUSTOMER`

There is no direct:

```text
ANANSE_CUSTOMER.ocb_customer_id
SIKACREDIT_CUSTOMER.ocb_customer_id
OMAN_REMIT_CUSTOMER.ocb_customer_id
```

The cross-institutional identity relationship is maintained through:

```text
OCB_CUSTOMER
      ↓
OCB_CUSTOMER_IDENTITY
```

This preserves source-system identity ownership.

---

## 8.2 Oman Remit → Ananse Wallet

No direct FK is established between:

```text
OMAN_REMIT_REMITTANCE
```

and:

```text
ANANSE_WALLET
```

The eventual financial relationship is handled through the financial-consequence and ledger architecture.

A business narrative suggesting that an Oman Remit transfer reaches an Ananse wallet is not, by itself, sufficient justification for introducing a direct FK.

---

## 8.3 SikaCredit → Ananse Wallet

No direct FK is established between SikaCredit loan or repayment entities and Ananse wallets.

The relationship between lending activity and financial state is handled through the financial-core architecture.

---

## 8.4 Ananse Transaction → `OCB_CUSTOMER`

No direct FK is established between:

```text
ANANSE_TRANSACTION
```

and:

```text
OCB_CUSTOMER
```

The transaction remains linked to the Ananse customer.

OCB resolves the institutional customer identity through:

```text
OCB_CUSTOMER_IDENTITY
```

---

## 8.5 SikaCredit Loan → `REF_CURRENCY`

No currency reference FK is established on `SIKACREDIT_LOAN` in the approved physical deployment.

The physical loan table therefore retains:

```text
currency
```

as its loan-level currency attribute.

The logical model does not introduce a `currency_id` FK that does not exist in the deployed physical table.

---

# 9. Foreign-Key Integrity Principle

Foreign keys represent relationships that are explicitly established in the relational model and physical deployment.

They are not merely analytical convenience links.

The model therefore distinguishes between:

```text
PHYSICAL FK RELATIONSHIP
```

and:

```text
ANALYTICAL / BUSINESS RELATIONSHIP
```

A relationship may be analytically meaningful without being implemented as a database FK.

For example:

```text
OMAN_REMIT_REMITTANCE
        ↓
financial consequence
        ↓
ANANSE_WALLET
```

may be a valid financial relationship without requiring:

```text
OMAN_REMIT_REMITTANCE.wallet_id
```

in the institutional source table.

This preserves the architectural boundary between institutional source activity and the financial core.

---

# 10. Reference-Data FK Principle

Reference-table foreign keys are used where the physical deployment establishes controlled reference relationships.

The current reference FK relationships are:

```text
ANANSE_TRANSACTION.transaction_type_id
        ↓
REF_TRANSACTION_TYPE.transaction_type_id
```

```text
ANANSE_TRANSACTION.transaction_status_id
        ↓
REF_TRANSACTION_STATUS.transaction_status_id
```

```text
ANANSE_TRANSACTION.transaction_channel_id
        ↓
REF_TRANSACTION_CHANNEL.transaction_channel_id
```

```text
ANANSE_TRANSACTION.currency_id
        ↓
REF_CURRENCY.currency_id
```

```text
OMAN_REMIT_REMITTANCE.country_id
        ↓
REF_COUNTRY.country_id
```

These reference relationships do not automatically eliminate corresponding descriptive attributes retained in the physical source representation.

---

# 11. Relationship Integrity and Entity Ownership

The FK structure preserves the ownership boundaries established in the logical model.

### OCB

```text
OCB_CUSTOMER
      ↓
OCB_CUSTOMER_IDENTITY
```

OCB owns the resolved identity.

The institutional systems retain ownership of their own customer identities.

### Ananse

```text
ANANSE_CUSTOMER
      ↓
ANANSE_WALLET
      ↓
ANANSE_TRANSACTION
```

Ananse customer, wallet, and transaction remain distinct entities.

### SikaCredit

```text
SIKACREDIT_CUSTOMER
      ↓
SIKACREDIT_LOAN
      ↓
SIKACREDIT_REPAYMENT
```

Customer, loan, and repayment remain distinct entities.

### Oman Remit

```text
OMAN_REMIT_CUSTOMER
      ↓
OMAN_REMIT_REMITTANCE
```

Remittance activity remains owned by the Oman Remit institutional domain.

---

# 12. Reconciliation With WP-2.4 Physical Deployment

This revision supersedes the earlier six-FK definition.

The following relationships were added to reconcile the logical model with the physical deployment:

```text
ANANSE_WALLET.customer_id
        ↓
ANANSE_CUSTOMER.customer_id
```

```text
ANANSE_TRANSACTION.transaction_type_id
        ↓
REF_TRANSACTION_TYPE.transaction_type_id
```

```text
ANANSE_TRANSACTION.transaction_status_id
        ↓
REF_TRANSACTION_STATUS.transaction_status_id
```

```text
ANANSE_TRANSACTION.transaction_channel_id
        ↓
REF_TRANSACTION_CHANNEL.transaction_channel_id
```

```text
ANANSE_TRANSACTION.currency_id
        ↓
REF_CURRENCY.currency_id
```

```text
OMAN_REMIT_REMITTANCE.country_id
        ↓
REF_COUNTRY.country_id
```

The six relationships already established in the earlier logical model remain valid:

```text
OCB_CUSTOMER_IDENTITY → OCB_CUSTOMER

ANANSE_TRANSACTION → ANANSE_CUSTOMER

ANANSE_TRANSACTION → ANANSE_WALLET

SIKACREDIT_LOAN → SIKACREDIT_CUSTOMER

SIKACREDIT_REPAYMENT → SIKACREDIT_LOAN

OMAN_REMIT_REMITTANCE → OMAN_REMIT_CUSTOMER
```

The logical model therefore now conforms to the **12-FK physical deployment baseline**.

No new relational entity is introduced.

No existing entity is removed.

No institutional customer identity is replaced by the OCB identity.

No FK is introduced solely because a business relationship could theoretically exist.

---

# 13. Authoritative FK Count

The authoritative count for the current relational model is:

| Domain     | FK Count |
| ---------- | -------: |
| OCB        |        1 |
| Ananse     |        6 |
| SikaCredit |        2 |
| Oman Remit |        2 |
| **Total**  |   **11** |

**Correction:** The domain-level grouping above accounts for eleven relationships because the Ananse grouping must contain **seven** relationships when the direct customer, wallet, and four reference relationships are counted together with the wallet-to-customer relationship:

```text
ANANSE_WALLET → ANANSE_CUSTOMER                 1
ANANSE_TRANSACTION → ANANSE_CUSTOMER            1
ANANSE_TRANSACTION → ANANSE_WALLET              1
ANANSE_TRANSACTION → REF_TRANSACTION_TYPE       1
ANANSE_TRANSACTION → REF_TRANSACTION_STATUS     1
ANANSE_TRANSACTION → REF_TRANSACTION_CHANNEL    1
ANANSE_TRANSACTION → REF_CURRENCY               1
```

Therefore the authoritative domain count is:

| Domain     | FK Count |
| ---------- | -------: |
| OCB        |        1 |
| Ananse     |        7 |
| SikaCredit |        2 |
| Oman Remit |        2 |
| **TOTAL**  |   **12** |

This is the authoritative physical FK count.

---

# 14. Final Decision

The foreign-key relationships defined in this document are the authoritative FK baseline for the OCB Platform v1.0.0 relational model.

The authoritative set contains **twelve (12) foreign-key relationships**:

```text
1.  OCB_CUSTOMER_IDENTITY
        → OCB_CUSTOMER

2.  ANANSE_WALLET
        → ANANSE_CUSTOMER

3.  ANANSE_TRANSACTION
        → ANANSE_CUSTOMER

4.  ANANSE_TRANSACTION
        → ANANSE_WALLET

5.  ANANSE_TRANSACTION
        → REF_TRANSACTION_TYPE

6.  ANANSE_TRANSACTION
        → REF_TRANSACTION_STATUS

7.  ANANSE_TRANSACTION
        → REF_TRANSACTION_CHANNEL

8.  ANANSE_TRANSACTION
        → REF_CURRENCY

9.  SIKACREDIT_LOAN
        → SIKACREDIT_CUSTOMER

10. SIKACREDIT_REPAYMENT
        → SIKACREDIT_LOAN

11. OMAN_REMIT_REMITTANCE
        → OMAN_REMIT_CUSTOMER

12. OMAN_REMIT_REMITTANCE
        → REF_COUNTRY
```

These relationships are reconciled with the approved **WP-2.4 physical table deployment**.

No subsequent logical-model ticket may introduce, remove, or alter a foreign-key relationship without explicitly reopening this decision and reconciling the change against the physical deployment.

**WP-2.2-T04 — REVISED, RECONCILED AND LOCKED.**
