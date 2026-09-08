# WP-2.3-T04 — Define Ledger Structures

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-2.3 — Operational Schema Design
**Ticket:** WP-2.3-T04
**Status:** **APPROVED**
**Decision Type:** Operational ledger structure definition

---

# 1. Purpose

This ticket defines the **physical-schema-level structure and responsibility of ledger objects** within the OCB Platform v1.0.0.

The purpose is to establish how valid financial consequences are represented within the `ledger` schema while preserving the distinction between:

* originating institutional financial activity;
* financial events;
* valid financial consequences;
* ledger postings;
* resulting financial state.

This ticket defines the **operational ledger structures required by the schema architecture**.

It does **not** implement the ledger posting engine or define the complete ledger-processing model.

Detailed ledger behaviour, posting rules, reconciliation, integrity controls, and processing mechanics belong to:

* **WP-2.6 — Ledger Architecture**; and
* **Programme 3 — Financial Transaction & Ledger Engine**.

The governing financial chain is:

```text
INSTITUTIONAL ACTIVITY
        ↓
FINANCIAL EVENT
        ↓
EVENT OUTCOME
        ↓
VALID FINANCIAL CONSEQUENCE
        ↓
LEDGER ENTRY
        ↓
FINANCIAL STATE
```

---

# 2. Ledger Architectural Role

The ledger provides the **accounting representation of valid financial consequences** produced by recognised financial events.

It does not replace the originating institutional activity.

For example:

```text
ananse.transaction
        ↓
Financial Event: Cash-in
        ↓
Valid Financial Consequence: Wallet Credit
        ↓
ledger.entry
        ↓
Wallet Financial Position
```

Likewise:

```text
sikacredit.loan
        ↓
Financial Event: Loan Disbursement
        ↓
Valid Financial Consequence: Loan Principal Creation
        ↓
ledger.entry
        ↓
Outstanding Principal
```

The distinction is therefore:

```text
Institutional Activity
        ↓
What the institution recorded

Financial Event
        ↓
What OCB recognised as a financial event

Financial Consequence
        ↓
What financially changed

Ledger Entry
        ↓
How that consequence is represented in the ledger

Financial State
        ↓
What financial position is subsequently true
```

None of these structures replaces the others.

---

# 3. Ledger Schema

The physical schema established in WP-2.3-T01 is:

```text
ledger
```

The `ledger` schema belongs to the **OCB Platform financial core**.

It is not institutionally owned by:

* Ananse Telecom;
* SikaCredit; or
* Oman Remit.

The ledger provides a common accounting representation for valid financial consequences arising from the approved institutional financial events.

The physical location of the ledger therefore represents **financial-core responsibility**, not ownership of the originating institutional activity.

---

# 4. Core Ledger Object

The principal operational ledger structure is:

```text
ledger.entry
```

One row represents:

> **One ledger posting representing one defined accounting consequence.**

The conceptual structure is:

```text
ledger.entry
─────────────────────────────
ledger_entry_id
financial_consequence_id
financial_event_id
transaction_reference
financial_object_type
financial_object_id
entry_type
amount
currency
entry_timestamp
```

The exact physical column definitions, data types, constraints, indexes, and implementation details are established during the relevant physical implementation and ledger-architecture work.

---

# 5. Ledger Entry Identity

Each ledger entry requires its own stable identifier:

```text
ledger_entry_id
```

The identifier uniquely identifies the **ledger posting**.

It must not be reused as:

```text
transaction_id
financial_event_id
financial_consequence_id
wallet_id
customer_id
loan_id
repayment_id
```

The identity hierarchy is:

```text
transaction_id
        ↓
Originating institutional activity

financial_event_id
        ↓
OCB financial-event identity

financial_consequence_id
        ↓
Specific financial effect

ledger_entry_id
        ↓
Accounting representation
```

This separation preserves independent identity while allowing complete traceability.

---

# 6. Financial Consequence Reference

Each ledger entry must retain a reference to the financial consequence it represents.

The relationship is:

```text
financial_event
        │
        │ 1 : many
        ↓
financial_consequence
        │
        │ 1 : many
        ↓
ledger.entry
```

This establishes an important architectural distinction:

> A financial consequence and a ledger entry are related objects and are not assumed to be the same object.

For the simple v1.0.0 cases, a financial consequence may produce a single ledger entry.

However, the physical model must not permanently assume that:

```text
1 financial consequence = exactly 1 ledger entry
```

because accounting representation may require more than one posting.

The approved structural relationship is therefore:

```text
1 financial consequence
        ↓
0..many ledger entries
```

where the zero case may be permitted during controlled processing states, while the final authoritative posting model is governed by WP-2.6 and Programme 3.

---

# 7. Financial Event Reference

A ledger entry must retain a reference to the recognised financial event that ultimately produced the ledger consequence.

Conceptually:

```text
financial_event
        ↓
financial_consequence
        ↓
ledger.entry
```

This permits investigation in both directions:

```text
Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
```

and:

```text
Ledger Entry
        ↓
Financial Consequence
        ↓
Financial Event
```

The financial-event reference therefore supports:

* event-to-ledger traceability;
* reconciliation;
* historical reconstruction;
* investigation;
* ledger integrity testing.

The ledger entry does not become the financial event merely because it references it.

---

# 8. Transaction Reference

Where the financial event originates from an operational transaction, the ledger entry may retain the relevant transaction reference.

Conceptually:

```text
Institutional Transaction
        ↓
Financial Event
        ↓
Financial Consequence
        ↓
Ledger Entry
```

This is applicable, for example, to Ananse transactions.

However, a transaction reference is **not universally applicable**.

For example:

```text
SikaCredit Loan
        ↓
Loan Disbursement Event
        ↓
Financial Consequence
        ↓
Ledger Entry
```

may not have an Ananse transaction identifier.

Therefore:

> `transaction_reference` is conditional and must not be treated as a universal ledger foreign key to `ananse.transaction`.

The ledger must support traceability without creating artificial cross-domain dependencies.

---

# 9. Financial Object Reference

A ledger entry must identify the financial object whose financial position is affected by the posting where such an object exists within the approved v1.0.0 model.

The conceptual structure is:

```text
ledger.entry
        ↓
financial_object_type
        ↓
financial_object_id
```

For wallet-affecting consequences:

```text
financial_object_type = Wallet
financial_object_id   = wallet_id
```

The wallet remains an **Ananse-owned financial object** even though it is physically located in the `wallet` schema.

The ledger therefore:

```text
represents the financial consequence
```

but does not:

```text
own the wallet
```

Similarly, a SikaCredit loan consequence may identify the relevant SikaCredit loan-related financial object without implying that the ledger owns the loan.

---

# 10. Financial Object Reference Is Conditional

Not every ledger entry necessarily affects the same type of financial object.

The physical structure must therefore avoid assuming that:

```text
wallet_id
```

is universally applicable.

The conceptual requirement is:

```text
financial_object_type
financial_object_id
```

rather than an unconditional wallet-specific reference.

Examples include:

```text
Wallet
    ↓
wallet_id
```

or:

```text
Loan
    ↓
loan_id
```

where supported by the approved financial model.

The precise supported object vocabulary is governed by the financial-state architecture and subsequent WP-2.6 decisions.

---

# 11. Debit and Credit Semantics

Ledger entries must distinguish the direction of the accounting posting.

The operational structure therefore requires an entry classification capable of representing:

```text
DEBIT
CREDIT
```

Conceptually:

```text
entry_type
──────────
DEBIT
CREDIT
```

The existence of the debit/credit classification is an operational structural requirement.

However, the complete accounting interpretation of debit and credit belongs to **WP-2.6 — Ledger Architecture**.

T04 therefore establishes the capability to represent both posting directions without prematurely defining the complete posting algorithm.

---

# 12. Monetary Value

Each ledger entry represents a defined monetary consequence.

The structure therefore requires:

```text
amount
currency
```

The amount must represent the monetary value of the specific ledger posting.

The currency identifies the denomination in which that value is expressed.

Financial amounts must use exact numeric representation in the eventual SQL Server implementation.

Approximate floating-point representation must not be used for authoritative monetary values.

Currency conversion is outside the scope of the ledger structure unless explicitly introduced by a later approved architecture.

---

# 13. Ledger Timestamp

Each ledger entry requires a timestamp representing its position within the authoritative financial-posting sequence.

Conceptually:

```text
event_timestamp
        ↓
When the source activity occurred

ledger_entry_timestamp
        ↓
When the financial consequence was posted
```

This must remain distinct from:

```text
event_timestamp
ingestion_timestamp
observation_timestamp
processing_timestamp
recorded_at
```

The distinction is necessary for:

* temporal reconstruction;
* reconciliation;
* processing-latency analysis;
* historical investigation.

The precise timestamp semantics and processing rules are governed by the subsequent ledger architecture.

---

# 14. Financial Event → Consequence → Ledger Relationship

The approved structural chain is:

```text
financial_event
        │
        │ 1 : many
        ↓
financial_consequence
        │
        │ 1 : many
        ↓
ledger.entry
```

Therefore:

```text
1 Financial Event
        ↓
0..many Financial Consequences
        ↓
0..many Ledger Entries
```

This provides sufficient structural flexibility without collapsing the three concepts.

A simple event may therefore produce:

```text
1 Event
   ↓
1 Consequence
   ↓
1 Ledger Entry
```

