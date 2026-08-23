# OCB Financial State Transition Definition

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-1.4 — State Model
**Ticket:** WP-1.4-T02
**Status:** **REVISED / LOCKED**
**Decision Type:** Financial state transition semantics

---

## 1. Purpose

This document defines how authoritative financial events produce changes in the financial-position states identified in **WP-1.4-T01**.

It establishes:

* state-increasing transitions;
* state-decreasing transitions;
* successful and failed-event behaviour;
* P2P transfer state consequences;
* cross-domain financial consequences;
* state reconstruction principles;
* state-integrity rules.

It does not define:

* physical database structures;
* ledger table implementation;
* ETL procedures;
* SQL implementation;
* analytical calculations.

---

# 2. Transition Principle

A financial-position state changes only when an authoritative financial event produces a valid financial consequence for that state.

```text
Authoritative Financial Event
            ↓
       Event Outcome
            ↓
   Financial Consequence
            ↓
     State Transition
```

A failed event produces **no financial state transition**.

A successful event may produce one or more financial consequences depending on the event definition.

---

# 3. Customer Wallet Balance

## 3.1 Domain

**Ananse Telecom**

## 3.2 State

Customer Wallet Balance.

The state belongs to the Ananse wallet domain.

The wallet itself remains an institution-owned financial object; the balance represents its financial position at a point in time.

---

## 3.3 Transition Principle

The wallet balance changes through valid successful financial consequences affecting the wallet.

```text
Previous Wallet Balance
        +
Successful Credits
        -
Successful Debits
        =
New Wallet Balance
```

---

## 3.4 Transition Rules

| Event                       | Outcome    | Wallet Transition |
| --------------------------- | ---------- | ----------------- |
| Cash-in                     | Successful | Balance + amount  |
| Cash-in                     | Failed     | No change         |
| Cash-out                    | Successful | Balance − amount  |
| Cash-out                    | Failed     | No change         |
| P2P Transfer — Sender Leg   | Successful | Balance − amount  |
| P2P Transfer — Receiver Leg | Successful | Balance + amount  |
| P2P Transfer                | Failed     | No change         |
| Merchant Payment            | Successful | Balance − amount  |
| Merchant Payment            | Failed     | No change         |

These transitions arise from the authoritative Ananse transaction/event model.

Cross-domain events are addressed separately in Section 7 rather than being treated as ordinary Ananse transaction types.

---

## 3.5 Balance Integrity

A successful debit must be supported by sufficient available wallet value.

Conceptually:

```text
Available Wallet Balance
          ≥
Proposed Debit
```

Where the condition is not satisfied:

```text
Financial Event
      ↓
Failed / rejected according to applicable event rules
      ↓
No valid financial consequence
      ↓
No wallet-state transition
```

The resulting wallet state must remain reconstructible from valid wallet-affecting financial consequences.

```text
Wallet Balance
=
Valid Credits
−
Valid Debits
```

---

# 4. P2P Transfer State Transition

P2P Transfer remains **one authoritative financial event**.

It produces two financial consequences when successful:

```text
              P2P TRANSFER
                   │
          ┌────────┴────────┐
          ↓                 ↓
     Sender Leg        Receiver Leg
        Debit               Credit
       − Amount             + Amount
```

Therefore:

```text
Sender Wallet
      ↓
Balance − Amount

Receiver Wallet
      ↓
Balance + Amount
```

The two legs belong to the same authoritative P2P Transfer event.

A failed P2P Transfer produces neither financial consequence:

```text
P2P Transfer
      ↓
Failed
      ↓
No Sender Debit
No Receiver Credit
```

This distinction is important because **P2P Send and P2P Receive are financial consequences/legs, not independent authoritative events**.

---

# 5. Outstanding Loan Principal

## 5.1 Domain

**SikaCredit**

## 5.2 State

Outstanding Loan Principal.

This is a monetary obligation derived from authoritative SikaCredit loan and repayment activity.

---

## 5.3 Transition Principle

```text
Previous Outstanding Principal
          +
Successful Loan Disbursements
          −
Successful Principal Repayments
          =
New Outstanding Principal
```

---

## 5.4 Transition Rules

| Event             | Outcome    | State Transition             |
| ----------------- | ---------- | ---------------------------- |
| Loan Disbursement | Successful | Principal + disbursed amount |
| Loan Disbursement | Failed     | No change                    |
| Loan Repayment    | Successful | Principal − repayment amount |
| Loan Repayment    | Failed     | No change                    |

For v1.0.0, the full amount of a successful loan repayment is treated as principal repayment.

No separate interest or fee allocation is modelled in this state-transition definition.

---

