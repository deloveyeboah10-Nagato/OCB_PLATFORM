# OCB Business Glossary

## Purpose

This directory contains the Business Glossary for the Osagyefo Central Bank Digital Financial Intelligence Platform (OCB Platform) v1.0.0.

The Business Glossary establishes the controlled vocabulary used across the OCB financial domain, financial processing, analytical platform, intelligence platform, and regulatory interpretation.

Its purpose is to ensure that important financial and analytical concepts have precise, consistent, and traceable meanings.

The glossary must provide a common language between:

```text
Business Domain
      ↓
Financial Processing
      ↓
Data Model
      ↓
Analytical Model
      ↓
Financial Intelligence
      ↓
Regulatory Intelligence
```

The glossary defines **business meaning**.

It does not independently determine physical database implementation or architectural authority.

---

## 1. Relationship to Governing Documentation

The Business Glossary operates within the established OCB documentation hierarchy:

```text
Master Project Document
        ↓
Project Charter
        ↓
Implementation & Engineering Specification
        ↓
Technical Build Guide
        ↓
Work Breakdown Structure
        ↓
Business Glossary
        ↓
Data Dictionary
        ↓
Implementation
        ↓
Testing & Validation
```

The Business Glossary must remain consistent with the governing documents above it.

It must not independently introduce:

- new platform scope;
- new financial capabilities;
- new architectural boundaries;
- unsupported production capabilities;
- unapproved terminology that changes established meaning.

Where terminology exposes a material architectural issue, the appropriate engineering governance and ADR process must be followed.

---

## 2. Glossary Status

The Business Glossary is a **living build-time reference**.

The framework is established during the foundation phase.

The glossary is populated and refined as the platform acquires concrete implementation knowledge.

The project must not invent detailed definitions merely to make the glossary appear complete.

Terms should be added when they are justified by:

- the approved business domain;
- an implemented capability;
- an analytical question;
- an intelligence rule;
- a regulatory requirement within the simulation;
- a testing requirement;
- an architectural decision;
- a required distinction between system responsibilities.

---

## 3. Definition Standard

Each significant glossary entry should provide, where applicable:

| Field | Purpose |
|---|---|
| **Term** | Official OCB terminology |
| **Definition** | Precise business meaning |
| **Context** | Where the concept is used |
| **System / Domain** | Originating or relevant institutional domain |
| **Ownership** | Conceptual ownership boundary |
| **Related Concepts** | Directly associated concepts |
| **Financial Significance** | Why the concept matters |
| **Analytical Significance** | Why the concept matters to analysis or intelligence |
| **Implementation Reference** | Relevant technical object once implemented |
| **Status** | Current definition state |
| **Notes / Boundary** | Important limitations or distinctions |

Definitions should be sufficiently precise that two technically competent engineers should derive substantially the same interpretation.

---

## 4. Definition Status

Glossary entries may use the following statuses:

### Proposed

The term has been identified but its formal OCB meaning has not yet been finalized.

### Defined

The business meaning has been formally established.

### Implemented

The term has a defined meaning and is represented by an implemented platform capability or data structure.

### Deprecated

The terminology is no longer preferred but remains historically relevant.

The status must reflect the actual state of the platform.

---

## 5. Core Domain Areas

The glossary structure should support the following terminology domains.

### 5.1 Institutional Terminology

Terms relating to:

- Ananse Telecom;
- SikaCredit;
- Oman Remit;
- OCB;
- institutional ownership;
- institutional responsibility;
- institutional boundaries;
- regulatory observation.

### 5.2 Financial Entity Terminology

Terms relating to justified financial entities such as:

- customer;
- wallet;
- merchant;
- agent;
- loan;
- remittance;
- account;
- transaction;
- ledger;
- institution.

Only entities justified by the platform should be added.

### 5.3 Financial Event Terminology

Terms relating to financial events such as:

- cash-in;
- cash-out;
- P2P transfer;
- merchant payment;
- loan disbursement;
- loan repayment;
- remittance;
- settlement;
- correction;
- reversal.

Definitions must distinguish financial events from their downstream interpretations.

### 5.4 Financial State Terminology

