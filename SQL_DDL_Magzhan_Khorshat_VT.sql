--SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'healthcare_facilities';
DROP DATABASE IF EXISTS healthcare_facilities;
CREATE DATABASE healthcare_facilities;

CREATE SCHEMA IF NOT EXISTS heal_fac;
SET search_path TO heal_fac;

ALTER TABLE IF EXISTS Staff DROP COLUMN IF EXISTS staff_role;
DROP TYPE IF EXISTS staff_role_enum;
-- Define ENUM type for staff roles
CREATE TYPE staff_role_enum AS ENUM ('DOCTOR', 'NURSE', 'ADMIN', 'TECHNICIAN', 'THERAPIST');
ALTER TABLE IF EXISTS Staff ADD COLUMN staff_role staff_role_enum;


--Table: Location. Contains information about various addresses where healthcare facilities might be situated
CREATE TABLE IF NOT EXISTS Location (
    location_id SERIAL PRIMARY KEY, --Unique identifier for each location
    Address_Line1 VARCHAR(100) not null, --address details, varchar since address may contain any characters
    Address_Line2 VARCHAR(100) not null --additional address details
);

-- Table: Facility. Stores details about healthcare facilities
CREATE TABLE IF NOT EXISTS Facility (
    facility_id SERIAL PRIMARY KEY, --Unique identifier for each facility
    facility_name VARCHAR(100) NOT NULL,
    location_id INTEGER references location(location_id) NOT NULL, --to link facilities to their addresses
    capacity_per_day INTEGER CHECK (capacity_per_day > 0) --Represents the maximum number of patients the facility can handle in a day
);

-- Table: Staff. Manages information about staff members working at healthcare facilities
CREATE TABLE IF NOT EXISTS Staff (
    staff_id SERIAL PRIMARY KEY, --Unique identifier for each staff member
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    staff_role staff_role_enum NOT NULL
);	

-- Table: Resource. Tracks resources available at each facility
CREATE TABLE IF NOT EXISTS Resource (
    resource_id SERIAL PRIMARY KEY, --Unique identifier for each resource
    facility_id INTEGER REFERENCES Facility(facility_id), --to link resources to specific facilities
    resource_name VARCHAR(50) NOT NULL,
    quantity INTEGER CHECK (quantity >= 0)
);

-- Table: Patient. Manages information about patients' visits to healthcare facilities
CREATE TABLE IF NOT EXISTS Patient (
    patient_id SERIAL PRIMARY KEY, --Unique identifier for each patient
    first_name VARCHAR(50) NOT null,
    last_name VARCHAR(50) NOT NULL
);

-- Table: Schedules. Manages schedules for staff members at healthcare facilities
CREATE TABLE IF NOT EXISTS Schedule (
    schedule_id SERIAL PRIMARY KEY, --Unique identifier for each schedule entry
    staff_id INTEGER REFERENCES Staff(staff_id), --to associate schedules with specific staff members
    schedule_date DATE NOT NULL,
    start_time TIME NOT NULL,	
    end_time TIME NOT NULL
);

CREATE TABLE IF NOT EXISTS Facility_Staff (
    facility_id INTEGER REFERENCES Facility(facility_id),
    staff_id INTEGER REFERENCES Staff(staff_id),
    PRIMARY KEY (facility_id, staff_id)
);

CREATE TABLE IF NOT EXISTS Visit (
    visit_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES Patient(patient_id),
    facility_id INTEGER REFERENCES Facility(facility_id),
    visit_date DATE NOT NULL,
    staff_id INTEGER REFERENCES Staff(staff_id)
);

ALTER TABLE IF EXISTS Schedule DROP CONSTRAINT IF EXISTS check_start_end_time;
ALTER TABLE IF EXISTS Schedule ADD CONSTRAINT check_start_end_time CHECK (start_time < end_time);
ALTER TABLE IF EXISTS Patient ADD COLUMN IF NOT EXISTS full_name VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED;





-- Location Table
INSERT INTO Location (Address_Line1, Address_Line2)
SELECT *
FROM (
    VALUES 
        ('Astana Avenue 123', 'Block A'), 
        ('Qabanbay Batyr Street 456', 'Apartment 3'), 
        ('Kunaev Street 789', 'Building B'), 
        ('Zheltoksan Street 321', '1'), 
        ('Mangilik El Avenue 567', '/5')
) AS loc (Address_Line1, Address_Line2)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Location 
    WHERE UPPER(Address_Line1) LIKE UPPER(loc.Address_Line1) AND UPPER(Address_Line2) LIKE upper(loc.Address_Line2)
);

