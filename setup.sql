-- setup.sql
-- This is a full setup script (text file) for our Project database in MariaDB.

-- Team Members: KEVIN GORMAN (JHED: KGORMAN4), UTKARSH SINGH (JHED: USINGH5)

-- To execute this file named auction_setup_example.sql as a script on dbase:
-- 
-- Option A: Execute it from ugrad. Save this file on ugrad in your current folder, then type:
--      mysql -h dbase.cs.jhu.edu -u YourUsername -D YourDatabaseName -p < auction_setup_example.sql
-- where you've replaced YourUsername and YourDatabaseName accordingly.
--
-- Option B: Execute it from your own laptop using DbVisualizer.
-- Connect to dbase via DbVisualizer specifying an appropriate database name in the
-- connection setup, then paste this into an SQL Commander window, and execute it. In DbVisualizer, 
-- you may find that you frequently need to click the "reload current view" to see table updates.



CREATE TABLE IF NOT EXISTS Countries(
   country   VARCHAR(58) NOT NULL PRIMARY KEY
  ,latitude  NUMERIC(10,6) NOT NULL
  ,longitude NUMERIC(10,6) NOT NULL
);
LOAD DATA LOCAL INFILE './processed/Countries.csv' INTO TABLE Countries
   FIELDS TERMINATED BY ',';  

