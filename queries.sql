/* Make a view of the countries and their active, recovered, and death totals for COVID-19 */

DROP VIEW IF EXISTS COVID19;
CREATE VIEW COVID19 AS
SELECT covid19_confirmed_global.country, covid19_deaths_global.April_12_2021 as deaths, covid19_recovered_global.April_12_2021 as recovered, covid19_confirmed_global.April_12_2021 - covid19_recovered_global.April_12_2021 - covid19_deaths_global.April_12_2021 as active
FROM covid19_confirmed_global INNER JOIN covid19_recovered_global
ON covid19_confirmed_global.country = covid19_recovered_global.country 
INNER JOIN covid19_deaths_global 
ON covid19_recovered_global.country = covid19_deaths_global.country;



/* Make a view of the countries and their total COVID-19 cases, in the decreasing order of cumulative total cases to date */
DROP VIEW IF EXISTS COVID19_Totals;
CREATE VIEW COVID19_Totals AS
SELECT country, deaths+recovered+active AS total
FROM COVID19
ORDER BY total DESC;

/* Make a view of the global COVID data by country per 1000 of the population. (To match up with Malaria data). */
DROP VIEW IF EXISTS COVID19_Incidence;
CREATE VIEW COVID19_Incidence as
SELECT COVID19_Totals.country, 1000*COVID19_Totals.total/Population.population as incidence
FROM COVID19_Totals INNER JOIN Population
ON COVID19_Totals.country = Population.country
ORDER BY incidence DESC;

/* List the top 10 countries, total cases to date, and the cumulative deaths for countries that have the highest rate of COVID-19 contraction increase in total covid cases over the last month, displayed in decreasing order.*/

DROP VIEW IF EXISTS CovidChange;
CREATE VIEW CovidChange AS
SELECT covid19_confirmed_global.country, (covid19_confirmed_global.April_12_2021-covid19_confirmed_global.April_11_2021) - (covid19_recovered_global.April_12_2021-covid19_recovered_global.April_11_2021) - (covid19_deaths_global.April_12_2021-covid19_deaths_global.April_11_2021) as dailyIncrease, (covid19_confirmed_global.April_12_2021-covid19_confirmed_global.March_12_2021) - (covid19_recovered_global.April_12_2021-covid19_recovered_global.March_12_2021) - (covid19_deaths_global.April_12_2021-covid19_deaths_global.March_12_2021) as monthlyIncrease
FROM covid19_confirmed_global INNER JOIN covid19_recovered_global
ON covid19_confirmed_global.country = covid19_recovered_global.country 
INNER JOIN covid19_deaths_global 
ON covid19_recovered_global.country = covid19_deaths_global.country;


DROP VIEW IF EXISTS HighestCovidIncreases;
CREATE VIEW HighestCovidIncreases AS
SELECT COVID19.country, monthlyIncrease, total, deaths
FROM COVID19 INNER JOIN COVID19_Totals
                                ON COVID19.country = COVID19_Totals.country 
                        INNER JOIN CovidChange 
                                ON COVID19_Totals.country = CovidChange.country
ORDER BY CovidChange.monthlyIncrease DESC
LIMIT 10;



/* List the countries where the rate of change of the difference in monthly case counts is negative -- i.e. where the number of new cases everyday is of a decreasing trend.*/

DROP VIEW IF EXISTS DecreasingCases;
CREATE VIEW DecreasingCases AS
SELECT COVID19.country, monthlyIncrease, total, deaths
FROM COVID19 INNER JOIN COVID19_Totals
                                ON COVID19.country = COVID19_Totals.country 
                        INNER JOIN CovidChange 
                                ON COVID19_Totals.country = CovidChange.country
WHERE CovidChange.monthlyIncrease < 0
ORDER BY CovidChange.monthlyIncrease DESC
LIMIT 10;



/* Which are the countries with highest malaria incident rates in the world where cumulative COVID19 
case counts are under 100,000 or deaths are under 10,000? */

DROP VIEW IF EXISTS HighMalariaLowCovid;
CREATE VIEW HighMalariaLowCovid as
SELECT Malaria.country, Malaria.malaria_incidence AS malaria_insidence, COVID19_Overall.total AS covid19_total, COVID19_Overall.deaths AS covid19_deaths
FROM Malaria INNER JOIN (SELECT COVID19_Totals.country, total, deaths
                               FROM COVID19_Totals INNER JOIN COVID19
                               ON COVID19_Totals.country = COVID19.country 
                               WHERE COVID19_Totals.total < 100000
                               OR COVID19.deaths < 10000) COVID19_Overall