## 5.5 Principal Integrity

Outstanding principal must not become negative.

Conceptually:

```text
Outstanding Principal
          ≥
Repayment Amount
```

A repayment that would produce an invalid negative principal must not generate an invalid state.

The precise validation and failure behaviour belongs to the subsequent financial-processing implementation.

---

# 6. Beneficiary Financial Position

## 6.1 Domain

**Oman Remit**

## 6.2 State

Beneficiary Financial Position.

This represents the financial position conceptually established for the beneficiary through successful Oman Remit activity.

It does **not** imply that OCB models the beneficiary's complete external financial account or operational withdrawal mechanism.

---

## 6.3 Transition Principle

A successful remittance creates a positive financial consequence associated with the beneficiary position.

```text
Previous Beneficiary Position
          +
Successful Remittance Consequence
          =
Updated Beneficiary Position
```

---

## 6.4 Transition Rules

| Event      | Outcome    | State Transition                     |
| ---------- | ---------- | ------------------------------------ |
| Remittance | Successful | Position + applicable remitted value |
| Remittance | Failed     | No change                            |
| Remittance | Rejected   | No change                            |

---

## 6.5 Withdrawal Boundary

The v1.0.0 model does **not** introduce a separate Remittance Withdrawal event.

Therefore, OCB does not model the beneficiary's subsequent withdrawal or consumption of remitted value as an Oman Remit state-decreasing event.

This is deliberate.

It prevents OCB from inventing an internal Oman Remit operational architecture that has not been established by the project scope.

---

# 7. Cross-Domain Financial Consequences

Cross-domain activity requires a critical distinction between:

1. **the source-domain financial state; and**
2. **the financial consequence observable elsewhere or represented by OCB.**

These must not be collapsed into a single institutional state transition.

---

## 7.1 Loan Disbursement

A successful SikaCredit loan disbursement changes the SikaCredit loan position:

```text
SIKACREDIT
    │
    └── Loan Disbursement
              ↓
    Outstanding Principal
              +
          Amount
```

The disbursement may also produce a financial consequence that becomes relevant to the customer's broader financial activity.

However, the conceptual and logical models do **not** establish:

```text
SikaCredit Loan Disbursement
             ↓
Ananse Wallet Balance +
```

as a direct source-domain state transition.

Instead:

```text
SikaCredit Loan Disbursement
             ↓
SikaCredit financial consequence
             ↓
OCB observes / resolves
             ↓
Cross-domain financial analysis
```

If a corresponding Ananse wallet credit is actually represented in source data, that credit is an **Ananse-authoritative wallet event/consequence in its own right**.

This preserves institutional ownership and prevents double counting.

---

## 7.2 Remittance

A successful Oman Remit remittance changes the Oman Remit beneficiary financial position:

```text
OMAN REMIT
    │
    └── Remittance
            ↓
Beneficiary Financial Position
            +
          Amount
```

The remittance may have downstream relevance to the customer's broader financial behaviour.

However, the model does **not** establish:

```text
Oman Remit Remittance
             ↓
Ananse Wallet Balance +
```

as an automatic direct state transition.

Instead:

```text
Oman Remit Remittance
             ↓
Oman Remit financial consequence
             ↓
OCB observes / resolves
             ↓
Cross-domain financial analysis
```

If Ananse subsequently records an actual wallet credit associated with that value, that wallet-affecting event must be represented according to Ananse's own authoritative transaction/event model.

---

# 8. Why Cross-Domain Effects Are Not Automatic Wallet Transitions

This distinction is essential to the OCB architecture.

OCB's conceptual model establishes:

```text
Institutional Financial Objects
remain institution-owned
          ↓
OCB observes / resolves them
          ↓
Their financial consequences can be
represented in OCB's financial /
analytical model
```

It does **not** establish that a financial consequence originating in one institution automatically mutates the authoritative financial state of another institution.

Therefore:

> **Cross-domain analytical relationship ≠ cross-domain source-state mutation.**

This prevents the state model from accidentally creating an implied shared wallet, shared ledger, or operational integration between Ananse, SikaCredit, and Oman Remit.

---

# 9. Failed Events

A failed or rejected event remains an observable event outcome but produces no valid financial consequence.

Therefore:

```text
Financial Event
      ↓
Failed / Rejected
      ↓
No Valid Financial Consequence
      ↓
No Financial State Transition
```

Examples:

```text
Failed Cash-out
    → Wallet unchanged

Failed P2P Transfer
    → Sender unchanged
    → Receiver unchanged

Failed Merchant Payment
    → Wallet unchanged

Failed Loan Disbursement
    → Outstanding Principal unchanged

Failed Loan Repayment
    → Outstanding Principal unchanged

Failed Remittance
    → Beneficiary Financial Position unchanged
```

