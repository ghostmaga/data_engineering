SET search_path TO public;

-- Top-3 most selling movie categories of all time AND total dvd rental income for each category.
-- Only consider dvd rental customers FROM the USA. 

SELECT    DISTINCT c."name" AS category_name,
          SUM(p.amount) AS income --income for the specific category
FROM category c
INNER JOIN film_category fc
ON c.category_id = fc.category_id -- Joining film_category to get categories
INNER JOIN film f
ON fc.film_id = f.film_id -- Connecting film to get film id
INNER JOIN inventory i
ON f.film_id = i.film_id -- Connecting inventory to get rental info
INNER JOIN rental r
ON i.inventory_id = r.inventory_id -- Joining rental details
INNER JOIN payment p
ON r.rental_id = p.rental_id -- Joining payments made
INNER JOIN customer cust
ON p.customer_id = cust.customer_id -- Joining customer details
INNER JOIN address a
ON cust.address_id = a.address_id -- Joining addresses to get city id
INNER JOIN city ct
ON a.city_id = ct.city_id
INNER JOIN country cntr
ON ct.country_id = cntr.country_id -- Joining country to get country name for filtering
WHERE UPPER(cntr.country) = 'UNITED STATES' -- Filtering for DVD category in the USA
GROUP BY  c."name" -- Grouping by category name for calculations
ORDER BY income DESC -- Ordering by total income in descending order
LIMIT 3; -- Top 3 category

-- For each client, display a list of horrors that he had ever rented (in one column, separated by commas),
-- AND the amount of money that he paid for it 

SELECT  
          --customer info
          cust.customer_id,
          cust.first_name || ' ' || cust.last_name AS customer_full_name,

          --rental info
          STRING_AGG(distinct f.title,', ')  AS list_of_horrors_rented_by_customer, -- Concatenating movie titles
          SUM(p.amount)                      AS payment -- Calculating total payment for rentals by summing out amount from payment table for each customer
FROM customer cust
INNER JOIN rental r
ON cust.customer_id = r.customer_id -- Joining customer rentals
INNER JOIN payment p
ON r.rental_id = p.rental_id -- Joining payments made
INNER JOIN inventory i
ON r.inventory_id = i.inventory_id -- Joining inventory for movie details
INNER JOIN film f
ON i.film_id = f.film_id -- Joining film details
INNER JOIN film_category fc
ON f.film_id = fc.film_id -- Joining film categories
INNER JOIN category c
ON fc.category_id = c.category_id -- Joining categories to get category name
WHERE UPPER(c."name") = 'HORROR' -- Filtering for horror movies only
GROUP BY  cust.customer_id, -- Grouping by customer ID
          cust.first_name, -- Grouping by customer' first name
          cust.last_name; -- Grouping by customer's last name