**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.3 — Financial Event Model

**Ticket:** WP-1.3-T02

**Status:** **REVISED / LOCKED**

**Decision Type:** Financial-event business semantics

---

# OCB Financial Event Semantics

## Purpose

This document defines the business semantics of the authoritative financial events established in **WP-1.3-T01 — OCB Financial Event Catalogue**.

It defines, for each authoritative event:

* business meaning;
* originating institution;
* participating actor or role;
* source;
* destination;
* value;
* event timestamp;
* event outcome;
* financial consequence;
* financial-state consequence;
* downstream intelligence significance;
* OCB observation boundary.

This document defines **business semantics**.

It does not define:

* physical database structures;
* relational implementation;
* ledger table structures;
* SQL processing;
* ETL procedures;
* analytical calculations.

## The semantics are reconciled with the institutional relationships established in **WP-2.1** and the logical relational model established in **WP-2.2**, and with the financial-state model established in **WP-1.4**.

# 1. Relationship to the Financial Event Catalogue

The Financial Event Catalogue establishes **which financial events OCB recognises**.

This ticket establishes **what those events mean**.

```text
FINANCIAL EVENT CATALOGUE
            ↓
     WHAT IS RECOGNISED?
            ↓
FINANCIAL EVENT SEMANTICS
            ↓
      WHAT DOES IT MEAN?
            ↓
   FINANCIAL CONSEQUENCE
            ↓
      FINANCIAL STATE
```

The distinction must remain explicit:

```text
FINANCIAL EVENT
      ↓
What occurred?

EVENT OUTCOME
      ↓
What happened to the event?

FINANCIAL CONSEQUENCE
      ↓
What financial effect occurred?

FINANCIAL STATE
      ↓
What is subsequently true?

ANALYTICAL INTERPRETATION
      ↓
What can OCB infer?
```

A financial event remains an event even where its outcome produces no valid financial consequence.

---

# 2. Institutional Ownership and OCB Observation

The authoritative financial event belongs to the institutional domain that owns the underlying financial activity or object.

The institutional model remains:

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

These institutional objects remain separate in the logical model. WP-2.2 explicitly avoids merging institutional activities merely because they may produce related financial consequences.

OCB's role is:

```text
INSTITUTIONAL FINANCIAL OBJECT / ACTIVITY
                    ↓
              OCB OBSERVES
                    ↓
            IDENTITY RESOLUTION
                    ↓
     FINANCIAL CONSEQUENCE REPRESENTATION
                    ↓
       OCB FINANCIAL / ANALYTICAL MODEL
```

This does **not** transfer ownership of the underlying institutional object to OCB.

The governing principle is:

> **Institutional financial objects remain institution-owned → OCB observes/resolves them → their financial consequences can be represented in OCB's financial and analytical model.**

---

# 3. Ananse Telecom Events

## 3.1 Cash-in

### Business Meaning

A **Cash-in** is an Ananse Telecom financial event in which monetary value is credited to an Ananse wallet.

### Institution

**Ananse Telecom**

### Actor

Customer.

The precise operational mechanism by which cash is introduced into the mobile-money ecosystem is outside the OCB observation boundary.

### Source

The source of the financial value is represented at the event/consequence level required by OCB.

OCB does not model the complete external cash or agent-float architecture.

### Destination

Ananse customer wallet.

### Value

The monetary amount credited to the wallet.

### Timestamp

The authoritative event timestamp supplied by Ananse Telecom.

Event timestamp is distinct from ingestion, processing, and observation timestamps.

### Outcome

The event may have a successful or unsuccessful outcome according to the approved event/lifecycle semantics.

A non-successful event produces no valid wallet financial consequence.

### Financial Consequence

Successful:

```text
ANANSE WALLET
      +
    Amount
```

Non-successful:

```text
ANANSE WALLET
      =
   Unchanged
```

### State Consequence

A successful Cash-in increases the relevant Ananse wallet balance.

A failed or rejected Cash-in does not change the wallet balance.

