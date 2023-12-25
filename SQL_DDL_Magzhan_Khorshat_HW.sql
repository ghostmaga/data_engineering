DROP 
  DATABASE IF EXISTS recruitment_agency_db;
CREATE database recruitment_agency_db;
CREATE SCHEMA IF NOT EXISTS rec_agency;
SET 
  search_path TO rec_agency;
ALTER TABLE 
  IF exists candidate_education 
DROP 
  COLUMN IF EXISTS degree;
DROP 
  TYPE IF EXISTS degree_types;
-- Define ENUM type for Degree typesCREATE TYPE degree_types AS enum (
    'HIGH SCHOOL', 
    'ASSOCIATE', 
    'BACHELOR', 
    'MASTER', 
    'DOCTORATE'
);
ALTER TABLE 
  IF EXISTS candidate_education 
ADD 
  COLUMN degree degree_types;
CREATE TABLE IF NOT EXISTS contract_type (
  contract_type_id serial PRIMARY KEY, 
  contract_type_name VARCHAR(50), 
  description VARCHAR(500)
);
CREATE TABLE IF NOT EXISTS company_type (
  company_type_id serial PRIMARY KEY, 
  company_type_name VARCHAR(50), 
  description VARCHAR(500)
);
CREATE TABLE IF NOT EXISTS position (
  position_id serial PRIMARY KEY, 
  position_name VARCHAR(50), 
  description VARCHAR(500), 
  salary DECIMAL(10, 2)
);
CREATE TABLE IF NOT EXISTS country (
  country_code CHAR(2) PRIMARY KEY, 
  country_name VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS job_type (
  job_type_id serial PRIMARY KEY, 
  job_type_name VARCHAR(50), 
  description VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS service (
  service_id serial PRIMARY KEY, 
  service_name VARCHAR(100), 
  description VARCHAR(200), 
  cost DECIMAL(10, 2)
);
CREATE TABLE IF NOT EXISTS recruiter (
  recruiter_id serial PRIMARY KEY, 
  recruiter_name VARCHAR(50), 
  recruiter_surname VARCHAR(50), 
  email VARCHAR(50), 
  phone VARCHAR(20), 
  recruiter_fullname VARCHAR(100) generated always AS (
    recruiter_name || ' ' || recruiter_surname
  ) stored
);
CREATE TABLE IF NOT EXISTS skill (
  skill_id serial PRIMARY KEY, 
  skill_name VARCHAR(100)
);
CREATE TABLE IF NOT EXISTS city (
  city_id serial PRIMARY KEY, 
  city_name VARCHAR(50), 
  country_code CHAR(2)
);
CREATE TABLE IF NOT EXISTS location (
  location_id serial PRIMARY KEY, 
  city_id INT, 
  address_line1 VARCHAR(50), 
  address_line2 VARCHAR(50)
);
CREATE TABLE IF NOT EXISTS company (
  company_id serial PRIMARY KEY, 
  company_name VARCHAR(50), 
  company_type_id INT, 
  country_code CHAR(2) --all countries are specified only by 2 characters
);
CREATE TABLE IF NOT EXISTS job (
  job_id serial PRIMARY KEY, 
  company_id INT, 
  position_id INT, 
  description VARCHAR(1500), 
  posting_date DATE, 
  deadline_to_apply timestamp, 
  job_type_id INT
);
CREATE TABLE IF NOT EXISTS candidate (
  candidate_id serial PRIMARY KEY, 
  candidate_fname VARCHAR(50), 
  candidate_lname VARCHAR(50), 
  email VARCHAR(50) UNIQUE NOT NULL, 
  phone VARCHAR(20), 
  location_id INT, 
  candidate_fullname VARCHAR(100) generated always AS (
    candidate_fname || ' ' || candidate_lname
  ) stored, -- fullname will be generated with concatenation of first name and last name
  total_experience_in_months INT -- calculated after every insert/delete using the trigger, useful attribute to display important info about candidate
);
CREATE 
OR replace FUNCTION calculate_total_experience() returns TRIGGER AS $$ BEGIN 
UPDATE 
  candidate c 
SET 
  total_experience_in_months = (
    SELECT 
      SUM(duration_in_months) 
    FROM 
      candidate_experience ce 
    WHERE 
      ce.candidate_id = c.candidate_id
  ) 
WHERE 
  candidate_id = NEW.candidate_id;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TABLE IF NOT EXISTS application (
  application_id serial PRIMARY KEY, 
  candidate_id INT, 
  job_id INT, 
  date_applied DATE CHECK (date_applied > '2000-01-01'), 
  status VARCHAR(10) CHECK (
    status IN (
      'APPLIED', 'REJECTED', 'ACCEPTED', 
      'PENDING', 'WITHDRAWN'
    ) -- specified every possible status and make it enum
  )
);
CREATE TABLE IF NOT EXISTS placement (
  placement_id serial PRIMARY KEY, 
  application_id INT, 
  date_placed DATE, 
  salary_offered DECIMAL(10, 2) CHECK (salary_offered >= 0), -- to avoid invalid values (negative)
  duration INT CHECK (duration >= 0), 
  status VARCHAR(9) CHECK (
    status IN ('PLACED', 'DISMISSED')
  ), 
  contract_type_id INT
);
CREATE TABLE IF NOT EXISTS service_skill (
  service_skill_id serial PRIMARY KEY, 
  service_id INT, skill_id INT
);
CREATE TABLE IF NOT EXISTS institution (
  institution_id serial PRIMARY KEY, 
  name VARCHAR(255) NOT NULL, 
  website VARCHAR(255) CHECK (website ~ * 'https://') --check for website to contain valid secured URL
);
CREATE TABLE IF NOT EXISTS candidate_education (
  education_id serial PRIMARY KEY, candidate_id INT, 
  institution_id INT, degree degree_types, 
  graduation_date DATE
);
CREATE TABLE IF NOT EXISTS candidate_experience (
  experience_id serial PRIMARY KEY, 
  candidate_id INT, 
  company_id INT, 
  title VARCHAR(100), 
  description VARCHAR(500), 
  duration_in_months INT
);

-- Drop the trigger if it exists
DROP 
  TRIGGER IF EXISTS update_total_experience_trigger ON candidate_experience;
-- Create a trigger to update Total_Experience_In_Months on insert or update in Candidate_Experience
CREATE TRIGGER update_total_experience_trigger 
AFTER 
  INSERT 
  OR 
UPDATE 
  ON candidate_experience FOR EACH ROW EXECUTE FUNCTION calculate_total_experience();


CREATE TABLE IF NOT EXISTS candidateskill (
  candidate_id INT, 
  skill_id INT, 
  proficiency VARCHAR(30), 
  PRIMARY KEY (candidate_id, skill_id)
);
CREATE TABLE IF NOT EXISTS interview (
  interview_id serial PRIMARY KEY, 
  application_id INT, 
  recruiter_id INT, 
  interview_date DATE, 
  feedback VARCHAR(200), 
  pass CHAR(4) CHECK (
    pass IN ('PASS', 'FAIL') -- only 2 values are possible
  )
);
CREATE TABLE IF NOT EXISTS candidateservice (
  candidate_service_id serial PRIMARY KEY, 
  candidate_id INT, service_skill_id INT, 
  date_used DATE
);

-- Drop Relationships if exists to avoid error of recreating the FK constraints
--Also, it is better to give constraints custom name instead of auto generated names to make database more convenient 

ALTER TABLE 
  application 
DROP 
  CONSTRAINT IF EXISTS fk_candidate_application;
ALTER TABLE 
  application 
DROP 
  CONSTRAINT IF EXISTS fk_job_application;
ALTER TABLE 
  job 
DROP 
  CONSTRAINT IF EXISTS fk_company_job;
ALTER TABLE 
  job 
DROP 
  CONSTRAINT IF EXISTS fk_position_job;
ALTER TABLE 
  placement 
DROP 
  CONSTRAINT IF EXISTS fk_application_placement;
ALTER TABLE 
  placement 
DROP 
  CONSTRAINT IF EXISTS fk_contracttype_placement;
ALTER TABLE 
  company 
DROP 
  CONSTRAINT IF EXISTS fk_companytype_company;
ALTER TABLE 
  company 
DROP 
  CONSTRAINT IF EXISTS fk_country_company;
ALTER TABLE 
  location 
DROP 
  CONSTRAINT IF EXISTS fk_city_location;
ALTER TABLE 
  service_skill 
DROP 
  CONSTRAINT IF EXISTS fk_serviceskill_service;
ALTER TABLE 
  service_skill 
DROP 
  CONSTRAINT IF EXISTS fk_serviceskill_skill;
ALTER TABLE 
  candidate_education 
DROP 
  CONSTRAINT IF EXISTS fk_candidateeducation_candidate;
ALTER TABLE 
  candidate_experience 
DROP 
  CONSTRAINT IF EXISTS fk_candidateexperience_candidate;
ALTER TABLE 
  candidate_experience 
DROP 
  CONSTRAINT IF EXISTS fk_candidateexperience_company;
ALTER TABLE 
  candidateskill 
DROP 
  CONSTRAINT IF EXISTS fk_candidateskill_candidate;
ALTER TABLE 
  candidateskill 
DROP 
  CONSTRAINT IF EXISTS fk_candidateskill_skill;
ALTER TABLE 
  interview 
DROP 
  CONSTRAINT IF EXISTS fk_interview_recruiter;
ALTER TABLE 
  interview 
DROP 
  CONSTRAINT IF EXISTS fk_interview_application;
ALTER TABLE 
  candidateservice 
DROP 
  CONSTRAINT IF EXISTS fk_candidateservice_candidate;
ALTER TABLE 
  candidateservice 
DROP 
  CONSTRAINT IF EXISTS fk_candidateservice_serviceskill;
ALTER TABLE 
  job 
DROP 
  CONSTRAINT IF EXISTS fk_type_job;
ALTER TABLE 
  city 
DROP 
  CONSTRAINT IF EXISTS fk_city_country;
ALTER TABLE 
  candidate 
DROP 
  CONSTRAINT IF EXISTS fk_candidate_location;
ALTER TABLE 
  candidate_education 
DROP 
  CONSTRAINT IF EXISTS fk_candidateeducation_institution;
ALTER TABLE 
  IF EXISTS candidate 
ADD 
  CONSTRAINT fk_candidate_location FOREIGN KEY (location_id) REFERENCES location(location_id);
ALTER TABLE 
  IF EXISTS application 
ADD 
  CONSTRAINT fk_candidate_application FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id);
ALTER TABLE 
  IF EXISTS application 
ADD 
  CONSTRAINT fk_job_application FOREIGN KEY (job_id) REFERENCES job(job_id);
ALTER TABLE 
  IF EXISTS job 
ADD 
  CONSTRAINT fk_company_job FOREIGN KEY (company_id) REFERENCES company(company_id);
ALTER TABLE 
  IF EXISTS job 
ADD 
  CONSTRAINT fk_position_job FOREIGN KEY (position_id) REFERENCES position(position_id);
ALTER TABLE 
  IF EXISTS job 
ADD 
  CONSTRAINT fk_type_job FOREIGN KEY (job_type_id) REFERENCES job_type(job_type_id);
ALTER TABLE 
  IF EXISTS placement 
ADD 
  CONSTRAINT fk_application_placement FOREIGN KEY (application_id) REFERENCES application(application_id);
ALTER TABLE 
  IF EXISTS placement 
ADD 
  CONSTRAINT fk_contracttype_placement FOREIGN KEY (contract_type_id) REFERENCES contract_type(contract_type_id);
ALTER TABLE 
  IF EXISTS company 
ADD 
  CONSTRAINT fk_companytype_company FOREIGN KEY (company_type_id) REFERENCES company_type(company_type_id);
ALTER TABLE 
  IF EXISTS company 
ADD 
  CONSTRAINT fk_country_company FOREIGN KEY (country_code) REFERENCES country(country_code);
ALTER TABLE 
  IF EXISTS location 
ADD 
  CONSTRAINT fk_city_location FOREIGN KEY (city_id) REFERENCES city(city_id);
ALTER TABLE 
  IF EXISTS service_skill 
ADD 
  CONSTRAINT fk_serviceskill_service FOREIGN KEY (service_id) REFERENCES service(service_id);
ALTER TABLE 
  IF EXISTS service_skill 
ADD 
  CONSTRAINT fk_serviceskill_skill FOREIGN KEY (skill_id) REFERENCES skill(skill_id);
ALTER TABLE 
  IF EXISTS candidate_education 
ADD 
  CONSTRAINT fk_candidateeducation_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id);
