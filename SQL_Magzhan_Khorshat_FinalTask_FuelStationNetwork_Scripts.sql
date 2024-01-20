DROP DATABASE IF EXISTS fuel_station_network;
CREATE database fuel_station_network;

-------------------------------------------------------------

--										DDL								  --

-------------------------------------------------------------

DROP SCHEMA IF EXISTS fuel_station CASCADE;
CREATE SCHEMA IF NOT EXISTS fuel_station;
SET search_path TO fuel_station;

-- Create Country Table
CREATE TABLE IF NOT EXISTS Country (
    country_code CHAR(2) PRIMARY KEY,
    country_name VARCHAR(30) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create City Table
CREATE TABLE IF NOT EXISTS City (
    city_id SERIAL PRIMARY KEY,
    country_code CHAR(2) REFERENCES Country(country_code),
    city_name VARCHAR(30) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Location Table
CREATE TABLE IF NOT EXISTS Location (
    location_id SERIAL PRIMARY KEY,
    city_id INT REFERENCES City(city_id),
    address_line1 VARCHAR(50) NOT NULL,
    address_line2 VARCHAR(50),
    full_address VARCHAR(100) GENERATED ALWAYS AS (address_line1 || ' ' || address_line2) STORED,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Role Table
CREATE TABLE IF NOT EXISTS Role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL,
    description TEXT,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Person Table
CREATE TABLE IF NOT EXISTS Person (
    person_id SERIAL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    full_name VARCHAR(60) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    contact_number VARCHAR(14) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Station Table
CREATE TABLE IF NOT EXISTS Station (
    station_id SERIAL PRIMARY KEY,
    station_name VARCHAR(30) NOT NULL,
    location_id INT REFERENCES Location(location_id),
    contact_number VARCHAR(14) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Fuel_Type Table
CREATE TABLE IF NOT EXISTS Fuel_Type (
    fuel_type_id SERIAL PRIMARY KEY,
    fuel_type_name VARCHAR(20) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Inventory Table
CREATE TABLE IF NOT EXISTS Inventory (
    inventory_id SERIAL PRIMARY KEY,
    station_id INT REFERENCES Station(station_id),
    fuel_type_id INT REFERENCES Fuel_Type(fuel_type_id),
    quantity INT,
	 last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Pricing Table
CREATE TABLE IF NOT EXISTS Pricing (
    pricing_id SERIAL PRIMARY KEY,
    station_id INT REFERENCES Station(station_id),
    fuel_type_id INT REFERENCES Fuel_Type(fuel_type_id),
    price NUMERIC,
    discounted_price NUMERIC,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Supplier Table
CREATE TABLE IF NOT EXISTS Supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(30) NOT NULL,
    contact_number VARCHAR(14) NOT NULL,
    country_code CHAR(2) REFERENCES Country(country_code),
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Replenishment Table
CREATE TABLE IF NOT EXISTS Replenishment (
    replenishment_id SERIAL PRIMARY KEY,
    station_id INT REFERENCES Station(station_id),
    supplier_id INT REFERENCES Supplier(supplier_id),
    fuel_type_id INT REFERENCES Fuel_Type(fuel_type_id),
    quantity_received INT,
    order_date TIMESTAMP,
    delivery_date TIMESTAMP,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Employee Table
CREATE TABLE IF NOT EXISTS Employee (
    employee_id SERIAL PRIMARY KEY,
    person_id INT REFERENCES Person(person_id),
    station_id INT REFERENCES Station(station_id),
    location_id INT REFERENCES Location(location_id),
    start_date DATE,
    end_date DATE,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Customer Table
CREATE TABLE IF NOT EXISTS Customer (
    customer_id SERIAL PRIMARY KEY,
    person_id INT REFERENCES Person(person_id),
    loyalty_points INT,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Payment_Method Table
CREATE TABLE IF NOT EXISTS Payment_Method (
    payment_method_id SERIAL PRIMARY KEY,
    payment_method_name VARCHAR(30) NOT NULL,
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Sale Table
CREATE TABLE IF NOT EXISTS Sale (
    sale_id SERIAL PRIMARY KEY,
    station_id INT REFERENCES Station(station_id),
    fuel_type_id INT REFERENCES Fuel_Type(fuel_type_id),
    customer_id int REFERENCES Customer(customer_id),
    quantity_sold decimal(10, 2),
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Payment Table
CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,
    sale_id INT NOT NULL REFERENCES Sale(sale_id),
    payment_date TIMESTAMPTZ NOT NULL,
    amount decimal(10, 2) NOT NULL, 
    employee_id INT REFERENCES Employee(employee_id),
    payment_method_id INT REFERENCES Payment_Method(payment_method_id),
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Employee_Sale Table (Bridge Table for M:N Relationship)
CREATE TABLE IF NOT EXISTS Employee_Sale (
    employee_sale_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES Employee(employee_id),
    sale_id INT REFERENCES Sale(sale_id),
    last_update timestamptz NOT NULL DEFAULT now()
);

-- Create Employee_Role Table (Bridge Table for M:N Relationship)
CREATE TABLE IF NOT EXISTS Employee_Role (
    employee_role_id SERIAL PRIMARY KEY,
    employee_id INT REFERENCES Employee(employee_id),
    role_id INT REFERENCES Role(role_id),
    last_update timestamptz NOT NULL DEFAULT now()
);

-------------------------------------------------------------

--								   CONSTRAINTS						     --

-------------------------------------------------------------

-- Non-Negative Quantity Check Constraint in Inventory Table
ALTER TABLE Inventory
ADD CONSTRAINT chk_non_negative_quantity
CHECK (quantity >= 0);

-- Non-Negative Quantity Check Constraint in Replenishment Table
ALTER TABLE Replenishment
ADD CONSTRAINT chk_non_negative_quantity_received
CHECK (quantity_received >= 0);

-- Specific Value Check Constraint in Pricing Table for price
ALTER TABLE Pricing
ADD CONSTRAINT chk_non_negative_price
CHECK (price > 0);

-- Date Check Constraint in Replenishment Table for order_date
ALTER TABLE Replenishment
ADD CONSTRAINT chk_valid_order_date
CHECK (order_date > '2023-11-01');

-- Date Check Constraint in Replenishment Table for delivery_date
ALTER TABLE Replenishment
ADD CONSTRAINT chk_valid_delivery_date
CHECK (delivery_date > '2023-11-01');

-- Check Constraint in Person Table for contact_number format (must contain '+' and 11 digits)
ALTER TABLE Person
ADD CONSTRAINT chk_valid_contact_number_format
CHECK (contact_number LIKE '+___________');

-- Not Null Constraint in Sale Table for customer_id
ALTER TABLE Sale
ALTER COLUMN customer_id SET NOT NULL;

-- Unique Constraint in Employee_Sale Table for employee_id and sale_id
ALTER TABLE Employee_Sale
ADD CONSTRAINT uq_unique_employee_sale
UNIQUE (employee_id, sale_id);

-- Not Null Constraint in Payment Table for amount
ALTER TABLE Payment
ALTER COLUMN amount SET NOT NULL;

ALTER TABLE Payment
ADD CONSTRAINT chk_non_negative_amount
CHECK (amount > 0);

-- Date Check Constraint in Payment Table for payment_date
ALTER TABLE Payment
ADD CONSTRAINT chk_valid_payment_date
CHECK (payment_date > '2023-11-01');

-- Check Constraint in Replenishment Table for delivery_date not earlier than order_date
ALTER TABLE Replenishment
ADD CONSTRAINT chk_delivery_not_earlier_than_order
CHECK (delivery_date >= order_date);


CREATE OR REPLACE FUNCTION last_updated()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END $function$
;

DO $$ 
DECLARE
    tname text;
BEGIN
    -- Loop through each table in the schema
    FOR tname IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'fuel_station' AND table_type = 'BASE TABLE') 
    LOOP
        -- Construct the trigger creation statement using dynamic SQL
        EXECUTE format('
            CREATE TRIGGER last_updated BEFORE
            UPDATE ON %I FOR EACH ROW 
            EXECUTE FUNCTION last_updated();
           
           	ALTER TABLE fuel_station.%I
            ADD CONSTRAINT chk_valid_last_update
            CHECK (last_update > ''2024-01-01'');', tname, tname);
    END LOOP;
END $$;

-------------------------------------------------------------

--										DML								  --

-------------------------------------------------------------

-- Insert into Country
INSERT INTO Country (country_code, country_name)
VALUES 
		('KZ', 'Kazakhstan'), 
		('AR', 'Argentine'),
		('AU', 'Australia'),
		('CA', 'Canada'),
		('PL', 'Poland'),
		('DM', 'Dominica');

-- Insert into City
INSERT INTO City (country_code, city_name)
VALUES 
    ('KZ', 'Almaty'),
    ('KZ', 'Nur-Sultan'),
    ('KZ', 'Shymkent'),
    ('KZ', 'Karaganda'),
    ('KZ', 'Aktobe'),
    ('KZ', 'Pavlodar');

-- Insert into Location
INSERT INTO Location (city_id, address_line1, address_line2)
VALUES 
    ((SELECT city_id FROM city WHERE upper(city_name) = 'ALMATY'), '123 Abay Ave', 'Apartment 5'),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'NUR-SULTAN'), '456 Nazarbayev St', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'SHYMKENT'), '789 Lenin St', 'Office 102'),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'KARAGANDA'), '101 Karagandy St', 'Floor 5'),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'AKTOBE'), '112 Pushkin St', 'Flat 3'),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'PAVLODAR'), '131 Astana St', 'Apartment 12'),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'ALMATY'), '1 Abay Ave', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'NUR-SULTAN'), '2 Nazarbayev St', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'SHYMKENT'), '3 Lenin St', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'KARAGANDA'), '4 Karagandy St', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'AKTOBE'), '5 Pushkin St', NULL),
    ((SELECT city_id FROM city WHERE upper(city_name) = 'PAVLODAR'), '6 Astana St', NULL);

