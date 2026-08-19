# OCB Financial Event Semantics

## Purpose

This document defines the business semantics of the authoritative financial events identified in the OCB Financial Event Catalogue.

It defines, for each event:

- purpose / business meaning;
- actor;
- source;
- destination;
- value;
- timestamp;
- lifecycle;
- financial consequence;
- institution;
- state consequences;
- downstream intelligence significance;
- observation boundary.

This document defines business semantics. It does not define physical database structures or implementation details.

---

## 1. Relationship to Financial Event Catalogue

The Financial Event Catalogue establishes which events are recognised by OCB Platform v1.0.0.

This document establishes what those events mean.

The distinction is:

```text
Financial Event Catalogue
        ↓
What events does OCB recognise?
        ↓
Financial Event Semantics
        ↓
What does each event mean?
````

Any change to the approved event inventory must be reflected in the Financial Event Catalogue and, where materially architectural, handled through the appropriate ADR process.

---

# 2. Ananse Telecom Events

## 2.1 Cash-in

### Purpose / Business Meaning

A Cash-in is an Ananse Telecom financial event that increases the customer's wallet balance.

### Actor

Customer.

### Source

Ananse Telecom.

### Destination

Customer wallet.

### Value

The monetary amount credited to the wallet.

### Timestamp

The authoritative event timestamp supplied by Ananse Telecom.

Event time is distinct from ingestion and processing timestamps.

### Lifecycle

```text
Cash-in
   ↓
Outcome
   ├── Successful
   └── Failed
```

A successful Cash-in produces a financial consequence. A failed Cash-in produces no wallet consequence.

### Financial Consequence

Successful:

```text
Customer Wallet
      +
    Amount
```

Failed:

```text
Customer Wallet
      =
    Unchanged
```

### Institution

Ananse Telecom.

### State Consequences

A successful Cash-in increases the customer's wallet balance.

A failed Cash-in does not change the wallet balance.

### Downstream Intelligence Significance

Supports analysis of:

* wallet inflows;
* transaction velocity;
* cash-in concentration;
* customer behaviour;
* liquidity activity.

### Observation Boundary

OCB observes the customer's wallet-level financial consequence.

Agent float, cash position, internal settlement, and other Ananse Telecom operational mechanisms are outside the OCB financial-event model.

---

## 2.2 Cash-out

### Purpose / Business Meaning

A Cash-out is an Ananse Telecom financial event that decreases the customer's wallet balance as value is withdrawn from the wallet.

### Actor

Customer.

### Source

Customer wallet / Ananse Telecom.

### Destination

Customer.

### Value

The monetary amount deducted from the wallet.

### Timestamp

The authoritative event timestamp supplied by Ananse Telecom.

### Lifecycle

```text
Cash-out
   ↓
Outcome
   ├── Successful
   └── Failed
```

### Financial Consequence

Successful:

```text
Customer Wallet
      -
    Amount
```

Failed:

```text
Customer Wallet
      =
    Unchanged
```

### Institution

Ananse Telecom.

### State Consequences

A successful Cash-out decreases the customer's wallet balance.

A failed Cash-out does not change the wallet balance.

### Downstream Intelligence Significance

Supports analysis of:

* wallet outflows;
* withdrawal velocity;
* cash-out concentration;
* behavioural patterns;
* balance validation.

### Observation Boundary

OCB observes the customer-side financial consequence.

Agent float, agent cash position, and internal agent settlement mechanisms are outside the OCB financial-event model.

---

## 2.3 P2P Transfer

### Purpose / Business Meaning

A P2P Transfer is an Ananse Telecom financial event in which value is transferred between two customer wallets.

### Actor

Sending customer.

### Source

Sender's wallet.

### Destination

Receiver's wallet.

### Value

The amount transferred between the wallets.

### Timestamp

The authoritative event timestamp supplied by Ananse Telecom.

### Lifecycle

```text
P2P Transfer
      ↓
Outcome
   ├── Successful
   └── Failed
```

### Financial Consequence

A successful P2P Transfer produces two financial legs:

```text
Sender Wallet
      -
    Amount