CREATE TABLE IF NOT EXISTS Region(
   country   VARCHAR(58) NOT NULL PRIMARY KEY
  ,region  VARCHAR(100) NOT NULL,
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/regions.csv' INTO TABLE Region
   FIELDS TERMINATED BY ',';  

CREATE TABLE IF NOT EXISTS Democracies(
   country   VARCHAR(58) NOT NULL PRIMARY KEY
  ,democracy_index  NUMERIC(5,2) NOT NULL,
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/democracies.csv' INTO TABLE Democracies
   FIELDS TERMINATED BY ',';  

CREATE TABLE IF NOT EXISTS Population(
   country    VARCHAR(24) NOT NULL PRIMARY KEY,
   population INTEGER  NOT NULL,
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/Population.csv' INTO TABLE Population
   FIELDS TERMINATED BY ',';  

CREATE TABLE IF NOT EXISTS Life_Expectancy(
   country              VARCHAR(24) NOT NULL,
   year                 YEAR NOT NULL,
   age                  NUMERIC(2) NOT NULL,
   sex                  VARCHAR(10) NOT NULL,
   life_expectancy      NUMERIC(5,2) NOT NULL,
   PRIMARY KEY (country, year, age, sex),
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/Life_Expectancy.csv' INTO TABLE Life_Expectancy
   FIELDS TERMINATED BY ',';  



CREATE TABLE IF NOT EXISTS Malaria(
   country           VARCHAR(24) NOT NULL,
   year              YEAR NOT NULL,
   malaria_incidence NUMERIC(9,4) NOT NULL,
   PRIMARY KEY (country, year),
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/Malaria.csv' INTO TABLE Malaria
   FIELDS TERMINATED BY ',';  

-- ----------------------------------------------------------------------------------
-- PART D

-- COVID 19 GLOBAL CONFIRMED


CREATE TABLE IF NOT EXISTS covid19_confirmed_global(
   country           VARCHAR(58) NOT NULL,
   dataDate          DATE NOT NULL,
   confirmed         INTEGER NOT NULL
  ,PRIMARY KEY (country, dataDate), 
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/covid19_confirmed_global.csv' INTO TABLE covid19_confirmed_global
   FIELDS TERMINATED BY ',';  





-- covid19 deaths global

CREATE TABLE IF NOT EXISTS covid19_deaths_global(
   country           VARCHAR(58) NOT NULL,
   dataDate         DATE NOT NULL,
   deaths           INTEGER NOT NULL
  ,PRIMARY KEY (country, dataDate), 
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/covid19_deaths_global.csv' INTO TABLE covid19_deaths_global
   FIELDS TERMINATED BY ',';  



-- covid19 recovered global

CREATE TABLE IF NOT EXISTS covid19_recovered_global(
   country           VARCHAR(58) NOT NULL,
   dataDate         DATE NOT NULL,
   recovered        INTEGER NOT NULL
  ,PRIMARY KEY (country, dataDate), 
   FOREIGN KEY (country) REFERENCES Countries(country)  ON DELETE CASCADE  ON UPDATE CASCADE
);
LOAD DATA LOCAL INFILE './processed/covid19_recovered_global.csv' INTO TABLE covid19_recovered_global
   FIELDS TERMINATED BY ',';  




-- Queries



/* Make a view of the countries and their active, recovered, and death totals for COVID-19 */
DROP VIEW IF EXISTS COVID19;
CREATE VIEW COVID19 AS
WITH covid19_confirmed_global_sorted AS (SELECT t.country, confirmed, covid19_confirmed_global.dataDate FROM covid19_confirmed_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_confirmed_global GROUP BY country)t ON t.country = covid19_confirmed_global.country AND t.dataDate = covid19_confirmed_global.dataDate),
     covid19_recovered_global_sorted AS (SELECT t.country, recovered FROM covid19_recovered_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_recovered_global GROUP BY country)t ON t.country = covid19_recovered_global.country AND t.dataDate = covid19_recovered_global.dataDate),
     covid19_deaths_global_sorted AS (SELECT t.country, deaths FROM covid19_deaths_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_deaths_global GROUP BY country)t ON t.country = covid19_deaths_global.country AND t.dataDate = covid19_deaths_global.dataDate)
SELECT covid19_confirmed_global_sorted.country as country, covid19_confirmed_global_sorted.confirmed as confirmed, covid19_deaths_global_sorted.deaths as deaths, covid19_recovered_global_sorted.recovered as recovered, covid19_confirmed_global_sorted.confirmed - covid19_recovered_global_sorted.recovered - covid19_deaths_global_sorted.deaths as active, covid19_confirmed_global_sorted.dataDate
FROM covid19_confirmed_global_sorted 
INNER JOIN covid19_recovered_global_sorted
ON covid19_confirmed_global_sorted.country = covid19_recovered_global_sorted.country 
INNER JOIN covid19_deaths_global_sorted 
ON covid19_recovered_global_sorted.country = covid19_deaths_global_sorted.country; 


DROP VIEW IF EXISTS CovidChange;

CREATE VIEW CovidChange AS
WITH monthly AS (
                SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                LEFT JOIN COVID19
                ON covid19_confirmed_global.country = COVID19.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID19.dataDate, INTERVAL 1 MONTH)),
     daily AS (
                SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                LEFT JOIN COVID19
                ON covid19_confirmed_global.country = COVID19.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID19.dataDate, INTERVAL 1 DAY))
SELECT COVID19.country, (COVID19.active - daily.active) as dailyIncrease, (COVID19.active - monthly.active) as monthlyIncrease
FROM COVID19 INNER JOIN monthly
ON COVID19.country = monthly.country 
INNER JOIN daily 
ON COVID19.country = daily.country;
/*
CREATE VIEW COVID19 AS
SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed as confirmed, covid19_deaths_global.deaths as deaths, covid19_recovered_global.recovered as recovered, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
FROM covid19_confirmed_global 
INNER JOIN covid19_recovered_global
ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
INNER JOIN covid19_deaths_global 
ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
WHERE covid19_confirmed_global.dataDate = "2021-04-12";
*/

/* Make a view of the countries and their total COVID-19 cases, in the decreasing order of cumulative total cases to date */
/*
DROP VIEW IF EXISTS COVID19_Totals;
CREATE VIEW COVID19_Totals AS
SELECT country, deaths+recovered+active AS total
FROM COVID19
ORDER BY total DESC;
*/
/* Make a view of the global COVID data by country per 1000 of the population. (To match up with Malaria data). */
DROP VIEW IF EXISTS COVID19_Incidence;
CREATE VIEW COVID19_Incidence as
SELECT COVID19.country, 1000*COVID19.confirmed/Population.population as incidence
FROM COVID19 INNER JOIN Population
ON COVID19.country = Population.country
ORDER BY incidence DESC;

/* List the top 10 countries, total cases to date, and the cumulative deaths for countries that have the highest rate of COVID-19 contraction increase in total covid cases over the last month, displayed in decreasing order.*/
/*
DROP VIEW IF EXISTS CovidChange;
CREATE VIEW CovidChange AS
WITH monthly AS (
                SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                WHERE covid19_confirmed_global.dataDate = "2021-03-12"),
     daily AS (
                SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                WHERE covid19_confirmed_global.dataDate = "2021-04-11")
SELECT COVID19.country, (COVID19.active - daily.active) as dailyIncrease, (COVID19.active - monthly.active) as monthlyIncrease
FROM COVID19 INNER JOIN monthly
ON COVID19.country = monthly.country 
INNER JOIN daily 
ON COVID19.country = daily.country;
*/


DROP VIEW IF EXISTS MostRecentMalaria;
CREATE VIEW MostRecentMalaria AS
SELECT country, malaria_incidence
FROM (SELECT country, malaria_incidence, MAX(year) AS year
      FROM Malaria
      GROUP BY country) t;

DROP VIEW IF EXISTS MostRecentLifeExpectancy;
CREATE VIEW MostRecentLifeExpectancy AS
SELECT country, age, sex, life_expectancy
FROM (SELECT country, age, sex, life_expectancy, MAX(year) AS year
      FROM Life_Expectancy
      GROUP BY country, age, sex) t
ORDER BY country, age DESC;

/*
DROP VIEW IF EXISTS COVID19;
CREATE VIEW COVID19 AS
WITH covid19_confirmed_global_sorted AS (SELECT t.country, confirmed, covid19_confirmed_global.dataDate FROM covid19_confirmed_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_confirmed_global GROUP BY country)t ON t.country = covid19_confirmed_global.country AND t.dataDate = covid19_confirmed_global.dataDate),
     covid19_recovered_global_sorted AS (SELECT t.country, recovered FROM covid19_recovered_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_recovered_global GROUP BY country)t ON t.country = covid19_recovered_global.country AND t.dataDate = covid19_recovered_global.dataDate),
     covid19_deaths_global_sorted AS (SELECT t.country, deaths FROM covid19_deaths_global INNER JOIN (SELECT country, MAX(dataDate) AS dataDate FROM covid19_deaths_global GROUP BY country)t ON t.country = covid19_deaths_global.country AND t.dataDate = covid19_deaths_global.dataDate)
SELECT covid19_confirmed_global_sorted.country as country, covid19_confirmed_global_sorted.confirmed as confirmed, covid19_deaths_global_sorted.deaths as deaths, covid19_recovered_global_sorted.recovered as recovered, covid19_confirmed_global_sorted.confirmed - covid19_recovered_global_sorted.recovered - covid19_deaths_global_sorted.deaths as active, covid19_confirmed_global_sorted.dataDate
FROM covid19_confirmed_global_sorted 
INNER JOIN covid19_recovered_global_sorted
ON covid19_confirmed_global_sorted.country = covid19_recovered_global_sorted.country 
INNER JOIN covid19_deaths_global_sorted 
ON covid19_recovered_global_sorted.country = covid19_deaths_global_sorted.country; 

DROP VIEW IF EXISTS monthly;
CREATE VIEW monthly AS
SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as activeMonthly
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                LEFT JOIN COVID19 
                ON covid19_confirmed_global.country = COVID19.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID19.dataDate, INTERVAL 1 MONTH);

DROP VIEW IF EXISTS daily;
CREATE VIEW daily AS
SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as activeDaily
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                LEFT JOIN COVID19
                ON covid19_confirmed_global.country = COVID19.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID19.dataDate, INTERVAL 1 DAY);


DROP VIEW IF EXISTS montlyIncrease;
CREATE VIEW montlyIncrease AS
SELECT COVID19.country, (COVID19.active - monthly.activeMonthly) as monthlyIncrease
FROM COVID19 INNER JOIN monthly
ON COVID19.country = monthly.country;

DROP VIEW IF EXISTS dailyIncrease;
CREATE VIEW dailyIncrease AS
SELECT COVID19.country, (COVID19.active - daily.activeDaily) as dailyIncrease
FROM COVID19 INNER JOIN daily
ON COVID19.country = daily.country;


DROP VIEW IF EXISTS CovidChange2;
CREATE VIEW CovidChange2 AS
SELECT COVID19.country, dailyIncrease.dailyIncrease, montlyIncrease.monthlyIncrease
FROM COVID19 INNER JOIN dailyIncrease
ON COVID19.country = dailyIncrease.country
INNER JOIN montlyIncrease
ON COVID19.country = montlyIncrease.country;
*/

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
SELECT CountryHemispheres.country, CountryHemispheres.ns, COVID19.confirmed, COVID19.deaths
FROM CountryHemispheres INNER JOIN COVID19
                                ON CountryHemispheres.country = COVID19.country;
                                
                                
/* List the countries, their populations, and if they’re east and west of the GMT-0 meridian, along with the total covid case counts and deaths */
DROP VIEW IF EXISTS EastWestCovid;
CREATE VIEW EastWestCovid as
SELECT CountryHemispheres.country, CountryHemispheres.ew, COVID19.confirmed, COVID19.deaths
FROM CountryHemispheres INNER JOIN COVID19
                                ON CountryHemispheres.country = COVID19.country;
                                
                                
/* List the aggregates of COVID cases and cumulative population in all Eastern countries and all Western countries, along with the count of countries in each bloc. */                            
DROP VIEW IF EXISTS EastWestAgg;
CREATE VIEW EastWestAgg as
SELECT CountryHemispheres.ew, SUM(COVID19.confirmed) AS confirmed, COUNT(COVID19.country) AS numCountries
FROM COVID19 INNER JOIN CountryHemispheres
ON COVID19.country = CountryHemispheres.country
GROUP BY CountryHemispheres.ew;


DELIMITER //

DROP PROCEDURE IF EXISTS Query1 //
CREATE PROCEDURE Query1(IN c VARCHAR(58))
BEGIN
   SELECT year, malaria_incidence
   FROM Malaria 
   WHERE country = c;

END; //

DROP PROCEDURE IF EXISTS TopMalaria //
CREATE PROCEDURE TopMalaria()
BEGIN
   SELECT country, malaria_incidence
   FROM MostRecentMalaria 
   ORDER BY MostRecentMalaria.malaria_incidence DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestMalaria //
CREATE PROCEDURE LowestMalaria()
BEGIN
   SELECT country, malaria_incidence
   FROM MostRecentMalaria
   ORDER BY MostRecentMalaria.malaria_incidence ASC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS TopPopulation //
CREATE PROCEDURE TopPopulation()
BEGIN
   SELECT country, population
   FROM Population 
   ORDER BY population DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestPopulation //
CREATE PROCEDURE LowestPopulation()
BEGIN
   SELECT country, population
   FROM Population 
   ORDER BY population ASC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS TopDemocracy //
CREATE PROCEDURE TopDemocracy()
BEGIN
   SELECT country, democracy_index 
   FROM Democracies 
   ORDER BY democracy_index DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestDemocracy //
CREATE PROCEDURE LowestDemocracy()
BEGIN
   SELECT country, democracy_index
   FROM Democracies 
   ORDER BY democracy_index ASC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS TopLifeExpectancy //
CREATE PROCEDURE TopLifeExpectancy()
BEGIN
   SELECT country, life_expectancy
   FROM Life_Expectancy 
   WHERE age = 60
   ORDER BY life_expectancy DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestLifeExpectancy //
CREATE PROCEDURE LowestLifeExpectancy()
BEGIN
   SELECT country, life_expectancy
   FROM Life_Expectancy 
   WHERE age = 60
   ORDER BY life_expectancy ASC
   LIMIT 20;

END; //



--Which are the countries with malaria incidence rates in the world where cumulative COVID19 case counts are (UNDER/OVER) (X amount) or deaths are (UNDER/OVER) (X amount)?
DROP PROCEDURE IF EXISTS CovidMalaria1 //
CREATE PROCEDURE CovidMalaria1(IN underover1 VARCHAR(5), IN x1 NUMERIC(9,4), IN underover2 VARCHAR(5), IN x2 NUMERIC(9,4))
BEGIN
   IF underover1 = 'UNDER' AND underover2 = 'UNDER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE COVID19.confirmed < x1
      OR COVID19.deaths < x2
      ORDER BY COVID19.confirmed ASC, COVID19.deaths ASC;
   ELSEIF underover1 = 'OVER' AND underover2 = 'UNDER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE COVID19.confirmed > x1
      OR COVID19.deaths < x2
      ORDER BY COVID19.confirmed ASC, COVID19.deaths DESC;
   ELSEIF underover1 = 'UNDER' AND underover2 = 'OVER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE COVID19.confirmed < x1
      OR COVID19.deaths > x2
      ORDER BY COVID19.confirmed DESC, COVID19.deaths ASC;
   ELSE
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE COVID19.confirmed > x1
      OR COVID19.deaths > x2
      ORDER BY COVID19.confirmed DESC, COVID19.deaths DESC;
   END IF;
END; //

-- What are the COVID-19 incidents for the countries with malaria rates (UNDER/ABOVE) (X amount)? 

DROP PROCEDURE IF EXISTS CovidMalaria2 //
CREATE PROCEDURE CovidMalaria2(IN underover VARCHAR(5), IN x NUMERIC(9,4))
BEGIN
   IF underover = 'UNDER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.recovered AS recovered, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE MostRecentMalaria.malaria_incidence < x
      ORDER BY MostRecentMalaria.malaria_incidence ASC;
   ELSE
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.recovered AS recovered, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN MostRecentMalaria                       
      ON COVID19.country = MostRecentMalaria.country
      WHERE MostRecentMalaria.malaria_incidence > x
      ORDER BY MostRecentMalaria.malaria_incidence DESC;
   END IF;
END; //

--What are the COVID-19 incidents, malaria incidences, and life expectancy for the 30 (MOST/LEAST populous countries?
DROP PROCEDURE IF EXISTS MostPopulous //
CREATE PROCEDURE MostPopulous(IN underover VARCHAR(5), IN x NUMERIC(9,4))
BEGIN
      IF underover = 'UNDER' THEN
         SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
         FROM Population INNER JOIN (SELECT MostRecentMalaria.country, malaria_incidence, incidence AS covid_incidence, life_expectancy
                                          FROM MostRecentMalaria 
                                                INNER JOIN COVID19_Incidence
                                                         ON MostRecentMalaria.country = COVID19_Incidence.country 
                                                INNER JOIN MostRecentLifeExpectancy   
                                                         ON COVID19_Incidence.country = MostRecentLifeExpectancy.country
                                                WHERE MostRecentLifeExpectancy.sex = "Both sexes"
                                                AND MostRecentLifeExpectancy.age = 60) AllComb                         
         ON Population.country = AllComb.country
         WHERE Population.population < x
         ORDER BY Population.population DESC;
      ELSE
         SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
         FROM Population INNER JOIN (SELECT MostRecentMalaria.country, malaria_incidence, incidence AS covid_incidence, life_expectancy
                                          FROM MostRecentMalaria 
                                                INNER JOIN COVID19_Incidence
                                                         ON MostRecentMalaria.country = COVID19_Incidence.country 
                                                INNER JOIN MostRecentLifeExpectancy   
                                                         ON COVID19_Incidence.country = MostRecentLifeExpectancy.country
                                                WHERE MostRecentLifeExpectancy.sex = "Both sexes"
                                                AND MostRecentLifeExpectancy.age = 60) AllComb                           
         ON Population.country = AllComb.country
         WHERE Population.population > x
         ORDER BY Population.population ASC;
      END IF;
END; //


--List the country names and the (NORTH HEM/SOUTH HEM) they are in on Earth, along with the total covid case counts and deaths.
DROP PROCEDURE IF EXISTS RegionCOVID1 //
CREATE PROCEDURE RegionCOVID1(IN hem VARCHAR(10))
BEGIN
      IF hem = 'NORTH HEM' THEN
         SELECT CountryHemispheres.ns as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN CountryHemispheres
         ON COVID19.country = CountryHemispheres.country
         WHERE CountryHemispheres.ns = "NORTH"
         GROUP BY CountryHemispheres.ns;
      ELSE
         SELECT CountryHemispheres.ns as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN CountryHemispheres
         ON COVID19.country = CountryHemispheres.country
         WHERE CountryHemispheres.ns = "SOUTH"
         GROUP BY CountryHemispheres.ns;
      END IF;
END; //

--List the country names and the (EAST/WEST) they are in on Earth, along with the total covid case counts and deaths.
DROP PROCEDURE IF EXISTS RegionCOVID2 //
CREATE PROCEDURE RegionCOVID2(IN region1 VARCHAR(20), IN region2 VARCHAR(20))
BEGIN
      SELECT region, confirmed, recovered, active, deaths
      FROM (SELECT Region.region as region, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
            FROM COVID19 INNER JOIN Region
            ON COVID19.country = Region.country
            WHERE region = region1
            OR region = region2
            GROUP BY Region.region)t;
END; //


--List the country names and the (EAST/WEST) they are in on Earth, along with the total covid case counts and deaths.
DROP PROCEDURE IF EXISTS RegionCOVID3 //
CREATE PROCEDURE RegionCOVID3(IN hem VARCHAR(10))
BEGIN
      IF hem = 'EAST' THEN
         SELECT CountryHemispheres.ew as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN CountryHemispheres
         ON COVID19.country = CountryHemispheres.country
         WHERE CountryHemispheres.ew = "EAST"
         GROUP BY CountryHemispheres.ew;
      ELSE
         SELECT CountryHemispheres.ew as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN CountryHemispheres
         ON COVID19.country = CountryHemispheres.country
         WHERE CountryHemispheres.ew = "WEST"
         GROUP BY CountryHemispheres.ew;
      END IF;
END; //

-- Show total population of each hemisphere
DROP PROCEDURE IF EXISTS GeographicAggregate1 //
CREATE PROCEDURE GeographicAggregate1()
BEGIN
   SELECT hemisphere, population
   FROM ((SELECT CountryHemispheres.ew as hemisphere, SUM(Population.population) AS population
         FROM Population INNER JOIN CountryHemispheres
         ON Population.country = CountryHemispheres.country
         GROUP BY CountryHemispheres.ew)
         UNION
      (SELECT CountryHemispheres.ns as hemisphere, SUM(Population.population) AS population
         FROM Population INNER JOIN CountryHemispheres
         ON Population.country = CountryHemispheres.country
         GROUP BY CountryHemispheres.ns))t;
END; //

-- Show weighted average democracy index data for each hemisphere
DROP PROCEDURE IF EXISTS GeographicAggregate2 //
CREATE PROCEDURE GeographicAggregate2()
BEGIN
   WITH hemPop AS ((SELECT CountryHemispheres.ew as hemisphere, SUM(Population.population) AS population
                  FROM Population INNER JOIN CountryHemispheres
                  ON Population.country = CountryHemispheres.country
                  GROUP BY CountryHemispheres.ew)
               UNION
               (SELECT CountryHemispheres.ns as hemisphere, SUM(Population.population) AS population
                  FROM Population INNER JOIN CountryHemispheres
                  ON Population.country = CountryHemispheres.country
                  GROUP BY CountryHemispheres.ns))
   SELECT hemPop.hemisphere, weightedDemocracy/hemPop.population as weightedAverageDemocracy
   FROM ((SELECT CountryHemispheres.ew as hemisphere,  SUM(Population.population * Democracies.democracy_index) AS weightedDemocracy
         FROM Population INNER JOIN CountryHemispheres 
         ON Population.country = CountryHemispheres.country
         INNER JOIN Democracies
         ON Democracies.country = CountryHemispheres.country
         GROUP BY  CountryHemispheres.ew)
         UNION
      (SELECT CountryHemispheres.ns as hemisphere, SUM(Population.population * Democracies.democracy_index) AS weightedDemocracy
         FROM Population INNER JOIN CountryHemispheres
         ON Population.country = CountryHemispheres.country
         INNER JOIN Democracies
         ON Democracies.country = CountryHemispheres.country
         GROUP BY  CountryHemispheres.ns))t
   INNER JOIN hemPop  
   ON hemPop.hemisphere = t.hemisphere;
END; //


-- Show total population of each region
DROP PROCEDURE IF EXISTS GeographicAggregate3 //
CREATE PROCEDURE GeographicAggregate3()
BEGIN
   SELECT region, population
   FROM (SELECT Region.region as region, SUM(Population.population) AS population
         FROM Population INNER JOIN Region
         ON Population.country = Region.country
         GROUP BY Region.region)t;   
END; //

-- Show weighted average democracy index data for each hemisphere
DROP PROCEDURE IF EXISTS GeographicAggregate4 //
CREATE PROCEDURE GeographicAggregate4()
BEGIN
   WITH regPop AS (SELECT region, population
                  FROM (SELECT Region.region as region, SUM(Population.population) AS population
                           FROM Population INNER JOIN Region
                           ON Population.country = Region.country
                           GROUP BY Region.region)t)
   SELECT regPop.region, SUM(weightedDemocracy)/regPop.population as weightedAverageDemocracy
   FROM  (SELECT Region.region as region, Population.population * Democracies.democracy_index AS weightedDemocracy
         FROM Population INNER JOIN Region
         ON Population.country = Region.country
         INNER JOIN Democracies
         ON Democracies.country = Region.country)t
   INNER JOIN regPop  
   ON regPop.region = t.region
   GROUP BY t.region;

END; //


-- Compare the 30 countries each with the (HIGHEST / LOWEST) democracy scores for total COVID-19
DROP PROCEDURE IF EXISTS HealthcareVDemocracy1 //
CREATE PROCEDURE HealthcareVDemocracy1(IN underover VARCHAR(7))
BEGIN
   IF underover = 'LOWEST' THEN
      SELECT Democracies.country, democracy_index, confirmed, recovered, active, deaths
      FROM COVID19 INNER JOIN Democracies
      ON Democracies.country = COVID19.country
      ORDER BY democracy_index ASC
      LIMIT 30;
   ELSE
      SELECT Democracies.country, democracy_index, confirmed, recovered, active, deaths
      FROM COVID19 INNER JOIN Democracies
      ON Democracies.country = COVID19.country
      ORDER BY democracy_index DESC
      LIMIT 30;
   END IF;
END; //

-- Compare the 30 countries each with the (HIGHEST / LOWEST) democracy scores for malaria incidence
DROP PROCEDURE IF EXISTS HealthcareVDemocracy2 //
CREATE PROCEDURE HealthcareVDemocracy2(IN underover VARCHAR(7))
BEGIN
   IF underover = 'LOWEST' THEN
      SELECT Democracies.country, democracy_index, malaria_incidence
      FROM MostRecentMalaria INNER JOIN Democracies
      ON Democracies.country = MostRecentMalaria.country
      ORDER BY democracy_index ASC
      LIMIT 30;
   ELSE
      SELECT Democracies.country, democracy_index, malaria_incidence
      FROM MostRecentMalaria INNER JOIN Democracies
      ON Democracies.country = MostRecentMalaria.country
      ORDER BY democracy_index DESC
      LIMIT 30;
   END IF;
END; //

-- List the countries where the female life expectancy is at least 2% greater than male life expectancies. 
DROP PROCEDURE IF EXISTS LifeExpectancy1 //
CREATE PROCEDURE LifeExpectancy1()
BEGIN                       
   WITH Male AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "male_life_expectancy"
                  FROM MostRecentLifeExpectancy 
                  WHERE age = 60
                  AND sex = "Male"),
      Female AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "female_life_expectancy"
                  FROM MostRecentLifeExpectancy 
                  WHERE age = 60
                  AND sex = "Female")
   SELECT Male.country, male_life_expectancy, female_life_expectancy
   FROM Male INNER JOIN Female
   WHERE Male.country = Female.country
   AND Female.female_life_expectancy >= 1.02 * Male.male_life_expectancy;
END; //
--List the 30 countries with the (HIGHEST/LOWEST) life expectancy at along with their malaria rates
DROP PROCEDURE IF EXISTS LifeExpectancy2 //
CREATE PROCEDURE LifeExpectancy2(IN underover VARCHAR(10))
BEGIN
      IF underover = 'LOWEST' THEN
         SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy, COVID19_Incidence.incidence AS 'covid19_incidence'
         FROM COVID19_Incidence INNER JOIN MostRecentLifeExpectancy                     
         ON COVID19_Incidence.country = MostRecentLifeExpectancy.country
         WHERE MostRecentLifeExpectancy.age = 60
         ORDER BY MostRecentLifeExpectancy.life_expectancy ASC
         LIMIT 30;
      ELSE
         SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy, COVID19_Incidence.incidence AS 'covid19_incidence'
         FROM COVID19_Incidence INNER JOIN MostRecentLifeExpectancy                     
         ON COVID19_Incidence.country = MostRecentLifeExpectancy.country
         WHERE MostRecentLifeExpectancy.age = 60
         ORDER BY MostRecentLifeExpectancy.life_expectancy DESC
         LIMIT 30;
      END IF;
END; //


-- List the aggregates of COVID cases across (REGION/HEMISPHERE/DEMOCRACY/2% LIFE EXP DIFF/POP SIZE)
DROP PROCEDURE IF EXISTS DiseaseAggregates1 //
CREATE PROCEDURE DiseaseAggregates1(IN agg VARCHAR(20))
BEGIN
      IF agg = 'REGION' THEN
         SELECT Region.region as region, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN Region
         ON COVID19.country = Region.country
         GROUP BY Region.region;
      ELSEIF agg = 'HEMISPHERE' THEN
         SELECT hemisphere, confirmed, recovered, active, deaths
         FROM ((SELECT CountryHemispheres.ew as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
                  FROM COVID19 INNER JOIN CountryHemispheres
                  ON COVID19.country = CountryHemispheres.country

                  GROUP BY CountryHemispheres.ew)
               UNION
                  (SELECT CountryHemispheres.ns as hemisphere, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
                  FROM COVID19 INNER JOIN CountryHemispheres
                  ON COVID19.country = CountryHemispheres.country

                  GROUP BY CountryHemispheres.ns))t;
      ELSEIF agg = 'DEMOCRACY' THEN
         WITH DemAuth AS ((SELECT country, "Democratic" AS demauth
                  FROM Democracies
                  WHERE democracy_index > 6)
                  UNION
                  (SELECT country,  "Hybrid" AS demauth
                  FROM Democracies
                  WHERE democracy_index <= 6
                  AND democracy_index > 4)
                  UNION
                  (SELECT country,  "Authoritatrian" AS demauth
                  FROM Democracies
                  WHERE democracy_index <= 4))
         SELECT DemAuth.demauth as demauth, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN DemAuth
         ON COVID19.country = DemAuth.country
         GROUP BY DemAuth.demauth;
      ELSEIF agg = '2% LIFE EXP DIFF' THEN
         WITH 2Percent AS (
               WITH Male AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "male_life_expectancy"
                                 FROM MostRecentLifeExpectancy 
                                 WHERE age = 60
                                 AND sex = "Male"),
                     Female AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "female_life_expectancy"
                                 FROM MostRecentLifeExpectancy 
                                 WHERE age = 60
                                 AND sex = "Female")
                  SELECT Male.country, male_life_expectancy, female_life_expectancy
                  FROM Male INNER JOIN Female
                  ON Male.country = Female.country
                  AND Female.female_life_expectancy >= 1.02 * Male.male_life_expectancy)
         SELECT 2Percent.country as country, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths
         FROM COVID19 INNER JOIN 2Percent
         ON COVID19.country = 2Percent.country
         GROUP BY 2Percent.country;
      ELSE
         WITH PopSize AS ((SELECT country, "Small, < 1 million" AS popSize
                  FROM Population
                  WHERE population < 1000000)
                  UNION
                  (SELECT country, "Medium, 1 to 10 million" AS popSize
                  FROM Population
                  WHERE population >= 1000000
                  AND population < 10000000)
                  UNION
                  (SELECT country, "Large, > 10 million" AS popSize
                  FROM Population
                  WHERE population > 10000000))
         SELECT PopSize.popSize as popSize, SUM(COVID19.confirmed) AS confirmed, SUM(COVID19.recovered) AS recovered, SUM(COVID19.active) AS active, SUM(COVID19.deaths) AS deaths, AVG(COVID19_Incidence.incidence) AS incidence
         FROM COVID19 INNER JOIN PopSize
         ON COVID19.country = PopSize.country
         INNER JOIN COVID19_Incidence
         ON COVID19.country = COVID19_Incidence.country
         GROUP BY PopSize.popSize;
      END IF;
