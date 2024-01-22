SET search_path TO sh;

-- Retrieve the total sales amount for each product category for a specific time period
SELECT
    p.prod_category AS product_category,
    SUM(s.amount_sold) AS total_sales_amount
FROM SALES s
INNER JOIN times t 
ON s.time_id = t.time_id
INNER JOIN products p 
ON s.prod_id = p.prod_id
WHERE t.calendar_year = 1998
GROUP BY p.prod_category;
  
-- Calculate the average sales quantity by region for a particular product
SELECT
    C.CUST_STATE_PROVINCE AS STATE_PROVINCE,
    SUM(S.QUANTITY_SOLD) AS TOTAL_SALES_QUANTITY,
    AVG(S.QUANTITY_SOLD) AS AVERAGE_SALES_QUANTITY
FROM SALES S
INNER JOIN CUSTOMERS C 
ON S.CUST_ID = C.CUST_ID
INNER JOIN PRODUCTS P 
ON S.PROD_ID = P.PROD_ID
WHERE P.PROD_ID = 13
GROUP BY
    C.CUST_STATE_PROVINCE;
  
-- Find the top five customers with the highest total sales amount
SELECT
    c.cust_id AS customer_id,
    c.cust_first_name || ' ' || c.cust_last_name AS customer_name,
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