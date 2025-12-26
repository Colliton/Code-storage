/*
Purpose:
- Reporting / analytics layer for the Clinical Trial project
- Defines reusable views for exploration, reporting and BI-style queries

Execution order:
- Run after:
  03_Clinical_Trial_Physical_Model_DDL.sql
  04_Clinical_Trial_Inserts.sql

Rerunnable:
- Views are created with CREATE OR REPLACE

Testing:
- Dedicated tests are stored in: 09_Clinical_Trial_Views_Tests.sql
- Tests are read-only (SELECTs) and can be executed repeatedly.
*/

/*
VIEW: vw_subject_journey

Purpose:
Provides a flattened, subject-centric timeline of study participation,
combining study, site, subject, and visit information in a single dataset.

One row represents:
- a single visit for a subject,
- or a subject without visits (visit-related columns are NULL).

Intended usage:
- subject-level reporting and analysis,
- visit timelines and progress tracking,
- foundation for window functions (e.g. visit ordering, cumulative metrics),
- filtering by study, site, subject, or visit status.

Notes:
- Uses LEFT JOIN on visits to preserve subjects without recorded visits.
- Status and code fields are normalized using UPPER/TRIM for consistent reporting.
*/

CREATE OR REPLACE VIEW clinical.vw_subject_journey AS
SELECT 
	UPPER(TRIM(st.study_code)) AS study_code,
	UPPER(TRIM(sts.site_code)) AS site_code,
	UPPER(TRIM(sub.subject_code)) AS subject_code,
	UPPER(TRIM(sub.status)) AS subject_status,
	vis.visit_no,
	vis.visit_type,
	vis.visit_date,
	UPPER(TRIM(vis.visit_status)) AS visit_status
FROM clinical.studies st
JOIN clinical.study_sites sts
  ON st.study_id = sts.study_id
JOIN clinical.subjects sub
  ON sts.study_site_id = sub.study_site_id
LEFT JOIN clinical.visits vis
  ON sub.subject_id = vis.subject_id;

/*
VIEW: vw_randomization_status

Purpose:
Provides a subject-level overview of randomization status within a study.

One row represents:
- a single subject,
- including assigned treatment arm and randomization timestamp,
- or NULL values for arm and date if the subject has not been randomized.

Intended usage:
- reporting and monitoring randomization progress,
- identifying randomized vs non-randomized subjects,
- joining with subject- or study-level views for analytics.

Notes:
- Uses LEFT JOIN to preserve subjects without randomization records.
- NULL values in arm_code and randomized_at indicate subjects not yet randomized.
- Status and code fields are normalized using UPPER/TRIM for consistent reporting.
*/

CREATE OR REPLACE VIEW clinical.vw_randomization_status AS 
SELECT
	UPPER(TRIM(sub.subject_code)) AS subject_code,
	UPPER(TRIM(sub.status)) AS subject_status,
	UPPER(TRIM(trar.arm_code)) AS arm_code,
	rand.randomized_at
FROM clinical.subjects sub
LEFT JOIN clinical.randomization rand
  ON sub.subject_id = rand.subject_id
LEFT JOIN clinical.treatment_arms trar
  ON rand.arm_id = trar.arm_id;

/*
VIEW: vw_studies_overview

Purpose:
Provides a high-level, study-centric overview with aggregated participation metrics.

One row represents:
- a single clinical study.

Included metrics:
- site_count: number of sites associated with the study,
- subject_count: number of subjects enrolled in the study.

Intended usage:
- study-level reporting and dashboards,
- monitoring study scale and enrollment progress,
- joining with other analytical views or metrics.

Notes:
- Uses LEFT JOINs to include studies without sites or subjects.
- DISTINCT aggregation prevents double counting of sites and subjects.
- Study attributes are normalized using UPPER/TRIM for consistent reporting.
*/

CREATE OR REPLACE VIEW clinical.vw_studies_overview AS 
SELECT 
	UPPER(TRIM(st.study_code)) AS study_code,
	UPPER(TRIM(st.study_phase)) AS study_phase,
	UPPER(TRIM(st.study_status)) AS study_status,
	COUNT(DISTINCT sts.site_id) AS site_count,
	COUNT(DISTINCT sub.subject_id) AS subject_count 
FROM clinical.studies st
LEFT JOIN clinical.study_sites sts
  ON st.study_id = sts.study_id
LEFT JOIN clinical.subjects sub
  ON sts.study_site_id = sub.study_site_id
GROUP BY 
	st.study_code, 
	st.study_phase, 
	st.study_status;

