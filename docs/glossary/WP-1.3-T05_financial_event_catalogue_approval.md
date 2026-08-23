**Programme:** OCB Platform v1.0.0

**Work Package:** WP-1.3 — Financial Event Catalogue

**Ticket:** WP-1.3-T05

**Status:** **REVISED / LOCKED**

**Decision Type:** Final financial-event catalogue approval and WP-1.3 completion

---

# OCB Financial Event Catalogue Approval

## Purpose

This document records the final review and approval of the OCB Platform v1.0.0 financial-event catalogue.

The review confirms that the approved financial events:

* represent the authoritative financial activities required within the OCB observation boundary;
* remain consistent with the financial-state model established in WP-1.4;
* remain consistent with the institutional relationship model established in WP-2.1;
* remain consistent with the attribute and ownership model established in WP-2.2;
* preserve the distinction between institutional financial objects, financial events, financial consequences, financial states, and analytical interpretations;
* provide sufficient coverage for the defined v1.0.0 financial-intelligence requirements.

This document does not introduce new financial events or define physical implementation structures.

---

# 1. Approved Financial Event Catalogue

The following events are approved for the v1.0.0 financial-event model.

| Institution    | Financial Event   | Status   |
| -------------- | ----------------- | -------- |
| Ananse Telecom | Cash-in           | Approved |
| Ananse Telecom | Cash-out          | Approved |
| Ananse Telecom | P2P Transfer      | Approved |
| Ananse Telecom | Merchant Payment  | Approved |
| SikaCredit     | Loan Disbursement | Approved |
| SikaCredit     | Loan Repayment    | Approved |
| Oman Remit     | Remittance        | Approved |

These seven events constitute the authoritative financial-event inventory for v1.0.0.

They are events occurring within the respective institutional domains.

OCB does not assume ownership of the underlying institutional financial objects merely because their events are observed, resolved, or represented within the OCB analytical model.

---

# 2. Ananse Telecom Event Coverage

## 2.1 Cash-in

Supports:

* wallet inflows;
* customer liquidity analysis;
* transaction velocity;
* cash-in concentration;
* behavioural analysis.

A successful Cash-in produces a wallet-credit financial consequence.

---

## 2.2 Cash-out

Supports:

* wallet outflows;
* withdrawal behaviour;
* transaction velocity;
* cash-out concentration;
* wallet-balance validation.

A successful Cash-out produces a wallet-debit financial consequence.

---

## 2.3 P2P Transfer

Supports:

* customer-to-customer value movement;
* wallet inflows and outflows;
* transaction velocity;
* transaction concentration;
* behavioural analysis;
* reconciliation.

P2P Transfer remains one authoritative financial event.

A successful event produces two financial legs:

```text
P2P Transfer
      │
      ├── Sender Leg → Outflow
      │
      └── Receiver Leg → Inflow
```

The sender and receiver legs are financial consequences of the same event.

They are not independent financial events.

---

## 2.4 Merchant Payment

Supports:

* customer spending behaviour;
* merchant activity analysis;
* transaction concentration;
* payment velocity;
* merchant-related intelligence.

A successful Merchant Payment produces a debit to the customer's Ananse wallet.

The merchant remains an observable reference rather than an OCB financial-account object.

---

# 3. SikaCredit Event Coverage

## 3.1 Loan Disbursement

Supports:

* loan exposure;
* credit origination;
* disbursement concentration;
* outstanding principal reconstruction;
* downstream credit analysis.

A successful Loan Disbursement establishes or increases the authoritative SikaCredit loan obligation.

The resulting loan obligation remains institution-owned by SikaCredit.

---

## 3.2 Loan Repayment

Supports:

* repayment behaviour;
* outstanding exposure;
* repayment performance;
* delinquency analysis;
* default analysis;
* credit-performance intelligence.

A successful Loan Repayment reduces the authoritative outstanding loan obligation.

For v1.0.0, the approved financial-state model treats the successful repayment amount as principal reduction.

---

# 4. Oman Remit Event Coverage

## 4.1 Remittance

Supports:

* remittance activity;
* remittance value;
* customer remittance behaviour;
* cross-border flow analysis;
* destination analysis;
* beneficiary-related intelligence.

A successful Remittance establishes the corresponding beneficiary financial consequence within the Oman Remit observation boundary.

