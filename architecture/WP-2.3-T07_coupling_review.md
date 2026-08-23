**Programme:** OCB Platform v1.0.0

**Work Package:** WP-2.3 — Operational Schema Design

**Ticket:** WP-2.3-T07

**Status:** **APPROVED**

**Decision Type:** Coupling and schema-boundary validation

---

# WP-2.3-T07 — Perform Coupling Review

## 1. Purpose

This ticket performs the final coupling review of the schema architecture defined across WP-2.3-T01 through WP-2.3-T06.

The objective is to confirm that the proposed schema boundaries:

* preserve institutional ownership;
* preserve source-system responsibility;
* isolate OCB identity resolution;
* permit required financial traceability;
* prevent inappropriate cross-institution operational coupling;
* permit controlled shared reference-data dependencies; and
* support cross-domain analytical correlation without forcing unnecessary operational relationships.

This is the final architectural validation before physical database implementation begins in WP-2.4.

---

## 2. Schema Architecture Under Review

The approved schema structure is:

```text
ocb
ananse
sikacredit
oman_remit
wallet
ledger
ref
```

Their responsibilities are:

| Schema       | Responsibility                                                         |
| ------------ | ---------------------------------------------------------------------- |
| `ocb`        | OCB-owned identity resolution and cross-institutional identity mapping |
| `ananse`     | Ananse Telecom operational customer and transaction records            |
| `sikacredit` | SikaCredit operational customer, loan, and repayment records           |
| `oman_remit` | Oman Remit operational customer and remittance records                 |
| `wallet`     | Wallet and financial-position representation                           |
| `ledger`     | Financial events, financial consequences, and ledger representation    |
| `ref`        | Shared controlled reference data                                       |

Schema separation represents **responsibility and coupling boundaries**. It does not mean that schemas must be completely independent.

---

## 3. Coupling Principles

### 3.1 Legitimate Operational Coupling

A relationship is legitimate where it represents an actual operational relationship within a domain.

Examples include:

```text
ananse.customer
       ↓
ananse.transaction
```

and:

```text
sikacredit.loan
       ↓
sikacredit.repayment
```

These relationships reflect the ownership and operational structure of the respective domains.

---

### 3.2 Financial Traceability Coupling

Institutional activity may be connected to the financial core where the relationship is required to establish financial traceability.

The approved pattern is:

```text
Source Institutional Activity
            ↓
     Financial Event
            ↓
   Financial Consequence
            ↓
       Ledger Entry
```

This does not transfer ownership of the source activity to the ledger.

The source record remains authoritative for the institutional activity.

---

### 3.3 Cross-Institution Operational Coupling

Direct operational dependencies between institutional schemas are not permitted merely because the institutions participate in the same financial ecosystem.

The following patterns are therefore rejected:

```text
ananse.transaction
       ↓
sikacredit.loan
```

```text
oman_remit.remittance
       ↓
ananse.transaction
```

```text
sikacredit.loan
       ↓
oman_remit.remittance
```

Where cross-institutional activity must be correlated, the relationship is represented through the appropriate OCB financial or analytical structures.

---

## 4. OCB Identity Coupling

OCB's cross-institutional identity is an OCB responsibility.

The approved identity-resolution pattern is:

```text
source_entity
       +
source_customer_id
       ↓
ocb.customer_identity
       ↓
ocb_customer_id
```

Source systems retain their own customer identities.

OCB resolves those identities rather than rewriting the identity of the source records.

Therefore, `ocb_customer_id` should not be added to every source-owned operational table merely to facilitate downstream analysis.

This preserves the distinction between:

* source identity;
* institutional ownership; and
* OCB-resolved identity.

---

## 5. Financial-Core Coupling

The financial core may reference institutional activity where required for financial traceability.

The intended dependency is:

```text
ananse.transaction ─────┐
sikacredit.loan ────────┼──→ ledger.financial_event
sikacredit.repayment ───┤
oman_remit.remittance ──┘
```

The financial event may then produce:

