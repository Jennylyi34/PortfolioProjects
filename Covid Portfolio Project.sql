--Preview data to make sure it was loaded correctly
SELECT *
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
--WHERE continent IS NOT NULL
ORDER BY 3,4


--SELECT *
--FROM [Portfolio Project COVID Deaths].dbo.CovidVaccinations
--ORDER BY 3, 4


--Select data that we will be using
SELECT location, continent, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid the in U.S.
SELECT location, continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
WHERE location like '%states'
ORDER BY 1, 2

-- Total cases vs population
-- Shows what percentage of population got covid
SELECT location, continent, date, population, total_cases, (total_cases/population)*100 AS PopulationInfected
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
WHERE location like '%states'
ORDER BY 1, 2

-- Countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PopulationInfected
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
--WHERE location like '%states'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PopulationInfected DESC

-- Countries with the highest death counts
SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
--WHERE location like '%states'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

-- Highest death count by continent
SELECT location, MAX(CAST(total_deaths AS int)) AS HighestDeathCount
FROM [Portfolio Project COVID Deaths].dbo.CovidDeaths
--WHERE location like '%states'
WHERE continent IS NULL
	AND location NOT LIKE '%income'
GROUP BY location
ORDER BY HighestDeathCount DESC


-- GLOBAL NUMBERS by date
SELECT date, SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM [Portfolio Project COVID Deaths]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- Total global cases
SELECT SUM(new_cases) AS total_cases, 
	SUM(CAST(new_deaths AS INT)) AS total_deaths, 
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM [Portfolio Project COVID Deaths]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1


-- view vaccination table
SELECT *
FROM [Portfolio Project COVID Deaths]..CovidVaccinations


-- JOIN deaths and vaccination tables to look at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated -- use partition by to reset the count of new vaccinations for each new location
FROM [Portfolio Project COVID Deaths]..CovidDeaths dea
JOIN [Portfolio Project COVID Deaths]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated -- use partition by to reset the count of new vaccinations for each new location
FROM [Portfolio Project COVID Deaths]..CovidDeaths dea
JOIN [Portfolio Project COVID Deaths]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100 
FROM PopvsVac


-- using temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS numeric)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated -- use partition by to reset the count of new vaccinations for each new location
FROM [Portfolio Project COVID Deaths]..CovidDeaths dea
JOIN [Portfolio Project COVID Deaths]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100 AS rollingpercentvaccinated
FROM #PercentPopulationVaccinated


--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated -- use partition by to reset the count of new vaccinations for each new location
FROM [Portfolio Project COVID Deaths]..CovidDeaths dea
JOIN [Portfolio Project COVID Deaths]..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated