# OCB Financial Event Catalogue

## Purpose

This document establishes the controlled inventory of financial events required by the OCB Platform v1.0.0.

It defines which events are recognised at the domain level as authoritative financial events and distinguishes those events from:

- event outcomes;
- financial consequences or legs;
- financial state;
- analytical interpretations;
- unresolved control mechanisms.

This catalogue establishes the scope for subsequent financial-event semantic definition and implementation.

It does not define physical database structures, transaction schemas, ledger structures, or intelligence calculations.

---

## 1. Governing Principle

A financial event records an occurrence within the simulated financial domain.

A financial event may or may not produce a financial consequence.

Therefore:

```text
Financial Event
      ↓
Event Outcome
      ↓
Financial Consequence
      ↓
Financial State
      ↓
Analytical Interpretation
````

These concepts must not be treated as interchangeable.

A failed transaction remains an event even when it produces no financial consequence.

---

## 2. Authoritative Financial Events

The following events constitute the current authoritative financial-event inventory for v1.0.0.

### 2.1 Ananse Telecom

| Event            | Domain         | Status  |
| ---------------- | -------------- | ------- |
| Cash-in          | Ananse Telecom | Defined |
| Cash-out         | Ananse Telecom | Defined |
| P2P transfer     | Ananse Telecom | Defined |
| Merchant payment | Ananse Telecom | Defined |

These represent the principal mobile-money/e-money financial activities within the Ananse Telecom domain.

---

### 2.2 SikaCredit

| Event             | Domain     | Status  |
| ----------------- | ---------- | ------- |
| Loan disbursement | SikaCredit | Defined |
| Loan repayment    | SikaCredit | Defined |

Loan application, approval, closure, and default are not included as independent authoritative financial events at this stage.

Loan default may instead be derived from authoritative loan information and repayment obligations.

---

### 2.3 Oman Remit

| Event      | Domain     | Status  |
| ---------- | ---------- | ------- |
| Remittance | Oman Remit | Defined |

Remittance initiation, processing, receipt, and failure are not currently treated as separate authoritative financial-event types.

Their precise relationship to the remittance event and its outcome will be established during event semantic definition.

---

## 3. P2P Transfer Structure

P2P transfer is retained as the authoritative financial event.

The event may produce two financial legs:

```text
P2P Transfer
      │
      ├───────────────┐
      ▼               ▼
 P2P Send          P2P Receive
 Sender Leg        Receiver Leg
   Outflow            Inflow
```

P2P Send and P2P Receive are therefore treated as financial consequences or legs of the P2P transfer rather than independent economic events.

This distinction preserves the identity of the underlying transfer while allowing wallet-level inflow, outflow, reconciliation, and financial-state analysis.

The precise implementation of these legs is deferred to subsequent data and ledger modelling.

---

## 4. Event Outcomes

Event outcomes are not independent financial-event types.

Relevant outcomes may include:

* successful;
* failed;
* rejected.

An unsuccessful event may remain recorded without producing a financial consequence.

For example:

```text
Cash-out
    ↓
Failed
    ↓
Event recorded
    ↓
No wallet financial consequence
```

This distinction is important for both financial reconstruction and intelligence analysis.

Repeated failed events may constitute an observable behavioural pattern even where they produce no financial state change.

The specific outcome taxonomy and processing rules will be established during subsequent event semantic definition.

---

## 5. Financial Consequences

A financial consequence represents the effect of an event on authoritative financial state.

Examples include:

* wallet debit;
* wallet credit;
* P2P sender outflow;
* P2P receiver inflow;
* loan principal creation;
* loan repayment reduction;
* other explicitly justified financial effects.

Financial consequences must not be confused with the events that produce them.

Conceptually:

```text
Financial Event
      ↓
Financial Consequence
      ↓
Ledger / Operational Financial State
```

The detailed consequence model is deferred to subsequent financial-processing and ledger design.

---

## 6. Derived Financial and Credit States

The following are not treated as independent financial events solely because they are analytically important:

* active loan;
* delinquent loan;
* defaulted loan;
* closed loan;
* wallet state;
* transaction state;
* other derived financial classifications.

For example:

```text
Loan Disbursement
      ↓
