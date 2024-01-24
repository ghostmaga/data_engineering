SET ROLE postgres;
SET search_path TO public;

DROP POLICY IF EXISTS customer_policy_rental ON rental;
DROP POLICY IF EXISTS customer_policy_payment ON payment;

ALTER TABLE rental DISABLE ROW LEVEL SECURITY;
ALTER TABLE payment DISABLE ROW LEVEL SECURITY;

-- TASK 2 --

-- 1 --
-- Create a new user with the username "rentaluser" and the password "rentalpassword". 
-- Give the user the ability to connect to the database but no other permissions.
DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'rentaluser') THEN
    CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
  END IF;
END $$;

-- 2 --
-- Grant "rentaluser" SELECT permission for the "customer" table
GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser;
-- Сheck to make sure this permission works correctly—write a SQL query to select all customers
SELECT * FROM customer c;

-- 3 --
-- Create a new user group called "rental" and add "rentaluser" to the group. 
SET ROLE postgres;

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_group WHERE groname = 'rental') THEN
    CREATE GROUP rental;
  END IF;
  EXCEPTION
		WHEN OTHERS THEN 
			RAISE NOTICE 'Error occured. %', SQLERRM;
END $$;

DO $$ 
BEGIN 
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_user 
    WHERE usename = 'rentaluser' 
    AND (
    	SELECT ARRAY(	
    		SELECT grosysid 
    		FROM pg_group 
    		WHERE groname = 'rental'
    	) @> ARRAY[usesysid]
    )
  ) THEN
    	ALTER GROUP rental ADD USER rentaluser;
  END IF;
END $$;

-- 4 --
-- Grant the "rental" group INSERT and UPDATE permissions for the "rental" table
GRANT SELECT, INSERT, UPDATE ON TABLE rental TO GROUP rental;
GRANT USAGE ON rental_rental_id_seq TO GROUP rental;
SET ROLE rentaluser;

-- Insert a new row and update one existing row in the "rental" table under that role
DO $$
BEGIN
	BEGIN
		INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
		SELECT * FROM 	(
			VALUES 
				('2005-05-26 01:54:33.000 +0600'::timestamptz, 1, 1, 1)
		) AS rnt(rental_date, iid, cid, sid)
		WHERE NOT EXISTS (
			SELECT 1 
			FROM rental 
			WHERE rental_date = rnt.rental_date 
			AND inventory_id = rnt.iid 
			AND customer_id = rnt.cid
		);
	EXCEPTION
		WHEN OTHERS THEN 
			RAISE NOTICE 'Error occured. %', SQLERRM;
	END;
END $$;

-- 5 --
-- Revoke the "rental" group's INSERT permission for the "rental" table
SET ROLE postgres;
REVOKE INSERT ON TABLE rental FROM GROUP rental;

-- Try to insert new rows into the "rental" table make sure this action is denied.
SET ROLE rental;
DO $$
BEGIN 
	BEGIN 
		INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
		VALUES ('2005-05-26 01:54:33.000 +0600', 1526, 460, '2005-05-29 22:40:33.000 +0600', 2);
	EXCEPTION
		WHEN OTHERS THEN 
			RAISE NOTICE 'Error occured. %', SQLERRM;
	END;
END $$;

-- 6 --
SET ROLE postgres;
-- Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

DO $$ 
DECLARE
    fname TEXT;
    lname TEXT;
    role_name TEXT;
BEGIN
	BEGIN 
    -- Step 1: Choose a customer with non-empty payment and rental history
		SELECT 
	       first_name, 
	       last_name 
	   INTO 
	       fname, 
	       lname 
	   FROM 
	       customer 
	   WHERE 
	       customer_id IN (
	       	SELECT DISTINCT customer_id 
	         FROM payment
	       )
	   AND customer_id IN (
	         SELECT DISTINCT customer_id 
	         FROM rental
	   )
	   LIMIT 1;
	
	    -- Step 2: Check if the role already exists
	    role_name := 'client_' || fname || '_' || lname;
	    
	   IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = role_name) THEN
	        -- Step 3: Create the role
	      EXECUTE 'CREATE ROLE ' || role_name;
	      EXECUTE 'GRANT CONNECT ON DATABASE dvdrental TO ' || role_name;
	      EXECUTE 'GRANT USAGE ON SCHEMA public TO ' || role_name;
--	      EXECUTE 'GRANT SELECT ON TABLE customer TO ' || role_name;  
	      RAISE NOTICE 'Personalized role % has been created.', role_name;
	   ELSE
	   	RAISE NOTICE 'Role % already exists.', role_name;
	   END IF;
	   
	   EXCEPTION
         WHEN NO_DATA_FOUND THEN
         	RAISE NOTICE 'No customer found satisfying the criteria';
         WHEN OTHERS THEN 
            RAISE NOTICE 'Error occurred: %', SQLERRM;
	END;
END $$;

-- TASK 3 --
ALTER TABLE rental ENABLE ROW LEVEL SECURITY; -- by default it is disabled
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

--FOR testing purposes
GRANT SELECT ON TABLE customer TO client_mary_smith;	
GRANT SELECT, UPDATE, INSERT ON TABLE rental TO client_mary_smith; 
GRANT SELECT ON TABLE payment TO client_mary_smith; 

-- Restrict access to the 'customer' table
REVOKE SELECT ON TABLE customer FROM public;

-- Create a RLS policy on the 'rental' table
CREATE POLICY customer_policy_rental
	ON rental
   USING (customer_id = (
   	SELECT customer_id 
    	FROM customer 
    	WHERE first_name = substring((SELECT rolname FROM pg_roles WHERE rolname = 'client_mary_smith') from 'client_(.*?)_') 
    	AND last_name = substring((SELECT rolname FROM pg_roles WHERE rolname = 'client_mary_smith') from '_([^_]+)$')
	));

-- Create a RLS policy on the 'payment' table
CREATE POLICY customer_policy_payment
	ON payment
   USING (customer_id = (
   	SELECT customer_id 
    	FROM customer 
    	WHERE (first_name) = upper(substring((SELECT rolname FROM pg_roles WHERE rolname = 'client_mary_smith') from 'client_(.*?)_')) 
    	AND upper(last_name) = upper(substring((SELECT rolname FROM pg_roles WHERE rolname = 'client_mary_smith') from '_([^_]+)$'))
	));

SET ROLE client_mary_smith;
SELECT * FROM rental;