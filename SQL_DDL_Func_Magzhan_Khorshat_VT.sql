SET SEARCH_PATH TO PUBLIC; -- Set the search path to the PUBLIC schema

-- Drop the function if it already exists
DROP FUNCTION IF EXISTS get_client_info;

-- Create the function named get_client_info
CREATE OR REPLACE FUNCTION get_client_info (
    client_id int,
    left_boundary timestamp,
    right_boundary timestamp
)
RETURNS TABLE (metric_name text, metric_value text) AS 
$$
BEGIN 
    -- 1. Customer's info
    RETURN QUERY -- Each RETURN QUERY block is responsible for obtaining a specific metric
    	SELECT 	'customer''s info', 
           		customer.first_name || ' ' || customer.last_name || ', ' || customer.email
    	FROM customer
    	WHERE customer.customer_id = client_id;

    -- 2. Number of films rented
    RETURN QUERY
    	SELECT 	'num. of films rented', 
           		COUNT(rental.rental_id)::TEXT
    	FROM rental
    	WHERE rental.customer_id = client_id
        AND rental.rental_date BETWEEN left_boundary AND right_boundary;

    -- 3. Rented films' titles
    RETURN QUERY
    	SELECT 	'rented films'' titles', 
           		COALESCE(string_agg(film.title, ', '), '') -- used to replace NULL with an empty string if no films are rented
    	FROM rental
    	JOIN inventory ON rental.inventory_id = inventory.inventory_id
    	JOIN film ON inventory.film_id = film.film_id
    	WHERE rental.customer_id = client_id
        AND rental.rental_date BETWEEN left_boundary AND right_boundary;

    -- 4. Number of payments
    RETURN QUERY
    	SELECT 	'num. of payments', 
           		COUNT(payment.payment_id)::TEXT
    	FROM payment
    	WHERE payment.customer_id = client_id
        AND payment.payment_date BETWEEN left_boundary AND right_boundary;

    -- 5. Payments' amount
    RETURN QUERY
    	SELECT 	'payments'' amount', 
           		COALESCE(SUM(payment.amount)::TEXT, '0')
    	FROM payment
    	WHERE payment.customer_id = client_id
        AND payment.payment_date BETWEEN left_boundary AND right_boundary;

END;
$$ LANGUAGE 'plpgsql';

SELECT * FROM get_client_info(1, '2001-01-01', '2018-01-01'); 