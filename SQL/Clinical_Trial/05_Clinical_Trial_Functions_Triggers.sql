/*
Purpose:
- Database logic layer for the Clinical Trial project
- Defines reusable functions, triggers, and analytical views

Execution order:
- Run after:
  03_Clinical_Trial_Physical_Model_DDL.sql
  04_Clinical_Trial_Inserts.sql

Rerunnable:
- Functions are created with CREATE OR REPLACE
- Triggers are dropped and recreated
- Views are created with CREATE OR REPLACE
*/

-- ============================================================
-- Function: set_updated_at
-- Purpose: automatically update updated_at column on row update
-- ============================================================

CREATE OR REPLACE FUNCTION clinical.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ============================================================
-- Triggers: updated_at
-- ============================================================

-- Table: clinical.studies
DROP TRIGGER IF EXISTS trg_studies_set_updated_at ON clinical.studies;

CREATE TRIGGER trg_studies_set_updated_at
BEFORE UPDATE ON clinical.studies
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.addresses
DROP TRIGGER IF EXISTS trg_addresses_set_updated_at ON clinical.addresses;

CREATE TRIGGER trg_addresses_set_updated_at
BEFORE UPDATE ON clinical.addresses
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.sites
DROP TRIGGER IF EXISTS trg_sites_set_updated_at ON clinical.sites;

CREATE TRIGGER trg_sites_set_updated_at
BEFORE UPDATE ON clinical.sites
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.investigators
DROP TRIGGER IF EXISTS trg_investigators_set_updated_at ON clinical.investigators;

CREATE TRIGGER trg_investigators_set_updated_at
BEFORE UPDATE ON clinical.investigators
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.study_sites
DROP TRIGGER IF EXISTS trg_study_sites_set_updated_at ON clinical.study_sites;

CREATE TRIGGER trg_study_sites_set_updated_at
BEFORE UPDATE ON clinical.study_sites
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.subjects
DROP TRIGGER IF EXISTS trg_subjects_set_updated_at ON clinical.subjects;

CREATE TRIGGER trg_subjects_set_updated_at
BEFORE UPDATE ON clinical.subjects
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.visits
DROP TRIGGER IF EXISTS trg_visits_set_updated_at ON clinical.visits;

CREATE TRIGGER trg_visits_set_updated_at
BEFORE UPDATE ON clinical.visits
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.measurements
DROP TRIGGER IF EXISTS trg_measurements_set_updated_at ON clinical.measurements;

CREATE TRIGGER trg_measurements_set_updated_at
BEFORE UPDATE ON clinical.measurements
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.randomization
DROP TRIGGER IF EXISTS trg_randomization_set_updated_at ON clinical.randomization;

CREATE TRIGGER trg_randomization_set_updated_at
BEFORE UPDATE ON clinical.randomization
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.treatment_arms
DROP TRIGGER IF EXISTS trg_treatment_arms_set_updated_at ON clinical.treatment_arms;

CREATE TRIGGER trg_treatment_arms_set_updated_at
BEFORE UPDATE ON clinical.treatment_arms
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.measurement_types
DROP TRIGGER IF EXISTS trg_measurement_types_set_updated_at ON clinical.measurement_types;

CREATE TRIGGER trg_measurement_types_set_updated_at
BEFORE UPDATE ON clinical.measurement_types
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();

-- Table: clinical.units
DROP TRIGGER IF EXISTS trg_units_set_updated_at ON clinical.units;

CREATE TRIGGER trg_units_set_updated_at
BEFORE UPDATE ON clinical.units
FOR EACH ROW
EXECUTE FUNCTION clinical.set_updated_at();


/*
Function: visit_status_info

Purpose:
- Returns a human-readable description of a visit status
  for a given subject and visit number.
- Validates whether the specified visit exists before processing.

Parameters:
- p_subject_id (INT)  : Identifier of the subject.
- p_visit_no   (INT)  : Visit number within the subject context.

Behavior:
- Raises an exception if the visit does not exist for the given subject.
- Emits a NOTICE with contextual information about the visit.
- Returns a descriptive text based on the visit_status value.

Notes:
- visit_no is not globally unique and is evaluated together with subject_id.
- Status comparison is case-insensitive and trimmed for robustness.

Usage example:
- SELECT visit_status_info(1, 0);
*/