-- Insert into Role
INSERT INTO Role (role_name, description)
VALUES 
    ('Manager', 'Manages operations'),
    ('Technician', 'Handles technical tasks'),
    ('Sales Associate', 'Assists customers with purchases'),
    ('Driver', 'Delivers fuel supplies'),
    ('Engineer', 'Works on technical projects'),
    ('Customer Service Representative', 'Assists customers with inquiries');

-- Insert into Person
INSERT INTO Person (first_name, last_name, contact_number)
VALUES 
    ('Aibek', 'Nazarbayev', '+77123456789'),
    ('Aigerim', 'Tokayeva', '+77234567890'),
    ('Baurzhan', 'Kazakhov', '+77345678901'),
    ('Dinara', 'Zhumasheva', '+77456789012'),
    ('Erlan', 'Sadykov', '+77567890123'),
    ('Gulnaz', 'Kenesova', '+77678901234'),
    ('Zhanar', 'Suleimenova', '+77011223444'),
    ('Ruslan', 'Kudaibergenov', '+77011223455'),
    ('Aigerim', 'Zhumagaliyeva', '+77011223466'),
    ('Bauyrzhan', 'Ospanov', '+77011223477'),
    ('Dina', 'Tazhibayeva', '+77011223488'),
    ('Erbol', 'Kulbayev', '+77011223499');

