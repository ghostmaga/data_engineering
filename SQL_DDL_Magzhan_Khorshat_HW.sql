DROP DATABASE IF EXISTS recruitment_agency_DB;
CREATE DATABASE recruitment_agency_DB;

CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE IF NOT EXISTS public.Contract_Type (
    Contract_Type_ID SERIAL PRIMARY KEY,
    Contract_Type_Name VARCHAR(50),
    Description VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS public.Company_Type (
    Company_Type_ID SERIAL PRIMARY KEY,
    Company_Type_Name VARCHAR(50),
    Description VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS public.Position (
    Position_ID SERIAL PRIMARY KEY,
    Position_Name VARCHAR(50),
    Description VARCHAR(500),
    Salary DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS public.Country (
    Country_Code CHAR(2) PRIMARY KEY,
    Country_Name VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS public.Job_Type (
    Job_Type_ID SERIAL PRIMARY KEY,
    Job_Type_Name VARCHAR(50),
    Description VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS public.Service (
    Service_ID SERIAL PRIMARY KEY,
    Service_Name VARCHAR(100),
    Description VARCHAR(200),
    Cost DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS public.Recruiter (
    Recruiter_ID SERIAL PRIMARY KEY,
    Recruiter_Name VARCHAR(50),
    Recruiter_Surname VARCHAR(50),
    Email VARCHAR(50),
    Phone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS public.Skill (
    Skill_ID SERIAL PRIMARY KEY,
    Skill_Name VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS public.City (
    City_ID SERIAL PRIMARY KEY,
    City_Name VARCHAR(50),
    Country_Code CHAR(2) REFERENCES public.Country(Country_Code)
);

CREATE TABLE IF NOT EXISTS public.Location (
    Location_ID SERIAL PRIMARY KEY,
    City_ID INT REFERENCES public.City(City_ID),
    Address_Line1 VARCHAR(50),
    Address_Line2 VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS public.Company (
    Company_ID SERIAL PRIMARY KEY,
    Company_Name VARCHAR(50),
    Company_Type_ID INT REFERENCES public.Company_Type(Company_Type_ID),
    Country_Code CHAR(2) REFERENCES public.Country(Country_Code)
);

CREATE TABLE IF NOT EXISTS public.Job (
    Job_ID SERIAL PRIMARY KEY,
    Company_ID INT REFERENCES public.Company(Company_ID),
    Position_ID INT REFERENCES public.Position(Position_ID),
    Description VARCHAR(1500),
    Posting_Date Date,
    Deadline_To_Apply TIMESTAMP,
    Job_Type_ID INT REFERENCES public.Job_Type(Job_Type_ID)
);

CREATE TABLE IF NOT EXISTS public.Candidate (
    Candidate_ID SERIAL PRIMARY KEY,
    Candidate_FName VARCHAR(50),
    Candidate_LName VARCHAR(50),
    Email VARCHAR(50) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    Location_ID INT REFERENCES public.Location(Location_ID)
);

CREATE TABLE IF NOT EXISTS public.Application (
    Application_ID SERIAL PRIMARY KEY,
    Candidate_ID INT REFERENCES public.Candidate(Candidate_ID),
    Job_ID INT REFERENCES public.Job(Job_ID),
    Date_Applied DATE CHECK (Date_Applied > '2000-01-01'),
    Status VARCHAR(10) CHECK (Status IN ('Applied', 'Rejected', 'Accepted', 'Pending', 'Withdrawn'))
);

CREATE TABLE IF NOT EXISTS public.Placement (
    Placement_ID SERIAL PRIMARY KEY,
    Application_ID INT REFERENCES public.Application(Application_ID),
    Date_Placed DATE,
    Salary_Offered DECIMAL(10, 2) CHECK (Salary_Offered >= 0),
    Duration INT CHECK (Duration >= 0),
    Status VARCHAR(9) CHECK (Status IN ('Placed', 'Dismissed')), 
    Contract_Type_ID INT REFERENCES public.Contract_Type(Contract_Type_ID)
);

CREATE TABLE IF NOT EXISTS public.Service_Skill (
    Service_Skill_ID SERIAL PRIMARY KEY,
    Service_ID INT REFERENCES public.Service(Service_ID),
    Skill_ID INT REFERENCES public.Skill(Skill_ID)
);

CREATE TABLE IF NOT EXISTS public.Candidate_Education (
    Education_ID SERIAL PRIMARY KEY,
    Candidate_ID INT REFERENCES public.Candidate(Candidate_ID),
    Institution VARCHAR(100),
    Degree VARCHAR(20),
    Graduation_Year DATE
);

CREATE TABLE IF NOT EXISTS public.Candidate_Experience (
    Experience_ID SERIAL PRIMARY KEY,
    Candidate_ID INT REFERENCES public.Candidate(Candidate_ID),
    Company_ID INT REFERENCES public.Company(Company_ID),
    Title VARCHAR(100),
    Description VARCHAR(500),
    Duration_In_Months INT
);

CREATE TABLE IF NOT EXISTS public.CandidateSkill (
    Candidate_ID INT,
    Skill_ID INT,
    Proficiency VARCHAR(30),
    PRIMARY KEY (Candidate_ID, Skill_ID),
    FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID),
    FOREIGN KEY (Skill_ID) REFERENCES public.Skill(Skill_ID)
);

CREATE TABLE IF NOT EXISTS public.Interview (
    Interview_ID SERIAL PRIMARY KEY,
    Application_ID INT REFERENCES public.Application(Application_ID),
    Recruiter_ID INT REFERENCES public.Recruiter(Recruiter_ID),
    Interview_Date DATE,
    Feedback VARCHAR(200),
    Pass CHAR(4) CHECK (Pass IN ('Pass', 'Fail'))
);

CREATE TABLE IF NOT EXISTS public.CandidateService (
    Candidate_Service_ID SERIAL PRIMARY KEY,
    Candidate_ID INT REFERENCES public.Candidate(Candidate_ID),
    Service_Skill_ID INT REFERENCES public.Service_Skill(Service_Skill_ID),
    Date_Used DATE
);

-- Add Relationships if not exists
ALTER TABLE public.Application DROP CONSTRAINT IF EXISTS FK_Candidate_Application;
ALTER TABLE public.Application DROP CONSTRAINT IF EXISTS FK_Job_Application;
ALTER TABLE public.Job DROP CONSTRAINT IF EXISTS FK_Company_Job;
ALTER TABLE public.Job DROP CONSTRAINT IF EXISTS FK_Position_Job;
ALTER TABLE public.Placement DROP CONSTRAINT IF EXISTS FK_Application_Placement;
ALTER TABLE public.Placement DROP CONSTRAINT IF EXISTS FK_ContractType_Placement;
ALTER TABLE public.Company DROP CONSTRAINT IF EXISTS FK_CompanyType_Company;
ALTER TABLE public.Company DROP CONSTRAINT IF EXISTS FK_Country_Company;
ALTER TABLE public.Location DROP CONSTRAINT IF EXISTS FK_City_Location;
ALTER TABLE public.Service_Skill DROP CONSTRAINT IF EXISTS FK_ServiceSkill_Service;
ALTER TABLE public.Service_Skill DROP CONSTRAINT IF EXISTS FK_ServiceSkill_Skill;
ALTER TABLE public.Candidate_Education DROP CONSTRAINT IF EXISTS FK_CandidateEducation_Candidate;
ALTER TABLE public.Candidate_Experience DROP CONSTRAINT IF EXISTS FK_CandidateExperience_Candidate;
ALTER TABLE public.Candidate_Experience DROP CONSTRAINT IF EXISTS FK_CandidateExperience_Company;
ALTER TABLE public.CandidateSkill DROP CONSTRAINT IF EXISTS FK_CandidateSkill_Candidate;
ALTER TABLE public.CandidateSkill DROP CONSTRAINT IF EXISTS FK_CandidateSkill_Skill;
ALTER TABLE public.Interview DROP CONSTRAINT IF EXISTS FK_Interview_Recruiter;
ALTER TABLE public.Interview DROP CONSTRAINT IF EXISTS FK_Interview_Application;
ALTER TABLE public.CandidateService DROP CONSTRAINT IF EXISTS FK_CandidateService_Candidate;
ALTER TABLE public.CandidateService DROP CONSTRAINT IF EXISTS FK_CandidateService_ServiceSkill;

ALTER TABLE IF EXISTS public.Application ADD CONSTRAINT FK_Candidate_Application FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID);
ALTER TABLE IF EXISTS public.Application ADD CONSTRAINT FK_Job_Application FOREIGN KEY (Job_ID) REFERENCES public.Job(Job_ID);

ALTER TABLE IF EXISTS public.Job ADD CONSTRAINT FK_Company_Job FOREIGN KEY (Company_ID) REFERENCES public.Company(Company_ID);
ALTER TABLE IF EXISTS public.Job ADD CONSTRAINT FK_Position_Job FOREIGN KEY (Position_ID) REFERENCES public.Position(Position_ID);

ALTER TABLE IF EXISTS public.Placement ADD CONSTRAINT FK_Application_Placement FOREIGN KEY (Application_ID) REFERENCES public.Application(Application_ID);
ALTER TABLE IF EXISTS public.Placement ADD CONSTRAINT FK_ContractType_Placement FOREIGN KEY (Contract_Type_ID) REFERENCES public.Contract_Type(Contract_Type_ID);

ALTER TABLE IF EXISTS public.Company ADD CONSTRAINT FK_CompanyType_Company FOREIGN KEY (Company_Type_ID) REFERENCES public.Company_Type(Company_Type_ID);
ALTER TABLE IF EXISTS public.Company ADD CONSTRAINT FK_Country_Company FOREIGN KEY (Country_Code) REFERENCES public.Country(Country_Code);

ALTER TABLE IF EXISTS public.Location ADD CONSTRAINT FK_City_Location FOREIGN KEY (City_ID) REFERENCES public.City(City_ID);

ALTER TABLE IF EXISTS public.Service_Skill ADD CONSTRAINT FK_ServiceSkill_Service FOREIGN KEY (Service_ID) REFERENCES public.Service(Service_ID);
ALTER TABLE IF EXISTS public.Service_Skill ADD CONSTRAINT FK_ServiceSkill_Skill FOREIGN KEY (Skill_ID) REFERENCES public.Skill(Skill_ID);

ALTER TABLE IF EXISTS public.Candidate_Education ADD CONSTRAINT FK_CandidateEducation_Candidate FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID);

ALTER TABLE IF EXISTS public.Candidate_Experience ADD CONSTRAINT FK_CandidateExperience_Candidate FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID);
ALTER TABLE IF EXISTS public.Candidate_Experience ADD CONSTRAINT FK_CandidateExperience_Company FOREIGN KEY (Company_ID) REFERENCES public.Company(Company_ID);

ALTER TABLE IF EXISTS public.CandidateSkill ADD CONSTRAINT FK_CandidateSkill_Candidate FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID);
ALTER TABLE IF EXISTS public.CandidateSkill ADD CONSTRAINT FK_CandidateSkill_Skill FOREIGN KEY (Skill_ID) REFERENCES public.Skill(Skill_ID);

ALTER TABLE IF EXISTS public.Interview ADD CONSTRAINT FK_Interview_Application FOREIGN KEY (Application_ID) REFERENCES public.Application(Application_ID);
ALTER TABLE IF EXISTS public.Interview ADD CONSTRAINT FK_Interview_Recruiter FOREIGN KEY (Recruiter_ID) REFERENCES public.Recruiter(Recruiter_ID);

ALTER TABLE IF EXISTS public.CandidateService ADD CONSTRAINT FK_CandidateService_Candidate FOREIGN KEY (Candidate_ID) REFERENCES public.Candidate(Candidate_ID);
ALTER TABLE IF EXISTS public.CandidateService ADD CONSTRAINT FK_CandidateService_ServiceSkill FOREIGN KEY (Service_Skill_ID) REFERENCES public.Service_Skill(Service_Skill_ID);

-- Apply Check Constraints
ALTER TABLE public.Application DROP CONSTRAINT IF EXISTS CHK_DateApplied;
ALTER TABLE public.Application ADD CONSTRAINT CHK_DateApplied CHECK (Date_Applied > '2000-01-01');

--Inserting sample data for every table
-- Contract_Type
INSERT INTO public.Contract_Type (Contract_Type_Name, Description)
SELECT * FROM (
    VALUES 
    ('Permanent', 'Permanent employment contracts'),
    ('Fixed-Term', 'Contracts for a specific duration')
) AS ct(Contract_Type_Name, Description)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Contract_Type c
    WHERE c.Contract_Type_Name = ct.Contract_Type_Name
);

-- Country
INSERT INTO public.Country (Country_Code, Country_Name)
SELECT * FROM (
    VALUES 
    ('US', 'United States'),
    ('UK', 'United Kingdom')
) AS co(Country_Code, Country_Name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Country c
    WHERE c.Country_Code = co.Country_Code
);

-- City
INSERT INTO public.City (City_Name, Country_Code)
SELECT * FROM (
    VALUES 
    ('San Francisco', 'US'),
    ('London', 'UK')
) AS ci(City_Name, Country_Code)
WHERE NOT EXISTS (
    SELECT 1 FROM public.City c
    WHERE c.City_Name = ci.City_Name AND c.Country_Code = ci.Country_Code
);

-- Company_Type
INSERT INTO public.Company_Type (Company_Type_Name, Description)
SELECT * FROM (
    VALUES 
    ('Technology', 'Technology companies specializing in software development.'),
    ('Marketing', 'Marketing and advertising agencies.')
) AS cty(Company_Type_Name, Description)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Company_Type c
    WHERE c.Company_Type_Name = cty.Company_Type_Name
);

-- Company
INSERT INTO public.Company (Company_Name, Company_Type_ID, Country_Code)
SELECT * FROM (
    VALUES 
    ('Tech Solutions Inc.', 1, 'US'),
    ('Marketing Innovations Ltd.', 2, 'UK')
) AS c(Company_Name, Company_Type_ID, Country_Code)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Company comp
    WHERE comp.Company_Name = c.Company_Name
);

-- Job_Type
INSERT INTO public.Job_Type (Job_Type_Name, Description)
SELECT * FROM (
    VALUES 
    ('Full-time', 'Regular full-time employment'),
    ('Contract', 'Short-term contract positions')
) AS jt(Job_Type_Name, Description)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Job_Type j
    WHERE j.Job_Type_Name = jt.Job_Type_Name
);