CREATE OR REPLACE FUNCTION visit_status_info (
IN p_subject_id INT,
IN p_visit_no INT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
	v_visit_status TEXT;
BEGIN
	IF NOT EXISTS (
        SELECT 1
        FROM clinical.visits
        WHERE visit_no = p_visit_no
          AND subject_id = p_subject_id
    ) THEN
        RAISE EXCEPTION 'Visit number % for subject_id % does not exist',
    	p_visit_no, p_subject_id;
    END IF;

	SELECT visit_status
	INTO v_visit_status
	FROM clinical.visits
	WHERE visit_no = p_visit_no
	  AND subject_id = p_subject_id;
	
	IF UPPER(TRIM(v_visit_status)) = 'PLANNED' THEN
		RAISE NOTICE 'Visit % is scheduled', p_visit_no;
		RETURN 'Visit scheduled';
	
	ELSIF UPPER(TRIM(v_visit_status)) = 'COMPLETED' THEN
		RAISE NOTICE 'Visit % was completed successfully', p_visit_no;
		RETURN 'Visit completed successfully';
	
	ELSIF UPPER(TRIM(v_visit_status)) = 'MISSED' THEN
		RAISE NOTICE 'Visit % was missed', p_visit_no;
		RETURN 'Visit missed';
	
	ELSE 
		RAISE NOTICE 'Visit % was cancelled', p_visit_no;
		RETURN 'Visit cancelled';
	END IF;
END;
$$;

/*
Function: subjects_per_study

Purpose:
- Returns the total number of subjects enrolled in a given study.
- Validates the input study code and ensures the study exists before processing.

Parameters:
- p_study_code (TEXT) : Code identifying the study (case-insensitive).

Behavior:
- Raises an exception if the study code is NULL or empty.
- Raises an exception if no study with the given code exists.
- Counts subjects across all study sites associated with the study.
- Emits a NOTICE with the resulting subject count.

Notes:
- Study code comparison is performed using UPPER(TRIM()) for robustness.
- Subject count is aggregated across all sites belonging to the study.

Usage example:
- SELECT subjects_per_study('CT-001');
*/

CREATE OR REPLACE FUNCTION subjects_per_study (
IN p_study_code TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$ 
DECLARE
	v_subject_count INT;
BEGIN
	IF p_study_code IS NULL OR TRIM(p_study_code) = '' THEN
        RAISE EXCEPTION 'Study code cannot be empty';
    END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM clinical.studies st 
		WHERE UPPER(TRIM(st.study_code)) = UPPER(TRIM(p_study_code))
	) THEN
		RAISE EXCEPTION 'Study with code "%" does not exist', p_study_code;
	END IF;
	
	SELECT COUNT(subject_id)
	INTO v_subject_count
	FROM clinical.subjects sub
	JOIN clinical.study_sites stus
	  ON sub.study_site_id = stus.study_site_id
	JOIN clinical.studies st 
	  ON stus.study_id = st.study_id
	WHERE UPPER(TRIM(st.study_code)) = UPPER(TRIM(p_study_code));
	
	RAISE NOTICE 'Study % contains % subjects', p_study_code, v_subject_count;
	RETURN v_subject_count;
END;
$$;

/*
Function: subject_ready_to_randomization

Purpose:
- Checks whether a subject is eligible for randomization.

Parameters:
- p_subject_id (INT) : Identifier of the subject.

Behavior:
- Raises an exception if p_subject_id is NULL.
- Raises an exception if the subject does not exist.
- Returns TRUE only when:
  - the subject has status = 'Enrolled' (case-insensitive), and
  - the subject does not already have a record in clinical.randomization.
- Returns FALSE otherwise.
- Emits a NOTICE when the subject is eligible for randomization.

Notes:
- Randomization is treated as a one-time event per subject (enforced by UNIQUE(subject_id) in clinical.randomization).
- Status comparison uses UPPER(TRIM()) for robustness.

Usage example:
- SELECT subject_ready_to_randomization(123);
*/

CREATE OR REPLACE FUNCTION subject_ready_to_randomization (
IN p_subject_id INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$ 
DECLARE
	v_status_check TEXT;
BEGIN
	IF p_subject_id IS NULL THEN 
		RAISE EXCEPTION 'Subject id cannot be NULL';
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM clinical.subjects sub
		WHERE sub.subject_id = p_subject_id
	) THEN
		RAISE EXCEPTION 'Subject with id % does not exist', p_subject_id;
	END IF;
	
	SELECT sub.status
	INTO v_status_check
	FROM clinical.subjects sub
	LEFT JOIN clinical.randomization rand
	  ON sub.subject_id = rand.subject_id
	WHERE sub.subject_id = p_subject_id
	  AND rand.randomization_id IS NULL;
	
	IF v_status_check IS NULL THEN
		RETURN FALSE;

	ELSIF UPPER(TRIM(v_status_check)) = 'ENROLLED' THEN
		RAISE NOTICE 'Subject with id % ready for randomization!', p_subject_id;
		RETURN TRUE;
		
	ELSE
		RETURN FALSE;
	END IF;
END;
$$;

/*
Function: subject_visits

Purpose:
- Returns a list of visits for a given subject.

Parameters:
- p_subject_code (TEXT) : Code identifying the subject (case-insensitive).

Returns:
- visit_no      (INT)
- visit_type    (VARCHAR)
- visit_date    (TIMESTAMP)
- visit_status  (VARCHAR)
- is_locked     (BOOLEAN)

Behavior:
- Raises an exception if the subject code is NULL or empty.
- Raises an exception if no subject with the given code exists.
- Returns all visits associated with the subject.

Notes:
- Subject code comparison is performed using UPPER(TRIM()) for robustness.
- Implemented as a set-returning function using RETURN QUERY.

Usage example:
- SELECT * FROM subject_visits('SUBJ-001');
*/

CREATE OR REPLACE FUNCTION subject_visits (
IN p_subject_code TEXT
)
RETURNS TABLE ( 
	visit_no		INT,
	visit_type 		VARCHAR(20),
	visit_date		TIMESTAMP,
	visit_status	VARCHAR(30),
	is_locked		BOOLEAN

)
LANGUAGE plpgsql
AS $$
BEGIN
	IF p_subject_code IS NULL OR TRIM(p_subject_code) = '' THEN
		RAISE EXCEPTION 'Subject code cannot be empty';
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM clinical.subjects sub
		WHERE UPPER(TRIM(sub.subject_code)) = UPPER(TRIM(p_subject_code))
	) THEN
		RAISE EXCEPTION 'Subject with code "%" does not exist', p_subject_code;
	END IF;
	