-- Insert into Station
INSERT INTO Station (station_name, location_id, contact_number)
VALUES 
    ('Station Almaty', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '123 ABAY AVE APARTMENT 5'), '+77111222333'),
    ('Station Nur-Sultan', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '456 NAZARBAYEV ST'), '+77222333444'),
    ('Station Shymkent', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '789 LENIN ST OFFICE 102'), '+77333444555'),
    ('Station Karaganda', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '101 KARAGANDY ST FLOOR 5'), '+77444555666'),
    ('Station Aktobe', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '112 PUSHKIN ST FLAT 3'), '+77555666777'),
    ('Station Pavlodar', (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '131 ASTANA ST APARTMENT 12'), '+77666777888');

-- Insert into Fuel_Type
INSERT INTO Fuel_Type (fuel_type_name)
VALUES 
    ('Regular'),
    ('Premium'),
    ('Diesel'),
    ('98-Octane'),
    ('95-Octane'),
    ('92-Octane');

-- Insert into Inventory
INSERT INTO Inventory (station_id, fuel_type_id, quantity)
VALUES 
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 1000),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 500),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 800),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 1200),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 600),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 900),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 1000),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 500),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 800),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 1200),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 600),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 900);

-- Insert into Pricing
INSERT INTO Pricing (station_id, fuel_type_id, price, discounted_price)
VALUES 
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 2.50, 2.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 3.00, 2.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 2.80, 2.50),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 2.60, 2.35),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 3.20, 2.95),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 2.90, 2.65);