END; //


-- List the aggregates of Malaria cases across (REGION/HEMISPHERE/DEMOCRACY/2% LIFE EXP DIFF/POP SIZE)
DROP PROCEDURE IF EXISTS DiseaseAggregates2 //
CREATE PROCEDURE DiseaseAggregates2(IN agg VARCHAR(20))
BEGIN
      IF agg = 'REGION' THEN
         SELECT Region.region as region, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
         FROM MostRecentMalaria INNER JOIN Region
         ON MostRecentMalaria.country = Region.country
         GROUP BY Region.region;
      ELSEIF agg = 'HEMISPHERE' THEN
         SELECT hemisphere, malaria_incidence
         FROM ((SELECT CountryHemispheres.ew as hemisphere, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
                  FROM MostRecentMalaria INNER JOIN CountryHemispheres
                  ON MostRecentMalaria.country = CountryHemispheres.country

                  GROUP BY CountryHemispheres.ew)
               UNION
                  (SELECT CountryHemispheres.ns as hemisphere, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
                  FROM MostRecentMalaria INNER JOIN CountryHemispheres
                  ON MostRecentMalaria.country = CountryHemispheres.country

                  GROUP BY CountryHemispheres.ns))t;
      ELSEIF agg = 'DEMOCRACY' THEN
         WITH DemAuth AS ((SELECT country, "Democratic" AS demauth
                  FROM Democracies
                  WHERE democracy_index > 6)
                  UNION
                  (SELECT country,  "Hybrid" AS demauth
                  FROM Democracies
                  WHERE democracy_index <= 6
                  AND democracy_index > 4)
                  UNION
                  (SELECT country,  "Authoritatrian" AS demauth
                  FROM Democracies
                  WHERE democracy_index <= 4))
         SELECT DemAuth.demauth as demauth, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
         FROM MostRecentMalaria INNER JOIN DemAuth
         ON MostRecentMalaria.country = DemAuth.country
         GROUP BY DemAuth.demauth;
      ELSEIF agg = '2% LIFE EXP DIFF' THEN
         WITH 2Percent AS (
               WITH Male AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "male_life_expectancy"
                                 FROM MostRecentLifeExpectancy 
                                 WHERE age = 60
                                 AND sex = "Male"),
                     Female AS (SELECT MostRecentLifeExpectancy.country, MostRecentLifeExpectancy.life_expectancy AS "female_life_expectancy"
                                 FROM MostRecentLifeExpectancy 
                                 WHERE age = 60
                                 AND sex = "Female")
                  SELECT Male.country, male_life_expectancy, female_life_expectancy
                  FROM Male INNER JOIN Female
                  ON Male.country = Female.country
                  AND Female.female_life_expectancy >= 1.02 * Male.male_life_expectancy)
         SELECT 2Percent.country as country, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
         FROM MostRecentMalaria INNER JOIN 2Percent
         ON MostRecentMalaria.country = 2Percent.country
         GROUP BY 2Percent.country;
      ELSE
         WITH PopSize AS ((SELECT country, "Small, < 1 million" AS popSize
                  FROM Population
                  WHERE population < 1000000)
                  UNION
                  (SELECT country, "Medium, 1 to 10 million" AS popSize
                  FROM Population
                  WHERE population >= 1000000
                  AND population < 10000000)
                  UNION
                  (SELECT country, "Large, > 10 million" AS popSize
                  FROM Population
                  WHERE population > 10000000))
         SELECT PopSize.popSize as popSize, AVG(MostRecentMalaria.malaria_incidence) AS malaria_incidence
         FROM MostRecentMalaria INNER JOIN PopSize
         ON MostRecentMalaria.country = PopSize.country
         GROUP BY PopSize.popSize;
      END IF;
