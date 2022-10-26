-- CREATE DATABASE EnergyTransition;
-- USE EnergyTransition; 

/*DROP TABLE Customer;
DROP TABLE Energy;
DROP TABLE Generator;
DROP TABLE Location;
DROP TABLE Supplier;*/

-- Location table holds information for where the customer, generator and supplier are based
CREATE TABLE Location
(
LocationId INTEGER PRIMARY KEY,
City varchar(255),
Country varchar (255),
PostCode varchar(255)
);

-- Supplier is the company that buys electricty fromthe generation companies to sell it to the customer
CREATE TABLE Supplier
(
SupplierId INTEGER PRIMARY KEY,
SupplierName varchar(255),
SupplierCapacity INT, 
SupplierCostPerKw INT, -- cost per kwh in pence
LocationId INT,
    CONSTRAINT FK_Location
    FOREIGN KEY (LocationId) 
        REFERENCES Location(LocationId)
);

-- Energy holds the credentials of the power source of the generator site
CREATE TABLE Energy
(
EnergySource varchar(255) PRIMARY KEY,
EnergyCarbonEmissions INT, 
EnergyEfficiency INT 
);

/*The generating company has a site which can produce a certain amount of electricity in total. 
The Generator is producing x energy currently. Each MW it produces it sells to suppliers (This is not how it really works but for 
simplification of the excersise). The site will either be on outage or not.*/
CREATE TABLE Generator 
(
Generatorid INTEGER PRIMARY KEY,
GeneratorName varchar(255),
GeneratorTotalCapacity INT,
GeneratorSiteName varchar(255),
GeneratorOutage bool,
GeneratorCurrentCapacity INT,
GeneratorCostPerMw INT, 
LocationId INT,
    CONSTRAINT FK_GenLocation
    FOREIGN KEY (LocationId) 
        REFERENCES Location(LocationId),
        SupplierId INT,
    CONSTRAINT FK_Supplier
    FOREIGN KEY (SupplierId) 
        REFERENCES Supplier(SupplierId),
        EnergySource varchar(255),
    CONSTRAINT FK_Energy
    FOREIGN KEY (EnergySource) 
        REFERENCES Energy(EnergySource)
        

);

-- the customer at home buys energy from the supplier.
 CREATE TABLE Customer 
(
CustomerId INTEGER PRIMARY KEY,
CustomerName varchar(255),
CustomerEnergyDemand INT, -- in kwh per year
CustomerEmail varchar(255),
LocationId INT,
 CONSTRAINT FK_CusLocation
    FOREIGN KEY (LocationId) 
        REFERENCES Location(LocationId),
        SupplierId INT,
    CONSTRAINT FK_CusSupplier
    FOREIGN KEY (SupplierId) 
        REFERENCES Supplier(SupplierId)
        
        
);

-- Filling database
INSERT INTO Location
(LocationId, City, Country,Postcode)
VALUES
(001,"Weybridge", "UK", "KT12 GT4"),
(002,"Didcot B", "UK", "OX11"),
(003,"Liverpool", "UK", "L113 8GT"),
(004, "Edinburgh","UK", "SC12 987"),
(005, "London","UK", "LO13 876"),
(006, "Cologne", "Germany", "GER1 3GT"),
(007,"Paris","France", "PA12 HDW");

INSERT INTO Energy
(EnergySource, EnergyCarbonEmissions,EnergyEfficiency)
VALUES
("solar power", 0, "20"),
("natural gas", 202, "56"),
("lignite", 364, "32"),
("offshore wind", 0, "40");

INSERT INTO Supplier
(SupplierId, SupplierName, SupplierCapacity,SupplierCostPerKw, LocationId)
VALUES
(001,"British gas", 2000, 60,005),
(002,"E.on", 700, 25, 003),
(003,"SSE", 1500, 50, 007),
(004,"Scottish power", 1000, 7, 004);

INSERT INTO Customer
(CustomerId, CustomerName, CustomerEnergyDemand, CustomerEmail, LocationId, SupplierId)
VALUES
(001,"Ashleigh McKenna", 18000, "ashleighlmckenna@hotmail.com", 001,004),
(002,"Betty Bilmore", 5000, "Betty.Bilmore@outlook.com",003, 002),
(003,"Charlie Cramer", 12000, "Charlie.cramer@outlook.com", 003, 003),
(004, "David Devito", 3000, "David.devito@outlook.com",004,001);

INSERT INTO Generator
(GeneratorId, GeneratorName, GeneratorTotalCapacity,GeneratorSiteName,GeneratorOutage, GeneratorCurrentCapacity, GeneratorCostPerMW, LocationId, SupplierId, EnergySource)
VALUES
(001,"RWE", 1360, "Didcot B", 1, 0, 37,002,003, "natural gas"),
(002,"Orsted", 1200, "Hornsea 1",0,1200, 121, 006, 002, "offshore wind"),
(003,"EDF", 1700, "Sutton Bridge",0,0 , 37, 004, 004, "solar power");

