SET search_path TO public;

--###################### Part 1: Write SQL queries to retrieve the following data ############################ 
--
-- All comedy movies released BETWEEN 2000 AND 2004, alphabetical 
-- Used a JOIN BETWEEN film, film_category, AND category tables to filter comedy movies released within the specified years.
-- Chose a BETWEEN clause for the release year to narrow down the movies within the required time frame.
-- Alphabetically ordered the movie titles USING ORDER BY.
-- 

SELECT  	f.title AS comedy_movie_title,
        	f.release_year
FROM film f
INNER JOIN film_category fc
ON f.film_id = fc.film_id
INNER JOIN category c
ON fc.category_id = c.category_id
WHERE UPPER(c.name) = 'COMEDY'
AND f.release_year BETWEEN 2000 AND 2004
ORDER BY f.title;

-- Second solution

SELECT  	f.title AS comedy_movie_title,
        	f.release_year
FROM film f
WHERE f.film_id IN ( 	SELECT fc.film_id 
					FROM film_category fc 
					JOIN category c 
					ON fc.category_id = c.category_id 
					WHERE UPPER(c.name) = 'COMEDY' )
AND f.release_year BETWEEN 2000 AND 2004
ORDER BY f.title;

--
-- Revenue of every rental store for year 2017 (columns: address AND address2 – AS one column, revenue) 
-- Employed JOINs BETWEEN rental, payment, inventory, store, AND address tables to calculate store revenue for 2017.
-- Aggregated payment amounts per store for 2017 USING SUM() AND GROUP BY  for a concise representation of revenue figures by store
-- Merged 'address' AND 'address2' columns USING CONCAT() to display the complete store address IN one column.
-- 

SELECT  	concat(a.address,' ',a.address2) AS store_address,
        	SUM(p.amount)                    AS revenue
FROM rental r
INNER JOIN payment p
ON r.rental_id = p.rental_id
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN store s
ON i.store_id = s.store_id
INNER JOIN address a
ON s.address_id = a.address_id
WHERE EXTRACT (YEAR
FROM p.payment_date) = 2017
GROUP BY  s.store_id,
          a.address,
          a.address2;

-- Second solution 

SELECT  	CONCAT(a.address,' ',a.address2) AS store_address,
        	SUM(PaymentDetails.amount)       AS revenue
FROM
(
	SELECT  r.inventory_id,
	        p.amount AS amount
	FROM rental r
	INNER JOIN payment p
	ON r.rental_id = p.rental_id
	WHERE EXTRACT (YEAR FROM p.payment_date) = 2017
) AS PaymentDetails
INNER JOIN inventory i
ON PaymentDetails.inventory_id = i.inventory_id
INNER JOIN store s
ON i.store_id = s.store_id
INNER JOIN address a
ON s.address_id = a.address_id
GROUP BY  s.store_id,
          a.address,
          a.address2; 
	    
/* Top-3 actors by number of movies they took part IN (columns: first_name,last_name,number_of_movies,sorted by number_of_movies IN descending order)
-- Employed COUNT() to tally the movies each actor appeared in.
-- Utilized
ORDER BY AND
LIMIT to retrieve the top 3 actors
WITH the most movies.*/ 


SELECT  	a.first_name,
        	a.last_name,
        	COUNT(*) AS number_of_movies
FROM actor a
INNER JOIN film_actor fa
ON a.actor_id = fa.actor_id
GROUP BY  a.actor_id
ORDER BY number_of_movies DESC
LIMIT 3;

-- Second solution

SELECT  act_mov.first_name,
        act_mov.last_name,
        COUNT(*) AS number_of_movies
FROM
(
	SELECT  a.actor_id,
	        a.first_name,
	        a.last_name
	FROM actor a
	INNER JOIN film_actor fa
	ON a.actor_id = fa.actor_id
) act_mov
GROUP BY	act_mov.actor_id,
          act_mov.first_name,
          act_mov.last_name
ORDER BY number_of_movies DESC
LIMIT 3; 

/* Number of comedy, horror AND action movies per year (columns: release_year, number_of_action_movies, number_of_horror_movies, number_of_comedy_movies), sorted by release year IN descending order
-- Employed conditional aggregation
WITH SUM() AND CASE statements to count each genre per year.
-- Used
GROUP BY  to aggregate the counts based
ON release year, sorting them IN descending order.*/ 

SELECT  	f.release_year,
        	SUM(CASE WHEN UPPER(c.name) = 'ACTION' THEN 1 ELSE 0 END) AS number_of_action_movies,
        	SUM(CASE WHEN UPPER(c.name) = 'HORROR' THEN 1 ELSE 0 END) AS number_of_horror_movies,
        	SUM(CASE WHEN UPPER(c.name) = 'COMEDY' THEN 1 ELSE 0 END) AS number_of_comedy_movies
FROM film f
INNER JOIN film_category fc
ON f.film_id = fc.film_id
INNER JOIN category c
ON fc.category_id = c.category_id
GROUP BY  f.release_year
ORDER BY f.release_year DESC;

-- Second solution 

SELECT  	f.release_year,
     	COUNT(CASE WHEN UPPER(c.name) = 'ACTION' THEN 1 END) AS number_of_action_movies,
        	COUNT(CASE WHEN UPPER(c.name) = 'HORROR' THEN 1 END) AS number_of_horror_movies,
       	COUNT(CASE WHEN UPPER(c.name) = 'COMEDY' THEN 1 END) AS number_of_comedy_movies
FROM film f
LEFT JOIN film_category fc
ON f.film_id = fc.film_id
LEFT JOIN category c
ON fc.category_id = c.category_id
GROUP BY  f.release_year
ORDER BY f.release_year DESC;