END; //


--List the top 20 countries  (LARGEST INCREASE/LARGEST DECREASE) in malaria incidence over (year X > 2000) along with their current active COVID cases and life expectancy change over that time period
DROP PROCEDURE IF EXISTS DiseasesOverTime1 //
CREATE PROCEDURE DiseasesOverTime1(IN underover VARCHAR(20), IN x NUMERIC(9,4))
BEGIN
      IF underover = 'LARGEST INCREASE' THEN
         WITH MalariaChange AS (WITH oldMalaria AS (SELECT Malaria.country as country, malaria_incidence
                                                   FROM Malaria 

                                                   WHERE Malaria.year = x)
                                 SELECT oldMalaria.country as country, (MostRecentMalaria.malaria_incidence - oldMalaria.malaria_incidence) AS malariaChange
                                 FROM oldMalaria INNER JOIN MostRecentMalaria
                                 ON oldMalaria.country = MostRecentMalaria.country),
            LifeExpectancyChange AS (WITH oldLifeExpectancy AS (SELECT Life_Expectancy.country as country, life_expectancy, sex, age
                                                   FROM Life_Expectancy 
                                                   WHERE Life_Expectancy.sex = "Both sexes"
                                                   AND Life_Expectancy.age = 60
                                                   AND YEAR(Life_Expectancy.year) = x)
                                 SELECT oldLifeExpectancy.country as country, (MostRecentLifeExpectancy.life_expectancy - oldLifeExpectancy.life_expectancy) AS lifeExpectancyChange
                                 FROM oldLifeExpectancy INNER JOIN MostRecentLifeExpectancy
                                 ON oldLifeExpectancy.country = MostRecentLifeExpectancy.country AND oldLifeExpectancy.sex = MostRecentLifeExpectancy.sex AND  oldLifeExpectancy.age = MostRecentLifeExpectancy.age)
         SELECT LifeExpectancyChange.country, LifeExpectancyChange.lifeExpectancyChange, MalariaChange.malariaChange, COVID19.active
         FROM MalariaChange INNER JOIN LifeExpectancyChange
         ON LifeExpectancyChange.country = MalariaChange.country
         INNER JOIN COVID19
         ON MalariaChange.country = COVID19.country
         ORDER BY MalariaChange.malariaChange DESC
         LIMIT 20;
      ELSE
         WITH MalariaChange AS (WITH oldMalaria AS (SELECT Malaria.country as country, malaria_incidence
                                                   FROM Malaria 

                                                   WHERE Malaria.year = x)
                                 SELECT oldMalaria.country as country, (MostRecentMalaria.malaria_incidence - oldMalaria.malaria_incidence) AS malariaChange
                                 FROM oldMalaria INNER JOIN MostRecentMalaria
                                 ON oldMalaria.country = MostRecentMalaria.country),
            LifeExpectancyChange AS (WITH oldLifeExpectancy AS (SELECT Life_Expectancy.country as country, life_expectancy, sex, age
                                                   FROM Life_Expectancy 
                                                   WHERE Life_Expectancy.sex = "Both sexes"
                                                   AND Life_Expectancy.age = 60
                                                   AND YEAR(Life_Expectancy.year) = x)
                                 SELECT oldLifeExpectancy.country as country, (MostRecentLifeExpectancy.life_expectancy - oldLifeExpectancy.life_expectancy) AS lifeExpectancyChange
                                 FROM oldLifeExpectancy INNER JOIN MostRecentLifeExpectancy
                                 ON oldLifeExpectancy.country = MostRecentLifeExpectancy.country AND oldLifeExpectancy.sex = MostRecentLifeExpectancy.sex AND  oldLifeExpectancy.age = MostRecentLifeExpectancy.age)
         SELECT LifeExpectancyChange.country, LifeExpectancyChange.lifeExpectancyChange, MalariaChange.malariaChange, COVID19.active
         FROM MalariaChange INNER JOIN LifeExpectancyChange
         ON LifeExpectancyChange.country = MalariaChange.country
         INNER JOIN COVID19
         ON MalariaChange.country = COVID19.country
         ORDER BY MalariaChange.malariaChange ASC
         LIMIT 20;
      END IF;
