# Repository and Naming Conventions

## Purpose

This document establishes the baseline naming conventions for OCB Platform v1.0.0. Names should be descriptive, consistent, and communicate the business or technical purpose of the artefact.

## General Principles

- Use descriptive names that communicate purpose.
- Use lowercase `snake_case` for repository files, SQL objects, and database identifiers unless a specific technology requires otherwise.
- Avoid ambiguous or meaningless names such as `tbl1`, `temp2`, or `data_final_new`.
- Prefer business meaning over implementation-specific abbreviations.
- Do not introduce naming conventions merely for the sake of convention.

## Repository Files and Folders

Use lowercase `snake_case` for files and directories.

Examples:

- `repository_naming_conventions.md`
- `data_engineering/`
- `sample_data/`

## Database Objects

Use lowercase `snake_case` and descriptive business names.

Examples:

- `customers`
- `transactions`
- `loan_repayments`
- `risk_assessments`

## Columns

Use lowercase `snake_case`.

Primary and foreign key columns should normally use the referenced entity name followed by `_id`.

Examples:

- `customer_id`
- `transaction_id`
- `loan_id`

## Views

Use descriptive names that communicate the analytical or business purpose of the view.

Example:

- `customer_transaction_summary`

## Stored Procedures

Use descriptive names that communicate the operation or purpose.

Example:

- `process_transaction`

## Functions

Use descriptive names that communicate the calculation or purpose.

Example:

- `calculate_risk_score`

## Indexes

Use a consistent descriptive structure identifying the indexed object and relevant column or purpose.

Example:

- `ix_transactions_customer_id`

## Constraints

Use descriptive names identifying the constraint type and affected object.

Examples:

- `pk_customers`
- `fk_transactions_customer`
- `uq_customers_account_number`

## Tests

Use descriptive names that communicate what behaviour or rule is being tested.

Example:

- `test_transaction_ordering`

## Diagrams

Use lowercase `snake_case` and identify the subject represented.

Examples:

- `financial_core_erd`
- `platform_architecture`

## Implementation-Specific Conventions

Additional conventions may be established when actual implementation introduces requirements that cannot reasonably be determined during the foundation phase. Such conventions must remain consistent with the project's architectural and governance standards.