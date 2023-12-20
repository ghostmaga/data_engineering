-- /*Choose your top-3 favorite movies AND add them to the 'film' table. Fill IN rental rates WITH 4.99, 9.99 AND 19.99 AND rental durations WITH 1, 2 AND 3 weeks respectively.*/
-- 
INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
SELECT  *
FROM( 
VALUES 
	('INTERSTELLAR', 'A visually stunning sci-fi epic where a group of astronauts embarks on a perilous journey through a wormhole in search of a new habitable planet for humanity', 2014, (	SELECT  language_id FROM "language" WHERE UPPER(name) = 'ENGLISH'), 7, 4.99, 169, 15.99, 'PG-13'::mpaa_rating, '{"Deleted Scenes","Behind the Scenes"}'::text[]), 
	('MOONLIGHT SONATA', 'A poignant drama exploring the life of a young pianist who navigates through personal struggles while pursuing a career in music', 2019, ( SELECT  language_id FROM "language" WHERE UPPER(name) = 'ENGLISH'), 14, 9.99, 48, 12.99, 'PG-13'::mpaa_rating, '{Trailers,"Deleted Scenes"}'::text[]), 
	('SANDS OF SERENITY', 'An epic adventure set in a mythical world where a group of explorers embarks on a quest to find an ancient artifact buried in the desert', 2021, ( SELECT  language_id FROM "language" WHERE UPPER(name) = 'ENGLISH'), 21, 19.99, 50, 18.99, 'PG'::mpaa_rating, '{Trailers,"Deleted Scenes"}'::text[]) 
) AS fm (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
WHERE NOT EXISTS ( -- 
					SELECT  1
					FROM film f
					WHERE f.title = fm.title ) 
RETURNING *;

-- 
 /*Add the actors who play leading roles IN your favorite movies to the 'actor' AND 'film_actor' tables (6 or more actors IN total).*/
-- 

INSERT INTO actor (first_name, last_name)
SELECT  *
FROM ( 
	VALUES 
		('JAVIER', 'BARDEM'), 
		('MAHERSHALA', 'ALI'), 
		('MATTHEW', 'MCCONAUGHEY'), 
		('NAOMIE', 'HARRIS'), 
		('OMAR', 'SY'), 
		('ANNE', 'HATHAWAY')
	) AS act (fname, lname)
WHERE NOT EXISTS (
SELECT  a.first_name || ' ' || a.last_name AS fullname
FROM actor a
WHERE UPPER(a.first_name || ' ' || a.last_name) = UPPER(act.fname || ' ' || act.lname)) 
RETURNING *;

-- 

INSERT INTO film_actor (actor_id, film_id)
SELECT  *
FROM ( 
	VALUES 	( 	( 	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'JAVIER' AND upper(last_name) = 'BARDEM'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'INTERSTELLAR')), 
			( 	(	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'MAHERSHALA' AND upper(last_name) = 'ALI'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'INTERSTELLAR')), 
			( 	(	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'MATTHEW' AND upper(last_name) = 'MCCONAUGHEY'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'MOONLIGHT SONATA')), 
			( 	(	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'NAOMIE' AND upper(last_name) = 'HARRIS'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'MOONLIGHT SONATA')), 
			( 	(	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'OMAR'	AND upper(last_name) = 'SY'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'SANDS OF SERENITY')), 
			( 	(	SELECT  actor_id
					FROM actor
					WHERE upper(first_name) = 'ANNE'
					AND upper(last_name) = 'HATHAWAY'), 
				(	SELECT  film_id
					FROM film
					WHERE upper(title) = 'SANDS OF SERENITY')) 
	) AS fa1 (actor_id, film_id)
WHERE NOT EXISTS (
				SELECT  *
				FROM film_actor fa
				WHERE fa.actor_id = fa1.actor_id AND fa.film_id = fa1.film_id) 
RETURNING *;

-- 
 /*Add your favorite movies to any store's inventory*/
-- 

INSERT INTO inventory (film_id, store_id)
SELECT  f.film_id,
        st.store_id
FROM film f
CROSS JOIN ( 	SELECT store_id -- to associate each film from the film table with a randomly chosen store
				FROM store 
				ORDER BY random() 
				LIMIT 1 ) st
WHERE UPPER(title) IN ('INTERSTELLAR', 'MOONLIGHT SONATA', 'SANDS OF SERENITY') --also I could add WHERE not exists statement but since IN store's inventory might be any amount of films there is no need to include it 
RETURNING *;

-- 
/*ALTER any existing customer IN the database WITH at least 43 rental AND 43 payment records. Change their personal data to yours (first name, last name, address, etc. ). You can use any existing address FROM the "address" table. Please do not perform any updates ON the "address" table, AS this can impact multiple records WITH the same address.*/
-- 

UPDATE customer
SET first_name = 'MAGZHAN', 
	last_name = 'KHORSHAT', 
	email = 'my.email@example.com', 
	address_id = (	SELECT  address_id
					FROM address
					WHERE postal_code = '2299'
					LIMIT 1), 
	last_update = current_date
WHERE customer_id = (	
					SELECT  customer_id
					FROM	(
								SELECT  c.customer_id
								FROM customer c
								INNER JOIN rental r
								ON c.customer_id = r.customer_id
								INNER JOIN payment p
								ON c.customer_id = p.customer_id
								GROUP BY  c.customer_id
								HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43
								LIMIT 1
							)
					) 
RETURNING *;

-- 
 /*Remove any records related to you (as a customer) FROM all tables except 'Customer' AND 'Inventory'*/
-- 

CREATE TEMP TABLE IF NOT EXISTS temp_cid AS --storing intermediate results or specific data needed for further processing 
	SELECT  customer_id
	FROM customer c
	WHERE UPPER(first_name) = 'MAGZHAN' AND UPPER(last_name) = 'KHORSHAT'; 

DELETE FROM payment
WHERE customer_id IN ( 	SELECT customer_id 
						FROM temp_cid); 
DELETE FROM rental
WHERE customer_id IN ( 	SELECT customer_id 
						FROM temp_cid);

DROP TABLE IF EXISTS temp_cid; -- cleanup/management of temporary data 

-- 
 /*Rent your favorite movies	FROM the store they are IN AND pay for them (add corresponding records to the database to represent this activity)*/
-- 

WITH customer_info AS
(
	SELECT  customer_id
	FROM customer
	WHERE UPPER(first_name) = 'MAGZHAN'
	AND UPPER(last_name) = 'KHORSHAT'
	LIMIT 1 -- IN case if by accident there are multiple IDs 
)
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT  CURRENT_DATE,
		MIN(i.inventory_id) AS inventory_id, --to avoid insertion of multiple inventory ids WITH the same film since there can be multiple copies of 1 film IN the store's inventory 
		(	SELECT  customer_id
			FROM customer_info), 
		CURRENT_DATE + f.rental_duration AS return_date, 
		(	SELECT  staff_id
			FROM staff
			ORDER BY RANDOM()
			LIMIT 1) AS staff_id
FROM inventory i
INNER JOIN film f -- to get film's rentaal duration 
ON i.film_id = f.film_id
WHERE i.film_id IN ( 	SELECT film_id 
						FROM film 
						WHERE title IN ('INTERSTELLAR', 'MOONLIGHT SONATA', 'SANDS OF SERENITY') )
AND NOT EXISTS ( -- to avoid duplicate keys 
					SELECT  1
					FROM rental
					WHERE rental.rental_date = CURRENT_DATE
					AND rental.inventory_id = i.inventory_id
					AND rental.customer_id = 	(
													SELECT  customer_id
													FROM customer_info))
GROUP BY  i.film_id,
          f.rental_duration 
RETURNING *;

WITH customer_info AS
(
	SELECT  customer_id
	FROM customer
	WHERE UPPER(first_name) = 'MAGZHAN'
	AND UPPER(last_name) = 'KHORSHAT'
	LIMIT 1
)
INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT  (
			SELECT  customer_id
			FROM customer_info ), 
		(
			SELECT  staff_id
			FROM staff
			ORDER BY RANDOM()
			LIMIT 1) AS staff_id, 
		r.rental_id, 
		f.rental_rate, 
		TIMESTAMP '2017-01-01 00:00:00' + (RANDOM() * (TIMESTAMP '2017-06-30 23:59:59' - TIMESTAMP '2017-01-01 00:00:00')) AS payment_date
FROM rental r
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id
INNER JOIN film f
ON i.film_id = f.film_id
WHERE r.customer_id = (
						SELECT  customer_id
						FROM customer_info) 
RETURNING *;