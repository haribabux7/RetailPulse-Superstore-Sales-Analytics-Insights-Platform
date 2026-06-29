"""
Dashboard.py — Superstore Sales Analytics (Streamlit)
=====================================================
Run:  streamlit run Dashboard.py

Features
--------
- Upload CSV (or use bundled Cleaned_Data.csv)
- KPI cards: Revenue, Profit, Orders, Customers, AOV, Margin
- Filters: Date range, Region, Category, Segment
- Interactive charts: Revenue trend, Category analysis, Correlation heatmap,
  Top performers, Geographic analysis
- Download filtered data + auto-generated insights
- Dynamic narrative insights
"""
import io
from pathlib import Path

import numpy as np
import pandas as pd
import plotly.express as px
import streamlit as st

st.set_page_config(page_title="Superstore Analytics", page_icon="📊", layout="wide")

DEFAULT = Path(__file__).resolve().parents[1] / "Dataset" / "Cleaned_Data.csv"

# US state -> 2-letter code for choropleth
STATE_CODES = {
    'Alabama':'AL','Arizona':'AZ','Arkansas':'AR','California':'CA','Colorado':'CO',
    'Connecticut':'CT','Delaware':'DE','District of Columbia':'DC','Florida':'FL','Georgia':'GA',
    'Idaho':'ID','Illinois':'IL','Indiana':'IN','Iowa':'IA','Kansas':'KS','Kentucky':'KY',
    'Louisiana':'LA','Maine':'ME','Maryland':'MD','Massachusetts':'MA','Michigan':'MI',
    'Minnesota':'MN','Mississippi':'MS','Missouri':'MO','Montana':'MT','Nebraska':'NE',
    'Nevada':'NV','New Hampshire':'NH','New Jersey':'NJ','New Mexico':'NM','New York':'NY',
    'North Carolina':'NC','North Dakota':'ND','Ohio':'OH','Oklahoma':'OK','Oregon':'OR',
    'Pennsylvania':'PA','Rhode Island':'RI','South Carolina':'SC','South Dakota':'SD',
    'Tennessee':'TN','Texas':'TX','Utah':'UT','Vermont':'VT','Virginia':'VA','Washington':'WA',
    'West Virginia':'WV','Wisconsin':'WI','Wyoming':'WY'}


@st.cache_data
def load(file=None) -> pd.DataFrame:
    df = pd.read_csv(file) if file is not None else pd.read_csv(DEFAULT)
    for c in ("order_date", "ship_date"):
        if c in df.columns:
            df[c] = pd.to_datetime(df[c], errors="coerce")
    return df


def money(x): return f"${x:,.0f}"


# ----------------------------------------------------------------- Sidebar
st.sidebar.title("📊 Controls")
up = st.sidebar.file_uploader("Upload CSV", type="csv")
df = load(up)
st.sidebar.caption(f"Loaded **{len(df):,}** rows")

if "order_date" in df.columns and df["order_date"].notna().any():
    dmin, dmax = df["order_date"].min(), df["order_date"].max()
    dr = st.sidebar.date_input("Date range", (dmin, dmax), min_value=dmin, max_value=dmax)
    if isinstance(dr, (list, tuple)) and len(dr) == 2:
        df = df[(df["order_date"] >= pd.to_datetime(dr[0])) & (df["order_date"] <= pd.to_datetime(dr[1]))]

def msel(col, label):
    if col in df.columns:
        opts = sorted(df[col].dropna().unique())
        chosen = st.sidebar.multiselect(label, opts, default=opts)
        return df[col].isin(chosen)
    return pd.Series(True, index=df.index)

mask = msel("region", "Region") & msel("category", "Category") & msel("segment", "Segment")
df = df[mask]

if df.empty:
    st.warning("No data for the selected filters.")
    st.stop()

# ----------------------------------------------------------------- Header
st.title("🛒 Superstore Sales — Executive Analytics Dashboard")
st.caption("Interactive Streamlit dashboard | filter, explore and export")

# ----------------------------------------------------------------- KPIs
rev = df["sales"].sum()
profit = df["profit"].sum() if "profit" in df else 0
orders = df["order_id"].nunique()
custs = df["customer_id"].nunique()
aov = rev / orders if orders else 0
margin = (profit / rev * 100) if rev else 0