### Downstream Intelligence Significance

Cash-in activity supports analysis of:

* wallet inflows;
* transaction velocity;
* funding patterns;
* concentration;
* customer behaviour;
* liquidity-related activity.

### Observation Boundary

OCB observes the Ananse financial activity and its wallet-level financial consequence.

OCB does not reproduce:

* agent float;
* physical cash position;
* internal cash management;
* internal settlement mechanisms;
* other unobserved Ananse operational architecture.

---

# 4. Cash-out

## 4.1 Business Meaning

A **Cash-out** is an Ananse Telecom financial event in which monetary value is debited from an Ananse wallet as value is withdrawn.

### Institution

**Ananse Telecom**

### Actor

Customer.

### Source

Ananse customer wallet.

### Destination

Customer / external value recipient as represented within the event.

The detailed external cash-distribution mechanism is outside the OCB observation boundary.

### Value

The amount deducted from the wallet.

### Timestamp

The authoritative Ananse event timestamp.

### Outcome

The event may be successful or unsuccessful.

A non-successful event produces no valid wallet debit.

### Financial Consequence

Successful:

```text
ANANSE WALLET
      -
    Amount
```

Non-successful:

```text
ANANSE WALLET
      =
   Unchanged
```

### State Consequence

A successful Cash-out decreases the Ananse wallet balance.

A failed or rejected Cash-out produces no wallet-state transition.

### Integrity

A successful debit must be supported by sufficient available wallet value.

Conceptually:

```text
Available Wallet Balance
          ≥
      Proposed Debit
```

If the applicable validation conditions are not satisfied, the event does not produce a valid financial consequence.

### Downstream Intelligence Significance

Cash-out activity supports analysis of:

* withdrawal velocity;
* wallet outflows;
* concentration;
* behavioural patterns;
* balance integrity.

### Observation Boundary

OCB observes the customer-side financial consequence.

Agent float, agent cash position, and internal settlement mechanisms remain outside the OCB event model.

---

# 5. P2P Transfer

## 5.1 Business Meaning

A **P2P Transfer** is an Ananse Telecom financial event in which value is transferred between two customer wallets.

WP-2.1 establishes P2P Transfer as **one authoritative business event** with sender and receiver legs representing its financial consequences.

### Institution

**Ananse Telecom**

### Actor

Sending customer.

### Source

Sender's Ananse wallet.

### Destination

Receiver's Ananse wallet.

### Value

The amount transferred.

### Timestamp

The authoritative Ananse transaction/event timestamp.

### Outcome

The transfer may be successful or unsuccessful.

### Financial Consequence

A successful P2P Transfer produces two financial legs:

```text
                 P2P TRANSFER
                       │
              ┌────────┴────────┐
              ↓                 ↓
         SENDER LEG        RECEIVER LEG
              ↓                 ↓
            DEBIT             CREDIT
              -                 +
            Amount            Amount
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

The two legs belong to the same authoritative P2P Transfer.

**P2P Send and P2P Receive are not independent financial events.**

### Failed / Rejected Behaviour

A non-successful P2P Transfer produces no valid financial consequence:

```text
P2P TRANSFER
      ↓
FAILED / REJECTED
      ↓
NO VALID CONSEQUENCE
      ↓
NO SENDER DEBIT
NO RECEIVER CREDIT
```

### State Consequence

Successful transfer:

```text
Sender Wallet   = − Amount
Receiver Wallet = + Amount
```

Non-successful transfer:

```text
Both Wallets = Unchanged
```

### Downstream Intelligence Significance

P2P activity supports analysis of:

* inflows;
* outflows;
* transaction velocity;
* concentration;
* customer-to-customer relationships;
* behavioural anomalies;
* network-like transaction patterns;
* reconciliation.

Repeated unsuccessful P2P attempts may remain analytically relevant even though they do not change financial state.

### Observation Boundary

OCB observes the P2P event and its customer-wallet financial consequences.

OCB does not reproduce Ananse's internal transfer-processing architecture.

---

# 6. Merchant Payment

## 6.1 Business Meaning

A **Merchant Payment** is an Ananse Telecom financial event in which a customer pays a merchant using an Ananse wallet.

### Institution

**Ananse Telecom**

### Actor

Customer.

### Source

Customer wallet.

### Destination

Merchant reference.

The merchant is an observable reference object, not an OCB financial account.

### Value

The amount paid by the customer.

### Timestamp

The authoritative Ananse event timestamp.

### Outcome

The event may be successful or unsuccessful.

### Financial Consequence

Successful:

```text
CUSTOMER WALLET
      -
    Amount