Terms relating to:

- balance;
- financial state;
- wallet state;
- loan state;
- transaction state;
- ledger state;
- successful processing;
- failed processing;
- rejected processing;
- corrected state;
- reversed state.

Financial state terminology must remain consistent with the principle that authoritative financial consequences originate from valid financial events.

### 5.5 Temporal Terminology

Where required, distinguish concepts such as:

- event time;
- transaction time;
- processing time;
- settlement time;
- effective time;
- recorded time.

Temporal concepts must not be treated as interchangeable without an explicit business justification.

### 5.6 Risk & Intelligence Terminology

Where implemented or required, define terms relating to:

- anomaly;
- velocity;
- structuring;
- risk indicator;
- risk event;
- risk score;
- behavioural deviation;
- concentration;
- exposure.

Quantitative intelligence terminology must eventually be connected to formal definitions and testable rules.

### 5.7 Liquidity Terminology

Where implemented or required, define concepts such as:

- inflow;
- outflow;
- net flow;
- liquidity pressure;
- liquidity stress;
- wallet stress;
- institutional pressure;
- system stress;
- settlement pressure.

Quantitative liquidity concepts must eventually identify their calculation basis, population, and time period.

### 5.8 Credit Terminology

Where implemented or required, define concepts such as:

- loan;
- principal;
- disbursement;
- repayment;
- outstanding balance;
- due date;
- delinquency;
- default;
- active loan;
- closed loan;
- defaulted loan;
- repayment behaviour;
- credit exposure.

Loan status must remain distinct from analytical measures of loan performance.

### 5.9 Remittance Terminology

Where implemented or required, define concepts such as:

- remittance;
- sender;
- beneficiary;
- originating institution;
- receiving institution;
- origin country;
- destination country;
- currency;
- exchange rate;
- settlement;
- remittance status;
- cross-border flow.

Additional remittance terminology must be proportional to the actual platform requirements.

### 5.10 Data Engineering Terminology

The glossary should establish controlled business meaning for analytical concepts such as:

- Bronze;
- Silver;
- Gold;
- ELT;
- data lineage;
- analytical representation;
- data mart;
- analytical grain.

The glossary must preserve the distinction between logical analytical responsibilities and physical database structures.

### 5.11 Regulatory Terminology

Where required by implemented supervisory workflows, define concepts such as:

- regulatory indicator;
- regulatory threshold;
- supervisory alert;
- regulatory report;
- investigation;
- case;
- institution monitoring;
- systemic risk indicator;
- escalation;
- regulatory consideration.

Regulatory terminology must reflect the OCB simulation rather than blindly importing generic real-world regulatory terminology.

### 5.12 Metric Terminology

Every important intelligence or regulatory metric should eventually have a controlled definition containing, where applicable:

| Field | Requirement |
|---|---|
| **Metric Name** | Official name |
| **Business Definition** | What it measures |
| **Formula** | Mathematical or rule-based calculation |
| **Population** | Records included |
| **Time Window** | Applicable period |
| **Grain** | Level of measurement |
| **Interpretation** | Meaning of the result |
| **Consumer** | Intended analytical or supervisory user |
| **Source** | Originating information |
| **Validation** | How correctness is established |

A metric must not be treated as formally defined merely because a SQL expression exists.

---

## 6. Cross-System Terminology

Where the same concept appears across independent institutional domains, the glossary must distinguish:

### Source Concept

The meaning of the concept within the originating institution.

### OCB Observed Concept

How OCB represents the information intentionally observable through the sandbox boundary.

### Analytical Concept

How the observable information is transformed for analytical or intelligence purposes.

This distinction prevents the platform from incorrectly assuming that independently operated institutions use identical internal concepts or semantics.

---

## 7. Ownership

Each major domain concept should have an identifiable ownership boundary where applicable.

Potential ownership domains include:

- Ananse Telecom;
- SikaCredit;
- Oman Remit;
- OCB Regulatory Intelligence.

A concept may be observed by OCB without being owned by OCB.

Therefore:

```text
Observed by OCB
      ≠
Owned by OCB
```

The glossary must preserve this distinction.

---

## 8. Financial Truth and Derived Interpretation

