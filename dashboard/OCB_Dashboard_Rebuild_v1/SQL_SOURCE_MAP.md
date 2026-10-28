# OCB Dashboard — SQL Source Map

## Purpose

This map identifies the existing SQL sources to use for the dashboard. The prototype CSVs are not the source specification. SQL Server is the analytical source of truth; the dashboard's Python layer will retrieve result sets from existing views and, where appropriate, execute existing analytical query logic directly.

## 1. Institutional monitoring sources

### Ananse Telecom

| Dashboard requirement | Existing SQL source in `WP-6.1_ institutional_monitoring.sql` | Result grain / notes |
|---|---|---|
| Monthly successful activity | `dashboard.vw_ananse_monthly_activity` | One row per month. Includes all successful transaction types, including merchant payment. |
| Monthly successful activity by transaction type | `dashboard.vw_ananse_monthly_type_activity` | One row per month and transaction type. Includes merchant payment where present. |
| Monthly successful activity by channel | `dashboard.vw_ananse_monthly_channel_activity` | One row per month and channel. Includes merchant payment where present. |
| Monthly outcomes | `dashboard.vw_ananse_monthly_outcomes` | One row per month; outcomes cover all statuses. |
| Successful activity by region | Standalone query `-- 4. Transaction Region Activity` | One row per month and `transaction_region`; filters successful transactions and does not exclude merchant payment. |
| Successful activity by town | Standalone query `-- 5. Transaction Town Activity` | One row per month and `transaction_town`; filters successful transactions and does not exclude merchant payment. |
| Top 10 customers by successful transaction value | Standalone query `-- 10. Customer Activity Analysis: Top 10 by Successful Transaction Value` | One row per customer in the top 10; successful transactions, including merchant payment. The query uses full available history through the source data, not the dashboard's selected period. |
| Monthly outcomes by channel/type/customer, if needed | Standalone queries `-- 7`, `-- 8`, and `-- 9. Successful vs Failure vs Rejection rates` | Different grains; these can be used only if the corresponding dashboard interaction is needed. Customer outcome analysis explicitly excludes merchant payment. |
| FATF/transaction intelligence and customer signals | Existing intelligence views and WP-6.3 query blocks | Use only for an investigation or indicator that the dashboard actually presents. |

**Important definition difference:** `intelligence.vw_ananse_institutional_monitoring` and `intelligence.vw_ananse_customer_transaction_analysis` explicitly exclude `merchant payment`. The `dashboard.vw_ananse_monthly_activity`, `dashboard.vw_ananse_monthly_type_activity`, and `dashboard.vw_ananse_monthly_channel_activity` definitions do not exclude it. Do not substitute the older intelligence views for the dashboard activity views when the desired definition includes merchant payment.

### SikaCredit

| Dashboard requirement | Existing SQL source in `WP-6.1_ institutional_monitoring.sql` | Result grain / notes |
|---|---|---|
| Institutional lending, repayment, portfolio and post-maturity monitoring | `dashboard.vw_sikacredit_institutional_monitoring` | One row per reporting month; coverage is April 2023–December 2025. Do not imply January–March 2023 coverage. |
| Monthly loan activity | `dashboard.vw_sikacredit_monthly_loan_activity` | One row per month; includes disbursement activity and net/cumulative principal-flow measures as defined by the view. |
| Monthly repayment activity | `dashboard.vw_sikacredit_monthly_repayment_activity` | One row per month; use for repayment-specific breakdowns where needed. |
| Top borrowers by total principal | Standalone query `-- Top 10 borrowers by total principal` | Customer grain; query currently has `TOP 10` commented out, so it returns the full ranked customer result. Uses data before 2026-01-01. |
| Top borrowers by outstanding principal | Standalone query `-- Top 10 borrowers by total outstanding principal` | Top 10 customer rows with positive calculated outstanding principal; uses data before 2026-01-01. |
| Top borrowers by post-maturity outstanding debt | Standalone query `-- Top 10 borrowers by post-maturity outstanding debt` | Top 10 customer rows with positive post-maturity outstanding principal; uses data before 2026-01-01. |

### Oman Remit

