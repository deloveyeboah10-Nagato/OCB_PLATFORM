# WP-2.3-T07 — Perform Coupling Review

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T07
**Status:** **APPROVED**
**Decision Type:** Coupling and schema-boundary validation

---

# 1. Purpose

This ticket performs the final coupling and schema-boundary review of the architecture established through **WP-2.3-T01 through WP-2.3-T06**.

The objective is to confirm that the approved schema architecture:

* preserves institutional ownership;
* preserves source-domain responsibility;
* isolates OCB identity resolution;
* supports required financial traceability;
* permits legitimate operational relationships;
* prevents inappropriate cross-institution operational coupling;
* permits controlled shared reference-data dependencies;
* supports financial-event and ledger relationships;
* supports cross-domain analytical correlation without creating unnecessary operational dependencies; and
* provides a sound boundary for physical implementation in **WP-2.4**.

This ticket is the final architectural validation of WP-2.3.

---

# 2. Approved Schema Architecture

The approved v1.0.0 schema architecture is:

```text
OCB_PLATFORM
│
├── ocb
├── ananse
├── sikacredit
├── oman_remit
├── wallet
├── ledger
└── ref
```

The responsibilities are:

| Schema       | Responsibility                                                          |
| ------------ | ----------------------------------------------------------------------- |
| `ocb`        | OCB-owned identity resolution and cross-institutional identity mapping  |
| `ananse`     | Ananse operational customer and transaction activity                    |
| `sikacredit` | SikaCredit operational customer, loan, and repayment activity           |
| `oman_remit` | Oman Remit operational customer and remittance activity                 |
| `wallet`     | Wallet and associated financial-position representation                 |
| `ledger`     | OCB financial events, financial consequences, and ledger representation |
| `ref`        | Shared controlled reference data                                        |

Schema separation represents **responsibility and coupling boundaries**.

It does not require every schema to be completely independent.

Legitimate relationships may cross schema boundaries where the relationship represents an approved financial or operational dependency.

---

# 3. Coupling Principles

Coupling within the OCB platform is classified into four principal categories:

```text
Operational Coupling
Financial Traceability Coupling
Shared Reference Coupling
Analytical Correlation
```

These categories must not be treated as equivalent.

A relationship may be valid architecturally without requiring a direct physical foreign key.

The governing principle is:

> **Physical coupling must exist only where the underlying relationship requires database-enforced integrity.**

---

# 4. Legitimate Operational Coupling

Operational relationships within an institutional domain are legitimate where they represent the actual structure of that domain.

Examples include:

```text
ananse.customer
       ↓
ananse.transaction
```

```text
sikacredit.customer
       ↓
sikacredit.loan
       ↓
sikacredit.repayment
```

```text
oman_remit.customer
       ↓
oman_remit.remittance
```

These relationships represent source-domain ownership and operational dependency.

They are therefore legitimate candidates for physical referential integrity.

---

# 5. Wallet Coupling

The wallet is physically represented within:

```text
wallet.wallet
```

while Ananse operational transactions remain within:

```text
ananse.transaction
```

Therefore, where a transaction is associated with a wallet, the relationship is:

```text
ananse.transaction
        │
        │ wallet_id
        ↓
wallet.wallet
```

This is a legitimate cross-schema operational relationship because the transaction requires identification of the wallet involved in the activity.

The physical separation does not imply separate ownership.

The wallet remains an Ananse-owned financial object represented within the dedicated `wallet` schema.

Therefore:

```text
wallet schema placement
        ≠
institutional ownership transfer
```

---

# 6. OCB Identity Coupling

OCB identity resolution remains an OCB responsibility.

The approved identity pattern is:

```text
source_entity
+
source_customer_id
        ↓
ocb.customer_identity
        ↓
ocb_customer_id
```

Source institutions retain their own customer identifiers.

OCB resolves relationships between those identities through its own identity model.

The architecture therefore does **not** require `ocb_customer_id` to be physically embedded into every source-owned operational table.

This preserves the distinction between:

```text
Source Identity
        ↓
Institutional Ownership
        ↓
OCB-Resolved Identity
```

OCB identity resolution is therefore a controlled OCB relationship rather than a replacement for source-domain identity.

---

# 7. Financial-Core Coupling

The financial core provides the controlled OCB representation of recognised financial activity.

The financial chain is:

```text
Source Institutional Activity
        ↓
ledger.financial_event
        ↓
ledger.financial_consequence
        ↓
ledger.entry
```

The approved source relationships are conceptually:

```text
ananse.transaction ───────┐
sikacredit.loan ──────────┤
sikacredit.repayment ─────┼──→ ledger.financial_event
oman_remit.remittance ────┘
```

The financial event retains source identity through its source-domain attributes.

Because the source object is polymorphic across institutional tables, the relationship:

```text
institution_id
source_entity
source_entity_id
```

must not be represented by an artificial foreign key to multiple unrelated source tables.

Instead, the source relationship is governed through controlled source identity and validation.

---

# 8. Financial Event to Consequence Coupling

The relationship between:

```text
ledger.financial_event
```

and:

```text
ledger.financial_consequence
```

is a mandatory financial-core relationship.

Its cardinality is:

```text
1 financial event
        ↓
0..many financial consequences
```

The zero-consequence case is required for:

```text
Failed events
Rejected events
```

A successful event may produce one or multiple consequences depending on the approved financial model.

For example:

```text
P2P Transfer
       │
       ├── Sender Debit
       │
       └── Receiver Credit
```

Therefore:

```text
1 financial event
        +
2 financial consequences
```

does not represent two independent authoritative events.

---

# 9. Financial Consequence to Ledger Coupling

A valid financial consequence may produce the corresponding ledger representation.

The approved chain is:

```text
financial_event
       ↓
financial_consequence
       ↓
ledger.entry
```

This relationship must preserve traceability.

A ledger entry must therefore be explainable back to the financial consequence and ultimately to the recognised financial event.

The structures remain distinct:

```text
Financial Event
        ≠
Financial Consequence
        ≠
Ledger Entry
```

This separation is mandatory.

---

# 10. Ledger-to-Wallet Coupling

Where a ledger entry affects an Ananse wallet, the ledger representation must identify the affected financial object.

Conceptually:

```text
ledger.entry
      ↓
affected wallet
      ↓
wallet.wallet
```

However, T07 does not automatically require every financial-object relationship to be implemented as a direct foreign key.

Where the ledger structure uses a generic financial-object representation, the physical integrity mechanism must be determined during WP-2.4 and WP-2.6.

The governing principle is:

> **The ledger must preserve financial-object traceability without introducing artificial foreign-key structures that cannot correctly represent polymorphic financial objects.**

---

# 11. Reference-Data Coupling

The `ref` schema provides shared controlled classifications.

The approved reference structures are:

```text
ref.transaction_type
ref.transaction_status
ref.transaction_channel
ref.currency
ref.country
```

Operational structures may reference these classifications where applicable.

For example:

```text
ananse.transaction
        │
        ├── transaction_type
        ├── transaction_status
        └── transaction_channel
                 ↓
                ref
```

Likewise:

```text
financial structure
        ↓
ref.currency
```

and:

```text
customer / remittance structure
        ↓
ref.country
```

Reference-data coupling is legitimate because these structures define shared controlled vocabularies rather than shared institutional ownership.

---

# 12. Cross-Institution Operational Coupling

Direct operational dependencies between institutional schemas are not permitted merely because the institutions participate in the same financial ecosystem.

The following relationships are therefore rejected:

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

These would incorrectly imply direct operational dependencies between independently owned institutional domains.

Cross-institution relationships are instead established through appropriate OCB financial, identity, or analytical structures.

---

# 13. Analytical Correlation Is Not Operational Coupling

OCB may need to correlate information across institutions.

For example:

```text
OCB Customer
     │
     ├── Ananse activity
     ├── SikaCredit activity
     └── Oman Remit activity
```

Such a relationship is analytically meaningful.

It does not require:

```text
ananse.transaction
        ↓
sikacredit.loan
```

as a physical operational foreign key.

The distinction is:

```text
Analytical Relationship
        ≠
Operational Dependency
```

Analytical correlation must therefore not be implemented as unnecessary operational coupling.

---

# 14. Source Activity and Financial Core

The financial core may depend upon institutional activity for financial traceability without acquiring ownership of that activity.

The intended architecture is:

```text
Institutional Source
        ↓
Source-Owned Activity
        ↓
OCB Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
```

The source record remains authoritative for its institutional meaning.

The financial core represents the OCB financial interpretation required for traceability, reconciliation, and state reconstruction.