ALTER TABLE 
  IF EXISTS candidate_education 
ADD 
  CONSTRAINT fk_candidateeducation_institution FOREIGN KEY (institution_id) REFERENCES institution(institution_id);
ALTER TABLE 
  IF EXISTS candidate_experience 
ADD 
  CONSTRAINT fk_candidateexperience_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id);
ALTER TABLE 
  IF EXISTS candidate_experience 
ADD 
  CONSTRAINT fk_candidateexperience_company FOREIGN KEY (company_id) REFERENCES company(company_id);
ALTER TABLE 
  IF EXISTS candidateskill 
ADD 
  CONSTRAINT fk_candidateskill_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id);
ALTER TABLE 
  IF EXISTS candidateskill 
ADD 
  CONSTRAINT fk_candidateskill_skill FOREIGN KEY (skill_id) REFERENCES skill(skill_id);
ALTER TABLE 
  IF EXISTS interview 
ADD 
  CONSTRAINT fk_interview_application FOREIGN KEY (application_id) REFERENCES application(application_id);
ALTER TABLE 
  IF EXISTS interview 
ADD 
  CONSTRAINT fk_interview_recruiter FOREIGN KEY (recruiter_id) REFERENCES recruiter(recruiter_id);
ALTER TABLE 
  IF EXISTS candidateservice 
