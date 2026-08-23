# WP-2.3-T04 — Define Ledger Structures

**Programme:** OCB Platform v1.0.0

**Work Package:** WP-2.3 — Operational Schema Design

**Ticket:** WP-2.3-T04

**Status:** **APPROVED**

**Decision Type:** Operational ledger structure definition

---

# 1. Purpose

This ticket defines the **physical-schema-level structure and responsibility of ledger objects** within the OCB Platform v1.0.0.

The purpose is to establish how financial consequences are represented within the `ledger` schema while preserving the distinction between:

* originating institutional financial activity;
* financial events;
* valid financial consequences;
* ledger postings;
* resulting financial state.

This ticket defines the **ledger data structures required by the operational schema architecture**.

It does **not** implement the ledger or define the complete financial posting engine.

Detailed ledger processing belongs to **WP-2.6 — Ledger Architecture** and **Programme 3 — Financial Transaction & Ledger Engine**.

---

# 2. Ledger Architectural Role

The ledger is the financial-accounting representation of valid financial consequences.

The governing flow is:

```text
INSTITUTIONAL ACTIVITY
        ↓
FINANCIAL EVENT
        ↓
EVENT OUTCOME
        ↓
VALID FINANCIAL CONSEQUENCE
        ↓
LEDGER POSTING
        ↓
FINANCIAL STATE
```

The ledger therefore does not replace the originating event.

For example:

```text
ananse.transaction
        ↓
Cash-in
        ↓
Successful financial consequence
        ↓
ledger.entry
        ↓
Wallet credit
```

The originating transaction and the resulting ledger representation remain distinct objects.

---

# 3. Ledger Schema

The physical schema established in WP-2.3-T01 is:

```text
ledger
```

The schema is owned by the **OCB Platform financial core**.

It is not owned by Ananse Telecom, SikaCredit, or Oman Remit.

The ledger provides a common accounting representation for financial consequences originating from the approved institutional financial events.

---

# 4. Core Ledger Object

The primary operational ledger structure is:

```text
ledger.entry
```

Conceptually:

```text
ledger.entry
-------------------------
ledger_entry_id
event_reference
transaction_reference
wallet_reference
account_reference
entry_type
amount
currency
entry_timestamp
```

The exact physical column definitions, data types, constraints, and implementation details are established through the subsequent physical implementation and ledger-architecture work.

---

# 5. Ledger Entry Identity

Each ledger entry requires its own identifier:

```text
ledger_entry_id
```

The ledger-entry identifier identifies the **accounting representation**.

It must not be reused as:

```text
transaction_id
event_id
wallet_id
customer_id
```

The distinction is:

```text
transaction_id
        ↓
identifies originating transaction

event_id
        ↓
identifies financial event

ledger_entry_id
        ↓
identifies ledger posting
```

This preserves traceability without collapsing distinct financial objects.

---

# 6. Financial Event Reference

A ledger entry must retain a reference to the financial event that produced the financial consequence.

Conceptually:

```text
financial_event
       │
       │ produces
       ↓
ledger.entry
```

The ledger therefore requires an event reference capable of answering:

> **Which recognised financial event produced this ledger consequence?**

This is essential for event-to-ledger traceability and later reconciliation.

The event reference must not be interpreted as making the ledger entry the event itself.

---

# 7. Transaction Reference

Where the originating financial event is associated with an operational transaction, the ledger entry must retain the relevant transaction reference.

Conceptually:

```text
transaction
     ↓
financial event
     ↓
ledger entry
```

This permits investigation from:

```text
Transaction
    ↓
Event
    ↓
Ledger Consequence
```

and, where required:

```text
Ledger Consequence
    ↓
Event
    ↓
Originating Transaction
```

The transaction reference therefore supports traceability rather than ownership transfer.

---

# 8. Financial Object Reference

The ledger entry must identify the financial object whose position is affected by the posting.

For v1.0.0, the principal observable financial object is the Ananse wallet.

Conceptually:

```text
ledger.entry
      ↓
affected financial object
      ↓
wallet.wallet
```

The ledger structure therefore requires an appropriate financial-object reference.

For wallet-affecting entries:

```text
ledger.entry
      ↓
wallet_id
```

The ledger does not become the owner of the wallet.

The ownership relationship remains:

```text
ANANSE
   ↓
WALLET

LEDGER
   ↓
REPRESENTS FINANCIAL CONSEQUENCE
```

---

# 9. Debit and Credit Semantics

