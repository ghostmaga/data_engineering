SET ROLE postgres;
SET search_path TO public;

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'rentaluser') THEN
    CREATE USER rentaluser WITH PASSWORD 'rentalpassword';
    GRANT CONNECT ON DATABASE dvdrental TO rentaluser;
  END IF;
END $$;

GRANT SELECT ON TABLE customer TO rentaluser;

SET ROLE rentaluser;

SELECT * FROM customer c;

SET ROLE postgres;

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_group WHERE groname = 'rental') THEN
    CREATE GROUP rental;
  END IF;
END $$;

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'rentaluser' AND usesysid = ANY (SELECT grosysid FROM pg_group WHERE groname = 'rental')) THEN
	ALTER GROUP rental ADD USER rentaluser;
  END IF;
END $$;

--SELECT * FROM pg_group
--select * from pg_user

--SELECT ROLNAME 
--FROM PG_USER
--JOIN PG_AUTH_MEMBERS 
--ON (PG_USER.USESYSID=PG_AUTH_MEMBERS.MEMBER)
--JOIN PG_ROLES 
--ON (PG_ROLES.OID=PG_AUTH_MEMBERS.ROLEID)
--WHERE PG_USER.USENAME='RENTALUSER';

GRANT SELECT, INSERT, UPDATE ON TABLE rental TO GROUP rental;
GRANT USAGE ON rental_rental_id_seq TO GROUP rental;
SET ROLE rentaluser;

--INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
--SELECT * 
--FROM 	(
--			VALUES ('2005-05-26 01:54:33.000 +0600'::timestamptz, 1, 1, 1)
--		) AS rnt(rental_date, iid, cid, sid)
--WHERE NOT EXISTS (SELECT 1 FROM rental WHERE rental_date = rnt.rental_date AND inventory_id = rnt.iid AND customer_id = rnt.cid);

--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM rentaluser;
--REVOKE ALL ON ALL TABLES IN SCHEMA public FROM group rental;

SET ROLE postgres;
REVOKE INSERT ON TABLE rental FROM GROUP rental;

DO $$ 
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE upper(rolname) = 'CLIENT_MARY_SMITH') THEN
	CREATE ROLE client_mary_smith;
  END IF;
END $$;

ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
	
DO $$ --FOR testing purposes I GRANTED ONLY SELECT TO CHECK whether it will display ONLY customer's DATA OR not
BEGIN 
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'mary_smith') THEN
    CREATE USER mary_smith WITH PASSWORD '123';
    GRANT CONNECT ON DATABASE dvdrental TO mary_smith;
    GRANT SELECT ON TABLE rental TO mary_smith; 
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customer,
    role_name VARCHAR(50) UNIQUE NOT NULL
);

DROP POLICY IF EXISTS customer_policy ON rental;
DROP POLICY IF EXISTS customer_policy ON payment;

CREATE POLICY customer_policy
ON rental
USING (customer_id = (SELECT customer_id FROM users WHERE role_name = current_user));

CREATE POLICY customer_policy
ON payment
USING (customer_id = (SELECT customer_id FROM users WHERE role_name = current_user));

SET ROLE mary_smith;

SELECT * FROM rental;