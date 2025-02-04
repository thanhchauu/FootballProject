


--- USE
-- Using the correct database
USE FootballDB;



--- SELECT___FROM
-- Check if all the data is loaded
SELECT * FROM games;
SELECT * FROM leagues;
SELECT * FROM players;
SELECT * FROM shots;
SELECT * FROM teams;
SELECT * FROM teamstats;



--- LIKE and WILDCARDS
-- Players’s name start with ‘Ro’ and end with ‘I’ 
SELECT 
	*
FROM players
WHERE name like 'Ro%i';



--- COUNT and AS
-- Number of shot by each type
SELECT 
	shot_type,
	COUNT(*) AS number
FROM shots
GROUP BY shot_type;



--- ORDER BY
-- How many yellow cards, red cards each season
SELECT
	season,
	COUNT(yellow_cards) AS count_yellow_cards,
	COUNT(red_cards) AS count_red_cards
FROM teamstats
GROUP BY season
ORDER BY season;



--- JOIN and ALIAS
-- How many games in each league
SELECT 
	l.name,
	COUNT(*) AS match_num
FROM leagues l 
JOIN games g
	ON l.league_id = g.league_id
GROUP BY l.name
ORDER BY match_num



--- DATE FUNCTIONS
-- The number of days the league takes place in each season
SELECT 
    l.name,
    season,
    DATEDIFF(day, MIN(date), MAX(date)) AS date_range
FROM games g
JOIN leagues l 
	ON g.league_id = l.league_id
GROUP BY l.name, season
ORDER BY l.name, season;



--- TOP
-- Top 5 goal scorers   
SELECT TOP 5
	p.name,
	COUNT(*) AS scored_num
FROM players p 
JOIN shots 
	ON player_id = shooter_id
WHERE shot_result = 'Goal'
GROUP BY p.name
ORDER BY scored_num DESC;



--- HAVING
-- Teams have ability to create scoring opportunities and apply high pressure on their opponent's defense.
-- When total deep >= 200
SELECT 
	name,
	COUNT(deep) AS count_apply_pressure
FROM teams t
JOIN teamstats ts
	ON t.team_id = ts.team_id
GROUP BY t.name
HAVING COUNT(deep) >= 200;



--- OFFSET and FETCH
-- Top 5 assist providers, excluding the top 5
SELECT
	p.name,
	COUNT(*) AS assist_num
FROM players p 
LEFT JOIN shots 
	ON player_id = assister_id
WHERE shot_result = 'Goal'
GROUP BY p.name
ORDER BY assist_num DESC
OFFSET 5 ROWS
FETCH NEXT 5 ROWS ONLY;



--- MULTI-TABLE JOIN
-- The match in which goals were scored without assists
SELECT 
    t1.name AS home_team_name,
    t2.name AS away_team_name
FROM 
    games g
JOIN teams t1 
	ON g.home_team_id = t1.team_id
JOIN teams t2 
	ON g.away_team_id = t2.team_id
WHERE 
    g.game_id IN (
        SELECT 
            game_id
        FROM 
            shots
        WHERE 
            assister_id IS NULL
    );



--- CTE
-- Measure a team's pressing intensity and defensive aggression by ppda metric
-- High if it's above 200, Medium if it's between 50 and 200, Low if it's below 50
WITH 
	ppda_total 
AS 
	(
	SELECT
		name,
		COUNT(ppda) as count_ppda
	FROM teams t
	JOIN teamstats ts
		ON t.team_id = ts.team_id
	GROUP BY t.name
	)
SELECT 
	name,
	CASE
		WHEN count_ppda >=200 THEN 'High pressing intensity'
		WHEN count_ppda between 50 and 200 THEN 'Medium pressing intensity'
		ELSE 'Low pressing intensity'
	END AS "Effectiveness of a team's pressing tactics"
FROM ppda_total;



--- CONCAT and CAST
-- The percentage of body part used by Ronaldo to perform a shot
-- Rounded to 5 decimal places 
-- Returned with a '%' symbol at the end of the result.
SELECT
	shot_type,
	CONCAT(
		CAST(
			COUNT(*) * 100.0 / (SELECT 
									COUNT(*) 
								FROM shots s
								JOIN players p
								ON s.shooter_id = p.player_id
								WHERE p.name = 'Cristiano Ronaldo') 
			AS DECIMAL(10,5)), '%') as pct
FROM
	shots s
JOIN players p
ON s.shooter_id = p.player_id
WHERE p.name = 'Cristiano Ronaldo'
GROUP BY
	shot_type
ORDER BY pct DESC;



--- WINDOWS FUNCTION
-- The first match of each team in each season
WITH 
	orders 
AS
	(
	SELECT 
		team_id,
		season,
		date,
		ROW_NUMBER() 
		  OVER(
			PARTITION BY team_id, season
			ORDER BY season, date ) AS match_order
	FROM teamstats
	)
SELECT 
	t.name,
	season,
	date
FROM orders o
JOIN teams t
	ON o.team_id = t.team_id
WHERE match_order = 1;



--- CASE
-- Number of matches that matched the probability predicted by the audience
WITH title
AS
	(
		SELECT 
			t1.name as home_team,
			t2.name as away_team,
			home_goals,
			away_goals,
			home_prob,
			draw_prob,
			away_prob,
			CASE
				WHEN (home_goals > away_goals AND home_prob > draw_prob and home_prob > away_prob)
					OR
					(home_goals = away_goals AND draw_prob > home_prob and draw_prob > away_prob)
					OR
					(home_goals < away_goals AND away_prob > home_prob and away_prob > draw_prob )
				THEN 'Reached'
				END AS title
		FROM games g 
		JOIN teams t1 
			ON g.home_team_id = t1.team_id
		JOIN teams t2 
			ON g.away_team_id = t2.team_id
	)
SELECT 
	COUNT(*) as num_matched_prob
FROM title
WHERE title = 'Reached'



-- CREATE TABLE
-- Create table about The achievements of Messi
SELECT 
	minute,
	situation,
	last_action,
	shot_type,
	shot_result
INTO messi_achive
FROM 
	shots s
JOIN players p
	ON p.player_id = s.shooter_id
WHERE name = 'Lionel Messi'



-- Check if the new table's all data is loaded
SELECT
	*
FROM 
	messi_achive;



-- Add a column named 'id' to the table 'messi_achieve' with default value starting from 1 and incrementing
ALTER TABLE messi_achive
ADD id INT IDENTITY(1,1)



-- Set the column 'id' as the primary key
ALTER TABLE messi_achive
ADD CONSTRAINT PK_messi_achive_id PRIMARY KEY (id)




-- Actually, some shots taken by Messi using other body parts are with his chest
UPDATE messi_achive
SET shot_type = 'Chest'
WHERE shot_type = 'OtherBodyPart';



-- Done with new table
DROP TABLE messi_achive;



--- VIEW
-- Creating View to store data for later visualization 
CREATE VIEW	
	view_test
AS
	SELECT 
		l.name as league_name,
		t.name AS team_name,
		p.name AS player_name,
		g.season,
		shot_type,
		shot_result 
	FROM shots s
	JOIN teamstats ts
		ON s.game_id = ts.team_id
	JOIN players p 
		ON s.shooter_id = p.player_id
	JOIN teams t
		ON ts.team_id = t.team_id
	JOIN games g
		ON s.game_id = g.game_id
	JOIN leagues l
		ON l.league_id = g.league_id



-- Check if the view is created successfully
SELECT 
	* 
FROM 
	view_test
