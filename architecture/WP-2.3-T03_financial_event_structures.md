# WP-2.3-T03 — Define Financial Event Structures

**Programme:** OCB Platform v1.0.0

**Work Package:** WP-2.3 — Operational Schema Design

**Ticket:** WP-2.3-T03

**Status:** **APPROVED**

**Decision Type:** Financial-event physical structure definition

---

# 1. Purpose

This ticket defines the physical financial-event structures required by the OCB Platform v1.0.0.

The purpose is to translate the financial-event semantics established in **WP-1.3** and the financial-state relationships established in **WP-1.4** into a controlled physical structure that can represent:

* authoritative financial events observed from institutional domains;
* event outcomes;
* valid financial consequences;
* affected financial objects;
* monetary values;
* temporal information;
* source references;
* relationships to resulting financial state.

The structure must preserve the distinction between:

```text
SOURCE-OWNED INSTITUTIONAL ACTIVITY
              ↓
        OCB OBSERVED EVENT
              ↓
         EVENT OUTCOME
              ↓
     FINANCIAL CONSEQUENCE
              ↓
        LEDGER POSTING
              ↓
      FINANCIAL STATE
```

The financial-event structure therefore does **not** replace the source institution's authoritative operational activity.

---

# 2. Governing Design Principle

The financial-event structure represents an observed financial event within the OCB financial model.

It does not become the source institution's operational transaction.

For example:

```text
ANANSE TRANSACTION
        ↓
OCB FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
WALLET STATE
```

Similarly:

```text
SIKACREDIT LOAN / REPAYMENT
        ↓
OCB FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
OUTSTANDING PRINCIPAL
```

and:

```text
OMAN REMIT REMITTANCE
        ↓
OCB FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
BENEFICIARY FINANCIAL POSITION
```

The source activity remains institution-owned.

The OCB financial-event structure provides the controlled representation required for financial traceability, reconciliation, and downstream intelligence.

---

# 3. Physical Location

Financial-event structures belong to the **financial core** rather than to an individual institutional schema.

They will therefore be placed within:

```text
ledger
```

The schema architecture becomes:

```text
OCB_PLATFORM

├── ocb
├── ananse
├── sikacredit
├── oman_remit
├── wallet
├── ledger
│   └── financial_event
└── ref
```

This does **not** mean that the `ledger` schema owns the institutional events.

It means that the OCB representation of financial truth is physically grouped within the financial-core responsibility.

Institutional ownership remains:

```text
Ananse
    → Ananse transaction

SikaCredit
    → Loan / Repayment

Oman Remit
    → Remittance

OCB Financial Core
    → Observed financial-event representation
    → Financial consequences
    → Ledger representation
```

---

# 4. Financial Event Structure

The principal structure is:

```text
ledger.financial_event
```

The grain is:

> **One row represents one OCB-recorded financial event.**

This means:

```text
1 financial event
        =
1 financial_event row
```

The structure must not combine multiple independent events into a single row.

Conversely, the existence of multiple financial consequences does not create multiple authoritative events where the event catalogue defines only one event.

This is particularly important for:

```text
P2P Transfer
```

A P2P Transfer remains **one financial event** even though it produces:

```text
P2P Send
P2P Receive
```

as separate financial consequences / event legs.

---

# 5. Core Financial Event Attributes

The initial structure is:

| Attribute            | Purpose                                                                   |
| -------------------- | ------------------------------------------------------------------------- |
| `financial_event_id` | Unique OCB identifier for the recorded financial event                    |
| `institution_id`     | Identifies the originating institutional domain                           |
| `event_type`         | Identifies the approved financial event                                   |
| `source_entity`      | Identifies the source-domain entity represented by the event              |
| `source_entity_id`   | Identifies the specific source record represented by the event            |
| `event_timestamp`    | Authoritative time at which the financial activity occurred               |
| `event_outcome`      | Records the outcome of the event                                          |
| `amount`             | Monetary value associated with the event where applicable                 |
| `currency`           | Currency associated with the event amount                                 |
| `actor_reference`    | Reference to the actor associated with the event where applicable         |
| `reference_value`    | Source or business reference associated with the event                    |
| `recorded_at`        | Time the event representation was recorded within the OCB financial model |

