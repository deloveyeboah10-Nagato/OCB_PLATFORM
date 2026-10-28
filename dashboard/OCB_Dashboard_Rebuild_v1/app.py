from pathlib import Path
from datetime import date, timedelta
from html import escape
import base64
import altair as alt
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st
from sql_data import load_sql_dataset, load_sql_query, sql_mode

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"
BG = "#0A1321"
PANEL = "#111D2D"
CYAN = "#56D6C2"
PURPLE = "#91A7FF"
GREEN = "#51C9A8"
AMBER = "#F2B765"
CRIMSON = "#ED7D8A"
TEXT = "#E8EFF8"
MUTED = "#9AAFC4"
GRID = "rgba(190,210,230,0.12)"

st.set_page_config(page_title="OCB | Financial Intelligence", page_icon="◈", layout="wide", initial_sidebar_state="expanded")

st.markdown(f"""
<style>
:root {{ color-scheme: dark; }}
.stApp, [data-testid="stAppViewContainer"] {{ background:{BG}; color:{TEXT}; }}
[data-testid="stHeader"] {{ background:rgba(10,19,33,.96); border-bottom:1px solid rgba(190,210,230,.08); }}
[data-testid="stMainBlockContainer"] {{ max-width:1640px; padding-top:1.25rem; padding-bottom:2.5rem; }}
[data-testid="stSidebar"] {{ background:#0D1929; border-right:1px solid rgba(190,210,230,.12); }}
[data-testid="stSidebar"] [data-testid="stVerticalBlock"] {{ gap:.8rem; }}
.ocb-brand {{ color:{CYAN}; font-size:.69rem; font-weight:800; letter-spacing:.17em; text-transform:uppercase; padding:.45rem 0 .8rem; border-bottom:1px solid rgba(190,210,230,.12); }}
.ocb-hero {{ display:grid; grid-template-columns:minmax(0,1fr) auto; align-items:center; gap:1.5rem; background:linear-gradient(115deg, rgba(86,214,194,.09), rgba(242,183,101,.055) 58%, rgba(17,29,45,.32)); border:1px solid rgba(242,183,101,.17); border-left:3px solid {CYAN}; border-radius:16px; padding:1.05rem 1.35rem .95rem; margin:.15rem 0 1.25rem; box-shadow:0 10px 30px rgba(242,183,101,.09), 0 0 22px rgba(242,183,101,.055), inset 0 1px 0 rgba(255,255,255,.025); }}
.ocb-hero-meta {{ display:flex; align-items:center; gap:.55rem; flex-wrap:wrap; margin-bottom:.45rem; }}
.ocb-eyebrow {{ color:{CYAN}; letter-spacing:.14em; font-size:.68rem; font-weight:800; text-transform:uppercase; }}
.ocb-title {{ font-size:2.05rem; line-height:1.15; font-weight:740; letter-spacing:-.025em; margin:.1rem 0 .3rem; color:{TEXT}; }}
.ocb-subtitle {{ color:{MUTED}; font-size:.98rem; line-height:1.5; margin:0; }}
.ocb-hero-emblem {{ width:104px; height:104px; display:grid; place-items:center; justify-self:end; border:1px solid rgba(242,183,101,.28); border-radius:50%; background:radial-gradient(circle, rgba(86,214,194,.10), rgba(242,183,101,.055) 62%, rgba(10,19,33,.18)); box-shadow:0 0 24px rgba(242,183,101,.12), inset 0 0 18px rgba(86,214,194,.06); }}
.ocb-hero-emblem img {{ width:82px; height:82px; display:block; filter:drop-shadow(0 3px 8px rgba(242,183,101,.18)); }}
.ocb-pill {{ display:inline-flex; align-items:center; border:1px solid rgba(86,214,194,.32); color:{CYAN}; background:rgba(86,214,194,.08); border-radius:999px; padding:.24rem .62rem; font-size:.69rem; font-weight:700; letter-spacing:.035em; }}
.ocb-pill-period {{ border-color:rgba(145,167,255,.3); color:#B8C6FF; background:rgba(145,167,255,.08); }}
.ocb-section {{ font-size:1.03rem; font-weight:730; color:{TEXT}; margin:.2rem 0 .15rem; letter-spacing:-.01em; }}
.ocb-section-note {{ font-size:.79rem; line-height:1.5; color:{MUTED}; margin-bottom:.75rem; max-width:1050px; }}
.ocb-card-kicker {{ color:{CYAN}; font-size:.7rem; font-weight:780; letter-spacing:.1em; text-transform:uppercase; margin:.1rem 0 .75rem; }}
.ocb-institution-grid {{ display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:1rem; align-items:stretch; }}
.ocb-institution-card {{ box-sizing:border-box; height:270px; display:flex; flex-direction:column; padding:1rem; border:1px solid rgba(242,183,101,.18); border-radius:14px; background:linear-gradient(155deg, rgba(242,183,101,.035), rgba(17,29,45,.62) 44%, rgba(10,19,33,.20)); box-shadow:0 8px 23px rgba(242,183,101,.075), 0 0 16px rgba(242,183,101,.04); }}
.ocb-institution-card-title {{ min-height:2.25rem; display:flex; align-items:flex-start; color:{CYAN}; font-size:.72rem; font-weight:780; letter-spacing:.085em; line-height:1.45; text-transform:uppercase; margin:0 0 .65rem; }}
.ocb-institution-metrics {{ display:grid; grid-template-columns:minmax(0,1fr) minmax(0,1fr); gap:.65rem; }}
.ocb-institution-metric {{ box-sizing:border-box; height:116px; padding:.72rem .78rem; border:1px solid rgba(190,210,230,.12); border-radius:12px; background:linear-gradient(145deg, #142338, #101C2C); }}
.ocb-institution-label {{ height:2.65rem; color:{MUTED}; font-size:.92rem; line-height:1.35; font-weight:570; }}
.ocb-institution-value {{ color:{TEXT}; font-size:clamp(.98rem, 1vw, 1.12rem); line-height:1.3; font-weight:740; letter-spacing:-.012em; white-space:nowrap; }}
.ocb-institution-note {{ min-height:2.6rem; display:flex; align-items:flex-end; margin-top:auto; color:{MUTED}; font-size:.86rem; line-height:1.45; }}
[data-testid="stMetric"] {{ background:linear-gradient(145deg, #142338, #101C2C); border:1px solid rgba(190,210,230,.12); padding:.8rem .95rem; border-radius:12px; min-height:112px; }}
[data-testid="stMetricLabel"] {{ color:{MUTED}; font-size:.72rem; line-height:1.3; font-weight:620; overflow:visible !important; text-overflow:clip !important; }}
[data-testid="stMetricLabel"] *, [data-testid="stMetricValue"] * {{ white-space:normal !important; overflow:visible !important; text-overflow:clip !important; max-width:100%; }}
[data-testid="stMetricValue"] {{ color:{TEXT}; font-size:1.08rem; line-height:1.25; font-weight:720; letter-spacing:-.015em; overflow:visible !important; text-overflow:clip !important; }}
[data-testid="stMetricValue"] > div, [data-testid="stMetricValue"] p {{ white-space:normal !important; overflow:visible !important; text-overflow:clip !important; overflow-wrap:anywhere; }}
[data-testid="stMetricDelta"] {{ font-size:.74rem; }}
[data-testid="stPlotlyChart"], [data-testid="stVegaLiteChart"] {{ background:{PANEL}; border:1px solid rgba(190,210,230,.10); border-radius:16px; padding:.35rem; overflow:hidden; }}
[data-testid="stDataFrame"] {{ border:1px solid rgba(190,210,230,.13); border-radius:11px; overflow:hidden; }}
[data-testid="stExpander"] {{ background:rgba(17,29,45,.62); border:1px solid rgba(190,210,230,.12); border-radius:12px; }}
[data-testid="stSelectbox"] label, [data-testid="stMultiSelect"] label, [data-testid="stDateInput"] label {{ color:{TEXT}; font-weight:650; }}
[data-baseweb="select"] > div {{ background:#132238; border-color:rgba(190,210,230,.2); border-radius:9px; min-height:2.75rem; }}
[data-baseweb="select"] > div:focus-within {{ border-color:{CYAN}; box-shadow:0 0 0 1px {CYAN}; }}
[data-testid="stDateInput"] input {{ background:#132238; border-color:rgba(190,210,230,.2); border-radius:9px; }}
[data-testid="stSidebar"] [data-testid="stSelectbox"] {{ padding:.15rem .2rem .25rem; }}
div[data-testid="stAlert"] {{ border-radius:11px; }}
hr {{ border-color:rgba(190,210,230,.12); margin:1.1rem 0; }}
footer {{ visibility:hidden; }}
@media (max-width: 1400px) {{ .ocb-institution-grid {{ grid-template-columns:1fr; }} .ocb-institution-card {{ height:240px; }} }}
@media (max-width: 760px) {{ .ocb-hero {{ grid-template-columns:minmax(0,1fr) 68px; gap:.7rem; padding:.9rem; }} .ocb-hero-emblem {{ width:68px; height:68px; }} .ocb-hero-emblem img {{ width:54px; height:54px; }} .ocb-title {{ font-size:1.65rem; }} [data-testid="stMetric"] {{ min-height:unset; }} .ocb-institution-card {{ height:240px; }} .ocb-institution-metric {{ padding:.65rem; }} .ocb-institution-value {{ font-size:.98rem; }} }}
</style>
""", unsafe_allow_html=True)

