CREATE DATABASE Lectures;
GO

USE Lectures;
GO

CREATE TABLE dbo.Courses
(
	CourseTitle nvarchar(50) NOT NULL,
	Department nvarchar(20) NULL,
	Credits int NOT NULL,
	CONSTRAINT PK_Courses PRIMARY KEY (CourseTitle ASC)
);
GO

CREATE TABLE dbo.Enrollments
(
	StudId int NOT NULL,
	CourseTitle nvarchar(50) NOT NULL,
	EnrollmentDate date NULL,
	Accepted bit NULL,
	CONSTRAINT PK_Enrollments PRIMARY KEY (StudId ASC, CourseTitle ASC)
);
GO

CREATE TABLE dbo.Students
(
	StudId int NOT NULL,
	StudName nvarchar(50) NOT NULL,
	DoB date NULL,
	PoB nvarchar(120) NULL,
	Major nchar(10) NULL,
	CONSTRAINT PK_Students PRIMARY KEY (StudId ASC),
	CONSTRAINT AK_Name_DoB_PoB UNIQUE (StudName ASC, DoB ASC, PoB ASC)
);
GO

ALTER TABLE dbo.Enrollments ADD CONSTRAINT FK_Courses_CourseTitle FOREIGN KEY(CourseTitle)
REFERENCES dbo.Courses (CourseTitle);
GO

ALTER TABLE dbo.Enrollments ADD CONSTRAINT FK_Students_StudId FOREIGN KEY(StudId)
REFERENCES dbo.Students (StudId);
GO

INSERT INTO dbo.Courses
	(CourseTitle, Department, Credits)
VALUES
	('Algebra',	'MATH',	5),
	('Algebra II', 'MATH',	5),
	('Baze de date I', 'CS', 6),
	('English I', 'LIT', 5),
	('Sisteme de operare', 'CS', 6),
	('Structuri de date', 'CS',	5);

INSERT INTO dbo.Students
	(StudId, StudName, DoB, PoB, Major)
VALUES
	(100,	'Adam Gheorghe',	'2001-02-18', 'Baia Mare', 'CS'),        
	(101,	'Ionescu Gabriela',	'2001-01-04', 'Arad', 'CS'),       
	(102,	'Popescu Andrei',	'2001-01-03', 'Lugoj', 'LIT'),      
	(103,	'Popescu Andrei',	'2001-01-03', 'Buzias', 'BIO'),      
	(104,	'Dobre Alexandru',	'2000-06-18', 'Deva', 'GEO');

INSERT INTO dbo.Enrollments
	(StudId, CourseTitle, EnrollmentDate, Accepted)
VALUES
	(100, 'Baze de date I',	'2020-09-23', 1),
	(100, 'English I',	'2020-09-24', NULL),
	(101, 'Baze de date I',	'2020-09-23', 1),
	(101, 'English I',	'2020-10-05', NULL),
	(102, 'English I',	'2020-10-06', NULL),
	(103, 'English I',	'2020-10-06', NULL);

SELECT * FROM Students;

SELECT * FROM Courses;

SELECT * FROM Enrollments;


