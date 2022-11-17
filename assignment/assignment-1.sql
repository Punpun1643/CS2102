------------------------------------------------------------------------
------------------------------------------------------------------------
--
-- CS2102 - ASSIGNMENT 1 (SQL)
--
------------------------------------------------------------------------
------------------------------------------------------------------------



DROP VIEW IF EXISTS student, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10;



------------------------------------------------------------------------
-- Replace the dummy values without Student ID & NUSNET ID
------------------------------------------------------------------------


CREATE OR REPLACE VIEW student(student_id, nusnet_id) AS
 SELECT 'XXX', 'XXX'
;






------------------------------------------------------------------------
-- Query Q1
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v1 (area, num_stations) AS
SELECT area, COUNT(*) as num_stations
FROM (
	SELECT m.name, s.area
	FROM subzones AS s
	LEFT JOIN mrt_stations AS m
		ON s.name = m.subzone
	WHERE m.name IS NOT NULL
) as temp
GROUP BY area
HAVING COUNT(*) >= 5
;





------------------------------------------------------------------------
-- Query Q2
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v2 (number, street, distance) AS
SELECT number, street, ROUND(geodistance(1.29271, 103.7754, lat, lng), 2) AS distance
FROM hdb_blocks
LEFT JOIN hdb_has_units
	ON id = block_id
WHERE unit_type = '1room'
ORDER BY distance
LIMIT 10
;





------------------------------------------------------------------------
-- Query 3
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v3 (area, num_blocks) AS
SELECT area, COUNT(*) - (COUNT(*) - COUNT(id)) as num_blocks
FROM (SELECT a.name as area, s.name as subzone_name
FROM areas a
LEFT JOIN subzones s
	ON a.name = area) as area_subzone
LEFT JOIN hdb_blocks 
	ON subzone_name = subzone
GROUP BY (area)
ORDER BY num_blocks DESC
;




------------------------------------------------------------------------
-- Query Q4
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v4 (area) AS
SELECT name AS area
FROM (SELECT a.name AS area, s.name as subzone
	FROM areas a
	LEFT JOIN subzones s
	ON a.name = s.area) as area_subzone
LEFT JOIN mrt_stations m
	ON m.subzone = area_subzone.subzone
WHERE name IS NOT NULL
	AND name IN (SELECT name FROM areas)
	AND area <> name
;




------------------------------------------------------------------------
-- Query Q5
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v5 (mrt_station, num_blocks) AS
WITH LineStation AS (SELECT line, station, lat, lng
FROM mrt_stations m
LEFT JOIN (SELECT line, station 
FROM mrt_stops 
WHERE line = 'ew') as ls
	ON ls.station = m.name
WHERE line IS NOT NULL)
SELECT station as mrt_station, COUNT(*) as num_blocks
FROM LineStation ls, hdb_blocks hb
WHERE geodistance(ls.lat, ls.lng, hb.lat, hb.lng) <= 0.300
GROUP BY (station)
ORDER BY num_blocks DESC
LIMIT 5
;





------------------------------------------------------------------------
-- Query Q6
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v6 (subzone) AS
(SELECT DISTINCT subzone 
FROM hdb_blocks)
EXCEPT
(SELECT subzone
FROM hdb_blocks
LEFT JOIN hdb_has_units
	ON id = block_id
WHERE unit_type = '1room')
;




------------------------------------------------------------------------
-- Query Q7
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v7 (mrt_station) AS
SELECT DISTINCT station as mrt_station
FROM mrt_stops ms2, 
(SELECT to_code as mrt_stations
FROM mrt_connections mc
LEFT JOIN mrt_stops ms
	ON mc.from_code = ms.code
LEFT JOIN mrt_stops ms1
	ON mc.to_code = ms1.code
WHERE ms.line = ms1.line
GROUP BY (to_code)
HAVING COUNT(*) = 1) mrt_code
WHERE ms2.code = mrt_code.mrt_stations
;





------------------------------------------------------------------------
-- Query Q8
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v8 (mrt_station, num_stops) AS
WITH RECURSIVE mrt_path AS (
	SELECT to_code, from_code, 1 AS stops
	FROM mrt_connections
	WHERE to_code = 'cc24'
	UNION ALL
	SELECT mc.to_code, mc.from_code, mp.stops + 1
	FROM mrt_path mp, mrt_connections mc
	WHERE mc.to_code = mp.from_code
	AND mp.stops < 10
),
	CodeStations AS (
		SELECT from_code, min(stops) as num_stops
		FROM mrt_path
		WHERE from_code <> 'cc24'
		GROUP BY from_code
		ORDER BY num_stops ASC
	)
SELECT DISTINCT station as mrt_station, num_stops
FROM mrt_stops
LEFT JOIN CodeStations
	ON mrt_stops.code = CodeStations.from_code
WHERE num_stops IS NOT NULL
ORDER BY num_stops
;





------------------------------------------------------------------------
-- Query Q9
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v9 (subzone, num_blocks) AS
WITH mrtInfo AS (
	SELECT subzone, MIN(opened) as earliest_opened
	FROM mrt_stops
	LEFT JOIN mrt_stations 
		ON mrt_stops.station = mrt_stations.name
	WHERE line = 'dt'
	GROUP BY subzone
), 
mrtQuery AS (
	SELECT mrtInfo.subzone, COUNT(id) as num_blocks
	FROM mrtInfo
	LEFT JOIN hdb_blocks 
		ON hdb_blocks.subzone = mrtInfo.subzone
	WHERE completed >= earliest_opened
	GROUP BY (mrtInfo.subzone)
)
SELECT temp.subzone, COALESCE(num_blocks, 0) as num_blocks
FROM (
	SELECT DISTINCT subzone
	FROM mrt_stations
	WHERE name in (
		SELECT station
		FROM mrt_stops
		WHERE line = 'dt'
	)
) as temp
LEFT JOIN mrtQuery
ON temp.subzone = mrtQuery.subzone
;






------------------------------------------------------------------------
-- Query Q10
------------------------------------------------------------------------

CREATE OR REPLACE VIEW v10 (stop_code) AS
WITH t1 AS (
SELECT code, line, CAST(SUBSTRING(code, 3, 2) AS INT) as code_id
FROM mrt_stops),
	t2 AS (
		SELECT line, GENERATE_SERIES(1, max(temp_table.code_id)) as last_id
		FROM (
			SELECT code, line, CAST(SUBSTRING(code, 3, 2) AS INT) as code_id
			FROM mrt_stops
		) as temp_table
		GROUP BY (line)
	)
SELECT CONCAT(lol.line, last_id) as stop_code
FROM t2 as lol
LEFT JOIN t1
	ON t1.line = lol.line
	AND lol.last_id = t1.code_id
WHERE t1.code IS NULL
;
