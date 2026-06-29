/* ============================================================================
   EDA.sql  —  Exploratory Data Analysis on cleaned table `superstore`
   Sections: dataset summary, category, trend, top/bottom, segmentation.
   ========================================================================== */

/* ---------- 1. DATASET SUMMARY ------------------------------------------- */
SELECT
    COUNT(*)                       AS line_items,
    COUNT(DISTINCT order_id)       AS orders,
    COUNT(DISTINCT customer_id)    AS customers,
    COUNT(DISTINCT product_id)     AS products,
    MIN(order_date)                AS first_order,
    MAX(order_date)                AS last_order,
    ROUND(SUM(sales),2)            AS total_sales,
    ROUND(SUM(profit),2)           AS total_profit,
    ROUND(AVG(sales),2)            AS avg_line_sales,
    ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS overall_margin_pct
FROM superstore;

-- Descriptive stats per numeric measure
SELECT 'sales' AS metric, MIN(sales) AS min_v, MAX(sales) AS max_v,
       ROUND(AVG(sales),2) AS avg_v, ROUND(STDDEV(sales),2) AS std_v FROM superstore
UNION ALL
SELECT 'profit', MIN(profit), MAX(profit), ROUND(AVG(profit),2), ROUND(STDDEV(profit),2) FROM superstore
UNION ALL
SELECT 'discount', MIN(discount), MAX(discount), ROUND(AVG(discount),2), ROUND(STDDEV(discount),2) FROM superstore;

/* ---------- 2. CATEGORY ANALYSIS ----------------------------------------- */
SELECT category,
       COUNT(DISTINCT order_id)  AS orders,
       ROUND(SUM(sales),2)       AS revenue,
       ROUND(SUM(profit),2)      AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM superstore GROUP BY category ORDER BY revenue DESC;

SELECT category, sub_category,
       ROUND(SUM(sales),2)  AS revenue,
       ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY category, sub_category ORDER BY profit ASC LIMIT 10;

/* ---------- 3. TREND ANALYSIS -------------------------------------------- */
-- Monthly trend
SELECT order_year, order_month,
       ROUND(SUM(sales),2)  AS revenue,
       ROUND(SUM(profit),2) AS profit,
       COUNT(DISTINCT order_id) AS orders
FROM superstore GROUP BY order_year, order_month ORDER BY order_year, order_month;

-- Year-over-year growth
WITH yearly AS (
    SELECT order_year, SUM(sales) rev, SUM(profit) prof
    FROM superstore GROUP BY order_year)
SELECT order_year, ROUND(rev,2) AS revenue,
       ROUND((rev - LAG(rev) OVER (ORDER BY order_year))
             / NULLIF(LAG(rev) OVER (ORDER BY order_year),0) * 100, 1) AS sales_growth_pct
FROM yearly;

-- Quarterly seasonality
SELECT order_quarter, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY order_quarter ORDER BY order_quarter;

/* ---------- 4. TOP / BOTTOM PERFORMANCE ---------------------------------- */
-- Top 10 products by revenue
SELECT product_name, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY product_name ORDER BY revenue DESC LIMIT 10;

-- Bottom 10 products by profit (loss leaders)
SELECT product_name, ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY product_name ORDER BY profit ASC LIMIT 10;

-- Top 10 customers by lifetime value
SELECT customer_name, ROUND(SUM(sales),2) AS clv, COUNT(DISTINCT order_id) AS orders
FROM superstore GROUP BY customer_name ORDER BY clv DESC LIMIT 10;

/* ---------- 5. SEGMENTATION ANALYSIS ------------------------------------- */
-- By segment
SELECT segment, COUNT(DISTINCT customer_id) AS customers,
       ROUND(SUM(sales),2) AS revenue, ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY segment ORDER BY revenue DESC;

-- By region
SELECT region, ROUND(SUM(sales),2) AS revenue, ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM superstore GROUP BY region ORDER BY revenue DESC;

-- By ship mode
SELECT ship_mode, COUNT(DISTINCT order_id) AS orders,
       ROUND(AVG(shipping_days),1) AS avg_ship_days
FROM superstore GROUP BY ship_mode ORDER BY orders DESC;

-- Sales-band distribution
SELECT CASE WHEN sales < 50 THEN '<50'
            WHEN sales < 200 THEN '50-200'
            WHEN sales < 500 THEN '200-500'
            WHEN sales < 1000 THEN '500-1000'
            ELSE '1000+' END AS sales_band,
       COUNT(*) AS line_items, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY sales_band ORDER BY revenue DESC;
