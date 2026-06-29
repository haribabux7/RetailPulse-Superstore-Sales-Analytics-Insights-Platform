/* ============================================================================
   Business_Queries.sql  —  30+ business questions on `superstore`
   Each block: BUSINESS QUESTION | SQL | INSIGHT | RECOMMENDATION
   ========================================================================== */

/* ===== Q1. What is total revenue, profit and margin? ===================== */
SELECT ROUND(SUM(sales),2) AS revenue, ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM superstore;
-- INSIGHT: Establishes the company-wide baseline KPI.
-- RECOMMENDATION: Set this as the board-level benchmark for QoQ tracking.

/* ===== Q2. Which category generates the most revenue? =================== */
SELECT category, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY category ORDER BY revenue DESC;
-- INSIGHT: Technology & Furniture dominate top-line revenue.
-- RECOMMENDATION: Protect top-revenue category supply and shelf priority.

/* ===== Q3. Which category is most profitable? =========================== */
SELECT category, ROUND(SUM(profit),2) AS profit,
       ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM superstore GROUP BY category ORDER BY profit DESC;
-- INSIGHT: High revenue does not equal high margin (Furniture lags).
-- RECOMMENDATION: Shift marketing spend toward higher-margin categories.

/* ===== Q4. Which sub-categories are unprofitable? ====================== */
SELECT sub_category, ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY sub_category HAVING SUM(profit) < 0 ORDER BY profit;
-- INSIGHT: A handful of sub-categories drag down total profit.
-- RECOMMENDATION: Re-price, renegotiate cost, or rationalise these SKUs.

/* ===== Q5. Top 10 products by revenue? ================================= */
SELECT product_name, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY product_name ORDER BY revenue DESC LIMIT 10;
-- INSIGHT: A small set of hero products drives outsized revenue.
-- RECOMMENDATION: Guarantee stock & bundle these as anchor products.

/* ===== Q6. Top 10 loss-making products? ================================ */
SELECT product_name, ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY product_name ORDER BY profit ASC LIMIT 10;
-- INSIGHT: Specific products consistently lose money.
-- RECOMMENDATION: Discontinue or remove discounts on chronic losers.

/* ===== Q7. Revenue by region? ========================================== */
SELECT region, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY region ORDER BY revenue DESC;
-- INSIGHT: West & East lead; Central/South trail.
-- RECOMMENDATION: Run targeted campaigns in under-performing regions.

/* ===== Q8. Most profitable region by margin? ========================== */
SELECT region, ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) AS margin_pct
FROM superstore GROUP BY region ORDER BY margin_pct DESC;
-- INSIGHT: Margin leadership can differ from revenue leadership.
-- RECOMMENDATION: Replicate high-margin region practices elsewhere.

/* ===== Q9. Top 10 states by revenue? ================================== */
SELECT state, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY state ORDER BY revenue DESC LIMIT 10;
-- INSIGHT: Revenue is geographically concentrated.
-- RECOMMENDATION: Assign dedicated reps to the top revenue states.

/* ===== Q10. Bottom 10 states by profit? =============================== */
SELECT state, ROUND(SUM(profit),2) AS profit
FROM superstore GROUP BY state ORDER BY profit ASC LIMIT 10;
-- INSIGHT: Some states are net-negative on profit.
-- RECOMMENDATION: Audit shipping/discount policy in loss-making states.

/* ===== Q11. Revenue by customer segment? ============================== */
SELECT segment, ROUND(SUM(sales),2) AS revenue, COUNT(DISTINCT customer_id) AS customers
FROM superstore GROUP BY segment ORDER BY revenue DESC;
-- INSIGHT: Consumer segment dominates volume.
-- RECOMMENDATION: Build loyalty programs for the largest segment.

/* ===== Q12. Average order value overall? ============================== */
SELECT ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) AS avg_order_value FROM superstore;
-- INSIGHT: Benchmark basket size for upsell targets.
-- RECOMMENDATION: Introduce free-shipping thresholds just above AOV.

