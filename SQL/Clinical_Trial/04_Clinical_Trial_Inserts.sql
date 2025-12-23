/*
Sample data (rerunnable) using CTEs (WITH ... VALUES) where practical.
No hardcoded IDs; FK values resolved via SELECT.
 */

-- ============================================================
-- Table: clinical.units
-- Purpose: seed basic measurement units (incl. 'NA' for boolean/text types)
-- ============================================================
WITH new_units(unit_code, unit_name) AS (
	VALUES
		('NA', 'Not applicable'),
        ('MMHG', 'Millimeters of mercury'),
        ('KG', 'Kilograms')
)
INSERT INTO clinical.units (unit_code, unit_name)
SELECT nu.unit_code, nu.unit_name
FROM new_units nu
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.units uni
    WHERE uni.unit_code = nu.unit_code
);


-- ============================================================
-- Table: clinical.measurement_types
-- Purpose: define measurement dictionary (FK -> units)
-- ============================================================

WITH new_measurement_types(unit_code, measurement_code, measurement_name, value_type) AS (
	VALUES
        ('MMHG', 'SBP', 'Systolic Blood Pressure', 'NUMERIC'),
        ('KG', 'WEIGHT', 'Body Weight', 'NUMERIC'),
        ('NA', 'SMOKER', 'Current Smoker', 'BOOLEAN')
)
INSERT INTO clinical.measurement_types (unit_id, measurement_code, measurement_name, value_type)
SELECT
    uni.unit_id,
    nmt.measurement_code,
    nmt.measurement_name,
    nmt.value_type
FROM new_measurement_types nmt
JOIN clinical.units uni
  ON uni.unit_code = nmt.unit_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.measurement_types mt
    WHERE mt.measurement_code = nmt.measurement_code
);

-- ============================================================
-- Table: clinical.addresses
-- Purpose: seed addresses for sites/investigators (unique address logic)
-- ============================================================

WITH new_addresses(street_name, building_no, flat_no, city_name, postal_code, country) AS (
    VALUES
        ('Mokotowska', '15', NULL, 'Warsaw', '00-640', 'PL'),
        ('Dluga', '8',  '12A', 'Krakow', '31-146', 'PL'),
        ('Piekna', '22', NULL, 'Gdansk', '80-001', 'PL')
)
INSERT INTO clinical.addresses (street_name, building_no, flat_no, city_name, postal_code, country)
SELECT
    na.street_name,
    na.building_no,
    na.flat_no,
    na.city_name,
    na.postal_code,
    na.country
FROM new_addresses na
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.addresses addr
    WHERE addr.street_name = na.street_name
      AND addr.building_no = na.building_no
      AND (
            (addr.flat_no IS NULL AND na.flat_no IS NULL)
         OR (addr.flat_no = na.flat_no)
      )
      AND addr.city_name = na.city_name
      AND addr.postal_code = na.postal_code
      AND addr.country = na.country
);

-- ============================================================
-- Table: clinical.sites
-- Purpose: seed study sites (FK -> addresses)
-- ============================================================

WITH new_sites(
    street_name, building_no, flat_no, city_name, postal_code, country,
    site_name, site_phone, site_email
) AS (
    VALUES
        ('Mokotowska','15',NULL,'Warsaw','00-640','PL', 'Site 1', '+48 22 700 1000', 'site1@example.org'),
        ('Dluga','8','12A','Krakow','31-146','PL', 'Site 2', '+48 12 300 2000', 'site2@example.org')
)
INSERT INTO clinical.sites (address_id, site_name, site_phone, site_email)
SELECT
    addr.address_id,
    ns.site_name,
    ns.site_phone,
    ns.site_email
FROM new_sites ns
JOIN clinical.addresses addr
  ON addr.street_name = ns.street_name
 AND addr.building_no = ns.building_no
 AND ( (addr.flat_no IS NULL AND ns.flat_no IS NULL) OR addr.flat_no = ns.flat_no )
 AND addr.city_name = ns.city_name
 AND addr.postal_code = ns.postal_code
 AND addr.country = ns.country
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.sites site
    WHERE site.site_email = ns.site_email
);

-- ============================================================
-- Table: clinical.investigators
-- Purpose: seed investigators (FK -> addresses)
-- ============================================================

WITH new_investigators(
    street_name, building_no, flat_no, city_name, postal_code, country,
    investigator_first_name, investigator_last_name,
    investigator_phone, investigator_email, institution, additional_info
) AS (
    VALUES
        ('Mokotowska','15',NULL,'Warsaw','00-640','PL',
         'Anna','Nowak',
         '+48 22 555 0101','anna.nowak@example.org',
         'Medical Center','Principal Investigator'),

        ('Dluga','8','12A','Krakow','31-146','PL',
         'Jan','Kowalski',
         '+48 12 555 0202','jan.kowalski@example.org',
         'Clinical Hospital','Sub-Investigator'),

        ('Piekna','22',NULL,'Gdansk','80-001','PL',
         'Ewa','Zielinska',
         '+48 58 555 0303','ewa.zielinska@example.org',
         'Research Institute','Study Coordinator')
)
INSERT INTO clinical.investigators (
    address_id,
    investigator_first_name, investigator_last_name,
    investigator_phone, investigator_email,
    institution, additional_info
)
SELECT
    addr.address_id,
    ni.investigator_first_name,
    ni.investigator_last_name,
    ni.investigator_phone,
    ni.investigator_email,
    ni.institution,
    ni.additional_info
FROM new_investigators ni
JOIN clinical.addresses addr
  ON addr.street_name = ni.street_name
 AND addr.building_no = ni.building_no
 AND ( (addr.flat_no IS NULL AND ni.flat_no IS NULL) OR addr.flat_no = ni.flat_no )
 AND addr.city_name = ni.city_name
 AND addr.postal_code = ni.postal_code
 AND addr.country = ni.country
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.investigators inv
    WHERE inv.investigator_email = ni.investigator_email
);

-- ============================================================
-- Table: clinical.studies
-- Purpose: seed clinical studies (independent entities)
-- ============================================================

WITH new_studies(
    study_code, study_title, study_phase, start_date, end_date, study_status
) AS (
    VALUES
        ('CT-001', 'Hypertension Study', 'II', DATE '2025-01-10', NULL, 'Ongoing'),
        ('CT-002', 'Diabetes Study', 'III', DATE '2024-06-01', NULL, 'Ongoing'),
        ('CT-003', 'Obesity Study', 'I', DATE '2023-03-15', DATE '2024-12-31', 'Closed')
)
INSERT INTO clinical.studies (
    study_code, study_title, study_phase, start_date, end_date, study_status
)
SELECT
    ns.study_code,
    ns.study_title,
    ns.study_phase,
    ns.start_date,
    ns.end_date,
    ns.study_status
FROM new_studies ns
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.studies st
    WHERE st.study_code = ns.study_code
);

-- ============================================================
-- Table: clinical.treatment_arms
-- Purpose: define treatment arms per study (FK -> studies)
-- ============================================================

WITH new_treatment_arms(
    study_code, arm_code, arm_name, arm_type, is_blinded
) AS (
    VALUES
        ('CT-001', 'A', 'Active Drug', 'Active',  TRUE),
        ('CT-001', 'P', 'Placebo', 'Placebo', TRUE),
        ('CT-002', 'A', 'Active Drug', 'Active',  FALSE)
)
INSERT INTO clinical.treatment_arms (
    study_id, arm_code, arm_name, arm_type, is_blinded
)
SELECT
    st.study_id,
    nta.arm_code,
    nta.arm_name,
    nta.arm_type,
    nta.is_blinded
FROM new_treatment_arms nta
JOIN clinical.studies st
  ON st.study_code = nta.study_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.treatment_arms arm
    WHERE arm.study_id = st.study_id
      AND arm.arm_code = nta.arm_code
);

-- ============================================================
-- Table: clinical.study_sites
-- Purpose: link studies with sites and optional PI (FK -> studies, sites, investigators)
-- ============================================================

WITH new_study_sites(
    study_code, site_email, pi_email, site_code
) AS (
    VALUES
        ('CT-001', 'site1@example.org', 'anna.nowak@example.org', 'WAW-01'),
        ('CT-001', 'site2@example.org', 'jan.kowalski@example.org', 'KRK-01'),
        ('CT-002', 'site1@example.org', 'ewa.zielinska@example.org', 'WAW-02')
)
INSERT INTO clinical.study_sites (study_id, site_id, pi_id, site_code)
SELECT
    st.study_id,
    site.site_id,
    inv.investigator_id,
    nss.site_code
FROM new_study_sites nss
JOIN clinical.studies st
  ON st.study_code = nss.study_code
JOIN clinical.sites site
  ON site.site_email = nss.site_email
JOIN clinical.investigators inv
  ON inv.investigator_email = nss.pi_email
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.study_sites ss
    WHERE ss.study_id = st.study_id
      AND ss.site_id = site.site_id
);

-- ============================================================
-- Table: clinical.subjects
-- Purpose: seed study subjects per study site (FK -> study_sites)
-- ============================================================

WITH new_subjects(
    study_code, site_code,
    subject_code, screening_date, enrollment_date, status
) AS (
    VALUES
        ('CT-001', 'WAW-01', 'SUBJ-001', DATE '2025-01-15', DATE '2025-01-20', 'Enrolled'),
        ('CT-001', 'WAW-01', 'SUBJ-002', DATE '2025-01-16', NULL, 'Screened'),
        ('CT-001', 'KRK-01', 'SUBJ-003', DATE '2025-01-18', DATE '2025-01-25', 'Randomized'),
        ('CT-002', 'WAW-02', 'SUBJ-004', DATE '2024-06-10', DATE '2024-06-15', 'Enrolled')
)
INSERT INTO clinical.subjects (
    study_site_id, subject_code, screening_date, enrollment_date, status
)
SELECT
    ss.study_site_id,
    ns.subject_code,
    ns.screening_date,
    ns.enrollment_date,
    ns.status
FROM new_subjects ns
JOIN clinical.studies st
  ON st.study_code = ns.study_code
JOIN clinical.study_sites ss
  ON ss.study_id = st.study_id
 AND ss.site_code = ns.site_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.subjects subj
    WHERE subj.study_site_id = ss.study_site_id
      AND subj.subject_code = ns.subject_code
);

-- ============================================================
-- Table: clinical.randomization
-- Purpose: assign enrolled subjects to treatment arms (FK -> subjects, treatment_arms)
-- Notes: one randomization per subject (UNIQUE(subject_id))
-- ============================================================

WITH new_randomization(
    study_code, site_code, subject_code,
    arm_code, randomized_at, randomization_method
) AS (
    VALUES
        ('CT-001', 'WAW-01', 'SUBJ-001', 'A', TIMESTAMPTZ '2025-01-21 10:00:00+01', 'Block'),
        ('CT-001', 'KRK-01', 'SUBJ-003', 'P', TIMESTAMPTZ '2025-01-26 09:30:00+01', 'Simple'),
        ('CT-002', 'WAW-02', 'SUBJ-004', 'A', TIMESTAMPTZ '2024-06-16 11:15:00+02', 'Stratified')
)
INSERT INTO clinical.randomization (subject_id, arm_id, randomized_at, randomization_method)
SELECT
    subj.subject_id,
    arm.arm_id,
    nr.randomized_at,
    nr.randomization_method
FROM new_randomization nr
JOIN clinical.studies st
  ON st.study_code = nr.study_code
JOIN clinical.study_sites ss
  ON ss.study_id = st.study_id
 AND ss.site_code = nr.site_code
JOIN clinical.subjects subj
  ON subj.study_site_id = ss.study_site_id
 AND subj.subject_code = nr.subject_code
JOIN clinical.treatment_arms arm
  ON arm.study_id = st.study_id
 AND arm.arm_code = nr.arm_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.randomization r
    WHERE r.subject_id = subj.subject_id
);

-- ============================================================
-- Table: clinical.visits
-- Purpose: seed subject visits (FK -> subjects)
-- ============================================================

WITH new_visits(
    study_code, site_code, subject_code,
    visit_no, visit_type, visit_date, visit_status, is_locked
) AS (
    VALUES
        ('CT-001', 'WAW-01', 'SUBJ-001', 0, 'Baseline', TIMESTAMP '2025-01-20 09:00:00', 'Completed', FALSE),
        ('CT-001', 'WAW-01', 'SUBJ-001', 4, 'Week4',    TIMESTAMP '2025-02-17 09:15:00', 'Planned',   FALSE),
        ('CT-001', 'KRK-01', 'SUBJ-003', 0, 'Baseline', TIMESTAMP '2025-01-25 10:00:00', 'Completed', TRUE)
)
INSERT INTO clinical.visits (
    subject_id, visit_no, visit_type, visit_date, visit_status, is_locked
)
SELECT
    subj.subject_id,
    nv.visit_no,
    nv.visit_type,
    nv.visit_date,
    nv.visit_status,
    nv.is_locked
FROM new_visits nv
JOIN clinical.studies st
  ON st.study_code = nv.study_code
JOIN clinical.study_sites ss
  ON ss.study_id = st.study_id
 AND ss.site_code = nv.site_code
JOIN clinical.subjects subj
  ON subj.study_site_id = ss.study_site_id
 AND subj.subject_code = nv.subject_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.visits vis
    WHERE vis.subject_id = subj.subject_id
      AND vis.visit_no = nv.visit_no
);

-- ============================================================
-- Table: clinical.measurements
-- Purpose: seed visit measurements (FK -> visits, measurement_types)
-- Notes: exactly one value_* must be provided per row (table CHECK)
-- ============================================================

WITH new_measurements(
    study_code, site_code, subject_code,
    visit_no, measurement_code,
    value_numeric, value_text, value_boolean
) AS (
    VALUES
        ('CT-001', 'WAW-01', 'SUBJ-001', 0, 'SBP', 128.500, NULL, NULL),
        ('CT-001', 'WAW-01', 'SUBJ-001', 0, 'SMOKER', NULL, NULL, TRUE),
        ('CT-001', 'KRK-01', 'SUBJ-003', 0, 'WEIGHT', 82.300, NULL, NULL)
)
INSERT INTO clinical.measurements (
    visit_id, measurement_type_id,
    value_numeric, value_text, value_boolean
)
SELECT
    vis.visit_id,
    mt.measurement_type_id,
    nm.value_numeric,
    nm.value_text,
    nm.value_boolean
FROM new_measurements nm
JOIN clinical.studies st
  ON st.study_code = nm.study_code
JOIN clinical.study_sites ss
  ON ss.study_id = st.study_id
 AND ss.site_code = nm.site_code
JOIN clinical.subjects subj
  ON subj.study_site_id = ss.study_site_id
 AND subj.subject_code = nm.subject_code
JOIN clinical.visits vis
  ON vis.subject_id = subj.subject_id
 AND vis.visit_no = nm.visit_no
JOIN clinical.measurement_types mt
  ON mt.measurement_code = nm.measurement_code
WHERE NOT EXISTS (
    SELECT 1
    FROM clinical.measurements mes
    WHERE mes.visit_id = vis.visit_id
      AND mes.measurement_type_id = mt.measurement_type_id
);

