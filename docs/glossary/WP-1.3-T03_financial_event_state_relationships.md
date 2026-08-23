# OCB Financial Event / State Relationships

**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.3 — Financial Event Catalogue

**Ticket:** WP-1.3-T03

**Status:** **REVISED / LOCKED**

**Decision Type:** Financial event-to-state relationship definition

---

## Purpose

This document defines how the authoritative financial events identified in the **OCB Financial Event Catalogue** relate to authoritative financial positions and their resulting state.

It establishes the relationship between:

```text
FINANCIAL EVENT
        ↓
EVENT / LIFECYCLE OUTCOME
        ↓
FINANCIAL CONSEQUENCE
        ↓
AUTHORITATIVE FINANCIAL POSITION
        ↓
DERIVED / ANALYTICAL INTERPRETATION
```

The model distinguishes:

* the event itself;
* its lifecycle or outcome;
* the financial consequence produced by the event;
* the resulting institutional financial position;
* derived lifecycle and credit states;
* analytical and intelligence classifications;
* ledger representations of financial consequences.

These concepts must not be treated as interchangeable.

This document does not define physical database structures, transaction lifecycle implementation, ledger posting mechanics, or analytical calculation algorithms.

---

# 1. Governing Principle

A financial event affects an authoritative financial position only where the event produces a valid financial consequence attributable to that position.

```text
AUTHORITATIVE FINANCIAL EVENT
            ↓
      EVENT OUTCOME
            ↓
 VALID FINANCIAL CONSEQUENCE
            ↓
AUTHORITATIVE FINANCIAL POSITION
```

Where an event fails before producing its intended financial consequence:

```text
FINANCIAL EVENT
      ↓
FAILED / INVALID OUTCOME
      ↓
NO VALID FINANCIAL CONSEQUENCE
      ↓
NO FINANCIAL POSITION CHANGE
```

The event may nevertheless remain recorded and analytically relevant.

The existence of an event therefore does not, by itself, establish a financial state change.

---

# 2. Institutional Ownership and State Authority

The authoritative financial positions remain institutionally attributable.

The v1.0.0 model recognises:

| Financial Position             | Institutional Domain |
| ------------------------------ | -------------------- |
| Customer Wallet Balance        | Ananse Telecom       |
| Outstanding Loan Principal     | SikaCredit           |
| Beneficiary Financial Position | Oman Remit           |

OCB observes and resolves institutional information but does not assume ownership of the underlying institutional financial object.

The governing architectural relationship is:

```text
INSTITUTIONAL FINANCIAL OBJECT
              ↓
     INSTITUTIONAL OWNERSHIP
              ↓
       OCB OBSERVATION
              ↓
      IDENTITY RESOLUTION
              ↓
 OBSERVABLE FINANCIAL CONSEQUENCE
              ↓
 OCB FINANCIAL / ANALYTICAL MODEL
```

This does not create a shared institutional financial state.

The institutional financial object remains owned by its originating domain.

---

# 3. Ananse Telecom

## 3.1 Cash-in

### State Affected

**Customer Wallet Balance — Ananse Telecom.**

### Successful Relationship

```text
Cash-in
   ↓
Successful
   ↓
Wallet Credit
   ↓
Customer Wallet Balance Increases
```

```text
Customer Wallet
      +
    Amount
```

### Failed Relationship

```text
Cash-in
   ↓
Failed
   ↓
No Financial Consequence
   ↓
Wallet Unchanged
```

### State Rule

A successful Cash-in increases the relevant Ananse wallet position by the valid credited amount.

A failed Cash-in does not change the wallet position.

### Ownership

The wallet and resulting wallet position remain Ananse Telecom financial objects.

---

## 3.2 Cash-out

### State Affected

**Customer Wallet Balance — Ananse Telecom.**

### Successful Relationship

```text
Cash-out
   ↓
Successful
   ↓
Wallet Debit
   ↓
Customer Wallet Balance Decreases
```

```text
Customer Wallet
      -
    Amount
```

### Failed Relationship

```text
Cash-out
   ↓
Failed
   ↓
No Financial Consequence
   ↓
Wallet Unchanged
```

### State Rule

