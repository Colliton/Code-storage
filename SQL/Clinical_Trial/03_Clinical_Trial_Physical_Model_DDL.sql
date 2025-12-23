/*
DDL script for clinical_trial DB
Rerunnable: drops and recreates schema `clinical` to ensure a clean state.
*/

/*
OPTIONAL (separate file recommended):
Create or recreate database `clinical_trial`
- cannot be safely executed from inside the target DB in many clients
*/

-- DROP DATABASE IF EXISTS clinical_trial;
-- CREATE DATABASE clinical_trial;


-- SCHEMA


DROP SCHEMA IF EXISTS clinical CASCADE;
CREATE SCHEMA clinical;


-- TABLES


/*
Table: clinical.studies
Rules:
- study_code unique
- end_date >= start_date (if end_date provided)
- study_phase limited to I–V
- study_status controlled vocabulary
*/

CREATE TABLE IF NOT EXISTS clinical.studies (
    study_id    	INT 			GENERATED ALWAYS AS IDENTITY,
    study_code  	VARCHAR(20) 	NOT NULL,
    study_title		VARCHAR(100)	NOT NULL,
    study_phase		VARCHAR(3)		NOT NULL,
    start_date		DATE 			NOT NULL DEFAULT CURRENT_DATE,
    end_date		DATE,
    study_status	VARCHAR(20)		NOT NULL DEFAULT 'Planned',
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_studies_study_id
    	PRIMARY KEY (study_id),
    CONSTRAINT UQ_studies_study_code
        UNIQUE (study_code),
    CONSTRAINT CK_studies_study_phase
    	CHECK (study_phase IN ('I', 'II', 'III', 'IV', 'V')),
    CONSTRAINT CK_studies_study_end_date
    	CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT CK_studies_study_status
    	CHECK (study_status IN ('Planned', 'Ongoing', 'Closed', 'Suspended'))
);

/*
Optional cleanup snippet for 'studies':
DROP TABLE IF EXISTS clinical.studies CASCADE;
*/

/*
Table: clinical.addresses
Rules:
- Primary key: address_id
- Required fields: street_name, building_no, city_name, postal_code, country
- Optional field: flat_no (can be NULL)
- Address uniqueness is enforced via a UNIQUE INDEX:
  (street_name, building_no, flat_no, city_name, postal_code, country)
  where NULL flat_no is treated as an empty value
*/

CREATE TABLE IF NOT EXISTS clinical.addresses (
    address_id    	INT 			GENERATED ALWAYS AS IDENTITY,
    street_name  	VARCHAR(100) 	NOT NULL,
    building_no		VARCHAR(10)		NOT NULL,
    flat_no			VARCHAR(10),
    city_name		VARCHAR(50) 	NOT NULL,
    postal_code		VARCHAR(10)		NOT NULL,
    country			VARCHAR(20)		NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_addresses_address_id
    	PRIMARY KEY (address_id)
);

-- Enforce address uniqueness (NULL flat_no treated as no flat)
CREATE UNIQUE INDEX UQ_addresses_uniqueness
ON clinical.addresses (
    street_name,
    building_no,
    COALESCE(flat_no, ''),
    city_name,
    postal_code,
    country
);

/*
Optional cleanup snippet for 'addresses':
DROP TABLE IF EXISTS clinical.addresses CASCADE;
*/

/*
Table: clinical.units
Rules:
- Primary key: unit_id
- unit_code is required and unique
- unit_name is required
*/

CREATE TABLE IF NOT EXISTS clinical.units (
    unit_id    		INT 			GENERATED ALWAYS AS IDENTITY,
    unit_code  		VARCHAR(10) 	NOT NULL,
    unit_name		VARCHAR(30)		NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_units_unit_id
    	PRIMARY KEY (unit_id),
    CONSTRAINT UQ_units_unit_code
    	UNIQUE (unit_code)
);


/*
Optional cleanup snippet for 'units':
DROP TABLE IF EXISTS clinical.units CASCADE;
*/

