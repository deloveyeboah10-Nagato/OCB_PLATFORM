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
