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
DECLARE
    country_count INT;
BEGIN
	 -- Check if there's at least one country in the input array
    IF array_length(countries, 1) IS NULL OR array_length(countries, 1) = 0 THEN
        RAISE NOTICE 'No countries provided.';
    END IF;

    -- Use a loop to iterate over each country in the input array
    FOR i IN 1..array_length(countries, 1) LOOP
        -- Check if the country is valid (exists in the database)
        SELECT COUNT(*) INTO country_count
        FROM COUNTRY c
        WHERE UPPER(c.country) = UPPER(countries[i]);

        IF country_count = 0 THEN
            RAISE NOTICE 'Invalid country: %, not exists in the database', countries[i];
        END IF;
    END LOOP;
    RETURN QUERY
    SELECT DISTINCT ON (c2.country)
        c2.country,
        f.title AS film_title,
        f.rating AS film_rating,
        l.name AS film_language,
        f.length AS film_length,
        f.release_year AS film_release_year
    FROM
        FILM f
        INNER JOIN INVENTORY i ON f.FILM_ID = i.FILM_ID
        INNER JOIN rental r ON i.inventory_id = r.inventory_id
        INNER JOIN store s ON i.STORE_ID = s.STORE_ID
        INNER JOIN ADDRESS a ON s.ADDRESS_ID = a.ADDRESS_ID
        INNER JOIN CITY c ON a.CITY_ID = c.CITY_ID
        INNER JOIN COUNTRY c2 ON c.COUNTRY_ID = c2.COUNTRY_ID
        INNER JOIN "language" l ON f.language_id = l.language_id
    WHERE
        UPPER(c2.country) IN (SELECT UPPER(unnest) FROM unnest(countries))
    GROUP BY
        c2.country, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY
        c2.country, COUNT(*) DESC;  -- order by country and count
END;
$$
LANGUAGE 'plpgsql';

-- TEST CALL
SELECT * FROM most_popular_films_by_countries(array['AUSTRALIA','CANADA','UNITED STATES']);

--Task 4
--Create a function that generates a list of movies available in stock based on a partial title match 
--(e.g., movies containing the word 'love' in their title).

CREATE OR REPLACE FUNCTION FILMS_IN_STOCK_BY_TITLE(PARTIAL_TITLE TEXT)
RETURNS TABLE (ROW_NUM INTEGER, FILM_TITLE TEXT, FILM_LANGUAGE BPCHAR(20), CUSTOMER_NAME TEXT, RENTAL_DATE TEXT) AS
$$
BEGIN
	 -- HANDLES THE CASE WHEN NO MOVIES ARE FOUND MATCHING THE TITLE PATTERN
	 IF NOT EXISTS (
        SELECT 1 
        FROM FILM
        WHERE FILM.TITLE ILIKE PARTIAL_TITLE
    ) THEN
    	  RAISE NOTICE 'MOVIES WITH THE SPECIFIED TITLE PATTERN NOT FOUND IN STOCK.';
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
    
    -- Check if movies are found but none are in stock
    IF NOT EXISTS (
        SELECT 1 
        FROM FILM
        LEFT JOIN INVENTORY ON FILM.FILM_ID = INVENTORY.FILM_ID
        WHERE FILM.TITLE ILIKE PARTIAL_TITLE AND INVENTORY_IN_STOCK(INVENTORY.INVENTORY_ID)
    ) THEN
        RAISE NOTICE 'FOUND MOVIES WITH THE SPECIFIED TITLE PATTERN, BUT NONE ARE IN STOCK.';
    END IF;
   
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
    NEW_FILM_ID INTEGER;
    LANG_ID INTEGER;
BEGIN
    -- TRY TO GET THE LANGUAGE ID
    SELECT LANGUAGE_ID INTO LANG_ID FROM "language" WHERE UPPER(NAME) = UPPER(MOVIE_LANGUAGE);

    -- IF THE LANGUAGE DOESN'T EXIST, ADD IT
    IF NOT FOUND THEN
        -- INSERT THE NEW LANGUAGE INTO THE LANGUAGE TABLE
        INSERT INTO LANGUAGE (NAME) VALUES (MOVIE_LANGUAGE) RETURNING LANGUAGE_ID INTO LANG_ID;
    END IF;
   
    -- GENERATE A NEW UNIQUE FILM ID
    SELECT COALESCE(MAX(FILM_ID) + 1, 1) INTO NEW_FILM_ID FROM FILM;

    -- INSERT THE NEW MOVIE INTO THE FILM TABLE
    INSERT INTO FILM (film_id, TITLE, RELEASE_YEAR, LANGUAGE_ID, RENTAL_RATE, RENTAL_DURATION, REPLACEMENT_COST)
    SELECT * FROM (VALUES (NEW_FILM_ID, MOVIE_TITLE, RELEASE_YEAR, LANG_ID, 4.99, 3, 19.99)) AS NEWF(FILM_ID, TITLE, RELEASE_YEAR, LANGUAGE_ID, RENTAL_RATE, RENTAL_DURATION, REPLACEMENT_COST)
    WHERE NOT EXISTS (SELECT 1 FROM FILM WHERE UPPER(FILM.TITLE) = UPPER(NEWF.TITLE));
    
    -- HANDLE EXCEPTION QUIETLY IF ANY
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR INSERTING THE MOVIE: %', SQLERRM;
            RETURN;
END;
$$ LANGUAGE 'plpgsql';

-- TEST CALL
SELECT * FROM NEW_MOVIE('DASTUR', 2024, 'Kazakh');