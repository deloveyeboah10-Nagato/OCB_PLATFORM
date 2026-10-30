# OCB Dashboard — Reporting Window Repair

## What changed

All eight investigation outputs that previously could not be filtered correctly in CSV mode now have an explicit reporting grain:

| Investigation output | Reporting grain |
|---|---|
| `remittance_to_p2p_summary` | Customer-month (`year_month`) |
| `sika_recycling_cashout_overlap` | Customer-month (`year_month`) |
| `remittance_to_repayment_summary` | Customer-month (`year_month`) |
| `sika_borrowing_surge` | Loan disbursement event (`disbursement_timestamp`) |
| `ananse_failed_rejected_customers` | Customer-month (`year_month`) |
| `ananse_overnight_events` | Overnight event (`overnight_date`) |
| `ananse_overnight_summary` | Customer-month (`year_month`) |
| `oman_fatf_customers` | Customer-month (`year_month`) |

The overnight-event query now joins transaction-outcome context by customer **and calendar month**. Filtering an overnight event snapshot therefore does not carry a customer's full-horizon failed/rejected totals into a narrower selected period.

The dashboard applies timestamp windows as `[start, end-exclusive)` and month-grain windows to every calendar month touched by the selected dates. It continues to fail closed if a CSV is missing its configured date field; it will not show unfiltered history under a custom-window label.

## One required local step: regenerate the CSV snapshots

The five affected packaged CSVs still contain their old schemas because this environment cannot connect to the user's local OCB SQL Server. The SQL/Python repair is ready, but the dashboard package is **not yet ready for use** until the snapshots are regenerated.

1. Extract this ZIP to a new folder; do not overwrite the working dashboard yet.
2. Open PowerShell in that extracted `dashboard` folder.
3. Activate the same Python virtual environment used for the dashboard.
4. Set the existing SQL connection environment variables and select SQL mode:

   ```powershell
   $env:OCB_DATA_SOURCE = "sql"
   ```

   Keep the existing `OCB_SQL_SERVER`, `OCB_SQL_DATABASE`, `OCB_SQL_DRIVER`, and authentication configuration you already use. Do not put passwords in this file or in Git.

5. Run the export:

   ```powershell
   python export_public_snapshots.py
   ```

   The script exports the monitoring data and all registered investigation snapshots. It now validates the required date columns and customer-month uniqueness for the repaired outputs and stops with a clear error if a query does not produce the expected grain.

6. After a successful export, run:

   ```powershell
   python -m unittest discover -s tests -v
   ```

7. Launch the dashboard in CSV mode and test at least two different date windows against the affected investigation outputs. Only then replace the current working dashboard with this folder.

## Validation performed here

- 14 automated tests passed.
- `app.py`, `sql_data.py`, and `export_public_snapshots.py` compile successfully.
- SQL Server execution was not possible in this environment. The local export is the remaining integration check; it must complete successfully before this build is treated as production-ready.
