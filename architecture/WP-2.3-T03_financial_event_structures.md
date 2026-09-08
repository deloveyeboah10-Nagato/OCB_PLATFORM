# WP-2.3-T03 — Define Financial Event Structures

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T03
**Status:** **REVISED / APPROVED**
**Decision Type:** Financial-event physical structure definition

---

# 1. Purpose

This ticket defines the financial-event structures required by the OCB Platform v1.0.0.

The purpose is to translate the approved financial-event semantics into physical structures that can represent:

* recognised financial events;
* their source-system identity;
* event type;
* event timing;
* event outcome;
* valid financial consequences;
* affected financial objects;
* monetary consequences;
* traceability into the ledger.

The structure preserves the distinction between:

```text
SOURCE-OWNED INSTITUTIONAL ACTIVITY
              ↓
       OCB FINANCIAL EVENT
              ↓
     FINANCIAL CONSEQUENCE
              ↓
          LEDGER ENTRY
              ↓
       FINANCIAL STATE
```

The financial-event structure does **not** replace the originating institutional record.

---

# 2. Governing Design Principle

A financial event is the OCB financial representation of an approved observable financial activity.

It is distinct from:

```text
source institutional activity
```

and from:

```text
ledger posting
```

The governing model is:

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

For example:

```text
ananse.transaction
        ↓
Cash-in
        ↓
Wallet Credit
        ↓
ledger.entry
        ↓
Wallet Position
```

Similarly:

```text
sikacredit.loan
        ↓
Loan Disbursement
        ↓
Loan Principal Creation
        ↓
ledger.entry
        ↓
Outstanding Loan Position
```

The source institution remains authoritative for the originating institutional activity.

---

# 3. Physical Location

Financial-event structures belong to the OCB Platform financial core and are physically located within:

```text
ledger
```

The financial-event structures are therefore:

```text
ledger.financial_event

ledger.financial_consequence
```

The ledger schema is a physical financial-core boundary.

It does not become the owner of:

```text
ananse.transaction
sikacredit.loan
sikacredit.repayment
oman_remit.remittance
```

This preserves the ownership distinction established in WP-2.3-T01 and T02. 

---

# 4. Financial Event Grain

The grain of:

```text
ledger.financial_event
```

is:

> **One row represents one OCB-recorded financial event.**

Therefore:

```text
1 financial event
        =
1 financial_event row
```

Multiple financial consequences do not create multiple financial events.

For example:

```text
P2P Transfer
      │
      ├── Sender Debit
      └── Receiver Credit
```

remains:

```text
1 financial_event
+
2 financial_consequences
```

---

# 5. Physical Financial Event Structure

The implemented structure is:

```text
ledger.financial_event
```

with the following attributes:

| Attribute            | Purpose                                                        |
| -------------------- | -------------------------------------------------------------- |
| `financial_event_id` | Unique OCB identifier for the financial event                  |
| `source_entity`      | Identifies the source-domain entity represented by the event   |
| `source_event_id`    | Identifies the specific source record represented by the event |
| `event_type`         | Identifies the approved financial event                        |
| `event_timestamp`    | Time at which the source financial activity occurred           |
| `event_status`       | Outcome/status of the recognised financial event               |

The deployed SQL structure confirms these columns and their implementation. 

The physical implementation uses:

```text
financial_event_id BIGINT
source_entity      NVARCHAR(50)
source_event_id    VARCHAR(100)
event_type         VARCHAR(100)
event_timestamp    DATETIME2(3)
event_status       VARCHAR(100)
```

The exact physical implementation is documented in WP-2.4; this ticket establishes the operational structure and semantics.

---

# 6. Event Identity

`financial_event_id` is the OCB identifier for the financial-event record.

It does not replace the source-system identifier.

The identity chain is:

```text
financial_event_id
        ↓
OCB financial-event identity

source_entity + source_event_id
        ↓
originating institutional record
```

For example:

```text
financial_event_id = 1000001

source_entity = TRANSACTION
source_event_id = AN-TXN-000001
```

The OCB event and the institutional transaction therefore remain separate identifiers.

---

# 7. Source Record Representation

The financial-event structure deliberately does **not** use a generic polymorphic foreign key.

Instead, the source relationship is represented by:

```text
source_entity
source_event_id
```

This is necessary because approved events originate from different source structures.

| Institution    | Event             | Source Entity |
| -------------- | ----------------- | ------------- |
| Ananse Telecom | Cash-in           | Transaction   |
| Ananse Telecom | Cash-out          | Transaction   |
| Ananse Telecom | P2P Transfer      | Transaction   |
| Ananse Telecom | Merchant Payment  | Transaction   |
| SikaCredit     | Loan Disbursement | Loan          |
| SikaCredit     | Loan Repayment    | Repayment     |
| Oman Remit     | Remittance        | Remittance    |

Thus:

```text
source_entity
+
source_event_id
```

provides the source identity context without pretending that one SQL foreign key can reference multiple unrelated tables.

---

# 8. Institution Identification

No separate `institution_id` column is implemented in `ledger.financial_event`.

The originating institutional context is represented through the controlled relationship between:

```text
source_entity
source_event_id
```

and the approved source-domain structures.

Therefore T03 does **not** require an unimplemented `institution_id` attribute.

This keeps the logical requirement aligned with the actual physical deployment rather than introducing a redundant physical identifier.

---

# 9. Approved Event Types

The v1.0.0 authoritative event catalogue remains:

| Institution    | Event Type        |
| -------------- | ----------------- |
| Ananse Telecom | Cash-in           |
| Ananse Telecom | Cash-out          |
| Ananse Telecom | P2P Transfer      |
| Ananse Telecom | Merchant Payment  |
| SikaCredit     | Loan Disbursement |
| SikaCredit     | Loan Repayment    |
| Oman Remit     | Remittance        |

The event table therefore represents **seven authoritative financial events**.

The following are not independent authoritative event types:

```text
P2P Send
P2P Receive
Settlement
Correction
Reversal
Adjustment
```

P2P Send and P2P Receive are consequences/event legs of:

```text
P2P Transfer
```

This remains consistent with the approved event model. 

---

# 10. Event Status

The physical implementation uses:

```text
event_status
```

rather than the previously proposed:

```text
event_outcome
```

The semantic purpose remains the same: recording the outcome/status of the recognised financial event.

The approved outcome vocabulary is:

```text
Successful
Failed
Rejected
```

Detailed lifecycle semantics remain within WP-2.5.

The important financial rule is:

```text
Successful
    ↓
May produce valid financial consequence
```

whereas:

```text
Failed / Rejected
    ↓
No valid financial consequence
```

unless a separately approved rule establishes otherwise.

Failed and rejected events remain observable records and may therefore be retained for analytical purposes. 

---

# 11. Monetary Attributes Belong to the Consequence

The deployed model does **not** place:

```text
amount
currency
```

in `ledger.financial_event`.

This is deliberate.

The financial event identifies **what occurred**.

The financial consequence identifies **what financial effect resulted**.

Therefore:

```text
ledger.financial_event
    ↓
what occurred
```

while:

```text
ledger.financial_consequence
    ↓
amount
currency
financial effect
affected financial object
```

This avoids unnecessarily duplicating monetary values when one event can produce multiple financial consequences.

---

# 12. Financial Consequence Structure

The second physical structure is:

```text
ledger.financial_consequence
```

Its grain is:

> **One row represents one financial consequence produced by one financial event.**

Therefore:

```text
1 financial event
        ↓
0..N financial consequences
```

This supports:

```text
Cash-in
    ↓
1 wallet credit consequence
```

and:

```text
P2P Transfer
    ↓
2 consequences
    ├── sender debit
    └── receiver credit
```

The deployed table contains:

```text
financial_consequence_id
financial_event_id
consequence_type
amount
currency
wallet_id
customer_id
```

as confirmed by the physical deployment. 

---

# 13. Financial Consequence Attributes

The authoritative operational structure is:

| Attribute                  | Purpose                                           |
| -------------------------- | ------------------------------------------------- |
| `financial_consequence_id` | Unique consequence identifier                     |
| `financial_event_id`       | Identifies the originating financial event        |
| `consequence_type`         | Identifies the resulting financial effect         |
| `amount`                   | Monetary magnitude of the consequence             |
| `currency`                 | Currency of the consequence                       |
| `wallet_id`                | Identifies the affected wallet where applicable   |
| `customer_id`              | Identifies the affected customer where applicable |

The actual SQL implementation confirms that `wallet_id` and `customer_id` are the physical financial-object references used by the current model. 

---

# 14. Financial Object Representation