The beneficiary financial position remains an Oman Remit-domain financial position.

OCB does not introduce a separate remittance-withdrawal event or reproduce Oman Remit's internal settlement or delivery architecture.

---

# 5. Business-Question Coverage

## 5.1 Transaction Activity

| Requirement                   | Supporting Events                        |
| ----------------------------- | ---------------------------------------- |
| Wallet inflows                | Cash-in, P2P Transfer                    |
| Wallet outflows               | Cash-out, P2P Transfer, Merchant Payment |
| Customer-to-customer movement | P2P Transfer                             |
| Merchant activity             | Merchant Payment                         |
| Transaction sequencing        | All applicable events                    |

**Coverage: Sufficient.**

---

## 5.2 Behavioural Intelligence

| Requirement                            | Supporting Events                    |
| -------------------------------------- | ------------------------------------ |
| Transaction velocity                   | All applicable events                |
| Inflow/outflow behaviour               | Wallet-affecting events              |
| Repeated failed activity               | Failed outcomes of applicable events |
| Customer behavioural patterns          | Customer-associated financial events |
| Transaction concentration              | Applicable financial events          |
| Cross-domain behavioural relationships | Resolved institutional activity      |

**Coverage: Sufficient.**

Failed events remain observable where captured by the relevant source and within the observation boundary.

They do not require separate financial-event types.

---

## 5.3 Liquidity Intelligence

| Requirement                   | Supporting Events                        |
| ----------------------------- | ---------------------------------------- |
| Wallet inflows                | Cash-in, P2P Transfer                    |
| Wallet outflows               | Cash-out, P2P Transfer, Merchant Payment |
| Wallet balance reconstruction | Wallet-affecting financial consequences  |
| Customer liquidity behaviour  | Wallet-affecting financial activity      |

**Coverage: Sufficient.**

---

## 5.4 Credit Intelligence

| Requirement            | Supporting Events / Information                             |
| ---------------------- | ----------------------------------------------------------- |
| Loan exposure          | Loan Disbursement                                           |
| Repayment behaviour    | Loan Repayment                                              |
| Outstanding obligation | Loan Disbursement + Loan Repayment                          |
| Delinquency            | Loan information + repayment information + applicable rules |
| Default                | Derived from authoritative loan and repayment information   |
| Loan-rate analysis     | Loan attributes + applicable loan events                    |

**Coverage: Sufficient.**

Loan application and approval are not required as independent financial events because they do not themselves establish the financial obligation.

---

## 5.5 Remittance Intelligence

| Requirement                      | Supporting Events / Information                |
| -------------------------------- | ---------------------------------------------- |
| Remittance activity              | Remittance                                     |
| Remittance value                 | Remittance                                     |
| Customer remittance behaviour    | Remittance                                     |
| Cross-border flow analysis       | Remittance                                     |
| Beneficiary/destination analysis | Remittance + participant/reference information |

**Coverage: Sufficient.**

The model does not require separate initiation, processing, receipt, or withdrawal events merely to reproduce Oman Remit's internal operational architecture.

---

## 5.6 Reconciliation and Financial Integrity

| Requirement                                 | Supporting Events / Information           |
| ------------------------------------------- | ----------------------------------------- |
| Wallet reconstruction                       | Successful wallet-affecting consequences  |
| P2P balancing                               | P2P Transfer + sender/receiver legs       |
| Loan obligation reconstruction              | Loan Disbursement + Loan Repayment        |
| Beneficiary-position reconstruction         | Successful Remittance                     |
| Historical event reconstruction             | Authoritative events + provenance         |
| Failed-event exclusion from financial state | Event outcomes                            |
| Chronological state reconstruction          | Event timestamps + financial consequences |

**Coverage: Sufficient.**

The approved model preserves the relationship:

```text
Financial Event
      ↓
Event Outcome
      ↓
Financial Consequence
      ↓
Financial State
      ↓
Intelligence
```

---

# 6. Candidates Reviewed and Excluded

The following concepts were reviewed during WP-1.3 and WP-1.4.

