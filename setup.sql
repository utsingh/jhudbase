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
  ,democrocy_index  VARCHAR(100) NOT NULL,
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
   age                  NUMERIC(5,2) NOT NULL,
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
   malaria_incidence VARCHAR(20) NOT NULL,
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