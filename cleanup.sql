-- cleanup.sql
-- This is a full cleanup script (text file) for our Project database in MariaDB.

-- Team Members: KEVIN GORMAN (JHED: KGORMAN4), UTKARSH SINGH (JHED: USINGH5)
DROP PROCEDURE IF EXISTS MostPopulous;
DROP PROCEDURE IF EXISTS CovidMalaria2;
DROP PROCEDURE IF EXISTS CovidMalaria1;
DROP PROCEDURE IF EXISTS LowestLifeExpectancy;
DROP PROCEDURE IF EXISTS TopLifeExpectancy;
DROP PROCEDURE IF EXISTS LowestDemocracy;
DROP PROCEDURE IF EXISTS TopDemocracy;
DROP PROCEDURE IF EXISTS LowestPopulation;
DROP PROCEDURE IF EXISTS TopPopulation;
DROP PROCEDURE IF EXISTS LowestMalaria;
DROP PROCEDURE IF EXISTS TopMalaria;
DROP PROCEDURE IF EXISTS Query1;

DROP VIEW IF EXISTS COVID19;
DROP VIEW IF EXISTS CovidChange;
DROP VIEW IF EXISTS COVID19_Incidence;
DROP VIEW IF EXISTS MostRecentMalaria;
DROP VIEW IF EXISTS MostRecentLifeExpectancy;
DROP VIEW IF EXISTS CountryHemispheres;
DROP VIEW IF EXISTS NorthSouthCovid;
DROP VIEW IF EXISTS EastWestCovid;
DROP VIEW IF EXISTS EastWestAgg;

DROP TABLE IF EXISTS COVID19_small;
DROP TABLE IF EXISTS Life_Expectancy_small;
DROP TABLE IF EXISTS Malaria_small;
DROP TABLE IF EXISTS Population_small;
DROP TABLE IF EXISTS covid19_confirmed_global_small;
DROP TABLE IF EXISTS covid19_deaths_global_small;
DROP TABLE IF EXISTS covid19_recovered_global_small;
DROP TABLE IF EXISTS Countries_small;

DROP TABLE IF EXISTS COVID19;
DROP TABLE IF EXISTS Life_Expectancy;
DROP TABLE IF EXISTS Malaria;
DROP TABLE IF EXISTS Population;
DROP TABLE IF EXISTS covid19_confirmed_global;
DROP TABLE IF EXISTS covid19_deaths_global;
DROP TABLE IF EXISTS covid19_recovered_global;
DROP TABLE IF EXISTS Democracies;
DROP TABLE IF EXISTS Region;
DROP TABLE IF EXISTS Countries;
