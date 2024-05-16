SET search_path TO sh;

-- Task 1: The regions with the highest quantity of products sold

-- The query first calculates the total sales for each combination of channel and region.
-- Then, it ranks the regions based on sales within each channel using the ROW_NUMBER() window function.
-- Finally, it filters out the top-ranked regions for each channel and displays the results.

SELECT 
	channel_desc,
	country_region,
	sales,
	TO_CHAR((sales / total_sales * 100.0)::NUMERIC, '999.99' || '%') AS "SALES %"
FROM (
	-- Subquery to calculate sales for each channel and region
	SELECT
        ch.channel_desc,
        co.country_region,
        SUM(s.quantity_sold) AS sales,
        SUM(SUM(s.quantity_sold)) OVER (PARTITION BY ch.channel_desc) AS total_sales, --calculates the total sales for each combination of channel and region using the SUM() aggregation function
        ROW_NUMBER() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.quantity_sold) DESC) AS region_rank --ROW_NUMBER() is applied to assign a rank to each region within its corresponding channel based on sales. This will help identify the region with the highest sales for each channel
    FROM
        sales s
    INNER JOIN
        customers c ON s.cust_id = c.cust_id
    INNER JOIN
        countries co ON c.country_id = co.country_id
    INNER JOIN
        channels ch ON s.channel_id = ch.channel_id
    GROUP BY
        ch.channel_desc,
        co.country_region
    ORDER BY 
    	ch.channel_desc
) region_sales_ranked
WHERE 
	region_rank = 1
ORDER BY 
	sales DESC;



-- Task 2: Identify subcategories with consistently higher sales from 1998 to 2001 compared to the previous year

-- The query calculates sales for each subcategory from 1998 to 2001 and compares them with the previous year's sales.
-- It then filters out subcategories where sales have consistently increased each year.

SELECT 
	prod_subcategory
FROM (
	SELECT
	    p.prod_subcategory,
	    EXTRACT(YEAR FROM t.time_id) AS calendar_year,
	    
--	    SUM(s.amount_sold) AS sales,
--	    COALESCE((LAG(sum(s.amount_sold), 1) OVER (PARTITION BY p.prod_subcategory)), 0) AS previous_year_sales,
	    
	    CASE -- CASE statement checks if the sales for the current year are higher than the previous year. If yes, it assigns a value of 1, indicating higher sales; otherwise, it assigns 0
	    	WHEN (SUM(s.amount_sold) - COALESCE((LAG(sum(s.amount_sold), 1) OVER (PARTITION BY p.prod_subcategory)), 0)) > 0 THEN 1 -- LAG() is applied to retrieve the sales of the previous year for each subcategory. If there is no data for the previous year, it is assumed as 0 since there is no data for 1997
	    	ELSE 0
	    END AS higher
	FROM
	    sales s
	INNER JOIN
	    times t ON s.time_id = t.time_id
	INNER JOIN
	    products p ON s.prod_id = p.prod_id
	WHERE
	    EXTRACT(YEAR FROM t.time_id) BETWEEN 1998 AND 2001
	GROUP BY
	    p.prod_subcategory,
	    EXTRACT(YEAR FROM t.time_id)
	ORDER BY
	    p.prod_subcategory,
	    EXTRACT(YEAR FROM t.time_id)
) sorted
GROUP BY 
	prod_subcategory
HAVING 
	SUM(higher) > 3; -- filters out subcategories where the sum of "higher" values (indicating consistent sales growth) is greater than 3


-- Task 3: Generate a sales report for the years 1999 and 2000, focusing on quarters and product categories

-- The query calculates sales for specific product categories across quarters for the years 1999 and 2000.
-- It then calculates the difference percentage compared to the first quarter of each year and the cumulative sum of sales.
-- The results are aggregated by calendar year, quarter, and product category.

WITH qrtsales AS (
    SELECT
        EXTRACT(YEAR FROM t.time_id) AS calendar_year,
        t.calendar_quarter_desc,
        p.prod_category,
        SUM(s.amount_sold) AS sales$
    FROM
        sales s
    INNER JOIN
        times t ON s.time_id = t.time_id
    INNER JOIN
        products p ON s.prod_id = p.prod_id
    INNER JOIN
        channels c ON s.channel_id = c.channel_id
    WHERE
        EXTRACT(YEAR FROM t.time_id) IN (1999, 2000)
        AND upper(p.prod_category) IN ('ELECTRONICS', 'HARDWARE', 'SOFTWARE/OTHER')
        AND upper(c.channel_desc) IN ('PARTNERS', 'INTERNET')
    GROUP BY
        EXTRACT(YEAR FROM t.time_id),
        t.calendar_quarter_desc,
        p.prod_category
),

total AS (
    SELECT
        calendar_year,
        calendar_quarter_desc,
        prod_category,
        sales$,
        CASE
            WHEN ROW_NUMBER() OVER (PARTITION BY calendar_year, prod_category ORDER BY CALENDAR_quarter_desc) = 1 THEN 'N/A' --assigns a sequential number to each row within its partition based on the quarter's order. This will be used to identify the first quarter in each year
            ELSE ROUND(((sales$ - FIRST_VALUE(sales$) OVER (PARTITION BY calendar_year, prod_category)) / first_value(sales$) OVER (PARTITION BY calendar_year, prod_category ORDER BY calendar_quarter_desc)) * 100, 2) || '%' -- retrieves the first quarter's sales value for each product category and year to calculate the difference percentage
        END AS diff_percent,
        SUM(sales$) OVER (PARTITION BY calendar_year ORDER BY calendar_quarter_desc RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum$ -- calculates the cumulative sum of sales from the beginning of the year to the current quarter
    FROM
        qrtsales
)
SELECT
    calendar_year,
    calendar_quarter_desc,
    prod_category,
    SUM(sales$) AS sales$,
    diff_percent,
    cum_sum$
FROM
    total
GROUP BY
    calendar_year,
    calendar_quarter_desc,
    prod_category,
    diff_percent,
    cum_sum$
ORDER BY
    calendar_year,
    calendar_quarter_desc,
    SUM(sales$) DESC;