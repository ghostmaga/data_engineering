SET search_path TO sh;

CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Task 1

-- CTE to rank customers within each sales channel based on total sales
WITH ranked AS ( --
    SELECT
        s.cust_id,
        c.channel_desc,
        SUM(s.amount_sold) AS total_sales, -- sums out total sales of each customer 
        RANK() OVER (PARTITION BY c.channel_desc ORDER BY SUM(s.amount_sold) DESC) AS sales_rank
    FROM
        sales s
    INNER JOIN channels c 
    	  ON s.channel_id = c.channel_id
    GROUP BY
        s.cust_id, 
        c.channel_desc
)
-- The main query then selects the top 5 customers for each channel and calculates the 'sales_percentage' 
-- 	using the total sales and the overall total sales within each channel
SELECT
    channel_desc,
    cust_id,
    ROUND(total_sales, 2) AS total_sales_amount, -- Display the total sales amount with two decimal places
    TO_CHAR((total_sales / SUM(total_sales) OVER (PARTITION BY channel_desc) * 100), 'FM999.9999') || '%' AS sales_percentage
FROM
    ranked
WHERE
   sales_rank <= 5
ORDER BY
	channel_desc, 
   total_sales DESC;

   -- Task 2
 
SELECT
    p.prod_name AS product_name,
    TO_CHAR(SUM(s.amount_sold), 'FM999999.00') AS sales_amount
    --TO_CHAR(SUM(s.amount_sold) OVER (), 'FM9999999990.00') AS "YEAR_SUM"
FROM
    sales s
INNER JOIN
    products p ON s.prod_id = p.prod_id
INNER JOIN
    customers cu ON s.cust_id = cu.cust_id
INNER JOIN
    countries co ON cu.country_id = co.country_id
WHERE
    EXTRACT(YEAR FROM s.time_id) = 2000
    AND upper(p.prod_category) = 'PHOTO'
    AND upper(co.country_region) = 'ASIA'
GROUP BY
    p.prod_name
ORDER BY
    SUM(s.amount_sold) DESC;


   -- Task 3
WITH ranked AS (
    SELECT
        COALESCE (upper(c2.cust_first_name) || ' ' || upper(c2.cust_last_name), '') AS customer_name,
        c.channel_desc,
        SUM(s.amount_sold) AS total_sales,
        RANK() OVER (PARTITION BY c.channel_desc ORDER BY SUM(s.amount_sold) DESC) AS sales_rank
    FROM
        sales s
    INNER JOIN
        channels c ON s.channel_id = c.channel_id
    INNER JOIN
    	  customers c2 ON c2.cust_id = s.cust_id
    WHERE
        EXTRACT(YEAR FROM s.time_id) IN (1998, 1999, 2001)
    GROUP BY
        c.channel_desc, s.cust_id, c2.cust_first_name, c2.cust_last_name
)

SELECT
    channel_desc,
    customer_name,
    ROUND(total_sales, 2) AS total_sales
FROM
    ranked
WHERE
    sales_rank <= 300
--GROUP BY 
--	 channel_desc, customer_name, total_sales
ORDER BY
    channel_desc, total_sales DESC;

   -- Task 4
   
SELECT
    TO_CHAR(SUM(s.amount_sold), 'FM9999999990.00') AS sales_amount,
    TO_CHAR(TO_DATE(t.calendar_month_desc, 'YYYY-MM'), 'Month YYYY') AS month_year,
    co.country_region,
    p.prod_name
FROM
    sales s
INNER JOIN
    times t ON s.time_id = t.time_id
INNER JOIN
    customers cu ON s.cust_id = cu.cust_id
INNER JOIN
    countries co ON cu.country_id = co.country_id
INNER JOIN
    products p ON s.prod_id = p.prod_id
WHERE
    TO_DATE(t.calendar_month_desc, 'YYYY-MM') BETWEEN TO_DATE('2000-01', 'YYYY-MM') AND TO_DATE('2000-03', 'YYYY-MM')
    AND upper(co.country_region) IN ('EUROPE', 'AMERICAS')
GROUP BY
    TO_DATE(t.calendar_month_desc, 'YYYY-MM'), 
    co.country_region, 
    p.prod_name
ORDER BY
    TO_DATE(t.calendar_month_desc, 'YYYY-MM'), 
    p.prod_name, 
    co.country_region;