-- Facility Table
INSERT INTO Facility (facility_name, location_id, capacity_per_day)
SELECT *
FROM (
    VALUES 
        ('ASTANA CITY HOSPITAL', (SELECT location_id FROM Location WHERE UPPER(Address_Line1) = 'ASTANA AVENUE 123' limit 1), 300), 
        ('ASTANA CENTRAL CLINIC', (SELECT location_id FROM Location WHERE UPPER(Address_Line1) = 'QABANBAY BATYR STREET 456' limit 1), 150), 
        ('ASTANA HEALTH CENTER', (SELECT location_id FROM Location WHERE UPPER(Address_Line1) = 'KUNAEV STREET 789' limit 1), 200), 
        ('ASTANA MEDICAL COMPLEX', (SELECT location_id FROM Location WHERE UPPER(Address_Line1) = 'ZHELTOKSAN STREET 321' limit 1), 250), 
        ('ASTANA URGENT CARE CENTER', (SELECT location_id FROM Location WHERE UPPER(Address_Line1) = 'MANGILIK EL AVENUE 567' limit 1), 100)
) AS fac (facility_name, location_id, capacity_per_day)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Facility 
    WHERE UPPER(facility_name) = UPPER(fac.facility_name) AND location_id = fac.location_id
);

-- Staff Table
INSERT INTO Staff (first_name, last_name, staff_role)
SELECT *
FROM (
    VALUES 
        ('NURZHAN', 'KAZBEKOV', 'DOCTOR'::staff_role_enum), 
        ('AISHA', 'SULTANOVA', 'NURSE'::staff_role_enum), 
        ('BEKZAT', 'TULEPOV', 'TECHNICIAN'::staff_role_enum), 
        ('GULNAZ', 'ISKAKOVA', 'ADMIN'::staff_role_enum), 
        ('RUSLAN', 'BAIBEKOV', 'THERAPIST'::staff_role_enum)
) AS stf (first_name, last_name, staff_role)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Staff 
    WHERE UPPER(first_name) = UPPER(stf.first_name) AND UPPER(last_name) = UPPER(stf.last_name)
);

-- Resource Table
INSERT INTO Resource (facility_id, resource_name, quantity)
SELECT *
FROM (
    VALUES 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CITY HOSPITAL'), 'CT Scanner', 2), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CENTRAL CLINIC'), 'Laboratory Equipment', 3), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA HEALTH CENTER'), 'Operating Room Tools', 4), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA MEDICAL COMPLEX'), 'Anesthesia Machines', 5), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA URGENT CARE CENTER'), 'Defibrillators', 3)
) AS res (facility_id, resource_name, quantity)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Resource 
    WHERE resource_name = res.resource_name
);

-- Patient Table
INSERT INTO Patient (first_name, last_name)
SELECT *
FROM (
    VALUES 
        ('AIDANA', 'NURZHANOVA'), 
        ('ARMAN', 'ZHUMABEKOV'), 
        ('DANA', 'KUDAIBERGENOVA'), 
        ('KAIRAT', 'NURMAGAMBETOV'), 
        ('ALIYA', 'SARSENOVA')
) AS pat (first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Patient 
    WHERE UPPER(first_name) = UPPER(pat.first_name) AND UPPER(last_name) = UPPER(pat.last_name)
);

-- Schedules Table
INSERT INTO Schedule (staff_id, schedule_date, start_time, end_time)
SELECT *
FROM (
    VALUES 
        ((SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'NURZHAN' AND UPPER(last_name) = 'KAZBEKOV'), '2023-12-05'::DATE, '08:00'::TIME, '16:00'::TIME), 
        ((SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'AISHA' AND UPPER(last_name) = 'SULTANOVA'), '2023-12-06'::DATE, '09:00'::TIME, '17:00'::TIME), 
        ((SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'BEKZAT' AND UPPER(last_name) = 'TULEPOV'), '2023-12-07'::DATE, '10:00'::TIME, '18:00'::TIME), 
        ((SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'GULNAZ' AND UPPER(last_name) = 'ISKAKOVA'), '2023-12-08'::DATE, '07:00'::TIME, '15:00'::TIME), 
        ((SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'RUSLAN' AND UPPER(last_name) = 'BAIBEKOV'), '2023-12-09'::DATE, '12:00'::TIME, '20:00'::TIME)
) AS sch (staff_id, schedule_date, start_time, end_time)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Schedule 
    WHERE staff_id = sch.staff_id AND schedule_date = sch.schedule_date
);

