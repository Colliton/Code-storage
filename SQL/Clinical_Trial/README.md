# Clinical Trial Database (PostgreSQL)

This folder contains a complete example of a **Clinical Trial relational database**
designed and implemented in PostgreSQL.  
The project demonstrates database modeling, SQL development, data validation,
access control, and analytical querying in a realistic clinical data domain.

The contents are organized as a **step-by-step database lifecycle**, from conceptual
design to analytical queries and quality checks.

---

## Project scope

The database models core clinical trial concepts, including:
- studies and study sites
- subjects and visits
- measurements and visit outcomes
- randomization and treatment arms

The project focuses on:
- clean relational design
- readable, maintainable SQL
- separation of concerns (DDL, logic, security, analytics)
- portfolio-ready documentation and examples

---

## Folder contents (execution order)

### 01–02: Data modeling (documentation)
- **01_Clinical_Trial_Conceptual_Model.png**  
  High-level conceptual ER model (entities and relationships).

- **02_Clinical_Trial_Logical_Model.png**  
  Logical data model with attributes, keys, and cardinalities.

---

### 03: Physical model (DDL)
- **03_Clinical_Trial_Physical_Model_DDL.sql**  
  Creates schemas, tables, primary/foreign keys, constraints, and indexes.

---

### 04: Sample data
- **04_Clinical_Trial_Inserts.sql**  
  Example INSERT statements used to populate the database
  for development, testing, and demonstration purposes.

---

### 05: Functions and triggers
- **05_Clinical_Trial_Functions_Triggers.sql**  
  PL/pgSQL functions and triggers implementing business logic,
  validations, and derived behavior.

---

### 06: Reporting views
- **06_Clinical_Trial_Views.sql**  
  Read-only reporting views used for analytics and downstream queries.
  Views encapsulate joins and domain logic to simplify consumption.

---

### 07: Roles and privileges
- **07_Clinical_Trial_Roles_Privileges.sql**  
  Role-based access control setup:
  - read-only reporting role
  - read-write application role
  - explicit privilege grants
  - default privileges for future objects

---

### 08–09: Tests
- **08_Clinical_Trial_Functions_Tests.sql**  
  Validation queries and sanity checks for database functions.

- **09_Clinical_Trial_Views_Tests.sql**  
  Validation queries to verify correctness and assumptions of reporting views.

---

### 10: Row-Level Security (optional)
- **10_Clinical_Trial_RLS.sql**  
  Optional Row-Level Security (RLS) example demonstrating
  site-based data access restrictions using session parameters.
  
  Included mainly for portfolio and learning purposes.

---

### 11: Analytical queries
- **11_Clinical_Trial_Analytical_Queries.sql**  
  A collection of example analytical SELECT queries built on top of the database.

  Demonstrated techniques include:
  - CTEs
  - correlated and non-correlated subqueries
  - EXISTS / NOT EXISTS patterns
  - window functions (ROW_NUMBER, LAG, aggregates)
  - window frames (ROWS)
  - conditional aggregation (FILTER)
  - data quality checks (QC-style reports)

  All queries are **read-only** and intended for exploration,
  reporting, and portfolio demonstration.

---

## Design principles

- PostgreSQL-focused SQL
- Clear separation between:
  - schema definition
  - business logic
  - security
  - analytics
- Readability over cleverness
- Explicit naming and documentation
- Predictable query output (ORDER BY where applicable)

---

## Notes

- This project is intended for **learning and portfolio demonstration**.
- It does not assume any specific application framework.
- All analytical queries are non-destructive (SELECT only).
- Sample data is illustrative and not based on real clinical data.

---

## Suggested execution order

For a clean setup, run scripts in numerical order:

1. 03 – Physical model (DDL)
2. 04 – Inserts
3. 05 – Functions & triggers
4. 06 – Views
5. 07 – Roles & privileges
6. 08–09 – Tests
7. 10 – RLS (optional)
8. 11 – Analytical queries