Ledger entries must distinguish the direction of the financial posting.

The operational structure therefore requires an entry classification capable of representing:

```text
DEBIT
CREDIT
```

Conceptually:

```text
entry_type
-----------
DEBIT
CREDIT
```

The interpretation of debit and credit is determined by the financial-accounting model established in WP-2.6.

This ticket establishes that the ledger must be capable of representing both sides of financial consequences where required.

It does not yet prescribe the complete posting algorithm.

---

# 10. Monetary Value

Each ledger entry represents a defined monetary consequence.

The structure therefore requires:

```text
amount
currency
```

The amount must represent the monetary value of the specific ledger consequence.

The currency identifies the monetary denomination in which that value is expressed.

The ledger must not silently convert amounts into another currency merely because analytical processing may later require a common reporting currency.

Currency conversion rules belong to the relevant financial-event and analytical architecture.

---

# 11. Timestamp

Each ledger entry requires a timestamp representing when the ledger consequence is established within the authoritative financial processing sequence.

This must remain distinct from:

```text
event_timestamp
ingestion_timestamp
observation_timestamp
processing_timestamp
```

Conceptually:

```text
EVENT TIMESTAMP
      ↓
when the source event occurred

LEDGER TIMESTAMP
      ↓
when its financial consequence was posted
```

The distinction is necessary for temporal reconstruction and reconciliation.

---

# 12. Ledger and Financial State

The ledger provides the authoritative financial-consequence record from which defined financial positions can be reconstructed or reconciled.

For example:

```text
Successful Cash-in
        ↓
Credit ledger entry
        ↓
Wallet financial consequence
        ↓
Wallet position
```

For a debit:

```text
Successful Cash-out
        ↓
Debit ledger entry
        ↓
Wallet financial consequence
        ↓
Wallet position
```

The ledger therefore participates in:

```text
EVENT
  ↓
CONSEQUENCE
  ↓
LEDGER
  ↓
STATE
```

It does not replace the financial-state representation itself.

---

# 13. P2P Transfer

P2P Transfer requires particular treatment.

The authoritative business event remains:

```text
P2P Transfer
```

It produces two financial consequences:

```text
P2P Transfer
      │
      ├── Sender consequence
      │       ↓
      │     DEBIT
      │
      └── Receiver consequence
              ↓
            CREDIT
```

The ledger must therefore permit both consequences to be represented while maintaining their relationship to the **same authoritative P2P Transfer event**.

Conceptually:

```text
P2P Transfer
     │
     ├───────────────┐
     ↓               ↓
ledger.entry      ledger.entry
DEBIT             CREDIT
sender wallet     receiver wallet
```

This preserves the event-level semantics established in WP-1.3 and WP-2.1.

---

# 14. Failed Events

A failed or rejected financial event must not generate a valid financial consequence merely because an event record exists.

Therefore:

```text
Financial Event
      ↓
Failed / Rejected
      ↓
No valid financial consequence
      ↓
No authoritative financial posting
```

The event remains available for historical and analytical purposes.

The ledger must represent **financial consequences**, not every attempted activity.

This is consistent with the state model:

> Failed financial activity does not alter authoritative financial position where no valid financial consequence exists.

---

# 15. Ledger Traceability

The ledger structure must support traceability across the financial chain:

```text
SOURCE ACTIVITY
      ↓
FINANCIAL EVENT
      ↓
EVENT OUTCOME
      ↓
FINANCIAL CONSEQUENCE
      ↓
LEDGER ENTRY
      ↓
FINANCIAL STATE
```

A material ledger posting must therefore be explainable back to its originating financial event.

This establishes the foundation for:

* financial reconciliation;
* event-to-state reconstruction;
* transaction investigation;
* ledger integrity testing;
* regulatory evidence;
* historical reconstruction.

---

# 16. Ledger Does Not Become a Generic Transaction Table

The ledger must not be used as a replacement for institutional transaction tables.

The distinction remains:

```text
ananse.transaction
        ↓
institutional activity

ledger.entry
        ↓
financial consequence / accounting posting
```

Likewise:

```text
sikacredit.loan
        ↓
institutional lending activity

ledger.entry
        ↓
financial consequence where applicable
```

and:

```text
oman_remit.remittance
        ↓
institutional remittance activity

ledger.entry
        ↓
financial consequence where applicable
```

The ledger therefore remains downstream of recognised financial activity.

---

# 17. Institutional Boundary