@st.cache_data(show_spinner=False, ttl=300)
def load_dataset(name, source_mode):
    """Read the authoritative SQL source when configured; otherwise use prototype CSV."""
    if source_mode == "sql":
        return load_sql_dataset(name)
    path = DATA / f"{name}.csv"
    if not path.exists():
        return pd.DataFrame()
    df = pd.read_csv(path)
    if "year_month" in df.columns:
        df["year_month"] = df["year_month"].astype(str).str.slice(0, 7)
        df["month_date"] = pd.to_datetime(df["year_month"] + "-01", errors="coerce")
    return df

@st.cache_data(show_spinner=False, ttl=300)
def run_investigation_query(query_name, start_date=None, end_date_exclusive=None):
    params = [] if start_date is None else [start_date, end_date_exclusive]
    return load_sql_query(query_name, params)

def month_filter(df, start, end):
    if df.empty or "month_date" not in df.columns:
        return df.copy()
    return df.loc[(df["month_date"] >= pd.Timestamp(start)) & (df["month_date"] <= pd.Timestamp(end))].copy()

def ghs(value, compact=False):
    if pd.isna(value): return "—"
    value = float(value)
    if compact:
        if abs(value) >= 1_000_000: return f"GHS {value/1_000_000:,.2f}M"
        if abs(value) >= 1_000: return f"GHS {value/1_000:,.1f}K"
    return f"GHS {value:,.2f}"

def integer(value):
    if pd.isna(value): return "—"
    return f"{int(round(float(value))):,}"

def pct(value):
    if pd.isna(value): return "—"
    return f"{float(value):,.2f}%"

def chart_theme(fig, height=330):
    fig.update_layout(
        template="plotly_dark", height=height, paper_bgcolor=PANEL, plot_bgcolor=PANEL,
        font=dict(family="Inter, Segoe UI, sans-serif", color=TEXT, size=11),
        margin=dict(l=12, r=12, t=58, b=12),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="left", x=0, font=dict(size=10)),
        hoverlabel=dict(bgcolor="#191E29", bordercolor="#2C3444", font_color=TEXT),
    )
    if "barcornerradius" in fig.layout._valid_props:
        fig.update_layout(barcornerradius=5)
    fig.update_xaxes(showgrid=False, zeroline=False, linecolor=GRID, tickfont=dict(color=MUTED))
    fig.update_yaxes(gridcolor=GRID, zeroline=False, tickfont=dict(color=MUTED))
    return fig

def _chart_key(kind, title):
    """Stable, chart-type-scoped Streamlit key; prevents accidental widget identity reuse."""
    import re
    slug = re.sub(r"[^a-z0-9]+", "_", str(title).lower()).strip("_")
    return f"ocb_{kind}_{slug or 'untitled'}"


def line_chart(df, x, y, title, color=CYAN, y_title=None, value_format=None, height=330, key=None):
    if df.empty:
        st.info("No records are available for this selection.")
        return
    # Ensure chronological line order; SQL views/exports are not guaranteed to arrive sorted.
    plot_df = df.copy()
    if x in plot_df.columns:
        plot_df = plot_df.sort_values(x, kind="stable")
    fig = px.line(plot_df, x=x, y=y, markers=True, title=title)
    hover = "%{x}<br>%{y:,.0f}<extra></extra>" if value_format == "integer" else "%{x}<br>%{y:,.2f}<extra></extra>"
    fig.update_traces(line=dict(color=color, width=2.6), marker=dict(size=5), hovertemplate=hover)
    if value_format == "money": fig.update_yaxes(tickprefix="GHS ", tickformat="~s")
    if value_format == "integer": fig.update_yaxes(tickformat=",d")
    if value_format == "percent": fig.update_yaxes(ticksuffix="%", tickformat=".1f")
    if y_title: fig.update_yaxes(title=y_title)
    chart_theme(fig, height)
    st.plotly_chart(fig, use_container_width=True, key=key or _chart_key("line", title), config={"displaylogo": False, "responsive": True})

def multi_line_chart(df, x, series, title, colors, value_format=None, height=330, key=None):
    if df.empty:
        st.info("No records are available for this selection.")
        return
    fig = go.Figure()
    for col, label, color in series:
        if col in df.columns:
            fig.add_trace(go.Scatter(x=df[x], y=df[col], mode="lines+markers", name=label, line=dict(color=color, width=2.3), marker=dict(size=4), hovertemplate=f"{label}<br>%{{x}}<br>%{{y:,.2f}}<extra></extra>"))
    fig.update_layout(title=title)
    if value_format == "money": fig.update_yaxes(tickprefix="GHS ", tickformat="~s")
    if value_format == "percent": fig.update_yaxes(ticksuffix="%", tickformat=".1f")
    chart_theme(fig, height)
    st.plotly_chart(fig, use_container_width=True, key=key or _chart_key("multi", title), config={"displaylogo": False, "responsive": True})

def bar_chart(df, x, y, title, color=PURPLE, horizontal=False, value_format=None, height=330, key=None):
    if df.empty:
        st.info("No records are available for this selection.")
        return
    value_axis = alt.Axis(format="~s", labelExpr="'GHS ' + format(datum.value, '~s')") if value_format == "money" else alt.Axis(format="~s")
    value_tooltip_format = ",.2f" if value_format == "money" else ",d" if value_format == "integer" else ",.2f"
    measure = alt.X(y, type="quantitative", title=y, axis=value_axis) if horizontal else alt.Y(y, type="quantitative", title=y, axis=value_axis)
    category = alt.Y(x, type="nominal", title=x, sort=alt.SortField(field=y, order="descending")) if horizontal else alt.X(x, type="nominal", title=x, sort=alt.SortField(field=y, order="descending"))
    chart = alt.Chart(df[[x, y]]).mark_bar(color=color, cornerRadiusEnd=5).encode(
        measure,
        category,
        tooltip=[alt.Tooltip(x, type="nominal", title=x), alt.Tooltip(y, type="quantitative", title=y, format=value_tooltip_format)],
    ).properties(title=title, height=height)
    chart = chart.configure(
        background=PANEL,
        view={"stroke": "rgba(255,255,255,.06)", "fill": PANEL},
        axis={"labelColor": MUTED, "titleColor": TEXT, "gridColor": GRID, "domainColor": GRID},
        title={"color": TEXT, "fontSize": 14, "anchor": "start"},
    )
    st.altair_chart(chart, width="stretch", key=key or _chart_key("bar", title), theme=None)

def section(title, note=None):
    st.markdown(f'<div class="ocb-section">{title}</div>', unsafe_allow_html=True)
    if note:
        st.markdown(f'<div class="ocb-section-note">{note}</div>', unsafe_allow_html=True)

def safe_table(df, columns, labels=None, money_cols=(), int_cols=(), pct_cols=(), height=360):
    if df.empty:
        st.info("No records are available for this selection.")
        return
    show = df[[c for c in columns if c in df.columns]].copy()
    for c in money_cols:
        if c in show.columns: show[c] = show[c].map(lambda x: ghs(x))
    for c in int_cols:
        if c in show.columns: show[c] = show[c].map(integer)
    for c in pct_cols:
        if c in show.columns: show[c] = show[c].map(pct)
    if labels: show = show.rename(columns=labels)
    st.dataframe(show, use_container_width=True, hide_index=True, height=height)

def latest_row(df):
    if df.empty: return None
    sort_col = "month_date" if "month_date" in df.columns else "year_month"
    return df.sort_values(sort_col).iloc[-1]

def period_summary(df, count_col, value_col):
    if df.empty: return 0, 0, 0
    return int(df[count_col].sum()), float(df[value_col].sum()), int(df["distinct_customers"].max()) if "distinct_customers" in df.columns else 0

def institution_card(title, first_label, first_value, second_label, second_value, note):
    metrics = [(first_label, first_value), (second_label, second_value)]
    metric_html = "".join(
        f'<div class="ocb-institution-metric"><div class="ocb-institution-label">{escape(str(label))}</div>'
        f'<div class="ocb-institution-value">{escape(str(value))}</div></div>'
        for label, value in metrics
    )
    return (
        f'<section class="ocb-institution-card"><div class="ocb-institution-card-title">{escape(title)}</div>'
        f'<div class="ocb-institution-metrics">{metric_html}</div>'
        f'<div class="ocb-institution-note">{escape(note)}</div></section>'
    )