The exact SQL Server data types, precision, scale, and nullability are physical implementation concerns addressed during WP-2.4.

---

# 6. Event Identity

`financial_event_id` is the stable OCB identifier for the financial-event record.

It identifies:

```text
OCB financial event
```

It does **not** replace:

```text
Ananse transaction_id
SikaCredit loan_id
SikaCredit repayment_id
Oman Remit remittance_id
```

The source identifier remains available through:

```text
source_entity
source_entity_id
```

Conceptually:

```text
financial_event_id
        ↓
OCB event identity

source_entity + source_entity_id
        ↓
source activity identity
```

This preserves traceability between the OCB representation and the originating institutional activity.

---

# 7. Source Entity Representation

Because the seven approved financial events originate from different institutional entities, the structure must identify the source object represented by the event.

The approved source mappings are:

| Institution    | Event             | Source Entity |
| -------------- | ----------------- | ------------- |
| Ananse Telecom | Cash-in           | Transaction   |
| Ananse Telecom | Cash-out          | Transaction   |
| Ananse Telecom | P2P Transfer      | Transaction   |
| Ananse Telecom | Merchant Payment  | Transaction   |
| SikaCredit     | Loan Disbursement | Loan          |
| SikaCredit     | Loan Repayment    | Repayment     |
| Oman Remit     | Remittance        | Remittance    |

The combination:

```text
institution_id
source_entity
source_entity_id
```

provides the traceability context required to identify the originating source record.

The structure must not use a generic foreign key pretending that:

```text
source_entity_id
```

can directly reference multiple unrelated institutional tables.

Where the source object is polymorphic, the relationship is represented explicitly through the source identity attributes and controlled validation rather than through an artificial cross-domain foreign key.

---

# 8. Event Type

`event_type` identifies the authoritative financial event represented by the record.

The approved v1.0.0 event catalogue contains seven authoritative events:

| Institution    | Event Type        |
| -------------- | ----------------- |
| Ananse Telecom | Cash-in           |
| Ananse Telecom | Cash-out          |
| Ananse Telecom | P2P Transfer      |
| Ananse Telecom | Merchant Payment  |
| SikaCredit     | Loan Disbursement |
| SikaCredit     | Loan Repayment    |
| Oman Remit     | Remittance        |

The event type must remain controlled reference data.

The structure must not introduce:

```text
P2P Send
P2P Receive
```

as independent authoritative event types.

They are consequences / financial legs of:

```text
P2P Transfer
```

Likewise:

```text
Settlement
Correction
Reversal
Adjustment
```

are not approved v1.0.0 authoritative event types.

---

# 9. Event Outcome

`event_outcome` records the outcome associated with the financial event.

The approved outcome vocabulary is:

```text
Successful
Failed
Rejected
```

The financial-event structure records the outcome but does not attempt to implement the complete lifecycle-transition engine.

Detailed transaction lifecycle implementation belongs to **WP-2.5**.

The financial consequence relationship is:

```text
Successful
     ↓
May produce valid financial consequence

Failed / Rejected
     ↓
No valid financial consequence
     ↓
No financial-state transition
```

An unsuccessful event may nevertheless remain recorded because it is part of the observable financial activity and may have analytical significance.

---

# 10. Financial Consequence Structure

A financial event and its financial consequence are not the same thing.

The physical model therefore requires a separate consequence structure:

```text
ledger.financial_event
        │
        └── ledger.financial_consequence
```

The grain of:

```text
ledger.financial_consequence
```

is:

> **One row represents one financial consequence produced by one financial event.**

This is necessary because a single event may produce more than one financial consequence.

The clearest example is:

```text
P2P Transfer
      │
      ├── Sender Debit
      │
      └── Receiver Credit
```

The event remains one row in:

```text
ledger.financial_event
```

while its two consequences are represented separately.

---

# 11. Financial Consequence Attributes

The initial structure is:

| Attribute                  | Purpose                                                            |
| -------------------------- | ------------------------------------------------------------------ |
| `financial_consequence_id` | Unique identifier for the consequence                              |
| `financial_event_id`       | Identifies the originating financial event                         |
| `consequence_type`         | Identifies the financial effect                                    |
| `financial_object_type`    | Identifies the affected financial object                           |
| `financial_object_id`      | Identifies the affected financial object                           |
| `direction`                | Identifies whether value is credited or debited where applicable   |
| `amount`                   | Monetary amount of the consequence                                 |
| `currency`                 | Currency of the consequence                                        |
| `sequence_no`              | Orders multiple consequences belonging to one event where required |

The exact SQL Server types and constraints are deferred to WP-2.4.

---

# 12. Consequence Types

The approved financial consequences include:

| Event             | Consequence                             |
| ----------------- | --------------------------------------- |
| Cash-in           | Wallet Credit                           |
| Cash-out          | Wallet Debit                            |
| P2P Transfer      | Sender Debit                            |
| P2P Transfer      | Receiver Credit                         |
| Merchant Payment  | Wallet Debit                            |
| Loan Disbursement | Loan Principal Creation                 |
| Loan Repayment    | Loan Principal Reduction                |
| Remittance        | Beneficiary Financial Position Increase |

These consequences are derived from the reconciled event and state models.

A failed or rejected event does not generate a valid financial consequence.

---

# 13. Financial Object Boundary

The consequence structure must identify the financial object affected by the consequence without collapsing institutional ownership.

Examples:

```text
Cash-in
    ↓
Ananse Wallet
```

```text
Cash-out
    ↓
Ananse Wallet
```

```text
Loan Disbursement
    ↓
SikaCredit Loan Principal
```

```text
Loan Repayment
    ↓
SikaCredit Outstanding Principal
```

```text
Remittance
    ↓
Oman Remit Beneficiary Financial Position
```

The model must not interpret:

```text
Oman Remit Remittance
        ↓
Ananse Wallet
```

as an automatic financial consequence.

Likewise:

```text
SikaCredit Loan Disbursement
        ↓
Ananse Wallet
```

is not established merely through customer identity resolution.

Cross-domain analytical relationships remain separate from financial-state mutation.

---

# 14. P2P Transfer

P2P Transfer requires special treatment because it produces two financial consequences.

The physical representation is:

```text
financial_event
       │
       │ event_type = P2P Transfer
       │
       ├── financial_consequence
       │      └── Sender Debit
       │
       └── financial_consequence
              └── Receiver Credit
```

Therefore:

```text
1 P2P Transfer
        =
1 financial_event
        +
2 financial_consequences
```

This preserves the authoritative event catalogue while allowing both wallet positions to be represented accurately.

---

# 15. Relationship to Source Institutional Activity

The physical event structure does not replace source-domain records.

The relationship is:

```text
ananse.transaction
        │
        ↓
ledger.financial_event
```

```text
sikacredit.loan
        │
        ↓
ledger.financial_event
```

```text
sikacredit.repayment
        │
        ↓
ledger.financial_event
```

```text
oman_remit.remittance
        │
        ↓
ledger.financial_event
```

The source record remains the institutional activity.

The financial-event record is the controlled OCB financial representation of that activity.

This distinction is required to preserve:

* institutional ownership;
* source-system traceability;
* financial-event semantics;
* historical reconstruction;
* reconciliation.

---

# 16. Relationship to Ledger Entries

The financial event is upstream of the ledger.

The intended architecture is:

```text
Institutional Activity
        ↓
Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
        ↓
Financial State
```

Therefore:

```text
financial_event
        ≠
ledger_entry
```

and:

```text
financial_consequence
        ≠
ledger_entry
```

