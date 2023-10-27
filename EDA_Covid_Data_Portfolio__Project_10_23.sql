--If you are having data import issues from excel to MSSM Studio please watch this https://www.youtube.com/watch?v=t7C151yxwcY 
--DATA SOURCES: https://ourworldindata.org/covid-deaths


--FILTER OUT DATA 
SELECT location,date,total_cases,total_deaths,population
FROM ProjectPortfolio01..CovidDeaths
ORDER BY location,date


--There is a overflow in for int data type so converting population into bigint
DROP TABLE IF EXISTS #Country_wise_population
CREATE TABLE #Country_wise_population
(location varchar(100)
,Population bigint
)
INSERT INTO #Country_wise_population
	SELECT location,CAST(SUM(population) AS bigint) as population
	from ProjectPortfolio01..CovidDeaths
	GROUP BY location
SELECT (SUM(population) )FROM #Country_wise_population


-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Not Required Just testing stuff out here
---- Deal with data type Validation (RUN only if when on importing datatype is not set correctly)
--ALter TABLE ProjectPortfolio01..CovidDeaths
--ALTER COLUMN population bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN total_cases bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_cases bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_cases_smoothed bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN total_deaths bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_deaths bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_deaths_smoothed bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN total_cases_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_cases_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_cases_smoothed_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN total_deaths_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_deaths_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN new_deaths_smoothed_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN reproduction_rate float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN icu_patients bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN icu_patients_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN hosp_patients bigint;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN hosp_patients_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN weekly_icu_admissions float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN weekly_icu_admissions_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN weekly_hosp_admissions float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN weekly_hosp_admissions_per_million float;
--      ALTER TABLE ProjectPortfolio01..CovidDeaths  ALTER COLUMN total_tests bigint;
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Total Cases vs Total Deaths
SELECT  location,date,total_cases,total_deaths,ROUND(total_deaths/CAST(total_cases as float)*100,2) as DeathPercentage 
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
--WHERE location = 'India'
ORDER BY location,date
--ROUGH Estimate of likelihood of death on contraction of COVID 19

-- Total Cases vs Population
SELECT  location,date,total_cases,population,(total_cases/CAST(population as float)*100) as InfectionPercentage 
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
ORDER BY location,date

--Countries with highest infection rate
SELECT  location,population,MAX(total_cases) AS Highest_Infection_Count,MAX(total_cases/CAST(population as float)*100) as InfectionPercentage 
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
GROUP BY location,population
ORDER BY InfectionPercentage DESC

-- ALL the Countries have the same amount of population throughout the data
SELECT DISTINCT location,population
FROM ProjectPortfolio01..CovidDeaths
ORDER BY location

SELECT DISTINCT location
FROM ProjectPortfolio01..CovidDeaths

--Even though population remains consistent throughout the dataset I personally find that hard to believe 
--so I am taking the max of population and max of total cases to find out highest ifection percentage for a country

--Countries with highest Infection Rate
SELECT  location,MAX(total_cases) AS Highest_Infection_Count,MAX(population) as max_population, CAST(MAX(total_cases) AS float)/MAX(population)*100 as InfectionPercentage 
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
GROUP BY location
ORDER BY InfectionPercentage DESC

--Countries with highest infection rate
SELECT  location,MAX(total_cases) AS Highest_Infection_Count,MAX(total_deaths) as max_death, CAST(MAX(total_cases) AS float)/MAX(total_deaths)*100 as DeathRate
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
GROUP BY location
ORDER BY DeathRate DESC

--As we can see our data was showing a litlle bit of erroneous values for locations 
--which is supposed to be country but the following values are also there

SELECT DISTINCT location FROM ProjectPortfolio01..CovidDeaths
WHERE continent is NULL

--This query gives us a list of all the countries without these erroneous values
SELECT DISTINCT location
FROM ProjectPortfolio01..CovidDeaths
WHERE location NOT IN 
(
	SELECT DISTINCT location FROM ProjectPortfolio01..CovidDeaths
	WHERE continent is NULL
)

--Count of each erroneous values
SELECT  continent, location,count(*)
FROM ProjectPortfolio01..CovidDeaths
WHERE location IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income','World')
GROUP BY continent, location

SELECT  count(*) as erroneuos_values
FROM ProjectPortfolio01..CovidDeaths
WHERE location IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income','World')


--One way to deal with these values is to filter them out from each query using
SELECT *
FROM ProjectPortfolio01..CovidDeaths
WHERE location NOT IN 
(	
	SELECT DISTINCT location FROM ProjectPortfolio01..CovidDeaths
	WHERE continent is NULL
)
ORDER BY 2,3,4

-- Or simply we can add WHERE continent is NOT NULL
SELECT *
FROM ProjectPortfolio01..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 2,3,4

--So writing the above queries again we get

--Countries with highest Infection Rate(filtered)
SELECT  location,MAX(total_cases) AS Highest_Infection_Count,MAX(population) as max_population, CAST(MAX(total_cases) AS float)/MAX(population)*100 as InfectionPercentage 
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY InfectionPercentage DESC

--Countries with highest infection rate(filtered)
SELECT  location,MAX(total_cases) AS Highest_Infection_Count,MAX(total_deaths) as max_death, CAST(MAX(total_cases) AS float)/MAX(total_deaths)*100 as DeathRate
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY DeathRate DESC

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--CONTINENT LEVEL NUMBERS
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  continent,location,MAX(total_deaths)
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is not NULL
GROUP BY continent,location


SELECT location,MAX(total_deaths)
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is NULL
GROUP BY location

--Since we noticed earlier that location has some of the continent names we run query by grouping both once 

SELECT  COALESCE(continent,location) as new_continent,MAX(total_deaths) as Deaths
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
GROUP BY COALESCE(continent,location)
ORDER BY Deaths