The revised physical model does **not** introduce generic:

```text
financial_object_type
financial_object_id
```

columns.

Instead, the current v1.0.0 structure explicitly represents the relevant objects through:

```text
wallet_id
customer_id
```

This is a significant physical-model clarification.

For wallet-affecting consequences:

```text
financial_consequence
        ↓
wallet_id
        ↓
wallet.wallet
```

The wallet itself remains an Ananse-owned financial object even though it physically resides in the separate `wallet` schema.

The existing physical FK architecture confirms the wallet as a relational object referenced by Ananse transaction activity. 

---

# 15. Consequence Types

The approved consequence vocabulary remains:

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

These represent financial effects, not independent authoritative events.

---

# 16. P2P Transfer

P2P Transfer remains one authoritative financial event.

Its consequences are represented independently:

```text
ledger.financial_event
        │
        │ P2P Transfer
        │
        ├── financial_consequence
        │       └── Sender Debit
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

The separate consequences allow the affected wallets to be represented independently while preserving their common event identity.

---

# 17. Direction Is Not Stored in the Consequence

The physical deployment does **not** include a:

```text
direction
```

column in `ledger.financial_consequence`.

This is consistent with the approved Model A monetary representation.

Financial amounts are stored as non-negative magnitudes:

```text
amount >= 0
```

while debit/credit direction is represented at the ledger-entry level through:

```text
entry_type
```

For example:

```text
entry_type = DEBIT
amount     = 500.00
```

rather than:

```text
amount = -500.00
```

The implemented database explicitly enforces non-negative financial-consequence and ledger-entry amounts. 

Therefore T03 must not introduce a separate consequence-level `direction` field.

---

# 18. Sequence Number

The previously proposed:

```text
sequence_no
```

is not part of the implemented `ledger.financial_consequence` structure.

It is therefore **not an authoritative T03 physical attribute**.

Ordering of ledger consequences or entries, where required, is handled by the relevant identifiers and timestamps and by the later ledger architecture.

No `sequence_no` column is introduced by T03.

---

# 19. Relationship Between Event and Consequence

The authoritative relationship is:

```text
ledger.financial_event
        │
        │ 1 : 0..N
        ↓
ledger.financial_consequence
```

The zero side is important.

A financial event may exist without a valid financial consequence when:

```text
event_status = Failed
```

or:

```text
event_status = Rejected
```

A successful event may produce one or multiple consequences depending on the approved event semantics.

---

# 20. Relationship to Ledger Entry

The financial consequence is upstream of the ledger entry.

The complete structure is:

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

The physical ledger object is:

```text
ledger.entry
```

not:

```text
ledger.ledger_entry
```

The deployed structure uses:

```text
ledger.entry
```

with:

```text
ledger_entry_id
financial_consequence_id
financial_event_id
transaction_id
wallet_id
account_reference
entry_type
amount
currency
entry_timestamp
```



Therefore:

```text
financial_event
    ≠
financial_consequence
    ≠
ledger.entry
```

---

# 21. Event-to-Ledger Traceability

The physical model provides two levels of traceability.

First:

```text
financial_consequence
        ↓
financial_event
```

through:

```text
financial_event_id
```

Second:

```text
ledger.entry
        ↓
financial_consequence
```

through:

```text
financial_consequence_id
```

The deployed ledger entry also retains:

```text
financial_event_id
```

directly, providing an additional event-level traceability path. 

This supports:

* reconciliation;
* investigation;
* event-to-ledger tracing;
* financial-state reconstruction;
* historical analysis.

---

# 22. Relationship to Source Institutional Activity

The source records remain authoritative for their institutional activity.

The mapping is conceptually:

```text
ananse.transaction
        ↓
ledger.financial_event
```

```text
sikacredit.loan
        ↓
ledger.financial_event
```

```text
sikacredit.repayment
        ↓
ledger.financial_event
```

```text
oman_remit.remittance
        ↓
ledger.financial_event
```

The source identifier is retained through:

```text
source_entity
source_event_id
```

This permits the OCB representation to be traced back to the originating institutional record without replacing it.

---

# 23. Financial-State Boundary

The financial-event and consequence structures do not themselves become the financial state.

The conceptual flow remains:

```text
Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
        ↓
Financial State
```

For example:

```text
Cash-in
   ↓
Wallet Credit
   ↓