# Load the actual exported monitoring datasets.
DATA_SOURCE_MODE = "sql" if sql_mode() else "csv"
try:
    A = {k: load_dataset(k, DATA_SOURCE_MODE) for k in ["ananse_monthly", "ananse_region", "ananse_town", "ananse_type", "ananse_channel", "ananse_outcomes", "ananse_top10"]}
    S = {k: load_dataset(k, DATA_SOURCE_MODE) for k in ["sika_monthly", "sika_flows", "sika_loan_activity", "sika_repayment_activity", "sika_top_post_maturity", "sika_top_outstanding"]}
    O = {k: load_dataset(k, DATA_SOURCE_MODE) for k in ["oman_monthly", "oman_channel", "oman_origin_country", "oman_type", "oman_region", "oman_town", "oman_outcomes", "oman_top10"]}
    O["oman_outbound_monthly_trigger"] = load_dataset("oman_outbound_monthly_trigger", DATA_SOURCE_MODE)
    O["oman_fatf_monthly_trigger"] = load_dataset("oman_fatf_monthly_trigger", DATA_SOURCE_MODE) if DATA_SOURCE_MODE == "sql" else pd.DataFrame()
except Exception as exc:
    st.error(f"Could not load the configured OCB data source: {exc}")
    if sql_mode():
        st.info("SQL mode does not silently fall back to CSV. Check the local SQL Server configuration and try again.")
    st.stop()

all_months = sorted(set(A["ananse_monthly"].get("year_month", pd.Series(dtype=str)).dropna()) | set(S["sika_monthly"].get("year_month", pd.Series(dtype=str)).dropna()) | set(O["oman_monthly"].get("year_month", pd.Series(dtype=str)).dropna()))
if not all_months:
    st.error("No OCB monitoring snapshots were found. Ensure the data/ folder is present beside app.py.")
    st.stop()

with st.sidebar:
    st.markdown('<div class="ocb-brand">OCB · FINANCIAL SUPERVISION</div>', unsafe_allow_html=True)
    st.markdown("## Workspace")
    view = st.selectbox("View", ["System overview", "Ananse Telecom", "SikaCredit", "Oman Remit", "Supervisory investigations"])
    st.markdown("---")
    selected_months = st.select_slider("Reporting period", options=all_months, value=(all_months[0], all_months[-1]))
    start_month, end_month = selected_months
    st.caption(f"{start_month} → {end_month}")
    st.markdown("---")
    source_label = "SQL Server · existing OCB views and analytical queries" if sql_mode() else "CSV prototype snapshots · not live SQL"
    st.caption(f"Data source: {source_label}\n\nValues shown in GHS where applicable.")

start_date = pd.Timestamp(start_month + "-01")
end_date = pd.Timestamp(end_month + "-01")

def filtered(key, dataset):
    return month_filter(dataset, start_date, end_date)

# Header
source_badge = "SQL SERVER DATA" if sql_mode() else "CSV SNAPSHOT"
logo_data = base64.b64encode((ROOT / "assets" / "ocb_emblem.svg").read_bytes()).decode("ascii")
st.markdown(f'''<div class="ocb-hero">
<div class="ocb-hero-copy">
<div class="ocb-hero-meta"><span class="ocb-eyebrow">REGULATORY SANDBOX · FINANCIAL SUPERVISION</span><span class="ocb-pill">{source_badge}</span><span class="ocb-pill ocb-pill-period">{start_month} — {end_month}</span></div>
<div class="ocb-title">Osagyefo Central Bank</div>
<div class="ocb-subtitle">Institutional monitoring, transaction outcomes and supervisory investigations</div>
</div>
<div class="ocb-hero-emblem"><img src="data:image/svg+xml;base64,{logo_data}" alt="Osagyefo Central Bank symbol"></div>
</div>''', unsafe_allow_html=True)

if view == "System overview":
    section("Institutional snapshot", "Institutions remain separate: each metric reflects its own activity and is not summed into a misleading system-wide financial total.")
    a = filtered("ananse_monthly", A["ananse_monthly"])
    s = filtered("sika_monthly", S["sika_monthly"])
    o = filtered("oman_monthly", O["oman_monthly"])
    a_count, a_value, a_customers = period_summary(a, "total_transaction_count", "total_transaction_value")
    o_count, o_value, o_customers = period_summary(o, "total_remittance_count", "total_remittance_value")
    s_disbursed = float(s["principal_disbursed"].sum()) if not s.empty else 0
    s_repaid = float(s["principal_repaid"].sum()) if not s.empty else 0
    s_latest = latest_row(s)
    cards = [
        institution_card("Ananse Telecom · Mobile Money", "Successful transactions", integer(a_count), "Successful value", ghs(a_value, True), f"Peak monthly active customers: {integer(a_customers)}"),
        institution_card("SikaCredit · digital lending", "Principal disbursed", ghs(s_disbursed, True), "Principal repaid", ghs(s_repaid, True), f"Latest closing outstanding: {ghs(s_latest['closing_outstanding_principal'], True) if s_latest is not None else '—'}"),
        institution_card("Oman Remit · remittance", "Successful remittances", integer(o_count), "Successful value", ghs(o_value, True), f"Peak monthly active customers: {integer(o_customers)}"),
    ]
    st.markdown(f'<div class="ocb-institution-grid">{"".join(cards)}</div>', unsafe_allow_html=True)

    st.markdown("---")
    section("Activity over time", "Separate panels preserve the scale and meaning of each institution's activity.")
    c1,c2,c3 = st.columns(3)
    with c1:
        line_chart(a, "year_month", "total_transaction_count", "Ananse · successful transactions", CYAN, value_format="integer", height=290)
    with c2:
        line_chart(s, "year_month", "loans_disbursed_count", "SikaCredit · loans disbursed", PURPLE, value_format="integer", height=290)
    with c3:
        line_chart(o, "year_month", "total_remittance_count", "Oman Remit · successful remittances", GREEN, value_format="integer", height=290)

    st.markdown("---")
    section("Unsuccessful transaction and remittance rates", "Each line is the share of all attempts that failed or were rejected; lower is better. These are rates, not transaction values.")
    c1,c2 = st.columns(2)
    with c1:
        ao = filtered("ananse_outcomes", A["ananse_outcomes"])
        if not ao.empty and "overall_unsuccessful_rate" in ao.columns:
            # Keep one observation per month for the overview trend.
            ao = ao.sort_values("year_month", kind="stable").drop_duplicates("year_month", keep="last")
            line_chart(ao, "year_month", "overall_unsuccessful_rate", "Ananse · unsuccessful rate", AMBER, y_title="Unsuccessful attempts (%)", value_format="percent", height=330)
        else:
            st.info("Ananse unsuccessful-rate data are not available from this source.")
    with c2:
        oo = filtered("oman_outcomes", O["oman_outcomes"])
        rate_col = "overall_unsuccessful_rate_pct" if "overall_unsuccessful_rate_pct" in oo.columns else "overall_unsuccessful_rate"
        if not oo.empty and rate_col in oo.columns:
            # Keep one observation per month for the overview trend.
            oo = oo.sort_values("year_month", kind="stable").drop_duplicates("year_month", keep="last")
            line_chart(oo, "year_month", rate_col, "Oman Remit · unsuccessful rate", AMBER, y_title="Unsuccessful remittances (%)", value_format="percent", height=330)
        else:
            st.info("Oman Remit unsuccessful-rate data are not available from this source.")
    st.caption("SikaCredit monitoring focuses on lending and repayment behaviour; transaction outcome charts are not available in the supplied SikaCredit export.")