```

The merchant-side financial account or settlement mechanism is not modelled.

Non-successful:

```text
CUSTOMER WALLET
      =
   Unchanged
```

### State Consequence

A successful Merchant Payment decreases the customer's wallet balance.

A failed or rejected Merchant Payment produces no wallet-state transition.

### Downstream Intelligence Significance

Merchant Payment activity supports analysis of:

* customer spending behaviour;
* merchant concentration;
* payment velocity;
* merchant activity;
* unusual merchant relationships;
* potentially suspicious merchant behaviour.

### Observation Boundary

OCB observes:

* the Ananse payment event;
* the customer;
* the wallet consequence;
* the merchant reference.

OCB does not model a merchant financial account, merchant ledger, or merchant settlement architecture.

---

# 7. SikaCredit Events

## 7.1 Loan Disbursement

### Business Meaning

A **Loan Disbursement** is a SikaCredit financial event that establishes loan principal as an outstanding financial obligation.

### Institution

**SikaCredit**

### Actor

SikaCredit.

The borrower is the recipient/beneficiary of the lending activity, but SikaCredit remains the institution owning the loan relationship.

### Source

SikaCredit loan activity.

### Destination

Customer / borrower.

### Value

The disbursed loan principal.

### Timestamp

The authoritative SikaCredit disbursement timestamp.

### Outcome

The event may be successful or unsuccessful.

A non-successful disbursement does not create outstanding principal.

### Financial Consequence

Successful:

```text
SIKACREDIT LOAN
      ↓
Outstanding Principal
      +
Disbursed Amount
```

### State Consequence

A successful disbursement increases Outstanding Loan Principal.

The loan remains a SikaCredit-owned financial object.

### Cross-Domain Consequence Boundary

A successful loan disbursement may have broader financial relevance to the borrower.

However, the event must **not** be interpreted as an automatic Ananse wallet transaction.

The model does not establish:

```text
SIKACREDIT LOAN DISBURSEMENT
             ↓
ANANSE WALLET +
```

as a direct institutional relationship.

If Ananse separately records an actual wallet credit associated with the disbursement, that activity must be represented through Ananse's own authoritative transaction/event model.

This prevents double counting and preserves institutional ownership.

### Downstream Intelligence Significance

Loan Disbursement supports analysis of:

* credit exposure;
* disbursement volume;
* lending concentration;
* customer borrowing behaviour;
* repayment performance;
* delinquency;
* default;
* loan-rate-related analysis.

Loan rate remains an attribute and analytical input, not a financial state.

### Observation Boundary

OCB observes the SikaCredit loan activity and its financial consequence.

OCB does not reproduce SikaCredit's internal:

* credit decisioning;
* approval workflow;
* disbursement infrastructure;
* settlement architecture.

---

# 8. Loan Repayment

## 8.1 Business Meaning

A **Loan Repayment** is a SikaCredit financial event/activity that reduces an outstanding loan obligation.

WP-2.2 models repayments as independent institutional records associated with a loan:

```text
SIKACREDIT_LOAN
       │
       └── 0..N
          SIKACREDIT_REPAYMENT
```

Therefore a repayment is not merely an attribute of the loan.

### Institution

**SikaCredit**

### Actor

Customer / borrower.

### Source

The customer's repayment activity within the SikaCredit loan relationship.

### Destination

SikaCredit loan obligation.

### Value

The repayment amount.

### Timestamp

The authoritative repayment timestamp.

### Outcome

The event may be successful or unsuccessful.

### Financial Consequence

Successful:

```text
Outstanding Loan Principal
            -
      Repayment Amount
