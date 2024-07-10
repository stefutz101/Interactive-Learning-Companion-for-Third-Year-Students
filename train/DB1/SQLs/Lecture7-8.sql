------------------------------------------------------------------------------------------
--- Second design
---
CREATE SCHEMA geo
GO

CREATE TABLE geo.States	
(
	Name nvarchar(50) NOT NULL,

    CONSTRAINT PK_States PRIMARY KEY (Name)
) 
GO

CREATE TABLE geo.Counties 
(
	Name nvarchar(50) NOT NULL,
	Area INT,
	StateName nvarchar(50) NOT NULL,

	CONSTRAINT PK_Counties PRIMARY KEY (Name, StateName),
	CONSTRAINT FK_Counties_State FOREIGN KEY (StateName) REFERENCES geo.States(Name)    
)
GO


CREATE TABLE geo.Cities
(
	Name nvarchar(50) NOT NULL,
	Population INT,
	CountyName nvarchar(50) NOT NULL,
	StateName nvarchar(50) NOT NULL,

	CONSTRAINT PK_Cities PRIMARY KEY (Name, CountyName, StateName),
	CONSTRAINT FK_Cities_Counties FOREIGN KEY (CountyName, StateName) REFERENCES geo.Counties (Name, StateName)
)
GO

CREATE TABLE geo.Capitals	
(
	CityName nvarchar(50) NOT NULL,
	CountyName nvarchar(50) NOT NULL,
	StateName nvarchar(50) NOT NULL,

	CONSTRAINT PK_Capitals PRIMARY KEY (StateName),
	CONSTRAINT FK_Capitals_Cities FOREIGN KEY (CityName, CountyName, StateName) REFERENCES geo.Cities (Name, CountyName, StateName),    
)
GO

INSERT INTO 
	geo.States 
VALUES 
	('Romania'), 
	('Germania'), 
	('SUA');

INSERT INTO 
	geo.Counties 
VALUES 
	('Timis', 100, 'Romania'),
	('Ilfov', 10, 'Romania'),
	('Timis', 1000, 'SUA'),
	('Baden-Württemberg', 25000, 'Germania');

-- FK constraint prevents us from adding counties in non-existent countries
INSERT INTO 
	geo.Counties 
VALUES 
	('Baden-Baden', 25000, 'Austria');
-- DELETE FROM geo.Counties WHERE StateName='Austria'

-- Check the effect of droping the FK constraint
-- ALTER TABLE geo.Counties DROP CONSTRAINT FK_Counties_State
-- ALTER TABLE geo.Counties ADD CONSTRAINT FK_Counties_State FOREIGN KEY (StateName) REFERENCES geo.States(Name)

INSERT INTO 
	geo.Cities 
VALUES 
	('Timisoara', 319000, 'Timis', 'Romania'),
	('Bucuresti', 1883000, 'Ilfov', 'Romania'),
	('Timisoara', 125000, 'Timis', 'SUA'),
	('Lugoj', 40000, 'Timis', 'Romania'),
	('Baden-Baden', 55000, 'Baden-Württemberg', 'Germania');

-- FK constraint prevents us from adding counties in non-existent countries
INSERT INTO 
	geo.Cities 
VALUES 
	('Lugoj', 80000, 'Baden-Württemberg', 'Romania');

INSERT INTO 
	geo.Capitals 
VALUES 
	('Bucuresti', 'Ilfov', 'Romania');

-- PK constraint rejects this insert
INSERT INTO 
	geo.Capitals 
VALUES 
	('Timisoara', 'Timis', 'Romania');

SELECT * FROM geo.States;

SELECT * FROM geo.Counties;

SELECT * FROM geo.Cities;

SELECT * FROM geo.Capitals;

DROP TABLE geo.Capitals

DROP TABLE geo.Cities

DROP TABLE geo.Counties

DROP TABLE geo.States


------------------------------------------------------------------------------------------
--- Third design
---
GO

CREATE SCHEMA geo2
GO

CREATE TABLE geo2.States	
(
    Id INT NOT NULL,
    Name nvarchar(50) NOT NULL,

    CONSTRAINT PK_States PRIMARY KEY (ID),
    CONSTRAINT AK_States UNIQUE (Name) -- (natural) candidate keys / alternate keys
) 
GO

CREATE TABLE geo2.Counties 
(
    Id INT NOT NULL,
    Name nvarchar(50) NOT NULL,
    Area INT,
    StateId INT NOT NULL,
	
    CONSTRAINT PK_Counties PRIMARY KEY (Id),
    CONSTRAINT AK_Counties UNIQUE (Name, StateId),
    CONSTRAINT FK_Counties_State FOREIGN KEY (StateId) REFERENCES geo2.States(Id),
)
GO


CREATE TABLE geo2.Cities
(
    Id INT IDENTITY(1, 1), -- Id is automatically incremented by the database engine
    Name nvarchar(50) NOT NULL,
    Population INT,
    CountyId INT NOT NULL,

    CONSTRAINT PK_Cities PRIMARY KEY (Id),
    CONSTRAINT AK_Cities UNIQUE (Name, CountyId),
    CONSTRAINT FK_Cities_Counties FOREIGN KEY (CountyId) REFERENCES geo2.Counties (Id)    
)
GO

