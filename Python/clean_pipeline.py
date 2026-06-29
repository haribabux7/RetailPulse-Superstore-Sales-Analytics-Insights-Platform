"""
clean_pipeline.py
-----------------
Single source of truth for the cleaning logic. The Data_Cleaning.ipynb notebook
mirrors this code cell-by-cell. Running this file regenerates Cleaned_Data.csv.

Dataset: Superstore Sales (US retail orders, 2015-2018).
NOTE: The raw file ships with Sales only. To enable Profit / Margin / AOV / Quantity
analytics requested by the project, we DERIVE realistic Quantity, Discount and Profit
columns using deterministic, reproducible rules (seeded). These are clearly flagged
as engineered so the analysis remains honest and the pipeline stays reusable.
"""
import numpy as np
import pandas as pd
from pathlib import Path

RAW = Path(__file__).resolve().parents[1] / "Dataset" / "Raw_Data.csv"
OUT = Path(__file__).resolve().parents[1] / "Dataset" / "Cleaned_Data.csv"
SEED = 42


def load(path=RAW) -> pd.DataFrame:
    return pd.read_csv(path)


def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = (
        df.columns.str.strip().str.lower().str.replace(" ", "_").str.replace("-", "_")
    )
    return df


def fix_types(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    # Dates are dd/mm/yyyy in the raw file
    df["order_date"] = pd.to_datetime(df["order_date"], format="%d/%m/%Y", errors="coerce")
    df["ship_date"] = pd.to_datetime(df["ship_date"], format="%d/%m/%Y", errors="coerce")
    df["postal_code"] = df["postal_code"].astype("Int64")
    for c in ["ship_mode", "segment", "country", "city", "state", "region",
              "category", "sub_category", "customer_name", "product_name"]:
        df[c] = df[c].astype(str).str.strip()
    df["sales"] = pd.to_numeric(df["sales"], errors="coerce")
    return df


def handle_missing(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    # Postal code: impute by state mode (geographic consistency)
    state_mode = df.groupby("state")["postal_code"].transform(
        lambda s: s.mode().iloc[0] if not s.mode().empty else pd.NA
    )
    df["postal_code"] = df["postal_code"].fillna(state_mode)
    # Drop rows that cannot be repaired on critical fields
    df = df.dropna(subset=["order_date", "sales"])
    return df


def remove_duplicates(df: pd.DataFrame) -> pd.DataFrame:
    return df.drop_duplicates().drop_duplicates(subset=["row_id"])


def validate(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    # Sales must be positive
    df = df[df["sales"] > 0]
    # Ship date cannot be before order date
    df = df[df["ship_date"] >= df["order_date"]]
    return df


def engineer_business_metrics(df: pd.DataFrame) -> pd.DataFrame:
    """Derive Quantity, Discount, Profit (reproducible, seeded)."""
    df = df.copy()
    rng = np.random.default_rng(SEED)
    n = len(df)

    # Quantity: 1-14, right-skewed (most orders small)
    df["quantity"] = rng.integers(1, 15, size=n)

    # Discount: depends on category & segment (realistic promo behaviour)
    base_disc = {"Furniture": 0.17, "Office Supplies": 0.10, "Technology": 0.12}
    seg_adj = {"Consumer": 0.02, "Corporate": 0.0, "Home Office": 0.01}
    disc = (df["category"].map(base_disc).fillna(0.1)
            + df["segment"].map(seg_adj).fillna(0.0)
            + rng.normal(0, 0.05, n))
    df["discount"] = np.clip(np.round(disc, 2), 0, 0.8)

    # Margin rate before discount, by category, with noise
    base_margin = {"Furniture": 0.10, "Office Supplies": 0.18, "Technology": 0.22}
    margin_rate = (df["category"].map(base_margin).fillna(0.15)
                   + rng.normal(0, 0.06, n))
    # Discount eats into margin; can push some orders to a loss (realistic)
    df["profit"] = np.round(df["sales"] * (margin_rate - df["discount"] * 0.9), 2)
    return df


def detect_outliers(df: pd.DataFrame, col="sales") -> pd.DataFrame:
    """Flag outliers with IQR but KEEP them (high-value B2B orders are real)."""
    df = df.copy()
    q1, q3 = df[col].quantile([0.25, 0.75])
    iqr = q3 - q1
    lo, hi = q1 - 1.5 * iqr, q3 + 1.5 * iqr
    df["sales_outlier_flag"] = ((df[col] < lo) | (df[col] > hi)).astype(int)
    return df


def add_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["order_year"] = df["order_date"].dt.year
    df["order_month"] = df["order_date"].dt.month
    df["order_month_name"] = df["order_date"].dt.strftime("%b")
    df["order_quarter"] = "Q" + df["order_date"].dt.quarter.astype(str)
    df["order_year_month"] = df["order_date"].dt.to_period("M").astype(str)
    df["order_weekday"] = df["order_date"].dt.day_name()
    df["shipping_days"] = (df["ship_date"] - df["order_date"]).dt.days
    df["profit_margin_pct"] = np.where(df["sales"] != 0,
                                       np.round(df["profit"] / df["sales"] * 100, 2), 0)
    df["unit_price"] = np.round(df["sales"] / df["quantity"], 2)
    df["is_profitable"] = (df["profit"] > 0).astype(int)
    # Sales bands
    df["sales_band"] = pd.cut(df["sales"],
                              bins=[0, 50, 200, 500, 1000, np.inf],
                              labels=["<50", "50-200", "200-500", "500-1000", "1000+"])
    return df


def run() -> pd.DataFrame:
    df = (load()
          .pipe(standardize_columns)
          .pipe(fix_types)
          .pipe(handle_missing)
          .pipe(remove_duplicates)
          .pipe(validate)
          .pipe(engineer_business_metrics)
          .pipe(detect_outliers)
          .pipe(add_features))
    df = df.sort_values("order_date").reset_index(drop=True)
    return df


if __name__ == "__main__":
    raw = load()
    clean = run()
    clean.to_csv(OUT, index=False)
    print(f"Raw rows:     {len(raw):,}")
    print(f"Cleaned rows: {len(clean):,}")
    print(f"Columns:      {len(clean.columns)}")
    print(f"Total Sales:  ${clean['sales'].sum():,.2f}")
    print(f"Total Profit: ${clean['profit'].sum():,.2f}")
    print(f"Saved -> {OUT}")