RETURN QUERY
SELECT 
	vis.visit_no,
	vis.visit_type,
	vis.visit_date,
	vis.visit_status,
	vis.is_locked
FROM clinical.visits vis
JOIN clinical.subjects sub
  ON vis.subject_id = sub.subject_id
WHERE UPPER(TRIM(sub.subject_code)) = UPPER(TRIM(p_subject_code));

END;
$$;

/*
Function: study_metrics

Purpose:
- Provides aggregated study-level metrics for a given study.

Parameters:
- p_study_code (TEXT) : Code identifying the study (case-insensitive).

Returns:
- subject_count    (INT) : Total number of subjects in the study.
- randomized_count (INT) : Number of subjects with an assigned randomization.
- completed_count  (INT) : Number of subjects with status 'Completed'.

Behavior:
- Raises an exception if the study code is NULL or empty.
- Raises an exception if no study with the given code exists.
- Aggregates metrics across all study sites belonging to the study.
- Uses DISTINCT counts to avoid duplication caused by joins.

Notes:
- Randomized subjects are identified via clinical.randomization rather than subject status.
- Status comparison is performed using UPPER(TRIM()) for robustness.
- Implemented as a single aggregated query for consistency and performance.

Usage example:
- SELECT * FROM study_metrics('CT-001');
*/