```

Non-successful:

```text
Outstanding Principal
       =
    Unchanged
```

### State Consequence

A successful repayment reduces Outstanding Loan Principal.

For v1.0.0:

```text
Successful Repayment
        ↓
Principal Reduction
```

The full successful repayment amount is treated as principal repayment.

No separate interest or fee allocation is modelled in this state model.

### Integrity

Outstanding principal must not become negative.

```text
Outstanding Principal
        ≥
Repayment Amount
```

The detailed processing and validation implementation is deferred to financial-processing work.

### Downstream Intelligence Significance

Loan Repayment supports analysis of:

* repayment behaviour;
* outstanding exposure;
* repayment performance;
* delinquency;
* default;
* loan performance.

### Observation Boundary

OCB observes the authoritative SikaCredit repayment activity and its financial consequence.

OCB does not reproduce the institution's internal repayment-processing architecture.

---

# 9. Oman Remit — Remittance

## 9.1 Business Meaning

A **Remittance** is an Oman Remit financial event representing the transfer of value from a sender to a beneficiary.

### Institution

**Oman Remit**

### Actor

Sender.

Sender and beneficiary are treated as **roles within the remittance relationship**, not as separate first-class OCB entities.

### Source

Sender-side remittance activity within Oman Remit.

### Destination

Beneficiary.

### Value

The remitted amount.

### Timestamp

The authoritative Oman Remit remittance timestamp.

### Outcome

The remittance may have a successful or unsuccessful outcome according to the approved event/lifecycle semantics.

A non-successful remittance produces no valid financial consequence.

### Financial Consequence

A successful remittance establishes the relevant beneficiary financial position within the approved OCB observation boundary:

```text
OMAN REMIT
Remittance
     ↓
Beneficiary Financial Position
     +
   Amount
```

The v1.0.0 model does not introduce a separate beneficiary account or withdrawal event.

### State Consequence

A successful Remittance increases the conceptual Beneficiary Financial Position.

A failed or rejected remittance produces no increase.

### Cross-Domain Consequence Boundary

A remittance may subsequently be relevant to analysis of customer activity elsewhere.

However, the model does **not** establish:

```text
OMAN REMIT REMITTANCE
          ↓
ANANSE WALLET +
```

as an automatic institutional state transition.

If Ananse subsequently records an actual wallet-affecting event associated with the value, that event/consequence must be represented through Ananse's own authoritative model.

Thus:

```text
Oman Remit Activity
        ↓
Oman Remit Financial Consequence
        ↓
OCB Observation / Resolution
        ↓
Cross-Domain Analysis
```

does not become:

```text
Oman Remit
     ↓
Ananse Wallet
```

as a direct institutional relationship.

### Downstream Intelligence Significance

Remittance activity supports analysis of:

* cross-border financial flows;
* remittance volumes;
* destination patterns;
* customer remittance behaviour;
* concentration;
* potential AML-related indicators.

### Observation Boundary

OCB observes the remittance activity and the financial position established within the approved Oman Remit observation boundary.

OCB does not reproduce:

* internal remittance-processing architecture;
* beneficiary account infrastructure;
* internal settlement arrangements;
* withdrawal mechanisms not explicitly modelled.

---

# 10. Cross-Event Semantic Rules

## 10.1 Event Outcome

An event outcome describes what happened to the event.

```text
FINANCIAL EVENT
      ↓
EVENT OUTCOME
```

The state model recognises that unsuccessful activity does not create a valid financial consequence.

For financial-state purposes:

```text
Successful
    ↓
May produce valid financial consequence

Failed / Rejected
    ↓
No valid financial consequence
    ↓
