SELECT *
FROM DataExplorationProject.dbo.Covid_Deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT * 
--FROM DataExplorationProject..Covid_Vaccinations
--ORDER BY 3,4
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM DataExplorationProject.dbo.Covid_Deaths
ORDER BY 1,2

--Looking at total cases vs total deaths
--Show likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM DataExplorationProject.dbo.Covid_Deaths
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS InfectionPercentage
FROM DataExplorationProject.dbo.Covid_Deaths
WHERE location like '%states%'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to the population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentOfPopulationInfected
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentOfPopulationInfected DESC

--Showing Countries with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT

--SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
--FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
--WHERE continent IS NULL
--GROUP BY location
--ORDER BY TotalDeathCount DESC

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Show Continents with the Highest Death Count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS BY DATE

SELECT date, SUM(new_cases)AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--GLOBAL NUMBERS AS A WHOLE

SELECT SUM(new_cases)AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM DataExplorationProject.dbo.Covid_Deaths
--WHERE location like '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2

--COVID VACCINATIONS SETUP
--LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM DataExplorationProject..Covid_Deaths dea
JOIN DataExplorationProject..Covid_Vaccinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--

--LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountVaccinations,
FROM DataExplorationProject..Covid_Deaths dea
JOIN DataExplorationProject..Covid_Vaccinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


--USING CTE

WITH PopVersusVac (continent, location, date, population, new_vaccinations, RollingCountVaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingCountVaccinations
FROM DataExplorationProject..Covid_Deaths dea
JOIN DataExplorationProject..Covid_Vaccinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingCountVaccinations/population)*100
FROM PopVersusVac

--USING TEMP TABLE

DROP TABLE IF EXISTS #PercnetPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric, 
New_Vaccincations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingCountVaccinations
FROM DataExplorationProject..Covid_Deaths dea
JOIN DataExplorationProject..Covid_Vaccinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW PercentPopulationVacinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingCountVaccinations
FROM DataExplorationProject..Covid_Deaths dea
JOIN DataExplorationProject..Covid_Vaccinations vac
	ON	dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
