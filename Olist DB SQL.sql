
/* 
	Olist DB Data Exploration
*/

SELECT DISTINCT(customer_id)
FROM olist_db.customers;
SELECT DISTINCT(order_id)
FROM olist_db.orders;
SELECT DISTINCT(product_id)
FROM olist_db.products;
SELECT DISTINCT(seller_id)
FROM olist_db.sellers;
SELECT DISTINCT(product_category_name)
FROM olist_db.product_category_translation;


-- Performance Matrics - Total Revenue

SELECT
    SUM(payment_value) AS total_payment
FROM payments p;


-- Average Transaction Value


WITH avg_transaction AS (
SELECT
	order_id,
    SUM(p.payment_value) AS total_payment
FROM payments p
GROUP BY order_id
	)
SELECT 
	ROUND(AVG(total_payment),2) AS avg_transaction_value
FROM avg_transaction;

-- Trend Analysis - Yearly Analysis


SELECT 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%M') as transaction_month,
	FORMAT(SUM(p.payment_value),2) as monthly_revenue
FROM payments p
JOIN orders o
	ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY transaction_month
ORDER BY transaction_month ASC;


-- Monthly Analysis


SELECT 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y') as transaction_year,
	FORMAT(SUM(p.payment_value),2) as yearly_revenue
FROM payments p
JOIN orders o
	ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY transaction_year
ORDER BY transaction_year ASC;

-- Top 15 paying - customers


SELECT
	c.customer_id AS customers,
    FORMAT(SUM(p.payment_value),2) as payment
FROM payments p
	JOIN orders o ON o.order_id = p.order_id
    JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY payment DESC
LIMIT 15;


-- Average review score per product category

SELECT
	p.product_category_name AS product_description,
    AVG(r.review_score) AS avg_review_rating,
	COUNT(r.review_id) AS total_reviews
FROM reviews r
	JOIN order_items o ON o.order_id = r.order_id
	JOIN products p ON p.product_id = o.product_id
GROUP BY product_description
ORDER BY avg_review_rating DESC;


-- Orders that were delivered Early, On Time, or Late 


SELECT 
    CASE 
        WHEN DATE_FORMAT(order_delivered_customer_date, '%Y-%m-%d') < DATE_FORMAT(order_estimated_delivery_date, '%Y-%m-%d') THEN 'Early'
        WHEN DATE_FORMAT(order_delivered_customer_date, '%Y-%m-%d') = DATE_FORMAT(order_estimated_delivery_date, '%Y-%m-%d') THEN 'On Time'
        WHEN DATE_FORMAT(order_delivered_customer_date, '%Y-%m-%d') > DATE_FORMAT(order_estimated_delivery_date, '%Y-%m-%d') THEN 'Late'
        ELSE 'Not Delivered'
    END AS delivery_status,

    COUNT(*) AS total_orders
FROM orders
GROUP BY delivery_status
ORDER BY total_orders DESC;

-- Products are priced above the average product price 


SELECT
	p.product_category_name as product_name,
    o.price 
FROM order_items o
JOIN products p ON p.product_id = o.product_id
	WHERE price > (
    SELECT 
		ROUND(AVG(price),2) 
        FROM order_items
    );


-- Rank Sellers by Total Revenue 


SELECT 
    seller_id,
    SUM(price) AS total_revenue,
    RANK() OVER (ORDER BY SUM(price) DESC) AS revenue_rank
FROM order_items
GROUP BY seller_id;


-- Running Total Revenue Over Time


 SELECT 
    DATE(o.order_purchase_timestamp) AS transaction_date,
    SUM(oi.price) AS daily_revenue,
    SUM(SUM(oi.price)) OVER (
        ORDER BY DATE(o.order_purchase_timestamp)
    ) AS running_total
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY transaction_date
ORDER BY transaction_date;       
	
    
-- WWhich product categories generate the highest revenue?     
SELECT 
    p.product_category_name as product_name,
    SUM(oi.price + oi.freight_value) AS product_revenue
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY product_name
ORDER BY product_revenue DESC
LIMIT 10;


-- What is the average delivery time (order purchase to delivery date)? 


SELECT 
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, 
                       order_purchase_timestamp)), 2) 
    AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
 AND order_status = 'delivered';


-- What are the top 10 best-selling products by revenue and by quantity? 


SELECT 
    p.product_id,
    p.product_category_name as product_desc,
	COUNT(oi.order_id) as order_quantity,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_id
ORDER BY total_revenue DESC
LIMIT 10;


-- What are the most frequently used payment types and their total revenue contribution? 


SELECT 
	payment_type,
    COUNT(*) as transaction_per_payment_type,
    SUM(p.payment_value) as payment_transaction
 FROM payments p
 GROUP BY p.payment_type
 ORDER BY transaction_per_payment_type DESC;
 
 
 -- “Which product categories generate the highest revenue per month, and how does this trend change over time?
 
 
CREATE OR REPlACE VIEW monthly_category_revenue AS 
SELECT 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS year_month_transaction,
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value),2) AS revenue
FROM order_items oi
		JOIN orders o ON oi.order_id = o.order_id
        JOIN products p ON p.product_id =  oi.product_id
GROUP BY year_month_transaction, p.product_category_name;