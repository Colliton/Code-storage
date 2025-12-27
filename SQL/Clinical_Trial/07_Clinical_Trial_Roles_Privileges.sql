/*
Clinical Trial Database – Roles & Privileges

Purpose:
Defines role-based access control for the Clinical Trial database.
Separates read-only reporting access from write-capable application access.

Execution order:
- Run AFTER all core objects are created:
  - DB, schema, tables with constrains: 03_Clinical_Trial_Physical_Model_DDL.sql
  - functions and triggers: 05_Clinical_Trial_Functions_Triggers.sql & 08_Clinical_Trial_Functions_Tests.sql
  - views: 06_Clinical_Trial_Views.sql & 09_Clinical_Trial_Views_Tests.sql

Assumptions:
- All objects are located in the 'clinical' schema
- Views are used for reporting and analytics
- Functions encapsulate business logic
*/


/*
0. Roles (created only if they do not already exist)
- clinical_ro  : reporting / analytics access
- clinical_rw  : application-level read-write access
*/

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clinical_ro') THEN
        CREATE ROLE clinical_ro
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOLOGIN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clinical_rw') THEN
        CREATE ROLE clinical_rw
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOLOGIN;
    END IF;
END $$;

/*
1. Schema privileges 
Allow roles to access objects inside the clinical schema
 */

GRANT USAGE ON SCHEMA clinical TO clinical_ro, clinical_rw;

/*
2. Table & View privileges
Views are included in TABLE privileges
*/

-- Read-only role: reporting / analytics
GRANT SELECT ON ALL TABLES IN SCHEMA clinical TO clinical_ro;

-- Read-write role: application-level DML
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA clinical
TO clinical_rw;

/*
3. Sequence privileges
Required for SERIAL / IDENTITY columns
*/

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA clinical
TO clinical_rw;

-- Optional for reporting (e.g. debugging, audits)
GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA clinical
TO clinical_ro;

/*
4. Function privileges
Functions act as the database API
*/

GRANT EXECUTE
ON ALL FUNCTIONS IN SCHEMA clinical
TO clinical_ro, clinical_rw;

/*
5. Default privileges (for future objects)
IMPORTANT:
Must be executed by the role that owns schema objects
*/

ALTER DEFAULT PRIVILEGES IN SCHEMA clinical
GRANT SELECT ON TABLES TO clinical_ro;

ALTER DEFAULT PRIVILEGES IN SCHEMA clinical
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO clinical_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA clinical
GRANT USAGE, SELECT ON SEQUENCES TO clinical_ro, clinical_rw;

ALTER DEFAULT PRIVILEGES IN SCHEMA clinical
GRANT EXECUTE ON FUNCTIONS TO clinical_ro, clinical_rw;

/*
6. Role hierarchy
RW implicitly includes RO privileges
*/

GRANT clinical_ro TO clinical_rw;

/*
7. Application / Reporting users (LOGIN roles)
NOTE:
Passwords are placeholders and should be set per environment.
*/

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clinical_app_user') THEN
        CREATE ROLE clinical_app_user
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            PASSWORD 'CHANGE_ME';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'clinical_report_user') THEN
        CREATE ROLE clinical_report_user
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            PASSWORD 'CHANGE_ME';
    END IF;
END $$;

/*
8. Assign roles to users
*/

GRANT clinical_rw TO clinical_app_user;
GRANT clinical_ro TO clinical_report_user;

/*
9. Database & schema access for login users
 */

GRANT CONNECT ON DATABASE clinical_trial
TO clinical_app_user, clinical_report_user;

GRANT USAGE ON SCHEMA clinical
TO clinical_app_user, clinical_report_user;

/*
10. Explicit revokes (defensive / least privilege)
Purpose:
Ensure roles do not have unintended privileges inherited
from PUBLIC or previous grants.
*/

REVOKE ALL ON DATABASE clinical_trial FROM PUBLIC;
REVOKE ALL ON SCHEMA clinical FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA clinical FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA clinical FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA clinical FROM PUBLIC;

/*
Optional (educational):
- Explicitly revoke write privileges from read-only role
if such privileges were ever granted in the future.

REVOKE INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA clinical
FROM clinical_ro;

- Deny write-functions to reporting role (example)

REVOKE EXECUTE 
ON FUNCTION clinical.some_write_function(...) 
FROM clinical_ro;

*/