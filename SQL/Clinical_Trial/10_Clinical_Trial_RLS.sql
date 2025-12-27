/*
Clinical Trial Database – Optional Row-Level Security (RLS)

Purpose:
Demonstrate row-level access control for portfolio purposes.

RLS model:
- Access is limited by site_code.
- The active site is provided via session parameter:
    SET app.current_site_code = 'WAW-01';

Scope:
- clinical.subjects (primary)
- (optional) clinical.visits via subject relationship

Notes:
- Policies are defined for LOGIN role: clinical_app_user.
- Reporting user clinical_report_user remains unrestricted (allow-all policy).
*/


/* 1. Enable RLS on subjects */

ALTER TABLE clinical.subjects ENABLE ROW LEVEL SECURITY;

/* Optional: enforce RLS also for table owner */
-- ALTER TABLE clinical.subjects FORCE ROW LEVEL SECURITY;


/* 2. Policies for clinical_app_user (site-scoped) */

DROP POLICY IF EXISTS subjects_app_select_by_site ON clinical.subjects;
CREATE POLICY subjects_app_select_by_site
ON clinical.subjects
FOR SELECT
TO clinical_app_user
USING (
    EXISTS (
        SELECT 1
        FROM clinical.study_sites sts
        WHERE sts.study_site_id = clinical.subjects.study_site_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
);

DROP POLICY IF EXISTS subjects_app_update_by_site ON clinical.subjects;
CREATE POLICY subjects_app_update_by_site
ON clinical.subjects
FOR UPDATE
TO clinical_app_user
USING (
    EXISTS (
        SELECT 1
        FROM clinical.study_sites sts
        WHERE sts.study_site_id = clinical.subjects.study_site_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM clinical.study_sites sts
        WHERE sts.study_site_id = clinical.subjects.study_site_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
);

DROP POLICY IF EXISTS subjects_app_insert_by_site ON clinical.subjects;
CREATE POLICY subjects_app_insert_by_site
ON clinical.subjects
FOR INSERT
TO clinical_app_user
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM clinical.study_sites sts
        WHERE sts.study_site_id = clinical.subjects.study_site_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
);

DROP POLICY IF EXISTS subjects_app_delete_by_site ON clinical.subjects;
CREATE POLICY subjects_app_delete_by_site
ON clinical.subjects
FOR DELETE
TO clinical_app_user
USING (
    EXISTS (
        SELECT 1
        FROM clinical.study_sites sts
        WHERE sts.study_site_id = clinical.subjects.study_site_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
);


/* 3. Reporting user unrestricted (allow-all) */
DROP POLICY IF EXISTS subjects_report_select_all ON clinical.subjects;
CREATE POLICY subjects_report_select_all
ON clinical.subjects
FOR SELECT
TO clinical_report_user
USING (true);


/* 4. Optional: RLS on visits (inherits subject/site restriction) */

ALTER TABLE clinical.visits ENABLE ROW LEVEL SECURITY;

/* Optional: enforce RLS also for table owner */
-- ALTER TABLE clinical.visits FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS visits_app_by_subject_site ON clinical.visits;
CREATE POLICY visits_app_by_subject_site
ON clinical.visits
FOR ALL
TO clinical_app_user
USING (
    EXISTS (
        SELECT 1
        FROM clinical.subjects sub
        JOIN clinical.study_sites sts
          ON sts.study_site_id = sub.study_site_id
        WHERE sub.subject_id = clinical.visits.subject_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM clinical.subjects sub
        JOIN clinical.study_sites sts
          ON sts.study_site_id = sub.study_site_id
        WHERE sub.subject_id = clinical.visits.subject_id
          AND UPPER(TRIM(sts.site_code)) = UPPER(TRIM(current_setting('app.current_site_code', true)))
    )
);

/* Reporting user unrestricted on visits (optional) */

DROP POLICY IF EXISTS visits_report_select_all ON clinical.visits;
CREATE POLICY visits_report_select_all
ON clinical.visits
FOR SELECT
TO clinical_report_user
USING (true);

/*
Example RLS tests (manual)
SET ROLE clinical_app_user;
SET app.current_site_code = 'WAW-01';
SELECT * FROM clinical.subjects;

SET app.current_site_code = 'KRK-01';
SELECT * FROM clinical.subjects;

SET ROLE clinical_report_user;
SELECT * FROM clinical.subjects;
 */