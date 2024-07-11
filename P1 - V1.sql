SELECT *
FROM olympic_medals

SELECT *
FROM olympic_athletes

SELECT *
FROM olympic_hosts

SELECT *
FROM olympic_results

----------------------------------------------------------------------------------------------------------------------------------------------

-- Medal Counts by country
SELECT country_3_letter_code, medal_type, count(*) AS medal_count
FROM olympic_medals
GROUP BY country_3_letter_code, medal_type
ORDER BY country_3_letter_code, CASE	WHEN medal_type = 'Gold' THEN 1
										WHEN medal_type = 'Silver' THEN 2
										WHEN medal_type = 'Bronze' THEN 3
										END


-- Number of National Teams Participating in the Olympics by games
SELECT slug_game, COUNT(DISTINCT country_3_letter_code) AS num_of_countries
FROM olympic_results
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
GROUP BY slug_game
ORDER BY CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT)

-- Who are the 10 most rewarded olympic athlete (only individual medals)?
SELECT TOP 10 athlete_full_name, COUNT(*)
FROM olympic_medals
WHERE athlete_full_name IS NOT NULL AND athlete_full_name NOT LIKE '%NAME%'
GROUP BY athlete_full_name
ORDER BY COUNT(*) DESC

-- Identifying Nations with Full Participation in All Summer Olympic Games
WITH total_games AS(
SELECT COUNT(game_slug) AS sum_of_games
FROM olympic_hosts 
WHERE game_season = 'Summer'
),
total_participation AS(
SELECT country_3_letter_code, COUNT(DISTINCT slug_game) AS sum_of_participation
FROM olympic_results
WHERE slug_game IN (SELECT game_slug
					FROM olympic_hosts 
					WHERE game_season = 'Summer')
GROUP BY country_3_letter_code 
--ORDER BY COUNT(DISTINCT slug_game) DESC
)
SELECT country_3_letter_code
FROM total_games AS TG JOIN total_participation AS TP ON TG.sum_of_games = TP.sum_of_participation

----------------------------------------------------------------------------------------------------------------------------------------------
--Basic SQL Questions:

--How many athletes participated in the Olympic Games each year (do not consider the athletes that compete only in team games)?
SELECT slug_game, COUNT(DISTINCT athlete_full_name) AS num_of_athletes
FROM olympic_results
GROUP BY slug_game
ORDER BY num_of_athletes DESC

--Which countries have won the most medals in total?
SELECT country_3_letter_code, count(*) AS medal_count
FROM olympic_medals
GROUP BY country_3_letter_code
ORDER BY medal_count DESC

--Who are the top 10 athletes with the highest number of medals (only individual medals)?
SELECT TOP 10 athlete_full_name, COUNT(*) AS num_of_medals
FROM olympic_medals
WHERE athlete_full_name IS NOT NULL AND athlete_full_name NOT LIKE '%NAME%'
GROUP BY athlete_full_name
ORDER BY num_of_medals DESC

--How many events are there in each discipline?
SELECT discipline_title, COUNT(DISTINCT event_title) AS num_of_events
FROM olympic_results
GROUP BY discipline_title
ORDER BY num_of_events DESC

--Intermediate SQL Questions:

--What is the average age of athletes for each olympic game?
WITH athletes_age AS(
SELECT OLR.slug_game, OLR.athlete_full_name, (CAST(SUBSTRING(OLR.slug_game, CHARINDEX('-', OLR.slug_game) + 1, 4) AS INT) - OA.athlete_year_birth) AS athlete_age 
FROM olympic_athletes AS OA JOIN olympic_results AS OLR ON OA.athlete_full_name = OLR.athlete_full_name
WHERE ISNUMERIC(SUBSTRING(OLR.slug_game, CHARINDEX('-', OLR.slug_game) + 1, 4)) = 1
)
SELECT slug_game, ROUND(AVG(athlete_age),2) AS avg_age
FROM athletes_age
GROUP BY slug_game 
ORDER BY avg_age

--How many medals of each type (gold, silver, bronze) have been won by each country?
SELECT country_3_letter_code, medal_type, count(*) AS medal_count
FROM olympic_medals
GROUP BY country_3_letter_code, medal_type
ORDER BY country_3_letter_code, CASE	WHEN medal_type = 'Gold' THEN 1
										WHEN medal_type = 'Silver' THEN 2
										WHEN medal_type = 'Bronze' THEN 3
										END

--Which games had the highest number of participating countries?
SELECT slug_game, COUNT(DISTINCT country_3_letter_code) AS num_of_countries
FROM olympic_results
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
GROUP BY slug_game
ORDER BY num_of_countries DESC

--Which countries have participated in the most Winter Olympic Games?
SELECT country_3_letter_code, COUNT(DISTINCT slug_game) AS num_of_winter_games
FROM olympic_results
WHERE slug_game IN (SELECT game_slug
					FROM olympic_hosts
					WHERE game_season='Winter')
GROUP BY country_3_letter_code
ORDER BY num_of_winter_games DESC

--What is the average age of medalists from each country and year?
WITH athletes_age AS(
SELECT OM.country_3_letter_code, OM.country_name, CAST(SUBSTRING(OM.slug_game, CHARINDEX('-', OM.slug_game) + 1, 4) AS INT) AS year, OM.athlete_full_name, CAST(SUBSTRING(OM.slug_game, CHARINDEX('-', OM.slug_game) + 1, 4) AS INT) - OA.athlete_year_birth AS athlete_age
FROM olympic_medals AS OM JOIN olympic_athletes AS OA ON OM.athlete_full_name = OA.athlete_full_name
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
)
SELECT country_3_letter_code, country_name, year, ROUND(AVG(athlete_age) ,2) AS avg_age
FROM athletes_age
WHERE athlete_age IS NOT NULL
GROUP BY country_3_letter_code, country_name, year
ORDER BY year, country_3_letter_code

--Advanced SQL Questions Using Window Functions:

--Rank the countries by their total medal count.
SELECT country_3_letter_code, country_name, COUNT(*) AS sum_of_medals, RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
FROM olympic_medals
GROUP BY country_3_letter_code, country_name
ORDER BY rank

--Calculate the running total of medals won by each country over the years.
WITH yearly_medal_counts AS (
SELECT country_3_letter_code, country_name, CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT) AS year, COUNT(*) AS yearly_medals
FROM olympic_medals
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
GROUP BY country_3_letter_code, country_name, CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT)
)
SELECT country_3_letter_code, country_name, year, SUM(yearly_medals) OVER(PARTITION BY country_3_letter_code ORDER BY year) AS running_total_medals
FROM yearly_medal_counts
ORDER BY country_3_letter_code, year

--What is the percentage of medals won by each country in each year?
WITH yearly_medal_counts AS (
SELECT CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT) AS year, country_3_letter_code, country_name, COUNT(*) AS yearly_medals
FROM olympic_medals
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
GROUP BY country_3_letter_code, country_name, CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT)
)
SELECT year, country_3_letter_code, country_name, yearly_medals, SUM(yearly_medals) OVER(PARTITION BY year) AS total_yearly_medals, CAST(100.0 * yearly_medals / SUM(yearly_medals) OVER(PARTITION BY year) AS DECIMAL(10,2)) AS percentage_of_medal_by_country
FROM yearly_medal_counts
ORDER BY year, percentage_of_medal_by_country DESC

--Identify the 3 top athlete by total medals in each discipline.
WITH ranked_athletes AS(
SELECT discipline_title, athlete_full_name, COUNT(*) AS num_of_medals, RANK() OVER(PARTITION BY discipline_title ORDER BY COUNT(*) DESC) AS discipline_rank
FROM olympic_results
WHERE athlete_full_name IS NOT NULL AND athlete_full_name NOT LIKE '%NAME%' AND medal_type IS NOT NULL
GROUP BY discipline_title, athlete_full_name
)
SELECT *
FROM ranked_athletes
WHERE discipline_rank <= 3
ORDER BY discipline_title, discipline_rank

--Advanced SQL Questions Using Analytical Functions:

