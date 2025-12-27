/*
Clinical Trial Database – Example Analytical Queries

Purpose:
This script contains example SELECT queries built on top of the Clinical Trial
database to demonstrate SQL querying skills in an analytical context.

Scope:
- Queries are based on existing tables and reporting views in the 'clinical' schema.
- The script focuses on data exploration and analysis, not data modification.

Techniques demonstrated:
- Common Table Expressions (CTE)
- Correlated and non-correlated subqueries
- EXISTS / NOT EXISTS patterns
- Window functions (ranking, lag/lead, aggregates)
- Window frames (ROWS / RANGE)
- Conditional aggregation (FILTER / CASE)
- JOIN strategies and NULL handling

Design principles:
- Read-only queries (SELECT only)
- Clear business intent per query
- Each query demonstrates a distinct SQL concept
- ORDER BY and LIMIT used where appropriate for predictable output

Notes:
- Queries are intended for portfolio and learning purposes.
- The script does not assume any specific user role or RLS context.
- No schema changes or DML operations are performed.
*/

/*
Query 1: Last visit per subject

Purpose:
Return the most recent visit record for each subject to support follow-up tracking
and subject-level timeline analysis.

Technique:
- CTE + ROW_NUMBER() window function
- PARTITION BY subject_code to rank visits within each subject
- Tie-breaker using visit_no to ensure deterministic results when visit_date ties occur

Uses:
- clinical.vw_subject_journey
*/

WITH ranked_visits AS (
    SELECT
        subject_code,
        study_code,
        visit_no,
        visit_date,
        visit_status,
        ROW_NUMBER() OVER (
            PARTITION BY subject_code
            ORDER BY visit_date DESC NULLS LAST, visit_no DESC NULLS LAST
        ) AS rn
    FROM clinical.vw_subject_journey
)
SELECT
    subject_code,
    study_code,
    visit_no,
    visit_date,
    visit_status
FROM ranked_visits
WHERE rn = 1
ORDER BY 
	study_code, 
	subject_code;

/*
Query 2: Last completed visit date per subject (correlated subquery)

Purpose:
For each subject, return the date of their most recent COMPLETED visit.
Useful for follow-up monitoring and subject timeline analysis.

Technique:
- Correlated subquery in the SELECT list
- MAX(visit_date) aggregated per subject inside the subquery
- Correlation via sj2.subject_code = sj1.subject_code

Uses:
- clinical.vw_subject_journey
*/

SELECT
    sj1.subject_code,
    sj1.study_code,
    (
        SELECT MAX(sj2.visit_date)
        FROM clinical.vw_subject_journey sj2
        WHERE sj2.subject_code = sj1.subject_code
          AND UPPER(TRIM(sj2.visit_status)) = 'COMPLETED'
    ) AS last_completed_visit_date
FROM clinical.vw_subject_journey sj1
GROUP BY
    sj1.subject_code,
    sj1.study_code
ORDER BY
    sj1.study_code,
    sj1.subject_code;


/*
Query 3: Subjects without any visits (anti-join)

Purpose:
List subjects who have not had any visits recorded yet.
This can be used to identify participants who require visit scheduling.

Technique:
- NOT EXISTS anti-join
- Checks absence of related rows in clinical.visits for each subject

Uses:
- clinical.subjects
- clinical.visits
*/

SELECT
    sub.subject_code,
    sub.status AS subject_status
FROM clinical.subjects sub
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.visits vis
    WHERE vis.subject_id = sub.subject_id
)
ORDER BY sub.subject_code;

/*
Query 4: Visit outcome counts per study (including subjects without visits)

Purpose:
Provide a high-level operational overview of visit statuses per study,
including identification of subjects who have not yet had any visits recorded.

Technique:
- Conditional aggregation using COUNT(*) FILTER (WHERE ...)
- Handling NULLs to capture subjects without visits (LEFT JOIN semantics)
- GROUP BY study_code

Uses:
- clinical.vw_subject_journey

Notes:
- Rows with visit_status IS NULL represent subjects with no visits recorded.
- Each FILTER clause counts a specific visit outcome category.
- The query aggregates visit-level data at the study level.
*/