-- Insert into Supplier
INSERT INTO Supplier (supplier_name, contact_number, country_code)
VALUES 
    ('PETROLEOS DE KAZAKHSTAN', '+77711112222', 'KZ'),
    ('EuroOil', '+77722223333', 'KZ'),
    ('Atlant Broker Company', '+77733334444', 'KZ'),
    ('HIT Kazakhstan', '+77744445555', 'KZ'),
    ('Astana Munai Trade', '+77755556666', 'KZ'),
    ('KAZOIL', '+77766667777', 'KZ');

-- Insert into Replenishment
INSERT INTO Replenishment (station_id, supplier_id, fuel_type_id, quantity_received, order_date, delivery_date)
VALUES 
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'HIT KAZAKHSTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), 1000, '2023-12-01', '2023-12-05'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'PETROLEOS DE KAZAKHSTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 500, '2023-12-02', '2023-12-06'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'EUROOIL'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 800, '2023-12-03', '2023-12-07'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'EUROOIL'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), 1200, '2023-12-04', '2023-12-08'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'PETROLEOS DE KAZAKHSTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 600, '2023-12-05', '2023-12-09'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'ATLANT BROKER COMPANY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 900, '2023-12-06', '2023-12-10'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'ASTANA MUNAI TRADE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'PREMIUM'), 1000, '2023-12-01', '2023-12-05'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'PETROLEOS DE KAZAKHSTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 500, '2023-12-02', '2023-12-06'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'KAZOIL'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), 800, '2023-12-03', '2023-12-07'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'ATLANT BROKER COMPANY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 1200, '2023-12-04', '2023-12-08'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'KAZOIL'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '98-OCTANE'), 600, '2023-12-05', '2023-12-09'),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT supplier_id FROM supplier WHERE upper(supplier_name) = 'KAZOIL'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), 900, '2023-12-06', '2023-12-10');

-- Insert into Employee
INSERT INTO Employee (person_id, station_id, location_id, start_date, end_date)
VALUES 
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'ZHANAR SULEIMENOVA'), (SELECT station_id FROM Station WHERE station_name = 'Station Almaty'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '1 Abay Ave'), '2023-11-01', NULL),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'RUSLAN KUDAIBERGENOV'), (SELECT station_id FROM Station WHERE station_name = 'Station Nur-Sultan'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '2 Nazarbayev St'), '2023-11-01', '2023-12-01'),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'AIGERIM ZHUMAGALIYEVA'), (SELECT station_id FROM Station WHERE station_name = 'Station Shymkent'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '3 Lenin St'), '2023-11-15', NULL),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'BAUYRZHAN OSPANOV'), (SELECT station_id FROM Station WHERE station_name = 'Station Karaganda'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '4 Karagandy St'), '2023-11-01', NULL),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'DINA TAZHIBAYEVA'), (SELECT station_id FROM Station WHERE station_name = 'Station Aktobe'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '5 Pushkin St'), '2023-11-15', NULL),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'ERBOL KULBAYEV'), (SELECT station_id FROM Station WHERE station_name = 'Station Pavlodar'), (SELECT location_id FROM "location" WHERE upper(address_line1 || '' || address_line2) = '6 Astana St'), '2023-11-01', NULL);

-- Insert into Customer
INSERT INTO Customer (person_id, loyalty_points)
VALUES 
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'AIBEK NAZARBAYEV'), 0),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'AIGERIM TOKAYEVA'), 0),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'BAURZHAN KAZAKHOV'), 0),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'DINARA ZHUMASHEVA'), 10),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'ERLAN SADYKOV'), 0),
    ((SELECT person_id FROM Person WHERE upper(first_name || ' ' || last_name) = 'GULNAZ KENESOVA'), 5);

-- Insert into Payment_Method
INSERT INTO Payment_Method (payment_method_name)
VALUES 
    ('Credit Card'),
    ('Cash'),
    ('Debit Card'),
    ('Mobile Payment'),
    ('Check'),
    ('Gift Card');

