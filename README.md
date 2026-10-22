# OCB Platform v1.0.0
### Osagyefo Central Bank Digital Financial Intelligence Platform

**Engineer financial truth. Transform events into intelligence.**

OCB is a SQL-first financial intelligence and supervisory analytics sandbox built to explore how transaction data, lending activity, repayment behaviour, and cross-institution financial events can be transformed into structured analytical signals and investigation-ready evidence.

The platform uses synthetic financial data representing three independent institutions. It combines a layered data warehouse with T-SQL intelligence engines, institutional monitoring, and cross-institution investigative analysis.

> **Project type:** Financial data engineering · SQL analytics · Financial intelligence · Supervisory monitoring  
> **Environment:** Synthetic regulatory sandbox  
> **Version:** 1.0.0

---

## 1. Project Overview

Financial events become more informative when they are examined in context. Individual transactions, loan disbursements, repayments, and remittances can be analysed for their timing, frequency, value relationships, recurrence, and connections across financial institutions.

OCB explores this process through a reproducible project structure that separates data preparation from analytical interpretation.

The platform is designed to demonstrate how to:

- Generate and manage synthetic financial event data.
- Resolve customer identities across separate institutional datasets.
- Build a layered Bronze, Silver, and Gold data warehouse.
- Develop SQL-based transaction, credit, repayment, and behavioural intelligence.
- Examine temporal and value relationships between events across institutions.
- Produce monitoring outputs and transaction-grain investigation results.
- Document analytical scope, assumptions, limitations, and implementation decisions.

OCB is a portfolio engineering project, not a live central bank system.

## 2. Simulated Financial Institutions

The sandbox models three fictional institutions with distinct financial activities.

| Institution | Domain | Activities represented |
|---|---|---|
| **Ananse Telecom** | Electronic money / mobile money | Cash-in, cash-out, P2P transfers, merchant payments |
| **SikaCredit** | Digital lending | Loan disbursements, loan accounts, repayments |
| **Oman Remit** | Remittance | Inbound and outbound remittance events |

The institutions remain separate simulated entities. Cross-institution analysis examines relationships between their events without treating the institutions as one operational system.

## 3. Architecture and Data Flow

The platform follows a layered data-engineering and analytical workflow:

```text
Synthetic Data Generation
          |
          v
Source Files (CSV / JSON)
          |
          v
Bronze Layer
          |
          v
Silver Layer
  Cleaning, transformation,
  identity resolution
          |
          v
Gold Layer
  Analytical data model
          |
          v
SQL Intelligence Views
          |
          v
Monitoring & Investigations
          |
          v
Presentation Layer
  Dashboard / reporting
```

The architecture separates source data, transformation, analytical modelling, and intelligence logic. This makes it possible to examine how each layer contributes to the final analytical output.

**Related resources**

- [Architecture and data-model documentation](architecture/)
- [Warehouse implementation](warehouse/)
- [Database scripts](scripts/database/)
- [Architecture diagrams](diagrams/)

## 4. Intelligence and Analytical Capabilities

### Transaction intelligence

Transaction-level analysis examines activity, transaction values, distributions, and event sequences.

Implementation: [`WP-5.1_transaction_intelligence.sql`](intelligence/WP-5.1_transaction_intelligence.sql)

### Financial behaviour

Behavioural analysis examines financial activity in context, including patterns across customers, time periods, and transaction categories.

Implementation: [`WP-5.2_financial__behaviour.sql`](intelligence/WP-5.2_financial__behaviour.sql)

### Behavioural anomaly analysis

The platform includes analytical engines for investigating unusual credit behaviour, cross-institution activity, and event sequences.

- [Behavioural anomaly engine](intelligence/WP-5.3-behavioural-anomaly-engine.sql)
- [Credit behaviour anomaly engine](intelligence/WP-5.3_credit_behaviour_anomaly_engine.sql)
- [Cross-institution anomaly engine](intelligence/WP-5.3_cross_institution_anomaly_engine.sql)
- [Sequence anomaly engine](intelligence/WP-5.3_sequence_anomaly_engine.sql)

These analyses produce signals for further examination. An unusual pattern is not, by itself, proof of fraud or misconduct.

### Cross-institution financial behaviour

The platform examines relationships between activity recorded by different institutions, including:

- Ananse cash-in followed by outbound Oman Remit activity.
- SikaCredit loan disbursement followed by outbound Oman Remit activity.
- Inbound Oman Remit activity followed by Ananse P2P transfers.
- Inbound Oman Remit activity followed by SikaCredit repayments.

The analysis uses event relationships and measures such as temporal proximity, value correspondence, and recurrence. These measures support investigation; they do not establish causality or prove the source or destination of funds.

Implementation: [`WP5.2_cross_institution_financial_behaviour.sql`](intelligence/WP5.2_cross_institution_financial_behaviour.sql)

### Supervisory monitoring and investigations

