# OCB Initial Financial State Inventory

**Programme:** OCB Platform v1.0.0
**Work Package:** WP-1.4 — State Model
**Ticket:** WP-1.4-T01
**Status:** **REVISED / LOCKED**
**Decision Type:** Financial state taxonomy and initial state inventory

---

## 1. Purpose

This document defines the initial financial-state inventory for the OCB Platform v1.0.0.

It establishes the distinction between:

* financial position states;
* event outcomes;
* lifecycle and derived states;
* analytical states.

It also establishes the relationship between institutional financial states and OCB's observation boundary.

This document does **not** define:

* physical database structures;
* relational implementation;
* ledger table design;
* state-transition algorithms;
* analytical calculations.

Those concerns are addressed by later work packages.

---

# 2. State Principle

A **state** describes a condition that is true at a particular point in time.

OCB does not treat every status, event outcome, or analytical classification as a financial state.

The state model distinguishes:

```text
STATE
│
├── Financial Position State
│
├── Event Outcome
│
├── Lifecycle / Derived State
│
└── Analytical State
```

These categories have different meanings, authorities, and derivation mechanisms.

The distinction is important because an analytical classification must never be mistaken for an authoritative financial position.

---

# 3. Institutional Ownership and OCB Observation Boundary

The financial states represented by the platform originate from institution-owned financial activity.

The institutional domains remain independent:

```text
ANANSE TELECOM
    ├── Customer
    ├── Wallet
    └── Transaction

SIKACREDIT
    ├── Customer
    ├── Loan
    └── Repayment

OMAN REMIT
    ├── Customer
    └── Remittance
```

The logical model preserves these institutional boundaries. `ANANSE_WALLET`, `SIKACREDIT_LOAN`, and `OMAN_REMIT_REMITTANCE` remain distinct institution-owned objects rather than being merged into an OCB financial object. 

OCB's role is to:

```text
Institutional financial activity
            ↓
      OCB observes
            ↓
     OCB resolves identity
            ↓
Financial consequences can be represented
in OCB's financial / analytical model
```

Therefore, the existence of an OCB financial-state representation does **not** imply that OCB owns the underlying institutional financial object.

---

# 4. Initial Financial Position State Inventory

The v1.0.0 conceptual state inventory contains three principal financial-position states:

| Financial Position State       | Institutional Domain | Nature              |
| ------------------------------ | -------------------- | ------------------- |
| Customer Wallet Balance        | Ananse Telecom       | Monetary position   |
| Outstanding Loan Principal     | SikaCredit           | Monetary obligation |
| Beneficiary Financial Position | Oman Remit           | Monetary position   |

These states are conceptually distinct even though their financial consequences may subsequently be analysed together.

---

# 5. Customer Wallet Balance

## 5.1 Domain

**Ananse Telecom**

## 5.2 Meaning

The customer's monetary position represented by an Ananse wallet at a particular point in time.

The wallet is a distinct financial object from the customer and from individual transaction records. The logical model therefore represents the wallet independently as `ANANSE_WALLET`. 

## 5.3 Nature

**Monetary position**

## 5.4 State Origin

The wallet balance is derived from authoritative wallet-affecting financial activity.

Conceptually:

```text
Previous Valid Wallet State
            +
Successful Financial Consequence
            =
New Valid Wallet State
```

Successful Ananse financial activity may include:

* Cash-in;
* Cash-out;
* P2P Transfer;
* Merchant Payment.

The transaction remains the authoritative activity record; the resulting wallet position is a state derived from the applicable financial consequences.

The logical model confirms that Ananse transactions reference both the Ananse customer and Ananse wallet because these are distinct relational objects. 

## 5.5 Cross-Domain Consequences

A financial consequence originating outside Ananse may ultimately have analytical relevance to an Ananse customer or wallet.

However, the conceptual state model must **not** imply a direct institutional relationship that has not been established in the logical model.

Therefore, this is **not** represented as:

```text
SikaCredit → Ananse Wallet
```

or:

```text
Oman Remit → Ananse Wallet
```

as a direct logical relationship.

Such relationships belong to the financial-consequence architecture rather than the institutional source-entity model. 

---

# 6. Outstanding Loan Principal

## 6.1 Domain

**SikaCredit**

## 6.2 Meaning

The amount of principal remaining outstanding on a SikaCredit loan at a particular point in time.

## 6.3 Nature

**Monetary obligation**

## 6.4 State Origin

The state is derived from authoritative SikaCredit loan and repayment activity.

Conceptually:

