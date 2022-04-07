USE Day3;
CREATE TABLE Warehouses (
   Code INTEGER NOT NULL,
   Location VARCHAR(255) NOT NULL ,
   Capacity INTEGER NOT NULL,
   PRIMARY KEY (Code)
 );
CREATE TABLE Boxes (
    Code CHAR(4) NOT NULL,
    Contents VARCHAR(255) NOT NULL ,
    Value REAL NOT NULL ,
    Warehouse INTEGER NOT NULL,
    PRIMARY KEY (Code)
 );
 
 INSERT INTO Warehouses(Code,Location,Capacity) VALUES(1,'Chicago',3);
 INSERT INTO Warehouses(Code,Location,Capacity) VALUES(2,'Chicago',4);
 INSERT INTO Warehouses(Code,Location,Capacity) VALUES(3,'New York',7);
 INSERT INTO Warehouses(Code,Location,Capacity) VALUES(4,'Los Angeles',2);
 INSERT INTO Warehouses(Code,Location,Capacity) VALUES(5,'San Francisco',8);
 
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('0MN7','Rocks',180,3);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('4H8P','Rocks',250,1);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('4RT3','Scissors',190,4);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('7G3H','Rocks',200,1);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('8JN6','Papers',75,1);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('8Y6U','Papers',50,3);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('9J6F','Papers',175,2);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('LL08','Rocks',140,4);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('P0H6','Scissors',125,1);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('P2T6','Scissors',150,2);
 INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES('TU55','Papers',90,5);

-- 3.1 Select all warehouses.
SELECT * FROM Warehouses;

-- 3.2 Select all boxes with a value larger than $150.
SELECT * FROM Boxes WHERE Value > 150;

-- 3.3 Select all distinct contents in all the boxes.
SELECT DISTINCT Contents FROM Boxes;

-- 3.4 Select the average value of all the boxes.
SELECT ROUND(AVG(Value),2) FROM Boxes;

-- 3.5 Select the warehouse code and the average value of the boxes in each warehouse.
SELECT ROUND(AVG(Value),2), Warehouse FROM Boxes GROUP BY Warehouse ORDER BY Warehouse ASC;

-- 3.6 Same as previous exercise, but select only those warehouses where the average value of the boxes is greater than 150.
SELECT ROUND(AVG(Value),2), Warehouse FROM Boxes GROUP BY Warehouse HAVING AVG(Value) > 150 ORDER BY Warehouse ASC;

-- 3.7 Select the code of each box, along with the name of the city the box is located in.
SELECT Boxes.Code AS BoxCode, Warehouses.Location FROM Boxes INNER JOIN Warehouses ON Boxes.Warehouse = Warehouses.Code;

-- 3.8 Select the warehouse codes, along with the number of boxes in each warehouse.
SELECT COUNT(*), Warehouse FROM Boxes INNER JOIN Warehouses ON Boxes.Warehouse = Warehouses.Code GROUP BY Warehouse ORDER BY Warehouse ASC;