```text
ledger.financial_event
          ↓
ledger.financial_consequence
          ↓
ledger.ledger_entry
```

The financial core therefore provides a controlled financial representation while preserving the authority of the institutional source records.

---

## 6. Wallet Coupling

Wallet is an Ananse-owned financial object.

Its physical placement in the `wallet` schema does not transfer institutional ownership.

The separation exists to distinguish wallet/financial-state representation from Ananse's operational transaction structures.

Accordingly, the model may permit:

```text
ananse.transaction
       ↓
wallet.wallet
```

where required to establish the transaction's wallet relationship.

The physical schema boundary must not be interpreted as an ownership boundary between Ananse and the wallet.

---

## 7. Reference-Data Coupling

The `ref` schema provides controlled shared vocabulary.

Examples include:

```text
transaction_type
transaction_status
transaction_channel
currency
country
```

Operational structures may depend on these reference values where required.

However, `ref` must remain limited to controlled reference data.

Operational entities must not be moved into `ref` merely because multiple schemas may eventually consume them.

---

## 8. Coupling Review Matrix

| Relationship                                        | Coupling Type          | Decision                      |
| --------------------------------------------------- | ---------------------- | ----------------------------- |
| `ocb.customer → ocb.customer_identity`              | OCB ownership          | **Required**                  |
| `ananse.customer → ananse.transaction`              | Operational            | **Required**                  |
| `ananse.wallet → ananse.transaction`                | Operational            | **Required**                  |
| `sikacredit.customer → sikacredit.loan`             | Operational            | **Required**                  |
| `sikacredit.loan → sikacredit.repayment`            | Operational            | **Required**                  |
| `oman_remit.customer → oman_remit.remittance`       | Operational            | **Required**                  |
| Source activity → `ledger.financial_event`          | Financial traceability | **Required where applicable** |
| `financial_event → financial_consequence`           | Financial core         | **Required**                  |
| `financial_consequence → ledger_entry`              | Financial core         | **Required**                  |
| Operational schema → `ref`                          | Controlled reference   | **Required where applicable** |
| Institutional schema → another institutional schema | Cross-institution      | **Rejected**                  |
| Analytical relationship → operational foreign key   | Analytical             | **Rejected**                  |
| `ocb_customer_id` embedded into all source records  | Identity               | **Rejected**                  |

---

## 9. Coupling Risks

### 9.1 OCB Identity Leakage

**Risk:** OCB's resolved identity becomes embedded throughout source-owned operational structures.

**Control:** Maintain identity resolution within the OCB identity model and resolve identities downstream where required.

### 9.2 Cross-Institution Foreign Keys

**Risk:** Financial relationships are incorrectly implemented as direct foreign keys between institutional schemas.

**Control:** Preserve institutional separation and represent cross-institution financial relationships through the financial-core model.

### 9.3 Ledger Replacement of Source Activity

**Risk:** The ledger becomes treated as the authoritative source for institutional events.

**Control:** Maintain the distinction between source activity, financial representation, financial consequence, and ledger state.

### 9.4 Reference Schema Expansion

**Risk:** `ref` becomes a general-purpose shared entity schema.

**Control:** Restrict `ref` to controlled reference data.

---

## 10. Review Outcome

The coupling review confirms that the schema architecture defined in WP-2.3 is suitable for physical implementation.

No additional schema is required.

No existing schema boundary requires redesign.

No additional cross-institution operational dependency is justified.

The architecture therefore preserves the intended separation:

```text
Institutional Source Domains
            ↓
      Financial Core
            ↓
      Financial State
            ↓
    OCB Intelligence
```

rather than collapsing the platform into a universally interconnected operational model.

---

## 11. Decision

**WP-2.3-T07 is APPROVED.**

The schema architecture defined through WP-2.3-T01 through WP-2.3-T06 is approved for physical implementation.

**WP-2.3 — Operational Schema Design is COMPLETE.**

The project proceeds to:

**WP-2.4 — Physical Database Implementation**

**Next Ticket:** WP-2.4-T01 — Create database