END; //


--List the top 20 countries  (LARGEST INCREASE/LARGEST DECREASE) in life expectancy since (year X > 2000) along with their current active COVID cases and life expectancy change over that time period
DROP PROCEDURE IF EXISTS DiseasesOverTime2 //
CREATE PROCEDURE DiseasesOverTime2(IN underover VARCHAR(20), IN x NUMERIC(9,4))
BEGIN
      IF underover = 'LARGEST INCREASE' THEN
         WITH MalariaChange AS (WITH oldMalaria AS (SELECT Malaria.country as country, malaria_incidence
                                                   FROM Malaria 

                                                   WHERE Malaria.year = x)
                                 SELECT oldMalaria.country as country, (MostRecentMalaria.malaria_incidence - oldMalaria.malaria_incidence) AS malariaChange
                                 FROM oldMalaria INNER JOIN MostRecentMalaria
                                 ON oldMalaria.country = MostRecentMalaria.country),
            LifeExpectancyChange AS (WITH oldLifeExpectancy AS (SELECT Life_Expectancy.country as country, life_expectancy, sex, age
                                                   FROM Life_Expectancy 
                                                   WHERE Life_Expectancy.sex = "Both sexes"
                                                   AND Life_Expectancy.age = 60
                                                   AND YEAR(Life_Expectancy.year) = x)
                                 SELECT oldLifeExpectancy.country as country, (MostRecentLifeExpectancy.life_expectancy - oldLifeExpectancy.life_expectancy) AS lifeExpectancyChange
                                 FROM oldLifeExpectancy INNER JOIN MostRecentLifeExpectancy
                                 ON oldLifeExpectancy.country = MostRecentLifeExpectancy.country AND oldLifeExpectancy.sex = MostRecentLifeExpectancy.sex AND  oldLifeExpectancy.age = MostRecentLifeExpectancy.age)
         SELECT LifeExpectancyChange.country, LifeExpectancyChange.lifeExpectancyChange, MalariaChange.malariaChange, COVID19.active
         FROM MalariaChange INNER JOIN LifeExpectancyChange
         ON LifeExpectancyChange.country = MalariaChange.country
         INNER JOIN COVID19
         ON MalariaChange.country = COVID19.country
         ORDER BY LifeExpectancyChange.lifeExpectancyChange DESC
         LIMIT 20;
      ELSE
         WITH MalariaChange AS (WITH oldMalaria AS (SELECT Malaria.country as country, malaria_incidence
                                                   FROM Malaria 

                                                   WHERE Malaria.year = x)
                                 SELECT oldMalaria.country as country, (MostRecentMalaria.malaria_incidence - oldMalaria.malaria_incidence) AS malariaChange
                                 FROM oldMalaria INNER JOIN MostRecentMalaria
                                 ON oldMalaria.country = MostRecentMalaria.country),
            LifeExpectancyChange AS (WITH oldLifeExpectancy AS (SELECT Life_Expectancy.country as country, life_expectancy, sex, age
                                                   FROM Life_Expectancy 
                                                   WHERE Life_Expectancy.sex = "Both sexes"
                                                   AND Life_Expectancy.age = 60
                                                   AND YEAR(Life_Expectancy.year) = x)
                                 SELECT oldLifeExpectancy.country as country, (MostRecentLifeExpectancy.life_expectancy - oldLifeExpectancy.life_expectancy) AS lifeExpectancyChange
                                 FROM oldLifeExpectancy INNER JOIN MostRecentLifeExpectancy
                                 ON oldLifeExpectancy.country = MostRecentLifeExpectancy.country AND oldLifeExpectancy.sex = MostRecentLifeExpectancy.sex AND  oldLifeExpectancy.age = MostRecentLifeExpectancy.age)
         SELECT LifeExpectancyChange.country, LifeExpectancyChange.lifeExpectancyChange, MalariaChange.malariaChange, COVID19.active
         FROM MalariaChange INNER JOIN LifeExpectancyChange
         ON LifeExpectancyChange.country = MalariaChange.country
         INNER JOIN COVID19
         ON MalariaChange.country = COVID19.country
         ORDER BY LifeExpectancyChange.lifeExpectancyChange ASC
         LIMIT 20;
      END IF;