/*
Table: clinical.sites
Rules:
- Primary key: site_id
- Each site must have an address (address_id NOT NULL, FK -> clinical.addresses.address_id)
- site_name, site_phone, site_email are required
- Phone format is validated with a regex CHECK (digits required; allowed characters: digits, '+', space; length 7–20)
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.sites (
    site_id    		INT 			GENERATED ALWAYS AS IDENTITY,
    address_id  	INT			 	NOT NULL,
    site_name		VARCHAR(100)	NOT NULL,
    site_phone		VARCHAR(25)		NOT NULL,
    site_email		VARCHAR(100)	NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_sites_site_id
    	PRIMARY KEY (site_id),
    CONSTRAINT FK_sites_addresses_address_id
        FOREIGN KEY (address_id)
        REFERENCES clinical.addresses(address_id),
    CONSTRAINT CK_sites_site_phone
    	CHECK (site_phone ~ '^(?=.*\d)[0-9+ ]{7,20}$')
);

/*
Optional cleanup snippet for 'sites':
DROP TABLE IF EXISTS clinical.sites CASCADE;
*/

/*
Table: clinical.investigators
Rules:
- Primary key: investigator_id
- Each investigator must have an address (address_id NOT NULL, FK -> clinical.addresses.address_id)
- investigator_first_name and investigator_last_name are required
- investigator_email is required and must be unique
- investigator_phone is optional; if provided, it must match the phone regex format
- institution and additional_info are optional
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.investigators (
	investigator_id 		INT 			GENERATED ALWAYS AS IDENTITY,
    address_id  			INT				NOT NULL,
    investigator_first_name	VARCHAR(50)		NOT NULL,
    investigator_last_name	VARCHAR(50)		NOT NULL,
    investigator_phone		VARCHAR(25),
    investigator_email		VARCHAR(100) 	NOT NULL,
    institution				VARCHAR(100),
    additional_info			VARCHAR(250),
    created_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_investigators_investigator_id
    	PRIMARY KEY (investigator_id),
    CONSTRAINT FK_investigators_addresses_address_id
        FOREIGN KEY (address_id)
        REFERENCES clinical.addresses(address_id),
    CONSTRAINT CK_investigators_investigator_phone
    	CHECK (	investigator_phone IS NULL 
    			OR investigator_phone~ '^(?=.*\d)[0-9+ ]{7,20}$'),
    CONSTRAINT UQ_investigators_investigator_email
    	UNIQUE (investigator_email)
);

/*
Optional cleanup snippet for 'investigators':
DROP TABLE IF EXISTS clinical.investigators CASCADE;
*/

/*
Table: clinical.measurement_types
Rules:
- Primary key: measurement_type_id
- Each measurement type must reference a unit (unit_id NOT NULL, FK -> clinical.units.unit_id)
- measurement_code is required and unique
- measurement_name is required
- value_type is required and restricted to: NUMERIC, TEXT, BOOLEAN
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.measurement_types (
	measurement_type_id 	INT 			GENERATED ALWAYS AS IDENTITY,
    unit_id  				INT				NOT NULL,
    measurement_code		VARCHAR(20)		NOT NULL,
    measurement_name		VARCHAR(50)		NOT NULL,
    value_type				VARCHAR(10)		NOT NULL,
    created_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_measurement_types_measurement_type_id
    	PRIMARY KEY (measurement_type_id),
    CONSTRAINT FK_measurement_types_units_unit_id
        FOREIGN KEY (unit_id)
        REFERENCES clinical.units(unit_id),
    CONSTRAINT UQ_measurement_types_measurement_code
    	UNIQUE (measurement_code),
    CONSTRAINT CK_measurement_types_value_type
    	CHECK (value_type IN ('NUMERIC', 'TEXT', 'BOOLEAN'))
);

/*
Optional cleanup snippet for 'measurement_types':
DROP TABLE IF EXISTS clinical.measurement_types CASCADE;
*/

