# OCB Financial Intelligence Dashboard

An interactive financial supervisory dashboard for the Osagyefo Central Bank regulatory sandbox. It brings institutional monitoring and event-level supervisory investigations into one local Streamlit application.

The dashboard is an analytical aid. Its signals support review; they do not establish wrongdoing, make regulatory findings, or replace an investigator's judgment.

## Dashboard sections

- **System overview** — separate summaries for Ananse Telecom, SikaCredit, and Oman Remit. Institutional values remain separate and are not added into a misleading system-wide financial total.
- **Ananse Telecom** — successful transaction activity, channels, transaction types, locations, customer rankings, and transaction outcomes.
- **SikaCredit** — loan disbursement and repayment, outstanding principal, post-maturity exposure, and borrower rankings.
- **Oman Remit** — successful remittance activity, channels, origin countries, remittance types, customer rankings, and outcomes.
- **Supervisory investigations** — twelve investigation questions with trigger context, reporting-window controls, signal explanations, and SQL-backed evidence views.

## Package contents

- `app.py` — dashboard layout and interactive pages.
- `assets/ocb_emblem.svg` — the dashboard's scalable OCB emblem used in the top banner.
- `sql_data.py` — SQL Server connection and data loading.
- `sql_queries/` — the read-only dashboard and supervisory queries used by the app.
- `data/` — supplied CSV snapshots for offline prototype use.
- `run_dashboard_sql.bat` — Windows launcher for SQL Server mode.
- `run_dashboard_csv.bat` — Windows launcher for CSV prototype mode.
- `requirements.txt` — Python dependencies.
- `SQL_SOURCE_MAP.md` — map of dashboard sections to existing SQL sources.

## Run locally on Windows — SQL Server mode

### Requirements

- Windows 10 or 11.
- Python 3.11 or newer and the Python Launcher (`py`).
- Microsoft ODBC Driver 18 for SQL Server.
- Access to the OCB SQL Server database and permission to read the dashboard and intelligence views.
- A network connection the first time you run the launcher, so it can install Python packages.

The database objects must already be installed. This package does not create SQL Server tables, views, or WP-5/WP-6 intelligence engines.

### Start the dashboard

