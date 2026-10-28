"""SQL Server data access for the OCB dashboard.

This SQL-integrated package defaults to SQL Server. Set OCB_DATA_SOURCE=csv
explicitly only when you intentionally want the prototype snapshots. Connection details are read only from environment variables.
"""
from __future__ import annotations

import os
from pathlib import Path
from functools import lru_cache

import pandas as pd

ROOT = Path(__file__).resolve().parent
QUERY_DIR = ROOT / "sql_queries"

# Dashboard datasets backed by the existing WP-6.1 dashboard views or the
# standalone analytical query blocks saved as query files from WP-6.1.
VIEW_SOURCES = {
    "ananse_monthly": "dashboard.vw_ananse_monthly_activity",
    "ananse_channel": "dashboard.vw_ananse_monthly_channel_activity",
    "ananse_type": "dashboard.vw_ananse_monthly_type_activity",
    "ananse_outcomes": "dashboard.vw_ananse_monthly_outcomes",
    "sika_monthly": "dashboard.vw_sikacredit_institutional_monitoring",
    "sika_loan_activity": "dashboard.vw_sikacredit_monthly_loan_activity",
    "sika_repayment_activity": "dashboard.vw_sikacredit_monthly_repayment_activity",
    "sika_flows": "dashboard.vw_sikacredit_monthly_loan_activity",
    "oman_monthly": "dashboard.vw_oman_remit_monthly_activity",
    "oman_channel": "dashboard.vw_oman_remit_monthly_channel_activity",
    "oman_type": "dashboard.vw_oman_remit_monthly_type_activity",
    "oman_outcomes": "dashboard.vw_oman_remit_monthly_outcomes",
}
QUERY_SOURCES = {
    "ananse_region": "ananse_region.sql",
    "ananse_town": "ananse_town.sql",
    "ananse_top10": "ananse_top10.sql",
    "sika_top_post_maturity": "sika_top_post_maturity.sql",
    "sika_top_outstanding": "sika_top_outstanding.sql",
    "oman_origin_country": "oman_origin_country.sql",
    "oman_town": "oman_town.sql",
    "oman_region": "oman_region.sql",
    "oman_top10": "oman_top10.sql",
    "oman_outbound_monthly_trigger": "oman_outbound_monthly_trigger.sql",
    "oman_fatf_monthly_trigger": "oman_fatf_monthly_trigger.sql",
}
INVESTIGATION_QUERIES = {
    "cashin_to_outbound_remittance_event": "cashin_to_outbound_remittance_event.sql",
    "credit_to_outbound_remittance_event": "credit_to_outbound_remittance_event.sql",
    "sika_debt_recycling": "sika_debt_recycling.sql",
    "sika_borrowing_surge": "sika_borrowing_surge.sql",
    "sika_credit_escalation": "sika_credit_escalation.sql",
    "ananse_surge_contributors": "ananse_surge_contributors.sql",
    "ananse_surge_tae": "ananse_surge_tae.sql",
    "ananse_cip2pco_events": "ananse_cip2pco_events.sql",
    "ananse_cip2pco_summary": "ananse_cip2pco_summary.sql",
    "ananse_failed_rejected_customers": "ananse_failed_rejected_customers.sql",
    "ananse_overnight_events": "ananse_overnight_events.sql",
    "ananse_overnight_summary": "ananse_overnight_summary.sql",
    "oman_fatf_customers": "oman_fatf_customers.sql",
    "sika_lending_surge_contributors": "sika_lending_surge_contributors.sql",
    "sika_loan_cashout_events": "sika_loan_cashout_events.sql",
    "sika_loan_cashout_summary": "sika_loan_cashout_summary.sql",
    "sika_recycling_cashout_overlap": "sika_recycling_cashout_overlap.sql",
    "oman_fatf_remittance_cashout": "oman_fatf_remittance_cashout.sql",
    "oman_fatf_cashout_tae": "oman_fatf_cashout_tae.sql",
    "cashin_to_outbound_q4_2024_summary": "cashin_to_outbound_q4_2024_summary.sql",
    "credit_to_outbound_q4_2024_summary": "credit_to_outbound_q4_2024_summary.sql",
    "credit_to_outbound_q4_2025_events": "credit_to_outbound_q4_2025_events.sql",
    "credit_to_outbound_q4_2025_summary": "credit_to_outbound_q4_2025_summary.sql",
    "remittance_to_p2p_events": "remittance_to_p2p_events.sql",
    "remittance_to_p2p_summary": "remittance_to_p2p_summary.sql",
    "remittance_to_repayment_events": "remittance_to_repayment_events.sql",
    "remittance_to_repayment_summary": "remittance_to_repayment_summary.sql",
}