/*
Table: clinical.study_sites
Rules:
- Primary key: study_site_id
- Each record links a study to a site:
  - study_id NOT NULL (FK -> clinical.studies.study_id)
  - site_id  NOT NULL (FK -> clinical.sites.site_id)
- PI_id is optional (FK -> clinical.investigators.investigator_id)
- site_code is required
- Uniqueness rules:
  - (study_id, site_id) must be unique
  - (study_id, site_code) must be unique
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.study_sites (
	study_site_id 	INT 			GENERATED ALWAYS AS IDENTITY,
    study_id  		INT				NOT NULL,
    site_id			INT				NOT NULL,
    PI_id			INT,
    site_code		VARCHAR(20)		NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_study_sites_study_site_id
    	PRIMARY KEY (study_site_id),
    CONSTRAINT FK_study_sites_studies_study_id
        FOREIGN KEY (study_id)
        REFERENCES clinical.studies(study_id),
    CONSTRAINT FK_study_sites_sites_site_id
        FOREIGN KEY (site_id)
        REFERENCES clinical.sites(site_id),
    CONSTRAINT FK_study_sites_investigators_PI_id
        FOREIGN KEY (PI_id)
        REFERENCES clinical.investigators(investigator_id),
    CONSTRAINT UQ_study_sites_ids_uniqueness
    	UNIQUE (study_id, site_id),
    CONSTRAINT UQ_study_sites_sites_uniqueness
    	UNIQUE (study_id, site_code)
);

/*
Optional cleanup snippet for 'study_sites':
DROP TABLE IF EXISTS clinical.study_sites CASCADE;
*/

/*
Table: clinical.treatment_arms
Rules:
- Primary key: arm_id
- Each treatment arm belongs to a study (study_id NOT NULL, FK -> clinical.studies.study_id)
- arm_code and arm_name are required
- arm_type is required and restricted to: Active, Placebo
- is_blinded is required (boolean)
- Uniqueness within a study:
  - (study_id, arm_code) must be unique
  - (study_id, arm_name) must be unique
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.treatment_arms (
	arm_id 			INT 			GENERATED ALWAYS AS IDENTITY,
    study_id  		INT				NOT NULL,
    arm_code		VARCHAR(5)		NOT NULL,
    arm_name		VARCHAR(50)		NOT NULL,
    arm_type		VARCHAR(10)		NOT NULL,
    is_blinded		BOOLEAN			NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_treatment_arms_arm_id
    	PRIMARY KEY (arm_id),
    CONSTRAINT FK_treatment_arms_studies_study_id
        FOREIGN KEY (study_id)
        REFERENCES clinical.studies(study_id),
    CONSTRAINT CK_treatment_arms_arm_type
    	CHECK (arm_type IN ('Active', 'Placebo')),
    CONSTRAINT UQ_treatment_arms_study_arm_code
    	UNIQUE (study_id, arm_code),
    CONSTRAINT UQ_treatment_arms_study_arm_name
    	UNIQUE (study_id, arm_name)
);

/*
Optional cleanup snippet for 'treatment_arms':
DROP TABLE IF EXISTS clinical.treatment_arms CASCADE;
*/