elif view == "Ananse Telecom":
    monthly = filtered("ananse_monthly", A["ananse_monthly"])
    outcomes = filtered("ananse_outcomes", A["ananse_outcomes"])
    channels = filtered("ananse_channel", A["ananse_channel"])
    regions = filtered("ananse_region", A["ananse_region"])
    section("Ananse Telecom", "Successful transaction activity, customer reach, channel mix and transaction outcomes.")
    channel_names = sorted(channels["transaction_channel"].dropna().unique().tolist()) if not channels.empty else []
    selected_channels = st.multiselect("Filter activity by channel", channel_names, default=channel_names, key="ananse_channels")
    channel_filtered = channels[channels["transaction_channel"].isin(selected_channels)] if selected_channels else channels.iloc[0:0]
    if selected_channels and len(selected_channels) < len(channel_names):
        trend = channel_filtered.groupby("year_month", as_index=False).agg(total_transaction_count=("total_transaction_count","sum"), total_transaction_value=("total_transaction_value","sum"))
        monthly_display = monthly.merge(trend, on="year_month", how="right", suffixes=("_all", "")) if not trend.empty else trend
        monthly_display = trend
        active_customers_label = "Not additive across selected channels"
    else:
        monthly_display = monthly
        active_customers_label = "Distinct customers (monthly maximum)"
    total_count = int(monthly_display["total_transaction_count"].sum()) if not monthly_display.empty else 0
    total_value = float(monthly_display["total_transaction_value"].sum()) if not monthly_display.empty else 0
    last = latest_row(monthly_display)
    k1,k2,k3,k4 = st.columns(4)
    k1.metric("Successful transactions", integer(total_count))
    k2.metric("Successful Txns Value", ghs(total_value, True))
    k3.metric("Latest-Month Txns", integer(last["total_transaction_count"]) if last is not None else "—")
    k4.metric("Latest-Month Avg Value", ghs(last["total_transaction_value"] / last["total_transaction_count"]) if last is not None and last["total_transaction_count"] else "—")
    c1,c2 = st.columns(2)
    with c1: line_chart(monthly_display, "year_month", "total_transaction_count", "Successful transaction volume", CYAN, value_format="integer", height=320)
    with c2: line_chart(monthly_display, "year_month", "total_transaction_value", "Successful transaction value", PURPLE, value_format="money", height=320)
    st.markdown("---")
    types = filtered("ananse_type", A["ananse_type"])
    towns = filtered("ananse_town", A["ananse_town"])
    c1,c2 = st.columns(2)
    with c1:
        ch = channel_filtered.groupby("transaction_channel", as_index=False).agg(total_transaction_count=("total_transaction_count","sum"),total_transaction_value=("total_transaction_value","sum")).sort_values("total_transaction_value",ascending=False)
        bar_chart(ch, "transaction_channel", "total_transaction_value", "Successful value by channel", PURPLE, horizontal=True, value_format="money", height=350)
    with c2:
        typ = types.groupby("transaction_type",as_index=False).agg(total_transaction_value=("total_transaction_value","sum"),total_transaction_count=("total_transaction_count","sum")).sort_values("total_transaction_value",ascending=False) if not types.empty else types
        bar_chart(typ, "transaction_type", "total_transaction_value", "Successful value by transaction type", GREEN, horizontal=True, value_format="money", height=350)
    c1,c2 = st.columns(2)
    with c1:
        reg = regions.groupby("transaction_region",as_index=False).agg(total_transaction_value=("total_transaction_value","sum"),total_transaction_count=("total_transaction_count","sum")).nlargest(10,"total_transaction_value") if not regions.empty else regions
        bar_chart(reg, "transaction_region", "total_transaction_value", "Top regions by successful transaction value", CYAN, horizontal=True, value_format="money", height=330)
    with c2:
        town = towns.groupby("transaction_town",as_index=False).agg(total_transaction_value=("total_transaction_value","sum"),total_transaction_count=("total_transaction_count","sum")).nlargest(10,"total_transaction_value") if not towns.empty and "transaction_town" in towns.columns else towns.iloc[0:0]
        bar_chart(town, "transaction_town", "total_transaction_value", "Top towns by successful transaction value", AMBER, horizontal=True, value_format="money", height=330)
    c1,c2 = st.columns(2)
    with c1:
        bar_chart(ch, "transaction_channel", "total_transaction_count", "Successful volume by channel", PURPLE, horizontal=True, value_format="integer", height=350)
    with c2:
        bar_chart(typ, "transaction_type", "total_transaction_count", "Successful volume by transaction type", GREEN, horizontal=True, value_format="integer", height=350)
    c1,c2 = st.columns(2)
    with c1:
        bar_chart(reg, "transaction_region", "total_transaction_count", "Top regions by successful transaction volume", CYAN, horizontal=True, value_format="integer", height=330)
    with c2:
        bar_chart(town, "transaction_town", "total_transaction_count", "Top towns by successful transaction volume", AMBER, horizontal=True, value_format="integer", height=330)
    st.markdown("---")
    c1,c2 = st.columns(2)
    with c1:
        multi_line_chart(outcomes,"year_month",[("successful_rate","Successful",GREEN),("failure_rate","Failed",AMBER),("rejection_rate","Rejected",CRIMSON)],"Transaction outcomes",[GREEN,AMBER,CRIMSON],value_format="percent",height=320)
    with c2:
        section("Highest-value customers", "All-history ranking from the supplied customer activity export; this table is not recalculated by the reporting-period filter.")
        safe_table(A["ananse_top10"].sort_values("total_transaction_value",ascending=False),["ocb_customer_id","total_transaction_count","total_transaction_value","average_transaction_value","median_transaction_value"],{"ocb_customer_id":"Customer ID","total_transaction_count":"Transactions","total_transaction_value":"Total value","average_transaction_value":"Average value","median_transaction_value":"Median value"},money_cols=("total_transaction_value","average_transaction_value","median_transaction_value"),int_cols=("total_transaction_count",),height=340)

elif view == "SikaCredit":
    monthly = filtered("sika_monthly", S["sika_monthly"])
    flows = filtered("sika_flows", S["sika_flows"])
    section("SikaCredit", "Lending, repayment flows, outstanding principal and post-maturity exposure.")
    with st.expander("How to read these measures"):
        st.markdown("- **Net principal flow:** principal disbursed minus principal repaid during the month. Positive means more principal was disbursed than repaid; negative means repayments exceeded disbursements.\n- **Closing outstanding principal:** principal remaining outstanding at month-end.\n- **Post-maturity outstanding:** principal still outstanding on loans past maturity. A rising balance can indicate accumulating overdue exposure, but is not by itself proof of distress.")
    total_disbursed = float(monthly["principal_disbursed"].sum()) if not monthly.empty else 0
    total_repaid = float(monthly["principal_repaid"].sum()) if not monthly.empty else 0
    last = latest_row(monthly)
    k1,k2,k3,k4 = st.columns(4)
    k1.metric("Principal disbursed", ghs(total_disbursed,True))
    k2.metric("Principal repaid", ghs(total_repaid,True))
    k3.metric("Closing outstanding principal", ghs(last["closing_outstanding_principal"],True) if last is not None else "—")
    k4.metric("Post-maturity outstanding", ghs(last["post_maturity_outstanding_principal"],True) if last is not None else "—", delta=pct(last["post_maturity_outstanding_ratio_pct"]) + " of outstanding" if last is not None else None, delta_color="inverse")
    c1,c2 = st.columns(2)
    with c1: multi_line_chart(monthly,"year_month",[("principal_disbursed","Principal disbursed",CYAN),("principal_repaid","Principal repaid",PURPLE)],"Principal disbursed vs repaid",[CYAN,PURPLE],value_format="money",height=340)
    with c2: line_chart(monthly,"year_month","closing_outstanding_principal","Closing outstanding principal",GREEN,value_format="money",height=340)
    c1,c2 = st.columns(2)
    with c1:
        fig=px.bar(flows,x="year_month",y="net_principal_flow",title="Net principal flow by month",color="net_principal_flow",color_continuous_scale=[CRIMSON,"#334256",GREEN],color_continuous_midpoint=0)
        fig.update_coloraxes(showscale=False); fig.update_yaxes(tickprefix="GHS ",tickformat="~s"); chart_theme(fig,320); st.plotly_chart(fig, use_container_width=True, key="ocb_sika_net_principal_flow", config={"displaylogo": False, "responsive": True})
    with c2: line_chart(monthly,"year_month","post_maturity_outstanding_ratio_pct","Post-maturity outstanding / closing outstanding",AMBER,value_format="percent",height=320)
    st.markdown("---")
    loan_activity = filtered("sika_loan_activity", S["sika_loan_activity"])
    repayment_activity = filtered("sika_repayment_activity", S["sika_repayment_activity"])
    st.markdown("---")
    section("Loan and repayment activity", "Separate views expose the lending and repayment activity behind the portfolio-level indicators.")
    c1,c2 = st.columns(2)
    with c1:
        loan_count_col = "principal_disbursed_count" if "principal_disbursed_count" in loan_activity.columns else None
        if loan_count_col: line_chart(loan_activity,"year_month",loan_count_col,"Loans disbursed per month",CYAN,value_format="integer",height=300)
        else: st.info("Loan-count field is not available in this source view.")
    with c2:
        repay_count_col = "principal_repaid_count" if "principal_repaid_count" in repayment_activity.columns else None
        if repay_count_col: line_chart(repayment_activity,"year_month",repay_count_col,"Repayment events per month",PURPLE,value_format="integer",height=300)
        else: st.info("Repayment-count field is not available in this source view.")
    c1,c2 = st.columns(2)
    with c1:
        if "principal_disbursed" in loan_activity.columns: line_chart(loan_activity,"year_month","principal_disbursed","Principal disbursed · loan activity view",CYAN,value_format="money",height=300)
        else: st.info("Principal disbursed field is not available in the loan activity view.")
    with c2:
        if "principal_repaid" in repayment_activity.columns: line_chart(repayment_activity,"year_month","principal_repaid","Principal repaid · repayment activity view",PURPLE,value_format="money",height=300)
        else: st.info("Principal repaid field is not available in the repayment activity view.")
    st.markdown("---")
    c1,c2 = st.columns(2)
    with c1:
        section("Largest Principal Past Maturity", "Ranks customers by principal still outstanding after loan maturity; highlights potentially overdue exposure.")
        safe_table(S["sika_top_post_maturity"].sort_values("post_maturity_outstanding",ascending=False),["ocb_customer_id","post_maturity_outstanding","post_maturity_loan_count","avg_post_maturity_outstanding"],{"ocb_customer_id":"Customer ID","post_maturity_outstanding":"Post-maturity outstanding","post_maturity_loan_count":"Loans","avg_post_maturity_outstanding":"Average exposure"},money_cols=("post_maturity_outstanding","avg_post_maturity_outstanding"),int_cols=("post_maturity_loan_count",),height=360)
    with c2:
        section("Largest Total Outstanding Principal", "Ranks customers by all principal still outstanding, whether or not the loan has passed maturity.")
        safe_table(S["sika_top_outstanding"].sort_values("total_outstanding_principal",ascending=False),["ocb_customer_id","total_outstanding_principal","total_principal_borrowed","loan_count","total_repaid"],{"ocb_customer_id":"Customer ID","total_outstanding_principal":"Outstanding principal","total_principal_borrowed":"Principal borrowed","loan_count":"Loans","total_repaid":"Total repaid"},money_cols=("total_outstanding_principal","total_principal_borrowed","total_repaid"),int_cols=("loan_count",),height=360)