def sql_mode() -> bool:
    return os.getenv("OCB_DATA_SOURCE", "sql").strip().lower() == "sql"


@lru_cache(maxsize=1)
def _connection_string() -> str:
    driver = os.getenv("OCB_SQL_DRIVER", "ODBC Driver 18 for SQL Server")
    server = os.getenv("OCB_SQL_SERVER", ".").strip()
    database = os.getenv("OCB_SQL_DATABASE", "ocb_platform").strip()
    if not server:
        raise RuntimeError(
            "OCB_DATA_SOURCE is 'sql' but OCB_SQL_SERVER is not set. "
            "Set OCB_SQL_SERVER in your local environment before launching the dashboard."
        )
    trusted = os.getenv("OCB_SQL_TRUSTED_CONNECTION", "true").strip().lower() in {"1", "true", "yes"}
    parts = [f"DRIVER={{{driver}}}", f"SERVER={server}", f"DATABASE={database}", "TrustServerCertificate=yes"]
    if trusted:
        parts.append("Trusted_Connection=yes")
    else:
        username = os.getenv("OCB_SQL_USERNAME", "").strip()
        password = os.getenv("OCB_SQL_PASSWORD", "")
        if not username or not password:
            raise RuntimeError(
                "SQL authentication is selected but OCB_SQL_USERNAME and OCB_SQL_PASSWORD are not both set."
            )
        parts.extend([f"UID={username}", f"PWD={password}"])
    return ";".join(parts) + ";"


@lru_cache(maxsize=1)
def _connect():
    try:
        import pyodbc
    except ImportError as exc:
        raise RuntimeError(
            "SQL mode requires pyodbc. Install the dashboard requirements and ensure a SQL Server ODBC driver is installed."
        ) from exc
    return pyodbc.connect(_connection_string(), timeout=10)


def _read_query(sql: str) -> pd.DataFrame:
    connection = _connect()
    return pd.read_sql_query(sql, connection)


def load_sql_query(name: str, params: list | tuple = ()) -> pd.DataFrame:
    """Execute a registered, parameterised analytical query against SQL Server."""
    if name not in INVESTIGATION_QUERIES:
        raise KeyError(f"No SQL investigation query registered for '{name}'.")
    path = QUERY_DIR / INVESTIGATION_QUERIES[name]
    if not path.exists():
        raise RuntimeError(f"SQL investigation query file is missing: {path.name}")
    sql = path.read_text(encoding="utf-8")
    if "{START_DATE}" in sql or "{START_MONTH}" in sql:
        if len(params) != 2:
            raise ValueError(f"Investigation query '{name}' requires start and end-exclusive dates.")
        start = pd.Timestamp(params[0]).date()
        end_exclusive = pd.Timestamp(params[1]).date()
        if start >= end_exclusive:
            raise ValueError("Investigation window must end after it starts.")
        end_inclusive = end_exclusive - pd.Timedelta(days=1)
        sql = (sql
               .replace("{START_DATE}", start.isoformat())
               .replace("{END_EXCLUSIVE}", end_exclusive.isoformat())
               .replace("{START_MONTH}", start.strftime("%Y-%m"))
               .replace("{END_MONTH}", end_inclusive.strftime("%Y-%m")))
        if "{START_DATE}" in sql or "{END_EXCLUSIVE}" in sql or "{START_MONTH}" in sql or "{END_MONTH}" in sql:
            raise ValueError(f"Investigation query '{name}' has an unresolved date token.")
        return pd.read_sql_query(sql, _connect())
    # Several source investigation views are intentionally all-history cohort
    # rankings and do not accept a reporting-period parameter. Pass bind values
    # only when the registered SQL actually contains DB-API placeholders.
    if params and "?" not in sql:
        return pd.read_sql_query(sql, _connect())
    return pd.read_sql_query(sql, _connect(), params=list(params))