CREATE OR REPLACE FUNCTION study_metrics (
IN p_study_code TEXT
)
RETURNS TABLE (
	subject_count INT,
	randomized_count INT,
	completed_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
	IF p_study_code IS NULL OR TRIM(p_study_code) = '' THEN
		RAISE EXCEPTION 'Study code cannot be empty';
	END IF;

	IF NOT EXISTS (
		SELECT 1
		FROM clinical.studies st
		WHERE UPPER(TRIM(st.study_code)) = UPPER(TRIM(p_study_code))
	) THEN
		RAISE EXCEPTION 'Study with code "%" does not exist', p_study_code;
	END IF;
	
	  RETURN QUERY
    SELECT
        COUNT(DISTINCT sub.subject_id)::INT AS subject_count,
        COUNT(DISTINCT rand.subject_id)::INT AS randomized_count,
        COUNT(DISTINCT sub.subject_id) FILTER (WHERE UPPER(TRIM(sub.status)) = 'COMPLETED')::INT AS completed_count
    FROM clinical.studies st
    JOIN clinical.study_sites sts
      ON sts.study_id = st.study_id
    JOIN clinical.subjects sub
      ON sub.study_site_id = sts.study_site_id
    LEFT JOIN clinical.randomization rand
      ON rand.subject_id = sub.subject_id
    WHERE UPPER(TRIM(st.study_code)) = UPPER(TRIM(p_study_code));	
END;
$$;

/*
Function: update_subject_status

Purpose:
- Updates a subject's status in a controlled way (business-rule guard).
- Prevents invalid status transitions using an explicit transition matrix.

Parameters:
- p_subject_id  (INT)  : Identifier of the subject.
- p_new_status  (TEXT) : Target status (case-insensitive).

Returns:
- BOOLEAN:
  - TRUE  -> status updated
  - FALSE -> no change (new status equals current status)

Behavior:
- Raises an exception when:
  - inputs are NULL/empty,
  - subject does not exist,
  - p_new_status is not allowed,
  - status transition is not permitted,
  - transition to Randomized is requested but subject is not ready.

Notes:
- Relies on trigger trg_*_set_updated_at to maintain updated_at.
- Uses subject_ready_to_randomization(p_subject_id) for Randomized transition.
*/

CREATE OR REPLACE FUNCTION clinical.update_subject_status(
    IN p_subject_id INT,
    IN p_new_status TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_status TEXT;
    v_target_status  TEXT;
BEGIN
    IF p_subject_id IS NULL THEN
        RAISE EXCEPTION 'Subject id cannot be NULL';
    END IF;

    IF p_new_status IS NULL OR TRIM(p_new_status) = '' THEN
        RAISE EXCEPTION 'New status cannot be empty';
    END IF;

    v_target_status := UPPER(TRIM(p_new_status));

    -- Validate allowed vocabulary (must match CK_subjects_status)
    IF v_target_status NOT IN ('SCREENED', 'ENROLLED', 'RANDOMIZED', 'WITHDRAWN', 'COMPLETED') THEN
        RAISE EXCEPTION 'Invalid subject status "%". Allowed: Screened, Enrolled, Randomized, Withdrawn, Completed',
            p_new_status;
    END IF;

    -- Ensure subject exists and read current status
    SELECT sub.status
    INTO v_current_status
    FROM clinical.subjects sub
    WHERE sub.subject_id = p_subject_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Subject with id % does not exist', p_subject_id;
    END IF;

    v_current_status := UPPER(TRIM(v_current_status));

    -- No-op if same status
    IF v_current_status = v_target_status THEN
        RETURN FALSE;
    END IF;

    -- Disallow changes from terminal states
    IF v_current_status IN ('COMPLETED', 'WITHDRAWN') THEN
        RAISE EXCEPTION 'Cannot change status from terminal state "%" for subject_id %',
            v_current_status, p_subject_id;
    END IF;

    -- Transition matrix
    IF v_current_status = 'SCREENED' THEN
        IF v_target_status NOT IN ('ENROLLED', 'WITHDRAWN') THEN
            RAISE EXCEPTION 'Invalid transition: % -> % for subject_id %',
                v_current_status, v_target_status, p_subject_id;
        END IF;

    ELSIF v_current_status = 'ENROLLED' THEN
        IF v_target_status NOT IN ('RANDOMIZED', 'WITHDRAWN') THEN
            RAISE EXCEPTION 'Invalid transition: % -> % for subject_id %',
                v_current_status, v_target_status, p_subject_id;
        END IF;

    ELSIF v_current_status = 'RANDOMIZED' THEN
        IF v_target_status NOT IN ('COMPLETED', 'WITHDRAWN') THEN
            RAISE EXCEPTION 'Invalid transition: % -> % for subject_id %',
                v_current_status, v_target_status, p_subject_id;
        END IF;
    END IF;

    -- Extra guard: moving to Randomized requires readiness
    IF v_target_status = 'RANDOMIZED' THEN
        IF NOT clinical.subject_ready_to_randomization(p_subject_id) THEN
            RAISE EXCEPTION 'Subject_id % is not ready for randomization', p_subject_id;
        END IF;
    END IF;

    -- Apply update (store in canonical case used by your CHECK values)
    UPDATE clinical.subjects
    SET status =
        CASE v_target_status
            WHEN 'SCREENED'    THEN 'Screened'
            WHEN 'ENROLLED'    THEN 'Enrolled'
            WHEN 'RANDOMIZED'  THEN 'Randomized'
            WHEN 'WITHDRAWN'   THEN 'Withdrawn'
            WHEN 'COMPLETED'   THEN 'Completed'
        END
    WHERE subject_id = p_subject_id;

    RAISE NOTICE 'Subject_id % status changed: % -> %',
        p_subject_id, v_current_status, v_target_status;

    RETURN TRUE;
END;
$$;

