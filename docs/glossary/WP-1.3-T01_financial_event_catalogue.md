# OCB Financial Event Catalogue

**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.3 — Financial Event Model

**Ticket:** WP-1.3-T01

**Status:** **REVISED / LOCKED**

**Decision Type:** Financial event taxonomy and controlled event inventory

---

## Purpose

This document establishes the controlled inventory of financial events required by the OCB Platform v1.0.0.

It defines which institutional financial activities are recognised by OCB as authoritative financial events and distinguishes those events from:

* institutional activity records;
* event outcomes;
* financial consequences;
* authoritative financial states;
* OCB-resolved identities;
* derived and analytical interpretations;
* unresolved control mechanisms.

The catalogue establishes the semantic scope for subsequent financial-event definition, financial-processing, ledger, and intelligence work.

It does not define physical database structures, transaction schemas, ledger structures, or intelligence calculations.

---

## 1. Governing Principle

A financial event represents an authoritative financial occurrence within an institutional domain.

The institution remains the owner of the underlying financial object and activity.

OCB observes the institutional information, resolves identities where required, and may represent the resulting financial consequences within its analytical model.

```text
Institutional Financial Activity
            ↓
       Event Outcome
            ↓
   Financial Consequence
            ↓
 Institutional Financial State
            ↓
     OCB Observation
            ↓
   Identity Resolution
            ↓
 OCB Financial / Analytical Model
            ↓
 Analytical Interpretation
```

These concepts must not be treated as interchangeable.

An OCB representation of an institutional financial consequence does not transfer ownership of the underlying institutional financial object to OCB.

A failed event remains an observable event even when it produces no financial consequence.

---

## 2. Authoritative Financial Event Inventory

The following events constitute the approved authoritative financial-event inventory for v1.0.0.

### 2.1 Ananse Telecom

| Event            | Institutional Domain | Status  |
| ---------------- | -------------------- | ------- |
| Cash-in          | Ananse Telecom       | Defined |
| Cash-out         | Ananse Telecom       | Defined |
| P2P Transfer     | Ananse Telecom       | Defined |
| Merchant Payment | Ananse Telecom       | Defined |

These represent the principal wallet-affecting financial activities within the Ananse Telecom domain.

The corresponding institutional transaction/activity records remain Ananse-owned.

OCB observes and resolves these activities for cross-institutional financial intelligence.

---

### 2.2 SikaCredit

| Event             | Institutional Domain | Status  |
| ----------------- | -------------------- | ------- |
| Loan Disbursement | SikaCredit           | Defined |
| Loan Repayment    | SikaCredit           | Defined |

Loan disbursement represents the creation or increase of the customer's loan obligation.

Loan repayment represents a financial activity that reduces the outstanding loan principal under the v1.0.0 transition model.

The underlying loan and repayment records remain SikaCredit-owned.

Loan application, approval, closure, delinquency, and default are not included as independent authoritative financial events.

---

### 2.3 Oman Remit

| Event      | Institutional Domain | Status  |
| ---------- | -------------------- | ------- |
| Remittance | Oman Remit           | Defined |

The remittance event represents the authoritative financial activity through which value is remitted to a beneficiary within the Oman Remit domain.

Remittance initiation, processing, receipt, and failure are not currently treated as separate authoritative financial-event types.

Their treatment is expressed through the remittance event, its outcome, and its resulting financial consequence.

The underlying remittance and beneficiary financial position remain Oman Remit-owned.

---

## 3. Institutional Event Ownership

The authoritative financial events are owned by their originating institutional domains.

```text
ANANSE TELECOM
    │
    ├── Cash-in
    ├── Cash-out
    ├── P2P Transfer
    └── Merchant Payment

SIKACREDIT
    │
    ├── Loan Disbursement
    └── Loan Repayment

OMAN REMIT
    │
    └── Remittance
```

OCB does not become the operational owner of these events merely because it observes or represents them.

The distinction is:

```text
Institution
    ↓
Owns financial object / activity
    ↓
OCB observes
    ↓
OCB resolves identity
    ↓
OCB represents relevant consequence
    ↓
OCB analyses cross-domain relationships
```

This preserves institutional boundaries while allowing OCB to perform cross-institutional intelligence.

---

## 4. P2P Transfer Structure

P2P Transfer remains one authoritative financial event.

A successful P2P Transfer may produce two financial legs:

```text
P2P Transfer
       │
       ├─────────────────┐
       ↓                 ↓
  Sender Leg        Receiver Leg
       ↓                 ↓
    Debit              Credit
   - Amount           + Amount
```

The sender and receiver legs are financial consequences of the same P2P Transfer event.

They are therefore not independent authoritative economic events.

This structure allows OCB to represent both wallet-level outflow and inflow while preserving the identity of the underlying transfer.

A failed P2P Transfer produces neither financial leg:

