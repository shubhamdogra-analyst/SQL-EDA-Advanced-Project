/*
===============================================================================
Database Exploration
===============================================================================
Purpose:
    - To explore the structure of the database, including the list of tables and their schemas.
    - To inspect the columns and metadata for specific tables.

Table Used:
    - INFORMATION_SCHEMA.TABLES
    - INFORMATION_SCHEMA.COLUMNS
===============================================================================
*/

-- Retrieve a list of all tables in the database
SELECT 
    TABLE_CATALOG, 
    TABLE_SCHEMA, 
    TABLE_NAME, 
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES;

-- Retrieve all columns for a specific table (dim_customers)
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE, 
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers';


-- Explore All Objects in the Database
SELECT * FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'



/*
===============================================================================
Dimensions Exploration
===============================================================================
Purpose:
    - To explore the structure of dimension tables.
	
SQL Functions Used:
    - DISTINCT
    - ORDER BY
===============================================================================
*/

-- Retrieve a list of unique countries from which customers originate
SELECT DISTINCT country FROM gold.dim_customers

-- Explore All Categories "The major Divisions"
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3



/*
===============================================================================
Date Range Exploration 
===============================================================================
Purpose:
    - To determine the temporal boundaries of key data points.
    - To understand the range of historical data.

SQL Functions Used:
    - MIN(), MAX(), DATEDIFF()
===============================================================================
*/

-- Find the date of the	first and last order
-- How many years of sales are available
-- How many months of sales are available
SELECT 
	MIN(order_date) AS First_Order_Date,
	MAX(order_date) AS Last_Order_Date,
	DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) AS Order_Range_years,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS Order_Range_months
FROM gold.fact_sales

-- Find the youngest and oldest customer
SELECT
	MIN(birthdate) AS First_Birthdate,
	DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS Oldest_Age,
	MAX(birthdate) AS Last_Birthdate,
	DATEDIFF(YEAR,MAX(birthdate),GETDATE()) AS Yongest_Age
FROM gold.dim_customers


/*
===============================================================================
Measures Exploration (Key Metrics)
===============================================================================
Purpose:
    - To calculate aggregated metrics (e.g., totals, averages) for quick insights.
    - To identify overall trends or spot anomalies.

SQL Functions Used:
    - COUNT(), SUM(), AVG()
===============================================================================
*/

-- Find the Total Sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

-- Find how many itemes are sold
SELECT SUM(quantity) AS total_qunatity FROM gold.fact_sales

-- Find the average selling price 
SELECT AVG(price) AS avg_price FROM gold.fact_sales

-- Find the Total number of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales
SELECT COUNT(DISTINCT(order_number)) AS total_orders FROM gold.fact_sales

-- Find the total number of products
SELECT COUNT(product_name) AS total_product FROM gold.dim_products
SELECT COUNT(DISTINCT(product_name)) AS total_product FROM gold.dim_products

-- Find the total number of customers
SELECT COUNT(customer_key) AS total_customrs FROM gold.dim_customers 

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT(customer_key)) AS total_customrs FROM gold.fact_sales


-- Generate a Report that show all key metrics of the business

SELECT 'Total Sales' AS measure_name,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' AS measure_name,SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average Price' AS measure_name,AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders' AS measure_name,COUNT(DISTINCT(order_number)) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Products' AS measure_name,COUNT(product_name) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total Customers' AS measure_name,COUNT(customer_key) AS measure_value FROM gold.dim_customers


/*
===============================================================================
Magnitude Analysis
===============================================================================
Purpose:
    - To quantify data and group results by specific dimensions.
    - For understanding data distribution across categories.

SQL Functions Used:
    - Aggregate Functions: SUM(), COUNT(), AVG()
    - GROUP BY, ORDER BY
===============================================================================
*/

-- Find total customers by countries
SELECT 
	country,
	COUNT(customer_key) AS Total_Customer
FROM gold.dim_customers
GROUP BY country
ORDER BY Total_Customer DESC

-- Find total customers by gender
SELECT
	gender,
	COUNT(customer_key) AS Total_Customer
FROM gold.dim_customers
GROUP BY gender
ORDER BY Total_Customer DESC

-- Find total products by category
SELECT
	category,
	COUNT(product_key) AS Total_Customer
FROM gold.dim_products
GROUP BY category
ORDER BY Total_Customer DESC

-- What is the average cost in each category?
SELECT
	category,
	AVG(cost) AS Avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY Avg_cost DESC

-- What is the total revenue genearated for each category?
SELECT
	p.category,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- What is the total revenue generated by each customer?
SELECT
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key 
GROUP BY	
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC

-- What is the distribution of sold items across countries?
SELECT
	c.country,
	SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key 
GROUP BY	
	c.country
ORDER BY total_sold_items DESC

select top 10 * from gold.dim_products
select distinct(maintenance) from gold.dim_products
select top 10 * from gold.fact_sales
where quantity < 0


/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.

SQL Functions Used:
    - Window Ranking Functions: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
    - Clauses: GROUP BY, ORDER BY
===============================================================================
*/

-- Which 5 products generate the highest revenue?
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC

SELECT
*
FROM (
	SELECT
		p.product_name,
		SUM(f.sales_amount) total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount)) AS rank_product
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
		ON p.product_key = f.product_key
	GROUP BY p.product_name)t
WHERE rank_product <= 5

-- What are the 5 worst-performing products in term of sales
SELECT TOP 5
	p.product_name,
	SUM(f.sales_amount) total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC

-- Find the top 10 customers who have generate the highest revenue 
SELECT TOP 10
	c.customer_key,
	c.first_name,
	c.last_name,
	SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key 
GROUP BY	
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_revenue DESC

-- The 3 customers with the fewest orders placed
SELECT TOP 3
	c.customer_key,
	c.first_name,
	c.last_name,
	COUNT(DISTINCT(f.order_number)) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key 
GROUP BY	
	c.customer_key,
	c.first_name,
	c.last_name
ORDER BY total_orders ASC

-- COMPLETE EDA 

/*=======================================================================================================================================*/

/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

SQL Functions Used:
    - Date Functions: DATEPART(), DATETRUNC(), FORMAT()
    - Aggregate Functions: SUM(), COUNT(), AVG()
===============================================================================
*/

-- Analyse sales performance over time
-- Quick Date Functions

SELECT 
	YEAR(order_date) AS order_year,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT(customer_key)) AS total_customer,
	SUM(quantity) as total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date)

SELECT 
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT(customer_key)) AS total_customer,
	SUM(quantity) as total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date)

SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT(customer_key)) AS total_customer,
	SUM(quantity) as total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	YEAR(order_date),
	MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)

-- DATETRUNC
SELECT 
	DATETRUNC(MONTH,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT(customer_key)) AS total_customer,
	SUM(quantity) as total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	DATETRUNC(MONTH,order_date)
ORDER BY DATETRUNC(MONTH,order_date)

-- FORMAT
SELECT 
	FORMAT(order_date,'yyyy-MMM') AS order_date,
	SUM(sales_amount) AS total_sales,
	COUNT(DISTINCT(customer_key)) AS total_customer,
	SUM(quantity) as total_quantity 
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 
	FORMAT(order_date,'yyyy-MMM')
ORDER BY FORMAT(order_date,'yyyy-MMM')

/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.

SQL Functions Used:
    - Window Functions: SUM() OVER(), AVG() OVER()
===============================================================================
*/

-- Calculate the total sales per month 
-- and the running total of sales over time

SELECT
	DATETRUNC(MONTH,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	SUM(SUM(sales_amount)) OVER (ORDER BY DATETRUNC(MONTH,order_date) ASC 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date)
ORDER BY DATETRUNC(MONTH,order_date)

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM (
SELECT
	DATETRUNC(MONTH,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
	FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date))t
ORDER BY order_date

-- Partition by Year

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM (
SELECT
	DATETRUNC(MONTH,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
	FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH,order_date))t

-- Running total by year

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales
FROM (
SELECT
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales
	FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date))t
ORDER BY order_date

-- moving average of price also

SELECT
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS moving_avg_price
FROM (
SELECT
	DATETRUNC(YEAR,order_date) AS order_date,
	SUM(sales_amount) AS total_sales,
	AVG(price) AS avg_price
	FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR,order_date))t
ORDER BY order_date

/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.

SQL Functions Used:
    - LAG(): Accesses data from previous rows.
    - AVG() OVER(): Computes average values within partitions.
    - CASE: Defines conditional logic for trend analysis.
===============================================================================
*/

/* Analyze the yearly performance of products by comparing their sales 
to both the average sales performance of the product and the previous year's sales */

WITH yearly_product_sales AS(
SELECT
	YEAR(f.order_date) AS order_year,
	p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key 
WHERE f.order_date IS NOT NULL
GROUP BY 
	YEAR(f.order_date),
	p.product_name
)
SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
	 WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
	 ELSE 'Avg'
END AS avg_change,
--Year-Over-Year Analysis
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) > 0 THEN 'Insrease'
	 WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year ASC) < 0 THEN 'Decrease'
	 ELSE 'No Change'
END AS py_change
FROM yearly_product_sales
ORDER BY product_name,order_year



/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.

SQL Functions Used:
    - SUM(), AVG(): Aggregates values for comparison.
    - Window Functions: SUM() OVER() for total calculations.
===============================================================================
*/
-- Which categories contribute the most to overall sales?

SELECT
*,
(total_sales * 100.0) / SUM(total_sales) OVER() AS contribution
FROM(
	SELECT
	p.category,
	SUM(f.sales_amount) AS total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.category)t

-- Another way to solve same question
WITH catagory_sales AS
(
	SELECT
	p.category,
	SUM(f.sales_amount) AS total_sales
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	GROUP BY p.category)
SELECT
	category,
	total_sales,
	SUM(total_sales) OVER() AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER())*100,2),'%') AS percentage_of_total 
FROM catagory_sales
ORDER BY total_sales DESC


/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.

SQL Functions Used:
    - CASE: Defines custom segmentation logic.
    - GROUP BY: Groups data into segments.
