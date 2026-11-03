# OCB PLATFORM v1.0.0

## REPOSITORY NAMING CONVENTIONS

### Official Document Definition

**Programme:** OCB Platform v1.0.0  
**Document:** Repository Naming Conventions  
**Component:** Repository structure, SQL files, database objects, tests, and diagrams  
**Purpose:** Establish consistent naming conventions across the OCB Platform repository.  
**Implementation Status:** Naming conventions defined; existing repository names require reconciliation.

---

## 1. Purpose

This document establishes consistent naming conventions for files, folders, and database objects within the OCB Platform repository.

The objective is to make project artefacts identifiable, understandable, and maintainable through descriptive and consistent names.

## 2. Governing Principles

All names should follow these principles:

- **Descriptive:** Names should communicate the purpose or contents of an artefact.
- **Consistent:** Similar artefacts should follow the same naming pattern.
- **Readable:** Names should be easy to understand and navigate.
- **Stable:** Names should not depend on an ordering system that requires constant maintenance.
- **Specific:** Different artefacts should have distinguishable names.
- **Practical:** Avoid unnecessary words, abbreviations, and duplicated information.

## 3. Folder Naming

Folder names should describe their contents or responsibility.

Use lowercase `snake_case` where practical. The following is the current OCB Platform repository structure, excluding Git's internal `.git/` directory and showing the folders that contain project artefacts:

```text
OCB_PLATFORM/
├── dashboard/
├── deprecated/
├── diagrams/
├── docs/
│   ├── glossary/
│   └── governance/
├── intelligence/
├── reports/
├── scripts/
│   ├── database/
│   └── testing/
├── simulation/
│   ├── control/
│   ├── documentation/
│   ├── reference/
│   └── source/
│       ├── ananse/
│       ├── oman_remit/
│       │   └── quarterly/
│       └── sikacredit/
│           └── quarterly/
└── warehouse/
```

This tree documents the repository's actual directory names and hierarchy. It is a structural reference, not a requirement to create additional folders. Update it when the repository structure changes.

## 4. File Naming

Use descriptive names that identify the file's purpose or contents.

Use lowercase `snake_case` for new file names wherever the file type and existing tooling permit it.

Use the appropriate file extension.

**Examples:**

- `project_summary.md`
- `customer_identity_resolution.sql`
- `transaction_anomaly_engine.sql`
- `supervisory_intelligence_questions.md`
- `institutional_monitoring.drawio`

Avoid vague names such as `file1.sql`, `new_script.sql`, or `final_updated.sql`.

## 5. SQL Files

SQL file names should identify the principal database component, operation, or analytical purpose.

Examples:

- `customer_identity_resolution.sql`
- `silver_table_deployment.sql`
- `gold_analytical_model.sql`
- `transaction_intelligence.sql`
- `financial_behaviour_analysis.sql`
- `cross_institution_analysis.sql`
- `sequence_anomaly_engine.sql`
- `institutional_monitoring.sql`
- `supervisory_intelligence_investigations.sql`

Where multiple files serve different purposes within the same area, distinguish them by function.

## 6. Database Object Naming

Database objects should have consistent names that communicate their function and align with the established OCB schema structure.

Relevant schemas include `bronze`, `silver`, `gold`, `intelligence`, and `dashboard`, where applicable.

General conventions:

- **Views:** `vw_<descriptive_subject>`
- **Stored procedures:** Descriptive names identifying the operation.
- **Tables:** Names identifying the represented entity or subject.
- **Functions:** Names identifying the operation or returned value.
- **Indexes and constraints:** Names identifying the relevant table and purpose.

Examples:

- `gold.vw_transaction`
- `intelligence.vw_cashin_remittance_rapidity_score`
- `dashboard.vw_ananse_monthly_activity`

Existing database conventions should remain consistent unless a change is justified.

## 7. Python Files and Scripts

Python file names should use lowercase `snake_case` and describe the script's purpose.

Examples:

- `simulation_generator.py`
- `export_monitoring_snapshots.py`
- `validate_source_data.py`
- `dashboard_app.py`

## 8. Test Files

Test file names should identify the component or behaviour being tested.

Examples:

- `test_customer_identity_resolution.py`
- `test_transaction_validation.py`
- `test_sequence_anomaly_engine.py`

Test files should also comply with the naming requirements of the testing framework in use.

## 9. Diagram Naming

Diagram names should describe the architecture, relationship, process, or component represented.

Examples:

- `platform_architecture.drawio`
- `database_relationships.drawio`
- `customer_identity_resolution.drawio`
- `financial_data_flow.drawio`
- `supervisory_monitoring_architecture.drawio`

Where editable source files and exported diagrams are both retained, their names should make the relationship clear.

For example:

- `platform_architecture.drawio`
- `platform_architecture.png`

## 10. Documentation Naming

Documentation file names should identify the document's subject or purpose.

Examples:

- `project_summary.md`
- `project_control_document.md`
- `repository_naming_conventions.md`
- `business_glossary.md`
- `supervisory_intelligence_questions.md`
- `database_architecture.md`
- `customer_identity_resolution.md`
- `release_notes.md`

Document titles may use normal title capitalization even when their file names use lowercase `snake_case`.

## 11. Reconciliation and Acceptance

Existing file and object names should be reviewed for consistency with these conventions.

During reconciliation, classify artefacts as:

- **Retain:** The name is clear and consistent.
- **Rename:** The name is unclear, misleading, or inconsistent.
- **Reconcile:** The name, contents, or references require alignment.
- **Archive:** The artefact is obsolete but should be preserved.
- **Remove:** The artefact is unnecessary and its removal has been authorized.

Before renaming an artefact, check for references in other files, scripts, configurations, and documentation.

Existing artefacts should not be renamed indiscriminately.

## 12. Governing Principle

Repository names should be descriptive, consistent, and easy to maintain.

The naming convention exists to improve navigation and maintainability, not to introduce unnecessary administrative work.