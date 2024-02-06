SET SEARCH_PATH TO PUBLIC;

--Task 1
--Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue 
--for the current quarter. The view should only display categories with at least one sale in the current quarter. 

CREATE OR REPLACE VIEW SALES_REVENUE_BY_CATEGORY_QTR AS
SELECT upper(C.NAME) AS CATEGORY_NAME, SUM(P.AMOUNT) AS TOTAL_SALES_REVENUE
FROM PAYMENT P 
INNER JOIN RENTAL R 
ON P.RENTAL_ID = R.RENTAL_ID 
INNER JOIN INVENTORY I 
ON R.INVENTORY_ID = I.INVENTORY_ID 
INNER JOIN FILM F 
ON I.FILM_ID = F.FILM_ID 
INNER JOIN FILM_CATEGORY FC 
ON F.FILM_ID = FC.FILM_ID 
INNER JOIN CATEGORY C 
ON FC.CATEGORY_ID = C.CATEGORY_ID 
WHERE EXTRACT (QUARTER FROM P.PAYMENT_DATE) = EXTRACT(QUARTER FROM CURRENT_DATE) 
AND EXTRACT(YEAR FROM P.PAYMENT_DATE) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY upper(C.NAME)
ORDER BY TOTAL_SALES_REVENUE DESC;

-- TEST CALL
SELECT * FROM SALES_REVENUE_BY_CATEGORY_QTR; 

--Task 2
--Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter
--representing the current quarter and returns the same result as the 'sales_revenue_by_category_qtr' view.

CREATE OR REPLACE FUNCTION GET_SALES_REVENUE_BY_CATEGORY_QTR(QTR_DATE DATE)
RETURNS TABLE (CATEGORY_NAME TEXT, TOTAL_SALES_REVENUE NUMERIC) AS
$$
    SELECT 
        upper(C.NAME) AS CATEGORY_NAME,
        SUM(P.AMOUNT) AS TOTAL_SALES_REVENUE
    FROM  
        FILM_CATEGORY FC
        JOIN CATEGORY C ON FC.CATEGORY_ID = C.CATEGORY_ID
        JOIN INVENTORY I ON FC.FILM_ID = I.FILM_ID
        JOIN RENTAL R ON I.INVENTORY_ID = R.INVENTORY_ID
        JOIN PAYMENT P ON R.RENTAL_ID = P.RENTAL_ID
    WHERE 
        EXTRACT(QUARTER FROM QTR_DATE) = EXTRACT(QUARTER FROM P.PAYMENT_DATE)
        AND EXTRACT(YEAR FROM QTR_DATE) = EXTRACT(YEAR FROM P.PAYMENT_DATE)
    GROUP BY 
        upper(C.NAME);
$$
LANGUAGE SQL;

-- TEST CALL
SELECT * FROM get_sales_revenue_by_category_qtr('2017-04-01'); 

--Task 3
--Create a function that takes a country as an input parameter and returns the most popular film in that specific country.

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE (country TEXT, film_title TEXT, film_rating MPAA_RATING, film_language bpchar(20), film_length INT2, film_release_year "year") AS
$$
BEGIN
    -- Check if the input array is empty
    IF array_length(countries, 1) IS NULL THEN
        RAISE NOTICE 'Empty array provided';
        RETURN;
    END IF;

    -- Check if any of the countries are invalid (do not exist in the database)
    IF EXISTS (
        SELECT 1
        FROM unnest(countries) AS country_name
        LEFT JOIN country c ON UPPER(c.country) = UPPER(country_name)
        WHERE c.country_id IS NULL
    ) THEN
        RAISE NOTICE 'Invalid countries provided.';
        RETURN;
    END IF;

    RETURN QUERY
    SELECT DISTINCT ON (co.country)
        co.country,
        f.title AS film_title,
        f.rating AS film_rating,
        l.name AS film_language,
        f.length AS film_length,
        f.release_year AS film_release_year
    FROM
        film f
        INNER JOIN inventory i ON f.film_id = i.film_id
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN customer cu ON r.customer_id = cu.customer_id
        INNER JOIN address a ON cu.address_id = a.address_id
        INNER JOIN city ci ON a.city_id = ci.city_id
        INNER JOIN country co ON ci.country_id = co.country_id
        INNER JOIN language l ON f.language_id = l.language_id
    WHERE
        UPPER(co.country) IN (SELECT UPPER(unnest) FROM unnest(countries))
    GROUP BY
        co.country, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY
        co.country, COUNT(*) DESC;  -- order by country and count
END;
$$
LANGUAGE 'plpgsql';

-- TEST CALL
SELECT * FROM most_popular_films_by_countries(array['AUSTRALIA','CANADA','UNITED STATES']::TEXT[]);

--Task 4
--Create a function that generates a list of movies available in stock based on a partial title match 
--(e.g., movies containing the word 'love' in their title).

