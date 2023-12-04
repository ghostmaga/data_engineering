--###################### Part 1: Write SQL queries to retrieve the following data ############################

--
-- All comedy movies released BETWEEN 2000 AND 2004, alphabetical

-- Used a JOIN between film, film_category, and category tables to filter comedy movies released within the specified years.
-- Chose a BETWEEN clause for the release year to narrow down the movies within the required time frame.
-- Alphabetically ordered the movie titles using ORDER BY.
-- 

SELECT  f.title AS comedy_movie_title
       ,f.release_year
FROM film f
JOIN film_category fc
ON f.film_id = fc.film_id
JOIN category c
ON fc.category_id = c.category_id
WHERE c.name = 'Comedy'
AND f.release_year BETWEEN 2000 AND 2004
ORDER BY f.title;

-- Second solution

-- SELECT f.title AS comedy_movie_title, f.release_year
-- FROM film f
-- WHERE f.film_id IN (
--     SELECT fc.film_id
--     FROM film_category fc
--     JOIN category c ON fc.category_id = c.category_id
--     WHERE c.name = 'Comedy'
-- )
-- AND f.release_year BETWEEN 2000 AND 2004
-- ORDER BY f.title;


--
-- Revenue of every rental store for year 2017 (columns: address AND address2 – AS one column, revenue)

-- Employed JOINs between rental, payment, inventory, store, and address tables to calculate store revenue for 2017.
-- Aggregated payment amounts per store for 2017 using SUM() and GROUP BY for a concise representation of revenue figures by store
-- Merged 'address' and 'address2' columns using CONCAT() to display the complete store address in one column.
-- 

SELECT  concat(a.address,' ',a.address2) AS store_address,
        SUM(p.amount)                    AS revenue
FROM rental r
JOIN payment p
ON r.rental_id = p.rental_id
JOIN inventory i
ON r.inventory_id = i.inventory_id
JOIN store s
ON i.store_id = s.store_id
JOIN address a
ON s.address_id = a.address_id
WHERE p.payment_date BETWEEN '2017-01-01' AND '2018-01-01'
GROUP BY store_address 

/* Top-3 actors by number of movies they took part IN (columns: first_name,last_name,number_of_movies,sorted by number_of_movies IN descending order) 

-- Employed COUNT() to tally the movies each actor appeared in.
-- Utilized ORDER BY and LIMIT to retrieve the top 3 actors with the most movies.*/

SELECT  a.first_name,
        a.last_name,
        COUNT(*) AS number_of_movies
FROM actor a
JOIN film_actor fa
ON a.actor_id = fa.actor_id
GROUP BY  a.actor_id
ORDER BY number_of_movies desc
LIMIT 3; 

/* Number of comedy, horror AND action movies per year (columns: release_year, number_of_action_movies, number_of_horror_movies, number_of_comedy_movies), sorted by release year IN descending order 

-- Employed conditional aggregation with SUM() and CASE statements to count each genre per year.
-- Used GROUP BY to aggregate the counts based on release year, sorting them in descending order.*/

SELECT  f.release_year,
        SUM(CASE WHEN UPPER(c.name) = 'ACTION' THEN 1 ELSE 0 END) AS number_of_action_movies,
        SUM(CASE WHEN UPPER(c.name) = 'HORROR' THEN 1 ELSE 0 END) AS number_of_horror_movies,
        SUM(CASE WHEN UPPER(c.name) = 'COMEDY' THEN 1 ELSE 0 END) AS number_of_comedy_movies
FROM film f
JOIN film_category fc
ON f.film_id = fc.film_id
JOIN category c
ON fc.category_id = c.category_id
GROUP BY  f.release_year
ORDER BY f.release_year DESC;

--###################### Part 2: Solve the following problems WITH the help of SQL ############################ 

/*
     Which staff members made the highest revenue for each store AND deserve a bonus for 2017 year?

     The outermost query r is used to fetch the staff members.
     The middle subquery sr calculates the sum of payments for each staff member and store.
     The innermost subquery srr identifies the maximum revenue achieved by any staff member within a particular store.
*/

SELECT  r.store_id,
        r.highest_revenue_for_2017,
        r.staff_id
FROM
(
	SELECT  sr.store_id,
	        sr.staff_id,
	        sr.highest_revenue_for_2017
	FROM
	(
		SELECT  s.store_id,
		        s.staff_id,
		        SUM(p.amount) AS highest_revenue_for_2017
		FROM staff s
		INNER JOIN payment p
		ON s.staff_id = p.staff_id
		WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
		GROUP BY  s.store_id, s.staff_id
	) sr
	WHERE sr.highest_revenue_for_2017 = (
	SELECT MAX(srr.highest_revenue_for_2017)
	FROM
	(
		SELECT  s.store_id,
		        s.staff_id,
		        SUM(p.amount) AS highest_revenue_for_2017
		FROM staff s
		INNER JOIN payment p
		ON s.staff_id = p.staff_id
		WHERE p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
		GROUP BY  s.store_id, s.staff_id
	) srr
	WHERE sr.store_id = srr.store_id ) 
) r
ORDER BY r.store_id;

--
-- Which 5 movies were rented more than others, AND what's the expected age of the audience for these movies?

-- Employed a CASE statement to categorize expected audience age based on movie ratings (G, PG, PG-13, R, NC-17).
-- Used COUNT() for rentals and categorization based on movie ratings to determine the expected audience age.
-- 

SELECT  f.title,
        COUNT(r.rental_id) AS rental_count,
        CASE WHEN f.rating = 'G' THEN ' > 0'
             WHEN f.rating = 'PG' THEN ' > 0 with parental guidance suggestion for the children'
             WHEN f.rating = 'PG-13' THEN ' > 13'
             WHEN f.rating = 'R' THEN ' < 17 with parents and > 18'
             WHEN f.rating = 'NC-17' THEN ' > 18' 
             END AS expected_age
FROM rental r
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN film f
ON i.film_id = f.film_id
GROUP BY  f.title,
          f.rating
ORDER BY rental_count DESC
LIMIT 5;

--
-- Which actors/actresses didn't act for a longer period of time than the others?

-- Calculated the inactive period for each actor by subtracting the most recent movie release year from the current year.
-- Utilized GROUP BY to organize the data by actor, and ORDER BY to sort the actors by their inactive periods.
-- 

SELECT  a.actor_id,
        a.first_name,
        a.last_name,
        MAX(f.release_year) AS recent_movie_release_year,
        EXTRACT(YEAR
FROM CURRENT_DATE) - MAX(f.release_year) AS no_acting_period
FROM actor a
JOIN film_actor fa
ON a.actor_id = fa.actor_id
JOIN film f
ON fa.film_id = f.film_id
GROUP BY  a.actor_id,
          a.first_name,
          a.last_name
ORDER BY no_acting_period DESC