A successful Cash-out decreases the relevant Ananse wallet position by the valid debit amount.

A successful debit must satisfy the applicable balance-validity rules.

A failed Cash-out does not produce a wallet debit.

Agent cash, agent float, and internal settlement mechanisms are outside this state relationship.

---

## 3.3 P2P Transfer

### State Affected

**Sender and receiver Ananse wallet balances.**

P2P Transfer remains one authoritative financial event.

A successful P2P Transfer produces two financial consequences:

```text
                 P2P TRANSFER
                       │
              ┌────────┴────────┐
              ↓                 ↓
        SENDER LEG         RECEIVER LEG
              ↓                 ↓
            DEBIT             CREDIT
              ↓                 ↓
          - Amount           + Amount
```

### Successful Relationship

```text
Sender Wallet
      -
    Amount

Receiver Wallet
      +
    Amount
```

The sender and receiver consequences remain attributable to the same P2P Transfer event.

### Failed Relationship

```text
P2P Transfer
      ↓
Failed
      ↓
No Sender Debit
No Receiver Credit
      ↓
Both Wallets Unchanged
```

A failed P2P Transfer must not partially alter either wallet.

### State Rule

For a successful transfer:

```text
Sender State Change   = -Amount
Receiver State Change = +Amount
Net Transfer Effect   = 0
```

This relationship provides the basis for later ledger reconciliation and atomic financial processing.

P2P Send and P2P Receive are financial legs, not independent financial events.

---

## 3.4 Merchant Payment

### State Affected

**Customer Wallet Balance — Ananse Telecom.**

### Successful Relationship

```text
Merchant Payment
       ↓
Successful
       ↓
Customer Wallet Debit
       ↓
Wallet Balance Decreases
```

```text
Customer Wallet
      -
    Amount
```

### Failed Relationship

```text
Merchant Payment
       ↓
Failed
       ↓
No Financial Consequence
       ↓
Wallet Unchanged
```

The merchant is an observable reference in the v1.0.0 model.

The model does not establish a corresponding OCB merchant financial-account state merely because a merchant payment occurred.

### State Rule

Only the customer-side Ananse wallet consequence is included in the authoritative wallet-state model.

Merchant settlement and merchant-side accounting mechanisms remain outside the OCB observation boundary.

---

# 4. SikaCredit

## 4.1 Loan Disbursement

### State Affected

**Outstanding Loan Principal — SikaCredit.**

### Successful Relationship

```text
Loan Disbursement
       ↓
Successful
       ↓
Loan Financial Obligation Established
       ↓
Outstanding Principal Increases
```

```text
Outstanding Principal
          +
   Disbursed Amount
```

The successful disbursement establishes the corresponding outstanding loan obligation.

### Failed Relationship

```text
Loan Disbursement
       ↓
Failed
       ↓
No Financial Consequence
       ↓
Outstanding Principal Unchanged
```

### State Rule

A successful Loan Disbursement increases SikaCredit's outstanding principal by the valid disbursed amount.

Loan approval does not itself create the outstanding financial position.

### Cross-Domain Boundary

A loan disbursement may be associated, after OCB identity resolution, with subsequent customer activity in another institutional domain.

However:

```text
SikaCredit Loan Disbursement
          ≠
Automatic Ananse Wallet Credit
```

A cross-domain relationship does not automatically mutate the Ananse wallet state.

Any Ananse wallet-state change must arise from an authoritative Ananse wallet-affecting financial event or consequence.

---

## 4.2 Loan Repayment

### State Affected

**Outstanding Loan Principal — SikaCredit.**

### Successful Relationship

```text
Loan Repayment
       ↓
Successful
       ↓
Principal Reduction
       ↓
Outstanding Principal Decreases
```

```text
Outstanding Principal
          -
    Repayment Amount
```

For v1.0.0, the full amount of a successful Loan Repayment is treated as principal repayment.

No separate interest or fee allocation is required for this state model.

### Failed Relationship

```text
Loan Repayment
       ↓
Failed
       ↓
No Financial Consequence
       ↓
Outstanding Principal Unchanged
```

### State Rule

A successful repayment reduces the outstanding principal.

Outstanding principal must not become negative.