```text
Loan Principal
      ↓
Loan Disbursement
      ↓
Outstanding Principal
      ↓
Loan Repayments
      ↓
Reduced Outstanding Principal
```

The logical model deliberately separates:

```text
SIKACREDIT_LOAN
        │
        └── SIKACREDIT_REPAYMENT
```

with a one-to-many relationship. 

Therefore, **Outstanding Loan Principal is a financial state, not a separate relational entity in WP-2.2**.

The `principal_amount` attribute on `SIKACREDIT_LOAN` represents the loan's principal amount; outstanding principal is a state that can be derived from the authoritative loan and repayment history.

## 6.5 Loan Rate

Loan interest rate remains a loan attribute and an analytical input.

It is not itself a financial-position state.

---

# 7. Beneficiary Financial Position

## 7.1 Domain

**Oman Remit**

## 7.2 Meaning

The financial position established for the beneficiary as a consequence of an applicable successful Oman Remit remittance.

## 7.3 Nature

**Monetary position**

## 7.4 State Boundary

The beneficiary financial position represents a conceptual financial state associated with Oman Remit's remittance activity.

The v1.0.0 logical model does **not** introduce a separate beneficiary entity or a beneficiary withdrawal event.

The logical model instead represents:

```text
OMAN_REMIT_CUSTOMER
        │
        └── OMAN_REMIT_REMITTANCE
```

with the remittance remaining an Oman Remit-owned institutional activity. 

Therefore, the state should **not** be interpreted as evidence that OCB models the beneficiary's complete external financial account or operational infrastructure.

## 7.5 Cross-Domain Analysis

A remittance may have financial consequences that become relevant to analysis of customer activity elsewhere.

However:

```text
OMAN REMIT
     │
 Remittance
     │
     ↓
Financial consequence
     │
     ↓
OCB analytical / financial model
```

must not be interpreted as:

```text
OMAN REMIT
     │
     └── directly owns or controls
             ANANSE WALLET
```

The institutions remain operationally independent.

---

# 8. Financial Position States Are Not Relational Entities

A critical distinction is established by this ticket:

> **A financial state does not necessarily require a corresponding standalone relational entity.**

For example:

```text
ANANSE_WALLET
      ↓
Customer Wallet Balance
```

The wallet is an institutional object represented in the logical model.

The balance is a financial state associated with that object.

Likewise:

```text
SIKACREDIT_LOAN
      ↓
Outstanding Loan Principal
```

The loan is the institutional object.

Outstanding principal is the resulting financial state.

And:

```text
OMAN_REMIT_REMITTANCE
      ↓
Beneficiary Financial Position
```

The remittance is the institutional activity.

The beneficiary financial position is the resulting conceptual state.

This prevents the state model from unnecessarily creating relational entities merely to represent calculated or derived positions.

---

# 9. Event Outcomes

Event outcomes describe what happened to an authoritative financial event.

They are **not financial-position states**.

The current outcome taxonomy is:

* Successful;
* Failed;
* Rejected.

For example:

```text
Cash-out
    ↓
Failed
    ↓
No successful financial consequence
    ↓
Wallet financial state unchanged
```

Whereas:

```text
Cash-out
    ↓
Successful
    ↓
Financial consequence
    ↓
Wallet financial state changes
```

Event outcomes were established by the WP-1.3 financial event model and are not redefined by this ticket.

---

# 10. Lifecycle and Derived States

Lifecycle and derived states describe the condition of an entity, obligation, or financial relationship.

Examples include:

* Active;
* Delinquent;
* Defaulted;
* Closed.

These are not independent monetary positions.

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

A lifecycle or derived state must remain traceable to authoritative underlying information.

For example, loan default should be derived from authoritative loan information, repayment activity, applicable obligations, and the relevant business rules.

---

# 11. Analytical States

Analytical states are classifications generated by applying analytical rules to authoritative information.

Examples include:

* Anomalous;
* High-risk;
* Elevated transaction velocity;
* Unusual concentration.

These are **not authoritative financial states**.

They are intelligence outputs.

Conceptually:

```text
Authoritative Events
        +
Financial States
        +
Approved Context
        ↓
Analytical Logic
        ↓
Analytical State
```

An analytical state therefore cannot replace the underlying financial event or financial position.

---

# 12. State Authority

The categories have different sources of authority:

| Category                  | Authority                                                                    |
| ------------------------- | ---------------------------------------------------------------------------- |
| Financial Position State  | Authoritative financial information within the relevant institutional domain |
| Event Outcome             | Outcome associated with an authoritative financial event                     |
| Lifecycle / Derived State | Rule-based interpretation of authoritative information                       |
| Analytical State          | Analytical/intelligence logic applied to authoritative information           |

