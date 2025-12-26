/*
This script validates VIEWs created for the Clinical Trial database.

Test strategy:
    1. Happy path (basic SELECTs / sanity checks)
    2. Null-handling checks (LEFT/RIGHT JOIN effects)
    3. Edge cases (empty result sets)
    4. Ordering / limits for rerunnability

All tests are executed inside a transaction and rolled back.
*/

BEGIN;

/*
Helper queries (inspect test data)

Uncomment if you want to see available test data
- SELECT study_id, study_code FROM clinical.studies;
- SELECT subject_id, subject_code, status, study_site_id FROM clinical.subjects;
- SELECT visit_id, subject_id, visit_no, visit_status, visit_date FROM clinical.visits;
- SELECT * FROM clinical.randomization;
- SELECT * FROM clinical.treatment_arms;
- SELECT measurement_id, visit_id, measurement_type_id, value_numeric, value_text, value_boolean FROM clinical.measurements;
*/


-- 1. vw_subject_journey
-- Purpose: wide join across studies -> sites -> subjects -> visits

-- Happy path
SELECT *
FROM clinical.vw_subject_journey
ORDER BY study_code, subject_code, visit_no
LIMIT 20;

-- Sanity check: expected columns not null for identifiers
-- EXPECTED: 0 rows (if data is consistent)
SELECT *
FROM clinical.vw_subject_journey
WHERE study_code IS NULL
   OR site_code IS NULL
   OR subject_code IS NULL
LIMIT 20;

-- Edge: subjects without visits should still appear (because visits is LEFT JOIN)
-- EXPECTED: >= 0 rows (depends on data)
SELECT *
FROM clinical.vw_subject_journey
WHERE visit_no IS NULL
LIMIT 20;


-- 2. vw_randomization_status
-- Purpose: show randomization info with NULLs for not randomized subjects

-- Happy path
SELECT *
FROM clinical.vw_randomization_status
ORDER BY subject_code
LIMIT 20;

-- Check: non-randomized subjects should have NULL arm_code and randomized_at
-- EXPECTED: >= 0 rows (depends on data)
SELECT *
FROM clinical.vw_randomization_status
WHERE arm_code IS NULL
  AND randomized_at IS NULL
LIMIT 20;

-- Check: if randomized_at is NOT NULL then arm_code should typically be NOT NULL
-- (unless data is incomplete)
-- EXPECTED: 0 rows in clean data
SELECT *
FROM clinical.vw_randomization_status
WHERE randomized_at IS NOT NULL
  AND arm_code IS NULL
LIMIT 20;


-- 3. vw_studies_overview
-- Purpose: aggregated per study (counts)

-- Happy path
SELECT *
FROM clinical.vw_studies_overview
ORDER BY study_code
LIMIT 20;

-- Sanity: counts should not be negative
-- EXPECTED: 0 rows
SELECT *
FROM clinical.vw_studies_overview
WHERE site_count < 0
   OR subject_count < 0
LIMIT 20;

-- Optional: check that study_code is unique in the view
-- EXPECTED: 0 rows
SELECT study_code, COUNT(*) AS cnt
FROM clinical.vw_studies_overview
GROUP BY study_code
HAVING COUNT(*) > 1;


-- 4. vw_measurements_flat
-- Purpose: flatten measurements across study/subject/visit/measurement types

-- Happy path
SELECT *
FROM clinical.vw_measurements_flat
ORDER BY study_code, subject_code, visit_no, measurement_code
LIMIT 20;

-- Check: measurement_code should not be NULL WHEN a measurement value exists
-- EXPECTED: 0 rows
SELECT *
FROM clinical.vw_measurements_flat
WHERE measurement_code IS NULL
  AND (
        value_numeric IS NOT NULL
     OR value_text    IS NOT NULL
     OR value_boolean IS NOT NULL
  )
LIMIT 20;

-- Check: at least one of value_* is present per measurement row (optional rule)
-- EXPECTED: >= 0 rows; if you enforce "one value must be present" then EXPECTED: 0 rows
SELECT *
FROM clinical.vw_measurements_flat
WHERE value_numeric IS NULL
  AND value_text IS NULL
  AND value_boolean IS NULL
LIMIT 20;


-- 5. vw_followup_candidates
-- Purpose: subjects who have no visits OR have missed/cancelled visits

-- Happy path
SELECT *
FROM clinical.vw_followup_candidates
ORDER BY subject_code, visit_date
LIMIT 20;

-- Check: should include subjects with NULL visit (no visits)
-- EXPECTED: >= 0 rows (depends on data)
SELECT *
FROM clinical.vw_followup_candidates
WHERE visit_type IS NULL
  AND visit_date IS NULL
  AND visit_status IS NULL
LIMIT 20;

-- Check: status filter works
-- EXPECTED: 0 rows (the view allows only NULL status (no visits) or CANCELLED/MISSED)
SELECT *
FROM clinical.vw_followup_candidates
WHERE visit_status IS NOT NULL
  AND visit_status NOT IN ('CANCELLED', 'MISSED')
LIMIT 20;


-- 6. vw_study_visit_activity_windows
-- Purpose: window functions + frames (cumulative + centered avg)

-- Happy path
SELECT *
FROM clinical.vw_study_visit_activity_windows
ORDER BY study_code, activity_day
LIMIT 30;

-- Sanity: cumulative should be non-decreasing within study
-- EXPECTED: 0 rows (if ordering is correct and values non-negative)
WITH x AS (
  SELECT
    study_code,
    activity_day,
    cum_completed_visits,
    LAG(cum_completed_visits) OVER (PARTITION BY study_code ORDER BY activity_day) AS prev_cum
  FROM clinical.vw_study_visit_activity_windows
)
SELECT *
FROM x
WHERE prev_cum IS NOT NULL
  AND cum_completed_visits < prev_cum
LIMIT 20;


/*
End of tests
ROLLBACK is included for consistency (views do not modify data)
*/

ROLLBACK;