elif view == "Oman Remit":
    monthly = filtered("oman_monthly", O["oman_monthly"])
    outcomes = filtered("oman_outcomes", O["oman_outcomes"])
    channels = filtered("oman_channel", O["oman_channel"])
    origins = filtered("oman_origin_country", O["oman_origin_country"])
    types = filtered("oman_type", O["oman_type"])
    section("Oman Remit", "Successful remittance activity, channel mix, origin exposure and transaction outcomes.")
    channel_names = sorted(channels["remittance_transaction_channel"].dropna().unique().tolist()) if not channels.empty else []
    selected_channels = st.multiselect("Filter activity by channel", channel_names, default=channel_names, key="oman_channels")
    channel_filtered = channels[channels["remittance_transaction_channel"].isin(selected_channels)] if selected_channels else channels.iloc[0:0]
    if selected_channels and len(selected_channels) < len(channel_names):
        monthly_display = channel_filtered.groupby("year_month",as_index=False).agg(total_remittance_count=("total_remittance_count","sum"),total_remittance_value=("total_remittance_value","sum"))
    else:
        monthly_display = monthly
    total_count = int(monthly_display["total_remittance_count"].sum()) if not monthly_display.empty else 0
    total_value = float(monthly_display["total_remittance_value"].sum()) if not monthly_display.empty else 0
    last = latest_row(monthly_display)
    k1,k2,k3,k4 = st.columns(4)
    k1.metric("Successful remittances", integer(total_count))
    k2.metric("Successful remittance value", ghs(total_value,True))
    k3.metric("Latest-month remittances", integer(last["total_remittance_count"]) if last is not None else "—")
    k4.metric("Latest-Month Avg Value", ghs(last["total_remittance_value"]/last["total_remittance_count"]) if last is not None and last["total_remittance_count"] else "—")
    c1,c2 = st.columns(2)
    with c1: line_chart(monthly_display,"year_month","total_remittance_count","Successful remittance volume",CYAN,value_format="integer",height=320)
    with c2: line_chart(monthly_display,"year_month","total_remittance_value","Successful remittance value",PURPLE,value_format="money",height=320)
    st.markdown("---")
    c1,c2 = st.columns(2)
    with c1:
        ch=channel_filtered.groupby("remittance_transaction_channel",as_index=False).agg(total_remittance_count=("total_remittance_count","sum"),total_remittance_value=("total_remittance_value","sum")).sort_values("total_remittance_value",ascending=False)
        bar_chart(ch,"remittance_transaction_channel","total_remittance_value","Value by channel",PURPLE,horizontal=True,value_format="money",height=340)
    with c2:
        origin=origins.groupby("remittance_origin_country",as_index=False).agg(total_remittance_value=("total_remittance_value","sum"),total_remittance_count=("total_remittance_count","sum")).nlargest(10,"total_remittance_value") if not origins.empty else origins
        bar_chart(origin,"remittance_origin_country","total_remittance_value","Top origin countries by value",CYAN,horizontal=True,value_format="money",height=340)
    c1,c2 = st.columns(2)
    with c1:
        if not outcomes.empty:
            outcomes = outcomes.sort_values("year_month", kind="stable").drop_duplicates("year_month", keep="last")
        multi_line_chart(outcomes,"year_month",[("successful_rate_pct","Successful",GREEN),("failure_rate_pct","Failed",AMBER),("rejection_rate_pct","Rejected",CRIMSON)],"Remittance outcomes",[GREEN,AMBER,CRIMSON],value_format="percent",height=320)
    with c2:
        type_summary=types.groupby("remittance_type",as_index=False).agg(total_remittance_value=("total_remittance_value","sum"),total_remittance_count=("total_remittance_count","sum")).sort_values("total_remittance_value",ascending=False)
        bar_chart(type_summary,"remittance_type","total_remittance_value","Successful value by remittance type",GREEN,horizontal=True,value_format="money",height=320)
    c1,c2 = st.columns(2)
    with c1:
        bar_chart(ch,"remittance_transaction_channel","total_remittance_count","Remittance volume by channel",PURPLE,horizontal=True,value_format="integer",height=340)
    with c2:
        bar_chart(origin,"remittance_origin_country","total_remittance_count","Top origin countries by volume",CYAN,horizontal=True,value_format="integer",height=340)
    st.markdown("---")
    bar_chart(type_summary,"remittance_type","total_remittance_count","Successful volume by remittance type",GREEN,horizontal=True,value_format="integer",height=320)
    st.markdown("---")
    section("Highest-value customers", "All-history ranking from the supplied customer activity export; this table is not recalculated by the reporting-period filter.")
    safe_table(O["oman_top10"].sort_values("total_remittance_value",ascending=False),["ocb_customer_id","total_remittance_count","total_remittance_value","average_remittance_value","median_remittance_value"],{"ocb_customer_id":"Customer ID","total_remittance_count":"Remittances","total_remittance_value":"Total value","average_remittance_value":"Average value","median_remittance_value":"Median value"},money_cols=("total_remittance_value","average_remittance_value","median_remittance_value"),int_cols=("total_remittance_count",),height=360)

