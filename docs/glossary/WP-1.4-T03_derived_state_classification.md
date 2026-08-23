# OCB Derived State Classification

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-1.4 — State Model
**Ticket:** WP-1.4-T03
**Status:** **REVISED / LOCKED**
**Decision Type:** State-semantics definition

---

## Purpose

This document identifies states and classifications that are **derived from authoritative financial information** rather than constituting independent sources of financial truth.

It establishes the distinction between:

* authoritative financial positions;
* event and transaction lifecycle outcomes;
* derived lifecycle and credit states;
* analytical and intelligence classifications.

It does not define physical database structures, transaction-processing implementation, or analytical calculation logic.

The classification is aligned with the institutional ownership and conceptual relationships established in WP-2.1 and the logical relational model established in WP-2.2.

---

# 1. State Classification Principle

OCB distinguishes several different forms of state information:

```text
STATE INFORMATION

│
├── AUTHORITATIVE FINANCIAL POSITION
│
├── EVENT / TRANSACTION LIFECYCLE STATE
│
├── DERIVED LIFECYCLE / CREDIT STATE
│
└── ANALYTICAL / INTELLIGENCE STATE
```

These categories are related but are **not interchangeable**.

In particular:

> A derived classification must never replace the authoritative financial information from which it was derived.

---

# 2. Authoritative Financial Positions

The v1.0.0 financial-position model identifies three principal financial positions:

| Financial Position             | Institutional Domain | Nature              |
| ------------------------------ | -------------------- | ------------------- |
| Customer Wallet Balance        | Ananse Telecom       | Monetary position   |
| Outstanding Loan Principal     | SikaCredit           | Monetary obligation |
| Beneficiary Financial Position | Oman Remit           | Monetary position   |

These positions represent financial reality within their respective institutional domains.

They are not analytical classifications.

---

## 2.1 Customer Wallet Balance

The customer wallet balance represents the monetary position associated with an Ananse wallet.

The wallet itself remains a distinct institutional financial object from the customer and transaction. WP-2.2 therefore represents `ANANSE_WALLET` separately from `ANANSE_CUSTOMER` and `ANANSE_TRANSACTION`. 

The balance may be reconstructed from valid financial consequences arising from successful wallet-affecting activity.

```text
ANANSE TRANSACTION
        ↓
FINANCIAL CONSEQUENCE
        ↓
WALLET POSITION
```

The wallet position remains an Ananse-domain financial position.

---

## 2.2 Outstanding Loan Principal

Outstanding loan principal represents the remaining principal obligation associated with a SikaCredit loan.

SikaCredit owns the loan relationship and its associated repayment objects. The customer participates in that relationship as borrower. 

The logical model therefore distinguishes:

```text
SIKACREDIT_LOAN
        │
        └── SIKACREDIT_REPAYMENT
```

A repayment is an institutional financial activity in its own right rather than merely an attribute embedded inside the loan.

Outstanding principal may therefore be derived from authoritative loan and repayment activity while remaining a representation of the underlying financial position.

---

## 2.3 Beneficiary Financial Position

Beneficiary Financial Position represents the financial position associated with the beneficiary side of an Oman Remit remittance relationship.

WP-2.1 establishes this as a conceptual financial object/state within the Oman Remit domain. It is not introduced as an independent relational entity in the WP-2.2 logical model.

The logical model instead retains:

```text
OMAN_REMIT_CUSTOMER
        │
        └── OMAN_REMIT_REMITTANCE
```

The beneficiary financial position therefore remains a **conceptual financial position**, not a new OCB-owned operational table.

Its representation must not be interpreted as transferring ownership of the underlying financial object from Oman Remit to OCB.

---

# 3. Institutional Ownership and OCB Representation

The state model must preserve the institutional boundary established by WP-2.1.