The glossary must distinguish authoritative financial concepts from derived representations.

Conceptually:

```text
Financial Event
      ↓
Financial Consequence
      ↓
Operational State / Ledger
      ↓
Analytical Transformation
      ↓
Intelligence
      ↓
Regulatory Insight
```

Terms describing:

- financial events;
- financial consequences;
- operational state;
- analytical structures;
- intelligence;
- risk classifications;
- regulatory indicators;

must not be defined in a way that makes a downstream interpretation appear to be an alternative source of financial truth.

---

## 9. Observational Modelling

The glossary must support OCB's observational modelling principle.

OCB does not need to reproduce every internal mechanism of every institution.

Where a regulatory intelligence question can be answered from observable financial information, the glossary should define the observable concept required by OCB rather than expanding unnecessarily into internal institutional terminology.

This protects v1.0.0 from unnecessary domain expansion.

---

## 10. Acronym Register

The completed glossary should maintain a controlled acronym register.

The register should eventually contain, where relevant:

| Acronym | Meaning |
|---|---|
| OCB | Osagyefo Central Bank |
| SQL | Structured Query Language |
| ELT | Extract, Load, Transform |
| ERD | Entity Relationship Diagram |
| KPI | Key Performance Indicator |
| ADR | Architecture Decision Record |
| WBS | Work Breakdown Structure |

Additional acronyms should be added only when they become relevant to the actual platform.

---

## 11. Relationship to the Data Dictionary

The Business Glossary defines **what a business concept means**.

The Data Dictionary defines **how that concept is represented in data**.

The distinction is:

```text
Business Glossary
"What does this concept mean?"
        ↓
Data Model
"How is the concept represented?"
        ↓
Data Dictionary
"What are the technical characteristics?"
```

The two documents must remain mutually consistent.

A database column name must not silently redefine an established business concept.

---

## 12. Relationship to ADRs

ADRs record consequential architectural decisions.

The Business Glossary records controlled terminology.

A terminology decision may require an ADR when changing the meaning of a term would materially affect:

- architecture;
- financial processing;
- data structures;
- intelligence logic;
- institutional boundaries;
- historical interpretation;
- established architectural commitments.

The glossary must not become a substitute for architectural decision records.

---

## 13. Change Control

Changes to established terminology must be controlled.

A terminology change may require review of:

- database objects;
- documentation;
- Data Dictionary;
- intelligence logic;
- tests;
- diagrams;
- ADRs;
- WBS acceptance criteria.

Where a terminology change materially affects architecture, the appropriate governance process must be followed.

Where terminology affects the interpretation of historical financial information, historical meaning must not be silently altered.

---

## 14. Future Population

The glossary will be populated incrementally as implementation creates concrete knowledge.

Future entries should be based on:

```text
Business Requirement
      ↓
Established Concept
      ↓
Precise Definition
      ↓
Implementation Reference
      ↓
Validation
```

The project should not attempt to complete the entire glossary before the corresponding platform concepts have been established.

---

## 15. Completion Standard

The Business Glossary framework is complete for the purposes of the foundation phase when:

- the glossary repository location exists;
- the purpose of the glossary is defined;
- the relationship to governing documentation is defined;
- the definition standard is established;
- definition statuses are established;
- major terminology domains are identified;
- cross-system terminology rules are established;
- ownership boundaries are established;
- financial truth and derived interpretation are distinguished;
- the relationship to the Data Dictionary is defined;
- the relationship to ADRs is defined;
- terminology change control is established;
- future population is explicitly tied to actual implementation knowledge.

The framework does **not** require the complete business vocabulary to be populated at this stage.

---

## 16. Core Principle

The Business Glossary follows one fundamental rule:

> **If two engineers can interpret the same important financial concept differently, the concept is not sufficiently defined.**

The objective is not to create a large dictionary.

The objective is to establish a precise shared language for:

```text
Financial Truth
      ↓
Financial Processing
      ↓
Analytical Processing
      ↓
Financial Intelligence
      ↓
Regulatory Interpretation
```

Terminology should evolve deliberately as the platform is engineered.

**Define the meaning before relying on the data.**