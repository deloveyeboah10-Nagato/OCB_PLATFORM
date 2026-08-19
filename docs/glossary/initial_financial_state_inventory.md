# OCB Initial Financial State Inventory

## Purpose

This document identifies the financial and operational states required by the OCB Platform v1.0.0.

It establishes the initial state inventory and distinguishes financial-position states from event outcomes, lifecycle states, and analytical states.

It does not define physical database structures, ledger implementation, or analytical calculations.

---

## 1. State Principle

A state describes a condition that is true at a particular point in time.

The term "state" is used across several different contexts and must not be treated as a single semantic category.

OCB distinguishes:

```text
State
│
├── Financial Position State
│
├── Event Outcome
│
├── Lifecycle / Derived State
│
└── Analytical State
````

These categories have different purposes and sources of authority.

---

## 2. Financial Position States

Financial position states represent authoritative monetary positions or obligations within the observed institutional domains.

The v1.0.0 inventory contains three:

| Financial State                | Domain         | Nature              |
| ------------------------------ | -------------- | ------------------- |
| Customer Wallet Balance        | Ananse Telecom | Monetary position   |
| Outstanding Loan Principal     | SikaCredit     | Monetary obligation |
| Beneficiary Financial Position | Oman Remit     | Monetary position   |

---

## 3. Customer Wallet Balance

### Domain

Ananse Telecom.

### Meaning

The customer's monetary position within the Ananse mobile-money domain.

### Nature

Monetary position.

### Associated Events

The state may be affected by successful wallet-affecting events, including:

* Cash-in;
* Cash-out;
* P2P Transfer;
* Merchant Payment;
* applicable value received from another institutional domain.

Detailed state-transition rules are deferred to WP-1.4-T02.

---

## 4. Outstanding Loan Principal

### Domain

SikaCredit.

### Meaning

The amount of loan principal that remains outstanding for a customer.

### Nature

Monetary obligation.

### Associated Events

The state is established or changed through:

* Loan Disbursement;
* Loan Repayment.

Loan rate remains an important loan attribute and analytical metric and will be addressed during subsequent loan modelling.

Detailed state-transition and calculation rules are deferred to WP-1.4-T02.

---

## 5. Beneficiary Financial Position

### Domain

Oman Remit.

### Meaning

The monetary position established for a beneficiary as a consequence of a successful remittance.

### Nature

Monetary position.

### Purpose

This state preserves the financial independence of the Oman Remit domain while allowing subsequent analysis of its relationship with Ananse customer activity.

Conceptually:

```text
Oman Remit
    ↓
Remittance
    ↓
Beneficiary Financial Position
    ↓
Value available to beneficiary
    ↓
Ananse Telecom
    ↓
Customer Wallet
```

The v1.0.0 model does not introduce a separate remittance withdrawal event.

The internal institutional mechanism by which Oman Remit makes value available to the beneficiary remains outside the OCB observation boundary.

Detailed state semantics are deferred to WP-1.4-T02.

---

# 6. Event Outcomes

Event outcomes describe what happened to a financial event.

They are not independent financial-position states.

The relevant outcome categories currently include:

* Successful;
* Failed;
* Rejected.

For example:

```text
Cash-out
    ↓
Failed
    ↓
No financial consequence
    ↓
Wallet state unchanged
```

or:

```text
Cash-out
    ↓
Successful
    ↓
Financial consequence
    ↓
Wallet balance changes
```

Event-outcome semantics were established during WP-1.3 and are not redefined by this state inventory.

---

# 7. Lifecycle and Derived States

Lifecycle and derived states describe the condition of an entity, obligation, or financial relationship.

Examples include:

* Active;
* Delinquent;
* Defaulted;
* Closed.

These are not treated as independent monetary positions.

For example:

```text
Loan
    ↓
Active
    ↓
Repayment obligation
    ↓
Delinquency evaluation
    ↓
Delinquent / Defaulted
```

Loan default is derived from authoritative loan information, repayment activity, and applicable repayment obligations unless a future architectural decision establishes otherwise.

---

# 8. Analytical States

Analytical states are classifications created by applying analytical rules to authoritative financial information.

Examples may include:

* anomalous;
* high-risk;
* elevated transaction velocity;
* unusual concentration.

These are not authoritative financial states.

They are intelligence outputs derived from authoritative events, financial states, and other approved information.

---

# 9. State Authority

The categories have different sources of authority:

| Category                  | Authority                                                      |
| ------------------------- | -------------------------------------------------------------- |
| Financial Position State  | Authoritative financial information within the relevant domain |
| Event Outcome             | Outcome associated with an authoritative financial event       |
| Lifecycle / Derived State | Rule-based interpretation of authoritative information         |
| Analytical State          | Intelligence logic applied to authoritative information        |

The platform must not treat an analytical or derived state as a replacement for the underlying authoritative financial information.

---

# 10. States Not Included as Financial Position States

The following are intentionally excluded from the financial-position inventory:

| Candidate   | Classification                 |
| ----------- | ------------------------------ |
| Successful  | Event outcome                  |
| Failed      | Event outcome                  |
| Rejected    | Event outcome                  |
| Active      | Lifecycle / derived state      |
| Delinquent  | Derived credit state           |
| Defaulted   | Derived credit state           |
| Closed      | Lifecycle / derived state      |
| P2P Send    | Financial consequence / leg    |
| P2P Receive | Financial consequence / leg    |
| Settlement  | Financial consequence / status |
| Correction  | Institutional internal control |
| Reversal    | Not required for v1.0.0        |
| Adjustment  | Not required for v1.0.0        |

---

# 11. Cross-Institution State Relationships

The three financial-position states belong to independent institutional domains.

```text
ANANSE TELECOM
Customer Wallet Balance


SIKACREDIT
Outstanding Loan Principal


OMAN REMIT
Beneficiary Financial Position
```

Their independence does not prevent cross-domain analysis.

For example:

```text
SikaCredit
Loan Disbursement
        ↓
Outstanding Loan Principal
        ↓
Customer financial activity
        ↓
Ananse Telecom
Customer Wallet Balance
```

Similarly:

```text
Oman Remit
Remittance
        ↓
Beneficiary Financial Position
        ↓
Customer financial activity
        ↓
Ananse Telecom
Customer Wallet Balance
```

These relationships allow OCB to analyse financial behaviour across institutions without reproducing their complete internal operational architectures.

---

# 12. Scope Boundary

The v1.0.0 state model does not introduce:

* loan withdrawal/drawdown events;
* remittance withdrawal events;
* separate institutional wallet architectures;
* institutional float states;
* internal settlement-account states.

These mechanisms may be reconsidered in a future architecture if a concrete intelligence or supervisory requirement justifies them.

---

# 13. Status

**Status:** Defined

The v1.0.0 financial-position inventory consists of:

1. Customer Wallet Balance;
2. Outstanding Loan Principal;
3. Beneficiary Financial Position.

The broader OCB state taxonomy distinguishes these financial-position states from event outcomes, lifecycle/derived states, and analytical states.

Detailed state semantics and transition rules are deferred to **WP-1.4-T02**.

---

## Core Principle

> **OCB distinguishes what financial position exists, what happened to an event, what condition a financial relationship is in, and what an analytical rule concludes about that information.**

```

I think this is substantially stronger than the previous version because **"state" is now a controlled term rather than a bucket we keep throwing things into**.

Once this is saved, **WP-1.4-T01 is complete** and T02 can focus specifically on the semantics and transitions of the three financial-position states.
```