```text
P2P Transfer
      ↓
    Failed
      ↓
No Financial Consequence
      ↓
No Wallet State Change
```

The sender and receiver consequences must remain attributable to the same originating P2P Transfer.

---

## 5. Event Outcomes

Event outcomes describe what happened to an authoritative financial event.

The approved v1.0.0 outcome taxonomy is:

* Successful;
* Failed.

### 5.1 Successful

A successful event produces its defined financial consequence and may therefore change the relevant authoritative financial state.

```text
Financial Event
      ↓
  Successful
      ↓
Financial Consequence
      ↓
Financial State Change
```

### 5.2 Failed

A failed event remains an authoritative or observable event occurrence but produces no financial consequence.

```text
Financial Event
      ↓
    Failed
      ↓
No Financial Consequence
      ↓
No Financial State Change
```

Failed events remain analytically relevant.

For example, repeated failed cash-out attempts may provide behavioural intelligence even though they do not affect wallet balance.

### 5.3 Rejected

`Rejected` is **not an approved v1.0.0 event outcome**.

No distinct business meaning has been established that requires rejection to exist as a separate outcome from failure.

It must not be introduced as an additional event outcome without:

* a defined business scenario;
* a demonstrated intelligence or supervisory requirement; and
* an approved architectural decision where required.

---

## 6. Financial Consequences

A financial consequence represents the financial effect produced by an authoritative event.

Examples include:

* wallet debit;
* wallet credit;
* P2P sender debit;
* P2P receiver credit;
* loan principal increase;
* loan principal reduction;
* beneficiary financial-position increase.

The event and its consequence must remain distinct.

```text
AUTHORITATIVE EVENT
        ↓
   EVENT OUTCOME
        ↓
FINANCIAL CONSEQUENCE
        ↓
AUTHORITATIVE FINANCIAL STATE
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
Updated wallet positions
```

The financial consequence is what changes financially; the event identifies what occurred.

---

## 7. Cross-Domain Financial Consequences

A financial event may have consequences that are observable across institutional boundaries.

Such relationships must not be interpreted as transferring ownership of the affected institutional financial objects.

For example:

```text
SikaCredit
Loan Disbursement
       ↓
Loan Principal +
       ↓
Observable consequence
       ↓
Customer receives value
       ↓
Ananse Wallet Position
```

The loan obligation remains SikaCredit-owned.

The wallet position remains Ananse-owned.

Similarly:

```text
Oman Remit
Remittance
       ↓
Beneficiary Financial Position +
       ↓
Observable consequence
       ↓
Beneficiary receives value
       ↓
Ananse Wallet Position
```

The beneficiary financial position remains Oman Remit-owned.

The Ananse wallet position remains Ananse-owned.

OCB may resolve the relevant customer or beneficiary identity and represent the observable financial relationship for analytical purposes.

However, cross-domain activity must not be modelled as an unsupported direct institutional foreign-key relationship or as OCB ownership of the underlying source object.

---

## 8. Financial State

Financial state represents what is financially true after applicable successful financial consequences have occurred.

The approved v1.0.0 financial-position states are:

| State                          | Domain         |
| ------------------------------ | -------------- |
| Customer Wallet Balance        | Ananse Telecom |
| Outstanding Loan Principal     | SikaCredit     |
| Beneficiary Financial Position | Oman Remit     |

The relationship is therefore:

```text
Authoritative Event
       ↓
Financial Consequence
       ↓
Financial State
```

Financial state must not be confused with the event that produced it.

---

## 9. Derived Financial and Credit States

The following are not independent authoritative financial events solely because they are operationally or analytically important:

* active loan;
* delinquent loan;
* defaulted loan;
* closed loan;
* transaction state;
* wallet lifecycle state;
* other derived financial classifications.

For example:

```text
Loan Disbursement
       ↓
Outstanding Principal
       ↓
Repayment Activity
       ↓
Repayment Obligations
       ↓
Applicable Rule
       ↓
Delinquent / Defaulted / Closed
```

These states are derived from authoritative institutional information and approved business rules.

They do not become separate authoritative financial events merely because OCB needs to analyse them.

Loan default, in particular, is a derived credit state in v1.0.0.

---

## 10. Event, Consequence, State and Intelligence Distinction

The platform must preserve the following semantic chain:

```text
FINANCIAL EVENT

What occurred?
        ↓
EVENT OUTCOME

Did it succeed or fail?
        ↓
FINANCIAL CONSEQUENCE

What financial effect occurred?
        ↓
FINANCIAL STATE

What is subsequently true?
        ↓
DERIVED STATE

What condition can be determined?
        ↓
INTELLIGENCE

What can OCB infer?
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
Updated wallet positions
      ↓
Transaction velocity / concentration
      ↓
Potential anomaly
```

For a failed event:

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

The analytical conclusion must never replace the underlying authoritative event or financial state.

---

## 11. Settlement

