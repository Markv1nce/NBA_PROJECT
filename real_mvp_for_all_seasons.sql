-- COVERAGE SEASON FROM 1996-97 TO 2022-23
SELECT * FROM all_seasons;

-- removing and renaming a columns
ALTER TABLE all_seasons
DROP COLUMN `MyUnknownColumn_[0]`;

ALTER TABLE all_seasons
RENAME COLUMN MyUnknownColumn to row_num;

-- Standardizing data types: Migrating raw string data to appropriate Numeric, Decimal, and Varchar formats for better performance and data integrity.
ALTER TABLE all_seasons
MODIFY COLUMN row_num INT,
MODIFY COLUMN player_name VARCHAR(30),
MODIFY COLUMN team_abbreviation VARCHAR(5),
MODIFY COLUMN age INT,
MODIFY COLUMN player_height DECIMAL(5,2),
MODIFY COLUMN player_weight DOUBLE,
MODIFY COLUMN college VARCHAR(45),
MODIFY COLUMN country VARCHAR(40),
MODIFY COLUMN draft_year VARCHAR(10),
MODIFY COLUMN draft_round VARCHAR(10),
MODIFY COLUMN draft_number VARCHAR(10),
MODIFY COLUMN gp INT,
MODIFY COLUMN pts FLOAT,
MODIFY COLUMN reb FLOAT,
MODIFY COLUMN ast FLOAT,
MODIFY COLUMN net_rating FLOAT,
MODIFY COLUMN oreb_pct FLOAT,
MODIFY COLUMN dreb_pct FLOAT,
MODIFY COLUMN usg_pct FLOAT,
MODIFY COLUMN ts_pct FLOAT,
MODIFY COLUMN ast_pct FLOAT,
MODIFY COLUMN season VARCHAR(10);

ALTER TABLE all_seasons
ADD PRIMARY KEY (row_num);

-- --- NBA Player Stats – Data Analysis Questions --- 

-- ---- Part 1 — Data Understanding (Easy Start) ----
-- 1. How many total players are in the dataset?
SELECT 
COUNT(player_name) AS TOTAL_PLAYERS 
FROM all_seasons;

-- 2. How many seasons are included in the dataset?
SELECT 
COUNT(DISTINCT SEASON) AS TOTAL_SEASONS 
FROM all_seasons;

-- 3. What are the earliest and latest seasons in the dataset?
SELECT 
MAX(season) AS latest_season 
FROM all_seasons;

-- 4. How many different teams appear in the dataset?
SELECT 
COUNT(DISTINCT team_abbreviation) AS total_team
FROM all_seasons;

-- ---- Part 2 — Player Performance (Stats Columns: pts, reb, ast, ts_pct, usg_pct) ----
-- 5. For each season, who is the top scorer (highest pts)?

WITH top_scorer AS (
SELECT player_name,pts,season,
RANK() OVER(PARTITION BY season ORDER BY pts DESC) AS rank_pts
FROM all_seasons
)
SELECT * FROM top_scorer
WHERE rank_pts = 1;


-- 6. For each season, who has the most rebounds (reb)?
WITH most_reb AS (
SELECT player_name,season, reb,
RANK() OVER(PARTITION BY season ORDER BY reb DESC) AS rank_reb
FROM all_seasons
)
SELECT * FROM most_reb
WHERE rank_reb = 1;

-- 7. For each season, who has the most assists (ast)?
WITH most_assist as(
SELECT player_name, season, ast,
RANK() OVER(PARTITION BY season ORDER BY ast DESC) AS Rank_Ast
FROM all_seasons
)
SELECT * FROM most_assist
WHERE Rank_Ast = 1;

-- 8. Which players appear in the Top 10 scoring list most often across all seasons?
WITH top_10_scoring AS (
SELECT player_name, season, pts,
RANK() OVER(PARTITION BY season ORDER BY pts DESC) AS most_points
FROM all_seasons

)
SELECT player_name, COUNT(*) as allplayer FROM top_10_scoring
WHERE most_points <= 10
GROUP by player_name
HAVING allplayer > 5 
ORDER BY allplayer DESC;


-- 9. Among players scoring at least 20 points per game, who has the highest True Shooting % (ts_pct)?
WITH highest_ts AS (
SELECT player_name, pts,season,ts_pct,
RANK() OVER( ORDER BY ts_pct DESC) AS true_shoot
FROM all_seasons
WHERE pts >= 20
)
SELECT * FROM highest_ts
WHERE true_shoot = 1;


-- ---- Part 3 — Efficiency vs Usage (Columns: usg_pct, ts_pct) ----

-- 10. List the top 10 players with the highest usage percentage (usg_pct).
WITH highest_usg_pct AS (
SELECT player_name, season, usg_pct, 
ROW_NUMBER() OVER(ORDER BY usg_pct DESC) as high_usg
FROM all_seasons
)
SELECT * FROM highest_usg_pct 
WHERE high_usg <= 10;


-- 11. Among those top usage players, who has the best True Shooting % (ts_pct)?
WITH highest_usg_pct AS (
	SELECT player_name, season, usg_pct, ts_pct,
	ROW_NUMBER() OVER(ORDER BY usg_pct DESC) as high_usg
	FROM all_seasons
)
SELECT * FROM highest_usg_pct 
WHERE high_usg <= 10
order by ts_pct DESC
LIMIT 1;

-- 12. Does higher usage (usg_pct) correlate with lower efficiency (ts_pct)? (Hint: look for patterns, maybe a scatter plot)

WITH insight AS (
SELECT *,
CASE
    WHEN usg_pct >= 0 AND usg_pct < 0.10 THEN "Low"
    WHEN usg_pct >= 0.10 AND usg_pct < 0.20 THEN "Medium"
    WHEN usg_pct >= 0.20 AND usg_pct < 0.30 THEN "High"
    ELSE "Very High"
END as Bucket_pct
FROM all_seasons
)
SELECT Bucket_pct, AVG(ts_pct)
FROM insight
GROUP BY bucket_pct;

-- 13. Find players who have both high usage (≥30%) and high TS% (≥60%).
SELECT player_name, season, usg_pct, ts_pct 
FROM all_seasons
WHERE usg_pct >= 0.30 AND ts_pct >= 0.60;

-- ---- Part 4 — Most Improved Players ----

-- 14. Which player had the largest increase in pts between two consecutive seasons?
SELECT * FROM(
WITH previous_points AS (
	SELECT
	player_name, season, pts,
	LAG(pts) OVER(PARTITION BY player_name ORDER BY season) AS pre_pts
	FROM all_seasons
)
SELECT *,
	pts - pre_pts AS pts_improved
	FROM previous_points
) AS pts_table
WHERE pts_improved IS NOT NULL AND pts_improved > 0
ORDER BY pts_improved DESC
LIMIT 1;


-- 15. Which player had the largest increase in ast between seasons?
SELECT 
player_name, season, ast, pre_ast, ROUND(improvement, 2) AS improvement
FROM (
	SELECT 
	player_name, season, ast,
	LAG(ast) OVER(partition by player_name ORDER BY season) AS pre_ast,
	ast - LAG(ast) OVER(partition by player_name ORDER BY season) AS improvement
	FROM all_seasons
)AS improve_ast
WHERE improvement IS NOT NULL AND improvement > 0
ORDER BY improvement DESC
LIMIT 1;


-- 16. Which player had the largest increase in reb between seasons?
SELECT * FROM(
WITH previous_reb AS (
	SELECT
	player_name, season, reb,
	LAG(reb) OVER(PARTITION BY player_name ORDER BY season) AS pre_reb
	FROM all_seasons
)
SELECT *,
	reb - pre_reb AS reb_improved
	FROM previous_reb
) AS reb_table
WHERE reb_improved IS NOT NULL AND reb_improved > 0
ORDER BY reb_improved DESC
LIMIT 1;


-- ---- Part 5 — Era Analysis ----

-- 17. Create an Era column from season: 1990s | 2000s | 2010s | 2020s

CREATE TABLE seasons_with_era AS 
WITH season_era AS (
SELECT *, CAST(LEFT(season, 4)AS UNSIGNED) AS season_year
FROM all_seasons 
)
SELECT *,
CASE
	WHEN season_year BETWEEN 1990 AND 1999 THEN "1990s"
    WHEN season_year BETWEEN 2000 AND 2009 THEN "2000s"
    WHEN season_year BETWEEN 2010 AND 2019 THEN "2010s" 
    ELSE "2020s" 
    END as era
FROM season_era;


-- 18. What is the average player height per era?
SELECT 
era, ROUND(AVG(player_height),2) AS avg_height,
ROUND(AVG(player_height) / 30.48,2) AS height_in_feet
FROM seasons_with_era
GROUP BY era;


-- 19. What is the average player weight per era?
SELECT era, ROUND(AVG(player_weight), 2) AS weight
FROM seasons_with_era
GROUP BY era;

-- 20. Which era has the highest average pts?
SELECT era, AVG(pts) as points
FROM seasons_with_era
GROUP BY era
ORDER BY points DESC;

-- 21. Which era has the highest average ast?
SELECT era, AVG(ast) as assists
FROM seasons_with_era
GROUP BY era
ORDER BY assists DESC;


-- ---- Part 6 — Teams ----

-- 22. Which team produces the most top scorers?

-- SELECT * FROM (
WITH table_score AS (
	SELECT  team_abbreviation, season, pts,
	RANK() OVER(PARTITION BY season ORDER BY pts DESC) AS top_scorer
	FROM all_seasons
)
SELECT 
team_abbreviation, COUNT(*) AS most_points_team
FROM table_score
WHERE top_scorer = 1
GROUP BY team_abbreviation
ORDER BY most_points_team DESC
LIMIT 1;

-- 23. Which team has the highest total points in a season?
SELECT team_abbreviation, season, ROUND(sum(pts),2) AS highest_total_pts
FROM all_seasons
GROUP BY team_abbreviation, season
ORDER BY highest_total_pts DESC
LIMIT 1;

-- 24. Which team has the highest total rebounds in a season?

SELECT 
	team_abbreviation, season, ROUND(SUM(reb),2) AS highest_total_reb
FROM all_seasons
GROUP BY team_abbreviation, season
ORDER BY highest_total_reb DESC
LIMIT 1;


-- 25. Which team has the highest total assists in a season?
SELECT 
	team_abbreviation, season, ROUND(SUM(ast),2) AS highest_total_ast
FROM all_seasons
GROUP BY team_abbreviation, season
ORDER BY highest_total_ast DESC
LIMIT 1;


-- ---- Part 7 — Draft & Age ----

-- 26. Which draft year produced the most high scorers?
SELECT draft_year, COUNT(DISTINCT player_name) AS high_score_count
FROM all_seasons
WHERE pts >= 20 AND draft_year NOT LIKE "Undrafted"
GROUP BY draft_year
ORDER BY high_score_count DESC
LIMIT 1;




-- 27. Which age group scores the most on average?
WITH age_avg_score AS (
	SELECT *,
	CASE
		WHEN age >= 18 AND age <= 22 THEN 'Young (18-22)'
		WHEN age >= 23 AND age <= 27 THEN 'Early Prime (23-27)'
		WHEN age >= 28 AND age <= 32 THEN 'Prime (28-32)'
		ELSE 'Veteran (33+)'
		END AS age_group
	FROM all_seasons
)
SELECT age_group, ROUND(AVG(pts),2) AS avg_pts
FROM age_avg_score
GROUP BY age_group
ORDER BY avg_pts desc
LIMIT 1;


-- 28. Which player under age 22 had the best season (highest pts)?
SELECT player_name, pts, season, age
FROM all_seasons
WHERE AGE < 22
ORDER BY pts DESC
LIMIT 1;

-- ----Part 8 — Data MVP----
-- 29. Create an MVP score: MVP Score = 0.40 * pts + 0.30 * (reb + ast) + 0.30 * ts_pct
-- 30. Who is the top MVP per season using this formula?
-- I COMBINE THE solution in this QUESTION.

SELECT * FROM (
	WITH mvp_score_table AS (
		SELECT *,  
		ROUND((0.40 * pts) + (0.30 * (reb + ast)) + (0.30 * ts_pct),2) AS mvp_score
		FROM all_seasons
	)
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY season ORDER BY mvp_score DESC) AS top_mvp
	FROM mvp_score_table
    ORDER BY draft_year
)AS ranked
WHERE top_mvp = 1
ORDER BY season DESC;

