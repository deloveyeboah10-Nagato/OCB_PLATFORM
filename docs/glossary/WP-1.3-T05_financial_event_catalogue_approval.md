# OCB Financial Event Catalogue Approval

## Purpose

This document records the final review and approval of the OCB Platform v1.0.0 financial-event catalogue.

The review evaluates whether the approved financial events provide sufficient coverage for the platform's defined financial-intelligence and analytical requirements.

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

These events represent the authoritative financial activities required within the OCB observation boundary.

---

# 2. Business-Question Coverage

## 2.1 Transaction Activity

| Requirement                   | Supporting Events                        |
| ----------------------------- | ---------------------------------------- |
| Wallet inflows                | Cash-in, P2P Transfer                    |
| Wallet outflows               | Cash-out, P2P Transfer, Merchant Payment |
| Customer-to-customer movement | P2P Transfer                             |
| Merchant activity             | Merchant Payment                         |
| Transaction sequencing        | All applicable events                    |

**Coverage:** Sufficient.

---

## 2.2 Behavioural Intelligence

| Requirement                   | Supporting Events                                 |
| ----------------------------- | ------------------------------------------------- |
| Transaction velocity          | All applicable events                             |
| Inflow/outflow behaviour      | Cash-in, Cash-out, P2P Transfer, Merchant Payment |
| Repeated failed activity      | Failed outcomes of applicable events              |
| Customer behavioural patterns | Customer-associated financial events              |
| Transaction concentration     | Applicable financial events                       |

**Coverage:** Sufficient.

Failed events remain observable outcomes where captured by the relevant source. They do not require separate financial-event types.

---

## 2.3 Liquidity Intelligence

| Requirement                   | Supporting Events                        |
| ----------------------------- | ---------------------------------------- |
| Wallet inflows                | Cash-in, P2P Transfer                    |
| Wallet outflows               | Cash-out, P2P Transfer, Merchant Payment |
| Wallet balance reconstruction | Wallet-affecting events                  |
| Customer liquidity behaviour  | Wallet-affecting events                  |

**Coverage:** Sufficient.

---

## 2.4 Credit Intelligence

| Requirement            | Supporting Events                                                   |
| ---------------------- | ------------------------------------------------------------------- |
| Loan exposure          | Loan Disbursement                                                   |
| Repayment behaviour    | Loan Repayment                                                      |
| Outstanding obligation | Loan Disbursement and Loan Repayment                                |
| Delinquency            | Loan information and repayment history                              |
| Default                | Derived from loan obligations, deadlines, and repayment information |
| Loan-rate analysis     | Loan attributes and applicable loan events                          |

**Coverage:** Sufficient.

Loan application and approval are not required as independent financial events because they do not themselves establish the financial obligation.

---

## 2.5 Remittance Intelligence

| Requirement                      | Supporting Events                     |
| -------------------------------- | ------------------------------------- |
| Remittance activity              | Remittance                            |
| Remittance value                 | Remittance                            |
| Customer remittance behaviour    | Remittance                            |
| Cross-border flow analysis       | Remittance                            |
| Beneficiary/destination analysis | Remittance and participant references |

**Coverage:** Sufficient.

Failed remittance processing is not included as an independent OCB financial event because it does not represent a customer financial-state change within the current OCB observation boundary.

---

## 2.6 Reconciliation and Financial Integrity

| Requirement                                 | Supporting Events                                 |
| ------------------------------------------- | ------------------------------------------------- |
| Wallet inflow/outflow reconstruction        | Cash-in, Cash-out, P2P Transfer, Merchant Payment |
| P2P balancing                               | P2P Transfer                                      |
| Loan obligation reconstruction              | Loan Disbursement, Loan Repayment                 |
| Historical event reconstruction             | Authoritative financial events and provenance     |
| Failed-event exclusion from financial state | Event outcomes                                    |

**Coverage:** Sufficient.

P2P Transfer remains one authoritative event with two financial legs:

```text
P2P Transfer
      │
      ├── Sender Outflow
      └── Receiver Inflow
```

This preserves both event identity and ledger/reconciliation requirements.

---

# 3. Candidates Reviewed and Excluded

The following concepts were specifically reviewed during T01–T04.

| Candidate             | Decision                      | Treatment                                                  |
| --------------------- | ----------------------------- | ---------------------------------------------------------- |
| P2P Send              | Excluded as independent event | Financial leg of P2P Transfer                              |
| P2P Receive           | Excluded as independent event | Financial leg of P2P Transfer                              |
| Loan Application      | Excluded                      | Process/lifecycle concept                                  |
| Loan Approval         | Excluded                      | Credit decision                                            |
| Loan Closure          | Excluded                      | Derived/lifecycle state                                    |
| Loan Default          | Excluded                      | Derived credit state                                       |
| Remittance Initiation | Excluded                      | Process/lifecycle concept                                  |
| Remittance Receipt    | Excluded as separate event    | Consequence of successful Remittance                       |
| Failed Remittance     | Excluded                      | Outside current OCB observable financial-event requirement |
| Settlement            | Excluded as independent event | Completed consequence/status                               |
| Correction            | Excluded                      | Originating-institution internal control                   |
| Reversal              | Excluded                      | No sufficiently strong v1.0.0 requirement                  |
| Adjustment            | Excluded                      | Insufficiently defined business meaning                    |

These exclusions are deliberate scope decisions rather than omissions.

---

# 4. Observation Boundary

The approved catalogue reflects the OCB Platform's role as an analytical and supervisory sandbox.

OCB does not reproduce the complete internal architecture of:

* Ananse Telecom;
* SikaCredit;
* Oman Remit.

Accordingly, events and states that belong primarily to institutional operational architecture are not introduced solely because they exist in real-world financial systems.

The catalogue focuses on financial activity that is observable and materially useful to OCB intelligence requirements.

---

# 5. Completeness Assessment

The catalogue provides authoritative financial events for:

```text
Ananse Telecom
    ├── Cash-in
    ├── Cash-out
    ├── P2P Transfer
    └── Merchant Payment

SikaCredit
    ├── Loan Disbursement
    └── Loan Repayment

Oman Remit
    └── Remittance
```

These events provide sufficient coverage for the v1.0.0 financial-intelligence requirements identified during the programme.

No additional authoritative financial event is required at this stage.

---

# 6. Approval Decision

**Decision: APPROVED**

The v1.0.0 financial-event catalogue is approved for progression into subsequent financial-state, ledger, business-rule, and implementation design.

The approved catalogue is:

1. Cash-in
2. Cash-out
3. P2P Transfer
4. Merchant Payment
5. Loan Disbursement
6. Loan Repayment
7. Remittance

The catalogue must not be expanded merely to reproduce institutional mechanisms that fall outside the OCB observation boundary.

Any future addition, removal, or material reclassification of an authoritative financial event requires review and, where architecturally significant, an ADR.

---

# 7. Programme 1.3 Completion

The following work has been completed:

| Ticket     | Deliverable                       | Status   |
| ---------- | --------------------------------- | -------- |
| WP-1.3-T01 | Financial event inventory         | Complete |
| WP-1.3-T02 | Event semantics                   | Complete |
| WP-1.3-T03 | Event/state relationships         | Complete |
| WP-1.3-T04 | Correction and reversal semantics | Complete |
| WP-1.3-T05 | Event catalogue approval          | Complete |

**WP-1.3 — Financial Event Catalogue: COMPLETE**

---

## Core Principle

> **The approved event catalogue contains the financial events necessary to observe the OCB sandbox's defined financial activities without reproducing unnecessary institutional architecture.**