--###################### Part 2: Solve the following problems WITH the help of SQL ############################ 

 /* Which staff members made the highest revenue for each store AND deserve a bonus for 2017 year? The outermost query r is used to fetch the staff members. The middle subquery sr calculates the sum of payments for each staff member AND store. The innermost subquery srr identifies the maximum revenue achieved by any staff member within a particular store. */

WITH StaffRevenue AS
(
	SELECT  	s.store_id,
	        	s.staff_id,
	        	SUM(p.amount) AS highest_revenue_for_2017
	FROM staff s
	INNER JOIN payment p
	ON s.staff_id = p.staff_id
	WHERE EXTRACT(YEAR
	FROM p.payment_date) = 2017
	GROUP BY  s.store_id,
	          s.staff_id
), 

MaxRevenuePerStore AS
(
	SELECT  	sr.store_id,
	        	MAX(sr.highest_revenue_for_2017) AS max_revenue
	FROM StaffRevenue sr
	GROUP BY  sr.store_id
)

SELECT  sr.store_id,
        sr.highest_revenue_for_2017,
        sr.staff_id AS staff_id_who_deserves_a_bonus
FROM StaffRevenue sr
INNER JOIN MaxRevenuePerStore mrps
ON sr.store_id = mrps.store_id AND sr.highest_revenue_for_2017 = mrps.max_revenue
ORDER BY sr.store_id;

-- Second solution 

WITH staff_revenue AS
(
	SELECT  s.staff_id,
	        SUM(p.amount) AS amount
	FROM staff s
	INNER JOIN payment p
	ON s.staff_id = p.staff_id
	WHERE EXTRACT (YEAR	FROM p.payment_date) = 2017
	GROUP BY  s.staff_id
), 

s_revenue AS
(
	SELECT  s1.store_id
	       ,s1.staff_id
	       ,sr1.amount
	FROM staff s1
	INNER JOIN staff_revenue sr1
	ON s1.staff_id = sr1.staff_id
)

SELECT  sr.store_id,
        sr.amount   AS highest_revenue_for_2017,
        sr.staff_id AS staff_id_who_deserves_a_bonus
FROM s_revenue sr
WHERE exists 
	(
		SELECT  	s_revenue.store_id,
        			MAX(s_revenue.amount)
		FROM s_revenue
		GROUP BY  s_revenue.store_id
		HAVING sr.amount = MAX(s_revenue.amount)
	);

--
-- Which 5 movies were rented more than others, AND what's the expected age of the audience for these movies? 
-- Employed a CASE statement to categorize expected audience age based ON movie ratings (G, PG, PG-13, R, NC-17).
-- Used COUNT() for rentals AND categorization based ON movie ratings to determine the expected audience age.
-- 

SELECT  f.title,
        COUNT(r.rental_id) AS rental_count,
        CASE WHEN f.rating = 'G' THEN ' > 0'
             WHEN f.rating = 'PG' THEN ' > 0 with parental guidance suggestion for the children'
             WHEN f.rating = 'PG-13' THEN ' > 13'
             WHEN f.rating = 'R' THEN ' < 17 with parents and > 18'
             WHEN f.rating = 'NC-17' THEN ' > 18'  
		   ELSE 'no specified age rating' 
		   END AS expected_age
FROM rental r
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN film f
ON i.film_id = f.film_id
GROUP BY  f.film_id,
          f.title,
          f.rating
ORDER BY rental_count DESC
LIMIT 5;

-- Second solution 

SELECT  f.title,
        COUNT(r.rental_id) AS rental_count,
        CASE WHEN f.rating = 'G' THEN ' > 0'
             WHEN f.rating = 'PG' THEN ' > 0 with parental guidance suggestion for the children'
             WHEN f.rating = 'PG-13' THEN ' > 13'
             WHEN f.rating = 'R' THEN ' < 17 with parents and > 18'
             WHEN f.rating = 'NC-17' THEN ' > 18'  
		   ELSE 'no specified age rating' 
		   END AS expected_age
FROM rental r
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN film f
ON i.film_id = f.film_id
GROUP BY  f.film_id,
          f.title,
          f.rating
ORDER BY rental_count DESC
LIMIT 5;

--
-- Which actors/actresses didn't act for a longer period of time than the others? 
-- Calculated the inactive period for each actor by looking for the largest gap between release_years of each actor.
-- Utilized GROUP BY  to organize the data by actor, AND ORDER BY to sort the actors by their inactive periods.
-- 

WITH ActorMovies AS
(
	SELECT  	a.actor_id,
	        	a.first_name,
	        	a.last_name,
	        	f.title AS movie_title,
	        	f.release_year,
	        	(
				SELECT  MIN(f2.release_year)
				FROM film_actor fa2
				INNER JOIN film f2
				ON fa2.film_id = f2.film_id
				WHERE fa2.actor_id = a.actor_id AND f2.release_year > f.release_year 
			) AS next_movie_year
	FROM actor a
	INNER JOIN film_actor fa
	ON a.actor_id = fa.actor_id
	INNER JOIN film f
	ON fa.film_id = f.film_id )

SELECT  actor_id,
        first_name,
        last_name,
        MAX(next_movie_year - release_year) AS longest_gap
FROM ActorMovies
GROUP BY  actor_id,
          first_name,
          last_name
HAVING MAX(next_movie_year - release_year) = 
			(
				SELECT  MAX(next_movie_year - release_year) AS max_gap
				FROM ActorMovies
			)
ORDER BY longest_gap DESC;