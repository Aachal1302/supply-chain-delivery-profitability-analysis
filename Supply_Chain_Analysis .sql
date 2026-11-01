-- Purpose: Create a structured table to analyze logistics costs, delivery performance, and profitability.

CREATE TABLE supply_chain_data (
    type VARCHAR(50),
    days_for_shipping_real INTEGER,
    days_for_shipment_scheduled INTEGER,
    benefit_per_order NUMERIC(12,2),
    sales_per_customer NUMERIC(12,2),
    delivery_status VARCHAR(50),
    late_delivery_risk INTEGER,
    category_id INTEGER,
    category_name VARCHAR(150),
    customer_city VARCHAR(150),
    customer_country VARCHAR(100),
    customer_id BIGINT,
    customer_segment VARCHAR(50),
    customer_state VARCHAR(100),
    customer_zipcode VARCHAR(20),
    department_id INTEGER,
    department_name VARCHAR(100),
    latitude NUMERIC(12,8),
    longitude NUMERIC(12,8),
    market VARCHAR(100),
    order_city VARCHAR(150),
    order_country VARCHAR(100),
    order_customer_id BIGINT,
    order_date_text VARCHAR(50),
    order_id BIGINT,
    order_item_cardprod_id BIGINT,
    order_item_discount NUMERIC(12,2),
    order_item_discount_rate NUMERIC(12,6),
    order_item_id BIGINT,
    order_item_product_price NUMERIC(12,2),
    order_item_profit_ratio NUMERIC(12,6),
    order_item_quantity INTEGER,
    sales NUMERIC(12,2),
    order_item_total NUMERIC(12,2),
    order_profit_per_order NUMERIC(12,2),
    order_region VARCHAR(100),
    order_state VARCHAR(150),
    order_status VARCHAR(50),
    product_card_id BIGINT,
    product_category_id INTEGER,
    product_name VARCHAR(255),
    product_price NUMERIC(12,2),
    shipping_date_text VARCHAR(50),
    shipping_mode VARCHAR(50)
);




-- =====================================================================
-- DATA CLEANING
-- =====================================================================

-- Step 1: Check date formats
-- Purpose: Find which date formats exist in the text columns before converting them.
--          Expected: 'M/D/YYYY' and 'YYYY-MM-DD'. If 'DD-MM-YY' or 'other' appears, tell me.
SELECT 'order_date' AS column_name,
    CASE
        WHEN order_date_text ~ '^\d{1,2}/\d{1,2}/\d{4}' THEN 'M/D/YYYY'
        WHEN order_date_text ~ '^\d{4}-\d{2}-\d{2}'     THEN 'YYYY-MM-DD'
        WHEN order_date_text ~ '^\d{2}-\d{2}-\d{2} '    THEN 'DD-MM-YY'
        ELSE 'other'
    END AS date_format,
    COUNT(*) AS rows_count,
    MIN(order_date_text) AS example
FROM supply_chain_data
GROUP BY 2
UNION ALL
SELECT 'shipping_date',
    CASE
        WHEN shipping_date_text ~ '^\d{1,2}/\d{1,2}/\d{4}' THEN 'M/D/YYYY'
        WHEN shipping_date_text ~ '^\d{4}-\d{2}-\d{2}'     THEN 'YYYY-MM-DD'
        WHEN shipping_date_text ~ '^\d{2}-\d{2}-\d{2} '    THEN 'DD-MM-YY'
        ELSE 'other'
    END,
    COUNT(*),
    MIN(shipping_date_text)
FROM supply_chain_data
GROUP BY 2;


