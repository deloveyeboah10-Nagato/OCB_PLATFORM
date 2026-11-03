# OCB PLATFORM v1.0.0
## END-TO-END EXECUTION GUIDE

**Project:** Osagyefo Central Bank Digital Financial Intelligence Platform  
**Version:** 1.0.0  
**Primary database:** `ocb_platform`  
**Primary execution environment:** Microsoft SQL Server  
**Dashboard:** Streamlit

---

## 1. PURPOSE

This guide provides the end-to-end execution sequence for deploying and running the OCB Platform v1.0.0 from the supplied repository.

It covers:

1. Database and table deployment.
2. Bronze source-data loading.
3. Identity resolution and Silver transformation.
4. Gold analytical view deployment.
5. Intelligence engine deployment.
6. Institutional monitoring and supervisory investigations.
7. Dashboard snapshot preparation and public delivery.

The sequence distinguishes between deploying database objects, executing data-loading procedures, creating analytical views, and preparing the public dashboard.

The supplied synthetic dataset is the authoritative source for the standard deployment. The generator does not need to be executed to reproduce the supplied platform.

---

## 2. PREREQUISITES

Before beginning, ensure the following are available:

### Software

- Microsoft SQL Server Database Engine.
- SQL Server Management Studio (SSMS), or another compatible SQL execution client.
- Python 3.11 or newer for dashboard snapshot preparation and local dashboard execution.
- Microsoft ODBC Driver 18 for SQL Server for the Python dashboard's SQL Server connection.
- Git, if preparing the public repository deployment.

### Repository

Download and extract the OCB Platform repository.

Keep the repository directory structure intact. The SQL scripts reference files within the `simulation/` directory.

### SQL Server permissions

The executing account must have sufficient permissions to:

- Create the `ocb_platform` database.
- Create schemas, tables, constraints, procedures and views.
- Execute stored procedures.
- Read the CSV source files through SQL Server's `BULK INSERT` operation.

**Important:** `BULK INSERT` reads files from the perspective of the SQL Server host and its service account, not necessarily the computer or user account running SSMS.

The SQL Server service account must therefore have permission to read the relevant source files.

---

## 3. EXECUTION SEQUENCE

### STAGE 1 — DATABASE AND TABLE DEPLOYMENT

Establish the database and its foundational analytical structures.

Execute the following scripts in order:

| Order | Script | Purpose |
|---|---|---|
| 1.1 | `scripts/database/create_database.sql` | Creates the `ocb_platform` database. |
| 1.2 | `scripts/database/create_schemas.sql` | Creates the Bronze, Silver and Gold schemas. |
| 1.3 | `scripts/database/physical_database_deployment.sql` | Deploys the Bronze source-layer tables and constraints. |

**Execution instructions**

1. Open the first SQL script in SSMS and execute it.
2. Execute the remaining scripts in the specified order.
3. Confirm that the database and Bronze tables have been created successfully.

The physical database deployment script creates the Bronze tables, including reference, institutional source and load-provenance tables.

**Destructive deployment warning**

The Bronze deployment script drops existing Bronze tables before recreating them.

The Silver table deployment script executed later also drops and recreates existing Silver tables.

These scripts are intended for initial deployment or a deliberate full rebuild. Do not execute them against an existing populated environment without understanding and accepting the data-loss implications.

---

### STAGE 2 — BRONZE SOURCE-DATA LOADING

Load the supplied synthetic source data into the Bronze layer.

#### 2.1 Configure source-file paths

Open:

`warehouse/bronze_full_load.sql`

The stored procedure contains absolute file paths in its `BULK INSERT` statements.

Update all source-file paths to match the location of the extracted repository on the SQL Server host.

The procedure references:

**Reference data**

- `simulation/reference/transaction_type.csv`
- `simulation/reference/transaction_status.csv`
- `simulation/reference/transaction_channel.csv`
- `simulation/reference/currency.csv`
- `simulation/reference/country.csv`

**Ananse Telecom**

- `simulation/source/ananse/customers.csv`
- `simulation/source/ananse/wallets.csv`
- `simulation/source/ananse/transactions_2023_Q1.csv` through `transactions_2025_Q4.csv`

**SikaCredit**

- `simulation/source/sikacredit/customers.csv`
- `simulation/source/sikacredit/loans.csv`
- `simulation/source/sikacredit/repayments.csv`

**Oman Remit**

- `simulation/source/oman_remit/customers.csv`
- `simulation/source/oman_remit/remittances.csv`

The SQL Server service account must have read access to these files.

#### 2.2 Deploy the Bronze full-load procedure

Execute:

`warehouse/bronze_full_load.sql`

This creates the stored procedure:

`dbo.ocb_bronze_full_load`

