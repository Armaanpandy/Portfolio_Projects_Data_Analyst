--Armaan Singh Pandher
--Project Date:28/10/2023

--I'll be taking this data to tableau for dashboard
--So after EDA with the data set we found out that the location column had some continents in it 
--so we updated those to NULL and put those values back into continent column

-- we exclude/deleted rows with the following values in location
--	High income				1391
--	Low income				1385
--	Lower middle income		1391
--	Upper middle income		1391
--	World					1391
---------------------------------
--	Total					6949

--Also we notice that location has 'European Union' in it which has to be converted to Europe i.e all european union contries come under europe

--The only columns that we required were date continent location ,daily cases ,daily deaths, population,total_tests,daily tests



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--Covids Death cleaned
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS CovidDeath_clean
CREATE TABLE CovidDeath_clean
(
continent varchar(250),
location varchar(250),
date datetime,
daily_cases bigint,
daily_deaths bigint,
population bigint,
total_tests bigint
);

--,total_tests-LAG(total_tests,1) OVER (PARTITION BY location_updated ORDER BY date)

WITH CTE_continent_deaths_updated (Date, continent,location,new_cases,new_deaths,population,total_tests)
AS
(
SELECT
	CASE 
		WHEN COALESCE(continent,location)='European Union' THEN 'Europe' 
		ELSE COALESCE(continent,location) 
	END as continent_new
	,CASE 
		WHEN location= COALESCE(continent,location) THEN NULL
		ELSE location
	END as location_updated	
	,date
	,new_cases
	,new_deaths
	,population
	--,icu_patients
	,total_tests
	--,[hosp_patients]
	FROM CovidDeaths
	WHERE 
	(
	CASE 
		WHEN COALESCE(continent,location)='European Union' THEN 'Europe' 
		ELSE COALESCE(continent,location) 
	END 
	) NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income','World')

--ORDER BY continent_new,location_updated,date
)
INSERT INTO CovidDeath_clean
	SELECT *
	FROM CTE_continent_deaths_updated
	ORDER BY location,date

--SELECT * 
--FROM CovidDeath_clean
--ORDER BY location,date


-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--Covids Vaccinations cleaned
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--We similarly transform the continent and locations columns as we did above
--SELECT TOP 10 * FROM CovidVaccinations

DROP TABLE IF EXISTS CovidVaccination_clean
CREATE TABLE CovidVaccination_clean
(
continent varchar(250),
location varchar(250),
date datetime,
daily_tests bigint,
daily_vaccinations bigint,
population_vaccinated bigint,
population_fully_vaccinated bigint,
total_booster bigint
);

WITH CTE_continent_vaccinations_updated (continent,location,Date,daily_tests,daily_vaccinations,population_vaccinated,population_fully_vaccinated,total_boosters)
AS
(
SELECT
	CASE 
		WHEN COALESCE(continent,location)='European Union' THEN 'Europe' 
		ELSE COALESCE(continent,location) 
	END as continent_new
	,CASE 
		WHEN location= COALESCE(continent,location) THEN NULL
		ELSE location
	END as location_updated	
	,date
	,new_tests
	,new_vaccinations
	,people_vaccinated
	,people_fully_vaccinated
	,total_boosters
	FROM CovidVaccinations
	WHERE 
	(
	CASE 
		WHEN COALESCE(continent,location)='European Union' THEN 'Europe' 
		ELSE COALESCE(continent,location) 
	END 
	) NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income','World')

--ORDER BY location_updated,date
)
INSERT INTO CovidVaccination_clean
	SELECT *
	FROM CTE_continent_vaccinations_updated 
	ORDER BY location,date



-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--COUNTRY WISE VIEW
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS #covid_country_aggregate
CREATE TABLE #covid_country_aggregate
(continent varchar(250),
location varchar(250),
total_cases bigint,
total_tests bigint,
total_deaths bigint,
total_vaccinated bigint,
total_fully_vaccinated bigint,
total_single_vaccinated bigint,
population bigint)

INSERT INTO #covid_country_aggregate
SELECT 
	continent,location,
	SUM(daily_cases) as total_cases ,
	SUM(daily_tests) as total_tests,
	SUM(daily_deaths) as total_deaths,
	MAX(population_vaccinated) as total_vaccinated,
	MAX(population_fully_vaccinated) as total_fully_vaccinated,
	MAX(population_vaccinated)-MAX(population_fully_vaccinated) as total_single_vaccinated,
	AVG(population) as population
FROM 
(
	SELECT 
		vac.continent,vac.location,vac.date
		,vac.daily_vaccinations,vac.population_fully_vaccinated,vac.population_vaccinated
		,vac.daily_tests,dea.total_tests,dea.population,dea.daily_cases,dea.daily_deaths
	FROM CovidVaccination_clean as vac
	JOIN CovidDeath_clean as dea
		ON 
			vac.location=dea.location
			AND vac.continent=dea.continent
			AND vac.date=dea.date
	--ORDER BY vac.location,vac.date
) as subquery
GROUP BY continent,location
HAVING MAX(population_vaccinated)-MAX(population_fully_vaccinated)>=0 OR MAX(population_vaccinated)-MAX(population_fully_vaccinated) is NULL
--HAVING MAX(population_vaccinated)-MAX(population_fully_vaccinated)<0



--THERE IS ONE DATA POINT WHERE ABOVE HAVING CLAUSE IS MET SO WE DISCARD THAT
--Only 220 Data points if we remove NULL from above query
--(Afghanistan population for refrence 41128772)










-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--CONTINENT SUMMARY
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
	continent,
	SUM(total_cases ) as total_cases ,
	SUM(total_tests) as total_tests,
	SUM(total_deaths) as total_deaths,
	SUM(total_vaccinated) as total_vaccinated,
	SUM(total_fully_vaccinated) as total_fully_vaccinated,
	SUM(total_single_vaccinated) total_single_vaccinated,
	SUM(Population) as population
FROM #covid_country_aggregate
GROUP BY continent


-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--GLOBAL SUMMARY
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
	'Global' as continent,
	SUM(total_cases ) as total_cases ,
	SUM(total_tests) as total_tests,
	SUM(total_vaccinated) as total_vaccinated,
	SUM(total_fully_vaccinated) as total_fully_vaccinated,
	SUM(total_single_vaccinated) as total_single_vaccinated,
	SUM(total_fully_vaccinated) as total_fully_vaccinated,
	SUM(population) as population
FROM 
	(
	SELECT 
	continent,
	SUM(total_cases ) as total_cases ,
	SUM(total_tests) as total_tests,
	SUM(total_deaths) as total_deaths,
	SUM(total_vaccinated) as total_vaccinated,
	SUM(total_fully_vaccinated) as total_fully_vaccinated,
	SUM(total_single_vaccinated) total_single_vaccinated,
	SUM(Population) as population
FROM #covid_country_aggregate
GROUP BY continent
) AS subquery

--Or just directly SUM(on all the columns) on SELECT * FROM #covid_country_aggregate


