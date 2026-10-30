import ast
import unittest
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app.py"
TREE = ast.parse(APP.read_text(encoding="utf-8"))


def assigned_literal(name):
    for node in TREE.body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == name for t in node.targets):
            return ast.literal_eval(node.value)
    raise AssertionError(f"Missing {name}")


class ReportingWindowMetadataTests(unittest.TestCase):
    def test_every_referenced_investigation_snapshot_has_a_date_policy(self):
        date_fields = assigned_literal("INVESTIGATION_DATE_FIELDS")
        referenced = set()
        for node in ast.walk(TREE):
            if isinstance(node, ast.Dict):
                for value in node.values:
                    if isinstance(value, ast.Constant) and isinstance(value.value, str):
                        if (ROOT / "data" / "investigations" / f"{value.value}.csv").exists():
                            referenced.add(value.value)
        self.assertFalse(referenced - set(date_fields), sorted(referenced - set(date_fields)))

    def test_newly_repaired_queries_select_their_reporting_grain(self):
        expected = {
            "sika_borrowing_surge": "disbursement_timestamp",
            "ananse_failed_rejected_customers": "year_month",
            "ananse_overnight_events": "overnight_date",
            "ananse_overnight_summary": "year_month",
            "oman_fatf_customers": "year_month",
        }
        for name, column in expected.items():
            sql = (ROOT / "sql_queries" / f"{name}.sql").read_text(encoding="utf-8").lower()
            self.assertIn(column.lower(), sql, name)
            self.assertEqual(assigned_literal("INVESTIGATION_DATE_FIELDS")[name][0], column)

    def test_overnight_event_outcome_context_is_month_aligned(self):
        sql = (ROOT / "sql_queries" / "ananse_overnight_events.sql").read_text(encoding="utf-8").lower()
        self.assertIn("group by ocb_customer_id, convert(char(7), transaction_timestamp, 120)", sql)
        self.assertIn("and o.year_month = t.year_month", sql)

    def test_multi_event_outputs_use_declared_reporting_event(self):
        rules = assigned_literal("INVESTIGATION_DATE_FIELDS")
        self.assertEqual(rules["cashin_to_outbound_remittance_event"][0], "remittance_timestamp")
        self.assertEqual(rules["credit_to_outbound_remittance_event"][0], "remittance_timestamp")
        self.assertEqual(rules["sika_loan_cashout_events"][0], "disbursement_timestamp")
        self.assertEqual(rules["oman_fatf_remittance_cashout"][0], "remittance_timestamp")
        self.assertEqual(rules["remittance_to_repayment_events"][0], "repayment_timestamp")

    def test_rebuilt_customer_summaries_preserve_month_grain(self):
        rules = assigned_literal("INVESTIGATION_DATE_FIELDS")
        for name in (
            "remittance_to_p2p_summary",
            "sika_recycling_cashout_overlap",
            "remittance_to_repayment_summary",
        ):
            self.assertEqual(rules[name], ("year_month", "month"), name)
            path = ROOT / "data" / "investigations" / f"{name}.csv"
            frame = pd.read_csv(path)
            self.assertIn("year_month", frame.columns, name)
            self.assertTrue(frame["year_month"].astype(str).str.match(r"^\d{4}-\d{2}$").all(), name)
            self.assertFalse(frame.duplicated(["ocb_customer_id", "year_month"]).any(), name)

    def test_monthly_summary_queries_return_the_reporting_month(self):
        for name in ("remittance_to_p2p_summary", "sika_recycling_cashout_overlap", "remittance_to_repayment_summary"):
            sql = (ROOT / "sql_queries" / f"{name}.sql").read_text(encoding="utf-8")
            self.assertIn("year_month", sql, name)

    def test_missing_snapshot_grain_fails_closed_until_regenerated(self):
        source = APP.read_text(encoding="utf-8")
        self.assertIn("missing its configured reporting date column", source)
        self.assertIn("no unfiltered rows were returned", source)
        rules = assigned_literal("INVESTIGATION_DATE_FIELDS")
        for name in ("sika_borrowing_surge", "ananse_failed_rejected_customers", "ananse_overnight_events", "ananse_overnight_summary", "oman_fatf_customers"):
            self.assertIn(name, rules)


if __name__ == "__main__":
    unittest.main()
