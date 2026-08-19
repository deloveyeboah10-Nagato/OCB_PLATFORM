# OCB Financial State Reconstructability Validation

## Purpose

This document validates whether the authoritative financial states defined for OCB Platform v1.0.0 can be reconstructed from authoritative financial events and their financial consequences.

The validation establishes the reconstruction basis and confirms that failed events do not alter reconstructed financial state.

It does not define physical SQL implementation.

---

## 1. Reconstructability Principle

An authoritative financial state must be reproducible from authoritative financial consequences.

```text
Authoritative Events
        ↓
Financial Consequences
        ↓
Reconstructed Financial State
```

A failed event produces no financial consequence and is therefore excluded from financial-state reconstruction.

---

## 2. Customer Wallet Balance

Customer Wallet Balance is reconstructable from successful financial consequences affecting the customer's wallet.

```text
Opening / Prior Balance
        +
Successful Credits
        -
Successful Debits
        =
Reconstructed Wallet Balance
```

### Relevant Consequences

* Cash-in credit;
* Cash-out debit;
* P2P sender debit;
* P2P receiver credit;
* Merchant payment debit;
* applicable successful cross-domain credit.

For P2P transfers:

```text
P2P Transfer
      │
      ├── Sender → Debit
      └── Receiver → Credit
```

The two legs belong to the same authoritative P2P Transfer event.

---

## 3. Outstanding Loan Principal

Outstanding Loan Principal is reconstructable from successful loan disbursements and successful loan repayments.

```text
Successful Loan Disbursements
        -
Successful Loan Repayments
        =
Reconstructed Outstanding Principal
```

For v1.0.0, the full amount of a successful Loan Repayment reduces principal.

No separate interest or fee allocation is required for reconstruction.

---

## 4. Beneficiary Financial Position

Beneficiary Financial Position is reconstructable from successful remittance value within the OCB observation boundary.

```text
Successful Remittance Value
        =
Reconstructed Beneficiary Financial Position
```

The model does not introduce a separate Oman Remit withdrawal event.

Consequently, OCB does not attempt to reconstruct reductions to the beneficiary financial position arising from an unmodelled internal withdrawal mechanism.

This preserves the defined scope of the Oman Remit domain.

---

## 5. Failed Events

Failed events are excluded from financial-state reconstruction because they produce no financial consequence.

```text
Financial Event
      ↓
Failed
      ↓
No Financial Consequence
      ↓
Excluded from State Reconstruction
```

Examples include:

```text
Failed Cash-out
    → No wallet debit

Failed P2P Transfer
    → No sender debit
    → No receiver credit

Failed Merchant Payment
    → No wallet debit

Failed Loan Disbursement
    → No increase in principal

Failed Loan Repayment
    → No reduction in principal

Failed Remittance
    → No increase in beneficiary financial position
```

Failed events may remain available for behavioural and intelligence analysis.

---

## 6. Chronological Reconstruction

Financial state reconstruction must preserve event order.

A final aggregate alone is insufficient to validate financial integrity.

For example:

```text
Starting Balance = GH₵100

10:00
Cash-out = GH₵100
Balance = GH₵0

10:01
Cash-out = GH₵100
Balance = INVALID
```

The second event must therefore be evaluated against the state established by preceding successful events.

Conceptually:

```text
Event 1
   ↓
State 1
   ↓
Event 2
   ↓
State 2
   ↓
Event 3
   ↓
State 3
```

This ensures that state reconstruction can identify invalid chronological financial activity rather than merely producing an end-of-period total.

---

## 7. Reconstruction Integrity Rules

The following rules apply:

1. Authoritative financial states must be reconstructible from authoritative financial consequences.
2. Failed events must not contribute financial consequences.
3. State reconstruction must preserve event chronology.
4. Successful debits must be evaluated against the financial state existing immediately before the debit.
5. P2P sender and receiver legs must remain attributable to the same P2P Transfer event.
6. Outstanding Loan Principal must not become negative.
7. Unmodelled institutional mechanisms must not be inferred during reconstruction.
8. Reconstructed state must provide a basis for subsequent reconciliation and integrity testing.

---

## 8. Reconstructability Summary

| Financial State                | Reconstructable | Basis                                            |
| ------------------------------ | --------------- | ------------------------------------------------ |
| Customer Wallet Balance        | Yes             | Successful credits − successful debits           |
| Outstanding Loan Principal     | Yes             | Successful disbursements − successful repayments |
| Beneficiary Financial Position | Yes             | Successful remittance value                      |
| Failed events                  | Excluded        | No financial consequence                         |

---

## 9. Scope Boundary

Reconstructability does not require reproducing the complete internal accounting architecture of each simulated institution.

OCB reconstructs only the authoritative financial positions required within the v1.0.0 observation boundary.

Internal mechanisms not explicitly modelled remain outside the reconstruction scope.

---

## 10. Status

**Status:** Defined

The three authoritative financial states are considered reconstructable from the approved v1.0.0 event and consequence model.

WP-1.4 is therefore complete.

---

## Core Principle

> **If an authoritative financial state cannot be reconstructed from authoritative financial consequences while preserving event chronology, the financial model cannot be considered fully trustworthy.**
