SELECT *
FROM dbo.covidDeaths
ORDER BY 3, 
         4;


--copy table
--select * into dbo.covidDeathsCopy from dbo.covidDeaths

-- copy data with locacation other than country to another table
--select * into dbo.covidDeathsNoCountryLocation from dbo.covidDeaths
--where continent is null

-- remove data with locacation other than country from proper table
--delete from dbo.covidDeaths 
--where continent is null


SELECT *
FROM dbo.covidVaccinations
ORDER BY 3, 
         4;


SELECT cd.location, 
       cd.date, 
       cd.total_cases, 
       cd.new_cases, 
       cd.total_deaths, 
	   cd.new_deaths,
       cd.population
FROM dbo.covidDeaths cd;

-- total cases vs total deaths

SELECT cd.location, 
       cd.date, 
       cd.total_cases, 
       cd.total_deaths, 
       (total_deaths / total_cases) * 100 AS [DeathPercentage]
FROM dbo.covidDeaths cd
where cd.location = 'Poland'


-- total cases vs population


SELECT cd.location, 
       cd.date,
	   cd.population,
       cd.total_cases, 
       cd.total_deaths, 
       (total_cases / population) * 100 AS [CasesPercentage]
FROM dbo.covidDeaths cd
where cd.location = 'Poland'


-- country with highest infection rate to population 

SELECT cd.location, 
       cd.population, 
       MAX(cd.total_cases) AS [HighestInfectionCount], 
       MAX(total_cases / population) * 100 AS [CasesPercentage]
FROM dbo.covidDeaths cd
where continent is not null
GROUP BY cd.location, 
         cd.population
ORDER BY 4 DESC;


-- country with highest death rate to population 

SELECT cd.location, 
       cd.population, 
       MAX(cast(cd.total_deaths as int)) AS [HighestDeathCount], 
       MAX(total_deaths / population) * 100 AS [DeathPercentage]
FROM dbo.covidDeaths cd
where continent is not null
GROUP BY cd.location, 
         cd.population
ORDER BY 4 DESC;

-- continents with highest death rate to population

SELECT deathByContry.continent, 
       SUM(deathByContry.HighestDeathCount) AS [DeathCount], 
       SUM(deathByContry.HighestDeathCount) / SUM(deathByContry.population) AS [DeathPercentage]
FROM
(
    SELECT cd.continent, 
           cd.location, 
           cd.population, 
           MAX(CAST(cd.total_deaths AS INT)) AS [HighestDeathCount], 
           MAX(total_deaths / population) * 100 AS [DeathPercentage]
    FROM dbo.covidDeaths cd
    WHERE continent IS NOT NULL
    GROUP BY cd.continent, 
             cd.location, 
             cd.population
) AS deathByContry
GROUP BY deathByContry.continent
ORDER BY 3 DESC;



-- country with highest death count

SELECT cd.location, 
       MAX(cast(cd.total_deaths as int)) AS [HighestDeathCount]
FROM dbo.covidDeaths cd
where continent is not null
GROUP BY cd.location 
ORDER BY [HighestDeathCount] DESC;

-- continents with highest death count

SELECT cd.continent, 
       MAX(cast(cd.total_deaths as int)) AS [HighestDeathCount]
FROM dbo.covidDeaths cd
where continent is not null
GROUP BY cd.continent 
ORDER BY [HighestDeathCount] DESC;


-- global numbers

SELECT cd.date AS Date, 
       SUM(cd.new_cases) AS [TotalCases], 
       SUM(CAST(cd.new_deaths AS INT)) AS [TotalDeaths], 
       (SUM(CAST(cd.new_deaths AS INT)) / SUM(cd.new_cases)) * 100 AS [DeathPercentage]
FROM dbo.covidDeaths cd
WHERE cd.continent IS NOT NULL
GROUP BY cd.date
order by 1,2

SELECT SUM(cd.new_cases) AS [TotalCases], 
       SUM(CAST(cd.new_deaths AS INT)) AS [TotalDeaths], 
       (SUM(CAST(cd.new_deaths AS INT)) / SUM(cd.new_cases)) * 100 AS [DeathPercentage]
FROM dbo.covidDeaths cd
WHERE cd.continent IS NOT NULL
order by 1,2
	   



-- total population vs vaccination

SELECT cd.continent, 
       cd.location, 
       cd.date, 
       cd.population, 
       cv.new_vaccinations, 
       SUM(CONVERT(INT, cv.new_vaccinations)) OVER(PARTITION BY cd.location
       ORDER BY cv.location, 
                cv.date) as [RollingPeopleVaccinated]
FROM dbo.covidDeaths cd
     JOIN covidVaccinations cv ON cd.date = cv.date
                                  AND cd.location = cv.location
WHERE cd.continent IS NOT NULL
      AND cd.location = 'Poland'
ORDER BY 2, 
         3;


-- population vs vaccination


		 WITH PopVsVac (
	Continent
	,Location
	,DATE
	,Population
	,Vaccination
	,RollingPeopleVaccinated
	)
AS (
	SELECT cd.continent
		,cd.location
		,cd.DATE
		,cd.population
		,cv.new_vaccinations
		,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (
			PARTITION BY cd.location ORDER BY cv.location
				,cv.DATE
			) AS [RollingPeopleVaccinated]
	FROM dbo.covidDeaths cd
	JOIN covidVaccinations cv ON cd.DATE = cv.DATE
		AND cd.location = cv.location
	WHERE cd.continent IS NOT NULL
		AND cd.location = 'Poland'
	)
SELECT Continent
	,Location
	,RollingPeopleVaccinated
	,(RollingPeopleVaccinated/Population)
FROM PopVsVac


drop table  if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
NewVaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
SELECT cd.continent
		,cd.location
		,cd.DATE
		,cd.population
		,cv.new_vaccinations
		,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (
			PARTITION BY cd.location ORDER BY cv.location
				,cv.DATE
			) AS [RollingPeopleVaccinated]
	FROM dbo.covidDeaths cd
	JOIN covidVaccinations cv ON cd.DATE = cv.DATE
		AND cd.location = cv.location
	WHERE cd.continent IS NOT NULL
		AND cd.location = 'Poland'

		SELECT Continent
	,Location
	,RollingPeopleVaccinated
	,(RollingPeopleVaccinated/Population)
FROM #PercentPopulationVaccinated


--

create view PercentPopulationVaccinated
as
SELECT cd.continent
		,cd.location
		,cd.DATE
		,cd.population
		,cv.new_vaccinations
		,SUM(CONVERT(INT, cv.new_vaccinations)) OVER (
			PARTITION BY cd.location ORDER BY cv.location
				,cv.DATE
			) AS [RollingPeopleVaccinated]
	FROM dbo.covidDeaths cd
	JOIN covidVaccinations cv ON cd.DATE = cv.DATE
		AND cd.location = cv.location
	WHERE cd.continent IS NOT NULL
		--AND cd.location = 'Poland'


select * from PercentPopulationVaccinated