ON COVID19_Overall.country = Malaria.country
ORDER BY Malaria.malaria_incidence DESC
LIMIT 10;

/*
What are the COVID-19 insidences for the 10 countries with the highest malaria rates?
*/

DROP VIEW IF EXISTS CovidIncidenceHighMalaria;
CREATE VIEW CovidIncidenceHighMalaria as
SELECT COVID19_Incidence.country, TopMalaria.malaria_incidence AS malaria_incidence, COVID19_Incidence.incidence AS covid19_incidence
FROM COVID19_Incidence INNER JOIN (SELECT country, malaria_incidence
                                   FROM Malaria
                                   ORDER BY Malaria.malaria_incidence DESC
                                   LIMIT 10) TopMalaria                             
ON COVID19_Incidence.country = TopMalaria.country
ORDER BY TopMalaria.malaria_incidence DESC
LIMIT 10;

/*
What are the COVID-19 insidences for the 10 countries with the lowest malaria rates?
*/

DROP VIEW IF EXISTS CovidIncidenceLowMalaria;
CREATE VIEW CovidIncidenceLowMalaria as
SELECT COVID19_Incidence.country, malaria_incidence, COVID19_Incidence.incidence AS covid19_incidence
FROM COVID19_Incidence INNER JOIN (SELECT country, malaria_incidence
                                   FROM Malaria
                                   ORDER BY Malaria.malaria_incidence ASC
                                   LIMIT 10) TopMalaria                             
ON COVID19_Incidence.country = TopMalaria.country
ORDER BY TopMalaria.malaria_incidence ASC
LIMIT 10;


/*
What are the COVID-19 insidences, malaria insidences, and life expectancy for the 10 most populous countries?
*/

DROP VIEW IF EXISTS MostPopulous;
CREATE VIEW MostPopulous as
SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
FROM Population INNER JOIN (SELECT Malaria.country, malaria_incidence, incidence AS covid_incidence, both_atbirth as life_expectancy
                                  FROM Malaria 
                                        INNER JOIN COVID19_Incidence
                                                ON Malaria.country = COVID19_Incidence.country 
                                        INNER JOIN Life_Expectancy   
                                                ON COVID19_Incidence.country = Life_Expectancy.country) AllComb                         
ON Population.country = AllComb.country
ORDER BY Population.population DESC
LIMIT 10;


/*
What are the COVID-19 insidences, malaria insidences, and life expectancy for the 10 least populous countries?
*/

DROP VIEW IF EXISTS LeastPopulous;
CREATE VIEW LeastPopulous as
SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
FROM Population INNER JOIN (SELECT Malaria.country, malaria_incidence, incidence AS covid_incidence, both_atbirth as life_expectancy
                                  FROM Malaria 
                                        INNER JOIN COVID19_Incidence
                                                ON Malaria.country = COVID19_Incidence.country 
                                        INNER JOIN Life_Expectancy   
                                                ON COVID19_Incidence.country = Life_Expectancy.country) AllComb                         
ON Population.country = AllComb.country
ORDER BY Population.population ASC
LIMIT 10;


/* Countries divided into their hemispheres */
DROP VIEW IF EXISTS CountryHemispheres;
CREATE VIEW CountryHemispheres as
WITH EastWestCountries as (
                        (SELECT country, 'East' as ew
                        FROM Countries               
                        WHERE longitude > 0)
                         
                        UNION
                        
                        (SELECT country, 'West' as ew
                        FROM Countries               
                        WHERE longitude <= 0)),
     NorthSouthCountries as (
                        (SELECT country, 'North' as ns
                        FROM Countries               
                        WHERE latitude > 0)
                        
                         UNION
                        
                        (SELECT country, 'South' as ns
                        FROM Countries               
                        WHERE latitude <= 0))
SELECT NorthSouthCountries.country, ns, ew
FROM NorthSouthCountries INNER JOIN EastWestCountries
ON NorthSouthCountries.country = EastWestCountries.country;


/* List the country names and the North/South hemisphere they are in on Earth, along with the total covid case counts and deaths */
DROP VIEW IF EXISTS NorthSouthCovid;
CREATE VIEW NorthSouthCovid as
SELECT CountryHemispheres.country, CountryHemispheres.ns, COVID19_Totals.total, COVID19.deaths
FROM CountryHemispheres INNER JOIN COVID19_Totals
                                ON CountryHemispheres.country = COVID19_Totals.country 
                        INNER JOIN COVID19 
                                ON COVID19_Totals.country = COVID19.country;
                                
                                