else:  # Supervisory investigations
    section("Supervisory investigations", "Event-level evidence retrieved directly from existing WP-6.3 analytical SQL. The reporting window filters the investigation output; it does not rewrite the underlying intelligence-engine history.")
    if not sql_mode():
        st.info("This page runs existing SQL investigation queries directly. Set OCB_DATA_SOURCE=sql and configure the local SQL Server connection to use it. No investigation CSVs are required.")
    else:
        investigation_options = {
            "Domestic cash-in → outbound remittance": "cashin_to_outbound_remittance_event",
            "SikaCredit loan disbursement → outbound remittance": "credit_to_outbound_remittance_event",
        }
        added_investigations = {
            "SikaCredit · November lending surge and debt recycling": {
                "question": "During SikaCredit's November 2025 lending surge, which customers exhibit elevated debt-recycling repayment-deficiency, reborrowing-rapidity and recurrence signals?",
                "trigger": "November 2025 lending jumped: principal rose from GHS 104,524 in October to GHS 210,646.56, while loans issued increased from 82 to 146.",
                "outputs": {"Customer debt-recycling signals": "sika_debt_recycling"},
            },
            "SikaCredit · first-time, repeat and frequent borrowers": {
                "question": "Was the November 2025 lending surge driven mainly by first-time borrowers, repeat borrowers, or frequent borrowing and short inter-loan intervals?",
                "trigger": "The November 2025 surge nearly doubled loan count: 82 loans in October versus 146 in November, alongside higher principal disbursement.",
                "outputs": {"November borrower behaviour": "sika_borrowing_surge"},
            },
            "SikaCredit · credit escalation": {
                "question": "Among customers receiving loans during the November 2025 surge, which exhibit credit-value escalation, escalation recurrence or credit-obligation signals?",
                "trigger": "November principal disbursements nearly doubled to GHS 210,646.56. The review checks whether larger loans and repayment obligations escalated for individual borrowers.",
                "outputs": {"Credit-escalation signals": "sika_credit_escalation"},
            },
            "Ananse · customers behind the December transaction surge": {
                "question": "Which customers contributed materially to Ananse's December 2025 transaction surge, and what existing TAE or cash-in → P2P → cash-out signals are associated with them?",
                "trigger": "Ananse's successful transactions rose from 37,913 in November to 53,173 in December 2025; value increased from about GHS 64.95M to GHS 91.41M.",
                "outputs": {
                    "Customers contributing to the surge": "ananse_surge_contributors",
                    "TAE transaction signals": "ananse_surge_tae",
                    "Cash-in → P2P → cash-out events": "ananse_cip2pco_events",
                    "Cash-in → P2P → cash-out customer summary": "ananse_cip2pco_summary",
                },
            },
            "Ananse · unsuccessful outcomes and overnight behaviour": {
                "question": "Are customers associated with failed or rejected Ananse transactions also exhibiting elevated overnight transaction rapidity or residual-value signals?",
                "trigger": "The source flagged customers with high failed/rejected counts or rates and compares them with overnight activity between 23:00 and 04:59.",
                "outputs": {
                    "Customers with disproportionate failed/rejected activity": "ananse_failed_rejected_customers",
                    "Overnight signals at event level": "ananse_overnight_events",
                    "Overnight signals by customer": "ananse_overnight_summary",
                },
            },
            "Oman Remit · FATF-origin exposure": {
                "question": "Which customers account for the highest volume and value of successful inbound remittances from FATF-flagged origins, and what failed or rejected activity is associated with them?",
                "trigger": "Oman Remit's origin-risk monitor flagged inbound transfers from designated higher-risk origins; the review compares successful value with failed and rejected activity.",
                "outputs": {"Customer exposure and outcomes": "oman_fatf_customers"},
            },
            "SikaCredit · November loans followed by cash-outs": {
                "question": "Among customers receiving SikaCredit loans during the November 2025 surge, which exhibit loan-disbursement → Ananse cash-out sequences with elevated rapidity, amount-ratio or recurrence signals?",
                "trigger": "SikaCredit issued 146 loans worth GHS 210,646.56 in November 2025, up from 82 loans worth GHS 104,524 in October; the review traces subsequent cash-outs.",
                "outputs": {
                    "Customers contributing to the lending surge": "sika_lending_surge_contributors",
                    "Loan → cash-out events": "sika_loan_cashout_events",
                    "Loan → cash-out customer summary": "sika_loan_cashout_summary",
                    "Debt-recycling and cash-out overlap": "sika_recycling_cashout_overlap",
                },
            },
            "Oman Remit · FATF-flagged remittance-to-cash-out sequences": {
                "question": "Which FATF-flagged Oman Remit remittance-to-cash-out sequences during Q4 2025 also exhibit TAE transaction-type amount anomalies in the associated Ananse cash-outs?",
                "trigger": "Q4 2025 inbound remittance value reached GHS 1,300,618.46, up GHS 217,678.44 quarter-on-quarter; the review traces flagged-origin funds to cash-outs.",
                "outputs": {
                    "FATF-flagged remittance → cash-out events": "oman_fatf_remittance_cashout",
                    "Events with TAE amount anomalies": "oman_fatf_cashout_tae",
                },
            },
            "Oman Remit · inbound remittance followed by Ananse P2P": {
                "question": "Among customers contributing to the December 2025 increase in inbound remittances, which exhibit the existing inbound remittance → Ananse P2P redistribution signals?",
                "trigger": "Inbound remittance value rose 62.824% from November to December 2025; the review checks whether flagged-origin funds were followed by Ananse P2P transfers.",
                "outputs": {
                    "Inbound remittance → P2P events": "remittance_to_p2p_events",
                    "Customer signal summary": "remittance_to_p2p_summary",
                },
            },
            "SikaCredit · inbound remittance followed by loan repayment": {
                "question": "Which inbound Oman Remit funds were associated with SikaCredit loan repayments during February 2025, following the decline in repayment value?",
                "trigger": "SikaCredit repayment value fell from GHS 30,355.61 in January to GHS 22,165.32 in February 2025, a drop of about 27%; the review checks associated inbound remittances.",
                "outputs": {
                    "Inbound remittance → repayment events": "remittance_to_repayment_events",
                    "Customer signal summary": "remittance_to_repayment_summary",
                },
            },
        }
        investigation_notes = {
            "cashin_to_outbound_remittance_event": {
                "question": "Did successful outbound remittances follow domestic Ananse cash-ins closely enough, and with enough value correspondence or repeated remittance behaviour, to merit review?",
                "trigger": "Oman Remit's outbound remittance value rose from GHS 274,048.05 to GHS 417,456.75 in Q4 2024 (+52.33%); this review checks cash-ins shortly before those transfers.",
                "scores": [
                    ("Funding/remittance rapidity", "Measures the time from a domestic cash-in to the first following successful outbound remittance in that cash-in window; shorter-than-usual intervals score higher."),
                    ("Value correspondence", "Compares each outbound remittance amount with its associated cash-in amount. Higher remittance-to-cash-in ratios score more strongly against the population; this does not prove direct funding."),
                    ("Recurrence", "Measures the interval between the two outbound remittances in successive qualifying cash-in → remittance cycles; shorter intervals score higher."),
                ],
                "trigger_window": ("2024-10-01", "2025-01-01"),
            },
            "credit_to_outbound_remittance_event": {
                "question": "Did successful outbound remittances follow SikaCredit loan disbursements, with timing, value correspondence or repeated remittance behaviour that merits review?",
                "trigger": "Oman Remit's outbound remittance value rose 52.33% in Q4 2024 (GHS 274,048.05 to GHS 417,456.75); five credit-to-remittance events were found in that quarter.",
                "scores": [
                    ("Credit/remittance rapidity", "Measures the time from loan disbursement to the first following successful outbound remittance in that loan window; shorter-than-usual intervals score higher."),
                    ("Value correspondence", "Compares each outbound remittance amount with the associated loan principal. Higher remittance-to-principal ratios score more strongly against the population; this does not prove direct funding."),
                    ("Remittance recurrence", "Measures the interval between the two outbound remittances across successive qualifying loan → remittance sequences; shorter intervals score higher."),
                ],
                "trigger_window": ("2024-10-01", "2025-01-01"),
            },
        }
        with st.container(border=True):
            st.markdown('<div class="ocb-card-kicker">Supervisory workbench</div>', unsafe_allow_html=True)
            st.caption("Choose an investigative question to review its trigger, reporting window, signals and supporting evidence.")
            chosen_label = st.selectbox("Investigation question", list(investigation_options) + list(added_investigations), key="investigation_question")
        if chosen_label in added_investigations:
            details = added_investigations[chosen_label]
            st.markdown("#### Investigation question")
            st.write(details["question"])
            st.markdown("**Trigger event**")
            st.info(details["trigger"])
            # Give every added investigation the same date controls and visible
            # trigger context as the original two investigations.
            investigation_context = {
                "SikaCredit · November lending surge and debt recycling": ("sika", (date(2025, 11, 1), date(2025, 11, 30)), [
                    ("Repayment deficiency", "Shows the share of the previous loan's principal still unpaid when the next loan was issued; higher deficiency relative to other qualifying cases scores higher."),
                    ("Reborrowing rapidity", "Measures the time from a loan to the next loan while the previous loan still has unpaid principal; shorter-than-usual delays score higher."),
                    ("Debt-recycling recurrence", "Measures the gap from the second loan in one sequence to the third loan in the next qualifying sequence. Both transitions must involve a new loan taken while principal on the previous loan is still unpaid. Shorter gaps mean qualifying debt recycling repeats sooner."),
                ]),
                "SikaCredit · first-time, repeat and frequent borrowers": ("sika", (date(2025, 11, 1), date(2025, 11, 30)), [
                    ("First-time / repeat", "First-time means no earlier loan appears in the available history; repeat means a prior loan is recorded."),
                    ("Monthly borrowing frequency", "Counts loans issued to each borrower in the selected month; it is not a customer count."),
                    ("Reborrowing rapidity", "Measures the time from a loan to the next loan while the previous loan still has unpaid principal; shorter-than-usual delays score higher."),
                ]),
                "SikaCredit · credit escalation": ("sika", (date(2025, 11, 1), date(2025, 11, 30)), [
                    ("Credit-value escalation", "Compares each loan with the customer's historical median loan size for the preceding observed lending year; a larger positive increase scores higher."),
                    ("Escalation recurrence", "Measures how quickly loans that qualify for credit-value escalation recur. Ordinary loans between qualifying increases do not count as escalation events."),
                    ("Strike 1 · before maturity", "A later loan was taken before the previous loan's due date, while that earlier loan still had an unpaid balance."),
                    ("Strike 2 · at maturity", "The previous loan still had an unpaid balance on its contractual maturity date."),
                    ("Strike 3 · after maturity", "The previous loan remained unpaid at maturity, and the customer took another loan after that due date."),
                ]),
                "Ananse · customers behind the December transaction surge": ("ananse", (date(2025, 12, 1), date(2025, 12, 31)), [
                    ("Surge contribution", "Shows each customer's change in transaction count and value from the previous month."),
                    ("Amount and velocity scores", "Amount compares a transaction with its transaction-type baseline; velocity measures the time between consecutive transactions and scores unusually short intervals."),
                    ("Cash-in → P2P → cash-out", "Tracks the three ordered transactions. Recurrence measures the gap from completing one qualifying sequence at cash-out to starting the next at cash-in; shorter gaps score higher."),
                ]),
                "Ananse · unsuccessful outcomes and overnight behaviour": ("ananse", (date(2025, 12, 1), date(2025, 12, 31)), [
                    ("Failed / rejected count and rate", "Count shows failed and rejected attempts; the rate is their combined share of all transaction attempts in the period."),
                    ("Overnight rapidity", "Measures the gap between consecutive transactions within the same overnight period (23:00–04:59); shorter-than-usual gaps score higher."),
                    ("Overnight residual value", "Compares that customer's overnight transaction total with their usual overnight-value baseline; only a positive excess receives a positive score."),
                ]),
                "Oman Remit · FATF-origin exposure": ("oman", (date(2025, 12, 1), date(2025, 12, 31)), [
                    ("Origin-risk flag", "A time-aware yes/no marker: it is set when the origin country met the source's risk rule on the remittance date."),
                    ("Count and successful value", "Counts flagged-origin transfers and sums the value of those that completed successfully."),
                    ("Failed / rejected outcomes", "Separate unsuccessful attempts shown for context; they are not included in successful remittance value."),
                ]),
                "SikaCredit · November loans followed by cash-outs": ("sika", (date(2025, 11, 1), date(2025, 11, 30)), [
                    ("Loan-to-cash-out rapidity", "Measures the time from loan disbursement to the first matched cash-out; shorter-than-usual delays score higher."),
                    ("Cash-out / loan ratio", "Divides the matched cash-out amount by loan principal. Higher ratios relative to the population score higher; a ratio above one does not prove that the loan funded the cash-out."),
                    ("Recurrence", "Measures the interval from completing one matched sequence at cash-out to starting the next at loan disbursement; shorter intervals score higher."),
                ]),
                "Oman Remit · FATF-flagged remittance-to-cash-out sequences": ("oman", (date(2025, 10, 1), date(2025, 12, 31)), [
                    ("Origin-risk flag", "A time-aware yes/no marker set when the remittance origin met the source's risk rule on that transaction date."),
                    ("Remittance-to-cash-out", "Rapidity measures the time from remittance to matched cash-out. Amount relationship compares cash-out value with remittance value; it does not establish fund provenance. Recurrence measures the gap from completing one sequence at cash-out to initiating the next at remittance."),
                    ("TAE amount signal", "Compares a cash-out amount with the historical baseline for its transaction type; it is distinct from the remittance-to-cash-out amount relationship."),
                ]),
                "Oman Remit · inbound remittance followed by Ananse P2P": ("oman", (date(2025, 12, 1), date(2025, 12, 31)), [
                    ("Rapidity", "Measures the time from inbound remittance receipt to the first following successful P2P transfer; shorter intervals score higher."),
                    ("Value correspondence", "Compares the matched P2P amount with the inbound remittance amount. Higher P2P-to-remittance ratios relative to the population score higher; this does not prove direct funding."),
                    ("Recurrence", "Measures the interval between completion of one remittance-to-P2P sequence and initiation of the next; shorter intervals score higher."),
                ]),
                "SikaCredit · inbound remittance followed by loan repayment": ("sika", (date(2025, 2, 1), date(2025, 2, 28)), [
                    ("Rapidity", "Measures the time from inbound remittance receipt to the first following loan repayment; shorter intervals score higher."),
                    ("Value correspondence", "Compares total loan repayments in the sequence with the inbound remittance amount. Higher repayment-to-remittance ratios relative to the population score higher; this does not prove direct funding."),
                    ("Recurrence", "Measures the interval between completion of one remittance-to-repayment sequence and initiation of the next; shorter intervals score higher."),
                ]),
            }
            institution, default_window, score_notes = investigation_context[chosen_label]
            selected_window = st.date_input("Investigation reporting window", value=default_window, key=f"window_{chosen_label}")
            if not isinstance(selected_window, tuple) or len(selected_window) != 2:
                st.warning("Select both a start date and an end date.")
            elif selected_window[0] > selected_window[1]:
                st.error("Invalid reporting window: the start date must be on or before the end date.")
            else:
                start_date, end_date = selected_window
                end_exclusive = end_date + timedelta(days=1)
                if start_date < date(2023, 1, 1) or end_date > date(2025, 12, 31):
                    st.error("Choose dates within the available event-data period (2023-01-01 to 2025-12-31).")
                else:
                    st.caption(f"Selected inclusive reporting window: {start_date.isoformat()} to {end_date.isoformat()}. The chart shows available monthly activity and highlights months touched by this window.")
                    st.caption("Event outputs use the exact dates selected where the source provides event timestamps. Monthly source indicators cover the complete months touched by the selected dates.")
                    if chosen_label == "Ananse · unsuccessful outcomes and overnight behaviour":
                        trigger_df = A["ananse_outcomes"].copy()
                        if {"failed_transactions", "rejected_transactions"}.issubset(trigger_df.columns):
                            trigger_df["unsuccessful_transactions"] = trigger_df["failed_transactions"].fillna(0) + trigger_df["rejected_transactions"].fillna(0)
                        count_col, value_col = "unsuccessful_transactions", "overall_unsuccessful_rate"
                        metric_titles = ("Failed + rejected transactions", "Unsuccessful transaction rate (%)")
                        chart_colors = (AMBER, CRIMSON)
                        chart_formats = (",d", ".1f")
                        trigger_title = "Ananse · unsuccessful outcomes"
                    elif chosen_label == "SikaCredit · inbound remittance followed by loan repayment":
                        trigger_df = S["sika_monthly"].copy()
                        count_col, value_col = "repayment_count", "principal_repaid"
                        metric_titles = ("Loan repayments", "Principal repaid (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "SikaCredit · repayments"
                    elif chosen_label == "Oman Remit · FATF-origin exposure":
                        trigger_df = O["oman_fatf_monthly_trigger"].copy()
                        count_col, value_col = "flagged_inbound_count", "flagged_successful_value"
                        metric_titles = ("Flagged inbound remittances", "Successful flagged value (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "Oman Remit · FATF-flagged inbound activity"
                    elif chosen_label in {"Oman Remit · FATF-flagged remittance-to-cash-out sequences", "Oman Remit · inbound remittance followed by Ananse P2P"}:
                        trigger_df = O["oman_type"].copy()
                        if "remittance_type" in trigger_df.columns:
                            trigger_df = trigger_df.loc[trigger_df["remittance_type"].astype(str).str.lower().eq("remittance_received")].copy()
                        trigger_df = trigger_df.groupby("year_month", as_index=False).agg(total_remittance_count=("total_remittance_count", "sum"), total_remittance_value=("total_remittance_value", "sum")) if not trigger_df.empty else trigger_df
                        count_col, value_col = "total_remittance_count", "total_remittance_value"
                        metric_titles = ("Inbound remittance count", "Inbound remittance value (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "Oman Remit · inbound remittances"
                    elif institution == "ananse":
                        trigger_df = A["ananse_monthly"].copy()
                        count_col, value_col = "total_transaction_count", "total_transaction_value"
                        metric_titles = ("Successful transaction count", "Successful transaction value (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "Ananse · successful transaction activity"
                    elif institution == "sika":
                        trigger_df = S["sika_monthly"].copy()
                        count_col, value_col = "loans_disbursed_count", "principal_disbursed"
                        metric_titles = ("Loans disbursed", "Principal disbursed (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "SikaCredit · lending activity"
                    else:
                        trigger_df = O["oman_monthly"].copy()
                        count_col, value_col = "total_remittance_count", "total_remittance_value"
                        metric_titles = ("Remittance count", "Remittance value (GHS)")
                        chart_colors = (CYAN, PURPLE)
                        chart_formats = (",d", "~s")
                        trigger_title = "Oman Remit · remittance activity"
                    if not trigger_df.empty and "year_month" in trigger_df.columns:
                        trigger_df = trigger_df.copy()
                        trigger_df["year_month"] = trigger_df["year_month"].astype(str).str[:7]
                        first_month = pd.Timestamp(start_date).to_period("M").strftime("%Y-%m")
                        last_month = pd.Timestamp(end_date).to_period("M").strftime("%Y-%m")
                        trigger_df["selected_window"] = trigger_df["year_month"].between(first_month, last_month)
                        c1, c2 = st.columns(2)
                        for target, column, title, color, fmt in [
                            (c1, count_col, f"{trigger_title} · {metric_titles[0]}", chart_colors[0], chart_formats[0]),
                            (c2, value_col, f"{trigger_title} · {metric_titles[1]}", chart_colors[1], chart_formats[1]),
                        ]:
                            if column in trigger_df.columns:
                                chart = alt.Chart(trigger_df).mark_bar(cornerRadiusEnd=5).encode(
                                    x=alt.X("year_month:O", sort=None, title="Month"),
                                    y=alt.Y(f"{column}:Q", title=column.replace("_", " "), axis=alt.Axis(format=fmt)),
                                    color=alt.Color("selected_window:N", scale=alt.Scale(domain=[True, False], range=[color, "#334256"]), legend=None),
                                    tooltip=[alt.Tooltip("year_month:O", title="Month"), alt.Tooltip(f"{column}:Q", title=column.replace("_", " "), format=fmt)],
                                ).properties(
                                    title=alt.TitleParams(text=title, anchor="start", fontSize=14, fontWeight="bold", offset=12),
                                    height=250,
                                    padding={"top": 20, "left": 8, "right": 8, "bottom": 8},
                                ).configure(
                                    background=PANEL,
                                    axis={"labelColor": MUTED, "titleColor": TEXT, "gridColor": GRID},
                                    title={"color": TEXT, "anchor": "start", "fontSize": 14, "fontWeight": "bold", "offset": 12},
                                )
                                target.altair_chart(chart, use_container_width=True, key=f"inv_{institution}_{column}_{chosen_label}")
                    with st.expander("What the scores and measures mean", expanded=True):
                        for score_title, score_description in score_notes:
                            st.markdown(f"**{score_title}.** {score_description}")
                        st.caption("These are analytical indicators for supervisory review, not proof of misuse or automatic regulatory findings.")
            outputs = details["outputs"]
            if len(outputs) > 1:
                output_label = st.selectbox("Evidence view", list(outputs), key=f"investigation_output_{chosen_label}")
            else:
                output_label = next(iter(outputs))
                st.caption(f"Evidence view: {output_label}")
            query_name = outputs[output_label]
            try:
                with st.spinner("Retrieving investigation evidence from SQL Server…"):
                    if isinstance(selected_window, tuple) and len(selected_window) == 2 and selected_window[0] >= date(2023, 1, 1) and selected_window[1] <= date(2025, 12, 31):
                        evidence = run_investigation_query(query_name, selected_window[0].isoformat(), (selected_window[1] + timedelta(days=1)).isoformat())
                    else:
                        evidence = pd.DataFrame()
                if evidence.empty:
                    st.info("No rows were returned for this valid reporting window, or the selected window is incomplete/outside the available period.")
                else:
                    metric_cols = st.columns(2)
                    metric_cols[0].metric("Evidence rows", integer(len(evidence)))
                    metric_cols[1].metric("Distinct customers", integer(evidence["ocb_customer_id"].nunique()) if "ocb_customer_id" in evidence.columns else "—")
                    st.caption("All qualifying rows for this reporting window are returned; the investigation queries do not apply a top-50 cutoff.")
                    st.dataframe(evidence, use_container_width=True, hide_index=True, height=520)
            except Exception as exc:
                st.error(f"The investigation query failed: {exc}")
        else:
            query_name = investigation_options[chosen_label]
            details = investigation_notes[query_name]
            st.markdown("#### Investigation question")
            st.write(details["question"])
            st.markdown("**Trigger event**")
            st.info(details["trigger"])
            default_window = (date(2024, 10, 1), date(2024, 12, 31))
            selected_window = st.date_input("Investigation reporting window", value=default_window, key=f"window_{query_name}")
            if not isinstance(selected_window, tuple) or len(selected_window) != 2:
                st.warning("Select both a start date and an end date.")
            elif selected_window[0] > selected_window[1]:
                st.error("Invalid reporting window: the start date must be on or before the end date.")
            else:
                start_date, end_date = selected_window
                end_exclusive = end_date + timedelta(days=1)
                st.caption("Available event data: 2023-01-01 to 2025-12-31. The selected reporting window filters returned event rows only. Score engines retain their existing full-history calculations; the trigger period is a starting point, not a date cap.")
                if start_date < date(2023, 1, 1) or end_date > date(2025, 12, 31):
                    st.error("Selected dates are outside the available event-data period (2023-01-01 to 2025-12-31). Choose a window entirely within these boundaries.")
                st.caption(f"Selected inclusive reporting window: {start_date.isoformat()} to {end_date.isoformat()}")
    
                # Trigger context chart: show full available monthly outbound-remittance history and highlight the chosen window.
                trigger = O.get("oman_outbound_monthly_trigger", pd.DataFrame()).copy()
                if not trigger.empty:
                    trigger["month_date"] = pd.to_datetime(trigger["year_month"] + "-01", errors="coerce")
                    trigger["selected_window"] = trigger["month_date"].between(pd.Timestamp(start_date).to_period("M").to_timestamp(), pd.Timestamp(end_date).to_period("M").to_timestamp())
                    chart_left, chart_right = st.columns(2)
                    with chart_left:
                        fig = go.Figure()
                        fig.add_trace(go.Bar(x=trigger["year_month"], y=trigger["outbound_remittance_count"], name="Successful outbound remittances", marker_color=[CYAN if v else "#334256" for v in trigger["selected_window"]], hovertemplate="%{x}<br>Successful outbound remittances: %{y:,}<extra></extra>"))
                        fig.update_layout(title="Oman Remit · outbound remittance volume", xaxis_title="Month", yaxis_title="Successful remittances")
                        chart_theme(fig, 330)
                        st.plotly_chart(fig, use_container_width=True, key="ocb_investigation_outbound_volume", config={"displaylogo": False, "responsive": True})
                    with chart_right:
                        fig = go.Figure()
                        fig.add_trace(go.Bar(x=trigger["year_month"], y=trigger["outbound_remittance_value"], name="Successful outbound value", marker_color=[PURPLE if v else "#334256" for v in trigger["selected_window"]], hovertemplate="%{x}<br>Successful outbound value: GHS %{y:,.2f}<extra></extra>"))
                        fig.update_layout(title="Oman Remit · outbound remittance value", xaxis_title="Month", yaxis_title="Successful value (GHS)")
                        fig.update_yaxes(tickprefix="GHS ", tickformat="~s")
                        chart_theme(fig, 330)
                        st.plotly_chart(fig, use_container_width=True, key="ocb_investigation_outbound_value", config={"displaylogo": False, "responsive": True})
                    if query_name == "cashin_to_outbound_remittance_event":
                        st.caption("Original trigger period: Q4 2024. The highlighted months follow the selected reporting window; the full history is shown to help compare other periods.")
                    else:
                        st.caption("Original trigger period: Q4 2024; Q4 2025 was supplementary context. The highlighted months follow the selected reporting window; the full history remains visible.")
    
                with st.expander("What the scores mean", expanded=True):
                    for score_title, score_description in details["scores"]:
                        st.markdown(f"**{score_title}.** {score_description}")
                    st.caption("Score definitions follow the existing OCB intelligence-engine intent. A positive score is an analytical signal, not proof of misuse or a regulatory finding.")
    
                if start_date >= date(2023, 1, 1) and end_date <= date(2025, 12, 31):
                    try:
                        with st.spinner("Retrieving investigation evidence from SQL Server…"):
                            evidence = run_investigation_query(query_name, start_date.isoformat(), end_exclusive.isoformat())
                        if evidence.empty:
                            st.info("No qualifying events were returned for this investigation window.")
                        else:
                            m1, m2 = st.columns(2)
                            m1.metric("Qualifying event rows", integer(len(evidence)))
                            m2.metric("Distinct customers", integer(evidence["ocb_customer_id"].nunique()) if "ocb_customer_id" in evidence.columns else "—")
                            st.caption("One row should represent one qualifying successful outbound remittance event. Signal columns retain the source query's definitions.")
                            labels = {
                                "ocb_customer_id": "Customer ID", "cash_in_id": "Cash-in event ID", "cash_in_timestamp": "Cash-in timestamp",
                                "loan_id": "Loan ID", "loan_timestamp": "Loan timestamp", "remittance_id": "Remittance event ID",
                                "remittance_timestamp": "Remittance timestamp", "cashin_remittance_delay_minutes": "Cash-in → remittance delay (min)",
                                "funding_remittance_rapidity_score": "Funding/remittance rapidity score", "funding_remittance_ratio": "Funding/remittance value ratio",
                                "funding_remittance_value_correspondence_score": "Funding/remittance value correspondence score", "recurrence_gap_minutes": "Remittance recurrence gap (min)",
                                "funding_remittance_recurrence_score": "Remittance recurrence score", "credit_to_remittance_rapidity_score": "Credit/remittance rapidity score",
                                "credit_to_remittance_value_correspondence_score": "Credit/remittance value correspondence score", "credit_to_remittance_recurrence_score": "Remittance recurrence score",
                            }
                            evidence = evidence.rename(columns=labels)
                            st.dataframe(evidence, use_container_width=True, hide_index=True, height=520)
                    except Exception as exc:
                        st.error(f"The investigation query failed: {exc}")


st.markdown("---")
st.caption("OCB is a synthetic supervisory sandbox. Monitoring and intelligence outputs are analytical evidence, not automatic regulatory findings. Investigation evidence is retrieved from existing SQL sources; it is not converted to CSV as a prerequisite.")