-- Position
INSERT INTO public.Position (Position_Name, Description, Salary)
SELECT * FROM (
    VALUES 
    ('Senior Software Engineer', 'Lead development projects', 100000.00),
    ('Digital Marketing Manager', 'Oversee digital marketing strategies', 90000.00)
) AS pos(Position_Name, Description, Salary)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Position p
    WHERE p.Position_Name = pos.Position_Name
);

-- Job
INSERT INTO public.Job (Company_ID, Position_ID, Description, Posting_Date, Deadline_To_Apply, Job_Type_ID)
SELECT * FROM (
    VALUES 
    (1, 1, 'Software Engineer', DATE '2023-01-15', TIMESTAMP '2023-02-15 13:51:51', 1),
    (2, 2, 'Marketing Manager', DATE '2023-02-01', TIMESTAMP '2023-03-01 20:13:46', 2)
) AS job(Company_ID, Position_ID, Description, Posting_Date, Deadline_To_Apply, Job_Type_ID)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Job j
    WHERE j.Company_ID = job.Company_ID AND j.Position_ID = job.Position_ID
);

-- Recruiter
INSERT INTO public.Recruiter (Recruiter_Name, Recruiter_Surname, Email, Phone)
SELECT * FROM (
    VALUES 
    ('Michael', 'Johnson', 'michael@example.com', '111-222-3333'),
    ('Emily', 'Wilson', 'emily@example.com', '444-555-6666')
) AS rec(Recruiter_Name, Recruiter_Surname, Email, Phone)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Recruiter r
    WHERE r.Email = rec.Email
);

