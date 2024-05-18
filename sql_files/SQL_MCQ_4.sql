USE md_water_services;

-- joining peaces together.
-- 1. Are there any specific provinces, or towns where some sources are more abundant?

SELECT 
	l.province_name,
    l.town_name,
    v.visit_count,
    l.location_id,
    ws.type_of_water_source,
    ws.number_of_people_served
FROM
	location AS l
JOIN
	visits AS v
    ON l.location_id = v.location_id
JOIN 
	water_source AS ws
	ON ws.source_id = v.source_id
WHERE v.visit_count = 1;

-- we drop the location_id and the visit_count after veirfying the data has been loaded correctly.
-- add location_type and time_in_queue
-- add well_polution results with a left join to join the results from the well polution table from the well sources and null for all the rest (from 17383 rows to 39650) 

SELECT 
	l.province_name,
    l.town_name,
    l.location_type,
    ws.type_of_water_source,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
	location AS l
JOIN
	visits AS v
    ON l.location_id = v.location_id
JOIN 
	water_source AS ws
	ON ws.source_id = v.source_id
LEFT JOIN
	well_pollution AS wp
    ON wp.source_id = v.source_id
WHERE v.visit_count = 1;


--  This view assembles data from different tables into one to simplify analysis

CREATE VIEW combined_analysis_table AS
SELECT 
	l.province_name,
    l.town_name,
    l.location_type,
    ws.type_of_water_source,
    ws.number_of_people_served,
    v.time_in_queue,
    wp.results
FROM
	location AS l
JOIN
	visits AS v
    ON l.location_id = v.location_id
JOIN 
	water_source AS ws
	ON ws.source_id = v.source_id
LEFT JOIN
	well_pollution AS wp
    ON wp.source_id = v.source_id
WHERE v.visit_count = 1;

-- call view
SELECT *
FROM combined_analysis_table;


/* The last analysis
We're building another pivot table! This time, we want to break down our data into provinces or towns and source types. If we understand where
the problems are, and what we need to improve at those locations, we can make an informed decision on where to send our repair teams.
*/
WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
	province_name,
	SUM(number_of_people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
	ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE WHEN type_of_water_source = 'river'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
ROUND((SUM(CASE WHEN type_of_water_source = 'well'
THEN number_of_people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
combined_analysis_table ct
JOIN
province_totals pt ON ct.province_name = pt.province_name
GROUP BY
ct.province_name
ORDER BY
ct.province_name;


-- A table of province names and summed up populations for each province.

WITH province_totals AS (-- This CTE calculates the population of each province
SELECT
	province_name,
	SUM(number_of_people_served) AS total_ppl_serv
FROM
combined_analysis_table
GROUP BY
province_name
)
SELECT
*
FROM
province_totals;


/* there are two towns in Maji Ndogo called Harare. One is in Akatsi, and one is in Kilimani. Amina is another example. 
To get around that, we have to group by province first, then by town, so that the duplicate towns are distinct because they are in different towns.
*/
/* create a temporary table to store the results of this complex querry as it takes longer to run */

-- CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS ( -- This CTE calculates the population of each town
-- Since there are two Harare towns, we have to group by province_name and town_name
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)
SELECT
	ct.province_name,
	ct.town_name,
	ROUND((SUM(CASE WHEN type_of_water_source = 'river'
	THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
	ROUND((SUM(CASE WHEN type_of_water_source = 'shared_tap'
	THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home'
	THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
	ROUND((SUM(CASE WHEN type_of_water_source = 'tap_in_home_broken'
	THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
	ROUND((SUM(CASE WHEN type_of_water_source = 'well'
	THEN number_of_people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
	combined_analysis_table ct
JOIN -- Since the town names are not unique, we have to join on a composite key
	town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY -- We group by province first, then by town.
	ct.province_name,
	ct.town_name
ORDER BY
	ct.town_name;

SELECT *
FROM town_aggregated_water_access
ORDER BY province_name DESC


-- to see which town has the highest ratio of people who have taps, but have no running water?

SELECT
	province_name,
	town_name,
	ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) *100,0) AS Pct_broken_taps
FROM
	town_aggregated_water_access;


-- might seem complex bt that's only because of the comments.

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY,
/* Project_id −− Unique key for sources in case we visit the same
source more than once in the future. */
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
/* source_id −− Each of the sources we want to improve should exist,
and should refer to the source table. This ensures data integrity. */
Address VARCHAR(50), -- Street address
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
/* Source_status −− We want to limit the type of information engineers can give us, so we
limit Source_status.
− By DEFAULT all projects are in the "Backlog" which is like a TODO list.
− CHECK() ensures only those three options will be accepted. This helps to maintain clean data.
*/
Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);



-- Project_progress_query
-- First things first, let's filter the data to only contain sources we want to improve

SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
	well_pollution.results
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE
	visits.visit_count = 1
    AND ( -- AND one of the following (OR) options must be true as well.
	well_pollution.results != 'Clean'
	OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
	OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
	)


-- Project_progress_query
-- get the neccessary table to take action.

SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
	well_pollution.results,
    CASE
    WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV filter'
    WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter' 
    WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'  
    WHEN type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby") 
    ELSE 'Diagnose local infrastructure'  END AS Improvements
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE
	visits.visit_count = 1
    AND ( -- AND one of the following (OR) options must be true as well.
	well_pollution.results != 'Clean'
	OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
	OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
	);



-- insert data into our Project_progress table.
-- the table 

INSERT INTO Project_progress(Address, Town, Province, source_id, Source_type, Improvement)
SELECT
	location.address,
	location.town_name,
	location.province_name,
	water_source.source_id,
	water_source.type_of_water_source,
    CASE
    WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV filter'
    WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter' 
    WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'  
    WHEN type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby") 
    ELSE 'Diagnose local infrastructure'  END AS Improvements
FROM
	water_source
LEFT JOIN
	well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
	visits ON water_source.source_id = visits.source_id
INNER JOIN
	location ON location.location_id = visits.location_id
WHERE
	visits.visit_count = 1
    AND ( -- AND one of the following (OR) options must be true as well.
	well_pollution.results != 'Clean'
	OR water_source.type_of_water_source IN ('tap_in_home_broken','river')
	OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
	);
    
    
  -- VIEW the table Project_progress
  
SELECT distinct COUNT(*)
FROM Project_progress
WHERE Improvement = 'Install UV filter';

SELECT distinct *
FROM Project_progress;