ADD 
  CONSTRAINT fk_candidateservice_candidate FOREIGN KEY (candidate_id) REFERENCES candidate(candidate_id);
ALTER TABLE 
  IF EXISTS candidateservice 
ADD 
  CONSTRAINT fk_candidateservice_serviceskill FOREIGN KEY (service_skill_id) REFERENCES service_skill(service_skill_id);
ALTER TABLE 
  IF EXISTS city 
ADD 
  CONSTRAINT fk_city_country FOREIGN KEY (country_code) REFERENCES country(country_code);
-- Apply Check Constraints
ALTER TABLE 
  application 
DROP 
  CONSTRAINT IF EXISTS chk_dateapplied;
ALTER TABLE 
  application 
ADD 
  CONSTRAINT chk_dateapplied CHECK (date_applied > '2000-01-01');
--Inserting sample data for every table
--For every statement there is a 'not exists' statement used to avoid the insertion of duplicated and avoid the constraint violation errors

-- Contract_Type
INSERT INTO contract_type (contract_type_name, description) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'PERMANENT', 'Permanent employment contracts'
      ), 
      (
        'FIXED-TERM', 'Contracts for a specific duration'
      )
  ) AS ct(contract_type_name, description) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      contract_type c 
    WHERE 
      c.contract_type_name = ct.contract_type_name
  );
