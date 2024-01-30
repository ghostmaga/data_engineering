SET search_path TO sh;

-- Retrieve the total sales amount for each product category for a specific time period
SELECT
    p.prod_category AS product_category,
    SUM(s.amount_sold) AS total_sales_amount
FROM sales s
LEFT JOIN products p 
ON s.prod_id = p.prod_id
WHERE EXTRACT (YEAR FROM s.time_id) = 1998
GROUP BY p.prod_category;
  

-- Calculate the average sales quantity by region for a particular product
SELECT
    c2.country_region AS region,
    SUM(s.quantity_sold) AS total_sales_quantity,
    AVG(s.quantity_sold) AS average_sales_quantity
FROM sales s
INNER JOIN customers c 
ON s.cust_id = c.cust_id
INNER JOIN countries c2 
ON c2.country_id = c.country_id 
INNER JOIN products p 
ON s.prod_id = p.prod_id
WHERE p.prod_id = (SELECT prod_id FROM products WHERE upper(prod_name) = '5MP TELEPHOTO DIGITAL CAMERA')
GROUP BY c2.country_region
ORDER BY SUM(s.quantity_sold) DESC;
    

-- Find the top five customers with the highest total sales amount
SELECT
    c.cust_id AS customer_id,
    COALESCE(upper(c.cust_first_name) || ' ' || upper(c.cust_last_name), '') AS customer_name,
    SUM(s.amount_sold) AS total_sales_amount
FROM SALES s
INNER JOIN customers c 
ON s.cust_id = c.cust_id
GROUP BY 
	c.cust_id, 
	customer_name
ORDER BY 
	total_sales_amount DESC
LIMIT 5;