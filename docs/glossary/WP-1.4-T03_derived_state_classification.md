# OCB Derived State Classification

## Purpose

This document identifies states that are derived from authoritative OCB financial information rather than directly established as authoritative financial states.

It distinguishes:

* authoritative financial states;
* event outcomes;
* derived lifecycle and credit states;
* analytical and intelligence-derived states.

It does not define physical database structures or analytical implementation.

---

## 1. State Classification

OCB distinguishes four categories:

```text
State Information
│
├── Authoritative Financial State
├── Event Outcome
├── Derived Lifecycle / Credit State
└── Analytical / Intelligence State
```

These categories must not be treated as interchangeable.

---

## 2. Authoritative Financial States

The following are authoritative financial states established in WP-1.4-T01:

| State                          | Domain         |
| ------------------------------ | -------------- |
| Customer Wallet Balance        | Ananse Telecom |
| Outstanding Loan Principal     | SikaCredit     |
| Beneficiary Financial Position | Oman Remit     |

These states are established from authoritative financial consequences.

They are not derived analytical classifications.

---

## 3. Event Outcomes

Event outcomes describe what happened to an authoritative financial event.

For v1.0.0, the approved outcomes are:

* Successful;
* Failed.

### Successful

A successful event produces its defined financial consequence and may therefore change financial state.

### Failed

A failed event produces no financial consequence and therefore produces no financial state transition.

```text
Financial Event
      ↓
Failed
      ↓
No Financial Consequence
      ↓
No Financial State Change
```

### Rejected

`Rejected` is **not an approved v1.0.0 event outcome**.

No distinct business meaning has been established that justifies separating rejection from failure.

It must not be introduced as a separate outcome without a defined business scenario and appropriate architectural decision where required.

---

## 4. Derived Lifecycle and Credit States

These states are determined from authoritative financial information and applicable business rules.

They are not independently captured as authoritative financial events.

### 4.1 Active

A loan may be classified as active when an outstanding loan obligation exists and the applicable lifecycle conditions for an active loan are satisfied.

```text
Loan
+
Outstanding Obligation
+
Active Lifecycle Conditions
=
Active
```

The precise conditions will be established during subsequent loan modelling.

### 4.2 Delinquent

A loan may be classified as delinquent when repayment obligations are not satisfied according to the applicable repayment rules and deadlines.

```text
Repayment Obligation
+
Required Payment Not Satisfied
+
Applicable Delinquency Rule
=
Delinquent
```

The specific delinquency rule is not defined by this document.

### 4.3 Defaulted

Loan default is treated as a derived credit state.

It is determined from authoritative loan information, repayment activity, repayment deadlines, and the approved default rule.

```text
Loan Information
+
Repayment History
+
Repayment Deadline
+
Default Rule
=
Defaulted
```

Default is therefore not required as an independent financial event.

### 4.4 Closed

A loan may be classified as closed when its outstanding obligation has been satisfied and the applicable closure conditions are met.

```text
Outstanding Principal = 0
+
Closure Conditions
=
Closed
```

The precise closure conditions will be defined during subsequent loan modelling.

---

## 5. Analytical and Intelligence States

Analytical and intelligence states are classifications produced by applying approved analytical rules to authoritative information.

Examples may include:

* elevated transaction velocity;
* unusual transaction behaviour;
* concentrated financial exposure;
* anomalous activity;
* elevated risk.

These are not authoritative financial states.

They are analytical conclusions derived from authoritative events, financial consequences, financial states, and other approved information.

```text
Authoritative Information
        ↓
Analytical Rule
        ↓
Analytical / Intelligence State
```

The specific analytical states and their rules will be defined by the intelligence requirements.

---

## 6. Derivation Principle

Derived states must remain traceable to the authoritative information from which they are calculated.

```text
Authoritative Events
        ↓
Financial Consequences
        ↓
Authoritative Financial States
        ↓
Derived Lifecycle / Credit States
        ↓
Analytical / Intelligence States
```

A derived state must not replace or overwrite its underlying authoritative information.

For example:

```text
Loan
  ↓
Outstanding Principal
  ↓
Repayment History
  ↓
Default Rule
  ↓
Defaulted
```

The `Defaulted` classification does not replace the underlying loan, principal, or repayment history.

---

## 7. v1.0.0 Classification Summary

| Concept                        | Classification                  |
| ------------------------------ | ------------------------------- |
| Customer Wallet Balance        | Authoritative financial state   |
| Outstanding Loan Principal     | Authoritative financial state   |
| Beneficiary Financial Position | Authoritative financial state   |
| Successful                     | Event outcome                   |
| Failed                         | Event outcome                   |
| Rejected                       | Not approved for v1.0.0         |
| Active                         | Derived lifecycle state         |
| Delinquent                     | Derived credit state            |
| Defaulted                      | Derived credit state            |
| Closed                         | Derived lifecycle state         |
| Analytical risk classification | Analytical / intelligence state |

---

## 8. Scope Boundary

OCB v1.0.0 does not introduce independent authoritative events solely to record derived states.

In particular:

* loan default is derived;
* loan delinquency is derived;
* loan closure is derived;
* analytical risk states are derived;
* `Rejected` is not introduced without a defined business requirement.

This prevents derived classifications from becoming competing sources of financial truth.

---

## 9. Status

**Status:** Defined

The distinction between authoritative financial states, event outcomes, derived lifecycle/credit states, and analytical/intelligence states has been established for v1.0.0.

The rules required to calculate individual derived states will be defined during the relevant domain and intelligence modelling work.

---

## Core Principle

> **Authoritative states record financial reality; derived states describe conditions inferred from that reality; analytical states describe conclusions produced by approved intelligence rules.**