END; //





-- Which countries solved (less than X cases) COVID crises in under (N DAYS) and display their democracy, life expectancy, and population size?
DROP PROCEDURE IF EXISTS COVIDCrisisHandling1 //
CREATE PROCEDURE COVIDCrisisHandling1(IN x1 NUMERIC(9,4), IN x2 NUMERIC(9,4))
BEGIN
   WITH Solved AS (
           WITH MinCOVID19 AS (
                          WITH covid19_confirmed_global_sorted AS (SELECT t.country, confirmed, covid19_confirmed_global.dataDate FROM covid19_confirmed_global INNER JOIN (SELECT country, MIN(dataDate) AS dataDate FROM covid19_confirmed_global GROUP BY country)t ON t.country = covid19_confirmed_global.country AND t.dataDate = covid19_confirmed_global.dataDate),
                                covid19_recovered_global_sorted AS (SELECT t.country, recovered FROM covid19_recovered_global INNER JOIN (SELECT country, MIN(dataDate) AS dataDate FROM covid19_recovered_global GROUP BY country)t ON t.country = covid19_recovered_global.country AND t.dataDate = covid19_recovered_global.dataDate),
                                covid19_deaths_global_sorted AS (SELECT t.country, deaths FROM covid19_deaths_global INNER JOIN (SELECT country, MIN(dataDate) AS dataDate FROM covid19_deaths_global GROUP BY country)t ON t.country = covid19_deaths_global.country AND t.dataDate = covid19_deaths_global.dataDate)
                          SELECT covid19_confirmed_global_sorted.country as country, covid19_confirmed_global_sorted.confirmed as confirmed, covid19_deaths_global_sorted.deaths as deaths, covid19_recovered_global_sorted.recovered as recovered, covid19_confirmed_global_sorted.confirmed - covid19_recovered_global_sorted.recovered - covid19_deaths_global_sorted.deaths as active, covid19_confirmed_global_sorted.dataDate
                          FROM covid19_confirmed_global_sorted 
                          INNER JOIN covid19_recovered_global_sorted
                          ON covid19_confirmed_global_sorted.country = covid19_recovered_global_sorted.country 
                          INNER JOIN covid19_deaths_global_sorted 
                          ON covid19_recovered_global_sorted.country = covid19_deaths_global_sorted.country)
           SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as active
           FROM covid19_confirmed_global 
           INNER JOIN covid19_recovered_global
           ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
           INNER JOIN covid19_deaths_global 
           ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
           LEFT JOIN MinCOVID19
           ON covid19_confirmed_global.country = MinCOVID19.country
           WHERE covid19_confirmed_global.dataDate = DATE_ADD(MinCOVID19.dataDate, INTERVAL x2 DAY)
           AND covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths < x1)
   SELECT Solved.country, Solved.active, democracy_index, life_expectancy, population
   FROM Solved 
   INNER JOIN Democracies
   ON Solved.country = Democracies.country 
   INNER JOIN MostRecentLifeExpectancy 
   ON Solved.country = MostRecentLifeExpectancy.country
   INNER JOIN Population 
   ON Solved.country = Population.country
   WHERE MostRecentLifeExpectancy.sex = "Both sexes" AND MostRecentLifeExpectancy.age = 60;