```text
INSTITUTIONAL FINANCIAL OBJECT
            ↓
      INSTITUTION OWNS
            ↓
       OCB OBSERVES
            ↓
       OCB RESOLVES
            ↓
FINANCIAL CONSEQUENCE MAY BE
REPRESENTED IN OCB'S ANALYTICAL
        LEDGER MODEL
```

The important distinction is:

```text
SOURCE FINANCIAL REALITY
        ≠
OCB REPRESENTATION OF THAT REALITY
```

The existence of an OCB analytical representation does not create institutional ownership.

WP-2.1 explicitly establishes that institutional financial objects remain institution-owned while OCB observes and resolves them and may represent their financial consequences in its analytical ledger model. 

---

# 4. Event and Transaction Lifecycle States

Event and transaction lifecycle states describe the condition or outcome of an event as it moves through processing.

These are **not financial-position states**.

Examples include:

```text
Initiated
Validated
Processing
Successful
Failed
Rejected
Reversed
Corrected
```

The precise lifecycle and transition semantics are deferred to WP-2.5 and the financial-processing architecture.

The important distinction for WP-1.4 is:

```text
EVENT STATE
    ≠
FINANCIAL POSITION
```

For example:

```text
CASH-OUT
   ↓
FAILED
   ↓
NO FINANCIAL CONSEQUENCE
   ↓
WALLET POSITION UNCHANGED
```

Conversely:

```text
CASH-OUT
   ↓
SUCCESSFUL
   ↓
VALID FINANCIAL CONSEQUENCE
   ↓
WALLET POSITION DECREASES
```

A lifecycle state therefore describes **what happened to the event**, while the financial position describes **the resulting financial condition**.

The project control baseline explicitly reserves initiation, validation, processing, success, failure, rejection, reversal and correction for transaction lifecycle modelling in WP-2.5. 

---

# 5. Derived Lifecycle and Credit States

Derived lifecycle and credit states are classifications calculated from authoritative financial information and applicable business rules.

They are **not independent financial events**.

Examples include:

* Active;
* Delinquent;
* Defaulted;
* Closed.

---

## 5.1 Active

A loan may be classified as **Active** when its authoritative information satisfies the applicable active-loan conditions.

Conceptually:

```text
LOAN
  +
OUTSTANDING OBLIGATION
  +
APPLICABLE LIFECYCLE CONDITIONS
  ↓
ACTIVE
```

`Active` does not constitute a new financial event.

---

## 5.2 Delinquent

A loan may be classified as **Delinquent** where the applicable repayment obligation has not been satisfied according to the relevant repayment rule or deadline.

```text
LOAN
   +
REPAYMENT OBLIGATION
   +
REQUIRED PAYMENT NOT SATISFIED
   +
DELINQUENCY RULE
   ↓
DELINQUENT
```

The delinquency classification is therefore derived from authoritative loan and repayment information.

The repayment activity itself remains institution-owned within SikaCredit.

---

## 5.3 Defaulted

`Defaulted` is a derived credit classification.

It is determined from authoritative information such as:

* loan information;
* outstanding principal;
* repayment activity;
* repayment timing;
* applicable default criteria.

Conceptually:

```text
LOAN
   +
REPAYMENT HISTORY
   +
REPAYMENT CONDITIONS
   +
DEFAULT RULE
   ↓
DEFAULTED
```

Default is therefore **not required to exist as an independent financial event**.

This is consistent with the later intelligence model, where credit intelligence explicitly analyses delinquency and defaults. 

---

## 5.4 Closed

A loan may be classified as **Closed** when its outstanding financial obligation has been satisfied and the applicable closure conditions are met.

```text
OUTSTANDING PRINCIPAL = 0
        +
CLOSURE CONDITIONS
        ↓
CLOSED
```

`Closed` describes the condition of the lending relationship.

It does not constitute an independent financial event.

---

# 6. Analytical and Intelligence States

Analytical and intelligence states are classifications produced by applying approved analytical rules to authoritative information.

Examples include:

* elevated transaction velocity;
* unusual transaction behaviour;
* concentrated financial exposure;
* anomalous activity;
* elevated risk;
* unusual repayment behaviour;
* abnormal financial concentration.

These classifications are **not authoritative financial positions**.

They are intelligence outputs.

```text
AUTHORITATIVE INFORMATION
          ↓
     ANALYTICAL RULE
          ↓
ANALYTICAL / INTELLIGENCE STATE
```

For example:

```text
TRANSACTION HISTORY
       +
TIME WINDOW
       +
VELOCITY RULE
       ↓
ELEVATED VELOCITY
```

The classification does not alter the underlying transactions or financial positions.

---

# 7. Derivation Chain

The complete state relationship is:

```text
AUTHORITATIVE FINANCIAL ACTIVITY
            ↓
     FINANCIAL CONSEQUENCE
            ↓
AUTHORITATIVE FINANCIAL POSITION
            ↓
 DERIVED LIFECYCLE / CREDIT STATE
            ↓
ANALYTICAL / INTELLIGENCE STATE
```

However, this is **not a mandatory sequential database pipeline**.

Some analytical classifications may be derived directly from authoritative events or financial activity without first materialising an intermediate state.

Therefore:

```text
Authoritative Information
        ↓
     Approved Rule
        ↓
Derived Classification
```

is the fundamental principle.

---

# 8. Example — Credit State Derivation

```text
SIKACREDIT LOAN
       ↓
LOAN DISBURSEMENT
       ↓
OUTSTANDING PRINCIPAL
       ↓
REPAYMENT ACTIVITY
       ↓
REPAYMENT PERFORMANCE
       ↓
DELINQUENCY / DEFAULT RULE
       ↓
DERIVED CREDIT STATE
```

The derived state does not replace:

* the loan;
* the repayment records;
* the outstanding principal;
* the underlying financial activity.

The authoritative records remain the source of truth.

---

# 9. Example — Transaction Intelligence

```text
ANANSE TRANSACTIONS
        ↓
AUTHORITATIVE FINANCIAL ACTIVITY
        ↓
TRANSACTION HISTORY
        ↓
VELOCITY / BEHAVIOURAL RULE
        ↓
ANOMALOUS OR ELEVATED ACTIVITY
```

The analytical classification does not modify the underlying transaction.

This preserves the separation between financial processing and downstream intelligence processing established elsewhere in the architecture.

---

# 10. State Authority

The authority hierarchy is:

| State Information                   | Authority                                                          |
| ----------------------------------- | ------------------------------------------------------------------ |
| Institutional financial activity    | Relevant institution                                               |
| Financial position                  | Authoritative financial information / valid financial consequences |
| Event / transaction lifecycle state | Financial-processing lifecycle                                     |
| Derived lifecycle state             | OCB-approved business rule applied to authoritative information    |
| Derived credit state                | OCB-approved credit rule applied to authoritative information      |
| Analytical / intelligence state     | OCB analytical or intelligence logic                               |

OCB does not acquire institutional ownership merely by representing or analysing institutional information.

The logical model reinforces this separation by retaining institutional customer and activity entities independently while using OCB identity resolution as a separate mapping layer. 

---

# 11. State Classification Summary

| Concept                        | Classification                                         |
| ------------------------------ | ------------------------------------------------------ |
| Customer Wallet Balance        | Authoritative financial position                       |
| Outstanding Loan Principal     | Authoritative financial position                       |
| Beneficiary Financial Position | Conceptual institutional financial position            |
| Initiated                      | Lifecycle state                                        |
| Validated                      | Lifecycle state                                        |
| Processing                     | Lifecycle state                                        |
| Successful                     | Event outcome / lifecycle state                        |
| Failed                         | Event outcome / lifecycle state                        |
| Rejected                       | Lifecycle state; detailed semantics deferred to WP-2.5 |
| Reversed                       | Lifecycle state / corrective processing state          |
| Corrected                      | Lifecycle/corrective processing state                  |
| Active                         | Derived lifecycle state                                |
| Delinquent                     | Derived credit state                                   |
| Defaulted                      | Derived credit state                                   |
| Closed                         | Derived lifecycle state                                |
| Elevated transaction velocity  | Analytical/intelligence state                          |
| Anomalous activity             | Analytical/intelligence state                          |
| Elevated risk                  | Analytical/intelligence state                          |