Deploying the procedure does not, by itself, load the source data.

#### 2.3 Execute the Bronze full load

Run:

```sql
EXEC dbo.ocb_bronze_full_load;
```

The procedure:

- Clears existing Bronze data in dependency order.
- Loads reference data.
- Loads institutional customer records.
- Loads Ananse wallet and transaction records.
- Loads SikaCredit loan and repayment records.
- Loads Oman Remit remittance records.
- Records load provenance.

#### 2.4 Verify the Bronze load

Review the execution messages and confirm that the load completed successfully.

Check the principal source tables for populated records:

```sql
SELECT COUNT(*) AS ananse_customer_count
FROM bronze.ananse_customer;

SELECT COUNT(*) AS ananse_transaction_count
FROM bronze.ananse_transaction;

SELECT COUNT(*) AS sikacredit_loan_count
FROM bronze.sikacredit_loan;

SELECT COUNT(*) AS sikacredit_repayment_count
FROM bronze.sikacredit_repayment;

SELECT COUNT(*) AS oman_remittance_count
FROM bronze.oman_remit_remittance;
```

Do not proceed if the Bronze load fails or the expected source records are missing.

---

### STAGE 3 — IDENTITY RESOLUTION AND SILVER TRANSFORMATION

The Silver layer establishes standardised analytical records and the canonical OCB customer identity used across the three simulated institutions.

Execute the following sequence.

#### 3.1 Deploy Silver tables

Execute:

`warehouse/silver_table_deployment.sql`

This creates the Silver tables, relationships and constraints, including:

- `silver.ocb_customer`
- `silver.ocb_customer_identity`
- `silver.ocb_customer_identity_resolved`
- Institutional customer and event tables.
- Reference tables.
- Load-provenance structures.

The script includes deployment verification.

#### 3.2 Configure the identity ground-truth file path

Open:

`warehouse/silver_ocb_customer_identity_resolution.sql`

Update the `BULK INSERT` path for:

`simulation/control/synthetic_identity_ground_truth.csv`

Use the actual absolute path to this file in the extracted repository.

The path must reflect the repository's current directory structure:

`simulation/control/synthetic_identity_ground_truth.csv`

Ensure that the SQL Server service account can read the file.

#### 3.3 Execute identity resolution

Execute:

`warehouse/silver_ocb_customer_identity_resolution.sql`

The script:

1. Unifies customer records from the three Bronze institutions.
2. Generates candidate OCB customer identities.
3. Compares the generated identities against the synthetic identity ground truth.
4. Performs identity validation checks.
5. Persists the validated source-to-OCB identity mappings in `silver.ocb_customer_identity_resolved`.

The ground-truth file is used to validate the generated mappings. It is not loaded as an operational Bronze table.

The script reports the resolved identity count and identity-resolution status.

**Execution checkpoint:** Confirm that identity resolution completes successfully and reports `PASS` before proceeding.

#### 3.4 Execute Silver transformations

Execute:

`warehouse/silver_transformations_final_load.sql`

This script:

- Creates the Silver full-load transformation procedure.
- Creates the Silver transformation verification procedure.
- Executes the full Silver transformation.
- Executes the Silver verification procedure.

The full-load transformation consumes the validated identity mappings produced in the previous step.

The verification procedure checks the completed Silver transformation, including identity mappings, source relationships, location parsing and load provenance.

**Important:** The script already contains the execution statements for the full load and verification. Do not execute the procedures separately as part of the normal sequence.

**Execution checkpoint:** Review the verification output and resolve any failed conditions before proceeding.

---

### STAGE 4 — GOLD ANALYTICAL MODEL DEPLOYMENT

Deploy the foundational Gold analytical views.

Execute:

`warehouse/gold_layer.sql`

This creates the six foundational Gold views:

| View | Analytical purpose |
|---|---|
| `gold.vw_transaction` | Ananse transaction activity. |
| `gold.vw_loan` | SikaCredit loan activity. |
| `gold.vw_repayment` | SikaCredit repayment activity. |
| `gold.vw_remittance` | Oman Remit remittance activity. |
| `gold.vw_customer` | Unified customer analytical interface. |
| `gold.vw_institution` | Institutional analytical reference. |

The Gold layer provides the reusable analytical interface consumed by the intelligence and monitoring layers.

**Execution checkpoint:** Confirm that all six Gold views have been created successfully.

---

### STAGE 5 — INTELLIGENCE ENGINE DEPLOYMENT

Deploy the SQL intelligence engines.

Execute the following scripts in order:

| Order | Script | Purpose |
|---|---|---|
| 5.1 | `intelligence/transaction_anomaly_engine.sql` | Deploys foundational transaction anomaly views and establishes the `intelligence` schema. |
| 5.2 | `intelligence/behavioural_anomaly_engine.sql` | Deploys behavioural anomaly views. |
| 5.3 | `intelligence/credit_behaviour_anomaly_engine.sql` | Deploys credit behaviour and debt-recycling views. |
| 5.4 | `intelligence/sequence_anomaly_engine.sql` | Deploys transaction and financial-event sequence views. |
| 5.5 | `intelligence/cross_institution_anomaly_engine.sql` | Deploys cross-institution financial-event relationship views. |

Execute each script completely before moving to the next.

These scripts create the reusable SQL intelligence views used by subsequent monitoring and investigation work.

**Execution checkpoint:** Confirm successful creation of the intelligence views before proceeding.

#### Additional analytical query files

The repository also contains:

- `intelligence/transaction_intelligence.sql`
- `intelligence/financial__behaviour.sql`
- `intelligence/cross_institution_financial_behaviour.sql`

These are analytical query files rather than foundational view-deployment scripts. They can be executed separately to inspect the corresponding analytical outputs after the required Gold and intelligence objects have been deployed.

They are not additional prerequisites in the core deployment sequence above.

---

### STAGE 6 — INSTITUTIONAL MONITORING AND SUPERVISORY INVESTIGATIONS

This stage deploys the institutional monitoring interfaces and supervisory investigation views.

#### 6.1 Deploy institutional monitoring

Execute:

`reports/institutional_monitoring.sql`

This script creates the institutional monitoring and dashboard-facing views for:

- Ananse Telecom.
- SikaCredit.
- Oman Remit.

It also establishes the dashboard schema and its associated monitoring views.

The dashboard-facing views provide the SQL data sources used by the monitoring dashboard.

#### 6.2 Deploy supervisory investigation views

Execute:

`intelligence/supervisory_intelligence_investigations.sql`

This script contains both investigation queries and reusable supervisory investigation views.

It creates the following investigation views:

- `intelligence.vw_sikacredit_debt_recycling_customer_signals`
- `intelligence.vw_sikacredit_borrowing_surge`
- `intelligence.vw_sikacredit_credit_escalation_customer_signals`
- `intelligence.vw_ananse_customer_transaction_analysis`

The script also executes its embedded investigation queries, returning result sets for the documented supervisory questions.

Execute the complete script, including its embedded query sections.

**Execution checkpoint:** Confirm that the investigation views are created successfully and that the embedded investigation queries execute without missing-object errors.

At this point, the SQL analytical and supervisory layers required by the dashboard have been deployed.

---

### STAGE 7 — DASHBOARD SNAPSHOT PREPARATION AND PUBLIC DELIVERY

The public dashboard uses packaged CSV snapshots rather than a live SQL Server connection.

SQL Server remains the analytical source of truth. The dashboard consumes exported results from the monitoring and investigation SQL sources.

#### 7.1 Prepare the Python environment

Open a terminal in the `dashboard/` directory.

Create the virtual environment:

```powershell
py -3 -m venv .venv
```

Install the dashboard dependencies:

```powershell
.venv\Scripts\python.exe -m pip install --upgrade pip
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

#### 7.2 Configure the SQL Server connection

The snapshot exporter must connect to the deployed OCB database.

Configure the required environment variables in the terminal.

Example using Windows PowerShell and Windows authentication:

```powershell
$env:OCB_DATA_SOURCE = "sql"
$env:OCB_SQL_SERVER = "."
$env:OCB_SQL_DATABASE = "ocb_platform"
$env:OCB_SQL_TRUSTED_CONNECTION = "true"
```

If SQL Server uses a named instance, replace `.` with the appropriate server and instance name.

The SQL Server account used by the Python process must have permission to read the monitoring and investigation sources.

#### 7.3 Export dashboard snapshots

From the `dashboard/` directory, execute:

```powershell
.venv\Scripts\python.exe export_public_snapshots.py
```

The exporter retrieves:

- Institutional monitoring datasets.
- Dashboard-specific analytical datasets.
- Supervisory investigation outputs.

It writes the resulting CSV files into:

- `dashboard/data/`
- `dashboard/data/investigations/`

It also generates:

`dashboard/data_manifest.json`

The manifest records the snapshot source, reporting period, export timestamp, datasets, row counts and columns.

The export covers the reporting period from 1 January 2023 to 31 December 2025.

The exporter stops when a registered source query fails or a required investigation snapshot validation fails. Do not treat an incomplete export as a successful dashboard release.

#### 7.4 Review the exported snapshots

Before publishing the snapshots:

1. Confirm that all expected monitoring datasets were exported.
2. Confirm that all expected investigation datasets were exported.
3. Review the manifest and row counts.
4. Inspect the investigation CSV files for sensitive or identifying fields.
5. Confirm that the exported datasets are appropriate for public release.

Do not commit sensitive or identifying information to a public repository.

#### 7.5 Prepare the public repository

Commit the reviewed dashboard application and its required snapshot files, including:

- Dashboard application and supporting Python files.
- `dashboard/data/`
- `dashboard/data/investigations/`
- `dashboard/data_manifest.json`
- `dashboard/requirements.txt`
- Dashboard configuration and supporting assets.

Push the changes to the GitHub repository.

#### 7.6 Deploy the public dashboard

Use Streamlit Community Cloud to deploy the dashboard from the GitHub repository.

Configure the application entry point as:

`dashboard/app.py`

The public application uses the packaged CSV snapshots. It does not require access to the private SQL Server database.

After deployment, verify that:

- The application starts successfully.
- The institutional monitoring sections load.
- The supervisory investigation section loads.
- Reporting-period controls operate as expected.
- The dashboard displays the reviewed snapshot data.

The public dashboard is the presentation layer. It does not replace the underlying SQL warehouse or intelligence engines.

---

## 4. COMPLETE EXECUTION CHECKLIST

Use this checklist to track a standard deployment.

| Stage | Execution item | Completion |
|---|---|---|
| 1 | Create `ocb_platform` database. | ☐ |
| 1 | Create Bronze, Silver and Gold schemas. | ☐ |
| 1 | Deploy Bronze tables and constraints. | ☐ |
| 2 | Update all Bronze CSV file paths. | ☐ |
| 2 | Deploy `dbo.ocb_bronze_full_load`. | ☐ |
| 2 | Execute and verify Bronze full load. | ☐ |
| 3 | Deploy Silver tables and constraints. | ☐ |
| 3 | Update the identity ground-truth file path. | ☐ |
| 3 | Execute and verify identity resolution. | ☐ |
| 3 | Execute Silver full load and verification. | ☐ |
| 4 | Deploy six Gold analytical views. | ☐ |
| 5 | Deploy transaction anomaly engine. | ☐ |
| 5 | Deploy behavioural anomaly engine. | ☐ |
| 5 | Deploy credit behaviour anomaly engine. | ☐ |
| 5 | Deploy sequence anomaly engine. | ☐ |
| 5 | Deploy cross-institution anomaly engine. | ☐ |
| 6 | Deploy institutional monitoring views. | ☐ |
| 6 | Deploy supervisory investigation views and execute investigation queries. | ☐ |
| 7 | Configure dashboard Python environment. | ☐ |
| 7 | Export monitoring and investigation snapshots. | ☐ |
| 7 | Review snapshots and manifest for public-release safety. | ☐ |
| 7 | Commit and push dashboard files and snapshots. | ☐ |
| 7 | Deploy and verify public Streamlit dashboard. | ☐ |

---

## 5. EXECUTION NOTES AND LIMITATIONS

### 5.1 Source data

The repository contains the frozen synthetic source dataset required for the standard deployment.

The standard execution sequence uses these supplied files directly.

The simulation generator is not required for a normal deployment. Regenerating the dataset is a separate operation and changes the source data on which the downstream warehouse and analytical outputs depend.

### 5.2 File paths

The Bronze full-load procedure and identity-resolution script contain hard-coded file paths.

These paths must be updated for the environment executing the project.

For `BULK INSERT`, the SQL Server service account must be able to access the specified files.

Changing a path in SSMS does not grant SQL Server access to that location.

### 5.3 Deployment versus execution

Some SQL scripts create database objects without loading data.

In particular:

- `bronze_full_load.sql` creates a stored procedure; `EXEC dbo.ocb_bronze_full_load` performs the Bronze load.
- `silver_transformations_final_load.sql` creates the Silver procedures and executes the full load and verification at the end.
- Gold, intelligence, monitoring and investigation scripts create reusable views, with the supervisory investigation script also executing embedded analytical queries.

Follow the execution sequence rather than assuming that executing a deployment script always performs a data load.

### 5.4 Dashboard snapshots

The public dashboard operates on packaged CSV snapshots.

Refreshing the public dashboard data requires:

1. Access to the authoritative OCB SQL Server database.
2. Successful execution of the snapshot exporter.
3. Review of the exported data.
4. Updating the committed dashboard snapshots.
5. Redeploying the public application.

The public Streamlit application does not connect directly to the private SQL Server database.

### 5.5 Analytical interpretation

OCB uses synthetic financial data and is intended as a financial intelligence and supervisory analytics sandbox.

Its monitoring and intelligence outputs identify patterns for examination. They do not independently establish fraud, intent, causality or regulatory non-compliance.

---

**OCB Platform v1.0.0**  
*Engineer financial truth. Transform events into intelligence.*