-- Step 2: Standardize order and shipping dates
-- Purpose: Convert both text date columns into one TIMESTAMP format.
-- Note:    Values like '2018-03-02' are day/month swapped (Excel mis-read them),
--          so they are read as YYYY-DD-MM on purpose. Slash dates are already correct (MM/DD/YYYY).
UPDATE supply_chain_data
SET
    order_date = CASE
        WHEN order_date_text ~ '^\d{1,2}/\d{1,2}/\d{4}'
            THEN TO_TIMESTAMP(order_date_text, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
        WHEN order_date_text ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_TIMESTAMP(order_date_text, 'YYYY-DD-MM HH24:MI:SS')::TIMESTAMP
    END,
    shipping_date = CASE
        WHEN shipping_date_text ~ '^\d{1,2}/\d{1,2}/\d{4}'
            THEN TO_TIMESTAMP(shipping_date_text, 'MM/DD/YYYY HH24:MI')::TIMESTAMP
        WHEN shipping_date_text ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_TIMESTAMP(shipping_date_text, 'YYYY-DD-MM HH24:MI:SS')::TIMESTAMP
    END;


-- Step 3: Verify the date conversion
-- Purpose: Confirm all dates converted, shipping is never before the order,
--          and the date range is correct.
-- Expected: total_rows = 180519, missing_dates = 0, invalid_date_records = 0,
--           first_order = Jan 2015, last_order = Jan 2018.
SELECT
    COUNT(*)                                          AS total_rows,
    COUNT(*) FILTER (WHERE order_date IS NULL
                        OR shipping_date IS NULL)     AS missing_dates,
    COUNT(*) FILTER (WHERE order_date > shipping_date) AS invalid_date_records,
    MIN(order_date)                                   AS first_order,
    MAX(order_date)                                   AS last_order
FROM supply_chain_data;



-- Step 4: Remove extra spaces from text columns
-- Purpose: Trailing spaces split one value into two groups (e.g. 'Southeast Asia ' vs 'Southeast Asia').
UPDATE supply_chain_data
SET
    type = TRIM(type),
    delivery_status = TRIM(delivery_status),
    category_name = TRIM(category_name),
    customer_city = TRIM(customer_city),
    customer_country = TRIM(customer_country),
    customer_segment = TRIM(customer_segment),
    customer_state = TRIM(customer_state),
    department_name = TRIM(department_name),
    market = TRIM(market),
    order_city = TRIM(order_city),
    order_country = TRIM(order_country),
    order_region = TRIM(order_region),
    order_state = TRIM(order_state),
    order_status = TRIM(order_status),
    product_name = TRIM(product_name),
    shipping_mode = TRIM(shipping_mode);


-- Step 4a: Verify the trim
-- Expected: every count is 0.
SELECT
    COUNT(*) FILTER (WHERE order_region    <> TRIM(order_region))    AS untrimmed_region,
    COUNT(*) FILTER (WHERE category_name   <> TRIM(category_name))   AS untrimmed_category,
    COUNT(*) FILTER (WHERE product_name    <> TRIM(product_name))    AS untrimmed_product,
    COUNT(*) FILTER (WHERE department_name <> TRIM(department_name)) AS untrimmed_department
FROM supply_chain_data;


-- Step 5: Clean the zipcode and convert blanks to NULL
-- Purpose: Remove the trailing '.0' (e.g. '725.0' becomes '725') and turn 3 blank values into NULL.
UPDATE supply_chain_data
SET customer_zipcode = NULLIF(REGEXP_REPLACE(TRIM(customer_zipcode), '\.0$', ''), '');


-- Step 6: Check for duplicates
-- Expected: duplicate_items = 0, total_orders = 65752.
SELECT
    COUNT(*)                                 AS total_items,
    COUNT(DISTINCT order_item_id)            AS unique_items,
    COUNT(*) - COUNT(DISTINCT order_item_id) AS duplicate_items,
    COUNT(DISTINCT order_id)                 AS total_orders
FROM supply_chain_data;



-- Step 7: Create the clean view for the dashboard
-- Purpose: One analysis-ready source for both dashboard pages. It uses the cleaned dates,
--          drops the raw text date columns, and adds helper columns used by the business queries.
CREATE OR REPLACE VIEW supply_chain_clean AS
SELECT
    -- all cleaned columns except the raw text dates
    type, days_for_shipping_real, days_for_shipment_scheduled, benefit_per_order,
    sales_per_customer, delivery_status, late_delivery_risk, category_id, category_name,
    customer_city, customer_country, customer_id, customer_segment, customer_state,
    customer_zipcode, department_id, department_name, latitude, longitude, market,
    order_city, order_country, order_customer_id, order_id, order_item_cardprod_id,
    order_item_discount, order_item_discount_rate, order_item_id, order_item_product_price,
    order_item_profit_ratio, order_item_quantity, sales, order_item_total,
    order_profit_per_order, order_region, order_state, order_status, product_card_id,
    product_category_id, product_name, product_price, shipping_mode,
    order_date,
    shipping_date,

    -- helper columns
    DATE_TRUNC('month', order_date)::DATE AS order_month,
    (days_for_shipping_real - days_for_shipment_scheduled) AS delay_days,
    CASE WHEN delivery_status = 'Late delivery' THEN 1 ELSE 0 END AS is_late,
    CASE WHEN delivery_status = 'Shipping canceled' THEN 1 ELSE 0 END AS is_canceled,
    CASE
        WHEN order_item_discount_rate < 0.05 THEN '0%-5%'
        WHEN order_item_discount_rate < 0.10 THEN '5%-10%'
        WHEN order_item_discount_rate < 0.15 THEN '10%-15%'
        WHEN order_item_discount_rate < 0.20 THEN '15%-20%'
        ELSE '20%-25%'
    END AS discount_range
FROM supply_chain_data;


-- Step 7a (alternative): Verify directly on the table
-- Expected: 180519, 65752, 7754, 98977, 4, 5 or more regions
SELECT
    COUNT(*)                                                  AS total_items,
    COUNT(DISTINCT order_id)                                  AS total_orders,
    COUNT(*) FILTER (WHERE delivery_status = 'Shipping canceled') AS canceled_items,
    COUNT(*) FILTER (WHERE delivery_status = 'Late delivery')     AS late_items,
    COUNT(DISTINCT shipping_mode)                             AS shipping_modes,
    COUNT(DISTINCT order_region)                              AS regions
FROM supply_chain_data;


SELECT * FROM supply_chain_data;






-- =====================================================================
-- BUSINESS PROBLEM 1: DELIVERY DELAYS & SHIPPING PERFORMANCE
-- =====================================================================

-- 1.1 Purpose: Analyze the overall distribution of delivery statuses.
SELECT
    delivery_status,
    COUNT(*) AS total_items,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM supply_chain_data
GROUP BY delivery_status
ORDER BY total_items DESC;


-- 1.2 Purpose: Calculate the overall late delivery risk percentage.
SELECT
    late_delivery_risk,
    COUNT(*) AS total_items,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM supply_chain_data
GROUP BY late_delivery_risk
ORDER BY late_delivery_risk;


-- 1.3 Purpose: Compare late delivery rates across shipping modes.
SELECT
    shipping_mode,
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE delivery_status = 'Late delivery'
    ) AS late_deliveries,
    ROUND(
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late delivery'
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY shipping_mode
ORDER BY late_delivery_percentage DESC;


-- 1.4 Purpose: Compare actual and scheduled shipping days.
SELECT
    ROUND(AVG(days_for_shipping_real), 2) AS avg_actual_shipping_days,
    ROUND(AVG(days_for_shipment_scheduled), 2) AS avg_scheduled_shipping_days,
    ROUND(
        AVG(days_for_shipping_real - days_for_shipment_scheduled),
        2
    ) AS avg_delay_days
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled';


-- 1.5 Purpose: Analyze late deliveries across different order regions.
SELECT
    order_region,
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE delivery_status = 'Late delivery'
    ) AS late_deliveries,
    ROUND(
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late delivery'
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY order_region
ORDER BY late_delivery_percentage DESC;


-- 1.6 Purpose: Analyze monthly delivery performance and late delivery trends.
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE delivery_status = 'Late delivery'
    ) AS late_deliveries,
    ROUND(
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late delivery'
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;


-- 1.7 Purpose: Analyze late delivery rates across product categories.
SELECT
    category_name,
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE delivery_status = 'Late delivery'
    ) AS late_deliveries,
    ROUND(
        COUNT(*) FILTER (
            WHERE delivery_status = 'Late delivery'
        ) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_percentage
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY category_name
ORDER BY late_delivery_percentage DESC;





-- =====================================================================
-- BUSINESS PROBLEM 2: Sales, Profitability & Discount Effectiveness
-- =====================================================================

-- 2.1 Purpose: Analyze overall sales and profit performance.
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_profit_per_order)::NUMERIC, 2) AS average_profit_per_item,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled';