---

# 12. What Is Not a Derived Financial State

The following must not be treated as independent authoritative financial positions merely because they may influence or describe financial activity:

| Concept                | Treatment                                          |
| ---------------------- | -------------------------------------------------- |
| Successful             | Event/lifecycle state                              |
| Failed                 | Event/lifecycle state                              |
| Rejected               | Lifecycle state                                    |
| Active                 | Derived lifecycle state                            |
| Delinquent             | Derived credit state                               |
| Defaulted              | Derived credit state                               |
| Closed                 | Derived lifecycle state                            |
| P2P Send               | Financial consequence / event leg                  |
| P2P Receive            | Financial consequence / event leg                  |
| Ledger Entry           | Accounting representation of financial consequence |
| Analytical risk score  | Analytical output                                  |
| Anomaly classification | Analytical output                                  |

In particular, a ledger entry does not become the originating financial event.

WP-2.1 explicitly establishes that ledger entries represent accounting consequences and do not replace or merge with the originating financial activity. 

---

# 13. Source Ownership and Derived State

OCB may derive classifications across institutional boundaries after resolving the relevant institutional identities.

For example:

```text
ANANSE CUSTOMER
       \
        \
SIKACREDIT CUSTOMER
        \
         → OCB RESOLVED CUSTOMER
        /
OMAN REMIT CUSTOMER
```

OCB can then apply analytical or derived-state logic to the resolved cross-institutional view.

However:

```text
OCB DERIVATION
      ≠
TRANSFER OF SOURCE OWNERSHIP
```

This is consistent with the logical model's decision that institutional attributes remain source-owned while OCB performs identity resolution and may create downstream derived analytical attributes. 

---

# 14. Scope Boundary

WP-1.4-T03 does not define:

* physical tables for derived states;
* database columns for lifecycle classifications;
* default or delinquency calculation algorithms;
* analytical risk algorithms;
* transaction lifecycle transition paths;
* ledger posting mechanics.

Those concerns belong to the appropriate later architectural and implementation stages.

In particular:

* transaction lifecycle semantics belong to WP-2.5;
* ledger architecture belongs to WP-2.6;
* financial processing belongs to WP-3;
* analytical architecture belongs to WP-6;
* credit intelligence belongs to WP-7.6.

---

# 15. Final Decision

The OCB v1.0.0 state model distinguishes:

```text
FINANCIAL REALITY
        ↓
AUTHORITATIVE FINANCIAL POSITION
        ↓
DERIVED CONDITION
        ↓
ANALYTICAL CONCLUSION
```

while separately recognising:

```text
FINANCIAL EVENT
        ↓
EVENT / TRANSACTION LIFECYCLE STATE
```

The three principal financial positions remain:

1. **Customer Wallet Balance** — Ananse Telecom;
2. **Outstanding Loan Principal** — SikaCredit;
3. **Beneficiary Financial Position** — Oman Remit.

Institutional ownership remains unchanged. OCB's observation, identity resolution, analytical representation, or derived classification does not transfer ownership of the underlying institutional financial object.

**WP-1.4-T03 — REVISED AND LOCKED.**

---

## Core Principle

> **Authoritative financial information represents financial reality; lifecycle states describe what happened to financial activity; derived states describe conditions inferred from that reality; and analytical states describe conclusions produced by approved intelligence rules.**

This version is materially stronger than the original because it no longer conflates **a financial position**, **a transaction lifecycle state**, and **a derived classification** into one generic idea of "state." That distinction will matter enormously once we get to the actual SQL state engine and intelligence layer.
