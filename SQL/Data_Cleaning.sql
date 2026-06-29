/* ============================================================================
   Data_Cleaning.sql  —  Superstore Sales
   Dialect: ANSI SQL (notes for MySQL 8 / PostgreSQL). Load Raw_Data.csv into
   a staging table `superstore_raw`, then build the cleaned table `superstore`.
   ----------------------------------------------------------------------------
   Steps: staging -> type conversion -> missing values -> duplicates ->
          validation -> feature engineering -> final cleaned table.
   ========================================================================== */

/* ---------- 0. STAGING TABLE (all TEXT, mirrors raw CSV) ----------------- */
DROP TABLE IF EXISTS superstore_raw;
CREATE TABLE superstore_raw (
    row_id        VARCHAR(20),
    order_id      VARCHAR(30),
    order_date    VARCHAR(20),
    ship_date     VARCHAR(20),
    ship_mode     VARCHAR(40),
    customer_id   VARCHAR(30),
    customer_name VARCHAR(120),
    segment       VARCHAR(40),
    country       VARCHAR(60),
    city          VARCHAR(80),
    state         VARCHAR(60),
    postal_code   VARCHAR(20),
    region        VARCHAR(30),
    product_id    VARCHAR(40),
    category      VARCHAR(40),
    sub_category  VARCHAR(40),
    product_name  VARCHAR(255),
    sales         VARCHAR(30)
);
-- MySQL:    LOAD DATA INFILE 'Raw_Data.csv' INTO TABLE superstore_raw
--           FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
--           LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- Postgres: \copy superstore_raw FROM 'Raw_Data.csv' WITH (FORMAT csv, HEADER true);

/* ---------- 1. PROFILING -------------------------------------------------- */
SELECT COUNT(*) AS total_rows FROM superstore_raw;
SELECT COUNT(*) AS missing_postal FROM superstore_raw
WHERE postal_code IS NULL OR postal_code = '';
SELECT order_id, product_id, COUNT(*) c
FROM superstore_raw GROUP BY order_id, product_id HAVING COUNT(*) > 1;

/* ---------- 2. TYPED + CLEANED TABLE -------------------------------------- */
DROP TABLE IF EXISTS superstore;
CREATE TABLE superstore (
    row_id            INT,
    order_id          VARCHAR(30),
    order_date        DATE,
    ship_date         DATE,
    ship_mode         VARCHAR(40),
    customer_id       VARCHAR(30),
    customer_name     VARCHAR(120),
    segment           VARCHAR(40),
    country           VARCHAR(60),
    city              VARCHAR(80),
    state             VARCHAR(60),
    postal_code       VARCHAR(20),
    region            VARCHAR(30),
    product_id        VARCHAR(40),
    category          VARCHAR(40),
    sub_category      VARCHAR(40),
    product_name      VARCHAR(255),
    sales             DECIMAL(12,2),
    quantity          INT,
    discount          DECIMAL(5,2),
    profit            DECIMAL(12,2),
    order_year        INT,
    order_month       INT,
    order_quarter     VARCHAR(2),
    shipping_days     INT,
    profit_margin_pct DECIMAL(6,2),
    is_profitable     INT
);

/* ---------- 3. TRANSFORM + LOAD (dates dd/mm/yyyy) ------------------------ */
-- STR_TO_DATE(x,'%d/%m/%Y') for MySQL  |  TO_DATE(x,'DD/MM/YYYY') for Postgres
INSERT INTO superstore
SELECT
    CAST(row_id AS UNSIGNED),
    TRIM(order_id),
    STR_TO_DATE(order_date, '%d/%m/%Y'),
    STR_TO_DATE(ship_date , '%d/%m/%Y'),
    TRIM(ship_mode),
    TRIM(customer_id),
    TRIM(customer_name),
    TRIM(segment),
    TRIM(country),
    TRIM(city),
    TRIM(state),
    /* 3a. MISSING VALUE HANDLING: blank -> '00000' placeholder */
    CASE WHEN postal_code IS NULL OR postal_code = '' THEN '00000' ELSE postal_code END,
    TRIM(region),
    TRIM(product_id),
    TRIM(category),
    TRIM(sub_category),
    TRIM(product_name),
    CAST(sales AS DECIMAL(12,2)),
    /* 3b. FEATURE ENGINEERING: deterministic synthetic business metrics
       (mirrors the Python pipeline; replace with real columns if available) */
    (MOD(CAST(row_id AS UNSIGNED), 14) + 1)                              AS quantity,
    ROUND(CASE category WHEN 'Furniture' THEN 0.17
                        WHEN 'Technology' THEN 0.12 ELSE 0.10 END, 2)    AS discount,
    ROUND(CAST(sales AS DECIMAL(12,2)) *
          (CASE category WHEN 'Technology' THEN 0.22
                         WHEN 'Office Supplies' THEN 0.18 ELSE 0.10 END
           - (CASE category WHEN 'Furniture' THEN 0.17
                            WHEN 'Technology' THEN 0.12 ELSE 0.10 END) * 0.9), 2) AS profit,
    YEAR (STR_TO_DATE(order_date, '%d/%m/%Y')),
    MONTH(STR_TO_DATE(order_date, '%d/%m/%Y')),
    CONCAT('Q', QUARTER(STR_TO_DATE(order_date, '%d/%m/%Y'))),
    DATEDIFF(STR_TO_DATE(ship_date,'%d/%m/%Y'), STR_TO_DATE(order_date,'%d/%m/%Y')),
    NULL,
    NULL
FROM superstore_raw
/* ---------- 4. VALIDATION (filter invalid rows) -------------------------- */
WHERE sales IS NOT NULL AND CAST(sales AS DECIMAL(12,2)) > 0
  AND STR_TO_DATE(ship_date,'%d/%m/%Y') >= STR_TO_DATE(order_date,'%d/%m/%Y');

/* ---------- 5. POST-LOAD DERIVED COLUMNS --------------------------------- */
UPDATE superstore
SET profit_margin_pct = ROUND(profit / NULLIF(sales,0) * 100, 2),
    is_profitable     = CASE WHEN profit > 0 THEN 1 ELSE 0 END;

/* ---------- 6. DUPLICATE REMOVAL ----------------------------------------- */
-- Keep lowest row_id per (order_id, product_id) pair.
DELETE s FROM superstore s
JOIN superstore d
  ON s.order_id = d.order_id AND s.product_id = d.product_id AND s.row_id > d.row_id;

/* ---------- 7. OUTLIER REVIEW (flag, do not delete) ---------------------- */
-- Inspect high-value orders against an approx. IQR upper fence.
WITH q AS (SELECT AVG(sales) m, STDDEV(sales) sd FROM superstore)
SELECT order_id, sales FROM superstore, q
WHERE sales > q.m + 3 * q.sd ORDER BY sales DESC;

/* ---------- 8. QUALITY CHECKS -------------------------------------------- */
SELECT COUNT(*) AS clean_rows,
       SUM(CASE WHEN postal_code='00000' THEN 1 ELSE 0 END) AS imputed_postal,
       MIN(order_date) AS first_order, MAX(order_date) AS last_order,
       ROUND(SUM(sales),2) AS total_sales, ROUND(SUM(profit),2) AS total_profit
FROM superstore;
