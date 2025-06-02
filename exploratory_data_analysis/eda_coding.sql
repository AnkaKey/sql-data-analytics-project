/* ========================================
1. Database Exploration
======================================== */ 

-- Explore All Objects in the Database

-- INFORMATION_SCHEMA is an internal schema in DB where we have multiple tables 
-- and views to explore the Metadata and Structure of our DB

SELECT * FROM INFORMATION_SCHEMA.TABLES;

-- Explore All CoLumns in the Database

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';

--------------------------------------------------------------------

/* ========================================
--- 2. Dimensions Exploration 
======================================== */ 

-- (Identifying the unique values (or categories) in each dimension.)
-- (Recognizing how data might be groupted or segmented, which is useful for later analysis.)
-- DISTINCT [Dimensions]

-- Explore all countries our customers come from

SELECT DISTINCT country FROM gold.dim_customers;

-- Explore All Product Categories "The Major Divisions"

SELECT DISTINCT category FROM gold.dim_products;

-- Explore All Product Categories & Subcategories "The Major Divisions"

SELECT DISTINCT category, subcategory FROM gold.dim_products;

-- Explore All Product Categories & Subcategories & Product "The Major Divisions"

SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1, 2, 3;

--------------------------------------------------------------------

/* ========================================
--- 3. Date Exploration
======================================== */ 

-- (Identify the earlieat and latest dates (boundries).)
-- (Understand the scope of data and the timespan.)
-- MIN/MAX [Date Dimension]

-- Find the date of the first and last order
-- How many years / months of sales are available

SELECT 
	MIN(order_date) AS first_order_date, 
	MAX(order_date) AS last_order_date,
	DATEDIFF(year, MIN(order_date), MAX(order_date)) AS order_range_years,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- Find the youngest and oldest customer

SELECT
	MIN(birthdate) AS oldest_birthdate, 
	DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
	MAX(birthdate) AS youngest_birthdate,
	DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;

--------------------------------------------------------------------

/* ========================================
--- 4. Measures Eploration (Big Numbers)
======================================== */ 

-- Calculate the key metric of the business (Big Numbers)
-- Highest Level of Aggregation | Lowest Level of Details 
-- SUM([Measure])...

-- Find the total sales

SELECT
	SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Find how many items are sold

SELECT 
	SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Find the avarege selling price

SELECT
	AVG(price) AS avg_price
FROM gold.fact_sales;

-- Find the total number of orders

SELECT 
	COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Find the total number of products
SELECT
	COUNT(product_key) AS total_products -- here no duplicates 
FROM gold.dim_products;

SELECT
	COUNT(product_name) AS total_products -- here no duplicates 
FROM gold.dim_products;

-- Find the total number of customers
SELECT
	COUNT(customer_key) AS total_customers
from gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT
	COUNT(DISTINCT customer_key) AS total_customers
from gold.fact_sales;

--- !!! Generate Report that shows all key metrics of the business

SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL 
SELECT 'Total Products', COUNT(product_name) FROM gold.dim_products
UNION ALL 
SELECT 'Total Number of Products', COUNT(customer_key) FROM gold.dim_customers
UNION ALL 
SELECT 'Total Nr, Cusomers (placed an order)', COUNT(DISTINCT customer_key) FROM gold.fact_sales;

--------------------------------------------------------------------

/* ========================================
--- 5. Magnitude
======================================== */ 

-- Compare the measure values by categories.
-- It helps us understand the importance of different categories.
-- SUM([Measure]) By ([Dimension])

-- Find total customers by countries

SELECT 
	country,
	COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;

-- Find total customers by gender

SELECT 
	gender,
	COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;

-- Find total products by category 

SELECT 
	category,
	COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- What is the average costs in each category?

SELECT 
	category,
	AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC;

-- What is the total revenue generated for each category?

SELECT 
	p.category,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Find total revenue that is generated by each customer?

SELECT 
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- What is the distribution of sold items across countries?

SELECT 
	c.country,
	SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;

--------------------------------------------------------------------

/* ========================================
--- 6. Ranking (Top N - Botton N)
======================================== */ 

-- Order the values of dimendions by measure
-- Top N performers | Bottom N Performers
-- Rank[Dimension] By SUM([Measure])

-- Which 5 products generate the highest revenue?

-- Method 1
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Method 2
SELECT *
FROM (
	SELECT 
		p.product_name,
		SUM(f.sales_amount) AS total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.product_name
	)t
WHERE rank_products <=5

-- What are the 5 worst-performing products in terms of sales?

-- Method 1
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue;

-- Method 2
SELECT *
FROM (
	SELECT 
		p.product_name,
		SUM(f.sales_amount) AS total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount)) AS rank_products
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.product_name
	)t
WHERE rank_products <=5

-- Which 5 subcategories generate the highest revenue?

SELECT TOP 5
	p.subcategory,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC;

-- What are the 5 worst-performing subcategories in terms of sales?

SELECT TOP 5
	p.subcategory,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY p.subcategory
ORDER BY total_revenue;

-- Find the Top-10 custimers who have generated the highest revenue

SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;

-- Find 3 customers with the fewest orders placed
SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders;