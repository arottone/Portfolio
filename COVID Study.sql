-- Selecting data I am starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%state%'
and continent is not null
order by 1,2



-- Total Cases vs Population
-- Shows what percentage of population were infected with covid
Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%state%'
order by 1,2



-- Countries with highest infection rates compared to population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%state%'
Group by Location, Population
order by PercentPopulationInfected desc



-- Countries total death count per population sorted greatest to least
select continent, sum(convert(float,new_deaths)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by continent
order by TotalDeathCount desc



-- Showing highest daily death count per continent
select continent, max(convert(float,new_deaths)) as MaxDailyDeathCount
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by continent
order by MaxDailyDeathCount desc



-- GLOBAL NUMBERS
select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent IS NOT NULL
--group by date
order by 1,2



-- Total Population vs Vaccinations
-- Shows percentage of population that has received at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent IS NOT NULL
order by 2,3



-- Using CTE to perform calculation on partition by in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--,(/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent IS NOT NULL
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using temp table to perform calculation on partition by in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
--where dea.continent IS NOT NULL
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Creating views to store data for later viz
-- Continent, Country, Date, Population, Vaccines Administered on That Day, and a Rolling Count of Vaccines
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent IS NOT NULL


-- Global Case, Death, and Death Percentage Numbers
Create View GlobalNumbers as
Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent IS NOT NULL


--Max Daily Death Total by Continent
Create View MaxDailyDeathsByContinent as
select continent, max(convert(float,new_deaths)) as MaxDailyDeathCount
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by continent

--Total Deaths Per Continent
Create View TotalDeathsContinent as
select continent, sum(convert(float,new_deaths)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent IS NOT NULL
group by continent