END; //


-- Graph the top 20 countries, total cases to date, and the cumulative deaths for countries that have the (HIGHEST/LOWEST) rate of COVID-19 contraction increase in total covid cases over the last month
DROP PROCEDURE IF EXISTS COVIDCrisisHandling2 //
CREATE PROCEDURE COVIDCrisisHandling2(IN underover VARCHAR(20))
BEGIN
   IF underover = 'HIGHEST' THEN
      SELECT CovidChange.country, CovidChange.monthlyIncrease
      FROM CovidChange
      ORDER BY CovidChange.monthlyIncrease DESC
      LIMIT 20;
   ELSE
      SELECT CovidChange.country, CovidChange.monthlyIncrease
      FROM CovidChange
      ORDER BY CovidChange.monthlyIncrease ASC
      LIMIT 20;
   END IF;
END; //

-- List the countries where the rate of change of the difference in daily case counts is (NEGATIVE/POSITIVE) 
DROP PROCEDURE IF EXISTS COVIDCrisisHandling3 //
CREATE PROCEDURE COVIDCrisisHandling3(IN underover VARCHAR(20))
BEGIN
   IF underover = 'NEGATIVE' THEN
      SELECT * 
      FROM CovidChange
      WHERE CovidChange.dailyIncrease > 0 
      ORDER BY CovidChange.dailyIncrease DESC
      LIMIT 20;
   ELSE
      SELECT * 
      FROM CovidChange
      WHERE CovidChange.dailyIncrease < 0 
      ORDER BY CovidChange.dailyIncrease DESC
      LIMIT 20;
   END IF;
END; //




DELIMITER ;