CREATE TABLE geo2.Capitals	
(
    CityId INT NOT NULL,

    CONSTRAINT FK_Capitals_Cities FOREIGN KEY (CityId) REFERENCES geo2.Cities (Id)
)
GO

INSERT INTO 
	geo2.States (Id, Name)
VALUES 
	(1, 'Romania'), 
	(2, 'Germania'), 
	(3, 'SUA');

INSERT INTO 
	geo2.Counties 
VALUES 
	(1, 'Timis', 100, 1),
	(2, 'Ilfov', 10, 1),
	(3, 'Timis', 1000, 3),
	(5, 'Baden-Württemberg', 25000, 2);

-- FK violation
INSERT INTO 
	geo2.Counties 
VALUES 
	(14, 'Baden-Baden', 25000, 56);

-- Id is automatically incremented, should not be set
INSERT INTO 
	geo2.Cities 
VALUES 
	('Timisoara', 319000, 1),
	('Bucuresti', 1883000, 2),
	('Timisoara', 125000, 3),
	('Lugoj', 40000, 1),
	('Baden-Baden', 55000, 5);

-- FK violation
INSERT INTO 
	geo2.Cities 
VALUES 
	('Lugoj', 40000, 0);

INSERT INTO 
	geo2.Capitals 
VALUES 
	(2); -- Bucuresti

-- Nothing prevents us from having multiple capitals for one state
INSERT INTO 
	geo2.Capitals 
VALUES 
	(1); -- Timisoara

SELECT * FROM geo2.States;

SELECT * FROM geo2.Counties;

SELECT * FROM geo2.Cities;

SELECT * FROM geo2.Capitals;

-- Getting the capital and state names is not straightforward
SELECT c.Name AS Capital, s.Name AS State
FROM geo2.Capitals Cap
INNER JOIN geo2.Cities c on c.Id = Cap.CityId
inner join geo2.Counties cnt on cnt.Id = c.CountyId
inner join geo2.States s on s.ID = cnt.StateId


--
-- In order to have a 1:1 relationship between capital and state
-- one can store the Capital city reference in States table
--
-- Add a new column, CapitalId
ALTER TABLE geo2.States
ADD CapitalId INT CONSTRAINT FK_States_Cities FOREIGN KEY (CapitalId) REFERENCES geo2.Cities(Id)

-- Set Bucuresti capital of Romania
UPDATE geo2.States SET CapitalId = 2 WHERE Id=1;

-- Getting the capital and state names is easier now
SELECT c.Name AS Capital, s.Name AS State
FROM geo2.States s 
INNER JOIN geo2.Cities c ON s.CapitalId = c.Id

-- But, nothing prevents us from setting Lugoj as capital of SUA
-- UPDATE geo2.States SET CapitalId = 4 WHERE Id = 3; -- 4 is Lugoj Id
-- UPDATE geo2.States SET CapitalId = NULL WHERE Id = 3;

SELECT c.Name AS Capital, s.Name AS "Capital Of", s2.Name AS "Located In"
FROM geo2.States s
INNER JOIN geo2.Cities c on c.Id = s.CapitalId
inner join geo2.Counties cnt on cnt.Id = c.CountyId
inner join geo2.States s2 on s2.ID = cnt.StateId

-- Now, let's fix this by adding a CHECK constraint to States table
-- 1. First, we need to create the validation function
GO 
CREATE FUNCTION geo2.IsCityInState 
(
    @CityId INT,
    @StateName VARCHAR(128)
)
RETURNS INT
AS
BEGIN
    IF @StateName = (SELECT S.Name 
                     FROM Counties CN
					 INNER JOIN States S ON CN.StateId = S.Id
                     INNER JOIN Cities CT ON CN.Id = CT.CountyId 
                     WHERE CT.Id = @CityId)
        return 1
    return 0
END
GO

-- 2. Next, add the CHECK constraint
ALTER TABLE geo2.States
ADD CONSTRAINT CK_Valid_Capital CHECK ([geo2].[IsCityInState](CapitalId, Name) = 1 OR CapitalId IS NULL)


-- Try to add Lugoj as capital of SUA now => rejected by the CHECK constraint
UPDATE geo2.States SET CapitalId = 5 WHERE Id = 3;

-- Cleanup time... be careful
-- Because of cycling references we need to drop first the FK constraint
-- and only afterwards the column Capital and then Cities, Counties and 
-- States tables (in this order)
ALTER TABLE geo2.States DROP CONSTRAINT FK_States_Cities

ALTER TABLE geo2.States DROP CONSTRAINT CK_Valid_Capital

ALTER TABLE geo2.States DROP COLUMN CapitalId

DROP TABLE geo2.Capitals

DROP TABLE geo2.Cities

DROP TABLE geo2.Counties

DROP TABLE geo2.States

