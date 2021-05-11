-- ShowBidHistory.sql

DELIMITER //

DROP PROCEDURE IF EXISTS ShowBidHistory //

CREATE PROCEDURE ShowBidHistory(IN item VARCHAR(10))
BEGIN
      SELECT buyerNum, bidTime, amount
      FROM Bid
      WHERE itemID = item
      ORDER BY bidTime;
END; //

DELIMITER ;