-- 31. Compare your result with the actual NBA MVP.
CREATE TABLE actual_mvp_name AS
SELECT player_name, team_abbreviation, season,mvp_score FROM (
	WITH mvp_score_table AS (
		SELECT *,  
		ROUND((0.40 * pts) + (0.30 * (reb + ast)) + (0.30 * ts_pct),2) AS mvp_score
		FROM all_seasons
	)
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY season ORDER BY mvp_score DESC) AS top_mvp
	FROM mvp_score_table
    ORDER BY draft_year
)AS ranked
WHERE top_mvp = 1
ORDER BY season DESC;

SELECT * FROM mvp_list;

CREATE TABLE actual_mvp(
	player_name VARCHAR(30),
    season VARCHAR(10)
);

INSERT INTO actual_mvp
VALUES ("Joel Embiid", "2022-23"),
	   ("Nikola Jokic", "2021-22"),
       ("Nikola Jokic", "2020-21"),
       ("Giannis Antetokounmpo", "2019-20"),
       ("Giannis Antetokounmpo", "2018-19"),
       ("James Harden", "2017-18"),
       ("Russell Westbrook", "2016-17"),
       ("Stephen Curry", "2015-16"),
       ("Stephen Curry", "2014-15"),
       ("Kevin Durant", "2013-14"),
       ("LeBron James", "2012-13"),
       ("LeBron James", "2011-12"),
       ("Derrick Rose", "2010-11"),
	   ("LeBron James", "2009-10"),
       ("LeBron James", "2008-09"),
       ("Kobe Bryant", "2007-08"),
       ("Dirk Nowitzki", "2006-07"),
       ("Steve Nash", "2005-06"),
       ("Steve Nash", "2004-05"),
       ("Kevin Garnett", "2003-04"),
       ("Tim Duncan", "2002-03"),
       ("Tim Duncan", "2001-02"),
       ("Allen Iverson", "2000-01"),
       ("Shaquille O'Neal", "1999-00"),
       ("Karl Malone", "1998-99"),
       ("Michael Jordan", "1997-98"),
       ("Karl Malone", "1996-97");
       
SELECT * FROM actual_mvp;
       
WITH matching_mvp AS (
SELECT 
	predicted_mvp.player_name AS Predicted, 
	real_mvp.player_name AS Actual, 
	real_mvp.season
FROM actual_mvp AS real_mvp
JOIN mvp_list AS predicted_mvp
ON real_mvp.season = predicted_mvp.season
)
SELECT *,
	CASE
		WHEN Predicted = Actual THEN "Match"
        ELSE "Not Match"
	END as Result
FROM matching_mvp;


-- ----Part 9 — Dream Team----

-- 32. Best Point Guard-type player (high assists / scoring)
SELECT player_name,
	   ROUND((ast * 2 + pts), 2) AS pg_score
FROM all_seasons
WHERE ast >= 5
ORDER BY pg_score DESC
LIMIT 1;

-- 33. Best Shooting Guard-type player (scoring focus)
SELECT player_name, ROUND((pts + (pts * ts_pct)),2) AS score
FROM all_seasons
WHERE pts >= 20
ORDER BY score DESC
lIMIT 1;

-- 34. Best Small Forward-type player (balanced stats)
SELECT 
player_name, 
(pts + reb + ast)/3 AS score
FROM all_seasons
ORDER BY score DESC
LIMIT 1;

-- 35. Best Power Forward-type player (rebounds + scoring)
SELECT 
player_name, 
(pts + reb )/2 AS score
FROM all_seasons
WHERE reb >= 10
ORDER BY score DESC
LIMIT 1;

-- 36. Best Center-type player (rebounds / efficiency)
SELECT
player_name, 
reb + (reb * ts_pct) AS score
FROM all_seasons
WHERE reb >= 10
ORDER BY score DESC
LIMIT 1;