-- Country
INSERT INTO country (country_code, country_name) 
SELECT 
  * 
FROM 
  (
    VALUES 
      ('US', 'UNITED STATES'), 
      ('UK', 'UNITED KINGDOM')
  ) AS co(country_code, country_name) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      country c 
    WHERE 
      c.country_code = co.country_code
  );
-- City
INSERT INTO city (city_name, country_code) 
SELECT 
  * 
FROM 
  (
    VALUES 
      ('SAN FRANCISCO', 'US'), 
      ('LONDON', 'UK')
  ) AS ci(city_name, country_code) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      city c 
    WHERE 
      c.city_name = ci.city_name 
      AND c.country_code = ci.country_code
  );
-- Company_Type
INSERT INTO company_type (company_type_name, description) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'TECHNOLOGY', 'Technology companies specializing in software development.'
      ), 
      (
        'MARKETING', 'Marketing and advertising agencies.'
      )
  ) AS cty(company_type_name, description) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      company_type c 
    WHERE 
      c.company_type_name = cty.company_type_name
  );
-- Company
INSERT INTO company (
  company_name, company_type_id, country_code
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'TECH SOLUTIONS INC.', 
        (
          SELECT 
            company_type_id 
          FROM 
            company_type 
          WHERE 
            upper(company_type_name) LIKE '%TECH%' 
          limit 
            1
        ), 
        'US'
      ), 
      (
        'MARKETING INNOVATIONS LTD.', 
        (
          SELECT 
            company_type_id 
          FROM 
            company_type 
          WHERE 
            upper(company_type_name) LIKE '%MARKETING%' 
          limit 
            1
        ), 
        'UK'
      )
  ) AS c(
    company_name, company_type_id, country_code
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      company comp 
    WHERE 
      comp.company_name = c.company_name
  );