| Dashboard requirement | Existing SQL source in `WP-6.1_ institutional_monitoring.sql` | Result grain / notes |
|---|---|---|
| Monthly successful activity | `dashboard.vw_oman_remit_monthly_activity` | One row per month. |
| Monthly successful activity by remittance type | `dashboard.vw_oman_remit_monthly_type_activity` | One row per month and remittance type. |
| Monthly successful activity by channel | `dashboard.vw_oman_remit_monthly_channel_activity` | One row per month and channel. |
| Monthly outcomes | `dashboard.vw_oman_remit_monthly_outcomes` | One row per month; outcome view includes all statuses. |
| Successful activity by origin country | Standalone query `-- 4. Remittance Origin Country Activity` | One row per month and origin country; successful remittances. |
| Successful activity by region | Standalone query `-- 6. Remittance Region Activity` | One row per month and location region; successful remittances. |
| Successful activity by town | Standalone query `-- 7. Remittance Town Activity` | One row per month and location town; successful remittances. |
| FATF origin-risk monitoring | `intelligence.vw_oman_remit_fatf_monitoring` | Reusable risk-monitoring view. Use its actual output contract for the relevant risk section. |
| Top 10 customers by successful remittance value | Standalone query `-- 9. Customer Activity Analysis: Top 10 by Successful Remittance Value` | One row per customer in the top 10; successful remittances, full available history through the query's source data. |

## 2. Supervisory investigation sources

Use the existing objects and analytical query blocks in `WP-6.3-supervisory_intelligence_investigations.sql`; do not export them to CSV as a prerequisite.

### Reusable intelligence views defined in WP-6.3

- `intelligence.vw_sikacredit_debt_recycling_customer_signals`
- `intelligence.vw_sikacredit_borrowing_surge`
- `intelligence.vw_sikacredit_credit_escalation_customer_signals`
- `intelligence.vw_ananse_customer_transaction_analysis`

### Existing investigation query groups

- SikaCredit November 2025 lending surge, debt recycling, borrowing composition, credit escalation, and loan-to-cash-out signals.
- Ananse December 2025 customer contribution to activity changes, TAE signals, cash-in-to-P2P-to-cash-out signals, transaction outcomes, and overnight activity.
- Oman Remit FATF-origin exposure and remittance-to-cash-out signals.
- Domestic cash-in → outbound remittance, using Q4 2024 as the primary investigation window.
- SikaCredit loan disbursement → outbound remittance, using Q4 2024 as the primary investigation window.
- Supplementary Q4 2025 credit → outbound remittance analysis.
- Inbound remittance → Ananse P2P redistribution signals.
- Inbound remittance → SikaCredit loan repayment signals for February 2025.

The dashboard exposes the two parameterised outbound-remittance event queries (`cashin_to_outbound_remittance_event.sql` and `credit_to_outbound_remittance_event.sql`) with a selectable reporting window. It also exposes the remaining WP-6.3 investigation questions using read-only query blocks copied into `sql_queries/`. Where the source defines both event-level and customer-level outputs, the dashboard provides them as separate evidence views. These queries rely on the existing WP-5 engine views and the reusable WP-6.3 views listed above; they do not create or alter database objects.

For event investigations, preserve the query's intended event grain and identifiers/timestamps. Customer-aggregated companion queries are separate result sets, not replacements for event-grain evidence. Use existing views where available and execute existing standalone queries for the other result sets. Do not create extra permanent views unless a specific dashboard requirement justifies one.

## 3. Integration rules

1. The dashboard queries SQL Server directly during local development.
2. Existing SQL definitions take precedence over old CSV exports if they differ.
3. The CSV prototype may be used for visual reference and comparison only.
4. Do not silently change a query's filters, event grain, reporting window, or metric definition to match an old export.
5. Keep all-history customer rankings distinct from period-filtered monthly charts unless a ranking query is deliberately parameterised to the selected period.
6. Do not add views or analyses merely to fill out the interface. Use the existing sources needed for the agreed dashboard.
7. For public deployment, any export-based data delivery is a separate deployment choice; it is not required for local SQL integration.

## 4. Next implementation step

The Python data-access layer reads named SQL views and executes registered query files against the configured OCB SQL Server database. The Supervisory Investigations page exposes the WP-6.3 investigation set, including separate event and customer-summary outputs where those are present in the source. SQL Server was not available for live validation in this package build; configure the user's local SQL connection and verify that the source WP-5/WP-6.3 views are deployed. Server/authentication details must be supplied through local environment configuration, never hard-coded into the project.