Monitoring and investigation work examines institutional activity and selected patterns that warrant closer review. The investigation layer includes analysis of lending behaviour and cross-institution financial event relationships.

- [Supervisory intelligence investigations](intelligence/WP-6.3-supervisory_intelligence_investigations.sql)
- [Institutional monitoring](reports/WP-6.1_%20institutional_monitoring.sql)

## 5. Data Warehouse

The warehouse is organised into three principal layers.

| Layer | Purpose |
|---|---|
| **Bronze** | Loads source data into the warehouse environment. |
| **Silver** | Applies transformations and supports customer identity resolution. |
| **Gold** | Exposes curated analytical entities for downstream SQL intelligence. |

Key implementation scripts:

- [Bronze full load — WP-3.2](warehouse/WP-3.2-bronze_full_load.sql)
- [Silver customer identity resolution — WP-3.3](warehouse/WP-3.3-silver_ocb_customer_identity_resolution.sql)
- [Silver table deployment — WP-3.3](warehouse/WP-3.3-silver_table_deployment.sql)
- [Silver transformations — WP-3.3](warehouse/WP-3.3-silver_transformations_full_load.sql)
- [Gold layer — WP-3.4](warehouse/WP-3.4-gold_layer.sql)

The Gold model exposes analytical views for transactions, loans, repayments, remittances, customers, and institutions.

## 6. Synthetic Simulation Platform

OCB includes a Python-based simulation platform for generating synthetic financial data used by the analytical environment.

The simulation resources include generator code, configuration, source data, reference data, loading guidance, and documentation of the platform's scope.

**Explore:** [OCB Simulation Platform v1.0.0](simulation/OCB_Simulation_Platform_v1_0_0/)

The data is synthetic and should not be interpreted as real customer activity or evidence of actual financial crime.

## 7. Repository Guide

Use this section to explore the project by implementation area.

| Repository path | Contents |
|---|---|
| [`architecture/`](architecture/) | Architecture, relational schema, entity and operational schema documentation |
| [`docs/`](docs/) | Governance, glossary, data dictionary, backlog, and testing documentation |
| [`diagrams/`](diagrams/) | Draw.io diagrams and SVG visualisations |
| [`simulation/`](simulation/) | Synthetic data generator, configuration, datasets, and simulation documentation |
| [`scripts/database/`](scripts/database/) | Database and schema creation scripts |
| [`scripts/testing/`](scripts/testing/) | Workflow validation and scenario-assignment controls |
| [`warehouse/`](warehouse/) | Bronze, Silver, and Gold implementation |
| [`intelligence/`](intelligence/) | Transaction, behavioural, sequence, and cross-institution intelligence |
| [`reports/`](reports/) | Institutional monitoring SQL |
| [`deprecated/`](deprecated/) | Retained legacy scripts |

## 8. Technology Stack

- **Microsoft SQL Server / T-SQL** — warehouse transformations, analytical views, window functions, and intelligence logic.
- **Python** — synthetic financial data generation.
- **CSV and JSON** — simulation data and configuration.
- **Draw.io and SVG** — architecture and data-model visualisation.
- **Git and GitHub** — source control and project documentation.

## 9. Current Development Status

OCB v1.0.0 has an established simulation, layered warehouse, and SQL intelligence structure. Monitoring and investigation analysis are being developed and refined alongside presentation and documentation work.

The repository should be treated as an evolving portfolio project rather than a fully deployed production platform. The README and supporting documentation will be reconciled with the final implementation as development progresses.

## 10. Scope and Limitations

OCB is a **synthetic supervisory analytics sandbox**.

- It is not a live central bank platform or production regulatory reporting system.
- It is not a payment processor, transaction ledger, or reconciliation engine.
- Its datasets do not represent real financial institutions or customers.
- Analytical signals identify patterns for review; they do not independently establish fraud, intent, causality, or regulatory violations.
- A relationship between events across institutions does not, on its own, prove that one event funded or caused another.
- Production deployment, operational controls, and end-to-end reproducibility should not be assumed from the presence of implementation scripts alone.

## 11. What This Project Demonstrates

OCB brings together financial-domain reasoning and data engineering in a single analytical workflow:

1. **Data engineering:** transforming source data into structured analytical layers.
2. **SQL analytics:** using joins, CTEs, window functions, and views to examine financial events.
3. **Behavioural analysis:** developing signals from transaction, lending, repayment, and sequence patterns.
4. **Cross-institution analysis:** connecting related events across separate simulated financial domains.
5. **Investigative thinking:** preserving event-level evidence and distinguishing observed relationships from conclusions.
6. **Engineering discipline:** separating components, documenting assumptions, and recognising the limitations of synthetic analytical results.

The objective is to demonstrate how financial data can be engineered into useful intelligence while keeping the analytical logic, evidence, and limitations explicit.

---

**OCB Platform v1.0.0**  
*Engineer financial truth. Transform events into intelligence.*