c = st.columns(6)
c[0].metric("Total Revenue", money(rev))
c[1].metric("Total Profit", money(profit))
c[2].metric("Orders", f"{orders:,}")
c[3].metric("Customers", f"{custs:,}")
c[4].metric("Avg Order Value", money(aov))
c[5].metric("Profit Margin", f"{margin:.1f}%")

st.divider()

# ----------------------------------------------------------------- Trend + Category
l, r = st.columns(2)
with l:
    st.subheader("📈 Revenue & Profit Trend")
    t = (df.assign(ym=df["order_date"].dt.to_period("M").astype(str))
           .groupby("ym").agg(Revenue=("sales", "sum"), Profit=("profit", "sum")).reset_index())
    fig = px.line(t, x="ym", y=["Revenue", "Profit"], markers=True)
    fig.update_layout(xaxis_title="", legend_title="", height=380)
    st.plotly_chart(fig, use_container_width=True)
with r:
    st.subheader("🗂️ Category Analysis")
    cat = df.groupby("category").agg(Revenue=("sales", "sum"), Profit=("profit", "sum")).reset_index()
    fig = px.bar(cat, x="category", y=["Revenue", "Profit"], barmode="group")
    fig.update_layout(xaxis_title="", legend_title="", height=380)
    st.plotly_chart(fig, use_container_width=True)

# ----------------------------------------------------------------- Top + Heatmap
l, r = st.columns(2)
with l:
    st.subheader("🏆 Top 10 Sub-Categories by Revenue")
    top = df.groupby("sub_category")["sales"].sum().sort_values().tail(10).reset_index()
    fig = px.bar(top, x="sales", y="sub_category", orientation="h")
    fig.update_layout(xaxis_title="Revenue", yaxis_title="", height=400)
    st.plotly_chart(fig, use_container_width=True)
with r:
    st.subheader("🔗 Correlation Heatmap")
    num = [c for c in ["sales", "quantity", "discount", "profit",
                       "profit_margin_pct", "unit_price", "shipping_days"] if c in df]
    fig = px.imshow(df[num].corr().round(2), text_auto=True,
                    color_continuous_scale="RdBu_r", zmin=-1, zmax=1)
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)

# ----------------------------------------------------------------- Geographic
st.subheader("🗺️ Geographic Analysis — Revenue by State")
geo = df.groupby("state")["sales"].sum().reset_index()
geo["code"] = geo["state"].map(STATE_CODES)
geo = geo.dropna(subset=["code"])
fig = px.choropleth(geo, locations="code", locationmode="USA-states", color="sales",
                    scope="usa", color_continuous_scale="Blues", labels={"sales": "Revenue"})
fig.update_layout(height=460)
st.plotly_chart(fig, use_container_width=True)

# ----------------------------------------------------------------- Dynamic insights
st.subheader("💡 Dynamic Insights")
best_cat = cat.loc[cat["Profit"].idxmax(), "category"]
worst_cat = cat.loc[cat["Profit"].idxmin(), "category"]
top_state = geo.loc[geo["sales"].idxmax(), "state"]
loss_pct = 100 * (df["profit"] < 0).mean()
st.markdown(
    f"""
- **{best_cat}** is the most profitable category; **{worst_cat}** is the weakest — rebalance the mix.
- **{top_state}** is the top revenue state — prioritise account & inventory investment there.
- **Average order value** is **{money(aov)}** at a **{margin:.1f}%** blended margin.
- **{loss_pct:.1f}%** of orders are unprofitable — tighten discount approval thresholds.
"""
)

# ----------------------------------------------------------------- Downloads
st.divider()
st.subheader("⬇️ Export")
d1, d2 = st.columns(2)
d1.download_button("Download filtered data (CSV)",
                   df.to_csv(index=False).encode(), "filtered_data.csv", "text/csv")
summary = io.StringIO()
summary.write("SUPERSTORE ANALYTICS — SUMMARY REPORT\n" + "=" * 40 + "\n")
summary.write(f"Revenue: {money(rev)}\nProfit: {money(profit)}\nOrders: {orders:,}\n")
summary.write(f"Customers: {custs:,}\nAOV: {money(aov)}\nMargin: {margin:.1f}%\n")
summary.write(f"Top profitable category: {best_cat}\nTop state: {top_state}\n")
summary.write(f"Unprofitable orders: {loss_pct:.1f}%\n")
d2.download_button("Download insights report (TXT)",
                   summary.getvalue(), "insights_report.txt", "text/plain")

st.caption("Built with Streamlit · Plotly · Pandas")