/*
Table: clinical.subjects
Rules:
- Primary key: subject_id
- Each subject belongs to a specific study site (study_site_id NOT NULL, FK -> clinical.study_sites.study_site_id)
- subject_code is required
- screening_date is required
- enrollment_date is optional, but if provided it must be >= screening_date
- status is required and restricted to: Screened, Enrolled, Randomized, Withdrawn, Completed
- Status/enrollment consistency:
  - if status = 'Screened' then enrollment_date must be NULL
  - if status in ('Enrolled','Randomized','Withdrawn','Completed') then enrollment_date must be NOT NULL
- Uniqueness: (study_site_id, subject_code) must be unique
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.subjects (
	subject_id 		INT 			GENERATED ALWAYS AS IDENTITY,
    study_site_id  	INT				NOT NULL,
    subject_code	VARCHAR(20)		NOT NULL,
    screening_date	DATE			NOT NULL,
    enrollment_date	DATE,
    status			VARCHAR(20)		NOT NULL,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_subjects_subject_id
    	PRIMARY KEY (subject_id),
    CONSTRAINT FK_subjects_study_sites_study_site_id
        FOREIGN KEY (study_site_id)
        REFERENCES clinical.study_sites(study_site_id),
    CONSTRAINT CK_subjects_screening_date
    	CHECK (enrollment_date IS NULL 
    	       OR enrollment_date >= screening_date),
    CONSTRAINT CK_subjects_status
    	CHECK (status IN ('Screened', 'Enrolled', 'Randomized', 'Withdrawn', 'Completed')),
    CONSTRAINT CK_subjects_status_enrollment_date
    	CHECK ((status = 'Screened' AND enrollment_date IS NULL) 
    	    OR (status IN ('Enrolled','Randomized','Withdrawn','Completed') AND enrollment_date IS NOT NULL)),
    CONSTRAINT UQ_subjects_uniqueness
    	UNIQUE (study_site_id, subject_code)
);

/*
Optional cleanup snippet for 'subjects':
DROP TABLE IF EXISTS clinical.subjects CASCADE;
*/

/*
Table: clinical.randomization
Rules:
- Primary key: randomization_id
- Each randomization belongs to exactly one subject:
  - subject_id NOT NULL (FK -> clinical.subjects.subject_id)
  - subject_id is unique (one randomization per subject)
- Each randomization assigns a subject to a treatment arm:
  - arm_id NOT NULL (FK -> clinical.treatment_arms.arm_id)
- randomized_at is required (timestamp of randomization)
- randomization_method is required and restricted to: Simple, Block, Stratified
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.randomization (
	randomization_id 		INT 			GENERATED ALWAYS AS IDENTITY,
    subject_id  			INT				NOT NULL,
    arm_id					INT				NOT NULL,
    randomized_at			TIMESTAMPTZ		NOT NULL,
    randomization_method	VARCHAR(30)		NOT NULL,
    created_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at				TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_randomization_randomization_id
    	PRIMARY KEY (randomization_id),
    CONSTRAINT FK_randomization_subjects_subject_id
        FOREIGN KEY (subject_id)
        REFERENCES clinical.subjects(subject_id),
    CONSTRAINT FK_randomization_treatment_arms_arm_id
    	FOREIGN KEY (arm_id)
    	REFERENCES clinical.treatment_arms(arm_id),
    CONSTRAINT UQ_randomization_subject_id
    	UNIQUE (subject_id),
    CONSTRAINT CK_randomization_randomization_method
    	CHECK (randomization_method IN ('Simple', 'Block', 'Stratified'))
);

/*
Optional cleanup snippet for 'randomization':
DROP TABLE IF EXISTS clinical.randomization CASCADE;
*/

/*
Table: clinical.visits
Rules:
- Primary key: visit_id
- Each visit belongs to a subject (subject_id NOT NULL, FK -> clinical.subjects.subject_id)
- visit_no is required and must be >= 0
- visit_type is required and restricted to: Screening, Baseline, Week4, Week8, EOT
- visit_date is required
- visit_status is required and restricted to: Planned, Completed, Missed, Cancelled
- is_locked is required and defaults to FALSE
- Uniqueness within a subject:
  - (subject_id, visit_no) must be unique
  - (subject_id, visit_type) must be unique
- created_at and updated_at default to current timestamp
*/

