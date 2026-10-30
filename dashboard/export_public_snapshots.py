"""Export the complete public OCB dashboard snapshot from the authoritative SQL Server.

Run locally with OCB_DATA_SOURCE=sql configured. This script does not invent data:
it executes the dashboard's existing SQL views and investigation query files, then
writes their results to data/*.csv and data/investigations/*.csv.
"""
from __future__ import annotations
import json
from pathlib import Path
import pandas as pd
from sql_data import VIEW_SOURCES, QUERY_SOURCES, INVESTIGATION_QUERIES, load_sql_dataset, load_sql_query

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
INVESTIGATIONS = DATA / "investigations"
START_DATE = "2023-01-01"
END_EXCLUSIVE = "2026-01-01"

def main():
    DATA.mkdir(parents=True, exist_ok=True)
    INVESTIGATIONS.mkdir(parents=True, exist_ok=True)
    manifest = {
        "source": "Existing OCB SQL Server monitoring views and WP-6.3 investigation queries",
        "period": {"start_inclusive": START_DATE, "end_exclusive": END_EXCLUSIVE},
        "generated_at_utc": pd.Timestamp.now(tz="UTC").isoformat(),
        "monitoring": {},
        "investigations": {},
        "note": "Snapshots are query results, not live SQL. Review privacy before publishing publicly."
    }

    # All registered monitoring datasets, including Ananse type/town and Sika
    # loan/repayment activity. A failure stops the export rather than silently
    # publishing a dashboard with missing charts.
    for name in sorted(set(VIEW_SOURCES) | set(QUERY_SOURCES)):
        frame = load_sql_dataset(name)
        path = DATA / f"{name}.csv"
        frame.to_csv(path, index=False)
        manifest["monitoring"][name] = {
            "file": f"data/{name}.csv", "rows": len(frame), "columns": list(frame.columns)
        }
        print(f"{name}: {len(frame):,} rows")

    # Export the same registered investigation queries used by the dashboard.
    # Queries with date tokens receive the complete OCB monitoring horizon.
    for name in INVESTIGATION_QUERIES:
        path_sql = ROOT / "sql_queries" / INVESTIGATION_QUERIES[name]
        sql = path_sql.read_text(encoding="utf-8")
        params = [START_DATE, END_EXCLUSIVE] if (
    any(token in sql for token in (
        "{START_DATE}", "{START_MONTH}", "{END_EXCLUSIVE}", "{END_MONTH}"))
    or "?" in sql) else []
        print(f"Running investigation query: {name}")
        frame = load_sql_query(name, params)
        path = INVESTIGATIONS / f"{name}.csv"
        frame.to_csv(path, index=False)
        manifest["investigations"][name] = {
            "file": f"data/investigations/{name}.csv",
            "rows": len(frame), "columns": list(frame.columns),
        }
        print(f"investigation {name}: {len(frame):,} rows")

    (ROOT / "data_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"\nExport complete: {len(manifest['monitoring'])} monitoring datasets and "
          f"{len(manifest['investigations'])} investigation snapshots.")
    print("Next: inspect data/investigations for sensitive fields before committing to a public repository.")

if __name__ == "__main__":
    main()
