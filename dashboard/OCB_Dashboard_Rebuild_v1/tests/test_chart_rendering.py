import ast
import unittest
from pathlib import Path


APP = Path(__file__).resolve().parents[1] / "app.py"
SOURCE = APP.read_text(encoding="utf-8")
TREE = ast.parse(SOURCE)


class DashboardChartStructureTests(unittest.TestCase):
    def test_app_source_parses(self):
        self.assertIsNotNone(TREE)

    def test_plotly_charts_keep_explicit_unique_keys(self):
        calls = [
            node for node in ast.walk(TREE)
            if isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and isinstance(node.func.value, ast.Name)
            and node.func.value.id == "st"
            and node.func.attr == "plotly_chart"
        ]
        self.assertTrue(calls, "No line or other Plotly charts found")
        keys = []
        for call in calls:
            keywords = {kw.arg: kw.value for kw in call.keywords}
            self.assertIn("key", keywords, f"Plotly chart at line {call.lineno} has no key argument")
            key = keywords["key"]
            if isinstance(key, ast.Constant) and isinstance(key.value, str):
                keys.append(key.value)
        self.assertEqual(len(keys), len(set(keys)), f"Duplicate literal chart keys: {keys}")

    def test_bar_helper_uses_single_altair_renderer(self):
        helper = next(
            node for node in TREE.body
            if isinstance(node, ast.FunctionDef) and node.name == "bar_chart"
        )
        renderers = [
            node.func.attr for node in ast.walk(helper)
            if isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and isinstance(node.func.value, ast.Name)
            and node.func.value.id == "st"
            and node.func.attr in {"plotly_chart", "altair_chart"}
        ]
        self.assertEqual(renderers, ["altair_chart"])

    def test_value_and_volume_channels_remain_separate(self):
        titles = {}
        for node in ast.walk(TREE):
            if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Name) or node.func.id != "bar_chart":
                continue
            if len(node.args) >= 4 and isinstance(node.args[3], ast.Constant):
                titles.setdefault(node.args[3].value, []).append(node)
        self.assertEqual(len(titles.get("Successful value by channel", [])), 1)
        self.assertEqual(len(titles.get("Successful volume by channel", [])), 1)
        value_call = titles["Successful value by channel"][0]
        volume_call = titles["Successful volume by channel"][0]
        self.assertEqual(ast.literal_eval(value_call.args[2]), "total_transaction_value")
        self.assertEqual(ast.literal_eval(volume_call.args[2]), "total_transaction_count")

    def test_oman_keeps_separate_value_and_volume_charts(self):
        titles = {}
        for node in ast.walk(TREE):
            if not isinstance(node, ast.Call) or not isinstance(node.func, ast.Name) or node.func.id != "bar_chart":
                continue
            if len(node.args) >= 4 and isinstance(node.args[3], ast.Constant):
                titles.setdefault(node.args[3].value, []).append(node)
        self.assertEqual(len(titles.get("Value by channel", [])), 1)
        self.assertEqual(len(titles.get("Remittance volume by channel", [])), 1)
        self.assertEqual(ast.literal_eval(titles["Value by channel"][0].args[2]), "total_remittance_value")
        self.assertEqual(ast.literal_eval(titles["Remittance volume by channel"][0].args[2]), "total_remittance_count")

    def test_investigation_trigger_charts_match_the_trigger(self):
        self.assertIn('chosen_label == "SikaCredit · inbound remittance followed by loan repayment"', SOURCE)
        self.assertIn('count_col, value_col = "repayment_count", "principal_repaid"', SOURCE)
        self.assertIn('chosen_label == "Ananse · unsuccessful outcomes and overnight behaviour"', SOURCE)
        self.assertIn('trigger_df = A["ananse_outcomes"].copy()', SOURCE)
        self.assertIn('chosen_label == "Oman Remit · FATF-origin exposure"', SOURCE)
        self.assertIn('trigger_df = O["oman_fatf_monthly_trigger"].copy()', SOURCE)
        self.assertIn('"oman_fatf_monthly_trigger": "oman_fatf_monthly_trigger.sql"', (APP.parent / "sql_data.py").read_text(encoding="utf-8"))

    def test_debt_recycling_rapidity_and_recurrence_are_distinct(self):
        self.assertIn("while the previous loan still has unpaid principal", SOURCE)
        self.assertIn("gap from the second loan in one sequence to the third loan", SOURCE)


if __name__ == "__main__":
    unittest.main()