CREATE TABLE IF NOT EXISTS clinical.visits (
	visit_id 		INT 			GENERATED ALWAYS AS IDENTITY,
    subject_id  	INT				NOT NULL,
    visit_no		INT				NOT NULL,
    visit_type		VARCHAR(20)		NOT NULL,
    visit_date		TIMESTAMP		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    visit_status	VARCHAR(30)		NOT NULL DEFAULT 'Planned',
    is_locked		BOOLEAN			NOT NULL DEFAULT FALSE,
    created_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at		TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_visits_visit_id
    	PRIMARY KEY (visit_id),
    CONSTRAINT FK_visits_subjects_subject_id
        FOREIGN KEY (subject_id)
        REFERENCES clinical.subjects(subject_id),
    CONSTRAINT CK_visits_visit_no
    	CHECK (visit_no >= 0),
    CONSTRAINT CK_visits_visit_type
    	CHECK (visit_type IN ('Screening', 'Baseline', 'Week4', 'Week8', 'EOT')),
    CONSTRAINT CK_visits_visit_status
    	CHECK (visit_status IN ('Planned', 'Completed', 'Missed', 'Cancelled')),
	CONSTRAINT UQ_visits_subject_visit_no
		UNIQUE (subject_id, visit_no),
	CONSTRAINT UQ_visits_subject_visit_type
		UNIQUE (subject_id, visit_type)
);

/*
Optional cleanup snippet for 'visits':
DROP TABLE IF EXISTS clinical.visits CASCADE;
*/

/*
Table: clinical.measurements
Rules:
- Primary key: measurement_id
- Each measurement belongs to a visit (visit_id NOT NULL, FK -> clinical.visits.visit_id)
- Each measurement has a defined type (measurement_type_id NOT NULL, FK -> clinical.measurement_types.measurement_type_id)
- For a given visit and measurement type, only one measurement is allowed
  (UNIQUE: visit_id, measurement_type_id)
- Exactly one value column must be provided:
  - value_numeric OR value_text OR value_boolean
- created_at and updated_at default to current timestamp
*/


CREATE TABLE IF NOT EXISTS clinical.measurements (
	measurement_id 		INT 			GENERATED ALWAYS AS IDENTITY,
    visit_id  			INT				NOT NULL,
    measurement_type_id	INT				NOT NULL,
    value_numeric		DECIMAL(12, 3),
    value_text			VARCHAR(100),
    value_boolean		BOOLEAN,
    created_at			TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at			TIMESTAMPTZ		NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_measurements_measurement_id
    	PRIMARY KEY (measurement_id),
    CONSTRAINT FK_measurements_visits_visit_id
        FOREIGN KEY (visit_id)
        REFERENCES clinical.visits(visit_id),
    CONSTRAINT FK_measurements_measurement_types_measurement_type_id
        FOREIGN KEY (measurement_type_id)
        REFERENCES clinical.measurement_types(measurement_type_id),
    CONSTRAINT UQ_measurements_visit_measurement_type
    	UNIQUE (visit_id, measurement_type_id),
    CONSTRAINT CK_measurements_one_value
    	CHECK ( 
    		((value_numeric IS NOT NULL)::int +
  			(value_text    IS NOT NULL)::int +
  			(value_boolean IS NOT NULL)::int) 
  			= 1)
);

/*
Optional cleanup snippet for 'measurements':
DROP TABLE IF EXISTS clinical.measurements CASCADE;
*/


/*
Post-DDL CHECK constraints

The following CHECK constraints are added using ALTER TABLE to demonstrate
additional validation rules applied at the business logic level, beyond the
structural rules already defined during the initial CREATE TABLE statements.

Core integrity constraints (PK, FK, NOT NULL, UNIQUE, and domain CHECK rules)
were defined in CREATE TABLE based on the logical ER model.
*/

-- Email format validation (sites, investigators)

-- Rerunnable cleanup (optional but recommended)
ALTER TABLE clinical.sites
    DROP CONSTRAINT IF EXISTS CK_sites_site_email;

ALTER TABLE clinical.investigators
    DROP CONSTRAINT IF EXISTS CK_investigators_investigator_email;

-- Add business-rule CHECK constraints
ALTER TABLE clinical.sites
ADD CONSTRAINT CK_sites_site_email
CHECK (site_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$');

ALTER TABLE clinical.investigators
ADD CONSTRAINT CK_investigators_investigator_email
CHECK (investigator_email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$');

