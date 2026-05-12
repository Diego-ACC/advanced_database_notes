-- ==========================================================
-- ORACLE SCHEMA INVESTIGATION LOG (FREESQL ENVIRONMENT)
-- PROJECT: Schema exploration and DDL reconstruction
-- ==========================================================

-- ----------------------------------------------------------
-- EXERCISE 1: Explore the shared schema (HR)
-- ----------------------------------------------------------
-- Counting objects available in the HR schema
SELECT object_type, COUNT(*) AS cnt
FROM all_objects
WHERE owner = 'HR'
GROUP BY object_type
ORDER BY object_type;

-- ----------------------------------------------------------
-- EXERCISE 2 & 3: Manual DDL Reconstruction (Column Definitions)
-- Since DBMS_METADATA.GET_DDL was restricted, we query metadata directly.
-- ----------------------------------------------------------
-- Inspecting table structure for 'EMPLOYEES'
SELECT column_name, data_type, data_length, nullable
FROM all_tab_columns
WHERE owner = 'HR' AND table_name = 'EMPLOYEES'
ORDER BY column_id;

-- ----------------------------------------------------------
-- EXERCISE 4: Constraint Investigation (For Migration Planning)
-- Identifying Primary Keys and Foreign Keys
-- ----------------------------------------------------------
SELECT constraint_name, constraint_type, search_condition
FROM all_constraints
WHERE owner = 'HR' AND table_name = 'EMPLOYEES';

-- ----------------------------------------------------------
-- EXERCISE 5: Dependency Investigation
-- Checking which objects across the database reference HR.EMPLOYEES
-- ----------------------------------------------------------
SELECT owner, name, type
FROM all_dependencies
WHERE referenced_owner = 'HR' 
  AND referenced_name = 'EMPLOYEES'
  AND owner != 'HR';

-- ----------------------------------------------------------
-- EXERCISE 6: Backup Strategy Comments
-- ----------------------------------------------------------
/*
   STRATEGY FOR RESTRICTED ENVIRONMENTS:
   1. Use ALL_TABLES and ALL_TAB_COLUMNS to map data structures.
   2. Use ALL_CONSTRAINTS to map relationships.
   3. Manually script CREATE TABLE statements based on metadata if GET_DDL is ORA-01031.
   4. Export data via CSV/Insert statements since expdp is unavailable.
*/