-- Job_Type
INSERT INTO job_type (job_type_name, description) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'FULL-TIME', 'Regular full-time employment'
      ), 
      (
        'CONTRACT', 'Short-term contract positions'
      )
  ) AS jt(job_type_name, description) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      job_type j 
    WHERE 
      j.job_type_name = jt.job_type_name
  );
-- Position
INSERT INTO position (
  position_name, description, salary
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'SENIOR SOFTWARE ENGINEER', 'Lead development projects', 
        100000.00
      ), 
      (
        'DIGITAL MARKETING MANAGER', 'Oversee digital marketing strategies', 
        90000.00
      )
  ) AS pos(
    position_name, description, salary
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      position p 
    WHERE 
      p.position_name = pos.position_name
  );
-- Job
INSERT INTO job (
  company_id, position_id, description, 
  posting_date, deadline_to_apply, 
  job_type_id
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            company_id 
          FROM 
            company 
          WHERE 
            upper(company_name) LIKE 'TECH SOLUTIONS INC.' 
          limit 
            1
        ), 
        (
          SELECT 
            position_id 
          FROM 
            "position" 
          WHERE 
            upper(position_name) LIKE 'SENIOR SOFTWARE ENGINEER' 
          limit 
            1
        ), 
        'Software Engineer', 
        DATE '2023-01-15', 
        timestamp '2023-02-15 13:51:51', 
        (
          SELECT 
            job_type_id 
          FROM 
            job_type 
          WHERE 
            upper(job_type_name) LIKE 'CONTRACT' 
          limit 
            1
        )
      ), 
      (
        (
          SELECT 
            company_id 
          FROM 
            company 
          WHERE 
            upper(company_name) LIKE 'MARKETING INNOVATIONS LTD.' 
          limit 
            1
        ), 
        (
          SELECT 
            position_id 
          FROM 
            "position" 
          WHERE 
            upper(position_name) LIKE 'DIGITAL MARKETING MANAGER' 
          limit 
            1
        ), 
        'Marketing Manager', 
        DATE '2023-02-01', 
        timestamp '2023-03-01 20:13:46', 
        (
          SELECT 
            job_type_id 
          FROM 
            job_type 
          WHERE 
            upper(job_type_name) LIKE 'FULL-TIME' 
          limit 
            1
        )
      )
  ) AS job(
    company_id, position_id, description, 
    posting_date, deadline_to_apply, 
    job_type_id
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      job j 
    WHERE 
      j.company_id = job.company_id 
      AND j.position_id = job.position_id
  );