Ledger Credit
   ↓
Wallet Position +
```

and:

```text
Loan Repayment
   ↓
Loan Principal Reduction
   ↓
Ledger Representation
   ↓
Outstanding Principal −
```

The ledger therefore remains an intermediate authoritative representation of financial consequence rather than the financial state itself. 

---

# 24. Failed and Rejected Events

The physical model permits the financial-event table to retain:

```text
Successful
Failed
Rejected
```

while valid financial consequences represent only financially effective outcomes.

Therefore:

```text
Failed Event
      ↓
Financial Event Record
      ↓
No Valid Consequence
      ↓
No Authoritative Financial-State Change
```

This preserves attempted activity for intelligence without incorrectly treating unsuccessful activity as completed financial activity. 

---

# 25. Correction, Reversal and Adjustment

T03 does not introduce separate:

```text
Correction
Reversal
Adjustment
Settlement
```

event types.

The v1.0.0 architecture deliberately does not invent unobserved institutional processing structures.

Historical events must not be silently overwritten.

Where future corrective architecture is required, it must preserve:

```text
Original Event
        ↓
Original Consequence
        ↓
Subsequent Corrective Information
```

rather than rewriting the original event.

The detailed lifecycle treatment remains within WP-2.5 and later ledger architecture.

---

# 26. Controlled Values

The following concepts require controlled vocabularies:

```text
source_entity
event_type
event_status
consequence_type
currency
entry_type
```

Reference-data ownership belongs to:

```text
ref
```

The detailed reference structures are handled by WP-2.3-T05.

T03 therefore establishes the semantic requirement without duplicating the reference-data implementation.

---

# 27. Monetary Semantics

Financial amounts use exact numeric representation.

The physical implementation uses:

```text
DECIMAL(18,4)
```

for:

```text
ledger.financial_consequence.amount
ledger.entry.amount
```

The database enforces:

```text
amount >= 0
```

for both structures. 

Financial direction is represented separately through ledger-entry classification.

Therefore:

```text
amount
```

represents magnitude, while:

```text
entry_type
```

represents debit/credit classification.

---

# 28. Temporal Semantics

The financial event uses:

```text
event_timestamp
```

to represent when the underlying financial activity occurred.

The ledger uses:

```text
entry_timestamp
```

to represent the ledger posting chronology.

These are distinct concepts.

Therefore:

```text
event_timestamp
        ≠
entry_timestamp
```

The platform retains the distinction between:

```text
Event Time
      ↓
Ledger Posting Time
```

and does not treat the two timestamps as interchangeable.

`DATETIME2(3)` is the established OCB v1.0.0 timestamp standard where millisecond precision is sufficient. 

---

# 29. Physical Structure Summary

The authoritative T03 structures are:

```text
ledger
│
├── financial_event
│
├── financial_consequence
│
└── entry
```

The relationships are:

```text
financial_event
       │
       │ 1 : 0..N
       ↓
financial_consequence
       │
       │
       ↓
ledger.entry
```

with event-level traceability:

```text
ledger.entry
       │
       ├── financial_consequence_id
       │
       └── financial_event_id
```

---

# 30. T03 vs Physical Deployment

The following reconciliation is authoritative:

| Concept                     | T03 physical model         |
| --------------------------- | -------------------------- |
| Event identifier            | `financial_event_id`       |
| Source entity               | `source_entity`            |
| Source record identifier    | `source_event_id`          |
| Event type                  | `event_type`               |
| Event timestamp             | `event_timestamp`          |
| Event outcome               | `event_status`             |
| Consequence identifier      | `financial_consequence_id` |
| Consequence event reference | `financial_event_id`       |
| Consequence type            | `consequence_type`         |
| Consequence amount          | `amount`                   |
| Consequence currency        | `currency`                 |
| Affected wallet             | `wallet_id`                |
| Affected customer           | `customer_id`              |
| Ledger object               | `ledger.entry`             |
| Ledger identifier           | `ledger_entry_id`          |
| Ledger direction            | `entry_type`               |

This is the structure actually reflected in the deployed database. 

---

# 31. Explicitly Excluded From T03

The following attributes are **not** part of the authoritative physical T03 structure:

```text
institution_id
actor_reference
reference_value
recorded_at
financial_object_type
financial_object_id
direction
sequence_no
```

They are not to be added merely because they may appear conceptually useful.

This is an important correction to the earlier version of T03.

The physical model should reflect **approved requirements and actual implementation**, not accumulate speculative metadata.

---

# 32. Relationship to WP-2.3-T01 and T02

T01 established:

```text
ledger
```

as the financial-core schema.

T02 established the distinction between:

```text
institutional ownership
```

and:

```text
physical schema placement
```

T03 therefore places the OCB financial-event representation within:

```text
ledger
```

without transferring ownership of the source activity.

The resulting distinction is:

```text
Institution
    ↓
