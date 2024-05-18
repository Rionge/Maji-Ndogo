USE md_water_services;
SET SQL_SAFE_UPDATES = 0;

-- get list of all tables in the database
show tables;

-- get a lay of the data before analysis begins
SELECT * FROM data_dictionary;
SELECT * FROM location;
SELECT * FROM visits;
SELECT * FROM water_source;
SELECT * FROM water_quality;
SELECT * FROM well_pollution;

-- get the types of water sources in our data
SELECT DISTINCT type_of_water_source
FROM water_source;

-- record of time spent in queue for more than 8 hours
SELECT * 
FROM visits
WHERE time_in_queue > 500;

-- check the type of water sources from the data obtained in the querry above
SELECT * 
FROM water_source
WHERE source_id IN ('AkKi00881224', 'AkLu01628224', 'AkRu05234224', 'HaRu19601224', 'HaZa21742224', 'SoRu36096224', 'SoRu37635224', 'SoRu38776224');

-- 
SELECT *
FROM water_quality
WHERE subjective_quality_score = 10 AND visit_count = 2;

-- when the polutant ppm is > 0.01 the results should indicate Biological Contaminated. Let's check if that is the case
SELECT * 
FROM well_pollution
WHERE results = 'Clean' AND pollutant_ppm >= 0.01;

-- the data from our above querry seems to have been recorded incorectly as it does not follow logic
-- case 1a
UPDATE well_pollution
SET description = 'Bacteria: E. coli'
WHERE description = 'Clean Bacteria: E. coli';

-- case 1b
UPDATE well_pollution
SET description = 'Bacteria: Giardia Lamblia'
WHERE description = 'Clean Bacteria: Giardia Lamblia';

-- case 2
UPDATE well_pollution
SET results = 'Contaminated: Biological'
WHERE biological > 0.1 AND results = 'Clean';


-- check if there are any errors made in the process
SELECT *
FROM well_pollution
WHERE description LIKE 'clean_%' 
OR (results = 'Clean' AND biological > 0.01);

-- 
