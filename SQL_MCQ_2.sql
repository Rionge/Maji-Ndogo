
USE md_water_services;
SET SQL_SAFE_UPDATES = 0;

-- updating the employee emails.
SELECT CONCAT(LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email 
FROM employee;

-- adding the new emails 
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),'@ndogowater.gov')

SELECT *
FROM employee;

-- getting to know the length of employee phone numbers so as to know if their is a blank before or after the number.
SELECT LENGTH(phone_number)
FROM employee;

-- TRIM THE COLUMN
SELECT LTRIM(RTRIM(phone_number)) 
FROM employee;

-- getting the number of employees that live in each town.
SELECT town_name, COUNT(assigned_employee_id) AS num_of_employees
FROM employee
GROUP BY town_name;

-- number of records each employee collected
SELECT assigned_employee_id, COUNT(*) AS number_of_visits
FROM visits
GROUP BY assigned_employee_id
ORDER BY number_of_visits ASC
LIMIT 3;

-- number of records per towns
SELECT town_name, COUNT(*) AS records_per_town
FROM location
GROUP BY town_name
ORDER BY records_per_town DESC;

-- number of records per province
SELECT province_name, COUNT(*) AS records_per_province
FROM location
GROUP BY province_name
ORDER BY records_per_province DESC;

-- town name x province name combo
SELECT province_name, town_name, COUNT(town_name) AS records_per_town
FROM location
GROUP BY province_name, town_name 
ORDER BY  province_name, records_per_town DESC;

-- number of records for each location types
SELECT location_type, COUNT(*) AS num_sources
FROM location
GROUP BY location_type;

-- total number of people surveyed
SELECT COUNT(number_of_people_served) AS number_of_people_surveyed
FROM water_source

-- total number of distinct water sources
SELECT type_of_water_source,
	COUNT(type_of_water_source) AS number_of_water_source_type
FROM water_source
GROUP BY type_of_water_source
ORDER BY number_of_water_source_type DESC;

-- AVERAGE NUMBER OF PEOPLE SERVED BY EACH WATER SOURCE
SELECT type_of_water_source, ROUND(AVG(number_of_people_served)) AS avg_ppl_per_source
FROM water_source
GROUP BY type_of_water_source

-- total number of population served per water source
SELECT type_of_water_source, SUM(number_of_people_served) AS population_served
FROM water_source
GROUP BY type_of_water_source
ORDER BY population_served DESC;

-- percetage population served per water source
SELECT type_of_water_source, 
	ROUND((SUM(number_of_people_served)/27628140)*100) AS percentage_ppl_per_source
FROM water_source
GROUP BY type_of_water_source
ORDER BY percentage_ppl_per_source DESC;

-- rank based on total people served
SELECT type_of_water_source, SUM(number_of_people_served) AS pop_number_of_people_served, 
RANK() OVER(ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population
FROM water_source
WHERE type_of_water_source != 'tap_in_home'
GROUP BY type_of_water_source
ORDER BY pop_number_of_people_served DESC
;

-- finding the most used sources
SELECT source_id, type_of_water_source, SUM(number_of_people_served) AS pop_number_of_people_served, 
DENSE_RANK() OVER(ORDER BY SUM(number_of_people_served) DESC) AS priority_rank
FROM water_source
WHERE type_of_water_source != 'tap_in_home'
GROUP BY type_of_water_source, source_id
ORDER BY pop_number_of_people_served DESC
;

-- duration of survey
SELECT	DATEDIFF ('2023-07-14 13:53:00', '2021-01-01 9:10:00') AS Survey_duration
FROM 	md_water_services.visits;

-- average time it takes to queue for water
SELECT  AVG(NULLIF(time_in_queue,  0)) AS Average_time_in_queue
FROM md_water_services.visits
ORDER BY time_in_queue
;

-- average time on different days it takes to queue for water
SELECT  DAYNAME(time_of_record) AS Day_Name,
		AVG(NULLIF(time_in_queue,  0)) AS Average_time_in_queue
FROM md_water_services.visits
GROUP BY Day_Name
ORDER BY Day_Name;

-- average time on different hours it takes to queue for water
SELECT  TIME_FORMAT(TIME(time_of_record), '%H:00') AS Hour_of_record,
		AVG(NULLIF(time_in_queue,  0)) AS Average_time_in_queue
FROM md_water_services.visits
GROUP BY Hour_of_record
ORDER BY Hour_of_record;


-- average queue times for each hour in each day.
SELECT
	TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    
	-- Sunday
    	ROUND(AVG(
    CASE
		WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
		ELSE NULL
	END),0) AS Sunday,
    
-- Monday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Monday,

-- Tuesday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Tuesday,

-- Wednesday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Wednesday,

-- Thursday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Thursday,

-- Friday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Friday,

-- Saturday
	ROUND(AVG(
	CASE
	WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
	ELSE NULL
	END), 0) AS Saturday

FROM
visits
WHERE
time_in_queue != 0
GROUP BY hour_of_day
ORDER BY hour_of_day
; 