(SELECT  location,MAX(total_deaths) as Deaths
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY Deaths


(SELECT  COALESCE(continent,location) as new_continent,MAX(total_deaths) as Deaths
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
GROUP BY COALESCE(continent,location)
--ORDER BY Deaths
)
UNION
(SELECT  location,MAX(total_deaths) as Deaths
FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
WHERE continent is NULL
GROUP BY location
--ORDER BY Deaths
)

--You can do all the queries we did above just change the group by function to what we concluded above
--Either put WHERE continent is NULL and GROUP BY location
--OR put WHERE continent is NULL and GROUP BY Continent


--COUNT of where continent is not NULL
(
	SELECT continent,COUNT(*)
	FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
	WHERE continent is NOT NULL
	GROUP BY continent
)
UNION
(
	SELECT 'Total',COUNT(*)
	FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
	WHERE continent is NOT NULL
)


--COUNT where continent is not given
SELECT location,COUNT(*) as count
FROM ProjectPortfolio01..CovidDeaths
WHERE continent is NULL 
GROUP BY location
UNION ALL
SELECT 'Total' as location,COUNT(*) as count
FROM ProjectPortfolio01..CovidDeaths
WHERE continent is NULL 

--There are 16,673 NULL values in the "Continents" column. Given their relatively small number, we can merge them with the "Location" column using the COALESCE function.

--Lets Merge the continent and location using COALESCE
(
	SELECT COALESCE(continent,location) as new_continent,COUNT(*)
	FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
	GROUP BY COALESCE(continent,location)
)
UNION
(
	SELECT 'Total',COUNT(*)
	FROM ProjectPortfolio01..ProjectPortfolio01..CovidDeaths
)

--When merging, we need to be cautious of four specific categories: "High income," "Upper middle income," "Lower middle income," and "Low income."
--We can adjust the table to ensure that these categories are not included in the "Continent" column.

--THESE ARE THE ACTUAL CONTINENT NUMBERS TO BE USED (WE copy this for our following quries in GLOBAL NUMBER)
SELECT COALESCE(continent,location) AS new_continent , COUNT(*)
FROM ProjectPortfolio01..CovidDeaths
WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
GROUP BY COALESCE(continent,location) 






-- ----------------------------------------------------------------------------------------------------------------------------------------------------------
--CONTINENT NUMBERS
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------

--SUMMARY TABLE
	SELECT COALESCE(continent,location) AS new_continent , COUNT(*) AS count
	FROM ProjectPortfolio01..CovidDeaths
	WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
	GROUP BY COALESCE(continent,location) 

UNION ALL

	SELECT 'Total' AS new_continent, COUNT(*) AS count
	FROM ProjectPortfolio01..CovidDeaths
	WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')

--DEATHS IN EACH CONTINENT

SELECT TOP (10) continent,location, total_deaths,new_deaths
FROM ProjectPortfolio01..CovidDeaths
WHERE total_deaths is NOT NULL 
--We can clearly see total deaths gives us the cummulative count of new_death
--We can either take max(total_deaths) this will give us the last total value since it a cummulative result
--OR we take SUM(new_deaths) should give the result 
SELECT TOP (10) continent,location, MAX(total_deaths),SUM(new_deaths)
FROM ProjectPortfolio01..CovidDeaths
WHERE total_deaths is NOT NULL 
GROUP BY continent,location
--This logic doesnt work for continent view but only limited to location

--Lets Look at deaths in each continent
SELECT 
	COALESCE(continent,location) AS new_continent , SUM(new_deaths) as deaths,SUM(population) population
	,SUM(new_deaths)/CAST(SUM(population) AS float) as DeathRate
FROM ProjectPortfolio01..CovidDeaths
WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
GROUP BY COALESCE(continent,location) 
ORDER BY deaths DESC



--Complete Summary
SELECT subquery.continent,SUM(avg_population) as continent_population,SUM(deaths_country) as Deaths
	,SUM(country_cases)/CAST(SUM(avg_population) as float) *100 'InfectionRate(%)'
	,SUM(deaths_country)/CAST(SUM(country_cases) as float) *100 'DeathRate(%)'
FROM
(
	SELECT continent,location,AVG(population) as avg_population,SUM(new_deaths) as deaths_country
	--,MAX(total_deaths) same as SUM(new_deaths)
	,SUM(new_cases) country_cases
	FROM ProjectPortfolio01..CovidDeaths
	WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
	GROUP BY continent,location
) as subquery
GROUP BY continent
ORDER BY [DeathRate(%)],[InfectionRate(%)]


--Before finalising we should look at whether the metrics we are are COMPLETE
SELECT 
	SELECT continent_new,location_updated
	FROM(
		SELECT 
			COALESCE(continent,location) as continent_new
			,CASE 
				WHEN location= COALESCE(continent,location) THEN NULL
				ELSE location
			END as location_updated
			,AVG(population) as avg_population
			,MAX(total_deaths) as deaths_country
			--,MAX(total_deaths) same as SUM(new_deaths)
			,SUM(new_cases) country_cases
			--,SUM(COUNT(*)) OVER (partition BY location_updated) as rows_missing
		FROM ProjectPortfolio01..CovidDeaths
		WHERE 
		COALESCE(continent,location) NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
	)
	
	GROUP BY 
	HAVING 
		SUM(new_deaths)  is NULL OR SUM(new_cases) is NULL OR AVG(population) is NULL 

UNION ALL

SELECT
	'Continent','Total',SUM(avg_population) as avg_population ,SUM(deaths_country) as deaths_country 
	,SUM(country_cases) as country_cases,SUM(rows_missing) as rows_missing
FROM
(	SELECT continent,location,AVG(population) as avg_population,MAX(total_deaths) as deaths_country
	,SUM(new_cases) country_cases,SUM(COUNT(*)) OVER (partition BY location) as rows_missing
	
	FROM ProjectPortfolio01..CovidDeaths
	WHERE continent NOT IN ('High income', 'Upper middle income' ,'Lower middle income', 'Low income')
	GROUP BY continent,location
	HAVING SUM(new_deaths)  is NULL OR SUM(new_cases) is NULL OR AVG(population) is NULL
) subquery

--Before finalising we should look at whether the metrics we are are COMPLETE



--Another thing to notice Location = 'World' doesnt quite fit anywhere so better we drop it for correct calculation
SELECT * from ProjectPortfolio01..CovidDeaths
WHERE location = 'World'
--Clearly there are 9 countries/locations with missing data population data is complete in all cases 
--i.e 9266 rows have no information in them so its better to drop them from our analysis
	
--SELECT * from ProjectPortfolio01..CovidDeaths
--WHERE location='Western Sahara'

--We re-write CONTINENT SUMMARY 

--Even though the population is already adjusted(They have taken constant population) in the data just for the sake of reproducible code in situations where population is not adjusted for 
--I have taken AVG of population for each country/location