Repayment history may subsequently contribute to derived delinquency, default, performance, and closure classifications.

---

## 4.3 Loan Default

Loan Default is **not an independent financial event**.

It is a derived credit state.

```text
Loan
 ↓
Outstanding Obligation
 ↓
Repayment Obligations
 ↓
Repayment History
 ↓
Applicable Rules
 ↓
Defaulted
```

The derived `Defaulted` classification does not replace:

* the loan;
* outstanding principal;
* repayment activity;
* repayment obligations;
* authoritative event history.

The same principle applies to other derived states such as `Delinquent`, `Active`, and `Closed`.

---

# 5. Oman Remit

## 5.1 Remittance

### State Affected

**Beneficiary Financial Position — Oman Remit.**

### Successful Relationship

```text
Remittance
     ↓
Successful
     ↓
Financial Consequence Established
     ↓
Beneficiary Financial Position Increases
```

```text
Beneficiary Financial Position
            +
      Remitted Amount
```

Within the v1.0.0 observation boundary, successful remittance value establishes the corresponding beneficiary financial position.

### Failed / Unsuccessful Relationship

Where a remittance does not successfully produce the defined financial consequence:

```text
No Successful Financial Consequence
             ↓
No Beneficiary Financial Position Increase
```

The detailed transaction/lifecycle semantics for failed, rejected, processing, or other remittance states belong to the later transaction lifecycle model.

### Cross-Domain Boundary

A successful Oman Remit remittance may be associated, after identity resolution, with subsequent Ananse customer activity.

However:

```text
Oman Remit Remittance
          ≠
Automatic Ananse Wallet Credit
```

The remittance's originating financial object remains Oman Remit's.

OCB may observe and resolve the relationship and represent the resulting financial consequence in its financial/analytical model without transferring institutional ownership.

No separate remittance withdrawal event is introduced in v1.0.0.

---

# 6. Cross-Domain State Relationships

Cross-domain relationships are permitted for **analysis and observation** but do not automatically create cross-domain institutional state mutations.

The correct conceptual model is:

```text
INSTITUTION A
Authoritative Event
        ↓
Institution A Consequence
        ↓
Institution A Financial State

              +

OCB Identity Resolution
              ↓
Cross-Institutional Relationship
              ↓
OCB Financial / Analytical Model
```

Not:

```text
Institution A Event
        ↓
Automatically mutate
Institution B State
```

For example:

```text
SIKACREDIT
Loan Disbursement
      ↓
SikaCredit Loan Position
      ↓
OCB Identity Resolution
      ↓
Relationship to Ananse Customer
      ↓
Cross-Domain Analysis
```

The same principle applies to Oman Remit.

```text
OMAN REMIT
Remittance
      ↓
Beneficiary Financial Position
      ↓
OCB Identity Resolution
      ↓
Relationship to Ananse Customer
      ↓
Cross-Domain Analysis
```

This preserves the institutional boundaries established by WP-2.1 and WP-2.2.

---

# 7. Event Outcomes and Lifecycle States

Event outcomes and transaction lifecycle states must not be confused with financial positions.

The v1.0.0 model distinguishes:

```text
FINANCIAL POSITION
        ≠
EVENT / TRANSACTION LIFECYCLE STATE
        ≠
DERIVED STATE
        ≠
ANALYTICAL STATE
```

Examples include:

| Concept                        | Classification                                         |
| ------------------------------ | ------------------------------------------------------ |
| Customer Wallet Balance        | Authoritative financial position                       |
| Outstanding Loan Principal     | Authoritative financial position                       |
| Beneficiary Financial Position | Authoritative financial position                       |
| Successful                     | Event outcome / lifecycle state                        |
| Failed                         | Event outcome / lifecycle state                        |
| Rejected                       | Lifecycle state; detailed semantics deferred to WP-2.5 |
| Reversed                       | Lifecycle / corrective processing state                |
| Corrected                      | Lifecycle / corrective processing state                |
| Active                         | Derived lifecycle state                                |
| Delinquent                     | Derived credit state                                   |
| Defaulted                      | Derived credit state                                   |
| Closed                         | Derived lifecycle state                                |
| Analytical risk score          | Analytical output                                      |
| Anomaly classification         | Analytical output                                      |