def load_sql_dataset(name: str) -> pd.DataFrame:
    """Fetch one registered dashboard dataset from SQL Server."""
    if name == "sika_flows":
        # The institutional monitoring view is the source for monthly disbursement,
        # repayment and net flow. The separate monthly-loan view does not expose
        # those same columns, so do not query it for the prototype's flow chart.
        df = _read_query("SELECT * FROM dashboard.vw_sikacredit_institutional_monitoring;")
        df = df[["year_month", "principal_disbursed", "principal_repaid", "net_principal_flow"]].copy()
        df = df.sort_values("year_month")
        df["cumulative_net_principal_flow"] = df["net_principal_flow"].cumsum()
    elif name in VIEW_SOURCES:
        source = VIEW_SOURCES[name]
        # Source identifiers are hard-coded in this registry, not user input.
        df = _read_query(f"SELECT * FROM {source};")
    elif name in QUERY_SOURCES:
        path = QUERY_DIR / QUERY_SOURCES[name]
        if not path.exists():
            raise RuntimeError(f"SQL query file is missing: {path.name}")
        df = _read_query(path.read_text(encoding="utf-8"))
    else:
        raise KeyError(f"No SQL source registered for dashboard dataset '{name}'.")

    # The existing dashboard expects these field names. Normalize only known
    # naming differences; do not alter SQL metric definitions or filters.
    rename = {
        "successful_rate": "successful_rate_pct" if name == "oman_outcomes" else "successful_rate",
        "failure_rate": "failure_rate_pct" if name == "oman_outcomes" else "failure_rate",
        "rejection_rate": "rejection_rate_pct" if name == "oman_outcomes" else "rejection_rate",
        "overall_unsuccessful_rate": "overall_unsuccessful_rate_pct" if name == "oman_outcomes" else "overall_unsuccessful_rate",
    }
    if name == "oman_outcomes":
        df = df.rename(columns={k: v for k, v in rename.items() if k in df.columns and v not in df.columns})

    # The repayment view uses repayment-specific names rather than the
    # principal_repaid names used by the institutional monitoring view.
    if name == "sika_loan_activity":
        aliases = {
            "loans_disbursed_count": "principal_disbursed_count",
            "total_principal_value": "principal_disbursed",
            "principal_disbursed_value": "principal_disbursed",
        }
        df = df.rename(columns={src: dst for src, dst in aliases.items()
                                if src in df.columns and dst not in df.columns})

    if name == "sika_repayment_activity":
        aliases = {
            "repayment_transaction_count": "principal_repaid_count",
            "repayment_count": "principal_repaid_count",
            "repayment_amount_value": "principal_repaid",
            "total_repayment_amount": "principal_repaid",
            "principal_repayment_amount": "principal_repaid",
        }
        df = df.rename(columns={src: dst for src, dst in aliases.items()
                                if src in df.columns and dst not in df.columns})

    if "year_month" in df.columns:
        df["year_month"] = df["year_month"].astype(str).str.slice(0, 7)
        df["month_date"] = pd.to_datetime(df["year_month"] + "-01", errors="coerce")
    return df