No financial-state transition
```

The detailed lifecycle semantics of `Rejected`, including how it differs operationally from `Failed`, remain subject to the appropriate transaction-lifecycle work.

The distinction must therefore not be invented in this semantic ticket.

---

## 10.2 Financial Consequence

A financial consequence describes the financial effect produced by an event.

```text
FINANCIAL EVENT
      ↓
EVENT OUTCOME
      ↓
FINANCIAL CONSEQUENCE
      ↓
FINANCIAL STATE
```

A financial consequence is not itself the originating event.

For example:

```text
P2P TRANSFER
      ↓
Successful
      ↓
Sender Debit
Receiver Credit
```

The sender debit and receiver credit are consequences/legs of the P2P Transfer.

---

## 10.3 Financial State

A financial state describes what financial position is true after valid financial consequences have been applied.

Examples:

```text
Wallet
    ↓
Customer Wallet Balance

Loan
    ↓
Outstanding Loan Principal

Remittance
    ↓
Beneficiary Financial Position
```

The state does not replace the institutional activity from which it is derived.

---

# 11. Settlement

Settlement is **not an independent v1.0.0 financial event**.

The OCB model does not assume that every financial event requires a separately observable settlement event.

A successful event may be treated as financially effective within the relevant institutional observation boundary once its defined financial consequence has occurred.

This does not mean that real-world settlement mechanisms do not exist.

It means that OCB does not introduce an additional settlement architecture unless a concrete v1.0.0 intelligence or supervisory requirement justifies it.

Therefore OCB does not model:

* settlement accounts;
* correspondent institutions;
* escrow arrangements;
* inter-institution settlement infrastructure;

unless separately approved.

---

# 12. Correction, Reversal and Adjustment

## 12.1 Correction

Correction is treated as an institutional control mechanism rather than an approved OCB financial-event type.

OCB assumes that authoritative source activity crossing the observation boundary is subject to the originating institution's applicable controls.

A future requirement may justify explicit corrective-event semantics.

---

## 12.2 Reversal

Reversal is not an approved v1.0.0 financial-event type.

A reversal would create a subsequent financial activity linked to an earlier financial consequence and would materially affect:

* event history;
* reconciliation;
* financial-state reconstruction;
* ledger representation.

It therefore requires a concrete business scenario before introduction.

---

## 12.3 Adjustment

Adjustment is not an approved v1.0.0 financial-event type.

The term is too semantically broad to represent a controlled financial meaning without a defined business requirement.

---

# 13. Event-to-State Semantic Matrix

| Authoritative Event | Institution    | Successful Financial Consequence | Primary Financial-State Effect           |
| ------------------- | -------------- | -------------------------------- | ---------------------------------------- |
| Cash-in             | Ananse Telecom | Wallet credit                    | Wallet balance increases                 |
| Cash-out            | Ananse Telecom | Wallet debit                     | Wallet balance decreases                 |
| P2P Transfer        | Ananse Telecom | Sender debit + receiver credit   | Both wallet positions change             |
| Merchant Payment    | Ananse Telecom | Wallet debit                     | Wallet balance decreases                 |
| Loan Disbursement   | SikaCredit     | Loan principal creation          | Outstanding principal increases          |
| Loan Repayment      | SikaCredit     | Principal reduction              | Outstanding principal decreases          |
| Remittance          | Oman Remit     | Beneficiary value established    | Beneficiary financial position increases |

P2P Send and P2P Receive remain consequences/legs of the P2P Transfer rather than independent events.

Cross-domain analytical relationships do not create automatic direct institutional state transitions.

---

# 14. Cross-Domain Financial Consequence Principle

The OCB model must distinguish between:

1. the **source institutional activity**;
2. the **financial consequence produced by that activity**;
3. the **institutional financial state affected by that consequence**;
4. the **OCB analytical relationship created after identity resolution**.

Conceptually:

```text
INSTITUTIONAL ACTIVITY
        ↓
INSTITUTIONAL OWNERSHIP
        ↓
FINANCIAL CONSEQUENCE
        ↓
INSTITUTIONAL / OBSERVABLE STATE
        ↓
OCB OBSERVATION
        ↓