Repayment obligation
      ↓
Due date / repayment information
      ↓
Actual repayment events
      ↓
Rule evaluation
      ↓
Delinquency / Default
```

Loan default should therefore be derived from authoritative loan and repayment information unless subsequent domain analysis establishes a legitimate independent financial event.

---

## 7. Settlement

Settlement remains a **candidate event requiring semantic definition**.

It is not currently assumed that every financial activity requires a separate settlement event.

The subsequent semantic definition must establish:

* what financial obligation is being settled;
* between which parties or institutions;
* whether settlement is distinct from the originating financial event;
* whether the simulated domain exposes a separate settlement occurrence;
* whether settlement produces an independent financial consequence;
* which institutional domains, if any, require settlement representation.

Settlement must not be introduced merely because settlement exists as a concept in real-world financial infrastructure.

---

## 8. Control and Correction Events

The following remain unresolved and are not part of the approved authoritative financial-event inventory at this stage:

* correction;
* reversal;
* adjustment.

These concepts may be required to support controlled historical correction, reconciliation, or reversal of previously established financial consequences.

However, they will only be promoted to formal event types where a concrete v1.0.0 business scenario justifies their inclusion.

No generic correction, reversal, or adjustment mechanism should be introduced solely for completeness.

---

## 9. Events Not Included as Independent Financial Events

The following concepts are not currently treated as independent authoritative financial events:

| Concept               | Treatment                                               |
| --------------------- | ------------------------------------------------------- |
| Loan application      | Process/lifecycle concept                               |
| Loan approval         | Credit decision/state concept                           |
| Loan closure          | Derived/lifecycle state                                 |
| Loan default          | Derived credit state unless later justified otherwise   |
| Remittance initiation | Process/lifecycle concept                               |
| Remittance processing | Process concept                                         |
| Remittance receipt    | Requires semantic treatment within the remittance event |
| Remittance failure    | Event outcome rather than separate financial-event type |
| P2P Send              | Financial leg of P2P transfer                           |
| P2P Receive           | Financial leg of P2P transfer                           |

These classifications may be revised through subsequent semantic analysis or an approved architectural decision where required.

---

## 10. Event / Consequence / State Distinction

The platform must preserve the following distinction:

```text
FINANCIAL EVENT
What occurred?
        ↓
EVENT OUTCOME
Did it succeed, fail, or get rejected?
        ↓
FINANCIAL CONSEQUENCE
What financial effect occurred?
        ↓
FINANCIAL STATE
What is now true?
        ↓
INTELLIGENCE
What can be inferred?
```

For example:

```text
P2P Transfer
      ↓
Successful
      ↓
Sender: -GH₵100
Receiver: +GH₵100
      ↓
Updated wallet states
      ↓
Velocity / concentration / anomaly analysis
```

Where a transaction fails:

```text
P2P Transfer
      ↓
Failed
      ↓
No financial consequence
      ↓
Wallet state unchanged
      ↓
Failure-pattern analysis may still be possible
```

---

## 11. Status

**Status:** Defined

This catalogue establishes the initial controlled inventory.

It does not constitute the final semantic specification for each event.

---

## 12. Next Definition Stage

The next financial-event work must define, for each retained event where applicable:

* business meaning;
* originating domain;
* participating entities;
* event actor;
* event outcome;
* financial consequence;
* source and destination;
* temporal semantics;
* state implications;
* failure behaviour;
* reconciliation implications.

The catalogue must be updated if semantic analysis establishes that an event should be added, removed, split, combined, or reclassified.

Where such a change materially affects architecture, the appropriate ADR process must be followed.

---

## Core Principle

> **An event records what occurred; an outcome records what happened to the event; a financial consequence records what changed financially; and financial state records what is subsequently true.**

These concepts must remain distinct throughout the OCB Platform.