UPDATE Generator
SET GeneratorOutage = 0, GeneratorCurrentCapacity = 1360
WHERE GeneratorId = 001;

-- Inner join: To calculate Generator carbon emissions per day in Kg of carbon
SELECT G.GeneratorName, E.EnergySource, E.EnergyCarbonEmissions, G.GeneratorCurrentCapacity,( G.GeneratorCurrentCapacity * E.EnergyCarbonEmissions) GeneratorCarbonEmissionsToday
FROM Generator G
INNER JOIN Energy E ON
G.EnergySource = E.EnergySource;

-- Left outer join: To calculate how much a customer spends on electricty in a year, Charlie cramer is possibly realistic cost for this year in £ per household using infor from energyguide.org.uk
SELECT C.CustomerName, C.CustomerEnergyDemand, S.SupplierName, ((C.CustomerEnergyDemand * S.SupplierCostPerKw)/100) CustomerCost
FROM Customer C
LEFT JOIN Supplier S ON S.SupplierID = C.SupplierID
ORDER BY C.CustomerEnergyDemand;

-- Veiw: created from joins to show the generator, where they are and what type of energy the produce
CREATE VIEW GeneratorLocationVeiw
AS SELECT G.GeneratorId,G.GeneratorName,G.GeneratorSiteName, L.LocationId, L.City, L.Country, E.EnergySource
FROM Generator G, Location L, Energy E
WHERE G.LocationId = L.LocationId
AND G.EnergySource = E.EnergySource;

SELECT * FROM GeneratorLocationVeiw;


-- Function: The tell user the best suppliers to buy from on a cost basis
DELIMITER $$

CREATE FUNCTION SupplierCostRating(
	SupplierCostPerKw INT
) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE SupplierCostRating VARCHAR(20);

    IF SupplierCostPerKw > 52 THEN
		SET SupplierCostRating = 'EXPENSIVE';
    ELSEIF SupplierCostPerKw <= 52 AND SupplierCostPerKw >= 10 THEN
        SET SupplierCostRating = 'MEDIUM';
    ELSEIF SupplierCostPerKw < 10 THEN
        SET SupplierCostRating = 'BUY NOW';
    END IF;
	-- return the customer level
	RETURN (SupplierCostRating);
END$$
DELIMITER ;

-- Query: To display results of function
SELECT 
    SupplierName, 
    SupplierCostPerKw,
    SupplierCostRating(SupplierCostPerKw)
FROM
    Supplier
ORDER BY 
    SupplierCostPerKw;


-- Query with subquery: To show the areas that use the most electricty
 SELECT 
    LocationId, City, Country, PostCode
FROM
    Location
WHERE
    LocationId IN (SELECT 
            CustomerId
        FROM
            Customer
        WHERE
            CustomerEnergyDemand > 5000)
ORDER BY City,Country,  PostCode;


-- Procedure: to see which generators are carbon neutral and assess best option on cost
DELIMITER $$
CREATE PROCEDURE GreenGenerator()
BEGIN

    SELECT GeneratorId, GeneratorName, EnergySource, GeneratorCostPerMw
    FROM Generator
WHERE EnergySource = 'solar power' OR EnergySource ='offshore wind';
END$$
DELIMITER ;

CALL GreenGenerator(); -- runs the procedure since they can't be used in select statements



-- Trigger: to ensure that the energy source value coming in is lowercase and concatinated

CREATE TRIGGER EnergySourceName
BEFORE INSERT on Energy
FOR EACH ROW 
	SET NEW.EnergySource = LOWER(NEW.EnergySource);
						
  INSERT INTO Energy
(EnergySource, EnergyCarbonEmissions,EnergyEfficiency)
VALUES
("HYDROgen ", 0, "20");
  
 SELECT * FROM Energy; -- to test trigger
  
    


 -- IGNORE CODE FROM HERE ON 
/* ALTER TABLE Customers
ADD
CONSTRAINT FK_CusEnergy
    FOREIGN KEY (EnergySource) 
        REFERENCES Energy(EnergySource);
        
        update Customer set EnergySource = "solar Power" where CustomerId = 001

DELIMITER $$

CREATE FUNCTION IndividualCarbonFootprint(
	CustomerEnergyDemand INT,
    EnergyCarbonEmissions INT
) 
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE IndividualCarbonFootprint INT;
    
    UPDATE Customer
SET GeneratorOutag = 0, GeneratorCurrentCapacity = 1360
WHERE GeneratorId = 001;

SELECT C.CustomerName, E.EnergySource, E.EnergyCarbonEmissions, C.CustomerEnergyDemand,( C.CustomerEnergyDemand * E.EnergyCarbonEmissions) IndividualCarbonFootprint
FROM Customer C
INNER JOIN Energy E ON
C.EnergySource = E.EnergySource;
	-- return the customer level
	RETURN (IndividualCarbonFootprint);
END$$
DELIMITER ; */ -- Just some code I was playing with, wasn't sure if I could multiply across tables and store it as a value without joins and keys
    
  