-- 3.9 Select the codes of all warehouses that are saturated (a warehouse is saturated if the number of boxes in it is larger than the warehouse's capacity).
SELECT Code as WarehouseCode FROM Warehouses WHERE Capacity < (
	SELECT COUNT(*) FROM Boxes WHERE Warehouse = Warehouses.Code
);
SELECT Warehouses.Code FROM Warehouses JOIN Boxes ON Warehouses.Code = Boxes.Warehouse
  GROUP BY Warehouses.code, Warehouses.Capacity
  HAVING Count(Boxes.code) > Warehouses.Capacity;

-- 3.10 Select the codes of all the boxes located in Chicago.
SELECT Boxes.Code AS BoxCode FROM Boxes INNER JOIN Warehouses ON Boxes.Warehouse = Warehouses.Code WHERE Warehouses.Location='Chicago';

-- 3.11 Create a new warehouse in New York with a capacity for 3 boxes.
INSERT INTO Warehouses(Code,Location,Capacity) VALUES (6,'New York',3);

-- 3.12 Create a new box, with code "H5RT", containing "Papers" with a value of $200, and located in warehouse 2.
INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES ('H5RT','Papers',200,2);

-- 3.13 Reduce the value of all boxes by 15%.
UPDATE Boxes SET Value = (Value - Value*0.15);

-- 3.14 Remove all boxes with a value lower than $100.
DELETE FROM Boxes WHERE Value < 100;

-- 3.15 Remove all boxes from saturated warehouses.
/* ! After deleting all boxes with a value lower than 100, there are no saturated warehouses! 
   For testing purposes created oversaturation in warehouse 1.
*/
INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES ('DF6T','Tests',500,1);
INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES ('L7TG','Tests',1000,1);
INSERT INTO Boxes(Code,Contents,Value,Warehouse) VALUES ('W9HG','Tests',200,1);

-- This works in SQLite not in MySQL 
UPDATE Boxes SET Warehouse=0 WHERE Warehouse IN (
     SELECT Code FROM Warehouses WHERE Capacity < (
         SELECT COUNT(*) FROM surplus_box WHERE surplus_box.Warehouse = Warehouses.Code
       )
   );
   
-- Alternative
UPDATE Boxes SET Warehouse=0 WHERE Warehouse IN (
	SELECT Warehouses.Code FROM Warehouses JOIN Boxes ON Warehouses.Code = Boxes.Warehouse
	GROUP BY Warehouses.Code, Warehouses.Capacity
	HAVING Count(Boxes.Code) > Warehouses.Capacity)
  ;

-- checks which warehouses are saturated and number of boxes in
SELECT Warehouses.Code AS WarehouseCode, Capacity, COUNT(Boxes.Code) AS BoxNumber
FROM Warehouses
JOIN Boxes ON Warehouses.Code=Boxes.Warehouse
GROUP BY WarehouseCode, Capacity
HAVING BoxNumber > Capacity;

DELETE FROM Boxes
WHERE Warehouse IN (
	SELECT Warehouses.Code 
	FROM Warehouses
	JOIN Boxes ON Warehouses.Code=Boxes.Warehouse
	GROUP BY Warehouses.Code, Capacity
	HAVING COUNT(Boxes.Code) > Capacity
);

WITH overcap AS (
	SELECT Warehouses.Code -- AS WarehouseCode , Capacity, COUNT(Boxes.Code) AS BoxNumber
	FROM Warehouses
	JOIN Boxes ON Warehouses.Code=Boxes.Warehouse
	GROUP BY Warehouses.Code, Capacity
	HAVING COUNT(Boxes.Code) > Capacity
)

DELETE Boxes FROM Boxes
JOIN overcap ON Boxes.Warehouse=overcap.Code;


/* Needs to use view (Virginia): CREATE VIEW view_name AS SELECT columns FROM table; QUERY;*/
/*CREATE VIEW surplus_box2 AS SELECT Boxes.*, Warehouses.Capacity FROM Boxes LEFT JOIN Warehouses ON Warehouses.Code = Boxes.Warehouse;
UPDATE Boxes SET Warehouse=0 WHERE Warehouse IN (
     SELECT Code FROM Warehouses WHERE Capacity < (
         SELECT COUNT(*) FROM surplus_box2 WHERE surplus_box2.Warehouse = Warehouses.Code
       )
   );*/
-- Error Code: 1443. The definition of table 'surplus_box' prevents operation UPDATE on table 'Boxes'.

SELECT * FROM Warehouses;
SELECT * FROM Boxes;
DROP TEMPORARY TABLE all_info;

set session sql_mode='TRADITIONAL';
CREATE TEMPORARY TABLE all_info AS
SELECT w.*, b.Code as box_code, b.Contents, b.Value, 
CASE 
        WHEN COUNT(w.Code)>w.Capacity THEN 1 
        ELSE 0
END AS saturation
FROM Warehouses w
JOIN Boxes b ON w.Code=b.Warehouse
GROUP BY Warehouse;

SELECT *
FROM all_info;

UPDATE all_info
SET box_code ='', contents='', Value=0
WHERE saturation=1; -- deletes box code

SELECT * FROM Warehouses;
SELECT * FROM Boxes;

         

   
-- Error Code: 1093. You can't specify target table 'Boxes' for update in FROM clause

/*UPDATE Boxes a LEFT JOIN
       (SELECT al.Code
        FROM Warehouses al JOIN
             Boxes a
             ON a.Warehouse = al.Code
        WHERE Capacity < (SELECT COUNT(*) FROM Boxes WHERE Warehouse = al.Code)
        -- GROUP BY al.Code
       ) aa
       ON a.Warehouse = aa.Code
    SET Warehouse=0;*/

/* Code from Virginia:
SELECT *, 
CASE 
        WHEN COUNT(w.code)>capacity THEN 0 
        ELSE COUNT(w.code)
END AS num_boxes
FROM warehouses w
JOIN boxes b ON w.code=b.warehouse
GROUP BY warehouse;
*/
    
SELECT * FROM Boxes;
SELECT * FROM Warehouses;

-- 3.16 Add Index for column "Warehouse" in table "boxes" (index should NOT be used on small tables in practice)
CREATE INDEX idx_warehouse ON Boxes (Warehouse);

-- 3.17 Print all the existing indexes (index should NOT be used on small tables in practice)
SHOW INDEXES FROM Boxes;

-- 3.18 Remove (drop) the index you added just (index should NOT be used on small tables in practice)
ALTER TABLE Boxes DROP INDEX idx_warehouse;