-- Facility_Staff Table
INSERT INTO Facility_Staff (facility_id, staff_id)
SELECT *
FROM (
    VALUES 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CITY HOSPITAL'), (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'NURZHAN' AND UPPER(last_name) = 'KAZBEKOV')), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CENTRAL CLINIC'), (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'AISHA' AND UPPER(last_name) = 'SULTANOVA')), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA HEALTH CENTER'), (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'BEKZAT' AND UPPER(last_name) = 'TULEPOV')), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA MEDICAL COMPLEX'), (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'GULNAZ' AND UPPER(last_name) = 'ISKAKOVA')), 
        ((SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA URGENT CARE CENTER'), (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'RUSLAN' AND UPPER(last_name) = 'BAIBEKOV'))
) AS fs (facility_id, staff_id)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Facility_Staff 
    WHERE facility_id = fs.facility_id AND staff_id = fs.staff_id
);

-- Visit Table
INSERT INTO Visit (patient_id, facility_id, visit_date, staff_id)
SELECT *
FROM (
    VALUES 
        ((SELECT patient_id FROM Patient WHERE UPPER(first_name) = 'AIDANA' AND UPPER(last_name) = 'NURZHANOVA'), (SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CITY HOSPITAL'), '2023-12-01'::DATE, (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'NURZHAN' AND UPPER(last_name) = 'KAZBEKOV')), 
        ((SELECT patient_id FROM Patient WHERE UPPER(first_name) = 'ARMAN' AND UPPER(last_name) = 'ZHUMABEKOV'), (SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA CENTRAL CLINIC'), '2023-12-02'::DATE, (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'AISHA' AND UPPER(last_name) = 'SULTANOVA')), 
        ((SELECT patient_id FROM Patient WHERE UPPER(first_name) = 'DANA' AND UPPER(last_name) = 'KUDAIBERGENOVA'), (SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA HEALTH CENTER'), '2023-12-03'::DATE, (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'BEKZAT' AND UPPER(last_name) = 'TULEPOV')), 
        ((SELECT patient_id FROM Patient WHERE UPPER(first_name) = 'KAIRAT' AND UPPER(last_name) = 'NURMAGAMBETOV'), (SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA MEDICAL COMPLEX'), '2023-12-04'::DATE, (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'GULNAZ' AND UPPER(last_name) = 'ISKAKOVA')), 
        ((SELECT patient_id FROM Patient WHERE UPPER(first_name) = 'ALIYA' AND UPPER(last_name) = 'SARSENOVA'), (SELECT facility_id FROM Facility WHERE UPPER(facility_name) = 'ASTANA URGENT CARE CENTER'), '2023-12-05'::DATE, (SELECT staff_id FROM Staff WHERE UPPER(first_name) = 'RUSLAN' AND UPPER(last_name) = 'BAIBEKOV'))
) AS vis (patient_id, facility_id, visit_date, staff_id)
WHERE NOT EXISTS (
    SELECT 1 
    FROM Visit 
    WHERE patient_id = vis.patient_id AND facility_id = vis.facility_id AND visit_date = vis.visit_date and staff_id = vis.staff_id
);


-- Task 2

SELECT
    S.staff_id,
    S.first_name,
    S.last_name,
    COUNT(V.visit_id) AS patient_count,
    DATE_TRUNC('month', V.visit_date) AS visit_month
FROM
    Staff S
LEFT JOIN
    Schedule Sch ON S.staff_id = Sch.staff_id
LEFT JOIN
    Visit V ON Sch.staff_id = V.staff_id 
WHERE
    V.visit_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 months') -- Filter for last two months
    AND V.visit_date < DATE_TRUNC('month', CURRENT_DATE) -- Filter for current month
GROUP BY
    S.staff_id, S.first_name, S.last_name, visit_month
HAVING
    COUNT(V.visit_id) < 5 -- Filter workload fewer than 5 patients per month
ORDER BY
    S.staff_id, visit_month;
