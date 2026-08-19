# OCB Financial Event / State Relationships

## Purpose

This document defines how the authoritative financial events identified in the OCB Financial Event Catalogue affect financial state.

It establishes the relationship between:

```text
Financial Event
      ↓
Event Outcome
      ↓
Financial Consequence
      ↓
Financial State
````

This document does not define the complete operational state-transition model, physical database structures, or ledger implementation.

Those concerns are addressed by subsequent engineering work.

---

## 1. Governing Principle

A financial event changes financial state only when its applicable financial consequence is successfully established.

Therefore:

```text
Successful Event
      ↓
Financial Consequence
      ↓
State Change
```

Where an event fails before producing its intended financial consequence:

```text
Failed Event
      ↓
No Financial Consequence
      ↓
No Corresponding Financial State Change
```

Failed events may nevertheless remain observable for analytical purposes where the event is within the OCB observation boundary.

---

# 2. Ananse Telecom

## 2.1 Cash-in

### State Affected

Customer wallet balance.

### Successful State Change

```text
Customer Wallet
      +
    Amount
```

The customer's wallet balance increases by the successful cash-in amount.

### Failed State Change

```text
Customer Wallet
      =
    Unchanged
```

### Relationship

```text
Cash-in
   ↓
Successful
   ↓
Wallet Credit
   ↓
Wallet Balance Increases
```

---

## 2.2 Cash-out

### State Affected

Customer wallet balance.

### Successful State Change

```text
Customer Wallet
      -
    Amount
```

The customer's wallet balance decreases by the successful cash-out amount.

### Failed State Change

```text
Customer Wallet
      =
    Unchanged
```

### Relationship

```text
Cash-out
   ↓
Successful
   ↓
Wallet Debit
   ↓
Wallet Balance Decreases
```

A failed cash-out must not produce a wallet debit.

---

## 2.3 P2P Transfer

### State Affected

Sender and receiver wallet balances.

### Successful State Change

```text
Sender Wallet
      -
    Amount

Receiver Wallet
      +
    Amount
```

The two financial legs form one P2P Transfer.

### Failed State Change

```text
Sender Wallet
      =
    Unchanged

Receiver Wallet
      =
    Unchanged
```

### Relationship

```text
P2P Transfer
      ↓
Successful
      ↓
┌───────────────────┐
│                   │
▼                   ▼
Sender Wallet     Receiver Wallet
   - Amount          + Amount
```

The transfer must preserve the relationship between the sender-side outflow and receiver-side inflow.

The sender and receiver legs are not independent financial events.

---

## 2.4 Merchant Payment

### State Affected

Customer wallet balance.

### Successful State Change

```text
Customer Wallet
      -
    Amount
```

### Failed State Change

```text
Customer Wallet
      =
    Unchanged
```

The merchant is an observable reference and does not receive a corresponding OCB merchant-account state change.

### Relationship

```text
Merchant Payment
      ↓
Successful
      ↓
Customer Wallet Debit
      ↓
Wallet Balance Decreases
```

---

# 3. SikaCredit

## 3.1 Loan Disbursement

### State Affected

Outstanding loan obligation.

### Successful State Change

```text
Outstanding Principal
          +
     Disbursed Amount
```

The loan becomes financially effective and establishes the corresponding outstanding obligation.

### Relationship

```text
Loan Disbursement
       ↓
Successful
       ↓
Loan Financial Obligation Established
       ↓
Outstanding Principal Increases
```

Loan approval does not itself create the outstanding financial state.

---

## 3.2 Loan Repayment

### State Affected

Outstanding loan obligation.

### Successful State Change

```text
Outstanding Loan Obligation
          -
     Repayment Amount
```

### Failed State Change

```text
Outstanding Loan Obligation
          =
       Unchanged
```

### Relationship

```text
Loan Repayment
      ↓
Successful
      ↓
Outstanding Obligation Decreases
```

Repayment history contributes to subsequent loan-state and credit-performance determinations.

---

## 3.3 Loan Default

Loan default is not an independent financial event.

It is a derived credit state.

Conceptually:

```text
Loan
 ↓
Repayment Obligation
 ↓
Repayment Deadline
 ↓
Repayment History
 ↓
Default Rule
 ↓
Defaulted State
```

The defaulted state therefore derives from authoritative loan and repayment information rather than from a separate `Loan Default` financial event.

---

# 4. Oman Remit

## 4.1 Remittance

### State Affected

The relevant customer/beneficiary financial state represented within the OCB observation boundary.

### Successful State Change

Successful completion results in the beneficiary receiving the remitted value.

```text
Remittance
      ↓
Successful
      ↓
Beneficiary Receives Value
      ↓
Financial State Changes
```

Within the v1.0.0 abstraction, successful completion of the remittance is treated as settled.

### Failed State Change

Failed internal remittance processing is not currently represented as an OCB observable financial event.

Where no successful remittance occurs, no corresponding beneficiary financial consequence is recognised by the OCB observable financial model.

---

# 5. Cross-Event State Rules

## 5.1 Successful Events

A successful financial event produces its defined financial consequence.

```text
Event
 ↓