| Candidate                         | Decision                        | Treatment                                     |
| --------------------------------- | ------------------------------- | --------------------------------------------- |
| P2P Send                          | Excluded as independent event   | Financial leg of P2P Transfer                 |
| P2P Receive                       | Excluded as independent event   | Financial leg of P2P Transfer                 |
| Loan Application                  | Excluded                        | Process/lifecycle concept                     |
| Loan Approval                     | Excluded                        | Credit decision concept                       |
| Loan Closure                      | Excluded                        | Derived lifecycle state                       |
| Loan Default                      | Excluded                        | Derived credit state                          |
| Loan Delinquency                  | Excluded                        | Derived credit state                          |
| Remittance Initiation             | Excluded                        | Process/lifecycle concept                     |
| Remittance Receipt                | Excluded as separate event      | Consequence of successful Remittance          |
| Remittance Withdrawal             | Excluded                        | Outside v1.0.0 observation model              |
| Settlement                        | Excluded as independent event   | Completed consequence/status where applicable |
| Correction                        | Excluded as OCB financial event | Originating-institution control               |
| Reversal                          | Excluded                        | No sufficiently strong v1.0.0 requirement     |
| Adjustment                        | Excluded                        | Insufficiently defined financial meaning      |
| Rollback                          | Not an event                    | Processing-control mechanism                  |
| Merchant Account                  | Excluded                        | Merchant remains an observable reference      |
| Agent Account / Float             | Excluded                        | Outside OCB financial-state boundary          |
| Internal institutional settlement | Excluded                        | Outside OCB observation boundary              |

These are deliberate scope decisions rather than omissions.

---

# 7. Institutional Ownership and OCB Observation

The approved catalogue must be interpreted together with the institutional relationship model.

The governing principle is:

> **Institutional financial objects remain institution-owned → OCB observes/resolves them → their financial consequences can be represented in OCB's financial / analytical model.**

Accordingly:

```text
ANANSE TELECOM
Institution-owned financial activity
          ↓
        OCB
Observation + Identity Resolution
          ↓
Financial / Analytical Representation
```

and similarly:

```text
SIKACREDIT
Institution-owned financial activity
          ↓
        OCB
Observation + Identity Resolution
          ↓
Financial / Analytical Representation
```

```text
OMAN REMIT
Institution-owned financial activity
          ↓
        OCB
Observation + Identity Resolution
          ↓
Financial / Analytical Representation
```

OCB therefore does not become the owner of the underlying institutional wallet, loan, remittance, or other source financial object.

This distinction is essential to the cross-institutional architecture.

---

# 8. Cross-Institutional Financial Consequences

Cross-institutional relationships are permitted for analytical and financial-intelligence purposes without collapsing institutional ownership.

For example:

```text
SikaCredit
Loan Disbursement
        ↓
SikaCredit Loan Obligation
        ↓
OCB Identity Resolution
        ↓
Customer
        ↓
Ananse Activity
```

Likewise:

```text
Oman Remit
Remittance
        ↓
Oman Remit Beneficiary Position
        ↓
OCB Identity Resolution
        ↓
Customer
        ↓
Ananse Activity
```

These relationships do not establish direct ownership or direct source-to-wallet mutation.

The conceptual model therefore remains consistent with the institutional boundaries established in WP-2.1 and the logical model established in WP-2.2.

---

# 9. Financial Event / Consequence / State Boundary

The final event catalogue preserves the following distinctions:

```text
FINANCIAL EVENT
What occurred?
        ↓
EVENT OUTCOME
What happened to the event?
        ↓
FINANCIAL CONSEQUENCE
What financial effect resulted?
        ↓
FINANCIAL STATE
What is subsequently true?
        ↓
INTELLIGENCE
What can OCB infer?
```

For example:

```text
P2P Transfer
      ↓
Successful
      ↓
Sender: -Amount
Receiver: +Amount
      ↓
Updated wallet positions
      ↓
Velocity / concentration / anomaly analysis
```

A failed event follows:

```text
P2P Transfer
      ↓
Failed
      ↓
No financial consequence
      ↓
Wallet state unchanged
      ↓
Failure-pattern analysis may still be possible
```

This separation is a locked semantic boundary for v1.0.0.

---

# 10. Financial-State Alignment

The approved event catalogue is aligned with the three authoritative financial-position states established in WP-1.4:

| Financial State                | Supporting Events                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- |
| Customer Wallet Balance        | Cash-in, Cash-out, P2P Transfer, Merchant Payment, applicable approved cross-domain financial consequence |
| Outstanding Loan Principal     | Loan Disbursement, Loan Repayment                                                                         |
| Beneficiary Financial Position | Successful Remittance                                                                                     |

The corresponding state model remains institutionally bounded.

Cross-domain analytical relationships do not create new institutional financial states.

---

# 11. Reconstructability Alignment

The approved events provide the financial consequences required to reconstruct the authoritative financial positions.

```text
Customer Wallet
=
Successful Credits
-
Successful Debits
```

```text
Outstanding Loan Principal
=
Successful Disbursements
-
Successful Principal Repayments
```

```text
Beneficiary Financial Position
=
Successful Remittance Value
```

Failed events do not contribute to these financial-state calculations.

Chronology must be preserved when reconstructing state.

---

# 12. Observation Boundary

The approved catalogue reflects OCB's role as an analytical and supervisory sandbox.

OCB does not reproduce the complete internal architecture of:

* Ananse Telecom;
* SikaCredit;
* Oman Remit.

Accordingly, the catalogue does not introduce events solely because equivalent mechanisms exist in real-world financial infrastructure.

OCB models the financial activity required to answer its defined intelligence questions while preserving the institutional ownership and observation boundaries of the source domains.

---

# 13. Completeness Assessment

The approved financial-event inventory is:

```text
ANANSE TELECOM

    ├── Cash-in
    ├── Cash-out
    ├── P2P Transfer
    └── Merchant Payment


SIKACREDIT

    ├── Loan Disbursement
    └── Loan Repayment


OMAN REMIT

    └── Remittance
```

These seven events provide sufficient coverage for the v1.0.0 financial-intelligence requirements established by the programme.

No additional authoritative financial event is required at this stage.

Completeness does not mean that every possible institutional process has been modelled.

It means that the approved event inventory is sufficient for the defined OCB observation and intelligence scope.

---

# 14. Approval Decision

**Decision: APPROVED**

The v1.0.0 financial-event catalogue is approved for progression into subsequent financial-state, ledger, business-rule, data-model, and implementation work.

The approved authoritative financial events are:

1. Cash-in;
2. Cash-out;
3. P2P Transfer;
4. Merchant Payment;
5. Loan Disbursement;
6. Loan Repayment;
7. Remittance.

The catalogue must not be expanded merely to reproduce institutional mechanisms outside the OCB observation boundary.

Any future addition, removal, or material reclassification of an authoritative financial event requires review and, where architecturally significant, an ADR.

---

# 15. Programme 1.3 Completion

| Ticket     | Deliverable                                 | Status   |
| ---------- | ------------------------------------------- | -------- |
| WP-1.3-T01 | Financial Event Inventory                   | Complete |
| WP-1.3-T02 | Financial Event Semantics                   | Complete |
| WP-1.3-T03 | Financial Event / State Relationships       | Complete |
| WP-1.3-T04 | Financial Correction and Reversal Semantics | Complete |
| WP-1.3-T05 | Financial Event Catalogue Approval          | Complete |

**WP-1.3 — Financial Event Catalogue: COMPLETE**

The approved event catalogue is now the controlled semantic baseline for subsequent OCB modelling and implementation.

---

# 16. Governance

The event catalogue is not permanently immutable.

A future change may be introduced where a concrete business requirement demonstrates that an additional event, removal, or reclassification is necessary.

Such a change must:

1. establish the business meaning of the proposed change;
2. evaluate its effect on financial consequences and state;
3. evaluate its effect on institutional ownership and observation boundaries;
4. evaluate its effect on reconciliation and historical reconstruction;
5. update the affected semantic and architectural artefacts;
6. follow the applicable ADR and governance process where materially architectural.

No event should be introduced solely because it exists in a conventional financial-system architecture.

---

## Core Principle

> **The approved event catalogue contains the financial events necessary to observe the OCB sandbox's defined financial activities without reproducing unnecessary institutional architecture. Institutional ownership remains with the source institution; OCB observes and resolves institutional activity and may represent its financial consequences for analysis without collapsing the underlying institutional boundaries.**

**WP-1.3 — FINANCIAL EVENT CATALOGUE: COMPLETE / LOCKED**
