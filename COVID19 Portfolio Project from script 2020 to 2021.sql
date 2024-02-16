---COVID 19 DATA ANALYSIS FROM 2020 TO 2021

---will first check to make sure the datasets are in order
select *
from PortfolioProject..CovidDeaths

select *
from PortfolioProject..CovidVaccinations

-- First selecting needed columns

select location,date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

---filtered by location which is Ghana
select location,date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where location ='Ghana'
order by 1,2


--looking at the number of cases in a country and the number of deaths in percentages ie probability of dying if you get infected (total cases vs total deaths %)
select location ,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

---filtered by location which is Ghana
select location ,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from PortfolioProject..CovidDeaths
where location = 'Ghana'
order by 1,2

--Total cases vs population(shows the percentage of the population infected by covid)
select location, date,population, total_cases, (total_cases/population)*100 as infectedpercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

--filtered by location Ghana
select location, date,population, total_cases, (total_cases/population)*100 as infectedpercentage
from PortfolioProject..CovidDeaths
where location = 'Ghana'
order by 1,2

---countries with the highest infection rates
select location, population, MAX(total_cases) as highestinfectionnum, MAX((total_cases/population))*100 as infectedpopercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by infectedpopercentage desc

---breaking the highest death counts down by continents
--here 'total death' column read as an nvarchar so it has to be convertd into an integer using the cast function
select continent, MAX(cast(total_deaths as int)) as highestdeathcount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by highestdeathcount desc

---breaking down the number of death counts by countries
--here 'total death' column read as an nvarchar so it has to be convertd into an integer using the cast function
select location, MAX(cast(total_deaths as int)) as highestdeathnum
from PortfolioProject..CovidDeaths
where continent is not null
group by location
order by highestdeathnum desc

---Global covid numbers(total cases and total deaths)
select SUM(new_cases) as total_cases,  SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as globaldeathpercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

---Using Joins i am going to connect tables covid deaths and covid vaccinations show the percentage of the global population vaccinated
---i will be adding up total number of vaccinations by date and location and then using the partition by function to split vaccinations by location 
select covdeaths.continent, covdeaths.location, covdeaths.date, covdeaths.population, covvac.new_vaccinations
, SUM(CONVERT(int,covvac.new_vaccinations)) OVER(partition by covdeaths.location order by covdeaths.location, covdeaths.date) as newvacadd
from PortfolioProject..CovidDeaths covdeaths
join PortfolioProject..CovidVaccinations covvac
     on covdeaths.location = covvac.location
	 and covdeaths.date = covvac.date
where covdeaths.continent is not null
order by 2,3

---Total population vs vaccinations
---Using common table expressions, i will use the new column name 'newvacadd' by using the max number of every countries vaccinations to divide the total population
with popvsvac (continent, location, date, population,new_vaccinations, newvacadd) 
as
(
select covdeaths.continent, covdeaths.location, covdeaths.date, covdeaths.population, covvac.new_vaccinations
, SUM(CONVERT(int,covvac.new_vaccinations)) OVER(partition by covdeaths.location order by covdeaths.location, covdeaths.date) as newvacadd
from PortfolioProject..CovidDeaths covdeaths
join PortfolioProject..CovidVaccinations covvac
     on covdeaths.location = covvac.location
	 and covdeaths.date = covvac.date
where covdeaths.continent is not null
--order by 2,3
)
select *, (newvacadd/population)*100 as vacpercentage
from popvsvac


--- i will also use temp table to perform the same calculations i did for the common table expression where i used the max number of every countries vaccinations to divide the total population
--also the drop table if exists is important in case any changes needs to be done in the queries
drop table if exists #populationVaccinated
create table #populationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
newvacadd numeric
)
insert into #populationVaccinated
select covdeaths.continent, covdeaths.location, covdeaths.date, covdeaths.population, covvac.new_vaccinations
, SUM(CONVERT(int,covvac.new_vaccinations)) OVER(partition by covdeaths.location order by covdeaths.location, covdeaths.date) as newvacadd
from PortfolioProject..CovidDeaths covdeaths
join PortfolioProject..CovidVaccinations covvac
     on covdeaths.location = covvac.location
	 and covdeaths.date = covvac.date
where covdeaths.continent is not null
select *, (newvacadd/population)*100 as vacpercent
from #populationVaccinated

---creating view to save date for viz
create view populationVaccinated as
select covdeaths.continent, covdeaths.location, covdeaths.date, covdeaths.population, covvac.new_vaccinations
, SUM(CONVERT(int,covvac.new_vaccinations)) OVER(partition by covdeaths.location order by covdeaths.location, covdeaths.date) as newvacadd
from PortfolioProject..CovidDeaths covdeaths
join PortfolioProject..CovidVaccinations covvac
     on covdeaths.location = covvac.location
	 and covdeaths.date = covvac.date
where covdeaths.continent is not null
select *
from populationVaccinated


--END