===============================================================================
*/

/*Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segment AS
(
	SELECT
		product_key,
		product_name,
		cost,
		CASE WHEN cost < 100 THEN 'Below 100' 
			 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
			 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
			 ELSE 'above 1000'
		END cost_range
	FROM gold.dim_products)

SELECT 
	cost_range,
	COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than 5,000.
	- Regular: Customers with at least 12 months of history but spending 5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/

WITH customer_Sales_data AS
(
	SELECT
		c.customer_key,
		SUM(f.sales_amount) total_spend,
		MAX(f.order_date) AS last_order_date,
		MIN(f.order_date) AS first_order_date,
		DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS lifespan_month
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY 
		c.customer_key
),

customer_category AS
(	
	SELECT
		customer_key,
		total_spend,
		lifespan_month,
		CASE WHEN lifespan_month >=12 AND total_spend > 5000 THEN 'VIP'
			 WHEN lifespan_month >=12 AND total_spend <= 5000 THEN 'Regular'
			 ELSE 'New'
	END AS customer_types
	FROM customer_Sales_data
)

SELECT
	customer_types,
	COUNT(customer_key) AS no_of_customers
FROM customer_category
GROUP BY customer_types
ORDER BY COUNT(customer_key) DESC 

-- Another way to solve thw same question

WITH customer_Sales_data AS
(
	SELECT
		c.customer_key,
		SUM(f.sales_amount) total_spend,
		MAX(f.order_date) AS last_order_date,
		MIN(f.order_date) AS first_order_date,
		DATEDIFF(MONTH,MIN(f.order_date),MAX(f.order_date)) AS lifespan_month
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON f.customer_key = c.customer_key
	GROUP BY 
		c.customer_key)

SELECT
	customer_segment,
	COUNT(customer_key) AS total_customer
FROM(
	SELECT
	customer_key,
	CASE WHEN lifespan_month >=12 AND total_spend > 5000 THEN 'VIP'
		 WHEN lifespan_month >=12 AND total_spend <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment
	FROM customer_Sales_data)t
GROUP BY customer_segment
ORDER BY total_customer DESC

/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

CREATE VIEW gold.report_customers AS

WITH base_query AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
	SELECT
		f.order_number,
		f.product_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
		DATEDIFF(YEAR,c.birthdate,GETDATE()) AS age
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = f.customer_key
	WHERE order_date IS NOT NULL
)

, customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
	SELECT
		customer_key,
		customer_number,
		customer_name, 
		age,
		COUNT(DISTINCT(order_number)) AS total_orders,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		COUNT(DISTINCT(product_key)) AS total_products,
		MAX(order_date) AS last_order_date,
		DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan
	FROM base_query
	GROUP BY
		customer_key,
		customer_number,
		customer_name, 
		age
)
SELECT
	customer_key,
	customer_number,
	customer_name, 
	age,
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
		 WHEN age BETWEEN 30 AND 39 THEN '30-39'
		 WHEN age BETWEEN 40 AND 49 THEN '40-49'
		 ELSE '50 and Above'
	END AS age_group,
	CASE WHEN lifespan >=12 AND total_sales > 5000 THEN 'VIP'
		 WHEN lifespan >=12 AND total_sales <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS customer_segment,
	last_order_date,
	DATEDIFF(MONTH,last_order_date,GETDATE()) AS recency,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	lifespan,
-- Compuate average order value (AVO)
	CASE WHEN total_sales = 0 THEN 0
		 ELSE total_sales / total_orders
	END AS avg_order_value,

--Compute Aberage monthly spend
	CASE WHEN lifespan = 0 THEN total_sales
		 ELSE total_sales / lifespan
	END AS avg_monthly_spend
FROM customer_aggregation

--View Final 
SELECT * FROM GOLD.report_customers



/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quan	tity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/


CREATE VIEW gold.report_products AS
WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
	SELECT
		f.order_number,
		f.product_key,
		f.customer_key,
		f.order_date,
		f.sales_amount,
		f.quantity,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	WHERE order_date IS NOT NULL
)

,product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT 
	product_name,
	category,
	subcategory,
	cost,
	COUNT(DISTINCT(order_number)) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT(customer_key)) AS total_customers,
	DATEDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_order_date,
	sales
FROM base_query
GROUP BY 
		product_name,
		category,
		subcategory,
		cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT
	product_name,
	category,
	subcategory,
	cost,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	lifespan,
	last_order_date,
	CASE WHEN total_sales > 50000 THEN 'High-Performers'
		 WHEN total_sales >= 10000 THEN 'Mid-Range'
		 ELSE 'Low-Performers'
	END AS product_segments,
	DATEDIFF(MONTH,last_order_date,GETDATE()) AS recencys,
-- Average Order Revenue (AOR)
	CASE WHEN total_orders = 0 THEN 0
		 ELSE total_sales / total_orders
	END AS avg_order_revenue,

-- Average Monthly Revenue
	CASE WHEN lifespan = 0 THEN total_sales
		 ELSE total_sales/lifespan
	END AS avg_monthly_revenue
FROM product_aggregations
