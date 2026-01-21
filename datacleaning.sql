
--data cleaning
---approach - make a copy of your data set

--SELECT * INTO sales FROM sales_store

SELECT * FROM sales_store

--perform analysis using the copy you created

SELECT * FROM sales

---1. DATA CLEANING
--check for duplicates. transaction_id column is the primary value because every time you make a payment a unique id IS always created. Hence if there are two entries then  one entry is considered a duplicate

--USE GROUP BY
SELECT
      transaction_id,
	  COUNT(*) total_ids
	  FROM sales
	  GROUP BY transaction_id
	  HAVING count(*) >1;
--use CTE and window function - row_number
WITH duplicates AS(
SELECT
    *,
ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id)rn
FROM sales)

SELECT * FROM duplicates WHERE rn >1;

--confirm if they are duplicates by using IN function

WITH duplicates AS(
SELECT
    *,
ROW_NUMBER() OVER(PARTITION BY transaction_id ORDER BY transaction_id)rn
FROM sales)

---DELETE FROM duplicates WHERE rn>1 4 rows will be deleted

SELECT * FROM sales

--step 2. correct mispelled headers

EXEC sp_rename 'sales.quantiy', 'quantity', 'COLUMN'
EXEC sp_rename 'sales.prce', 'price', 'COLUMN'


--step 3. check data type

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales'

--step 4. check for nulls
--check null count
--delete the first record where transaction_id is null. this is showing up as an outlier

SELECT *
FROM sales 
WHERE transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR
product_id IS NULL
OR
product_name IS NULL
OR
product_category IS NULL
OR
quantity IS NULL
or
payment_mode is null
or
purchase_date is null
or 
status is null
or 
price is null



--DELETE FROM sales
--WHERE transaction_id IS NULL

--next, check for customer_id IS NULL. lookup customer_name for missing customer_id
--update table with the customer_id found by data profiling

SELECT * FROM sales WHERE customer_name = 'Ehsaan Ram'
SELECT * FROM sales WHERE customer_ID = 'CUST1003'
-

UPDATE sales
SET customer_name = 'Mahika Saini', customer_age = 35, gender = 'Male'
WHERE customer_id = 'CUST1003' and transaction_id = 'TXN432798'

--Step 5 standardize data
--starndardize gender column
--starndardize payment_mode column
SELECT * FROM sales

SELECT DISTINCT payment_mode from sales



UPDATE sales
SET payment_mode = 'Credit Card'
WHERE payment_mode = 'CC'

---SOLVE BUSINESS REQUIREMENTS

--1. What are the top 5 most selling products by quantity?
--business problem - we did not know which products are most in demand
--business impact - helps prioritize stock and boost sales through targeted promotions.

SELECT TOP 5
    product_name,
	sum(quantity) total_products
	FROM sales
	WHERE status = 'delivered'
	GROUP BY product_name
	ORDER BY sum(quantity) desc

--2. Which products are most frequently cancelled
--Business problem- frequent cancellations affect revenue and customer trust.
--Business impact - identify products that can be improved  or removed from the catalog

SELECT time_of_purchase FROM sales

 SELECT TOP 5
    product_name,
	COUNT(*) total_cancelled
	FROM sales
	WHERE status = 'cancelled'
	GROUP BY product_name
	ORDER BY count(*) DESC
--3. what time of the day has the highest number of purchases? PEAK ours
--use CASE statement to categories time of purchase
--business impact - Optimize staffing, promotions, check stocks and server loads


WITH t as(
SELECT 
	CASE
	    WHEN DATEPART(HOUR, time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
		WHEN DATEPART(HOUR, time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
		WHEN DATEPART(HOUR, time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
		WHEN DATEPART(HOUR, time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
		END AS time_of_day
	
FROM sales)

SELECT 
   time_of_day,
   COUNT(*) as total_orders
   FROM t
   GROUP BY time_of_day

      
--who are the top 5 highest spending customers?
--Business problem solved: Identify VIP customers
--Business impact: Personalized offers, loyalty rewards, and retention

SELECT * FROM sales
--C stands for currency in the format syntax
SELECT top 5
     customer_name,
	 FORMAT(SUM(quantity * price), 'C0') AS total_spend
FROM sales
GROUP BY customer_name
ORDER BY SUM(quantity * price) desc

--Which product category generates the highest revenue (
--business impact; refine product strategy, supply chain, and promotions.
--this will allow the business to invest more in high-margin or high- demand categories
SELECT * FROM sales

SELECT TOP 5 product_category,
FORMAT(SUM(quantity * price), 'C0') total_revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(quantity * price) desc


--what is the return/ cancellation rate per product category?
--In the format table N stands for number

SELECT product_category,
	FORMAT(COUNT(CASE WHEN status = 'cancelled' THEN 1 END)*100.0/COUNT(*),'N2')+' %' as cancelled_percentage
	FROM sales
	GROUP BY product_category
	ORDER BY COUNT(CASE WHEN status = 'cancelled' THEN 1 END)*100.0/COUNT(*) DESC ;

--for returns
--Business problem solved; Monitor dissatisfaction trends per category
--business impact; reduce returns, improve product descriptions/expectations
--help identify and fix product or logistic issues.

SELECT product_category,
	FORMAT(COUNT(CASE WHEN status = 'returned' THEN 1 END)*100.0/COUNT(*),'N2')+' %' as returned_percentage
	FROM sales
	GROUP BY product_category
	ORDER BY COUNT(CASE WHEN status = 'returned' THEN 1 END)*100.0/COUNT(*) DESC ;

--what is the most preferred payment mode
--Business problem solved; know which payment options customers prefer.
--business impact; streamline payment processing, prioritize popular modes

SELECT * FROM sales

SELECT
  payment_mode,
  COUNT(*) preferred_pyt_mode
  FROM sales
  GROUP BY payment_mode
  ORDER BY count(*) desc

--how does the age group affect purchasing behavior?
--business problem solved; understand customer demographics
--Targeted marketing and product recommendations by age group
SELECT * FROM sales

SELECT 
 CASE
    WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
	WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
	ELSE '51+'
	END AS customer_age,
	FORMAT(SUM(quantity * price),'C0') as total_sales
from SALES
GROUP BY  CASE
    WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
	WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
    WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
	ELSE '51+'
	END
	ORDER BY SUM(quantity * price)  desc
--what is the monthly sales trend?  
--sales fluctuations go unnoticed
--business impact - plan inventory and marketing according to seasonal trends.

SELECT
     YEAR(purchase_date) as years,
	 MONTH(purchase_date) as months,
	 FORMAT(SUM(price*quantity), 'C0')as total_sales,
	 SUM(quantity)as total_quantity
FROM sales
GROUP BY  YEAR(purchase_date),
	 MONTH(purchase_date)
ORDER BY  SUM(price*quantity)  desc

--are certain genders buying more specific product categories?
SELECT * FROM sales
     
SELECT
    gender,
	product_category,
	FORMAT(SUM(quantity * price),'C0') total_sales
	FROM sales
	GROUP BY gender, product_category
	ORDER BY sum(quantity * price) desc


--USE COUNT to count how many times products are being bought by each gender
--use PIVOT to pivot the table
--Business problem - gender based product preferences
--business impact - personalized ads, gender_focused campaigns
SELECT * FROM(
             SELECT gender, product_category
					FROM sales) as source_table
PIVOT(COUNT (gender)
      FOR gender IN(F,M)) as pivot_table
	  ORDER BY product_category