Settlement remains a **candidate event requiring semantic definition**.

It is not currently part of the approved authoritative financial-event inventory.

The semantic definition must establish:

* what financial obligation is being settled;
* between which parties or institutions;
* whether settlement is distinct from the originating financial event;
* whether the simulated institutional domain exposes a separate settlement occurrence;
* whether settlement produces an independent financial consequence;
* whether settlement is required for a v1.0.0 intelligence or reconciliation objective.

Settlement must not be introduced merely because settlement exists in real-world financial infrastructure.

---

## 12. Control and Correction Events

The following remain unresolved and are not part of the approved authoritative financial-event inventory:

* correction;
* reversal;
* adjustment.

These concepts may become necessary for controlled historical correction, reconciliation, or reversal of previously established financial consequences.

However, they will only be promoted to formal event types where a concrete v1.0.0 requirement justifies their inclusion.

No generic correction, reversal, or adjustment framework should be introduced solely for completeness.

---

## 13. Events Not Included as Independent Financial Events

| Concept               | Treatment                                                 |
| --------------------- | --------------------------------------------------------- |
| Loan Application      | Process/lifecycle concept                                 |
| Loan Approval         | Credit decision / lifecycle concept                       |
| Loan Closure          | Derived lifecycle state                                   |
| Loan Default          | Derived credit state                                      |
| Loan Delinquency      | Derived credit state                                      |
| Remittance Initiation | Process concept within Remittance                         |
| Remittance Processing | Process concept within Remittance                         |
| Remittance Receipt    | Financial consequence/state implication within Remittance |
| Remittance Failure    | Event outcome                                             |
| P2P Send              | Financial consequence / leg of P2P Transfer               |
| P2P Receive           | Financial consequence / leg of P2P Transfer               |
| Settlement            | Candidate event requiring semantic definition             |
| Correction            | Unresolved control event                                  |
| Reversal              | Unresolved control event                                  |
| Adjustment            | Unresolved control event                                  |

These classifications may be revised through subsequent semantic analysis or an approved architectural decision where required.

---

## 14. Relationship to the OCB Analytical Ledger

The event catalogue does not define the physical ledger model.

However, the semantic relationship is:

```text
Institutional Financial Event
          ↓
     Event Outcome
          ↓
   Financial Consequence
          ↓
OCB Analytical / Ledger Representation
          ↓
 Financial-State Reconstruction
          ↓
 Cross-Domain Intelligence
```

A ledger entry is therefore a representation of a financial consequence within the OCB analytical model.

It is not the originating institutional event.

Institutional financial objects remain institution-owned.

OCB observes and resolves them.

Their financial consequences may then be represented in OCB's analytical ledger model where required.

This distinction must remain intact during subsequent ledger and financial-processing design.

---

## 15. Event Semantic Definition Requirements

For each retained authoritative event, subsequent semantic definition must establish, where applicable:

* business meaning;
* originating institutional domain;
* institutional object or activity represented;
* participating entities;
* event actor;
* event outcome;
* financial consequence;
* source and destination;
* temporal semantics;
* affected financial state;
* cross-domain implications;
* failure behaviour;
* reconstruction implications;
* reconciliation implications.

The semantic definition must preserve institutional ownership and must not introduce unsupported internal mechanisms merely to explain an observable consequence.

Where semantic analysis materially changes the approved event inventory or institutional boundary, the appropriate ADR process must be followed.

---

## 16. v1.0.0 Authoritative Event Summary

| Domain         | Authoritative Financial Event |
| -------------- | ----------------------------- |
| Ananse Telecom | Cash-in                       |
| Ananse Telecom | Cash-out                      |
| Ananse Telecom | P2P Transfer                  |
| Ananse Telecom | Merchant Payment              |
| SikaCredit     | Loan Disbursement             |
| SikaCredit     | Loan Repayment                |
| Oman Remit     | Remittance                    |

The inventory contains **seven approved authoritative financial events**.

P2P Send and P2P Receive are consequences/legs of P2P Transfer, not additional events.

Settlement, correction, reversal, and adjustment remain unresolved and are not included in the approved event inventory.

---

## 17. Status

**Status:** **REVISED / LOCKED**

This catalogue establishes the controlled v1.0.0 inventory of authoritative financial events and their semantic boundaries.

The catalogue is aligned with:

* the institutional relationship model;
* the financial-state model;
* the financial-state transition rules;
* the financial-state reconstructability model;
* the conceptual financial-object model;
* the OCB identity-resolution boundary.

Detailed physical implementation belongs to subsequent financial-processing, ledger, data-model, and implementation work.

---

## Core Principle

> **An institutional financial event records what occurred; its outcome records whether it succeeded or failed; its financial consequence records what changed financially; financial state records what is subsequently true; and OCB observes, resolves, represents, and analyses that information without assuming ownership of the underlying institutional financial objects.**