-- Location
INSERT INTO public.Location (City_ID, Address_Line1, Address_Line2)
SELECT * FROM (
    VALUES 
    (1, '123 Main St', 'Suite 101'),
    (2, '456 Elm St', 'Floor 5')
) AS loc(City_ID, Address_Line1, Address_Line2)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Location l
    WHERE l.Address_Line1 = loc.Address_Line1 AND l.Address_Line2 = loc.Address_Line2
);

-- Candidate
INSERT INTO public.Candidate (Candidate_FName, Candidate_LName, Email, Phone, Location_ID) 
SELECT * FROM (
    VALUES 
    ('Alice', 'Johnson', 'alice@example.com', '123-456-7890', 1),
    ('Bob', 'Smith', 'bob@example.com', '987-654-3210', 2)
) AS cand(Candidate_FName, Candidate_LName, Email, Phone, Location_ID)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Candidate c
    WHERE c.Email = cand.Email
);

-- Candidate_Education
INSERT INTO public.Candidate_Education (Candidate_ID, Institution, Degree, Graduation_Year)
SELECT * FROM (
    VALUES 
    (1, 'ABC University', 'Bachelor', DATE '2022-05-30'),
    (2, 'XYZ College', 'Master', DATE '2023-06-15')
) AS ced(Candidate_ID, Institution, Degree, Graduation_Year)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Candidate_Education ce
    WHERE ce.Candidate_ID = ced.Candidate_ID AND ce.Institution = ced.Institution
);