-- Insert into Sale
INSERT INTO Sale (station_id, fuel_type_id, customer_id, quantity_sold)
VALUES 
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION ALMATY'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'REGULAR'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'AIBEK NAZARBAYEV'), 20.5),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION NUR-SULTAN'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'AIGERIM TOKAYEVA'), 15.75),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION SHYMKENT'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'BAURZHAN KAZAKHOV' ), 18.0),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION KARAGANDA'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = 'DIESEL'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'DINARA ZHUMASHEVA' ), 25.5),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION AKTOBE'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '95-OCTANE'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'ERLAN SADYKOV' ), 12.25),
    ((SELECT station_id FROM station WHERE upper(station_name) = 'STATION PAVLODAR'), (SELECT fuel_type_id FROM fuel_type WHERE upper(fuel_type_name) = '92-OCTANE'), (SELECT c.customer_id FROM customer c INNER JOIN person p ON c.person_id = p.person_id WHERE upper(p.first_name || ' ' || p.last_name) = 'GULNAZ KENESOVA' ), 30.0);

-- Insert into Payment
INSERT INTO Payment (sale_id, payment_date, amount, employee_id, payment_method_id)
VALUES 
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 20.5), '2023-12-10', 25.75, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'ZHANAR SULEIMENOVA' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Credit Card')),
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 15.75), '2023-12-12', 30.00, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'RUSLAN KUDAIBERGENOV' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Cash')),
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 18.0), '2023-12-14', 22.50, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'AIGERIM ZHUMAGALIYEVA' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Debit Card')),
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 25.5), '2023-12-16', 32.50, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'BAUYRZHAN OSPANOV' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Mobile Payment')),
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 12.25), '2023-12-18', 15.75, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'DINA TAZHIBAYEVA' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Check')),
    ((SELECT sale_id FROM Sale WHERE quantity_sold = 30.0), '2023-12-20', 40.00, (SELECT employee_id FROM employee e INNER JOIN person p ON e.person_id = p.person_id WHERE upper(p.first_name || '' || p.last_name) = 'ERBOL KULBAYEV' LIMIT 1), (SELECT payment_method_id FROM Payment_Method WHERE payment_method_name = 'Gift Card'));

-- Insert into Employee_Sale
INSERT INTO Employee_Sale (employee_id, sale_id)
VALUES 
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-01-01'), (SELECT sale_id FROM Sale WHERE quantity_sold = 20.5)),
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-02-01'), (SELECT sale_id FROM Sale WHERE quantity_sold = 15.75)),
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-02-15'), (SELECT sale_id FROM Sale WHERE quantity_sold = 18.0)),
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-03-01'), (SELECT sale_id FROM Sale WHERE quantity_sold = 25.5)),
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-03-15'), (SELECT sale_id FROM Sale WHERE quantity_sold = 12.25)),
    ((SELECT employee_id FROM Employee WHERE start_date = '2023-04-01'), (SELECT sale_id FROM Sale WHERE quantity_sold = 30.0));

   
   
   
CREATE OR REPLACE FUNCTION update_pricing_column(
    p_pricing_id int,
    p_column_name text,
    p_new_value ANYELEMENT --to make sure that function could work with any data type 
)
RETURNS VOID
AS $$
DECLARE
    v_sql text;
BEGIN
    -- Construct the dynamic SQL statement for updating the specified column in the 'Pricing' table
    v_sql := format('UPDATE Pricing SET %I = $1 WHERE pricing_id = $2 returning *', p_column_name);

    -- Execute the dynamic SQL with the provided parameters
    EXECUTE v_sql USING p_new_value, p_pricing_id;
END;
$$ LANGUAGE plpgsql;

-- Update the 'price' column in the 'Pricing' table for the row with pricing_id = 1
SELECT update_pricing_column(1, 'price', 15.99);

CREATE OR REPLACE FUNCTION add_new_transaction(
    p_station_id int,
    p_fuel_type_id int,
    p_customer_id int,
    p_quantity_sold decimal
)
RETURNS VOID
AS $$
BEGIN
    -- Insert a new row into the 'Sale' table
    INSERT INTO Sale (station_id, fuel_type_id, customer_id, quantity_sold, last_update)
    VALUES (p_station_id, p_fuel_type_id, p_customer_id, p_quantity_sold, CURRENT_TIMESTAMP);

    -- Confirm successful insertion 
    RAISE NOTICE 'New transaction added successfully!';
END;
$$ LANGUAGE plpgsql;

-- Add a new transaction for station_id = 1, fuel_type_id = 2, customer_id = 3, quantity_sold = 20.5
SELECT add_new_transaction(1, 2, 3, 20.5);