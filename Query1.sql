-- kgorman4
-- Query1.sql

DELIMITER //

DROP PROCEDURE IF EXISTS Query1 //

CREATE PROCEDURE Query1(IN c VARCHAR(58))
BEGIN
   SELECT * 
   FROM Malaria 
   WHERE country = c;

END; //

DELIMITER ;