while a P2P transfer may produce:

```text
1 Event
   ↓
2 Consequences
   ↓
2 Ledger Entries
```

The architecture does not require the number of ledger entries to equal the number of financial consequences.

That relationship is determined by the accounting model.

---

# 15. P2P Transfer

P2P Transfer remains one authoritative financial event.

The event produces two financial consequences:

```text
P2P Transfer
      │
      ├── Sender Debit
      │
      └── Receiver Credit
```

These consequences may then produce corresponding ledger postings:

```text
P2P Transfer
      │
      ├── Sender Debit
      │       ↓
      │    ledger.entry
      │
      └── Receiver Credit
              ↓
           ledger.entry
```

Therefore:

```text
1 P2P Transfer
        ↓
2 Financial Consequences
        ↓
At least 2 corresponding ledger postings
```

The exact posting rules, balancing requirements, and accounting treatment are deferred to WP-2.6.

The critical principle remains:

> P2P Send and P2P Receive are not separate authoritative financial events.

---

# 16. Failed and Rejected Events

A failed or rejected financial event must not generate a valid authoritative financial consequence merely because the event record exists.

The relationship is:

```text
Financial Event
        ↓
Failed / Rejected
        ↓
No valid financial consequence
        ↓
No authoritative ledger posting
```

The failed or rejected event may remain recorded for:

* historical analysis;
* operational investigation;
* fraud and anomaly analysis;
* failure-rate measurement;
* reconciliation.

The ledger represents valid financial consequences, not every attempted activity.

---

# 17. Successful Events

A successful event may produce one or more valid financial consequences according to the approved event catalogue.

Conceptually:

```text
Successful Event
        ↓
Valid Financial Consequence
        ↓
Ledger Posting
```

However, successful status alone must not be interpreted as an unrestricted instruction to post.

The authoritative posting decision remains governed by the financial-event semantics and the ledger-posting architecture.

---

# 18. Ledger and Financial State

The ledger provides the accounting representation from which defined financial positions may be reconstructed or reconciled.

For example:

```text
Successful Cash-in
        ↓
Wallet Credit Consequence
        ↓
Credit Ledger Entry
        ↓
Wallet Financial Position
```

For cash-out:

```text
Successful Cash-out
        ↓
Wallet Debit Consequence
        ↓
Debit Ledger Entry
        ↓
Wallet Financial Position
```

For loan activity:

```text
Loan Disbursement
        ↓
Loan Principal Creation
        ↓
Ledger Posting
        ↓
Outstanding Principal
```

The distinction remains:

```text
Ledger Entry
        ≠
Financial Position
```

The ledger represents financial consequence.

The financial-state model represents the resulting position.

---

# 19. Ledger Does Not Become a Generic Transaction Table

The ledger must not be used as a replacement for institutional operational tables.

The distinction remains:

| Structure                      | Meaning                                                |
| ------------------------------ | ------------------------------------------------------ |
| `ananse.transaction`           | Ananse institutional transaction activity              |
| `sikacredit.loan`              | SikaCredit lending activity                            |
| `sikacredit.repayment`         | SikaCredit repayment activity                          |
| `oman_remit.remittance`        | Oman Remit remittance activity                         |
| `ledger.financial_event`       | OCB financial-event representation                     |
| `ledger.financial_consequence` | Financial effect produced by the event                 |
| `ledger.entry`                 | Accounting representation of the financial consequence |

The ledger therefore remains downstream of recognised financial activity.

---

# 20. Institutional Boundary

Ledger structures do not transfer institutional ownership.

For example:

```text
ANANSE
   │
   └── Transaction
          ↓
      Financial Event
          ↓
      Financial Consequence
          ↓
      Ledger Entry
```

The transaction remains Ananse-owned.

Likewise:

```text
ANANSE
   │
   └── Wallet
```

The wallet remains Ananse-owned even though it resides physically in:

```text
wallet
```

The ledger represents the financial consequence affecting that wallet but does not own the wallet.

Therefore:

```text
Physical Schema Placement
        ≠
Institutional Ownership
```

---

# 21. Ledger Authority Boundary

The ledger is authoritative **for the accounting representation of valid financial consequences within the OCB financial core**.

It is not authoritative for:

```text
Source institutional activity
```

which remains with the relevant institution.

It is not itself the authoritative representation of:

```text
Financial State
```

where the state model maintains the resulting position.

The authority model is therefore:

```text
Institutional Source
        ↓
Authoritative for source activity

OCB Financial Event
        ↓
Authoritative OCB representation of recognised financial event

Financial Consequence
        ↓
Authoritative representation of financial effect

Ledger
        ↓
Authoritative accounting representation of that effect

Financial State
        ↓
Authoritative resulting position within its defined state model
```

Each layer has a distinct responsibility.

---

# 22. Ledger Traceability

Every authoritative ledger posting must ultimately be explainable through the financial chain:

```text
SOURCE ACTIVITY
        ↓
FINANCIAL EVENT
        ↓
FINANCIAL CONSEQUENCE
        ↓
LEDGER ENTRY
        ↓
FINANCIAL STATE
```

This provides the foundation for:

* financial reconciliation;
* event-to-state reconstruction;
* transaction investigation;
* ledger integrity testing;
* regulatory evidence;
* historical reconstruction.

A ledger posting that cannot be explained through the approved financial-event and consequence chain represents a ledger-integrity problem.

---

# 23. Minimum Structural Requirements

The v1.0.0 ledger structure must support, at minimum:

| Requirement                                 | Purpose                                             |
| ------------------------------------------- | --------------------------------------------------- |
| `ledger_entry_id`                           | Unique ledger-entry identity                        |
| `financial_consequence_id`                  | Identify the consequence represented by the posting |
| `financial_event_id`                        | Trace the posting to the recognised financial event |
| Transaction reference where applicable      | Trace to originating operational transaction        |
| Financial-object reference where applicable | Identify the affected financial object              |
| Debit/credit classification                 | Represent posting direction                         |
| Amount                                      | Represent monetary value                            |
| Currency                                    | Identify monetary denomination                      |
| Ledger timestamp                            | Preserve posting chronology                         |

Additional attributes may be introduced where justified by:

* reconciliation;
* provenance;
* integrity controls;
* auditability;
* ledger processing requirements.

Such additions must not contradict the approved responsibility boundaries.

---

# 24. Relationship to WP-2.3-T03

WP-2.3-T03 establishes:

```text
ledger.financial_event
ledger.financial_consequence
```

This ticket establishes:

```text
ledger.entry
```

The resulting relationship is:

```text
Financial Event
      │
      │ 1 : many
      ↓
Financial Consequence
      │
      │ 1 : many
      ↓
Ledger Entry
```

The three structures remain distinct.

A financial event records the recognised financial activity.

A financial consequence records what financially changed.

A ledger entry records the accounting representation of that change.

---

# 25. Relationship to WP-2.6

T04 does **not** replace WP-2.6.

T04 establishes the operational schema boundary and minimum ledger structure.

WP-2.6 will establish the complete ledger architecture, including:

* authoritative ledger behaviour;
* debit/credit semantics;
* posting rules;
* event-to-ledger linkage;
* consequence-to-ledger linkage;
* ledger balancing;
* reconciliation;
* ledger integrity;
* temporal ordering;
* event-to-state traceability.

The architectural progression is:

```text
WP-2.3-T04
LEDGER STRUCTURE
        ↓
WP-2.6
LEDGER ARCHITECTURE
        ↓
PROGRAMME 3
LEDGER POSTING ENGINE
```

---

# 26. v1.0.0 Boundary

The v1.0.0 ledger structure does not introduce:

* institutional internal ledgers;
* correspondent accounts;
* settlement accounts;
* bank accounts;
* escrow structures;
* external payment-rail ledgers;
* SWIFT structures;
* real-time ledger streaming;
* external accounting integrations;
* general-purpose accounting modules.

The ledger represents only the financial consequences required by the approved OCB v1.0.0 financial model.

---

# 27. Resulting Operational Schema Architecture

The resulting architecture is:

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
    └── [defined in T05]
```

The core financial relationship is:

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

---

# 28. Decision

The OCB Platform v1.0.0 will maintain a dedicated:

```text
ledger
```

schema containing the operational financial-core structures:

```text
ledger.financial_event
ledger.financial_consequence
ledger.entry
```

The ledger entry will provide a distinct accounting representation of valid financial consequences.

The ledger structure will maintain traceability to:

* the originating financial event;
* the financial consequence represented by the posting;
* the originating transaction where applicable;
* the affected financial object where applicable.

The ledger will support:

* debit and credit representation;
* monetary value;
* currency;
* posting chronology;
* financial-object identification;
* event and consequence traceability.

The ledger will not replace:

* institutional activity;
* financial events;
* financial consequences; or
* financial-state structures.

The approved cardinality is:

```text
Financial Event
      ↓ 0..many
Financial Consequence
      ↓ 0..many
Ledger Entry
```

with the final posting requirements and validity rules governed by WP-2.6 and Programme 3.

Detailed ledger behaviour, reconciliation, integrity, and posting mechanics remain outside T04.

---

# 29. Core Principle

> **The ledger records the accounting representation of a valid financial consequence. It does not become the originating institutional activity, the financial event, the financial consequence itself, or the resulting financial position. Every authoritative ledger posting must remain traceable through the financial chain that explains why the posting exists and what financial state it affects.**
