-- 
/*Choose your top-3 favorite movies AND add them to the 'film' table. Fill IN rental rates WITH 4.99, 9.99 AND 19.99 AND rental durations WITH 1, 2 AND 3 weeks respectively.*/
-- 

INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
SELECT  'INTERSTELLAR',
        'A visually stunning sci-fi epic where a group of astronauts embarks on a perilous journey through a wormhole in search of a new habitable  planet for humanity',
        2014,
        1,
        1,
        4.99,
        169,
        15.99,
        'PG-13'::mpaa_rating,
        '{"Deleted Scenes","Behind the Scenes"}'::text[]
UNION ALL
SELECT  'MOONLIGHT SONATA',
        'A poignant drama exploring the life of a young pianist who navigates through personal struggles while pursuing a career in music',
        2019,
        1,
        2,
        9.99,
        48,
        12.99,
        'PG-13'::mpaa_rating,
        '{Trailers,"Deleted Scenes"}'::text[]
UNION ALL
SELECT  'SANDS OF SERENITY',
        'An epic adventure set in a mythical world where a group of explorers embarks on a quest to find an ancient artifact buried in the desert',
        2021,
        1,
        3,
        19.99,
        50,
        18.99,
        'PG'::mpaa_rating,
        '{Trailers,"Deleted Scenes"}'::text[];

-- 
 /*Add the actors who play leading roles IN your favorite movies to the 'actor' AND 'film_actor' tables (6 or more actors IN total).*/
-- 

INSERT INTO actor (first_name, last_name)
SELECT  'JAVIER','BARDEM'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'JAVIER' AND last_name = 'BARDEM' ) 
UNION ALL
SELECT  'MAHERSHALA','ALI'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'MAHERSHALA' AND last_name = 'ALI' ) 
UNION ALL
SELECT  'MATTHEW','MCCONAUGHEY'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'MATTHEW' AND last_name = 'MCCONAUGHEY') 
UNION ALL
SELECT  'NAOMIE','HARRIS'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'NAOMIE' AND last_name = 'HARRIS') 
UNION ALL
SELECT  'OMAR','SY'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'OMAR' AND last_name = 'SY') 
UNION ALL
SELECT  'ANNE','HATHAWAY'
WHERE NOT EXISTS (
				SELECT  1
				FROM actor
				WHERE first_name = 'ANNE' AND last_name = 'HATHAWAY');

INSERT INTO film_actor
SELECT  fa.actor_id,
        fa.film_id
FROM
(
	SELECT  a.actor_id,
	        f.film_id
	FROM actor a, film f
	WHERE a.actor_id > 200
	AND f.film_id BETWEEN 1001 AND 1003
) fa
WHERE ((actor_id BETWEEN 201 AND 202) AND film_id = 1001) OR ((actor_id BETWEEN 203 AND 204) AND film_id = 1002) OR ((actor_id BETWEEN 205 AND 206) AND film_id = 1003);

-- 
 /*Add your favorite movies to any store's inventory*/
-- 

INSERT INTO inventory (film_id, store_id)
SELECT  film.film_id,
        st.store_id
FROM film
CROSS JOIN ( SELECT store_id FROM store ORDER BY random() LIMIT 1 ) st
WHERE title IN ('INTERSTELLAR', 'MOONLIGHT SONATA', 'SANDS OF SERENITY');

-- 
 /* ALTER any existing customer IN the database WITH at least 43 rental AND 43 payment records. Change their personal data to yours (first name, last name, address, etc.). You can use any existing address FROM the "address" table. Please do not perform any updates ON the "address" table, AS this can impact multiple records WITH the same address.*/
-- 

UPDATE customer
SET first_name = 'Magzhan', last_name = 'Khorshat', email = 'my.email@example.com', address_id = 20
WHERE customer_id = (
					SELECT  customer_id
					FROM 	(
								SELECT  c.customer_id
								FROM customer c
								INNER JOIN rental r
								ON c.customer_id = r.customer_id
								INNER JOIN payment p
								ON c.customer_id = p.customer_id
								GROUP BY  c.customer_id
								HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
								LIMIT 1 
							)
				);

-- 
 /*Remove any records related to you (as a customer)
FROM all tables except 'Customer' AND 'Inventory'*/
-- 

SET CONSTRAINTS ALL DEFERRED;

CREATE TEMP TABLE if not exists temp_cid AS
SELECT  customer_id
FROM customer c
WHERE first_name = 'Magzhan' AND last_name = 'Khorshat'; DELETE
FROM payment
WHERE customer_id IN ( SELECT customer_id FROM temp_cid); DELETE
FROM rental
WHERE customer_id IN ( SELECT customer_id FROM temp_cid);

SET CONSTRAINTS ALL IMMEDIATE;

DROP TABLE IF EXISTS temp_cid;
-- 
 /*Rent you favorite movies
FROM the store they are IN AND pay for them (add corresponding records to the database to represent this activity)*/
-- 

CREATE TEMP TABLE if not exists fid AS (
SELECT  film_id,
        rental_rate AS amt
FROM film
WHERE title IN ('INTERSTELLAR', 'MOONLIGHT SONATA', 'SANDS OF SERENITY'));

SELECT  film_id,
        store_id
FROM inventory
WHERE film_id IN ( SELECT film_id FROM fid);
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT  	CURRENT_DATE,
        	inventory_id,
        	(
			SELECT  customer_id
			FROM customer
			WHERE UPPER(first_name) = 'MAGZHAN' AND UPPER(last_name) = 'KHORSHAT' 
		), 
		NULL AS return_date, 
		2 AS staff_id
FROM inventory
WHERE film_id IN ( SELECT film_id FROM fid );


INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT  	(
			SELECT  distinct customer_id
			FROM customer
			WHERE UPPER(first_name) = 'MAGZHAN' AND UPPER(last_name) = 'KHORSHAT' 
		), 
		2 AS staff_id, 
		r.rental_id, 
		f.rental_rate AS amount, 
		'2017-01-30 07:06:50.996 +0600' AS payment_date
FROM rental r
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN film f
ON i.film_id = f.film_id
WHERE r.customer_id = (
					SELECT  customer_id
					FROM customer
					WHERE UPPER(first_name) = 'MAGZHAN' AND UPPER(last_name) = 'KHORSHAT'
					LIMIT 1 );