-- Recruiter
INSERT INTO recruiter (
  recruiter_name, recruiter_surname, 
  email, phone
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'MICHAEL', 'JOHNSON', 'michael@example.com', 
        '111-222-3333'
      ), 
      (
        'EMILY', 'WILSON', 'emily@example.com', 
        '444-555-6666'
      )
  ) AS rec(
    recruiter_name, recruiter_surname, 
    email, phone
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      recruiter r 
    WHERE 
      r.email = rec.email
  );
-- Location
INSERT INTO location (
  city_id, address_line1, address_line2
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            city_id 
          FROM 
            city 
          WHERE 
            upper(city_name) LIKE 'LONDON' 
          limit 
            1
        ), 
        '123 Main St', 
        'Suite 101'
      ), 
      (
        (
          SELECT 
            city_id 
          FROM 
            city 
          WHERE 
            upper(city_name) LIKE 'SAN FRANCISCO' 
          limit 
            1
        ), 
        '456 Elm St', 
        'Floor 5'
      )
  ) AS loc(
    city_id, address_line1, address_line2
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      location l 
    WHERE 
      l.address_line1 = loc.address_line1 
      AND l.address_line2 = loc.address_line2
  );
-- Candidate
INSERT INTO candidate (
  candidate_fname, candidate_lname, 
  email, phone, location_id
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'ALICE', 
        'JOHNSON', 
        'alice@example.com', 
        '123-456-7890', 
        (
          SELECT 
            location_id 
          FROM 
            location 
          WHERE 
            upper(address_line1) LIKE '132 MAIN ST' 
          limit 
            1
        )
      ), 
      (
        'BOB', 
        'SMITH', 
        'bob@example.com', 
        '987-654-3210', 
        (
          SELECT 
            location_id 
          FROM 
            location 
          WHERE 
            upper(address_line1) LIKE '456 ELM ST' 
          limit 
            1
        )
      )
  ) AS cand(
    candidate_fname, candidate_lname, 
    email, phone, location_id
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      candidate c 
    WHERE 
      c.email = cand.email
  );
-- Institution
INSERT INTO institution (name, website) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'ABC University', 'https://abcuniversity.com'
      ), 
      (
        'XYZ College', 'https://xyzcollege.edu.com'
      )
  ) AS inst(name, website) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      institution ins 
    WHERE 
      ins.name = inst.name 
      AND ins.website = inst.website
  );
-- Candidate_Education
INSERT INTO candidate_education (
  candidate_id, institution_id, degree, 
  graduation_date
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            institution_id 
          FROM 
            institution 
          WHERE 
            upper(name) = 'ABC UNIVERSITY'
        ), 
        'BACHELOR' :: degree_types, 
        DATE '2022-05-30'
      ), 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            institution_id 
          FROM 
            institution 
          WHERE 
            upper(name) = 'XYZ COLLEGE'
        ), 
        'MASTER' :: degree_types, 
        DATE '2023-06-15'
      )
  ) AS ced(
    candidate_id, institution_id, degree, 
    graduation_date
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      candidate_education ce 
    WHERE 
      ce.candidate_id = ced.candidate_id 
      AND ce.institution_id = ced.institution_id
  );
-- Candidate_Experience
INSERT INTO candidate_experience (
  candidate_id, company_id, title, description, 
  duration_in_months
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            company_id 
          FROM 
            company 
          WHERE 
            upper(company_name) LIKE 'TECH SOLUTIONS INC.' 
          limit 
            1
        ), 
        'SOFTWARE DEVELOPER', 
        'Developed scalable web applications', 
        36
      ), 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            company_id 
          FROM 
            company 
          WHERE 
            upper(company_name) LIKE 'MARKETING INNOVATIONS LTD.' 
          limit 
            1
        ), 
        'MARKETING SPECIALIST', 
        'Managed social media campaigns', 
        24
      )
  ) AS cexp(
    candidate_id, company_id, title, description, 
    duration_in_months
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      candidate_experience ce 
    WHERE 
      ce.candidate_id = cexp.candidate_id 
      AND ce.company_id = cexp.company_id 
      AND ce.title = cexp.title
  );