IDENTITY RESOLUTION
        ↓
OCB FINANCIAL / ANALYTICAL MODEL
        ↓
CROSS-DOMAIN ANALYSIS
```

This prevents a financial consequence from being incorrectly interpreted as a transfer of institutional ownership.

It also prevents OCB from creating artificial direct relationships such as:

```text
SIKACREDIT → ANANSE_WALLET
```

or:

```text
OMAN_REMIT → ANANSE_WALLET
```

where no such relational dependency exists in WP-2.2. The logical model explicitly avoids these cross-institutional foreign-key relationships.

---

# 15. Financial-State Integrity Implications

The event semantics established here must satisfy the financial-state rules established in WP-1.4.

Accordingly:

1. Only valid financial consequences may change a financial-position state.
2. Failed or rejected activity produces no valid financial-state transition.
3. P2P sender and receiver consequences remain attributable to one authoritative event.
4. Outstanding principal must not become negative.
5. Wallet debits must respect applicable available-balance constraints.
6. Cross-domain analytical relationships must not be interpreted as shared institutional ownership.
7. Cross-domain activity must not be counted twice.
8. Unmodelled institutional mechanisms must not be invented merely to explain an observed relationship.
9. Financial positions must remain institutionally attributable and reconcilable.

## These principles are consistent with the locked WP-1.4 state-transition and reconstructability model.

# 16. Observation Boundary

The OCB financial-event model deliberately stops short of reproducing complete institutional architectures.

OCB does not model, unless separately justified:

* internal institutional ledgers;
* agent float;
* merchant accounts;
* settlement accounts;
* correspondent institutions;
* escrow accounts;
* beneficiary withdrawal infrastructure;
* internal processing engines;
* unobserved institutional accounting mechanisms.

The objective is not to recreate each institution.

The objective is to observe institution-owned financial activity, resolve relevant identities, represent valid financial consequences, reconstruct approved financial positions, and support cross-domain intelligence.

---

# 17. Relationship to WP-2.2 Logical Model

The event semantics align with the current logical entities:

```text
ANANSE
    ├── ANANSE_CUSTOMER
    ├── ANANSE_WALLET
    └── ANANSE_TRANSACTION

SIKACREDIT
    ├── SIKACREDIT_CUSTOMER
    ├── SIKACREDIT_LOAN
    └── SIKACREDIT_REPAYMENT

OMAN REMIT
    ├── OMAN_REMIT_CUSTOMER
    └── OMAN_REMIT_REMITTANCE

OCB
    ├── OCB_CUSTOMER
    └── OCB_CUSTOMER_IDENTITY
```

The logical model preserves institutional ownership and source identity while OCB provides cross-institutional identity resolution.

The event semantics therefore do not introduce new relational entities merely to represent:

* wallet balance;
* outstanding principal;
* beneficiary financial position;
* P2P legs;
* analytical classifications.

These remain conceptual financial consequences, states, roles, or classifications as appropriate.

---

# 18. Status

**Status: REVISED / LOCKED**

This ticket establishes the business semantics of the authoritative financial events recognised by OCB Platform v1.0.0.

The semantic model is aligned with:

* **WP-1.3-T01** — Financial Event Catalogue;
* **WP-1.4** — State Model;
* **WP-2.1** — Conceptual Data Model;
* **WP-2.2** — Logical Data Model.

Any material change to an event's business meaning, institutional ownership, financial consequence, or state implication must be reflected in the relevant upstream catalogue and reviewed through the applicable governance process.

---

# Core Principle

> **An authoritative financial event records institutional activity; its outcome determines whether a valid financial consequence exists; the consequence affects an attributable financial position; and OCB may then observe, resolve, represent, and analyse that information without transferring ownership of the underlying institutional financial object.**

> **P2P Send and P2P Receive are consequences of one P2P Transfer, cross-domain analytical relationships do not create automatic cross-domain source-state mutations, and unmodelled institutional mechanisms must not be invented merely to complete the picture.**
