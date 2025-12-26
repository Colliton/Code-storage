/*
This script validates PL/pgSQL functions created for the Clinical Trial database.

Test strategy:
	1. Happy path (expected correct behavior)
	2. Invalid input (NULL / empty)
	3.  Not found scenarios
	4. Business rule violations
	
All tests are executed inside a transaction and rolled back.
*/

BEGIN;

/*
Helper queries (inspect test data)

Uncomment if you want to see available test data
- SELECT study_id, study_code FROM clinical.studies;
- SELECT subject_id, subject_code, status FROM clinical.subjects;
- SELECT visit_no, subject_id, visit_status FROM clinical.visits;
*/


-- 1. visit_status_info(p_subject_id, p_visit_no)

-- Happy path: existing subject & visit
SELECT clinical.visit_status_info(
    (SELECT subject_id FROM clinical.subjects LIMIT 1),
    (SELECT visit_no FROM clinical.visits LIMIT 1)
);

-- Not found: invalid subject
-- EXPECTED: EXCEPTION
SELECT clinical.visit_status_info(999999, 1);

-- Not found: invalid visit
-- EXPECTED: EXCEPTION
SELECT clinical.visit_status_info(
	(SELECT subject_id FROM clinical.subjects LIMIT 1),
	999999
	);

-- 2. subjects_per_study(p_study_code)

-- Happy path
SELECT clinical.subjects_per_study(
    (SELECT study_code FROM clinical.studies LIMIT 1)
);

-- Invalid input
-- EXPECTED: EXCEPTION
SELECT clinical.subjects_per_study(NULL);
SELECT clinical.subjects_per_study('   ');

-- Not found
-- EXPECTED: EXCEPTION
SELECT clinical.subjects_per_study('STUDY_DOES_NOT_EXIST');

-- 3. subject_ready_to_randomization(p_subject_id)

-- Happy path (for any existing subject)
SELECT clinical.subject_ready_to_randomization(
    (SELECT subject_id FROM clinical.subjects LIMIT 1)
);

-- EXPECTED: TRUE
SELECT clinical.subject_ready_to_randomization(sub.subject_id)
FROM clinical.subjects sub
WHERE UPPER(TRIM(sub.status)) = 'ENROLLED'
  AND NOT EXISTS (
      SELECT 1 FROM clinical.randomization r
      WHERE r.subject_id = sub.subject_id
  )
LIMIT 1;

-- EXPECTED: FALSE
SELECT clinical.subject_ready_to_randomization(sub.subject_id)
FROM clinical.subjects sub
WHERE EXISTS (
    SELECT 1 FROM clinical.randomization r
    WHERE r.subject_id = sub.subject_id
)
LIMIT 1;

-- Invalid input
-- EXPECTED: EXCEPTION
SELECT clinical.subject_ready_to_randomization(NULL);

-- Not found
-- EXPECTED: EXCEPTION
SELECT clinical.subject_ready_to_randomization(999999);

-- 4. subject_visits(p_subject_code)

-- Happy path
SELECT *
FROM clinical.subject_visits(
    (SELECT subject_code FROM clinical.subjects LIMIT 1)
);

-- Invalid input
-- EXPECTED: EXCEPTION
SELECT * FROM clinical.subject_visits(NULL);
SELECT * FROM clinical.subject_visits('   ');

-- Not found
-- EXPECTED: EXCEPTION
-- SELECT * FROM clinical.subject_visits('SUBJECT_DOES_NOT_EXIST');

-- 5. study_metrics(p_study_code)

-- Happy path
SELECT *
FROM clinical.study_metrics(
    (SELECT study_code FROM clinical.studies LIMIT 1)
);

-- Invalid input
-- EXPECTED: EXCEPTION
SELECT * FROM clinical.study_metrics(NULL);
SELECT * FROM clinical.study_metrics('   ');

-- Not found
-- EXPECTED: EXCEPTION
SELECT * FROM clinical.study_metrics('STUDY_DOES_NOT_EXIST');

-- 6. update_subject_status(p_subject_id, p_new_status)

-- Pick a subject for status transition tests
-- (limit 1 ensures rerunnability)
WITH test_subject AS (
    SELECT subject_id, status
    FROM clinical.subjects
    LIMIT 1
)
SELECT * FROM test_subject;

-- No-op update (same status)
-- EXPECTED: FALSE
SELECT clinical.update_subject_status(
    (SELECT subject_id FROM clinical.subjects LIMIT 1),
    (SELECT status FROM clinical.subjects LIMIT 1)
);

-- Invalid status value
-- EXPECTED: EXCEPTION
SELECT clinical.update_subject_status(
	(SELECT subject_id FROM clinical.subjects LIMIT 1),
	'INVALID_STATUS'
	);

-- Invalid input
-- EXPECTED: EXCEPTION
SELECT clinical.update_subject_status(NULL, 'Enrolled');
SELECT clinical.update_subject_status(
	(SELECT subject_id FROM clinical.subjects LIMIT 1),
	NULL
	);

-- Example valid transition (depends on current status & data)
-- Uncomment ONLY if transition is allowed by business rules
SELECT clinical.update_subject_status(
	(SELECT subject_id FROM clinical.subjects LIMIT 1),
	'Withdrawn'
	);

/*
End of tests
Roll back all changes to keep data intact
*/

ROLLBACK;
