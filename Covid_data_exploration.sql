Select *
From Portfolio_Project..covid_data$
Where continent is not null 
order by 3,4



-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From Portfolio_Project..covid_data$
Where continent is not null 
order by 1,2



-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio_Project..covid_data$
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- Checking total cases per countries with month and year

Select continent,Location, SUM(CASE WHEN new_cases is null then 0 else cast(new_cases as int)end) as New_cases,convert(varchar(7), date, 126)  AS Date
From Portfolio_Project..covid_data$
Where continent is not null 
Group by convert(varchar(7), date, 126),location,continent
order by location



-- Checking total deaths per country with month and year

Select Location, SUM(CASE WHEN new_deaths is null then 0 else CAST(new_deaths as int) end) as Death_counts,convert(varchar(7), date, 126)  AS Date
From Portfolio_Project..covid_data$
Where continent is not null 
Group by convert(varchar(7), date, 126),Location
order by location 



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio_Project..covid_data$
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, ROUND(SUM(cast(new_deaths as int))/SUM(New_Cases)*100,3) as DeathPercentage
From Portfolio_Project..covid_data$
where continent is not null and (new_deaths is not null and new_cases !=0 )and new_cases is not null



-- Creating Table to calculate percentage of people vaccinated

DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Location nvarchar(255),
Population numeric,
Fully_vaccinated numeric
)
Insert into PercentPopulationVaccinated
SELECT location,CAST(population as int),MAX(CASE WHEN people_fully_vaccinated is null then 0 else people_fully_vaccinated end)
From Portfolio_Project..covid_data$
WHERE continent is not null 
GROUP BY location,population



-- checking new table

Select *
FROM PercentPopulationVaccinated



-- Calculating infection fatality ratio

Select continent,location,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio_Project..covid_data$
where continent is not null and (new_deaths is not null and new_cases !=0 )and new_cases is not null
GROUP BY location,continent
ORDER BY DeathPercentage desc



-- Creating table for infection fatality ratio

DROP Table if exists InfectionFatalityRatio
Create Table InfectionFatalityRatio
(Continent nvarchar(255),
Country nvarchar(255),
FatalityRate float)

Insert into InfectionFatalityRatio
Select continent,location,ROUND(SUM(cast(new_deaths as int))/SUM(New_Cases)*100,3) as DeathPercentage
From Portfolio_Project..covid_data$
where continent is not null and (new_deaths is not null and new_cases !=0 )and new_cases is not null
GROUP BY location,continent



-- Viewing InfectionFatalityRatio table

SELECT *
FROM InfectionFatalityRatio



-- Creating View to store data for visuals

--Visual 1 cases vs death

Create or Alter View CasesVsDeath AS
SELECT SUM(CASE WHEN new_cases is null then 0 else cast(new_cases as int)end) as Total_cases,SUM(CASE WHEN new_deaths is null then 0 else CAST(new_deaths as int) end) as Total_Deaths,YEAR(date) as Date
FROM Portfolio_Project..covid_data$
WHERE continent is not null 
GROUP BY YEAR(date)



-- Visual 2 Human_Development_Index vs Death_rate

Create or Alter View HdiVsDeathRate AS
SELECT Inf.Continent,Inf.Country,CD.human_development_index,Inf.FatalityRate
FROM InfectionFatalityRatio Inf
LEFT JOIN Portfolio_Project..covid_data$ CD ON Inf.Country=CD.location
WHERE  (CD.human_development_index is not null AND CD.human_development_index!=0)
GROUP BY Inf.Country,CD.human_development_index,Inf.FatalityRate,Inf.Continent



-- Visual 3 Life_Expectancy vs Death_rate

Create or Alter View Life_ExpectancyVsDeath_Rate AS
SELECT Inf.Continent,Inf.Country,CD.life_expectancy,Inf.FatalityRate
FROM InfectionFatalityRatio Inf
LEFT JOIN Portfolio_Project..covid_data$ CD ON Inf.Country=CD.location
WHERE  CD.life_expectancy is not null AND CD.life_expectancy!=0
GROUP BY Inf.Country,CD.life_expectancy,Inf.FatalityRate,Inf.Continent



-- Visual 4 Ages_above_60_and_70 vs Death_rate

Create or Alter View AgesVsDeath_rate AS
SELECT Inf.Continent,Inf.Country,CD.aged_65_older,CD.aged_70_older,Inf.FatalityRate
FROM InfectionFatalityRatio Inf
LEFT JOIN Portfolio_Project..covid_data$ CD ON Inf.Country=CD.location
WHERE  CD.aged_65_older is not null AND CD.aged_70_older is not null AND CD.aged_65_older!=0 AND CD.aged_70_older!=0
GROUP BY Inf.Country,CD.aged_65_older,CD.aged_70_older,Inf.FatalityRate,Inf.Continent



-- Visual 5 Vaccinated vs Death_Rate

Create or Alter View VaccinatedVsDeath_rate AS
SELECT  Inf.Continent,Inf.Country,CAST(ROUND((Per.Fully_vaccinated/Per.Population)*100,3)AS numeric(36,2)) as Fully_vaccinated_rate,Inf.FatalityRate
FROM InfectionFatalityRatio Inf
LEFT JOIN PercentPopulationVaccinated Per ON Inf.Country=Per.Location
GROUP BY Inf.Country,Per.Fully_vaccinated,Per.Population,Inf.FatalityRate,Inf.Continent



-- Partition visual
Create View PopulationVaccinatedPercentage AS
Select continent, location, date, population, (CASE WHEN new_vaccinations is null THEN 0 else new_vaccinations end) as New_vaccinations, SUM(CASE WHEN new_vaccinations is null then 0 else CAST(new_vaccinations AS BIGint) end) OVER (Partition by Location Order by location, Date) as RollingPeopleVaccinated
From Portfolio_Project..covid_data$ dea
where dea.continent is not null 