-- Service
INSERT INTO service (service_name, description, cost) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        'SOFTWARE DEVELOPMENT', 'Custom software solutions', 
        500.00
      ), 
      (
        'MARKETING CAMPAIGN', 'Full-scale marketing campaigns', 
        800.00
      )
  ) AS serv(service_name, description, cost) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      service s 
    WHERE 
      s.service_name = serv.service_name
  );
-- Skill
INSERT INTO skill (skill_name) 
SELECT 
  * 
FROM 
  (
    VALUES 
      ('JAVA PROGRAMMING'), 
      ('SOCIAL MEDIA MARKETING')
  ) AS sk(skill_name) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      skill s 
    WHERE 
      s.skill_name = sk.skill_name
  );
-- Service_Skill
INSERT INTO service_skill (service_id, skill_id) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            service_id 
          FROM 
            service 
          WHERE 
            upper(service_name) = 'SOFTWARE DEVELOPMENT'
        ), 
        (
          SELECT 
            skill_id 
          FROM 
            skill 
          WHERE 
            upper(skill_name) = 'JAVA PROGRAMMING'
        )
      ), 
      (
        (
          SELECT 
            service_id 
          FROM 
            service 
          WHERE 
            upper(service_name) = 'MARKETING CAMPAIGN'
        ), 
        (
          SELECT 
            skill_id 
          FROM 
            skill 
          WHERE 
            upper(skill_name) = 'SOCIAL MEDIA MARKETING'
        )
      )
  ) AS ss(service_id, skill_id) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      service_skill ss 
    WHERE 
      ss.service_id = ss.service_id 
      AND ss.skill_id = ss.skill_id
  );
-- CandidateSkill
INSERT INTO candidateskill (
  candidate_id, skill_id, proficiency
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            skill_id 
          FROM 
            skill 
          WHERE 
            upper(skill_name) = 'JAVA PROGRAMMING'
        ), 
        'ADVANCED'
      ), 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            skill_id 
          FROM 
            skill 
          WHERE 
            upper(skill_name) = 'SOCIAL MEDIA MARKETING'
        ), 
        'INTERMEDIATE'
      )
  ) AS cs(
    candidate_id, skill_id, proficiency
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      candidateskill csk 
    WHERE 
      csk.candidate_id = cs.candidate_id 
      AND csk.skill_id = cs.skill_id
  );
-- CandidateService
INSERT INTO candidateservice (
  candidate_id, service_skill_id, date_used
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            service_skill_id 
          FROM 
            service_skill ss 
            inner join service s ON ss.service_id = s.service_id 
          WHERE 
            upper(service_name) = 'SOFTWARE DEVELOPMENT'
        ), 
        DATE '2023-02-20'
      ), 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            service_skill_id 
          FROM 
            service_skill ss 
            inner join service s ON ss.service_id = s.service_id 
          WHERE 
            upper(service_name) = 'MARKETING CAMPAIGN'
        ), 
        DATE '2023-03-10'
      )
  ) AS cserv(
    candidate_id, service_skill_id, date_used
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      candidateservice cser 
    WHERE 
      cser.candidate_id = cserv.candidate_id 
      AND cser.service_skill_id = cserv.service_skill_id
  );
