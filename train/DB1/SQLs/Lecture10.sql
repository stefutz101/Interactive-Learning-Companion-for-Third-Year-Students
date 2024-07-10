--USE Lectures
--GO

-- Despite the fact that some of the examples in this document
-- work only against MS SQL SERVER / Azure Relational Database
-- the concepts hold for other relational DBMSes as well with
-- small syntax adjustments

-- Get to know your data
SELECT * FROM Courses;
SELECT * FROM Enrollments;
SELECT * FROM Students;

-- MobileAppView
GO
CREATE /*ALTER*/ VIEW MobileAppView 
AS
SELECT
	StudID AS Id, 
	E.CourseTitle AS Course, 
	EnrollmentDate, 
	Accepted, 
	Department AS DeptName, 
	Credits 
FROM 
	Enrollments E 
    INNER JOIN Courses C ON E.CourseTitle = C.CourseTitle;
GO

-- Use view
SELECT * FROM MobileAppView;

-- Drop view
DROP VIEW MobileAppView;
GO

-- Create View
CREATE /*ALTER*/ VIEW StudentsWithNoEnrollments 
AS
SELECT Students.StudID, StudName
FROM Students
    LEFT JOIN Enrollments ON Enrollments.StudID = Students.StudID
WHERE Enrollments.StudID IS NULL;
GO

-- Use view
SELECT * FROM StudentsWithNoEnrollments;

-- Drop view
DROP VIEW StudentsWithNoEnrollments;
GO

-- Modifiable view
CREATE /*ALTER*/ VIEW DBAccepted(ID, Curs, EDate) 
AS
SELECT StudID, CourseTitle, EnrollmentDate 
FROM Enrollments 
WHERE CourseTitle='Baze de date I' AND Accepted=1;
GO

-- A view in another view's definition
CREATE /*ALTER*/ VIEW DBAccepted2 
AS
SELECT Students.StudID, StudName, Major 
FROM Students, DBAccepted
WHERE Students.StudID = DBAccepted.ID;
GO

SELECT * 
FROM DBAccepted2
WHERE StudName LIKE '%escu%';

DROP VIEW DBAccepted2;
GO

BEGIN TRANSACTION

SELECT * FROM DBAccepted;

--DELETE FROM DBAccepted WHERE ID=101;

--UPDATE DBAccepted SET EDate = '2021-11-01' WHERE ID=101;

--UPDATE DBAccepted SET Curs = 'Algebra' WHERE ID=101;

--INSERT INTO DBAccepted 
--	(ID, Curs, EDate)
--VALUES 
--	(1004, 'Baze de date I', '2021-11-01');

--INSERT INTO DBAccepted 
--	(ID, Curs, EDate)
--VALUES 
--	(104, 'Baze de date I', '2021-11-01');

SELECT * FROM DBAccepted;

SELECT * FROM Enrollments;

ROLLBACK

-- Modifiable view WITH CHECK OPTION
GO
CREATE VIEW DBAcceptedChecked(ID, Curs, EDate) 
AS
SELECT StudID, CourseTitle, EnrollmentDate 
FROM Enrollments 
WHERE CourseTitle='Baze de date I' AND Accepted=1
WITH CHECK OPTION;
GO

BEGIN TRANSACTION

SELECT * FROM DBAcceptedChecked;

--DELETE FROM DBAcceptedChecked WHERE ID=101;

--UPDATE DBAcceptedChecked SET EDate = '2021-11-01' WHERE ID=101;

--UPDATE DBAcceptedChecked SET Curs = 'Algebra' WHERE ID=101;

--INSERT INTO DBAcceptedChecked 
--	(ID, Curs, EDate)
--VALUES 
--	(104, 'Baze de date I', '2021-11-01');

SELECT * FROM DBAcceptedChecked;

SELECT * FROM Enrollments;

ROLLBACK

-- Drop views
DROP VIEW DBAccepted;

DROP VIEW DBAcceptedChecked;
GO

-- Modifiable view through trigger
CREATE /*ALTER*/ VIEW DBAcceptedUnmodifiable(ID, Name, Course, EDate) 
AS
SELECT S.StudID, StudName, CourseTitle, EnrollmentDate 
FROM Enrollments E JOIN Students S ON E.StudId = S.StudId
WHERE CourseTitle='Baze de date I' AND Accepted=1;
GO

-- This trigger definition works only under MS SQL SERVER
-- Other DBMSes have a slightly different syntax
CREATE TRIGGER DBAcceptedUnmodifiable_OnDelete
ON DBAcceptedUnmodifiable
INSTEAD OF DELETE 
AS
DELETE E
FROM Enrollments E
	INNER JOIN deleted D ON D.ID = E.StudID AND D.EDate = E.EnrollmentDate
WHERE CourseTitle = 'Baze de date I' AND Accepted = 1;
GO

BEGIN TRANSACTION
SELECT * FROM DBAcceptedUnmodifiable;

DELETE FROM DBAcceptedUnmodifiable WHERE ID=101;

SELECT * FROM DBAcceptedUnmodifiable;

SELECT * FROM Enrollments;

ROLLBACK

DROP TRIGGER DBAcceptedUnmodifiable_OnDelete;
DROP VIEW DBAcceptedUnmodifiable;
GO

-- Materialzed views
-- This materialized view definition works only under MS SQL SERVER
-- Other DBMSes have a slightly different syntax
CREATE VIEW CSEnrollments
WITH SCHEMABINDING
AS
 SELECT S.StudID, CourseTitle, Accepted 
 FROM dbo.Enrollments E
 INNER JOIN dbo.Students S ON E.StudID = S.StudId
 WHERE Major='CS';
GO

CREATE UNIQUE CLUSTERED INDEX IDX_CSEnrollments
   ON CSEnrollments (StudID, CourseTitle);
GO

-- Use the materialized view
SELECT * FROM CSEnrollments

-- These queries 'transparently' use the materialized view, because query engine finds it appealing
SELECT S.StudID, CourseTitle, Accepted 
 FROM dbo.Enrollments E
 INNER JOIN dbo.Students S ON E.StudID = S.StudId
 WHERE Major='CS';

SELECT S.StudID, count(S.StudID) as cnt
 FROM dbo.Enrollments E
 INNER JOIN dbo.Students S ON E.StudID = S.StudId
 WHERE Major='CS'
 GROUP BY S.StudId;

DROP INDEX IDX_CSEnrollments ON CSEnrollments
DROP VIEW CSEnrollments
GO

-- Inline Table Value Function
-- Inline Table Value Functions work only under MS SQL SERVER
CREATE FUNCTION EnrolledStudents (@CourseTitle VARCHAR(50))
RETURNS TABLE
AS
RETURN 
SELECT S.*, E.EnrollmentDate, E.Accepted
FROM Students S
	INNER JOIN Enrollments E ON S.StudID = E.StudID
WHERE E.CourseTitle = @CourseTitle;
GO

SELECT * FROM EnrolledStudents('Baze de date I') WHERE Accepted = 1;

SELECT * FROM EnrolledStudents('English I');

DROP FUNCTION EnrolledStudents