-- Candidate_Experience
INSERT INTO public.Candidate_Experience (Candidate_ID, Company_ID, Title, Description, Duration_In_Months)
SELECT * FROM (
    VALUES 
    (1, 1, 'Software Developer', 'Developed scalable web applications', 36),
    (2, 2, 'Marketing Specialist', 'Managed social media campaigns', 24)
) AS cexp(Candidate_ID, Company_ID, Title, Description, Duration_In_Months)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Candidate_Experience ce
    WHERE ce.Candidate_ID = cexp.Candidate_ID AND ce.Company_ID = cexp.Company_ID AND ce.Title = cexp.Title
);

-- Service
INSERT INTO public.Service (Service_Name, Description, Cost)
SELECT * FROM (
    VALUES 
    ('Software Development', 'Custom software solutions', 500.00),
    ('Marketing Campaign', 'Full-scale marketing campaigns', 800.00)
) AS serv(Service_Name, Description, Cost)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Service s
    WHERE s.Service_Name = serv.Service_Name
);

-- Skill
INSERT INTO public.Skill (Skill_Name)
SELECT * FROM (
    VALUES 
    ('Java Programming'),
    ('Social Media Marketing')
) AS sk(Skill_Name)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Skill s
    WHERE s.Skill_Name = sk.Skill_Name
);