-- Application
INSERT INTO application (
  candidate_id, job_id, date_applied, 
  status
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            j.job_id 
          FROM 
            job j 
            inner join company c ON j.company_id = c.company_id 
            inner join position p ON j.position_id = p.position_id 
          WHERE 
            upper(c.company_name) LIKE 'MARKETING INNOVATIONS LTD.' 
            AND upper(p.position_name) LIKE 'DIGITAL MARKETING MANAGER'
        ), 
        DATE '2023-01-15', 
        'APPLIED'
      ), 
      (
        (
          SELECT 
            candidate_id 
          FROM 
            candidate c 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            j.job_id 
          FROM 
            job j 
            inner join company c ON j.company_id = c.company_id 
            inner join position p ON j.position_id = p.position_id 
          WHERE 
            upper(c.company_name) LIKE 'TECH SOLUTIONS INC.' 
            AND upper(p.position_name) LIKE 'SENIOR SOFTWARE ENGINEER'
        ), 
        DATE '2023-02-20', 
        'PENDING'
      )
  ) AS app(
    candidate_id, job_id, date_applied, 
    status
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      application a 
    WHERE 
      a.candidate_id = app.candidate_id 
      AND a.job_id = app.job_id
  );
-- Interview
INSERT INTO interview (
  application_id, recruiter_id, interview_date, 
  feedback, pass
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            application_id 
          FROM 
            application a 
            inner join candidate c ON a.candidate_id = c.candidate_id 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        (
          SELECT 
            recruiter_id 
          FROM 
            recruiter 
          WHERE 
            upper(recruiter_fullname) = 'MICHAEL JOHNSON'
        ), 
        DATE '2023-02-10', 
        'Impressive technical skills', 
        'PASS'
      ), 
      (
        (
          SELECT 
            application_id 
          FROM 
            application a 
            inner join candidate c ON a.candidate_id = c.candidate_id 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        (
          SELECT 
            recruiter_id 
          FROM 
            recruiter 
          WHERE 
            upper(recruiter_fullname) = 'EMILY WILSON'
        ), 
        DATE '2023-03-05', 
        'Great communication abilities', 
        'FAIL'
      )
  ) AS intrw(
    application_id, recruiter_id, interview_date, 
    feedback, pass
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      interview i 
    WHERE 
      i.application_id = intrw.application_id 
      AND i.recruiter_id = intrw.recruiter_id
  );
-- Placement
INSERT INTO placement (
  application_id, date_placed, salary_offered, 
  duration, status, contract_type_id
) 
SELECT 
  * 
FROM 
  (
    VALUES 
      (
        (
          SELECT 
            application_id 
          FROM 
            application a 
            inner join candidate c ON a.candidate_id = c.candidate_id 
          WHERE 
            upper(c.candidate_fullname) = 'ALICE JOHNSON'
        ), 
        DATE '2023-01-20', 
        75000.00, 
        12, 
        'PLACED', 
        (
          SELECT 
            contract_type_id 
          FROM 
            contract_type 
          WHERE 
            upper(contract_type_name) = 'PERMANENT'
        )
      ), 
      (
        (
          SELECT 
            application_id 
          FROM 
            application a 
            inner join candidate c ON a.candidate_id = c.candidate_id 
          WHERE 
            upper(c.candidate_fullname) = 'BOB SMITH'
        ), 
        DATE '2023-02-25', 
        80000.00, 
        24, 
        'DISMISSED', 
        (
          SELECT 
            contract_type_id 
          FROM 
            contract_type 
          WHERE 
            upper(contract_type_name) = 'FIXED-TERM'
        )
      )
  ) AS pl(
    application_id, date_placed, salary_offered, 
    duration, status, contract_type_id
  ) 
WHERE 
  NOT EXISTS (
    SELECT 
      1 
    FROM 
      placement p 
    WHERE 
      p.application_id = pl.application_id
  );
-- Add 'record_ts' field using ALTER TABLE for every table if it doesn't exist
ALTER TABLE 
  IF EXISTS candidate 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS application 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS job 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS placement 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS company 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS location 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS city 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS service_skill 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS candidate_education 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS candidate_experience 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS skill 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS candidateskill 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS recruiter 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS interview 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS service 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS candidateservice 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS company_type 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS position 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS country 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS job_type 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;
ALTER TABLE 
  IF EXISTS contract_type 
ADD 
  COLUMN IF NOT EXISTS record_ts timestamp DEFAULT current_timestamp NOT NULL;