A lifecycle state therefore does not itself constitute a financial-position change.

The financial consequence associated with a valid successful event is what changes the relevant financial position.

---

# 8. Settlement

Settlement is not an independent state-changing financial event in the v1.0.0 model.

Where a successful financial event's defined financial consequence has been completed within the relevant institutional abstraction, the event may be considered settled for the purposes of the model.

```text
Successful Event
       ↓
Defined Financial Consequence Completed
       ↓
Settled
```

`Settled` does not create an additional financial-position change merely because settlement has been identified.

The model therefore does not introduce:

* a generic settlement account;
* a shared settlement ledger;
* an institutional settlement state;
* an additional settlement event.

This is consistent with the decision to avoid reproducing unobserved institutional settlement architecture.

---

# 9. Ledger Relationship

A ledger entry represents the accounting consequence of a financial event.

It does not become the originating financial event.

The relationship is:

```text
FINANCIAL EVENT
       ↓
FINANCIAL CONSEQUENCE
       ↓
LEDGER REPRESENTATION
       ↓
FINANCIAL POSITION / RECONCILIATION
```

Therefore:

```text
Ledger Entry
     ≠
Financial Event
```

The ledger may represent the debit and credit consequences of the event, but the originating event remains the authoritative record of what occurred.

For P2P Transfer:

```text
P2P Transfer
      ↓
Sender Debit
      +
Receiver Credit
      ↓
Ledger Consequences
      ↓
Wallet Position Changes
```

This preserves the WP-2.1 distinction between financial activity and its accounting consequences.

---

# 10. Failed and Rejected Activity

Failed or rejected activity must not create a financial-position change unless a separately defined valid financial consequence exists.

The general rule is:

```text
Event
 ↓
Failed / Rejected
 ↓
No Valid Financial Consequence
 ↓
No Financial Position Change
```

Such activity may nevertheless remain important for:

* behavioural analysis;
* failed-attempt analysis;
* transaction monitoring;
* anomaly detection;
* operational intelligence.

The lifecycle semantics of `Rejected`, `Reversed`, `Corrected`, and other transaction states are deliberately deferred to **WP-2.5 — Transaction Lifecycle Model**.

---

# 11. Correction, Reversal and Adjustment

## 11.1 Correction

Correction is not currently an independent financial-state transition in the v1.0.0 model.

The OCB sandbox assumes that source institutions apply their applicable internal controls before authoritative information crosses the observation boundary.

Future correction mechanisms must preserve historical truth rather than silently rewriting the original event.

---

## 11.2 Reversal

Reversal is not included as an independent v1.0.0 financial event or financial-position transition.

A future reversal model would require explicit linkage between:

```text
Original Event
      ↓
Original Consequence
      ↓
Reversal Event
      ↓
Reversal Consequence
```

Such a mechanism would affect:

* historical event interpretation;
* ledger representation;
* reconciliation;
* state reconstruction.

It therefore requires a separate architectural decision if introduced.

---

## 11.3 Adjustment

Adjustment has no defined v1.0.0 financial-state relationship.

A future adjustment mechanism would require a concrete business definition establishing:

* what is being adjusted;
* why it is adjusted;
* which original event or state is affected;
* what financial consequence results;
* how historical truth is preserved.

---

# 12. State Relationship Summary

| Financial Event   | Institutional State Affected              | Successful Financial Consequence | Failed / Unsuccessful Consequence   |
| ----------------- | ----------------------------------------- | -------------------------------- | ----------------------------------- |
| Cash-in           | Ananse Customer Wallet Balance            | Wallet credit                    | No wallet change                    |
| Cash-out          | Ananse Customer Wallet Balance            | Wallet debit                     | No wallet change                    |
| P2P Transfer      | Ananse sender and receiver wallets        | Sender debit + receiver credit   | No wallet changes                   |
| Merchant Payment  | Ananse Customer Wallet Balance            | Wallet debit                     | No wallet change                    |
| Loan Disbursement | SikaCredit Outstanding Loan Principal     | Principal increases              | No principal increase               |
| Loan Repayment    | SikaCredit Outstanding Loan Principal     | Principal decreases              | No principal change                 |
| Remittance        | Oman Remit Beneficiary Financial Position | Beneficiary position increases   | No recognised financial consequence |