Failed events may nevertheless remain analytically significant.

For example, repeated failed transactions may indicate operational friction, attempted fraud, or other behavioural patterns even though they do not change financial state.

---

# 10. State Reconstruction

Authoritative financial states should be reconstructible from authoritative financial consequences wherever the available source information supports such reconstruction.

## 10.1 Wallet

```text
Wallet Balance
=
Valid Wallet Credits
−
Valid Wallet Debits
```

## 10.2 Outstanding Loan Principal

```text
Outstanding Principal
=
Valid Disbursement Principal
−
Valid Principal Repayments
```

## 10.3 Beneficiary Financial Position

At the conceptual v1.0.0 level:

```text
Beneficiary Financial Position
=
Applicable Successful Remittance Value
−
Modelled Decreases
```

Since no beneficiary withdrawal/decrease event is modelled in v1.0.0, the state currently has no corresponding OCB-defined decrease transition.

This is a **scope limitation**, not a claim that the real-world beneficiary position can never decrease.

---

# 11. State Transition Integrity

The following rules apply across the state model.

### Rule 1 — Valid consequences only

Only valid financial consequences may change a financial-position state.

### Rule 2 — Failed events do not change financial state

A failed or rejected event produces no valid financial state transition.

### Rule 3 — State ownership is preserved

A financial state remains attributable to the institutional domain that owns the underlying financial object or activity.

### Rule 4 — Cross-domain relationships do not imply shared ownership

An analytical relationship between financial states must not be interpreted as shared institutional ownership.

### Rule 5 — No automatic cross-domain duplication

A cross-domain consequence must not be counted twice merely because OCB observes both the originating event and a resulting financial consequence.

### Rule 6 — States must remain reconcilable

Where sufficient authoritative information exists, a financial state must be reconstructible from its valid financial consequences.

### Rule 7 — Invalid negative states are prohibited

Financial integrity constraints must prevent impossible monetary states such as:

```text
Wallet Balance < 0
```

or:

```text
Outstanding Principal < 0
```

unless a future architecture explicitly establishes an alternative mechanism.

### Rule 8 — Unmodelled institutional mechanisms remain outside scope

OCB must not invent withdrawal, settlement, internal-account, or other institutional mechanisms merely to explain an observed cross-domain relationship.

---

# 12. State Transition Summary

| Financial State                | Increasing Transition                | Decreasing Transition               |
| ------------------------------ | ------------------------------------ | ----------------------------------- |
| Customer Wallet Balance        | Successful wallet credit consequence | Successful wallet debit consequence |
| Outstanding Loan Principal     | Successful Loan Disbursement         | Successful Loan Repayment           |
| Beneficiary Financial Position | Successful Remittance                | Not modelled in v1.0.0              |

Cross-domain consequences are **not automatically added to the Ananse wallet state**. Any wallet-state change must arise from an authoritative Ananse wallet-affecting event/consequence.

---

# 13. Relationship to OCB's Financial / Analytical Model

The resulting conceptual flow is:

```text
AUTHORITATIVE INSTITUTIONAL EVENT
              ↓
        EVENT OUTCOME
              ↓
     FINANCIAL CONSEQUENCE
              ↓
     INSTITUTIONAL STATE
              ↓
       OCB OBSERVATION
              ↓
      IDENTITY RESOLUTION
              ↓
OCB FINANCIAL / ANALYTICAL MODEL
              ↓
       CROSS-DOMAIN ANALYSIS
```

This preserves the central architectural boundary:

> **Institutional financial objects remain institution-owned → OCB observes/resolves them → their financial consequences can be represented in OCB's financial and analytical model.**

---

# 14. Status

**Status: REVISED / LOCKED**

The v1.0.0 transition model establishes:

1. Wallet state transitions from valid Ananse wallet-affecting financial consequences;
2. Outstanding loan principal transitions from successful SikaCredit disbursement and repayment;
3. Beneficiary financial position increases from successful Oman Remit remittance activity;
4. Failed and rejected events produce no financial state transition;
5. P2P Transfer remains one authoritative event with sender and receiver financial legs;
6. Cross-domain relationships do not automatically mutate another institution's authoritative state;
7. Financial states must remain institutionally attributable and reconcilable.

Detailed physical implementation belongs to the subsequent financial-processing, ledger, and logical/physical data-model work.

---

# Core Principle

> **An authoritative financial state changes only through a valid financial consequence attributable to that state. Failed events do not change financial state, and cross-domain analytical relationships must not be mistaken for cross-domain institutional state mutations.**