/* ===== Q13. AOV by segment? =========================================== */
SELECT segment, ROUND(SUM(sales)/COUNT(DISTINCT order_id),2) AS aov
FROM superstore GROUP BY segment ORDER BY aov DESC;
-- INSIGHT: B2B segments often have higher AOV.
-- RECOMMENDATION: Offer volume tiers to lift consumer AOV.

/* ===== Q14. Monthly revenue trend? =================================== */
SELECT order_year, order_month, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY order_year, order_month ORDER BY order_year, order_month;
-- INSIGHT: Clear upward trend with Q4 peaks.
-- RECOMMENDATION: Pre-stock and ramp staffing ahead of Q4.

/* ===== Q15. Year-over-year growth? ==================================== */
WITH y AS (SELECT order_year, SUM(sales) rev FROM superstore GROUP BY order_year)
SELECT order_year, ROUND(rev,2) revenue,
       ROUND((rev-LAG(rev) OVER(ORDER BY order_year))/NULLIF(LAG(rev) OVER(ORDER BY order_year),0)*100,1) growth_pct
FROM y;
-- INSIGHT: Quantifies momentum year to year.
-- RECOMMENDATION: Investigate any decelerating year for root cause.

/* ===== Q16. Best sales month historically? =========================== */
SELECT order_month, ROUND(SUM(sales),2) AS revenue
FROM superstore GROUP BY order_month ORDER BY revenue DESC LIMIT 3;
-- INSIGHT: Identifies peak demand months.
-- RECOMMENDATION: Concentrate promo budget in peak months.

/* ===== Q17. Top 10 customers by lifetime value? ====================== */
SELECT customer_name, ROUND(SUM(sales),2) AS clv, COUNT(DISTINCT order_id) orders
FROM superstore GROUP BY customer_name ORDER BY clv DESC LIMIT 10;
-- INSIGHT: A small cohort drives disproportionate value (Pareto).
-- RECOMMENDATION: Launch VIP retention for top customers.

/* ===== Q18. How many one-time vs repeat customers? =================== */
WITH c AS (SELECT customer_id, COUNT(DISTINCT order_id) o FROM superstore GROUP BY customer_id)
SELECT CASE WHEN o=1 THEN 'one-time' ELSE 'repeat' END AS type, COUNT(*) customers
FROM c GROUP BY (o=1);
-- INSIGHT: Reveals dependency on repeat vs new business.
-- RECOMMENDATION: Win-back campaigns to convert one-timers to repeat.

/* ===== Q19. Customer retention by cohort year? ====================== */
WITH first AS (SELECT customer_id, MIN(order_year) cohort FROM superstore GROUP BY customer_id)
SELECT f.cohort, COUNT(DISTINCT s.customer_id) active_customers, s.order_year
FROM superstore s JOIN first f ON s.customer_id=f.customer_id
GROUP BY f.cohort, s.order_year ORDER BY f.cohort, s.order_year;
-- INSIGHT: Shows how many cohort customers stay active over time.
-- RECOMMENDATION: Focus retention on cohorts with steepest drop-off.

/* ===== Q20. Average shipping time by ship mode? ===================== */
SELECT ship_mode, ROUND(AVG(shipping_days),1) AS avg_days, COUNT(*) line_items
FROM superstore GROUP BY ship_mode ORDER BY avg_days;
-- INSIGHT: Quantifies fulfilment speed by service level.
-- RECOMMENDATION: Promote faster modes; fix any SLA breaches.

/* ===== Q21. Which ship mode is most used? ========================== */
SELECT ship_mode, COUNT(DISTINCT order_id) orders FROM superstore
GROUP BY ship_mode ORDER BY orders DESC;
-- INSIGHT: Standard class likely dominates.
-- RECOMMENDATION: Negotiate carrier rates on the highest-volume mode.

/* ===== Q22. Discount impact on profit margin? ===================== */
SELECT ROUND(discount,1) AS discount_band,
       ROUND(AVG(profit_margin_pct),2) AS avg_margin