Receiver Wallet
      +
    Amount
```

P2P Send and P2P Receive are financial legs of the same P2P Transfer, not separate financial events.

A failed P2P Transfer produces no wallet financial consequence.

### Institution

Ananse Telecom.

### State Consequences

Successful transfer:

```text
Sender Wallet  = -Amount
Receiver Wallet = +Amount
```

Failed transfer:

```text
Both Wallets = Unchanged
```

### Downstream Intelligence Significance

Supports analysis of:

* inflows;
* outflows;
* velocity;
* transaction concentration;
* customer-to-customer activity;
* behavioural anomalies;
* reconciliation.

Repeated failed P2P attempts may also provide behavioural evidence where captured.

### Observation Boundary

OCB observes the transfer and its customer-wallet consequences.

OCB does not reproduce Ananse Telecom's internal transfer-processing architecture.

---

## 2.4 Merchant Payment

### Purpose / Business Meaning

A Merchant Payment is an Ananse Telecom financial event in which a customer pays a merchant using the customer's wallet.

### Actor

Customer.

### Source

Customer wallet.

### Destination

Merchant reference.

### Value

The amount paid by the customer.

### Timestamp

The authoritative event timestamp supplied by Ananse Telecom.

### Lifecycle

```text
Merchant Payment
      ↓
Outcome
   ├── Successful
   └── Failed
```

### Financial Consequence

Successful:

```text
Customer Wallet
      -
    Amount
```

The merchant is represented as an observable reference and not as an OCB financial account.

Failed:

```text
Customer Wallet
      =
    Unchanged
```

### Institution

Ananse Telecom.

### State Consequences

A successful Merchant Payment decreases the customer's wallet balance.

A failed Merchant Payment does not change the customer's wallet balance.

### Downstream Intelligence Significance

Supports analysis of:

* merchant transaction concentration;
* customer spending behaviour;
* merchant activity;
* suspicious merchant activity;
* payment velocity.

### Observation Boundary

OCB observes the customer's financial consequence and relevant merchant reference.

OCB does not model a merchant-side account, merchant ledger, or merchant settlement architecture.

---

# 3. SikaCredit Events

## 3.1 Loan Disbursement

### Purpose / Business Meaning

A Loan Disbursement is a SikaCredit financial event that establishes the principal amount of a loan as an outstanding financial obligation.

### Actor

SikaCredit.

### Source

SikaCredit.

### Destination

Customer / borrower.

### Value

The disbursed loan principal.

### Timestamp

The authoritative loan disbursement timestamp.

### Lifecycle

```text
Loan Disbursement
      ↓
Successful
      ↓
Loan becomes financially effective
```

Loan approval is not a financial event in this catalogue.

### Financial Consequence

```text
Outstanding Loan Principal
          +
      Disbursed Amount
```

### Institution

SikaCredit.

### State Consequences

A successful disbursement establishes an outstanding loan obligation.

### Downstream Intelligence Significance

Supports analysis of:

* credit exposure;
* loan volume;
* disbursement concentration;
* repayment behaviour;
* delinquency;
* default;
* loan-rate analysis.

The loan rate remains an attribute required for later loan intelligence and calculation design.

### Observation Boundary

OCB observes the loan and its authoritative financial consequences.

OCB does not reproduce SikaCredit's internal credit-decision or loan-processing architecture.

---

## 3.2 Loan Repayment

### Purpose / Business Meaning

A Loan Repayment is a SikaCredit financial event that reduces an outstanding loan obligation.

### Actor

Customer / borrower.

### Source

Customer repayment obligation within SikaCredit.

### Destination

SikaCredit loan obligation.

### Value

The repayment amount.

### Timestamp

The authoritative repayment timestamp.

### Lifecycle

```text
Loan Repayment
      ↓
Outcome
   ├── Successful
   └── Failed
```

### Financial Consequence

Successful:

```text
Outstanding Loan Obligation
          -
    Repayment Amount
```

Failed:

```text
Outstanding Loan Obligation
          =
       Unchanged