SELECT 
	study_code,
	COUNT(*) FILTER (WHERE UPPER(TRIM(visit_status)) = 'COMPLETED') AS completed_visits_count,
	COUNT(*) FILTER (WHERE UPPER(TRIM(visit_status)) = 'MISSED') AS missed_visits_count,
	COUNT(*) FILTER (WHERE UPPER(TRIM(visit_status)) = 'CANCELLED') AS cancelled_visits_count,
	COUNT(*) FILTER (WHERE UPPER(TRIM(visit_status)) = 'PLANNED') AS planned_visits_count,
	COUNT(*) FILTER (WHERE visit_status IS NULL) AS no_visits_count
FROM clinical.vw_subject_journey
GROUP BY study_code
ORDER BY study_code;

/*
Query 5: Visit status change between consecutive visits (LAG)

Purpose:
Track how each subject’s visit status changes from one visit to the next.
Useful for identifying transitions such as Planned → Completed or Completed → Missed.

Technique:
- Window function LAG() to retrieve the previous visit status within each subject
- PARTITION BY subject_code with deterministic ordering (visit_date, visit_no)

Uses:
- clinical.vw_subject_journey
*/

SELECT
	subject_code,
	subject_status,
	visit_no,
	visit_type,
	visit_date,
	visit_status,
	LAG(visit_status) OVER(
		PARTITION BY subject_code 
		ORDER BY visit_date, visit_no
		) AS prev_visit_status
FROM clinical.vw_subject_journey
WHERE visit_no IS NOT NULL 
ORDER BY 
	subject_code,
	visit_date,
	visit_no;

/*
Query 6: Rolling 7-row average of daily visits per study (window frame)

Purpose:
Provide a rolling average of daily visit counts per study to smooth short-term fluctuations.

Technique:
- CTE to aggregate raw visit records into daily visit counts (study_code + visit_day)
- Window function AVG(...) with ROWS frame:
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
- PARTITION BY study_code, ordered by visit_day (chronological)

Uses:
- clinical.vw_subject_journey

Notes:
- ROWS frame is row-based (last 7 rows), not strictly “last 7 calendar days”.
- If there are gaps in dates, the window still spans up to 7 available rows.
- For deterministic ordering, ensure visit_day is unique per study in the CTE (daily aggregation).
*/

