# OCB Financial State Transition Definition

## Purpose

This document defines how authoritative financial events change the financial states identified in WP-1.4-T01.

It establishes:

* state-increasing events;
* state-decreasing events;
* successful and failed-event behaviour;
* cross-domain state effects;
* state integrity rules.

It does not define physical database structures or ledger implementation.

---

## 1. Transition Principle

A financial state changes only when an authoritative financial event produces a valid financial consequence.

```text
Financial Event
      ↓
Event Outcome
      ↓
Financial Consequence
      ↓
State Transition
```

A failed event produces no financial state transition.

---

## 2. Customer Wallet Balance

### Domain

Ananse Telecom.

### State Transition

Successful financial consequences affecting the customer's wallet change the wallet balance.

```text
Previous Balance
      +
Successful Credit
      -
Successful Debit
      =
New Balance
```

### Transition Rules

| Event                       | Outcome    | Transition                 |
| --------------------------- | ---------- | -------------------------- |
| Cash-in                     | Successful | Balance + amount           |
| Cash-in                     | Failed     | No change                  |
| Cash-out                    | Successful | Balance − amount           |
| Cash-out                    | Failed     | No change                  |
| P2P Transfer — receiver leg | Successful | Balance + amount           |
| P2P Transfer — sender leg   | Successful | Balance − amount           |
| P2P Transfer                | Failed     | No change                  |
| Merchant Payment            | Successful | Balance − amount           |
| Merchant Payment            | Failed     | No change                  |
| Loan Disbursement           | Successful | Balance + disbursed amount |
| Remittance                  | Successful | Balance + remitted amount  |

The precise cross-domain implementation of loan and remittance consequences remains subject to the approved institutional-boundary model.

### Balance Integrity

A successful debit must not create an invalid negative wallet balance.

Conceptually:

```text
Current Available Balance
        ≥
Proposed Debit
```

If the condition is not satisfied:

```text
Event
  ↓
Failed
  ↓
No Financial Consequence
  ↓
No State Transition
```

The authoritative wallet balance is reconstructible from authoritative financial consequences.

```text
Wallet Balance
=
Total Credits
-
Total Debits
```

---

## 3. P2P Transfer State Transition

P2P Transfer remains one authoritative financial event.

Its successful financial consequences contain two legs:

```text
P2P Transfer
      │
      ├──────────────┐
      ▼              ▼
Sender Leg       Receiver Leg
Debit            Credit
- Amount         + Amount
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

The two financial legs belong to the same P2P Transfer event.

A failed P2P Transfer produces neither leg.

```text
P2P Transfer
      ↓
Failed
      ↓
No Debit
No Credit
```

---

## 4. Outstanding Loan Principal

### Domain

SikaCredit.

### State Transition

Outstanding Loan Principal changes through successful loan disbursement and repayment events.

```text
Previous Principal
      +
Successful Disbursement
      -
Successful Repayment
      =
New Outstanding Principal
```

### Transition Rules

| Event             | Outcome    | Transition                   |
| ----------------- | ---------- | ---------------------------- |
| Loan Disbursement | Successful | Principal + disbursed amount |
| Loan Disbursement | Failed     | No change                    |
| Loan Repayment    | Successful | Principal − repayment amount |
| Loan Repayment    | Failed     | No change                    |

For v1.0.0, the full amount of a successful Loan Repayment is treated as principal repayment.

No separate interest or fee allocation is modelled.

### Integrity Rule

Outstanding Principal must not become negative.

```text
Outstanding Principal
        ≥
Repayment Amount
```

A repayment that would exceed the outstanding principal must not produce an invalid negative principal state.

The exact validation and failure handling will be enforced during financial-processing and ledger implementation.

---

## 5. Beneficiary Financial Position

### Domain

Oman Remit.

### State Transition

A successful Remittance increases the beneficiary's financial position by the remitted amount.

```text
Previous Financial Position
        +
Successful Remittance
        =
Updated Financial Position
```

### Transition Rules

| Event      | Outcome    | Transition                 |
| ---------- | ---------- | -------------------------- |
| Remittance | Successful | Position + remitted amount |
| Remittance | Failed     | No change                  |

The v1.0.0 model does not introduce a separate Remittance Withdrawal event.

Consequently, subsequent Ananse activity is not modelled as a corresponding decrease to the Oman Remit financial position.

This preserves the independent Oman Remit domain without introducing an unnecessary internal withdrawal architecture.

---

## 6. Cross-Domain State Transitions

Cross-domain financial activity may produce consequences observable across more than one institutional domain.

### Loan Disbursement

```text
SikaCredit
Loan Disbursement
      ↓
Outstanding Loan Principal + Amount
      ↓
Customer receives disbursed value
      ↓
Ananse Wallet Balance + Amount
```

The loan obligation remains authoritative within SikaCredit.

The resulting wallet position remains authoritative within Ananse.

The model does not introduce a separate Loan Withdrawal event.

### Remittance

```text
Oman Remit
Remittance
      ↓
Beneficiary Financial Position + Amount
      ↓
Beneficiary receives value
      ↓
Ananse Wallet Balance + Amount
```

The beneficiary financial position remains within the Oman Remit domain.

The model does not introduce a separate Remittance Withdrawal event.

---

## 7. Failed Events

A failed event remains recorded as an event outcome but produces no financial consequence and therefore no financial state transition.

```text
Financial Event
      ↓
Failed
      ↓
No Financial Consequence
      ↓
No State Change
```

Examples include:

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

Failed events may remain analytically relevant even though they do not alter financial state.

---

## 8. State Reconstruction and Reconciliation

Authoritative financial states must be reconstructible from authoritative financial consequences.

### Customer Wallet

```text
Wallet Balance
=
Credits − Debits
```

### Outstanding Loan Principal

```text
Outstanding Principal
=
Successful Disbursements
−
Successful Principal Repayments
```

### Beneficiary Financial Position

```text
Beneficiary Financial Position
=
Successful Remittance Value
```

These relationships provide the basis for reconciliation and financial-integrity testing.

---

## 9. State Transition Integrity

The following rules apply across the financial-state model:

1. Failed events produce no financial state transition.
2. Only valid financial consequences may change authoritative financial state.
3. A successful debit must be supported by sufficient available financial position.
4. Financial state must remain reconstructible from authoritative financial consequences.
5. Cross-domain relationships must not create duplicate financial consequences.
6. Institutional mechanisms not required by v1.0.0 must not be introduced solely to explain a state transition.

---

## 10. State Transition Summary

| State                          | Increasing Transition         | Decreasing Transition        |
| ------------------------------ | ----------------------------- | ---------------------------- |
| Customer Wallet Balance        | Successful credit consequence | Successful debit consequence |
| Outstanding Loan Principal     | Successful Loan Disbursement  | Successful Loan Repayment    |
| Beneficiary Financial Position | Successful Remittance         | Not modelled in v1.0.0       |

---

## 11. Status

**Status:** Defined

The transition rules for the three authoritative financial states have been established for v1.0.0.

Detailed physical implementation of these transitions belongs to the subsequent ledger, financial-processing, and data-model design work.

---

## Core Principle

> **Authoritative financial state changes only through valid financial consequences of authoritative events; failed events do not change financial state.**
