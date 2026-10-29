"""Run local SQL connectivity and dashboard-source checks for OCB."""
from __future__ import annotations

import os
import sys

os.environ["OCB_DATA_SOURCE"] = "sql"

from sql_data import _connect, load_sql_dataset, load_sql_query, VIEW_SOURCES, QUERY_SOURCES


def main() -> int:
    print("OCB SQL connection diagnostic")
    print(f"Server:   {os.getenv('OCB_SQL_SERVER', '.')}")
    print(f"Database: {os.getenv('OCB_SQL_DATABASE', 'ocb_platform')}")
    print(f"Auth:     {'Windows integrated' if os.getenv('OCB_SQL_TRUSTED_CONNECTION', 'true').lower() in {'1','true','yes'} else 'SQL login'}")
    try:
        conn = _connect()
        row = conn.cursor().execute("SELECT @@SERVERNAME, DB_NAME();").fetchone()
        print(f"Connected server: {row[0]}")
        print(f"Connected DB:     {row[1]}")
        if str(row[1]).lower() != "ocb_platform":
            print("WARNING: connected database is not named ocb_platform.")
    except Exception as exc:
        print("CONNECTION FAILED")
        print(f"{type(exc).__name__}: {exc}")
        print("Check the SQL Server service, ODBC driver, server name, database, and Windows/SQL authentication.")
        return 1

    names = list(VIEW_SOURCES) + [n for n in QUERY_SOURCES if n not in VIEW_SOURCES]
    # Avoid querying sika_flows twice: it deliberately reuses the institutional monitoring view.
    failures = 0
    print("\nDashboard source checks:")
    for name in names:
        try:
            df = load_sql_dataset(name)
            print(f"OK   {name}: {len(df):,} rows; columns={', '.join(df.columns)}")
        except Exception as exc:
            failures += 1
            print(f"FAIL {name}: {type(exc).__name__}: {exc}")
    print("\nInvestigation query checks (Q4 2024):")
    for name in ("cashin_to_outbound_remittance_event", "credit_to_outbound_remittance_event"):
        try:
            df = load_sql_query(name, ["2024-10-01", "2025-01-01"])
            print(f"OK   {name}: {len(df):,} event rows; columns={', '.join(df.columns)}")
        except Exception as exc:
            failures += 1
            print(f"FAIL {name}: {type(exc).__name__}: {exc}")
    print("\nRESULT:", "PASS" if failures == 0 else f"{failures} CHECK(S) FAILED")
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