WITH daily_visits AS (
	SELECT
		study_code, 
    	DATE(visit_date) AS visit_day,
    	COUNT(*) AS daily_visit_count
	FROM clinical.vw_subject_journey
	WHERE visit_date IS NOT NULL
	GROUP BY 
		study_code,
		DATE(visit_date)
)
SELECT 
	study_code,
	visit_day,
	AVG(daily_visit_count) OVER(
		PARTITION BY study_code 
		ORDER BY visit_day 
		ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
FROM daily_visits
ORDER BY 
	study_code,
	visit_day;

/*
Query 7: Randomization status with default value for non-randomized subjects

Purpose:
Provide a unified view of subject randomization status, explicitly marking
subjects without an assigned treatment arm as NOT_RANDOMIZED.
This makes the randomization state explicit and easier to interpret in reports
and downstream queries.

Technique:
- JOIN between subject-level journey data and randomization status view
- COALESCE used to replace NULL arm_code values with a semantic default
  ('NOT_RANDOMIZED')
- Preserve original randomization metadata (arm_code, randomized_at)
  while exposing a normalized status column

Uses:
- clinical.vw_randomization_status
- clinical.vw_subject_journey

Notes:
- NULL arm_code indicates subjects who have not been randomized yet.
- The derived column randomization_status is intended for reporting
  and filtering, while arm_code remains available for audit/debug purposes.
- This query does not modify data; it only standardizes interpretation
  of missing randomization information.
*/

SELECT 
	sj.study_code,
	rs.subject_code,
	rs.arm_code,
	COALESCE(rs.arm_code, 'NOT_RANDOMIZED') AS randomization_status,
	rs.randomized_at
FROM clinical.vw_randomization_status rs
JOIN (
    SELECT DISTINCT subject_code, study_code
    FROM clinical.vw_subject_journey
) sj
  ON rs.subject_code = sj.subject_code;

	
/*
QC: subject journey sanity checks (multi-check report)

Purpose:
Return a compact quality-check report for subject/visit data based on vw_subject_journey.
Each row represents one detected issue (or an info case), with a short explanation.

How to read:
- INFO  : expected situations (e.g., subject without visits)
- WARN  : suspicious, but might be acceptable depending on business rules
- ERROR : usually indicates inconsistent / incomplete data
*/

WITH base AS (
    SELECT
        UPPER(TRIM(study_code))  AS study_code,
        UPPER(TRIM(subject_code)) AS subject_code,
        visit_no,
        visit_type,
        visit_date,
        UPPER(TRIM(visit_status)) AS visit_status
    FROM clinical.vw_subject_journey
)
-- 1) Subjects without any visits (expected in many datasets)
SELECT
    'subjects_without_visits' AS check_name,
    'INFO' AS severity,
    study_code,
    subject_code,
    visit_no,
    visit_type,
    visit_date,
    visit_status,
    'All visit_* columns are NULL -> subject currently has no visits in the dataset.' AS details
FROM base
WHERE visit_no IS NULL
  AND visit_type IS NULL
  AND visit_date IS NULL
  AND visit_status IS NULL

UNION ALL

-- 2) Visit exists but status is NULL (usually bad)
SELECT
    'visit_missing_status' AS check_name,
    'ERROR' AS severity,
    study_code,
    subject_code,
    visit_no,
    visit_type,
    visit_date,
    visit_status,
    'visit_no is present but visit_status is NULL -> visit recorded without a status.' AS details
FROM base
WHERE visit_no IS NOT NULL
  AND visit_status IS NULL

UNION ALL

-- 3) Visit exists but visit_date is NULL (often suspicious)
SELECT
    'visit_missing_date' AS check_name,
    'WARN' AS severity,
    study_code,
    subject_code,
    visit_no,
    visit_type,
    visit_date,
    visit_status,
    'visit_no is present but visit_date is NULL -> visit recorded without a date.' AS details
FROM base
WHERE visit_no IS NOT NULL
  AND visit_date IS NULL

UNION ALL

-- 4) Status present but visit_no is NULL (join anomaly / unexpected shape)
SELECT
    'status_without_visit_no' AS check_name,
    'ERROR' AS severity,
    study_code,
    subject_code,
    visit_no,
    visit_type,
    visit_date,
    visit_status,
    'visit_status is present but visit_no is NULL -> inconsistent visit identifiers.' AS details
FROM base
WHERE visit_no IS NULL
  AND visit_status IS NOT NULL

UNION ALL

-- 5) Duplicate visit_no per subject (should typically be unique per subject)
SELECT
    'duplicate_visit_no_per_subject' AS check_name,
    'ERROR' AS severity,
    b.study_code,
    b.subject_code,
    b.visit_no,
    b.visit_type,
    b.visit_date,
    b.visit_status,
    'Same (subject_code, visit_no) appears multiple times -> possible duplicates in joins or data.' AS details
FROM base b
JOIN (
    SELECT subject_code, visit_no
    FROM base
    WHERE visit_no IS NOT NULL
    GROUP BY subject_code, visit_no
    HAVING COUNT(*) > 1
) d
  ON d.subject_code = b.subject_code
 AND d.visit_no     = b.visit_no

ORDER BY
    severity DESC,  -- ERROR first, then WARN, then INFO (lexicographic works here)
    check_name,
    study_code,
    subject_code,
    visit_no NULLS FIRST
LIMIT 200;

	