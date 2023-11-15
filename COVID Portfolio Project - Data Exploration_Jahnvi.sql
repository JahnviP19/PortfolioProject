SELECT * 
FROM CovidDeaths
ORDER BY 3,4

SELECT * 
FROM CovidVaccinations
ORDER BY 3,4


-- data that we're going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2

--looking at total cases vs total detahs
--shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, 
	(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases), 0))*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

--looking at total cases vs population
--shows what percentage of population contracted in your country
SELECT location, date, population, total_cases, (population/total_cases)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location = 'India'
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
FROM CovidDeaths
Group BY location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null 
Group BY location
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not null 
Group BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null 
ORDER BY 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
	(
		SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
			SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
		FROM CovidDeaths dea
		JOIN CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
		WHERE dea.continent is not null 
	)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac On dea.location = vac.location and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 