1. Download and extract the ZIP. Keep the `OCB_Dashboard_Rebuild_v1` folder and all of its contents together.
2. Open that folder and double-click `run_dashboard_sql.bat`.
3. On the first run, the launcher creates a local `.venv`, installs the packages in `requirements.txt`, and starts Streamlit. Later starts reuse the same environment.
4. Open [http://localhost:8502](http://localhost:8502) if it does not open automatically.
5. To stop the dashboard, return to the command window and press **Ctrl+C**. Closing the browser tab alone does not stop the local server.

The SQL launcher uses these defaults:

| Setting | Default |
|---|---|
| Data source | SQL Server |
| SQL Server instance | `.` (the local default instance) |
| Database | `ocb_platform` |
| Authentication | Windows trusted connection |
| Local dashboard address | `http://localhost:8502` |

If your server uses a named instance, open `run_dashboard_sql.bat` in a text editor and change `OCB_SQL_SERVER`. For example, use `.` for the default local instance or `localhost\SQLEXPRESS` for a local SQL Express instance. Update `OCB_SQL_DATABASE` if your database has a different name. Save the file and run it again.

Windows authentication uses the Windows account that starts the batch file. That account needs permission to read the required database objects. Do not put a database password into `app.py` or share a batch file containing credentials.

### Required SQL sources

The connected database must contain the existing monitoring views described in `SQL_SOURCE_MAP.md`, the Oman FATF monitoring view, and the WP-6.3 supervisory investigation views and source objects. Their WP-5.3 intelligence dependencies must also be deployed. The dashboard runs investigation queries directly; it does not install or alter database objects.

If an investigation page reports that a SQL object is missing, ask the database administrator to check the deployment of the source WP-5.3 engines, WP-6.1 monitoring views, and WP-6.3 supervisory investigation views for this database.

## Run locally in CSV prototype mode

CSV mode is the mode used by the public deployment. It reads committed snapshots and does not require a recruiter to connect to SQL Server. The package must contain all monitoring CSVs and `data/investigations/*.csv`; otherwise the app reports the exact missing snapshot rather than silently substituting an empty chart.

To refresh the public snapshot from the authoritative OCB database, run the following locally after confirming SQL Server access and configuring `OCB_DATA_SOURCE=sql` and the `OCB_SQL_*` environment variables:

```bat
.venv\\Scripts\\python.exe export_public_snapshots.py
```

The exporter executes the dashboard's existing monitoring views and registered WP-6.3 investigation SQL files. It fails if a source query cannot run; it does not fabricate investigation results. Review every exported investigation CSV for sensitive or identifying fields before committing the files to the public repository. Then commit the generated `data/` files and `data_manifest.json`, and redeploy. The public app reads those snapshots without requiring the database connection.

1. Open a terminal in the `OCB_Dashboard_Rebuild_v1` folder.
2. If this is the first run, create the Python environment and install the dependencies:

   ```bat
   py -3 -m venv .venv
   .venv\Scripts\python.exe -m pip install --upgrade pip
   .venv\Scripts\python.exe -m pip install -r requirements.txt
   ```

3. Double-click `run_dashboard_csv.bat` or run it from the terminal.
4. Open [http://localhost:8502](http://localhost:8502).

The CSV launcher sets `OCB_DATA_SOURCE=csv`. In this mode, the investigation page explains that its live SQL evidence is unavailable. Use the SQL launcher when you need investigation results.

## Run on macOS or Linux

The supplied `.bat` launchers are for Windows. On another operating system, install Python 3.11 or newer and use a terminal in the extracted package folder.

For CSV prototype mode:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
OCB_DATA_SOURCE=csv .venv/bin/python -m streamlit run app.py --server.port 8502
```

For SQL mode, first install the Microsoft SQL Server ODBC driver for your operating system and configure SQL Server access. Then set `OCB_DATA_SOURCE=sql`, `OCB_SQL_SERVER`, `OCB_SQL_DATABASE`, and the authentication variables in your shell before running Streamlit. Windows trusted authentication may not be available on other operating systems; follow your organization's SQL authentication policy and do not save passwords in the project files.

## Use the dashboard

- Choose a dashboard section from **View** in the left panel.
- Set the shared reporting period in the left panel to filter monthly monitoring charts.
- On **Supervisory investigations**, choose a question in the highlighted workbench, then select a reporting window. Where a question has multiple evidence outputs, use **Evidence view** to switch between them.
- The investigation window filters event results. Monthly trigger charts show monthly activity and highlight the months touched by the selected window.
- Investigation results return qualifying rows from the source query without a top-50 cutoff.

## Troubleshooting

| What you see | What to check |
|---|---|
| The dashboard cannot connect to SQL Server | Confirm that SQL Server is running, the instance and database names in `run_dashboard_sql.bat` are correct, and your Windows account can connect. |
| Driver or ODBC error | Install Microsoft ODBC Driver 18 for SQL Server, then restart the launcher. |
| Login or permission error | Ask the database administrator to grant your account read access to the required views and source objects. |
| Missing SQL view or object | Confirm that the OCB monitoring and WP-5.3/WP-6.3 intelligence objects are deployed in the selected database. |
| Package installation fails | Check your internet connection and rerun the launcher. Package installation is needed only when setting up or refreshing `.venv`. |
| Port 8502 is already in use | Close the other local Streamlit session using that port, then try again. |
| Missing chart or investigation snapshot | Run `export_public_snapshots.py` against the configured OCB SQL Server, confirm the required CSV appears under `data/` or `data/investigations/`, review it for public-release safety, then commit and redeploy. |

## Data and operating notes

- SQL Server is the source of truth in SQL mode. The supplied CSV files are prototype snapshots and may not match current database values.
- The shared reporting-period control applies to monthly activity. Some customer ranking tables use all-history source queries and are not recalculated for that period.
- Supervisory investigation outputs use their source-defined event or customer-summary grain. The reporting window filters events; it does not recalculate the source intelligence scores.
- The package contains no database, database credentials, or SQL Server deployment script.
- Treat data according to your organization's access and confidentiality rules. Do not expose internal or identifiable data through a public dashboard.