-- Service_Skill
INSERT INTO public.Service_Skill (Service_ID, Skill_ID)
SELECT * FROM (
    VALUES 
    (1, 1),
    (2, 2)
) AS ss(Service_ID, Skill_ID)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Service_Skill ss
    WHERE ss.Service_ID = ss.Service_ID AND ss.Skill_ID = ss.Skill_ID
);

-- CandidateSkill
INSERT INTO public.CandidateSkill (Candidate_ID, Skill_ID, Proficiency)
SELECT * FROM (
    VALUES 
    (1, 1, 'Advanced'),
    (2, 2, 'Intermediate')
) AS cs(Candidate_ID, Skill_ID, Proficiency)
WHERE NOT EXISTS (
    SELECT 1 FROM public.CandidateSkill csk
    WHERE csk.Candidate_ID = cs.Candidate_ID AND csk.Skill_ID = cs.Skill_ID
);

-- CandidateService
INSERT INTO public.CandidateService (Candidate_ID, Service_Skill_ID, Date_Used)
SELECT * FROM (
    VALUES 
    (1, 1, DATE '2023-02-20'),
    (2, 2, DATE '2023-03-10')
) AS cserv(Candidate_ID, Service_Skill_ID, Date_Used)
WHERE NOT EXISTS (
    SELECT 1 FROM public.CandidateService cser
    WHERE cser.Candidate_ID = cserv.Candidate_ID AND cser.Service_Skill_ID = cserv.Service_Skill_ID
);

-- Application
INSERT INTO public.Application (Candidate_ID, Job_ID, Date_Applied, Status)
SELECT * FROM (
    VALUES 
    (1, 1, DATE '2023-01-15', 'Applied'),
    (2, 2, DATE '2023-02-20', 'Pending')
) AS app(Candidate_ID, Job_ID, Date_Applied, Status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Application a
    WHERE a.Candidate_ID = app.Candidate_ID AND a.Job_ID = app.Job_ID
);

-- Interview
INSERT INTO public.Interview (Application_ID, Recruiter_ID, Interview_Date, Feedback, Pass)
SELECT * FROM (
    VALUES 
    (1, 1, DATE '2023-02-10', 'Impressive technical skills', 'Pass'),
    (2, 2, DATE '2023-03-05', 'Great communication abilities', 'Fail')
) AS intrw(Application_ID, Recruiter_ID, Interview_Date, Feedback, Pass)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Interview i
    WHERE i.Application_ID = intrw.Application_ID AND i.Recruiter_ID = intrw.Recruiter_ID
);

-- Placement
INSERT INTO public.Placement (Application_ID, Date_Placed, Salary_Offered, Duration, Status, Contract_Type_ID)
SELECT * FROM (
    VALUES 
    (1, DATE '2023-01-20', 75000.00, 12, 'Placed', 1),
    (2, DATE '2023-02-25', 80000.00, 24, 'Dismissed', 2)
) AS pl(Application_ID, Date_Placed, Salary_Offered, Duration, Status, Contract_Type_ID)
WHERE NOT EXISTS (
    SELECT 1 FROM public.Placement p
    WHERE p.Application_ID = pl.Application_ID
);

-- Add 'record_ts' field using ALTER TABLE for every table if it doesn't exist
ALTER TABLE IF EXISTS public.Candidate
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Application
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Job
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Placement
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Company
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Location
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.City
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Service_Skill
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Candidate_Education
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Candidate_Experience
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Skill
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.CandidateSkill
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Recruiter
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Interview
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Service
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.CandidateService
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Company_Type
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Position
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Country
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Job_Type
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;

ALTER TABLE IF EXISTS public.Contract_Type
ADD COLUMN IF NOT EXISTS record_ts TIMESTAMP DEFAULT current_timestamp NOT NULL;