The ledger represents the accounting consequence of the financial event.

Detailed ledger structures, debit/credit semantics, reconciliation, and event-to-ledger traceability belong to **WP-2.3-T04** and the subsequent **WP-2.6 Ledger Architecture** work.

---

# 17. Relationship to Financial State

The financial-event structure must permit the resulting financial state to be explained.

The conceptual relationship is:

```text
Financial Event
      ↓
Financial Consequence
      ↓
Financial State
```

For example:

```text
Cash-in
   ↓
Wallet Credit
   ↓
Wallet Balance +
```

```text
Loan Disbursement
   ↓
Principal Creation
   ↓
Outstanding Principal +
```

```text
Loan Repayment
   ↓
Principal Reduction
   ↓
Outstanding Principal −
```

The physical event structure therefore supports state reconstruction but does not itself become the state.

---

# 18. Temporal Semantics

The financial-event structure must distinguish the authoritative event timestamp from platform processing timestamps.

At minimum:

```text
event_timestamp
```

represents:

> when the financial activity actually occurred according to the authoritative source.

It must not be confused with:

```text
recorded_at
```

which represents when the OCB financial representation was recorded.

Additional ingestion and processing timestamps may be introduced by the later ingestion and analytical architecture.

The governing distinction remains:

```text
Event Time
     ≠
Ingestion Time
     ≠
Processing Time
```

This is consistent with the platform's controlled time and event semantics.

---

# 19. Monetary Semantics

Where an event or consequence has monetary value, the structure must preserve:

```text
amount
currency
```

Amounts must use exact numeric representation in the eventual SQL Server implementation.

Approximate floating-point representation must not be used for financial amounts.

The exact precision and scale are deferred to physical implementation.

---

# 20. Failed and Rejected Events

Failed and rejected events remain financial-event records where they are observable within the approved boundary.

However:

```text
Failed / Rejected Event
        ↓
No Valid Financial Consequence
        ↓
No Financial-State Transition
```

Therefore the event table may contain:

```text
Successful
Failed
Rejected
```

while the consequence table contains only valid financial consequences.

This prevents the financial-event model from incorrectly treating attempted activity as completed financial activity.

---

# 21. Correction and Reversal Boundary

The event structure must preserve historical event identity.

It must not silently rewrite an already observed financial event to make the historical record appear as though the original event never occurred.

Correction, reversal, and adjustment semantics remain governed by the reconciled WP-1.3 decisions.

In particular:

```text
Original Event
      ↓
Historical Record
      ↓
Subsequent Corrective Information
```

rather than:

```text
Original Event
      ↓
Overwrite / Delete
```

No independent correction, reversal, or adjustment event structure is introduced by T03 unless a separately approved v1.0.0 requirement establishes one.

---

# 22. Controlled Event Vocabulary

The physical event structure must use controlled reference values for:

```text
institution
event_type
event_outcome
consequence_type
financial_object_type
currency
direction
```

Reference-data ownership belongs to the:

```text
ref
```

schema.

The actual reference structures will be defined in:

**WP-2.3-T05 — Define Reference Structures.**

T03 therefore defines the semantic requirement for controlled values without prematurely locking the physical reference-table implementation.

---

# 23. Physical Relationship Model

The resulting conceptual physical structure is:

```text
SOURCE INSTITUTIONAL RECORD
            │
            │
            ↓
ledger.financial_event
            │
            │ 1 : many
            ↓
ledger.financial_consequence
            │
            ↓
       ledger entries
            │
            ↓
   financial position/state
```

The cardinality between event and consequence is:

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

The one-to-many relationship is required for events such as:

```text
P2P Transfer
```

---

# 24. Event Structure Does Not Become a Generic Transaction Table

The financial-event structure must not be used as a replacement for:

```text
ananse.transaction
sikacredit.loan
sikacredit.repayment
oman_remit.remittance
```

Those tables retain their source-domain meaning.

The distinction is:

