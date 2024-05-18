DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

SELECT *
FROM auditor_report;

SELECT location_id, true_water_source_score
FROM auditor_report;

-- Joining the visit table to the auditor_report table
SELECT 
	ar.location_id AS audit_location, 
	ar.true_water_source_score, 
    v.record_id, 
    v.location_id AS visit_location
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id

-- join auditor_report, visits, water_quality table to view the subjective_quality_score
-- make sure the audit_score and the employee_score match via the where clause = 1518 cases (94%)
-- make sure the audit_score and the employee_score have a missmatch via the where clause = 102 cases
SELECT 
	ar.location_id AS location, 
	ar.true_water_source_score AS auditor_score, 
    v.record_id, 
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1;

-- getting to check if the type of water source has an error affecting our data intergrity
SELECT 
	ar.location_id AS location, 
	ar.true_water_source_score AS auditor_score, 
    v.record_id, 
    wq.subjective_quality_score AS employee_score,
    ws.type_of_water_source AS survey_source,
    ar.type_of_water_source AS auditor_source
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN water_source AS ws
ON ws.source_id = v.source_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1;

-- considering that this errors are man made, let's fetch their details
-- making it a CTE for later reference
WITH Incorrect_records AS (
SELECT 
	ar.location_id AS location, 
    v.record_id, 
    e.employee_name,
    ar.true_water_source_score AS auditor_score, 
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN employee AS e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1
)
 SELECT * 
 FROM Incorrect_records;

-- get names of each employee in CTE and how many times they messed up
-- create a CTE known as error_count to store this
WITH error_count AS(
WITH Incorrect_records AS (
SELECT 
	ar.location_id AS location, 
    v.record_id, 
    e.employee_name,
    ar.true_water_source_score AS auditor_score, 
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN employee AS e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1)
SELECT DISTINCT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC)
SELECT *
FROM error_count;


-- calculate the average number of mistakes employees made.
WITH error_count AS(
WITH Incorrect_records AS (
SELECT 
	ar.location_id AS location, 
    v.record_id, 
    e.employee_name,
    ar.true_water_source_score AS auditor_score, 
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN employee AS e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1)
SELECT DISTINCT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC)
SELECT AVG(number_of_mistakes) AS avg_error_count_per_empl
FROM error_count;

-- Finaly we have to compare each employee's error_count with avg_error_count_per_empl.
WITH error_count AS(
WITH Incorrect_records AS (
SELECT 
	ar.location_id AS location, 
    v.record_id, 
    e.employee_name,
    ar.true_water_source_score AS auditor_score, 
    wq.subjective_quality_score AS employee_score
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN employee AS e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1)
SELECT DISTINCT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name
ORDER BY number_of_mistakes DESC)
SELECT employee_name,  number_of_mistakes
FROM error_count
WHERE number_of_mistakes > 6;


-- Converting the Incorect records to a view to make the query more readable
/*
Incorrect_records is a view that joins the audit report to the database
for records where the auditor and
employees scores are different
*/
CREATE VIEW Incorrect_records AS (
SELECT 
	ar.location_id AS location, 
    v.record_id, 
    e.employee_name,
    ar.true_water_source_score AS auditor_score, 
    wq.subjective_quality_score AS employee_score,
    ar.statements AS statements
FROM auditor_report AS ar
JOIN visits AS v
ON v.location_id = ar.location_id
JOIN water_quality AS wq
ON wq.record_id = v.record_id
JOIN employee AS e
ON e.assigned_employee_id = v.assigned_employee_id
WHERE wq.subjective_quality_score != ar.true_water_source_score 
AND v.visit_count = 1);

SELECT * 
FROM Incorrect_records;


-- Create error_count as a CTE

WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
SELECT * 
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count);


-- create suspect_list as a CTE of the suspected employees

WITH suspect_list AS(
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
SELECT * 
FROM error_count
WHERE number_of_mistakes > 6)
SELECT employee_name 
FROM suspect_list


-- Filter the records that refer to "cash".

WITH suspect_list AS(
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
SELECT * 
FROM error_count
WHERE number_of_mistakes > 6)
SELECT employee_name, location, statements
FROM Incorrect_records
WHERE employee_name  IN (
SELECT employee_name 
FROM suspect_list
WHERE statements LIKE '%cash%'); 


-- Check if there are any employees in the Incorrect_records table with statements mentioning "cash" 
-- that are not in our suspect list.

WITH suspect_list AS(
WITH error_count AS ( 
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
SELECT * 
FROM error_count
WHERE number_of_mistakes > 6)
SELECT employee_name, location, statements
FROM Incorrect_records
WHERE employee_name  IN (
SELECT employee_name 
FROM suspect_list
WHERE statements LIKE '%cash%'
	AND employee_name NOT IN (SELECT employee_name FROM suspect_list)
    )