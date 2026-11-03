# OCB PLATFORM v1.0.0

##  DIMENSIONAL MODEL

### Official Work Package Definition

- **Programme:** Gold Analytical Model
- **Component:** Fact Tables, Dimensions and Conceptual Dimensional Architecture
- **Purpose:** Define the analytical facts, dimensions, grains and relationships supporting OCB's institutional and cross-domain intelligence workloads.
- **Implementation Status:** Logical model validated; physical implementation pending.

### 1. Fact Tables

| Fact Table | Institution | Grain | Analytical Focus |
|---|---|---|---|
| `FACT_TRANSACTION` | Ananse Telecom | One row per transaction | Transaction activity, value, type and channel |
| `FACT_LOAN` | SikaCredit | One row per loan | Loan origination, disbursement and loan-level analysis |
| `FACT_REPAYMENT` | SikaCredit | One row per repayment | Repayment activity, amounts and repayment behaviour |
| `FACT_REMITTANCE` | Oman Remit | One row per remittance | Remittance activity, value, channel and origin |

The four facts remain separate because each represents a distinct business process and grain. `FACT_REPAYMENT` retains `loan_id` as a reference to its associated loan.

### 2. Dimensions

**Conformed dimensions**

- `DIM_CUSTOMER` — identifies customers using the canonical `ocb_customer_id`.
- `DIM_TIME` — supports consistent time-based analysis across institutions.
- `DIM_INSTITUTION` — identifies the institution associated with an analytical record.
- `DIM_GEOGRAPHY` — supports geographical analysis of relevant events and activities.

**Process-specific dimensions and attributes**

- `DIM_CHANNEL` — supports channel analysis for transactions and remittances.
- `DIM_TRANSACTION_TYPE` — classifies Ananse Telecom transaction types.
- `DIM_COUNTRY` — identifies the country of origin for Oman Remit remittances.
- `remittance_type` — remains an attribute of the remittance fact.

### 3. Conceptual Dimensional Architecture

The model connects the four fact tables to applicable shared and process-specific dimensions while preserving each fact's grain.

- Customer-level analysis uses `ocb_customer_id` as the canonical customer key.
- `cross_domain_id` remains synthetic identity ground truth, not the canonical analytical customer key.
- Geography represents the location associated with an event; it must not automatically be interpreted as customer residence.
- Shared dimensions must retain consistent meanings across the facts that use them.
- Relationships between facts must not introduce duplication or distort measures.

### 4. Outcome

The conceptual model establishes four distinct institutional facts, shared conformed dimensions and process-specific analytical dimensions. No confirmed structural conflict was identified in the reviewed diagrams.