Successful
 ↓
Financial Consequence
 ↓
State Change
```

---

## 5.2 Failed Events

A failed event produces no intended financial consequence.

```text
Event
 ↓
Failed
 ↓
No Financial Consequence
 ↓
State Unchanged
```

The failed event itself may remain available for intelligence analysis where it is within the OCB observation boundary.

---

## 5.3 Settlement

Settlement is not an independent state-changing financial event in v1.0.0.

It describes the completed financial consequence of a successfully completed event where applicable.

```text
Successful Event
      ↓
Financial Consequence Completed
      ↓
Settled
```

It must not create an additional state change merely because the event is described as settled.

---

## 5.4 P2P Transfer Atomicity

A successful P2P Transfer must produce balanced financial consequences:

```text
Sender Outflow = Receiver Inflow
```

For a transfer of `Amount`:

```text
Sender State Change = -Amount
Receiver State Change = +Amount
Net Transfer Effect = 0
```

A failed P2P Transfer must not partially change either wallet.

This relationship is important for later ledger, reconciliation, and balance-validation design.

---

## 5.5 Wallet Balance Integrity

Wallet-affecting events must preserve the relationship between event outcome and wallet state.

For successful events:

```text
Cash-in          → Wallet +
Cash-out         → Wallet -
P2P sender leg   → Wallet -
P2P receiver leg → Wallet +
Merchant payment → Wallet -
```

Failed events produce no corresponding wallet change.

The detailed prevention and validation of negative balances is an implementation and business-rule concern addressed in subsequent stages.

---

# 6. State Relationships Not Represented as Independent Events

The following relationships are derived from authoritative events and financial state:

| State / Concept            | Source Relationship                                             |
| -------------------------- | --------------------------------------------------------------- |
| Wallet balance             | Wallet-affecting financial events                               |
| Outstanding loan principal | Loan disbursement and repayment                                 |
| Loan delinquency           | Loan obligations, deadlines and repayment history               |
| Loan default               | Derived from applicable loan rules                              |
| Loan closure               | Derived when the applicable outstanding obligation is satisfied |
| Settlement                 | Completed consequence/status of a successful event              |
| P2P sender outflow         | Financial leg of P2P Transfer                                   |
| P2P receiver inflow        | Financial leg of P2P Transfer                                   |

These are not additional authoritative financial events.

---

# 7. Correction, Reversal and Adjustment

## 7.1 Correction

Correction does not currently produce a separate OCB financial-state transition.

Institutional correction is treated as an internal control process occurring before authoritative information crosses the OCB observation boundary.

---

## 7.2 Reversal

Reversal is not included in the v1.0.0 financial-state model.

A future reversal mechanism would require an explicit relationship between an original financial event and a subsequent reversal event.

It would therefore affect:

* historical event interpretation;
* ledger consequences;
* reconciliation;
* state reconstruction.

No reversal state transition is defined for v1.0.0.

---

## 7.3 Adjustment

Adjustment does not have a defined v1.0.0 state transition.

A specific adjustment mechanism would require a concrete business definition before it could be incorporated into the financial-state model.

---

# 8. State Relationship Summary

| Event             | State Affected              | Successful Consequence               | Failed Consequence                      |
| ----------------- | --------------------------- | ------------------------------------ | --------------------------------------- |
| Cash-in           | Customer wallet             | Balance increases                    | No change                               |
| Cash-out          | Customer wallet             | Balance decreases                    | No change                               |
| P2P Transfer      | Sender and receiver wallets | Sender decreases; receiver increases | No change                               |
| Merchant Payment  | Customer wallet             | Balance decreases                    | No change                               |
| Loan Disbursement | Loan obligation             | Outstanding principal increases      | No obligation established               |
| Loan Repayment    | Loan obligation             | Outstanding obligation decreases     | No change                               |
| Remittance        | Beneficiary financial state | Beneficiary receives value           | No OCB financial consequence recognised |

---

# 9. Relationship to Later State Modelling

This document establishes the event-to-state relationships required for the financial-event model.

It does not yet define the complete financial state machine.

The later state-modelling stage must determine, where required:

* formal state names;
* state-transition rules;
* valid transition sequences;
* invalid transitions;
* temporal constraints;
* reconciliation rules;
* balance constraints;
* historical state reconstruction.

The established event relationships in this document must remain consistent with that later state model.

---

# 10. Status

**Status:** Defined

The event/state relationships defined here represent the current v1.0.0 semantic model.

Changes that materially affect financial truth, event semantics, ledger behaviour, reconciliation, or historical interpretation require appropriate governance review and, where necessary, an ADR.

---

## Core Principle

> **A financial event establishes what occurred; its successful financial consequence determines what changes; financial state records what is subsequently true.**

```

This is much closer to the appropriate size for **T03**. It records the relationships we have actually agreed without prematurely building WP-1.4's full state machine.
```