---

# 15. Coupling Review Matrix

| Relationship                                               | Coupling Type                  | Decision                      |
| ---------------------------------------------------------- | ------------------------------ | ----------------------------- |
| `ocb.customer → ocb.customer_identity`                     | OCB identity                   | **Required**                  |
| `ananse.customer → ananse.transaction`                     | Operational                    | **Required**                  |
| `ananse.transaction → wallet.wallet`                       | Operational / financial object | **Required where applicable** |
| `sikacredit.customer → sikacredit.loan`                    | Operational                    | **Required**                  |
| `sikacredit.loan → sikacredit.repayment`                   | Operational                    | **Required**                  |
| `oman_remit.customer → oman_remit.remittance`              | Operational                    | **Required**                  |
| Source activity → `ledger.financial_event`                 | Financial traceability         | **Required where applicable** |
| `financial_event → financial_consequence`                  | Financial core                 | **Required**                  |
| `financial_consequence → ledger.entry`                     | Financial core                 | **Required**                  |
| Operational structures → `ref`                             | Controlled reference           | **Required where applicable** |
| Institutional schema → another institutional schema        | Cross-institution operational  | **Rejected**                  |
| Analytical relationship → operational FK                   | Analytical                     | **Rejected**                  |
| `ocb_customer_id` embedded in all source records           | Identity leakage               | **Rejected**                  |
| Generic financial-object FK without valid target semantics | Physical integrity risk        | **Rejected**                  |

---

# 16. Coupling Risk — OCB Identity Leakage

### Risk

OCB's resolved identity becomes embedded throughout source-owned operational structures.

### Control

Identity resolution remains within:

```text
ocb.customer
ocb.customer_identity
```

Source systems retain their own identities.

Downstream analytical processes may resolve the appropriate OCB identity when required.

---

# 17. Coupling Risk — Cross-Institution Foreign Keys

### Risk

Relationships between institutions are implemented as direct foreign keys.

### Control

Institutional schemas remain operationally independent.

Cross-institution relationships are represented through:

* OCB identity resolution;
* financial-event structures;
* financial-core structures;
* analytical relationships.

No direct institutional-to-institutional operational foreign key is introduced without a separately approved requirement.

---

# 18. Coupling Risk — Ledger Replacing Source Activity

### Risk

The ledger becomes incorrectly treated as the authoritative source for institutional transactions.

### Control

Maintain the separation:

```text
Source Activity
        ↓
Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
```

The ledger represents the accounting consequence.

It does not replace the source institution's operational record.

---

# 19. Coupling Risk — Reference Schema Expansion

### Risk

The `ref` schema becomes a general-purpose shared entity repository.

### Control

Restrict `ref` to controlled reference data.

The following remain outside its responsibility:

```text
Customers
Transactions
Wallets
Loans
Repayments
Remittances
Financial Events
Ledger Entries
Financial Positions
```

A concept does not belong in `ref` merely because multiple schemas may consume it.

---

# 20. Coupling Risk — Physical FK Overreach

### Risk

Every conceptual relationship is converted into a physical foreign key without considering ownership, polymorphism, or implementation semantics.

### Control

Physical foreign keys must be introduced only where:

1. the referenced object has a single valid target structure;
2. referential integrity can actually be enforced;
3. the relationship represents an approved dependency; and
4. the FK does not create unintended operational coupling.

Where a relationship is polymorphic or analytical, controlled identifiers and validation may be preferable to an artificial FK.

This distinction is particularly important for:

```text
financial_event.source_entity
financial_event.source_entity_id
financial_consequence.financial_object_type
financial_consequence.financial_object_id
```

---

# 21. Coupling Risk — Schema Placement Misinterpreted as Ownership

### Risk

Physical placement of a structure is interpreted as institutional ownership.

For example:

```text
wallet.wallet
```

could incorrectly be interpreted as an OCB-owned wallet merely because it resides outside the `ananse` schema.

### Control

Schema placement represents **database responsibility**, not necessarily institutional ownership.

Therefore:

```text
wallet schema
        ≠
wallet institutional ownership
```

and:

```text
ledger schema
        ≠
ownership of source institutional activity
```

---

# 22. Final Coupling Assessment

The review confirms that the approved architecture provides sufficient separation between:

```text
Institutional Operational Domains
```

```text
OCB Identity Resolution
```