/*
VIEW: vw_measurements_flat

Purpose:
Provides a fully flattened, measurement-centric dataset across studies,
subjects, visits, and measurement definitions.

One row represents:
- a single measurement recorded for a subject during a specific visit,
- or a visit without measurements (measurement-related columns are NULL).

Included data:
- study and subject identifiers,
- visit number,
- measurement code and associated values (numeric, text, boolean),
- unit of measurement.

Intended usage:
- analytical queries and reporting,
- exploratory data analysis and BI use cases,
- foundation for window functions and time-based analyses on measurements.

Notes:
- Uses LEFT JOINs throughout to preserve visits and subjects without measurements.
- NULL values in measurement-related columns indicate missing or not-yet-recorded measurements.
- Codes and status-like fields are normalized using UPPER/TRIM for consistent reporting.
*/

CREATE OR REPLACE VIEW clinical.vw_measurements_flat AS
SELECT
	UPPER(TRIM(st.study_code)) AS study_code,
	UPPER(TRIM(sub.subject_code)) AS subject_code,
	vis.visit_no,
	UPPER(TRIM(mestyp.measurement_code)) AS measurement_code, 
	mes.value_numeric, 
	mes.value_text, 
	mes.value_boolean, 
	UPPER(TRIM(uni.unit_code)) AS unit_code 
FROM clinical.studies st
LEFT JOIN clinical.study_sites sts 
  ON st.study_id = sts.study_id
LEFT JOIN clinical.subjects sub
  ON sts.study_site_id = sub.study_site_id 
LEFT JOIN clinical.visits vis
  ON sub.subject_id = vis.subject_id
LEFT JOIN clinical.measurements mes
  ON vis.visit_id = mes.visit_id
LEFT JOIN clinical.measurement_types mestyp
  ON mes.measurement_type_id = mestyp.measurement_type_id
LEFT JOIN clinical.units uni
  ON mestyp.unit_id = uni.unit_id;

/*
VIEW: vw_followup_candidates

Purpose:
Identifies subjects who require visit planning or follow-up actions.

One row represents:
- a subject with no recorded visits yet,
- or a subject with visits that were cancelled or missed.

Included data:
- subject identifier,
- visit type and date (if available),
- visit status and lock flag.

Intended usage:
- operational follow-up and visit planning,
- identifying subjects requiring scheduling or rescheduling,
- monitoring incomplete or failed visit activity.

Notes:
- RIGHT JOIN is used intentionally to preserve all subjects,
  including those without any visit records.
- NULL values in visit-related columns indicate subjects
  who have not yet had any visits recorded.
- Status and code fields are normalized using UPPER/TRIM
  for consistent reporting.
*/

CREATE OR REPLACE VIEW clinical.vw_followup_candidates AS 
SELECT 
	UPPER(TRIM(sub.subject_code)) AS subject_code,
	UPPER(TRIM(vis.visit_type)) AS visit_type,
	vis.visit_date,
	UPPER(TRIM(vis.visit_status)) AS visit_status,
	vis.is_locked
FROM clinical.visits vis
RIGHT JOIN clinical.subjects sub
  ON vis.subject_id = sub.subject_id
WHERE vis.visit_id IS NULL 
  OR UPPER(TRIM(vis.visit_status)) IN ('CANCELLED', 'MISSED');

/*
VIEW: vw_study_visit_activity_windows

Purpose:
Provides a study-level daily activity time series with advanced window analytics
(cumulative totals and centered moving averages) based on visit completion dates.

One row represents:
- a single calendar day within a study (only days with at least one completed visit are included).

Included metrics:
- daily_completed_visits: number of completed visits on a given day,
- cum_completed_visits: cumulative number of completed visits within a study over time,
- centered_7d_avg_completed_visits: centered moving average of daily completed visits
  using a RANGE-based window frame (+/- 3 days).

Intended usage:
- study activity monitoring and trend analysis,
- demonstrating window functions and window frames (EPAM-style "final task"),
- building dashboards (activity curves per study).

Notes:
- Uses DATE_TRUNC('day', visit_date) to aggregate timestamps into calendar days.
- RANGE window frame is date-based (INTERVAL), ensuring correct time-centered averaging.
*/

CREATE OR REPLACE VIEW clinical.vw_study_visit_activity_windows AS
WITH daily AS (
    SELECT
        sj.study_code,
        DATE_TRUNC('day', sj.visit_date)::date AS activity_day,
        COUNT(*) AS daily_completed_visits
    FROM clinical.vw_subject_journey sj
    WHERE sj.visit_date IS NOT NULL
      AND UPPER(TRIM(sj.visit_status)) = 'COMPLETED'
    GROUP BY
        sj.study_code,
        DATE_TRUNC('day', sj.visit_date)::date
)
SELECT
    study_code,
    activity_day,
    daily_completed_visits,
    SUM(daily_completed_visits) OVER (
        PARTITION BY study_code
        ORDER BY activity_day
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_completed_visits,
    AVG(daily_completed_visits::numeric) OVER (
        PARTITION BY study_code
        ORDER BY activity_day
        RANGE BETWEEN INTERVAL '3 days' PRECEDING AND INTERVAL '3 days' FOLLOWING
    ) AS centered_7d_avg_completed_visits
FROM daily;