-- 2.2 Purpose: Compare sales and profit across product categories.
SELECT
    category_name,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY category_name
ORDER BY total_sales DESC;


-- 2.3 Purpose: Compare total sales and profit across order regions.
SELECT
    order_region,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY order_region
ORDER BY total_sales DESC;


-- 2.4 Purpose: Analyze sales and profitability across discount rate ranges.
SELECT
    CASE
        WHEN order_item_discount_rate < 0.05 THEN '0%-5%'
        WHEN order_item_discount_rate < 0.10 THEN '5%-10%'
        WHEN order_item_discount_rate < 0.15 THEN '10%-15%'
        WHEN order_item_discount_rate < 0.20 THEN '15%-20%'
        ELSE '20%-25%'
    END AS discount_range,
    COUNT(*) AS total_items,
    ROUND(AVG(order_item_discount_rate)::NUMERIC, 4) AS average_discount_rate,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY 1
ORDER BY MIN(order_item_discount_rate);


-- 2.5 Purpose: Analyze monthly sales and profit trends.
SELECT
    DATE_TRUNC('month', order_date)::DATE AS order_month,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY 1
ORDER BY 1;


-- 2.6 Purpose: Compare sales and profitability across customer segments.
SELECT
    customer_segment,
    COUNT(*) AS total_items,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY customer_segment
ORDER BY total_profit DESC;


-- 2.7 Purpose: Analyze sales and profitability across shipping modes.
SELECT
    shipping_mode,
    COUNT(*) AS total_items,
    ROUND(SUM(sales)::NUMERIC, 2) AS total_sales,
    ROUND(SUM(order_profit_per_order)::NUMERIC, 2) AS total_profit,
    ROUND(SUM(order_profit_per_order) * 100.0 / SUM(sales), 2) AS profit_margin_pct,
    ROUND(AVG(order_item_profit_ratio)::NUMERIC, 4) AS average_profit_ratio
FROM supply_chain_data
WHERE delivery_status <> 'Shipping canceled'
GROUP BY shipping_mode
ORDER BY total_profit DESC;