```text
Financial Core
```

```text
Shared Reference Data
```

and:

```text
Analytical Correlation
```

The architecture permits necessary relationships without requiring the entire platform to become a universally interconnected operational database.

The resulting model is:

```text
Institutional Domains
        │
        ├───────────────┐
        │               │
        ↓               ↓
   OCB Identity     Financial Core
        │               │
        │               ├── Financial Event
        │               ├── Consequence
        │               └── Ledger
        │
        └──────→ OCB Intelligence
```

Shared reference data supports the appropriate structures without creating institutional ownership.

---

# 23. Physical Implementation Gate

The coupling review confirms that the architecture is sufficiently defined to proceed to physical implementation.

WP-2.4 must therefore implement only relationships authorised by the approved WP-2.3 architecture.

In particular, WP-2.4 must not introduce:

* direct institutional-to-institutional foreign keys;
* unnecessary duplication of OCB identity;
* speculative integration dependencies;
* unsupported external financial structures;
* generic reference tables without approved requirements;
* artificial foreign keys for polymorphic relationships;
* ledger structures that collapse financial events and accounting entries.

Any deviation from these boundaries requires explicit architectural review.

---

# 24. Final Approved Schema Architecture

The final WP-2.3 architecture is:

```text
OCB_PLATFORM
│
├── ocb
│   ├── customer
│   └── customer_identity
│
├── ananse
│   ├── customer
│   └── transaction
│
├── sikacredit
│   ├── customer
│   ├── loan
│   └── repayment
│
├── oman_remit
│   ├── customer
│   └── remittance
│
├── wallet
│   └── wallet
│
├── ledger
│   ├── financial_event
│   ├── financial_consequence
│   └── entry
│
└── ref
    ├── transaction_type
    ├── transaction_status
    ├── transaction_channel
    ├── currency
    └── country
```

The principal financial chain is:

```text
SOURCE-OWNED ACTIVITY
        ↓
FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER ENTRY
        ↓
FINANCIAL STATE
```

The principal identity chain is:

```text
SOURCE CUSTOMER IDENTITY
        ↓
OCB IDENTITY RESOLUTION
        ↓
OCB CUSTOMER IDENTITY
```

The principal control-data relationship is:

```text
OPERATIONAL STRUCTURE
        ↓
CONTROLLED REFERENCE DATA
```

The principal analytical principle is:

```text
CROSS-DOMAIN CORRELATION
        ≠
CROSS-DOMAIN OPERATIONAL COUPLING
```

---

# 25. Decision

**WP-2.3-T07 is APPROVED.**

The coupling review confirms that the schema architecture established through **WP-2.3-T01 through WP-2.3-T06** is suitable for physical implementation.

The review confirms that:

1. Institutional operational domains remain separated.

2. OCB identity resolution remains an OCB responsibility.

3. Legitimate intra-domain operational relationships are permitted.

4. Required wallet relationships are represented through the approved `wallet` schema.

5. Financial-event and financial-core relationships are explicitly recognised.

6. Financial events, financial consequences, and ledger entries remain separate structures.

7. Shared reference-data dependencies are permitted through the `ref` schema.

8. Direct cross-institution operational foreign keys are rejected.

9. Analytical relationships must not be implemented as unnecessary operational foreign keys.

10. OCB identity must not be redundantly embedded into all source-owned records.

11. Polymorphic source and financial-object relationships must not be represented through artificial foreign keys.

12. Schema placement must not be interpreted as institutional ownership.

13. No additional schema is required.

14. No additional cross-institution operational dependency is justified.

15. The architecture is approved for physical implementation.

---

# 26. WP-2.3 Completion

With approval of T07:

```text
WP-2.3
Operational Schema Design
        ↓
COMPLETE
```

The project proceeds to:

```text
WP-2.4
Physical Database Implementation
```

**Next Ticket:**

```text
WP-2.4-T01 — Create Database
```

WP-2.4 must implement the approved architecture without silently changing the schema boundaries, ownership model, event semantics, or coupling rules established by WP-2.3.

---

# Core Principle

> **OCB's schema architecture must be coupled where financial, operational, identity, or reference integrity genuinely requires a relationship, but must remain decoupled where a relationship would create artificial institutional ownership, operational dependency, or unsupported physical complexity. Architectural relationships and physical foreign keys are therefore not automatically equivalent.**