```

### Institution

SikaCredit.

### State Consequences

A successful repayment reduces the outstanding loan obligation.

Repayment information contributes to determining loan status and performance.

### Downstream Intelligence Significance

Supports analysis of:

* repayment behaviour;
* outstanding exposure;
* delinquency;
* default;
* repayment performance;
* loan-rate-related analysis.

### Observation Boundary

OCB observes the authoritative loan repayment event and its financial consequence.

---

# 4. Oman Remit Event

## 4.1 Remittance

### Purpose / Business Meaning

A Remittance is an Oman Remit financial event representing the transfer of value from a sender to a beneficiary.

### Actor

Sender.

### Source

Sender-side remittance instruction within Oman Remit.

### Destination

Beneficiary.

### Value

The amount transferred to the beneficiary.

### Timestamp

The authoritative remittance event timestamp.

### Lifecycle

```text
Remittance
      ↓
Outcome
   └── Successful
```

Failed remittance processing is not currently included as an OCB observable financial event.

### Financial Consequence

A successful remittance results in value being received by the beneficiary.

Within the v1.0.0 OCB abstraction, the successful financial consequence is treated as settled.

### Institution

Oman Remit.

### State Consequences

A successful remittance changes the relevant customer financial state by transferring value to the beneficiary.

### Downstream Intelligence Significance

Supports analysis of:

* cross-border flows;
* remittance volumes;
* customer remittance behaviour;
* destination patterns;
* concentration;
* AML-related analysis.

### Observation Boundary

OCB observes the remittance financial activity relevant to its intelligence requirements.

Sender and beneficiary are remittance roles and are not separate first-class OCB entities.

OCB does not reproduce Oman Remit's internal remittance-processing or settlement architecture.

---

# 5. Cross-Event Semantic Rules

## 5.1 Event Outcome

An event outcome describes what happened to the event.

```text
Event
  ↓
Successful / Failed
```

A failed event does not produce its intended financial consequence.

---

## 5.2 Financial Consequence

A financial consequence describes the change produced by a successful event.

```text
Event
  ↓
Financial Consequence
  ↓
Financial State
```

---

## 5.3 Settlement

Settlement is not an independent financial event in the v1.0.0 model.

A successfully completed financial event is considered settled where its intended financial consequence has been completed within the relevant institutional domain.

This abstraction does not imply a separate OCB settlement layer.

---

## 5.4 P2P Transfer Legs

P2P Send and P2P Receive are financial legs of the P2P Transfer.

They are not separate events and are not derived after the fact from wallet balances.

---

## 5.5 Loan Default

Loan Default is a derived credit state.

It is determined from authoritative loan information, repayment information, and the applicable repayment deadline or rules.

It is not an independent financial event.

---

# 6. Correction, Reversal and Adjustment

## 6.1 Correction

Correction is treated as an internal institutional control mechanism rather than an OCB financial event.

The OCB sandbox assumes that authoritative information crossing the observation boundary has undergone the originating institution's applicable internal controls.

---

## 6.2 Reversal

Reversal is not included as a v1.0.0 OCB financial event.

A reversal would introduce a subsequent event linked to a previously established financial event and would materially affect event history, ledger treatment, reconciliation, and state reconstruction.

A future architecture involving additional settlement institutions, banks, escrow arrangements, or other requirements may justify a separate reversal model.

---

## 6.3 Adjustment

Adjustment is not included as a v1.0.0 OCB financial event.

The term is insufficiently specific to establish a controlled financial meaning without a concrete business requirement.

---

# 7. Status

**Status:** Defined

This document establishes the business semantics of the authoritative financial events identified in the OCB Financial Event Catalogue.

Physical representation, ledger design, database structures, and implementation rules are deferred to the appropriate engineering stages.

Any material change to these semantics must be reflected in the Financial Event Catalogue and reviewed through the applicable governance process.

---

## Core Principle

> **Define what the financial event means before defining how the system stores it.**

```

**This is the version I would actually commit as T02.** It is deliberately leaner than my previous response, follows the T02 fields, and leaves implementation decisions for the later database/ledger work.
```
