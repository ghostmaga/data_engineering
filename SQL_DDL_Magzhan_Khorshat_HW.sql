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
    Posting_Date TIMESTAMP,
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