FROM superstore GROUP BY ROUND(discount,1) ORDER BY discount_band;
-- INSIGHT: Margin falls sharply as discount rises.
-- RECOMMENDATION: Cap discount approvals beyond the break-even band.

/* ===== Q23. Share of unprofitable orders? ========================= */
SELECT ROUND(100.0*SUM(CASE WHEN profit<0 THEN 1 ELSE 0 END)/COUNT(*),2) AS pct_loss_orders
FROM superstore;
-- INSIGHT: Measures how much business runs at a loss.
-- RECOMMENDATION: Add margin guardrails in the order-entry workflow.

/* ===== Q24. Revenue contribution % by category? ================== */
SELECT category, ROUND(100.0*SUM(sales)/(SELECT SUM(sales) FROM superstore),2) AS pct_of_revenue
FROM superstore GROUP BY category ORDER BY pct_of_revenue DESC;
-- INSIGHT: Concentration risk if one category dominates.
-- RECOMMENDATION: Diversify the category mix to reduce risk.

/* ===== Q25. Top sub-category per region? ========================= */
SELECT region, sub_category, revenue FROM (
  SELECT region, sub_category, ROUND(SUM(sales),2) revenue,
         ROW_NUMBER() OVER(PARTITION BY region ORDER BY SUM(sales) DESC) rn
  FROM superstore GROUP BY region, sub_category) t
WHERE rn=1;
-- INSIGHT: Regional demand preferences differ.
-- RECOMMENDATION: Localise assortment & inventory by region.

/* ===== Q26. Sales by day of week? =============================== */
SELECT DAYNAME(order_date) AS weekday, ROUND(SUM(sales),2) revenue
FROM superstore GROUP BY DAYNAME(order_date) ORDER BY revenue DESC;
-- INSIGHT: Identifies high-traffic days.
-- RECOMMENDATION: Time email/ad sends to peak ordering days.

/* ===== Q27. Average quantity per order? ======================== */
SELECT ROUND(AVG(quantity),2) AS avg_qty_per_line FROM superstore;
-- INSIGHT: Baseline basket depth.
-- RECOMMENDATION: Bundle to increase items per order.

/* ===== Q28. Profit per customer segment per region? =========== */
SELECT region, segment, ROUND(SUM(profit),2) profit
FROM superstore GROUP BY region, segment ORDER BY region, profit DESC;
-- INSIGHT: Pinpoints the most valuable region×segment cells.
-- RECOMMENDATION: Allocate sales coverage to top cells.

/* ===== Q29. Running cumulative monthly revenue? =============== */
SELECT order_year, order_month,
       ROUND(SUM(SUM(sales)) OVER(ORDER BY order_year, order_month),2) AS cumulative_revenue
FROM superstore GROUP BY order_year, order_month ORDER BY order_year, order_month;
-- INSIGHT: Tracks progress toward annual targets.
-- RECOMMENDATION: Compare cumulative curve vs plan monthly.

/* ===== Q30. Highest single orders by value? ================== */
SELECT order_id, ROUND(SUM(sales),2) order_value
FROM superstore GROUP BY order_id ORDER BY order_value DESC LIMIT 10;
-- INSIGHT: Identifies whale orders / key accounts.
-- RECOMMENDATION: Provide white-glove service to large accounts.

/* ===== Q31. Average margin by sub-category (best to worst)? === */
SELECT sub_category, ROUND(SUM(profit)/NULLIF(SUM(sales),0)*100,2) margin_pct
FROM superstore GROUP BY sub_category ORDER BY margin_pct DESC;
-- INSIGHT: Ranks profitability efficiency per sub-category.
-- RECOMMENDATION: Promote high-margin sub-categories in merchandising.

/* ===== Q32. New customers acquired per year? ================= */
WITH f AS (SELECT customer_id, MIN(order_year) yr FROM superstore GROUP BY customer_id)
SELECT yr AS acquisition_year, COUNT(*) AS new_customers FROM f GROUP BY yr ORDER BY yr;
-- INSIGHT: Tracks acquisition velocity over time.
-- RECOMMENDATION: If acquisition slows, boost top-of-funnel marketing.
