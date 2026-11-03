# OCB PLATFORM v1.0.0

## PROJECT SUMMARY — PLATFORM OVERVIEW

### Official Project Definition

**Programme:** OCB Platform v1.0.0  
**Document:** Project Summary  
**Component:** Financial Intelligence Platform  
**Purpose:** Summarise the platform's objectives, implemented architecture, institutional scope, analytical capabilities, and release boundaries.  
**Implementation Status:** Core analytical platform and public supervisory dashboard implemented.

---

## 1. PROJECT OVERVIEW

The **Osagyefo Central Bank Digital Financial Intelligence Platform (OCB)** is a SQL-first, synthetic financial-intelligence and supervisory-monitoring platform. It transforms simulated financial activity into structured analytical data, intelligence signals, and investigation outputs.

The platform demonstrates how data engineering, analytical modelling, and financial intelligence logic can be combined to examine financial activity across independently modelled institutions.

**Platform principle:** Engineer financial truth. Transform events into intelligence.

## 2. PROJECT OBJECTIVES

OCB v1.0.0 was developed to establish an analytical workflow capable of:

- Transforming institutional source records into structured analytical data.
- Resolving synthetic customer identities across separate institutional data sources.
- Providing reusable analytical views at defined grains.
- Identifying transaction anomalies and financial-behaviour patterns.
- Analysing lending, repayment, transaction, and remittance activity.
- Examining event sequences and cross-institution associations.
- Supporting institutional monitoring and targeted supervisory investigations.
- Presenting analytical outputs through an interactive public dashboard.

## 3. INSTITUTIONAL SCOPE

The platform models three independent synthetic institutions.

| Institution | Domain | Activity represented |
|---|---|---|
| Ananse Telecom | Electronic money and mobile money | Cash-in, cash-out, P2P transfers, merchant payments, and other transaction activity |
| SikaCredit | Digital lending | Loan disbursements and repayments |
| Oman Remit | Remittance services | Inbound and outbound remittance activity |

The simulation covers **1 January 2023 to 31 December 2025**.

Each institution remains a separate source domain. Cross-institution analysis is performed within the OCB analytical environment and does not imply shared operational systems, accounts, or infrastructure.

## 4. IMPLEMENTED ANALYTICAL ARCHITECTURE

The platform follows a layered analytical workflow:

**Source Records → Bronze → Silver → Gold → Intelligence → Supervisory Dashboard**

### 4.1 Bronze — Source Ingestion

The Bronze layer holds loaded source records for downstream transformation and analysis.

### 4.2 Silver — Transformation and Identity Resolution

The Silver layer prepares source records for analytical use while retaining source identifiers and establishing canonical customer mappings for cross-institution analysis.

### 4.3 Gold — Analytical Model

The Gold layer exposes reusable analytical views covering customer, institution, transaction, loan, repayment, and remittance information.

### 4.4 Intelligence — Financial Analysis

The intelligence layer contains SQL-based analytical logic for transaction patterns, financial behaviour, credit-related signals, event sequences, anomaly detection, and cross-institution analysis.

### 4.5 Supervisory Dashboard

The public dashboard presents institutional monitoring outputs and a set of 12 supervisory investigation questions supported by prepared synthetic-data snapshots.

Microsoft SQL Server and T-SQL provide the principal data-engineering and analytical environment. The public dashboard consumes prepared snapshots rather than querying the development database directly.

## 5. FINANCIAL INTELLIGENCE CAPABILITIES

The implemented analytical capabilities cover:

- Transaction-level intelligence and transaction-type anomalies.
- Customer financial-behaviour analysis.
- Lending, borrowing, and repayment patterns.
- Event sequencing, rapidity, and recurrence.
- Value correspondence between related financial events.
- Cross-institution analytical associations.
- Institutional activity and status monitoring.
- Supervisory investigations combining selected event populations with existing intelligence signals.

The analytical model preserves event-level detail where the question depends on event order, timing, recurrence, or value correspondence. Aggregated monitoring outputs serve summary purposes and do not replace event-level evidence where sequence analysis is required.

## 6. SUPERVISORY INVESTIGATION WORKBENCH

The released dashboard addresses 12 supervisory questions involving patterns in the simulated data, including:

- SikaCredit's November 2025 lending surge.
- Ananse Telecom's December 2025 transaction surge.
- Failed and rejected transaction activity.
- Inbound remittance activity associated with FATF-flagged origins in the simulation.
- Remittance and mobile-money event sequences.
- Relationships between lending, repayments, transactions, and remittances.

The questions are defined in the **Supervisory Intelligence Questions** document and presented through the public dashboard.

The workbench supports examination of analytical evidence. It does not automatically establish misconduct or make regulatory findings.

## 7. TECHNOLOGY

The principal technologies used in the implementation are:

| Technology | Role |
|---|---|
| Microsoft SQL Server | Data storage and analytical execution environment |
| T-SQL | Data transformations, analytical views, and intelligence logic |
| Python | Simulation and supporting data-preparation workflows |
| Streamlit | Interactive public dashboard |
| Pandas | Data handling and preparation |
| Plotly | Dashboard visualisation |
| CSV snapshots | Prepared datasets consumed by the public dashboard |

## 8. VALIDATION AND RELEASE

The completed build record reports:

- **14 passing unit tests**
- **23 monitoring datasets exported**
- **27 investigation snapshots exported**

These figures describe the recorded validation and exported dashboard artefacts. They do not constitute production certification or regulatory approval.

**Public dashboard:** https://ocb-financial-intelligence.streamlit.app/  
**Source repository:** https://github.com/deloveyeboah10-Nagato/OCB_PLATFORM

## 9. SCOPE BOUNDARIES

OCB v1.0.0 is a synthetic analytical platform for demonstration, monitoring, and supervisory investigation.

It is not a production banking platform, transaction-processing system, operational ledger, or reconciliation engine. It does not connect to real institutional systems or use real customer financial records.

Temporal proximity, recurrence, anomaly signals, and value correspondence must be interpreted within the rules and data that produce them. These relationships do not independently prove direct funding, intent, causation, fraud, money laundering, or other misconduct.

## 10. PROJECT OUTCOME

OCB v1.0.0 delivers an integrated analytical workflow connecting source-data preparation, customer identity resolution, reusable analytical modelling, SQL-based financial intelligence, institutional monitoring, and a public supervisory investigation dashboard.

The completed platform demonstrates how financial events can be transformed into structured, traceable analytical outputs that support further examination of financial activity across distinct synthetic institutional domains.