| Structure                      | Meaning                                                |
| ------------------------------ | ------------------------------------------------------ |
| `ananse.transaction`           | Ananse institutional transaction activity              |
| `sikacredit.loan`              | SikaCredit loan activity                               |
| `sikacredit.repayment`         | SikaCredit repayment activity                          |
| `oman_remit.remittance`        | Oman Remit remittance activity                         |
| `ledger.financial_event`       | OCB financial-event representation                     |
| `ledger.financial_consequence` | Financial effect produced by the event                 |
| `ledger.ledger_entry`          | Accounting representation of the financial consequence |

This separation prevents the financial core from absorbing institutional operational meaning.

---

# 25. Relationship to WP-2.3-T01 and T02

WP-2.3-T01 established:

```text
ledger
```

as the financial-core schema.

WP-2.3-T02 established the distinction between:

```text
institutional ownership
```

and:

```text
physical schema placement
```

T03 applies those decisions by placing the OCB financial-event representation within the financial core without transferring ownership of the originating institutional activity.

Therefore:

```text
ledger.financial_event
```

does not mean:

> "the ledger owns Ananse transactions."

It means:

> "the financial core contains OCB's controlled representation of material financial events."

---

# 26. Relationship to WP-2.3-T04

T03 deliberately stops before defining the detailed ledger structure.

T03 establishes:

```text
financial_event
        ↓
financial_consequence
```

T04 will establish:

```text
financial_consequence
        ↓
ledger_entry
```

including the detailed ledger structures required for accounting representation.

This separation prevents financial-event semantics and ledger implementation from being unnecessarily collapsed into one structure.

---

# 27. Relationship to WP-2.4

T03 defines the required physical structures and their semantic attributes.

It does **not** implement:

* SQL Server tables;
* primary keys;
* foreign keys;
* CHECK constraints;
* unique constraints;
* defaults;
* indexes;
* exact data types;
* exact precision and scale.

Those implementation concerns belong to **WP-2.4 — Physical Database Implementation**.

---

# 28. Final Financial Event Architecture

The approved T03 structure is:

```text
ledger
│
├── financial_event
│
└── financial_consequence
```

with the following relationship:

```text
financial_event
       │
       │ 1 : many
       ↓
financial_consequence
```

The complete financial flow is:

```text
SOURCE-OWNED ACTIVITY
        ↓
OCB FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
FINANCIAL STATE
```

This preserves the distinction between:

```text
what the institution recorded
        ↓
what financially occurred
        ↓
what accounting representation is produced
        ↓
what financial position becomes true
```

---

# 29. Decision

The OCB Platform v1.0.0 will implement the financial-event physical structure as:

```text
ledger.financial_event
ledger.financial_consequence
```

The authoritative design decisions are:

1. **One row in `ledger.financial_event` represents one OCB-recorded financial event.**

2. **One row in `ledger.financial_consequence` represents one financial consequence produced by an event.**

3. **A financial event may produce zero, one, or multiple financial consequences.**

4. **Failed and rejected events may exist as event records but produce no valid financial consequence.**

5. **P2P Transfer remains one authoritative event with separate sender-debit and receiver-credit consequences.**

6. **Source institutional records remain authoritative for their respective institutional activities.**

7. **The OCB financial-event structure preserves traceability to the source record without replacing it.**

8. **Financial events are physically located in the `ledger` financial-core schema but are not institutionally owned by the ledger schema.**

9. **Financial consequences are distinct from ledger entries.**

10. **Detailed ledger structures are deferred to WP-2.3-T04.**

11. **Physical SQL implementation is deferred to WP-2.4.**

12. **The structure must support financial-state reconstruction and reconciliation without creating cross-institution operational dependencies.**

---

# Core Principle

> **The financial-event structure records the OCB representation of what financially occurred; the financial-consequence structure records what changed financially; the ledger subsequently represents that consequence; and the resulting financial state records what is true. None of these structures replaces the source institution's authoritative operational activity.**
