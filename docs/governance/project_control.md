# OCB PLATFORM v1.0.0

## PROJECT CONTROL DOCUMENT — SCOPE, GOVERNANCE & RELEASE CONTROL

### Official Work Package Definition

**Programme:** OCB Platform v1.0.0  
**Work Package:** Project Control Document  
**Component:** Project Governance, Scope Control & Release Management  
**Purpose:** Establish the authoritative scope, architectural boundaries, implementation controls, validation standards, and release requirements for the completed OCB Platform v1.0.0.  
**Implementation Status:** Core platform and public supervisory dashboard implemented; release documentation being finalized.

---

## 1. Project Identity

**Official Name:** Osagyefo Central Bank Digital Financial Intelligence Platform  
**Platform Version:** v1.0.0  
**Platform Type:** SQL-first synthetic financial-intelligence and supervisory-monitoring sandbox  
**Primary Analytical Environment:** Microsoft SQL Server and T-SQL  
**Public Demonstration:** Streamlit  
**Project Principle:** *Engineer financial truth. Transform events into intelligence.*

OCB simulates a financial ecosystem consisting of independent digital financial institutions. It transforms their synthetic source records into validated analytical data, financial-behaviour signals, investigation evidence, and supervisory monitoring outputs.

This document governs what OCB v1.0.0 represents, what it includes, what it excludes, and how its implementation and public presentation must be controlled.

## 2. Project Objective

The objective of OCB v1.0.0 is to demonstrate an end-to-end financial intelligence data platform that can:

- ingest synthetic financial source records;
- transform source data into consistent analytical structures;
- resolve customer identities for cross-institution analysis;
- expose financial events through a Gold analytical model;
- identify transaction, behavioural, temporal, credit, and cross-institution patterns;
- provide SQL-based intelligence and investigation evidence;
- support institutional monitoring and supervisory investigation;
- publish a dashboard using packaged synthetic datasets; and
- present the completed engineering work in a reproducible, inspectable project repository.

The platform is an analytical and supervisory demonstration. Its outputs support examination and review; they do not automatically establish wrongdoing.

## 3. Authoritative Scope

### 3.1 Included Institutions

OCB v1.0.0 models three independent financial entities.

| Institution | Simulated domain | Analytical relevance |
|---|---|---|
| Ananse Telecom | Mobile money and electronic money | Transactions, transaction types, customer activity, transaction outcomes, and behavioural sequences |
| SikaCredit | Digital lending | Loan disbursements, repayments, borrowing behaviour, credit exposure, and loan-related sequences |
| Oman Remit | Remittance services | Inbound and outbound remittances, remittance outcomes, origin-related attributes, and cross-institution sequences |

These entities remain distinct source domains. Their inclusion in a common analytical platform does not make them one operational financial institution or imply shared operational accounts or infrastructure.

### 3.2 Data Period

The synthetic source data covers:

**1 January 2023 – 31 December 2025**

The project uses controlled synthetic records to support repeatable analysis and demonstration. The data must not be represented as actual customer activity or real institutional records.

### 3.3 Included Technical Scope

The completed v1.0.0 platform includes:

- Bronze source ingestion;
- Silver transformations and analytical identity resolution;
- Gold analytical views;
- SQL intelligence and investigation views;
- transaction and behavioural analysis;
- temporal and cross-institution event-sequence analysis;
- institutional monitoring;
- packaged synthetic-data snapshots;
- automated tests recorded for the completed build;
- a public Streamlit dashboard; and
- release-facing documentation and GitHub presentation.

Only implemented and supportable capabilities may be presented as completed functionality.

## 4. Architectural Boundaries

### 4.1 Analytical Architecture

The implemented analytical pathway is:

```text
Synthetic Source Records
          ↓
Bronze Ingestion
          ↓
Silver Transformations
          + Identity Resolution
          ↓
Gold Analytical Model
          ↓
SQL Intelligence and Investigation Views
          ↓
Institutional Monitoring
          + Supervisory Investigation
          ↓
Public Streamlit Dashboard
```