owns source activity

OCB Financial Core
    ↓
represents recognised financial consequences
```

This preserves the architectural boundary established by the preceding tickets. 

---

# 33. Relationship to WP-2.3-T04

T03 establishes:

```text
financial_event
        ↓
financial_consequence
```

T04 establishes the ledger posting structure:

```text
financial_consequence
        ↓
ledger.entry
```

The two concerns remain separate.

A financial event answers:

> **What financial activity was recognised?**

A financial consequence answers:

> **What financial effect resulted?**

A ledger entry answers:

> **How was that financial consequence represented as an accounting posting?**

This separation is consistent with the existing WP-2.3 ledger architecture. 

---

# 34. Relationship to WP-2.4

WP-2.4 implements the physical database structures.

T03 establishes the operational structure and semantics.

The actual implementation has now been reconciled as:

```text
ledger.financial_event
ledger.financial_consequence
ledger.entry
```

with the physical definitions established by the deployment script. 

T03 therefore does not introduce additional implementation requirements that are absent from the deployed database.

---

# 35. Final Financial Event Architecture

The authoritative v1.0.0 financial-event architecture is:

```text
SOURCE-OWNED ACTIVITY
        │
        ↓
ledger.financial_event
        │
        │ 1 : 0..N
        ↓
ledger.financial_consequence
        │
        ↓
ledger.entry
        │
        ↓
FINANCIAL STATE
```

The semantic distinction is:

```text
Source Activity
    = what the institution recorded

Financial Event
    = what OCB recognised as a financial event

Financial Consequence
    = what financially resulted

Ledger Entry
    = accounting representation of that consequence

Financial State
    = what financial position subsequently becomes true
```

---

# 36. Final Decision

The OCB Platform v1.0.0 will use:

```text
ledger.financial_event
ledger.financial_consequence
ledger.entry
```

as the operational financial-event and ledger chain.

The authoritative decisions are:

1. **One row in `ledger.financial_event` represents one OCB-recorded financial event.**

2. **`financial_event_id` identifies the OCB financial event and does not replace the source-system identifier.**

3. **Source traceability is represented through `source_entity` and `source_event_id`.**

4. **The seven approved v1.0.0 financial events remain the authoritative event catalogue.**

5. **`event_status` records the event outcome/status.**

6. **A financial event may produce zero, one, or multiple financial consequences.**

7. **Failed and rejected events may remain recorded but do not produce valid financial consequences under the normal v1.0.0 rule.**

8. **P2P Transfer remains one financial event with separate sender-debit and receiver-credit consequences.**

9. **Financial consequence monetary values are represented through `amount` and `currency`.**

10. **Affected financial objects are represented through the implemented `wallet_id` and `customer_id` references rather than a generic polymorphic financial-object pair.**

11. **Financial direction is not stored as a consequence-level `direction` attribute; ledger debit/credit classification is represented through `ledger.entry.entry_type`.**

12. **Financial amounts are represented as non-negative magnitudes.**

13. **Financial consequences remain distinct from ledger entries.**

14. **The physical ledger object is `ledger.entry`.**

15. **Ledger entries retain traceability to both the financial consequence and financial event.**

16. **The financial-event structures remain physically located in the `ledger` schema without transferring ownership of source institutional activity.**

17. **No speculative attributes such as `institution_id`, `recorded_at`, `sequence_no`, or generic `financial_object_type` are introduced.**

18. **Detailed ledger behaviour remains subject to WP-2.6 and subsequent financial-processing architecture.**

---

# Core Principle

> **The source institution remains authoritative for its operational activity; `ledger.financial_event` records OCB's recognised financial event; `ledger.financial_consequence` records the resulting financial effect and affected financial object; `ledger.entry` represents the accounting posting; and the resulting financial state remains a separate concept.**

**WP-2.3-T03 — REVISED.**
