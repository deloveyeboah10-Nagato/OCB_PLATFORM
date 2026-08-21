# WP-2.2-T07 — Produce Logical ERD

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.2 — Logical Data Model
**Ticket:** WP-2.2-T07
**Status:** **COMPLETE**
**Decision Type:** Logical architecture

---

## 1. Purpose

WP-2.2-T07 consolidates the decisions established in T01–T06 into the **logical entity-relationship model** for the OCB Platform.

The ERD represents:

* logical entities;
* primary identifiers;
* foreign keys;
* established relationships;
* cardinalities;
* OCB identity resolution;
* institutional boundaries.

It does not define physical SQL Server implementation details.

---

# 2. Logical ERD
Logical ERD: See the accompanying Draw.io logical ERD artifact.

---

# 3. Entity Boundaries

The logical model is organized into four conceptual areas:

```text
                         OCB
                          │
                 ┌────────┴────────┐
                 │                 │
          OCB_CUSTOMER       IDENTITY MAPPING
                 │
                 │
       ┌─────────┼──────────┐
       │         │          │
       ▼         ▼          ▼
    ANANSE    SIKACREDIT   OMAN REMIT
```

### Ananse

```text
ANANSE_CUSTOMER
ANANSE_WALLET
ANANSE_TRANSACTION
```

### SikaCredit

```text
SIKACREDIT_CUSTOMER
SIKACREDIT_LOAN
SIKACREDIT_REPAYMENT
```

### Oman Remit

```text
OMAN_REMIT_CUSTOMER
OMAN_REMIT_REMITTANCE
```

---

# 4. Identity Resolution

OCB does not directly merge the three institutional customer identifiers.

Instead:

```text
                    OCB_CUSTOMER
                         │
                         │ 1:M
                         ▼
              OCB_CUSTOMER_IDENTITY
                  │        │        │
                  ▼        ▼        ▼
               ANANSE     SIKA     OMAN
              CUSTOMER   CUSTOMER  CUSTOMER
```

The mapping is identified by:

```text
(source_entity, source_customer_id)
```

and resolves to:

```text
ocb_customer_id
```

This preserves institutional ownership while allowing OCB to establish a cross-institutional identity.

---

# 5. Ananse Activity Structure

The Ananse logical model distinguishes:

```text
Customer
   │
   └──< Transaction >── Wallet
```

A customer can have multiple transactions.

A wallet can have multiple transactions.

The transaction remains the activity-level record and carries:

```text
transaction_id
customer_id
wallet_id
```

This allows the same transaction to be associated with both its customer and wallet without conflating those objects.

---

# 6. SikaCredit Activity Structure

The SikaCredit model distinguishes:

```text
Customer
   │
   └──< Loan
          │
          └──< Repayment
```

This explicitly accommodates multiple repayments against a single loan.

The model therefore does not attempt to place multiple repayment amounts or timestamps directly into the loan entity.

---

# 7. Oman Remit Activity Structure

The Oman Remit model distinguishes:

```text
Customer
   │
   └──< Remittance
```

The remittance identifies its originating Oman Remit customer through:

```text
customer_id
```

No separate sender customer identifier is introduced.

No receiver customer identifier or counterparty reference is introduced.

---

# 8. Unresolved Cross-Institutional Relationship

The ERD deliberately does **not** draw a direct relationship between:

```text
OMAN_REMIT_REMITTANCE
```

and:

```text
ANANSE_WALLET
```

at this stage.

The broader financial architecture establishes that institutional financial activity ultimately contributes to financial consequences and ledger postings:

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

The logical linkage between an Oman Remit remittance and its resulting Ananse financial consequence will therefore be established through the appropriate financial-core model rather than by inventing an unsupported FK in the Oman Remit source model.

---

# 9. Scope of the ERD

The ERD intentionally excludes:

* physical SQL Server data types;
* indexes;
* constraints beyond PK/FK relationships;
* ETL implementation;
* Bronze/Silver/Gold physical schemas;
* derived analytical attributes;
* financial-consequence implementation;
* ledger implementation;
* wallet financial-state calculations;
* identity-resolution algorithms.

These belong to subsequent architecture and implementation work.

---

# 10. Final Decision

WP-2.2-T07 consolidates the logical data-model decisions established in WP-2.2-T01 through WP-2.2-T06.

The logical ERD is now defined.

**WP-2.2-T07 — COMPLETE.**

### WP-2.2 Status

**WP-2.2 — Logical Data Model: COMPLETE**