CREATE OR REPLACE FUNCTION FILMS_IN_STOCK_BY_TITLE(PARTIAL_TITLE TEXT)
RETURNS TABLE (ROW_NUM INTEGER, FILM_TITLE TEXT, FILM_LANGUAGE BPCHAR(20), CUSTOMER_NAME TEXT, RENTAL_DATE TEXT) AS
$$
BEGIN
	 -- Check if movies are found but none are in stock
    IF NOT EXISTS (
        SELECT 1 
        FROM FILM
        LEFT JOIN INVENTORY ON FILM.FILM_ID = INVENTORY.FILM_ID
        WHERE FILM.TITLE ILIKE PARTIAL_TITLE AND INVENTORY_IN_STOCK(INVENTORY.INVENTORY_ID)
    ) THEN
        RAISE NOTICE 'NONE ARE IN STOCK';
        RETURN;
    END IF;
   
    RETURN QUERY
    SELECT DISTINCT ON (FILM.FILM_ID)
        ROW_NUMBER() OVER (ORDER BY FILM.FILM_ID)::INTEGER AS ROW_NUM,
        FILM.TITLE AS FILM_TITLE,
        LANGUAGE.NAME AS FILM_LANGUAGE,
        COALESCE(CUSTOMER.FIRST_NAME || ' ' || CUSTOMER.LAST_NAME, 'Not Rented') AS CUSTOMER_NAME, --not rented text if customer name not applicable for never rented film in stock
        COALESCE(TO_CHAR(RENTAL.RENTAL_DATE, 'YYYY-MM-DD HH24:MI:SS'), 'Never Rented') AS RENTAL_DATE
    FROM 
        FILM
    LEFT JOIN 
        INVENTORY ON FILM.FILM_ID = INVENTORY.FILM_ID
    LEFT JOIN 
        RENTAL ON INVENTORY.INVENTORY_ID = RENTAL.INVENTORY_ID
    LEFT JOIN 
        CUSTOMER ON RENTAL.CUSTOMER_ID = CUSTOMER.CUSTOMER_ID
    LEFT JOIN 
        LANGUAGE ON FILM.LANGUAGE_ID = LANGUAGE.LANGUAGE_ID
    WHERE 
        FILM.TITLE ILIKE PARTIAL_TITLE
        AND INVENTORY_IN_STOCK(INVENTORY.INVENTORY_ID) -- CHECK IF THE INVENTORY IS IN STOCK
    ORDER BY 
        FILM.FILM_ID, RENTAL.RENTAL_DATE DESC NULLS LAST;
   
END;
$$
LANGUAGE 'plpgsql';

-- TEST CALL
SELECT * FROM FILMS_IN_STOCK_BY_TITLE('%dino%');

--Task 5
--Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts 
--a new movie with the given title in the film table. The function should generate a new unique film ID, 
--set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
--The release year and language are optional and by default should be current year and Klingon respectively. 
--The function should also verify that the language exists in the 'language' table. 
--Then, ensure that no such function has been created before; if so, replace it.

CREATE OR REPLACE FUNCTION NEW_MOVIE(
    MOVIE_TITLE TEXT,
    RELEASE_YEAR "year" DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    MOVIE_LANGUAGE TEXT DEFAULT 'KLINGON'
)
RETURNS VOID AS $$
DECLARE
    LANG_ID INTEGER;
BEGIN
    -- TRY TO GET THE LANGUAGE ID
    SELECT LANGUAGE_ID INTO LANG_ID FROM "language" WHERE UPPER(NAME) = UPPER(MOVIE_LANGUAGE);

    -- IF THE LANGUAGE DOESN'T EXIST, ADD IT
    IF NOT FOUND THEN
        -- INSERT THE NEW LANGUAGE INTO THE LANGUAGE TABLE
        INSERT INTO LANGUAGE (NAME) VALUES (MOVIE_LANGUAGE) RETURNING LANGUAGE_ID INTO LANG_ID;
        RAISE NOTICE 'ADDED THE NEW LANGUAGE %', MOVIE_LANGUAGE;
    END IF;
   
    IF NOT EXISTS (
    	SELECT 1 FROM FILM WHERE UPPER(FILM.TITLE) = UPPER(MOVIE_TITLE)
    ) THEN 
		    INSERT INTO FILM (TITLE, RELEASE_YEAR, LANGUAGE_ID, RENTAL_RATE, RENTAL_DURATION, REPLACEMENT_COST)
		    SELECT * FROM (VALUES (MOVIE_TITLE, RELEASE_YEAR, LANG_ID, 4.99, 3, 19.99)) AS NEWF(TITLE, RELEASE_YEAR, LANGUAGE_ID, RENTAL_RATE, RENTAL_DURATION, REPLACEMENT_COST);
		    --WHERE NOT EXISTS (SELECT 1 FROM FILM WHERE UPPER(FILM.TITLE) = UPPER(NEWF.TITLE));
	      	RAISE NOTICE 'SUCCESSFULLY ADDED NEW FILM "%" INTO FILM TABLE', MOVIE_TITLE;
    	ELSE RAISE NOTICE 'FILM "%" IS ALREADY IN THE TABLE', MOVIE_TITLE;
    END IF;
END;
$$ LANGUAGE 'plpgsql';

-- TEST CALL
SELECT * FROM NEW_MOVIE('QA4', 2023, 'Kaz');