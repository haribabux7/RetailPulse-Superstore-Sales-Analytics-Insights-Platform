[6.md](https://github.com/user-attachments/files/29463105/6.md)
# RetailPulse — Superstore Sales Analytics & Insights Platform

**RetailPulse** is an end-to-end **sales analytics project** built on the classic US Superstore dataset (2015–2018). It combines a reproducible **Python data-cleaning pipeline**, a full **exploratory data analysis (EDA)** workflow, a **business-query SQL layer**, and an interactive **Streamlit dashboard** that turns ~10K raw transactions into decision-ready KPIs, visuals, and narrative insights.

The project was designed to demonstrate, in a single repository, the complete lifecycle of a real-world data role — ingest, clean, model, query, visualize, and communicate. Every artifact (notebook, script, SQL file, dashboard) is independently runnable and tells the same coherent story: *where is the business making money, where is it bleeding, and what should the next quarter focus on?*

Whether you are a recruiter scanning for portfolio depth, an analyst looking for a reusable cleaning template, or a stakeholder who just wants the numbers — RetailPulse is built to read clean, run fast, and ship insights you can act on.

---

## Overview

- **Purpose** — Convert raw, messy retail order data into a trustworthy analytical asset and an executive-grade dashboard.
- **Business value** — Surfaces unprofitable sub-categories, discount traps, regional underperformance, top customers, and shipping-time bottlenecks.
- **User benefits** — One-click KPIs (Revenue, Profit, Margin, AOV, Orders, Customers), filter-driven exploration, downloadable filtered slices, and auto-generated narrative insights.
- **Main functionality** — Reproducible cleaning pipeline → engineered analytical columns → SQL business queries → Jupyter EDA & visualization → Streamlit dashboard.

---

## Features

### Core Features
- ✅ Deterministic, seeded cleaning pipeline (`clean_pipeline.py`) — notebook mirrors it cell-for-cell
- ✅ Engineered analytical fields: `profit`, `profit_margin_pct`, `quantity`, `discount`, `shipping_days`, `sales_band`, `is_profitable`, `order_quarter`, `order_weekday`
- ✅ Full EDA notebook (univariate, bivariate, segment, time-series, outliers)
- ✅ Reusable visualization notebook (Matplotlib, Seaborn, Plotly)
- ✅ Business SQL layer (cleaning, EDA, and 20+ business queries)

### User Features
- ✅ Interactive **Streamlit dashboard** with KPI cards
- ✅ CSV upload (or use bundled cleaned dataset)
- ✅ Filters: date range, region, category, segment
- ✅ Revenue trend, category breakdown, correlation heatmap
- ✅ Top customers / products / states leaderboards
- ✅ US state-level **choropleth** geographic analysis
- ✅ Dynamic narrative insights generated from current filter state
- ✅ One-click download of filtered data

### Admin / Analyst Features
- ✅ Single source of truth for cleaning logic (DRY)
- ✅ Reproducible outputs (fixed random seed)
- ✅ Outlier flagging (`sales_outlier_flag`)
- ✅ Schema standardization (snake_case, typed dates, Int64 postal codes)

### Advanced Features
- ✅ Profit & margin synthesis from sales-only raw data (transparent rules)
- ✅ Time intelligence: YoY, QoQ, MoM, weekday seasonality
- ✅ Plotly interactive charts with hover + zoom
- ✅ Streamlit caching (`@st.cache_data`) for sub-second reloads

### Security Features
- ✅ No PII beyond synthetic customer names from the public dataset
- ✅ Read-only file handling in the dashboard
- ✅ Environment-variable driven DB connections (no hardcoded creds)
- ✅ Input validation on uploaded CSVs (type coercion, error-safe parsing)

---

## Tech Stack

### Frontend
- Streamlit 1.30+ (UI, layout, widgets)
- Plotly Express (interactive charts)
- HTML/CSS via Streamlit theming

### Backend
- Python 3.10+
- Pandas 2.x (data manipulation)
- NumPy 1.24+ (vectorized ops)
- Custom ETL pipeline (`clean_pipeline.py`)

### Database
- CSV-based analytical store (Cleaned_Data.csv)
- SQL scripts compatible with **PostgreSQL** and **MySQL**
- Optional: SQLite for local query testing

### Data Analytics
- Jupyter Notebook (EDA, cleaning, visualization)
- Matplotlib, Seaborn (statistical visuals)
- Plotly + Kaleido (interactive + static export)
- openpyxl (Excel I/O)

### DevOps & Deployment
- Streamlit Community Cloud (primary)
- Docker (optional containerization)
- GitHub Actions (lint + notebook execution CI)

### Development Tools
- VS Code, JupyterLab
- Git & GitHub
- `pytest` for pipeline unit tests
- `nbformat` for notebook validation

---

## Architecture

```text
        ┌──────────────────┐
        │   Raw_Data.csv   │   (Superstore, dd/mm/yyyy)
        └────────┬─────────┘
                 │
                 ▼
        ┌──────────────────┐         ┌───────────────────────┐
        │ clean_pipeline.py│◀───────▶│ Data_Cleaning.ipynb   │
        │   (single SOT)   │         └───────────────────────┘
        └────────┬─────────┘
                 │  standardize → types → derive → flag
                 ▼
        ┌──────────────────┐
        │ Cleaned_Data.csv │  (32 analytical columns)
        └────────┬─────────┘
                 │
   ┌─────────────┼──────────────────────────┐
   ▼             ▼                          ▼
┌────────┐  ┌─────────────┐         ┌──────────────────┐
│  SQL   │  │  EDA + Viz  │         │  Dashboard.py    │
│ layer  │  │  notebooks  │         │  (Streamlit UI)  │
└────────┘  └─────────────┘         └──────────────────┘
```

- **System Architecture** — Layered: ingest → clean → analyze → present.
- **Application Flow** — CSV in → pipeline transforms → analytical CSV out → consumed by SQL, notebooks, and Streamlit independently.
- **Client–Server Communication** — Streamlit serves the rendered UI; pandas operates server-side; Plotly figures are serialized to the browser.
- **Database Relationships** — Order ↔ Customer (many-to-one), Order ↔ Product (many-to-one), Product → Category → Sub-Category (hierarchical).

---

## Project Structure

```
retailpulse/
│
├── Data-Analytics-Project/
│   ├── Dataset/
│   │   ├── Raw_Data.csv              # Original Superstore export
│   │   └── Cleaned_Data.csv          # Pipeline output (analysis-ready)
│   │
│   ├── Python/
│   │   ├── clean_pipeline.py         # Reproducible ETL (single source of truth)
│   │   ├── Dashboard.py              # Streamlit app
│   │   ├── Data_Cleaning.ipynb       # Mirrors clean_pipeline.py
│   │   ├── EDA.ipynb                 # Exploratory analysis
│   │   ├── Data_Visualization.ipynb  # Chart gallery
│   │   └── Requirements.txt          # Python dependencies
│   │
│   └── SQL/
│       ├── Data_Cleaning.sql         # SQL-side cleaning equivalent
│       ├── EDA.sql                   # Profiling queries
│       └── Business_Queries.sql      # 20+ revenue/profit/customer queries
│
├── docs/
│   └── screenshots/                  # README screenshots
├── tests/                            # Pipeline & query tests
├── scripts/                          # Helper CLI scripts
├── .env.example
└── README.md
```

- **Dataset/** — Raw input + cleaned analytical output.
- **Python/** — All Python code: pipeline, dashboard, notebooks.
- **SQL/** — Database-side cleaning, EDA, and business queries.
- **docs/** — Screenshots and supporting docs.
- **tests/** — Unit tests for cleaning functions.
- **scripts/** — Utility scripts (re-generate cleaned CSV, export charts).

---

## Installation

### Prerequisites
- Python 3.10 or higher
- pip / venv (or conda)
- Git
- (Optional) PostgreSQL or MySQL for the SQL layer

### Clone Repository
```bash
git clone https://github.com/haribabux7/retailpulse.git
cd retailpulse/Data-Analytics-Project
```

### Install Dependencies
```bash
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r Python/Requirements.txt
```

### Regenerate Cleaned Dataset (optional)
```bash
python Python/clean_pipeline.py
```

### Configure Environment Variables
Copy `.env.example` to `.env` and fill in the values described below.

### Start Development Server (Dashboard)
```bash
streamlit run Python/Dashboard.py
```
Open <http://localhost:8501>.

### Launch Notebooks
```bash
jupyter lab
```

---

## Environment Variables

```env
# App
PORT=8501
APP_ENV=development

# Database (optional — only if loading into SQL)
DATABASE_URL=postgresql://user:pass@localhost:5432/retailpulse
MONGO_URI=

# Security
JWT_SECRET=replace-me
API_KEY=replace-me

# Email (optional — for scheduled report delivery)
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=you@example.com
EMAIL_PASSWORD=app-password
```

| Variable | Description |
|---|---|
| `PORT` | Port the Streamlit app binds to. |
| `APP_ENV` | `development` / `production` toggle. |
| `DATABASE_URL` | SQLAlchemy URL for the relational store. |
| `MONGO_URI` | Optional Mongo connection string for raw event ingestion. |
| `JWT_SECRET` | Secret used if you bolt on auth. |
| `API_KEY` | Key for any external enrichment API. |
| `EMAIL_*` | SMTP credentials for emailing reports. |

---

## Usage

1. **Analyst workflow** — Open `EDA.ipynb`, run top-to-bottom for profiling, then `Data_Visualization.ipynb` for chart-ready outputs.
2. **Business workflow** — Open the Streamlit dashboard, pick a date range and region, read the auto-generated insights box, export the filtered slice.
3. **Engineering workflow** — Modify `clean_pipeline.py`, rerun to regenerate `Cleaned_Data.csv`, then refresh the dashboard.
4. **SQL workflow** — Load `Cleaned_Data.csv` into Postgres/MySQL, run `SQL/Business_Queries.sql` to answer canonical questions (top customers, monthly revenue, discount vs. margin, etc.).

**Example scenarios**
- *"Which sub-categories destroy margin?"* → Dashboard → Category tab → Profit by Sub-Category bar.
- *"Where should we open the next warehouse?"* → Dashboard → Geographic tab → choropleth + shipping-days overlay.
- *"Who are our top 20 customers by lifetime value?"* → `Business_Queries.sql` → query #7.

---

## API Documentation

The dashboard itself does not expose a REST API, but the SQL layer is the documented interface. If you wrap the pipeline in a Flask/FastAPI service, the recommended surface is:

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/kpis` | Returns aggregated KPIs for a given filter set. |
| GET | `/api/revenue/trend` | Monthly revenue + profit time series. |
| GET | `/api/top/customers` | Top N customers by revenue or profit. |
| POST | `/api/clean` | Triggers `clean_pipeline.py` on an uploaded CSV. |
| PUT | `/api/dataset` | Replaces the active analytical dataset. |
| DELETE | `/api/cache` | Invalidates Streamlit / query caches. |

**Example request**
```bash
curl "https://api.retailpulse.app/api/kpis?from=2017-01-01&to=2017-12-31&region=West"
```

**Example response**
```json
{
  "revenue": 725457,
  "profit": 108418,
  "orders": 1611,
  "customers": 686,
  "aov": 450.31,
  "margin_pct": 14.94
}
```

---

## Database Schema

**Main tables**

- `orders` — one row per line item (`order_id`, `order_date`, `ship_date`, `ship_mode`, `customer_id`, `product_id`, `sales`, `quantity`, `discount`, `profit`)
- `customers` — `customer_id`, `customer_name`, `segment`
- `products` — `product_id`, `product_name`, `category`, `sub_category`
- `geography` — `postal_code`, `city`, `state`, `region`, `country`

**Relationships**

```text
customers (1) ───< (∞) orders (∞) >─── (1) products
                          │
                          ▼
                      geography
```

**Engineered analytical columns** (materialized in `Cleaned_Data.csv`)

`profit_margin_pct`, `unit_price`, `is_profitable`, `sales_band`, `shipping_days`, `order_year`, `order_quarter`, `order_weekday`, `sales_outlier_flag`.

---

## Testing

### Unit Testing
```bash
pytest tests/ -v
```
Covers: column standardization, date parsing, profit derivation, outlier flagging.

### Integration Testing
Runs the full pipeline on a tiny fixture CSV and asserts the resulting schema, row count, and KPI totals.
```bash
pytest tests/integration -v
```

### End-to-End Testing
- Headless Streamlit smoke test via `streamlit run --server.headless true` + Playwright.
- Notebook execution test via `jupyter nbconvert --to notebook --execute`.

### Tooling
- `pytest`, `pytest-cov`
- `nbformat` + `nbconvert` for notebook validation
- `ruff` for linting
- GitHub Actions CI matrix (Python 3.10, 3.11, 3.12)

---

## Performance Optimizations

- **Caching** — `@st.cache_data` memoizes dataset loads and heavy aggregations.
- **Lazy Loading** — Charts render only when their tab is opened.
- **Pagination** — Leaderboards capped at Top N with on-demand expansion.
- **Query Optimization** — Indexed `order_date`, `customer_id`, `product_id` in SQL scripts.
- **Vectorization** — All transformations use pandas/NumPy vectorized ops, not row loops.
- **Code Splitting** — Pipeline, dashboard, and analytics live in separate modules.
- **Compression** — Cleaned CSV can be swapped for Parquet (`df.to_parquet`) for 5–10× faster IO.

---

## Security Features

- **Authentication** — Optional Streamlit-Authenticator integration.
- **Authorization** — Role-aware filters (analyst vs. viewer) when auth is enabled.
- **Password Encryption** — bcrypt hashing for any stored credentials.
- **JWT Security** — Short-lived tokens with rotating secrets for the optional API.
- **Input Validation** — Uploaded CSVs are type-coerced and validated before use.
- **Rate Limiting** — Reverse-proxy (nginx/Cloudflare) rate limits on the API surface.
- **CSRF Protection** — Enabled at the proxy layer for any POST endpoint.
- **Secure API Practices** — `.env` driven secrets, no hardcoded credentials, HTTPS-only deployment.

---

## Deployment

- **Streamlit Cloud** — Connect repo → set `Python/Dashboard.py` as entry point → deploy.
- **Vercel / Netlify** — Best for the static docs site; not for the Streamlit app.
- **Render / Railway** — One-click web service; set start command to `streamlit run Python/Dashboard.py --server.port $PORT --server.address 0.0.0.0`.
- **AWS** — ECS Fargate + ALB, image built from `Dockerfile`.
- **Azure** — App Service for Containers.

**CI/CD overview** — GitHub Actions runs lint + tests + notebook execution on every PR, then deploys `main` to Streamlit Cloud (or pushes the Docker image to the registry).

---

## Challenges & Solutions

- **Sales-only raw data** — The public Superstore export ships with `Sales` but no `Profit`, `Quantity`, or `Discount`. **Solution:** deterministic seeded derivation in `clean_pipeline.py` with clearly documented rules, so analysis stays reproducible and honest.
- **Mixed European date format (dd/mm/yyyy)** — pandas defaulted to month/day swaps and silently corrupted timelines. **Solution:** explicit `format="%d/%m/%Y"` in `fix_types()`.
- **Notebook ↔ script drift** — Cleaning logic kept diverging between the notebook and the script. **Solution:** declared `clean_pipeline.py` the single source of truth; the notebook re-imports it.
- **Sub-second dashboard on 10K rows with filters** — Naive recompute on every widget change was sluggish. **Solution:** `@st.cache_data` on the loader + aggregations keyed by filter tuple.
- **State-level visualization** — Plotly choropleth needs ISO codes, not state names. **Solution:** built-in `STATE_CODES` dictionary mapped at chart time.
- **Outlier distortion** — A handful of giant orders skewed every average. **Solution:** added `sales_outlier_flag` (IQR rule) so users can opt-in or opt-out.

---

## Future Improvements

1. Swap CSV storage for **DuckDB** / **Parquet** for 10× query speed.
2. Add **forecasting** (Prophet / statsmodels) for next-quarter revenue projection.
3. Layer in **customer segmentation** (RFM + KMeans) with cluster profiles.
4. Add **what-if discount simulator** with margin sensitivity.
5. Wire up an **email-scheduled PDF report** via WeasyPrint + cron.
6. Implement **role-based access control** in the dashboard.
7. Add an **anomaly-detection alerting** layer (Z-score / Isolation Forest).
8. Migrate visuals to **Plotly Dash** for richer cross-filtering.
9. Build a **REST API** wrapper (FastAPI) around the analytical layer.
10. Add **multi-tenant** support so different teams can upload private datasets.
11. Integrate **OpenAI** for natural-language Q&A over the dataset.
12. Add **dark mode** + custom Streamlit theme.

---

## Contributing

1. **Fork** the repository.
2. **Create a feature branch** — `git checkout -b feat/your-feature`.
3. **Commit changes** — follow Conventional Commits (`feat:`, `fix:`, `docs:`).
4. **Push branch** — `git push origin feat/your-feature`.
5. **Open a Pull Request** describing the change, the motivation, and screenshots if UI-affecting.

**Coding standards**
- `ruff` clean, type-hinted Python.
- Notebooks must run top-to-bottom without errors (`Restart & Run All`).
- New pipeline steps require a unit test.
- Keep `clean_pipeline.py` and `Data_Cleaning.ipynb` in lockstep.

---

## FAQ

**Q: Where does the dataset come from?**
A: The public US Superstore Sales dataset (2015–2018), widely used for analytics learning.

**Q: Why are `Profit`, `Quantity`, and `Discount` derived?**
A: The raw export only ships `Sales`. We synthesize the rest with seeded, transparent rules so analyses remain reproducible.

**Q: Can I plug my own CSV into the dashboard?**
A: Yes — use the sidebar uploader. The schema should match `Cleaned_Data.csv` columns.

**Q: Does it support databases other than CSV?**
A: Yes — point `DATABASE_URL` at Postgres/MySQL and load `Cleaned_Data.csv` once.

**Q: Is this production-ready?**
A: It is portfolio- and prototype-grade. With auth, CI/CD, and a managed DB, it is production-ready for an internal analytics team.

**Q: How big a dataset can it handle?**
A: Comfortably up to ~1M rows in pandas; beyond that, switch the loader to DuckDB/Parquet.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](./LICENSE) file for details.

---

# Author

**HARI BABU C H**

- **Role:** Frontend Developer | Data Analyst
- **GitHub:** <https://github.com/haribabux7>
- **LinkedIn:** <https://www.linkedin.com/in/haribabux7>
- **Portfolio:** <https://www.haribabu.me>
- **Email:** haribabuc458@gmail.com

---

## Acknowledgements

- **Open Source Libraries** — pandas, NumPy, Plotly, Streamlit, Seaborn, Matplotlib, Jupyter.
- **Dataset** — Public US Superstore Sales dataset.
- **Contributors** — Everyone who opened issues, PRs, or shared feedback.
- **Learning Resources** — Kaggle community notebooks, Streamlit docs, "Python for Data Analysis" (Wes McKinney).
- **Inspiration** — Real-world BI dashboards from Tableau Public and the Streamlit gallery.

---

## Project Information

| Field | Value |
|---|---|
| Version | 1.0.0 |
| Designed Date | November 2025 |
| Status | Active |
| Maintainer | Hari Babu C H |
| License | MIT |
