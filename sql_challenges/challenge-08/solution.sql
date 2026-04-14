-- EXERCISE 1: Low Cardinality (No index)
SELECT * FROM patient_visits WHERE site_id = 3;



-- EXERCISE 2: Creating a Range Index
CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits WHERE visit_date BETWEEN SYSDATE - 7 AND SYSDATE;

SELECT * FROM patient_visits WHERE visit_date BETWEEN SYSDATE - 700 AND SYSDATE;



-- EXERCISE 3: Composite Index (Order: patient_id, then visit_date)
CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

SELECT * FROM patient_visits WHERE patient_id = 1234 AND visit_date > SYSDATE - 90;

SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;



-- EXERCISE 4: The Function Trap
SELECT * FROM patient_visits WHERE patient_id = 5432;

SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';