The OCB platform must preserve the distinction between:

```text
Source authority
      ↓
OCB observation / resolution
      ↓
OCB financial representation
      ↓
OCB analytical interpretation
```

OCB's analytical representation does not transfer institutional ownership of the source financial object.

This is consistent with the logical model's explicit preservation of source ownership and identity separation. 

---

# 13. States Excluded from the Financial-Position Inventory

The following are intentionally excluded from the financial-position state inventory:

| Candidate   | Classification                    |
| ----------- | --------------------------------- |
| Successful  | Event outcome                     |
| Failed      | Event outcome                     |
| Rejected    | Event outcome                     |
| Active      | Lifecycle / derived state         |
| Delinquent  | Derived credit state              |
| Defaulted   | Derived credit state              |
| Closed      | Lifecycle / derived state         |
| P2P Send    | Financial consequence / leg       |
| P2P Receive | Financial consequence / leg       |
| Settlement  | Financial consequence / status    |
| Correction  | Institutional control / event     |
| Reversal    | Financial event/control mechanism |
| Adjustment  | Financial control mechanism       |

These may be operationally or analytically important without constituting independent financial-position states.

---

# 14. Cross-Institutional State Relationships

The three financial-position states belong to independent institutional domains:

```text
ANANSE TELECOM
    │
    └── Customer Wallet Balance


SIKACREDIT
    │
    └── Outstanding Loan Principal


OMAN REMIT
    │
    └── Beneficiary Financial Position
```

Their independence does not prevent OCB from analysing relationships between them.

For example:

```text
SIKACREDIT
    │
    └── Loan / Repayment Activity
             ↓
    Outstanding Loan Principal
             ↓
      OCB Customer Identity
             ↓
    Ananse Financial Activity
             ↓
      Customer Wallet Balance
```

Similarly:

```text
OMAN REMIT
    │
    └── Remittance Activity
             ↓
    Beneficiary Financial Position
             ↓
      OCB Customer Identity
             ↓
    Ananse Financial Activity
             ↓
      Customer Wallet Balance
```

These are **analytical relationships**, not declarations of shared institutional ownership or direct operational integration.

The logical model deliberately avoids imposing direct relationships between SikaCredit/Oman Remit and the Ananse wallet. 

---

# 15. Relationship to the Ledger / Financial-Core Model

The conceptual architecture is:

```text
Institutional Financial Activity
            ↓
      Financial Consequence
            ↓
       Ledger Posting
            ↓
     Financial State
            ↓
    Analytical Interpretation
```

The ledger consequence does not replace the originating institutional event or object.

The institutional source remains authoritative for the activity it owns.

OCB's ledger/financial model provides a controlled representation of the resulting financial consequences for reconciliation and analysis.

This preserves the architectural principle established during Programme 2:

> **Institutional financial objects remain institution-owned → OCB observes/resolves them → their financial consequences can be represented in OCB's financial / analytical ledger model.**

---

# 16. Scope Boundary

The v1.0.0 state model does not introduce:

* loan withdrawal/drawdown events;
* remittance withdrawal events;
* separate beneficiary account architecture;
* separate institutional wallet architectures;
* institutional float states;
* internal settlement-account states;
* shared institutional accounts;
* shared institutional ledgers;
* operational integration between the three institutions.

The logical model likewise does not assume shared databases, ledgers, or operational infrastructure between institutions.

Future architecture may introduce additional states only where a concrete intelligence, financial-processing, or supervisory requirement justifies them.

---

# 17. Status

**Status: REVISED / LOCKED**

The v1.0.0 initial financial-position inventory consists of:

1. **Customer Wallet Balance** — Ananse Telecom;
2. **Outstanding Loan Principal** — SikaCredit;
3. **Beneficiary Financial Position** — Oman Remit.

These are **conceptual financial states**, not a declaration that each requires a separate relational entity.

The state taxonomy additionally distinguishes:

* financial-position states;
* event outcomes;
* lifecycle / derived states;
* analytical states.

The detailed transition semantics and business rules are deferred to **WP-1.4-T02**.

---

# Core Principle

> **OCB distinguishes what financial position exists, what happened to an authoritative event, what condition a financial relationship is in, and what an analytical rule concludes from that information.**
>
> **Institutional financial objects remain institution-owned. OCB observes and resolves them; their financial consequences may then be represented in OCB's financial and analytical model without transferring institutional ownership.**

**WP-1.4-T01 — REVISED AND LOCKED.**