--Which countries have won medals in the same discipline and event in consecutive olympic Games, and how many times has this occurred (not necessarily consecutively)?
WITH helper AS(
SELECT	OM.discipline_title,
		OM.event_title,
		OH.game_year,
		OH.game_season,
		OM.country_3_letter_code,
		LAG(country_3_letter_code, 3) OVER(PARTITION BY OM.discipline_title, OM.event_title ORDER BY OH.game_year, OH.game_season) AS prev_games_1,
		LAG(country_3_letter_code, 4) OVER(PARTITION BY OM.discipline_title, OM.event_title ORDER BY OH.game_year, OH.game_season) AS prev_games_2,
		LAG(country_3_letter_code, 5) OVER(PARTITION BY OM.discipline_title, OM.event_title ORDER BY OH.game_year, OH.game_season) AS prev_games_3,
		OM.medal_type
FROM olympic_medals AS OM LEFT JOIN olympic_hosts AS OH ON OM.slug_game = OH.game_slug
)
SELECT discipline_title, event_title, country_3_letter_code, COUNT(*) AS num_of_times_consecutive_on_podium -- not necessarily consecutively
FROM helper
WHERE country_3_letter_code = prev_games_1 OR country_3_letter_code = prev_games_2 OR country_3_letter_code = prev_games_3
GROUP BY discipline_title, event_title, country_3_letter_code
ORDER BY discipline_title, event_title, num_of_times_consecutive_on_podium DESC

-- What is the distribution of medals by athlete age groups?
WITH age_calculator AS(
SELECT OM.event_gender, OM.medal_type, CAST(SUBSTRING(OM.slug_game, CHARINDEX('-', OM.slug_game) + 1, 4) AS INT) - OA.athlete_year_birth AS Age
FROM olympic_medals AS OM LEFT JOIN olympic_athletes AS OA ON OM.athlete_full_name = OA.athlete_full_name
WHERE OM.athlete_full_name IS NOT NULL AND OM.athlete_full_name NOT LIKE '%NAME%' AND OM.participant_type NOT LIKE '%GameTeam%' AND OA.athlete_year_birth IS NOT NULL AND ISNUMERIC(SUBSTRING(OM.slug_game, CHARINDEX('-', OM.slug_game) + 1, 4)) = 1
)
SELECT event_gender, medal_type, ROUND(AVG(Age), 2) AS avg_age
FROM age_calculator
GROUP BY event_gender, medal_type
ORDER BY event_gender, CASE	WHEN medal_type = 'Gold' THEN 1
							WHEN medal_type = 'Silver' THEN 2
							WHEN medal_type = 'Bronze' THEN 3
							END,
		 avg_age

-- Who are the top 3 countries by medal type each year?
WITH country_medal_year AS (
SELECT country_name, country_code, medal_type, CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT) AS year, COUNT(*) AS num_of_medals
FROM olympic_medals
WHERE ISNUMERIC(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4)) = 1
GROUP BY country_name, country_code, medal_type, CAST(SUBSTRING(slug_game, CHARINDEX('-', slug_game) + 1, 4) AS INT)
),
rank_by_country_medal_year AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY year, medal_type ORDER BY num_of_medals DESC) AS row_number
FROM country_medal_year
)
SELECT country_name, country_code, medal_type,year
FROM rank_by_country_medal_year
WHERE row_number < 4
ORDER BY  year, CASE	WHEN medal_type = 'Gold' THEN 1
						WHEN medal_type = 'Silver' THEN 2
						WHEN medal_type = 'Bronze' THEN 3
						END, 
						num_of_medals DESC

-- ISNUMERIC(expression): returns 1 if the expression is numeric and 0 otherwise
-- SUBSTRING(expression, start, length): Extracts a substring from the given expression starting at the specified position (start) and with the specified length (length).
-- CHARINDEX(substring, expression): Returns the starting position of the specified substring within the given expression. If the substring is not found, it returns 0.

--Temp Table

DROP TABLE is exists #dfsj
CREATE TABLE #rbjhdfik(

)

INSERT INTO #fkjdv

--Creating View to store data for later visualizations

CREATE VIEW rbrkvb AS


