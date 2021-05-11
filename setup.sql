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
DROP VIEW IF EXISTS COVID192;
CREATE VIEW COVID192 AS
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
                LEFT JOIN COVID192 
                ON covid19_confirmed_global.country = COVID192.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID192.dataDate, INTERVAL 1 MONTH);

DROP VIEW IF EXISTS daily;
CREATE VIEW daily AS
SELECT covid19_confirmed_global.country as country, covid19_confirmed_global.confirmed - covid19_recovered_global.recovered - covid19_deaths_global.deaths as activeDaily
                FROM covid19_confirmed_global 
                INNER JOIN covid19_recovered_global
                ON covid19_confirmed_global.country = covid19_recovered_global.country AND covid19_confirmed_global.dataDate = covid19_recovered_global.dataDate
                INNER JOIN covid19_deaths_global 
                ON covid19_recovered_global.country = covid19_deaths_global.country AND covid19_confirmed_global.dataDate = covid19_deaths_global.dataDate
                LEFT JOIN COVID192
                ON covid19_confirmed_global.country = COVID192.country
                WHERE covid19_confirmed_global.dataDate = DATE_SUB(COVID192.dataDate, INTERVAL 1 DAY);


DROP VIEW IF EXISTS montlyIncrease;
CREATE VIEW montlyIncrease AS
SELECT COVID192.country, (COVID192.active - monthly.activeMonthly) as monthlyIncrease
FROM COVID192 INNER JOIN monthly
ON COVID192.country = monthly.country;

DROP VIEW IF EXISTS dailyIncrease;
CREATE VIEW dailyIncrease AS
SELECT COVID192.country, (COVID192.active - daily.activeDaily) as dailyIncrease
FROM COVID192 INNER JOIN daily
ON COVID192.country = daily.country;


DROP VIEW IF EXISTS CovidChange2;
CREATE VIEW CovidChange2 AS
SELECT COVID192.country, dailyIncrease.dailyIncrease, montlyIncrease.monthlyIncrease
FROM COVID192 INNER JOIN dailyIncrease
ON COVID192.country = dailyIncrease.country
INNER JOIN montlyIncrease
ON COVID192.country = montlyIncrease.country;
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
   FROM Malaria 
   WHERE YEAR(Malaria.year) = 2019
   ORDER BY Malaria.malaria_incidence DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestMalaria //
CREATE PROCEDURE LowestMalaria()
BEGIN
   SELECT country, malaria_incidence
   FROM Malaria 
   WHERE YEAR(Malaria.year) = 2019
   ORDER BY Malaria.malaria_incidence ASC
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
   WHERE age = 0
   ORDER BY life_expectancy DESC
   LIMIT 20;

END; //

DROP PROCEDURE IF EXISTS LowestLifeExpectancy //
CREATE PROCEDURE LowestLifeExpectancy()
BEGIN
   SELECT country, life_expectancy
   FROM Life_Expectancy 
   WHERE age = 0
   ORDER BY life_expectancy ASC
   LIMIT 20;

END; //



--Which are the countries with malaria incidence rates in the world where cumulative COVID19 case counts are (UNDER/OVER) (X amount) or deaths are (UNDER/OVER) (X amount)?
DROP PROCEDURE IF EXISTS CovidMalaria1 //
CREATE PROCEDURE CovidMalaria1(IN underover1 VARCHAR(5), IN x1 NUMERIC(9,4), IN underover2 VARCHAR(5), IN x2 NUMERIC(9,4))
BEGIN
   IF underover1 = 'UNDER' AND underover2 = 'UNDER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
      WHERE COVID19.confirmed < x1
      OR COVID19.deaths < x2
      ORDER BY COVID19.confirmed ASC, COVID19.deaths ASC;
   ELSEIF underover1 = 'OVER' AND underover2 = 'UNDER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
      WHERE COVID19.confirmed > x1
      OR COVID19.deaths < x2
      ORDER BY COVID19.confirmed ASC, COVID19.deaths DESC;
   ELSEIF underover1 = 'UNDER' AND underover2 = 'OVER' THEN
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
      WHERE COVID19.confirmed < x1
      OR COVID19.deaths > x2
      ORDER BY COVID19.confirmed DESC, COVID19.deaths ASC;
   ELSE
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
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
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
      WHERE Malaria.malaria_incidence < x
      ORDER BY Malaria.malaria_incidence ASC;
   ELSE
      SELECT COVID19.country, malaria_incidence, COVID19.confirmed AS confirmed, COVID19.recovered AS recovered, COVID19.deaths AS deaths
      FROM COVID19 INNER JOIN Malaria                       
      ON COVID19.country = Malaria.country
      WHERE Malaria.malaria_incidence > x
      ORDER BY Malaria.malaria_incidence DESC;
   END IF;
END; //

--What are the COVID-19 incidents, malaria incidences, and life expectancy for the 30 (MOST/LEAST populous countries?
DROP PROCEDURE IF EXISTS MostPopulous //
CREATE PROCEDURE MostPopulous(IN underover VARCHAR(5), IN x NUMERIC(9,4))
BEGIN
      IF underover = 'UNDER' THEN
         SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
         FROM Population INNER JOIN (SELECT Malaria.country, malaria_incidence, incidence AS covid_incidence, both_atbirth as life_expectancy
                                          FROM Malaria 
                                                INNER JOIN COVID19_Incidence
                                                         ON Malaria.country = COVID19_Incidence.country 
                                                INNER JOIN Life_Expectancy   
                                                         ON COVID19_Incidence.country = Life_Expectancy.country) AllComb                         
         ON Population.country = AllComb.country
         WHERE Population.population < x
         ORDER BY Population.population DESC;
      ELSE
         SELECT Population.country, population, malaria_incidence, covid_incidence, life_expectancy
         FROM Population INNER JOIN (SELECT Malaria.country, malaria_incidence, incidence AS covid_incidence, both_atbirth as life_expectancy
                                          FROM Malaria 
                                                INNER JOIN COVID19_Incidence
                                                         ON Malaria.country = COVID19_Incidence.country 
                                                INNER JOIN Life_Expectancy   
                                                         ON COVID19_Incidence.country = Life_Expectancy.country) AllComb                         
         ON Population.country = AllComb.country
         WHERE Population.population > x
         ORDER BY Population.population ASC;
      END IF;
END; //






DELIMITER ;