Ledger structures do not collapse institutional boundaries.

The originating event remains owned by its source institution.

For example:

```text
ANANSE
   │
   └── Transaction
          ↓
      Financial Event
          ↓
       Ledger Entry
```

The ledger represents the financial consequence within the OCB financial core.

It does not mean:

```text
OCB owns Ananse transaction
```

or:

```text
ledger owns Ananse wallet
```

Ownership and financial representation remain distinct.

---

# 18. Ledger Entry vs Financial State

The distinction between ledger entries and financial positions is mandatory.

| Object             | Represents                                                       |
| ------------------ | ---------------------------------------------------------------- |
| Financial event    | What financially occurred                                        |
| Ledger entry       | The accounting representation of the valid financial consequence |
| Financial position | What is subsequently true                                        |
| Analytical state   | What OCB derives from available financial information            |

Therefore:

```text
Ledger Entry
      ≠
Financial Position
```

and:

```text
Ledger Entry
      ≠
Financial Event
```

The ledger is an intermediate authoritative representation of financial consequence.

---

# 19. Minimum Structural Requirements

The v1.0.0 ledger structure must support, at minimum:

| Requirement                            | Purpose                             |
| -------------------------------------- | ----------------------------------- |
| `ledger_entry_id`                      | Unique ledger-entry identity        |
| Event reference                        | Trace entry to financial event      |
| Transaction reference where applicable | Trace entry to originating activity |
| Financial-object reference             | Identify affected financial object  |
| Debit/credit classification            | Represent posting direction         |
| Amount                                 | Represent monetary consequence      |
| Currency                               | Identify monetary denomination      |
| Ledger timestamp                       | Preserve posting chronology         |

Additional control, provenance, and reconciliation attributes may be introduced where justified by later implementation requirements.

---

# 20. Relationship to WP-2.3-T03

WP-2.3-T03 establishes the **financial event structures**.

This ticket establishes the corresponding **ledger representation of financial consequences**.

The relationship is:

```text
WP-2.3-T03
Financial Event Structure
        ↓
WP-2.3-T04
Ledger Structure
```

The two structures must remain separate.

A financial event records the recognised activity.

A ledger entry records its valid accounting consequence.

---

# 21. Relationship to WP-2.6

This ticket does **not** replace WP-2.6.

WP-2.3-T04 establishes the operational schema boundary and minimum ledger structure required by the database architecture.

WP-2.6 will subsequently establish the complete ledger architecture, including:

* authoritative ledger behaviour;
* debit/credit semantics;
* event-to-ledger linkage;
* transaction-to-ledger linkage;
* reconciliation;
* ledger integrity;
* event-to-ledger traceability.

The separation is deliberate:

```text
WP-2.3-T04
STRUCTURE
      ↓
WP-2.6
LEDGER ARCHITECTURE
      ↓
WP-3.4
LEDGER POSTING ENGINE
```

---

# 22. v1.0.0 Boundary

The ledger structure does **not** introduce:

* institutional internal ledgers;
* correspondent accounts;
* settlement accounts;
* bank accounts;
* escrow structures;
* external payment-rail ledgers;
* SWIFT structures;
* real-time ledger streaming;
* external accounting integrations.

The ledger represents only the financial consequences required by the approved OCB v1.0.0 financial model.

---

# 23. Resulting Structure

The operational schema architecture is therefore:

```text
OCB_PLATFORM
│
├── ledger
│   └── entry
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
├── ocb
│   ├── customer
│   └── customer_identity
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
Valid Financial Consequence
        ↓
ledger.entry
        ↓
Financial Position
```

---

# 24. Decision

The OCB Platform v1.0.0 will maintain a dedicated:

```text
ledger
```

schema containing the operational ledger structure:

```text
ledger.entry
```

The ledger entry will provide a distinct accounting representation of valid financial consequences and will maintain traceability to the originating financial event and, where applicable, transaction and affected financial object.

The ledger will support debit and credit representation, monetary value, currency, chronology, and financial-object reference.

The ledger will not replace institutional activity, financial events, or financial-state structures.

Detailed ledger behaviour, reconciliation, and posting mechanics remain governed by **WP-2.6** and **Programme 3**.

---

## Core Principle

> **The ledger records the accounting representation of a valid financial consequence; it does not become the originating financial event, the institutional transaction, or the financial position itself. Every authoritative ledger consequence must remain traceable to the financial activity that produced it and to the financial state it affects.**