Each layer has a defined purpose. Source ingestion preserves access to the supplied synthetic records; Silver establishes transformed analytical data; Gold provides the analytical model; intelligence views derive investigation signals; and the dashboard presents prepared outputs.

### 4.2 SQL Server as the Source of Truth

SQL Server and T-SQL remain the development and analytical source of truth.

The public dashboard consumes packaged synthetic-data snapshots. It does not require public visitors to connect to the development database.

The dashboard is a presentation and demonstration interface, not a replacement for the SQL implementation.

### 4.3 Institutional Separation

Ananse Telecom, SikaCredit, and Oman Remit are independent source domains. Cross-institution analysis is performed in the analytical layer.

The project must not imply that these entities share a production database, operational account system, transaction-processing infrastructure, or internal logging environment.

OCB analyses the information represented in its synthetic source data and exposed to its analytical model. It does not claim unrestricted access to every internal record that a real institution might generate.

### 4.4 Customer Identity

`ocb_customer_id` is the canonical customer identifier used for analytical customer-level analysis.

`cross_domain_id` represents synthetic simulation ground truth. It must not be described as the production identity-resolution mechanism.

The source identity bridge is based on:

`(source_entity, source_customer_id)`

Cross-institution conclusions must be based on the implemented analytical identity structures and the relevant source events.

### 4.5 Event Grain and Analytical Interpretation

Event-level records must be preserved where the analytical question depends on event ordering, timing, recurrence, or value correspondence.

Sequence and recurrence analyses must reflect their defined anchor events, qualifying events, time boundaries, and relevant conditions. Aggregated results may support monitoring, but must not be substituted for event-grain evidence when the investigation requires individual event relationships.

A temporal or value association does not, by itself, establish that one event directly funded another.

## 5. Scope Exclusions

OCB v1.0.0 is not a production financial operations platform.

The following must not be represented as implemented v1.0.0 capabilities unless supported by the actual delivered implementation:

- production payment or transaction processing;
- live wallet or account management;
- an operational ledger;
- production balance reconstruction;
- correction, reversal, or deferred-processing infrastructure;
- production settlement or reconciliation operations;
- real-time institutional connectivity;
- live regulatory reporting integrations; or
- automatic regulatory determinations based on intelligence scores.

Conceptual designs, abandoned implementation directions, and undeveloped schemas do not become part of the delivered scope merely because they appeared in earlier planning materials.

The project documentation must describe the completed analytical platform, not the broader system that could have been built.

## 6. Intelligence and Supervisory Controls

### 6.1 Intelligence Outputs

OCB's intelligence layer examines patterns such as:

- unusual transaction activity;
- financial behaviour across time;
- rapid or repeated event sequences;
- borrowing and repayment behaviour;
- transaction outcomes;
- remittance activity;
- value relationships between events; and
- activity spanning independent institutional domains.

Signals are intended to identify activity that merits closer examination. Their existence does not independently establish intent, causation, fraud, money laundering, or other misconduct.

### 6.2 Canonical Supervisory Question Set

The dashboard's twelve supervisory investigation questions constitute the canonical question set for v1.0.0.

The questions must remain consistent across the dashboard, GitHub README, and dedicated Supervisory Intelligence Questions document. If a question changes, all affected presentation and documentation artefacts must be reconciled.

The dedicated question document and the public README provide the full wording of the canonical set.

### 6.3 Interpretive Discipline

Public-facing descriptions and investigation outputs must distinguish among:

1. **Observed event:** a record represented in the synthetic data.
2. **Analytical relationship:** a relationship derived from the defined query logic.
3. **Intelligence signal:** a pattern that satisfies a specified analytical condition.
4. **Investigation implication:** a reason to examine the underlying evidence further.

An intelligence signal must not be presented as a proven offence or definitive regulatory finding.

## 7. Implementation and Validation Control

### 7.1 Evidence Standard

A capability may be described as implemented only when the delivered project artefacts support that claim.

Documentation must not substitute intended architecture, proposed work, or an earlier plan for evidence of completed implementation.