/* List the countries, their populations, and if they’re east and west of the GMT-0 meridian, along with the total covid case counts and deaths */
DROP VIEW IF EXISTS EastWestCovid;
CREATE VIEW EastWestCovid as
SELECT CountryHemispheres.country, CountryHemispheres.ew, Population.population, COVID19_Totals.total, COVID19.deaths
FROM CountryHemispheres INNER JOIN COVID19_Totals
                                ON CountryHemispheres.country = COVID19_Totals.country 
                        INNER JOIN COVID19 
                                ON COVID19_Totals.country = COVID19.country
                        INNER JOIN Population 
                                ON COVID19.country = Population.country;
                                
                                
/* List the aggregates of COVID cases and cumulative population in all Eastern countries and all Western countries, along with the count of countries in each bloc. */                            
DROP VIEW IF EXISTS EastWestAgg;
CREATE VIEW EastWestAgg as
SELECT CountryHemispheres.ew, SUM(COVID19_Totals.total) AS totalCases, COUNT(COVID19_Totals.country) AS numCountries
FROM COVID19_Totals INNER JOIN CountryHemispheres
ON COVID19_Totals.country = CountryHemispheres.country
GROUP BY CountryHemispheres.ew;


/* List the countries where the female life expectancy is at least 2% greater than male life expectancies. */  
DROP VIEW IF EXISTS FemLeGreaterThanMale;
CREATE VIEW FemLeGreaterThanMale as                          
SELECT Life_Expectancy.country, Life_Expectancy.male_atbirth AS "male", Life_Expectancy.female_atbirth AS "female"
FROM Life_Expectancy 
WHERE Life_Expectancy.female_atbirth >= 1.02 * Life_Expectancy.male_atbirth;

/* Aggregate the global life-expectancy data by greater than 2% life expectancy difference and less than 2% life expectancy difference between females and males,  along with the malaria incidence, COVID incidence, and total population sizes for each of those groups. */
DROP VIEW IF EXISTS LeAgg;
CREATE VIEW LeAgg as
WITH GreaterLess as (
                (SELECT country, 'Greater' as twoPercent
                FROM Life_Expectancy               
                WHERE Life_Expectancy.female_atbirth >= 1.02 * Life_Expectancy.male_atbirth)
                 
                UNION
                
                (SELECT country, 'Less' as twoPercent
                FROM Life_Expectancy               
                WHERE Life_Expectancy.female_atbirth < 1.02 * Life_Expectancy.male_atbirth))
SELECT GreaterLess.twoPercent, AVG(Malaria.malaria_incidence) AS 'average_malaria_incidence', AVG(COVID19_Incidence.incidence) AS 'average_covid19_incidence', AVG(Population.population) AS 'average_population'
FROM Population INNER JOIN GreaterLess
                                ON Population.country = GreaterLess.country 
                        INNER JOIN Malaria 
                                ON GreaterLess.country = Malaria.country
                        INNER JOIN COVID19_Incidence 
                                ON Malaria.country = COVID19_Incidence.country
GROUP BY GreaterLess.twoPercent;
                                
                                
/* List the 20 countries with the lowest life expectancy at birth along with their COVID-19 incidences and the the 20 countries with the lowest life expectancy at 60 years along with their COVID-19 incidences*/
DROP VIEW IF EXISTS LowLifeExpectancyAtBirthCovid;
CREATE VIEW LowLifeExpectancyAtBirthCovid as
SELECT Life_Expectancy.country, Life_Expectancy.both_atbirth, COVID19_Incidence.incidence AS 'covid19_incidence'
FROM COVID19_Incidence INNER JOIN Life_Expectancy                     
ON COVID19_Incidence.country = Life_Expectancy.country
ORDER BY Life_Expectancy.both_atbirth ASC
LIMIT 20;

DROP VIEW IF EXISTS LowLifeExpectancy60Covid;
CREATE VIEW LowLifeExpectancy60Covid as
SELECT Life_Expectancy.country, Life_Expectancy.both60, COVID19_Incidence.incidence AS 'covid19_incidence'
FROM COVID19_Incidence INNER JOIN Life_Expectancy                     
ON COVID19_Incidence.country = Life_Expectancy.country
ORDER BY Life_Expectancy.both60 ASC
LIMIT 20;