**Important:** cross-domain identity relationships do not automatically add or subtract from another institution's authoritative financial position.

---

# 13. Relationship to Financial-State Reconstruction

The event/state relationships established here provide the conceptual basis for WP-1.4-T04 reconstructability.

The reconstruction model is:

```text
AUTHORITATIVE EVENTS
        ↓
VALID FINANCIAL CONSEQUENCES
        ↓
INSTITUTIONAL FINANCIAL POSITIONS
        ↓
CHRONOLOGICAL RECONSTRUCTION
        ↓
RECONCILIATION
```

For the three principal financial positions:

```text
Wallet Balance
=
Opening / Prior Position
+
Valid Credits
-
Valid Debits
```

```text
Outstanding Principal
=
Successful Disbursements
-
Successful Repayments
```

```text
Beneficiary Financial Position
=
Successful Remittance Value
```

Reconstruction must preserve institutional ownership and must not infer unmodelled internal institutional mechanisms. This is consistent with the consolidated WP-1.4 reconstructability model.

---

# 14. Core State-Relationship Rules

The following rules are established:

1. **A financial event is not itself a financial position.**

2. **An event outcome or lifecycle state is not itself a financial position.**

3. **Only a valid financial consequence may change an authoritative financial position.**

4. **Failed activity produces no financial-position change where no valid financial consequence exists.**

5. **P2P Send and P2P Receive remain financial legs of one P2P Transfer event.**

6. **P2P sender and receiver consequences must remain attributable to the same originating event.**

7. **Cross-domain relationships do not automatically mutate another institution's authoritative financial state.**

8. **Institutional financial objects remain institution-owned.**

9. **OCB may observe, resolve, represent, reconcile, and analyse financial consequences without assuming institutional ownership.**

10. **A ledger entry represents a financial consequence; it does not become the originating financial event.**

11. **Derived lifecycle and credit states must remain traceable to authoritative financial information.**

12. **Analytical classifications must not replace authoritative financial information.**

13. **Financial positions must remain reconstructable from valid financial consequences while preserving chronology.**

---

# 15. Scope Boundary

This ticket establishes conceptual event-to-state relationships.

It does not define:

* physical database tables;
* transaction lifecycle state-machine implementation;
* SQL constraints;
* ledger posting mechanics;
* atomic transaction processing;
* detailed balance-validation algorithms;
* delinquency calculation;
* default calculation;
* analytical risk algorithms.

Those concerns belong to the subsequent architectural and engineering work.

In particular:

* transaction lifecycle implementation belongs to **WP-2.5**;
* ledger architecture belongs to **WP-2.6**;
* financial processing belongs to **WP-3**;
* analytical architecture belongs to the later intelligence work.

---

# 16. Status

**Status: REVISED / LOCKED**

The v1.0.0 event/state model establishes:

1. Ananse wallet-affecting events change the Ananse customer wallet position through valid financial consequences;
2. P2P Transfer remains one authoritative event with sender and receiver financial legs;
3. SikaCredit Loan Disbursement and Loan Repayment affect Outstanding Loan Principal;
4. Oman Remit Remittance affects the Beneficiary Financial Position within the defined observation boundary;
5. Failed activity does not change authoritative financial position where no valid financial consequence exists;
6. lifecycle states and derived states remain distinct from financial positions;
7. ledger entries represent financial consequences rather than originating events;
8. cross-domain identity resolution enables analysis without automatically mutating another institution's authoritative financial state;
9. institutional financial objects remain institution-owned;
10. authoritative financial positions remain reconstructable from their valid financial consequences.

This ticket is therefore aligned with the revised **WP-1.4 State Model**, **WP-2.1 Conceptual Data Model**, and **WP-2.2 Logical Data Model**.

---

# Core Principle

> **A financial event records what occurred; its valid financial consequence determines what changes; the resulting financial position records what is subsequently true. OCB may observe and resolve relationships across institutions without transferring ownership or automatically mutating another institution's financial state.**

**WP-1.3-T03 — REVISED AND LOCKED.**