### 7.2 Recorded Build Validation

The completed build record reports:

- 14 passing unit tests;
- 23 monitoring datasets exported; and
- 27 investigation snapshots exported.

These are recorded build and export results. They support the release description of the dashboard package and its synthetic outputs; they do not constitute production certification, prove every possible analytical case, or establish suitability for live financial operations.

### 7.3 Reproducibility and Traceability

Project claims should be traceable to the relevant SQL implementation, synthetic data, tests, packaged outputs, or public demonstration.

Where a claim cannot be supported by the available implementation or evidence, the claim must be narrowed or omitted.

## 8. Release and Public Delivery

### 8.1 Public Resources

**Dashboard:** https://ocb-financial-intelligence.streamlit.app/  
**GitHub repository:** https://github.com/deloveyeboah10-Nagato/OCB_PLATFORM

The public dashboard demonstrates institutional monitoring and supervisory investigation using packaged synthetic datasets.

The repository is the engineering presentation surface for the project. It should allow a reviewer to understand the system's purpose, inspect its implementation, and distinguish delivered functionality from its limitations.

### 8.2 Release Documentation

The release documentation set is intended to contain the essential documents needed to understand, control, and inspect the delivered v1.0.0:

- GitHub README;
- Project Summary;
- Project Control Document;
- relevant completed work-package documentation;
- Supervisory Intelligence Questions; and
- Glossary.

Work-package documents must describe the corresponding implemented scope. Shared terminology must remain consistent across the summary, control document, work packages, glossary, README, and dashboard.

## 9. Documentation Governance

### 9.1 Governing Principle

The implementation is the basis for final documentation.

Where an earlier planning document conflicts with the completed implementation, the final documentation must describe the implemented v1.0.0 accurately rather than preserve an obsolete design assumption.

### 9.2 Documentation Acceptance

A document is acceptable for the v1.0.0 release when it:

- accurately describes the implemented platform;
- uses consistent institutional and technical terminology;
- respects the system's analytical and operational boundaries;
- distinguishes completed functionality from excluded or undeveloped functionality;
- avoids unsupported claims;
- agrees with the other release documents; and
- contributes directly to understanding or inspecting the delivered project.

Documentation that duplicates existing content without a clear purpose, preserves superseded plans, or describes unimplemented capabilities must be reconciled or excluded from the final documentation set.

## 10. Change Control

The v1.0.0 release scope is controlled.

A proposed change to the scope, architecture, analytical interpretation, canonical supervisory questions, or public claims must be evaluated against the delivered implementation and the effect on dependent artefacts.

Changes that alter a shared definition or analytical meaning must be reflected consistently in the relevant SQL implementation, work-package documentation, glossary, README, dashboard, and question set.

New capabilities that exceed the completed v1.0.0 scope must not be introduced into the release documentation as though they already exist.

## 11. Release Completion Standard

The OCB Platform v1.0.0 documentation and presentation are ready for release when:

- the Project Summary accurately describes the delivered platform;
- this Project Control Document establishes the final scope and boundaries;
- relevant work-package documents reflect completed implementation;
- the twelve supervisory questions are consistent across their published locations;
- the glossary uses consistent institutional and analytical terminology;
- the GitHub README presents the project and links to the public demonstration;
- public synthetic datasets and artefacts contain no credentials or real personal/financial data; and
- no release document misrepresents a planned, abandoned, or undeveloped capability as implemented.

This standard concerns the accuracy and coherence of the release presentation. It does not claim that OCB v1.0.0 is a production-certified financial system.

## 12. Final Control Principle

OCB v1.0.0 must be presented as the platform that was actually engineered: a SQL-first synthetic financial-intelligence and supervisory-monitoring sandbox that transforms institutional source records into analytical data, investigation signals, and a public supervisory demonstration.

Its credibility depends on the consistency between its source events, analytical logic, intelligence outputs, validation evidence, and public claims.

**The governing rule is simple: document the delivered system, preserve the evidence, and do not claim capabilities beyond the implementation.**