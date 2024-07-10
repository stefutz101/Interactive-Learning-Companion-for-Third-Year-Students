--USE Lectures
--GO

-- Get to know the data
SELECT * FROM Courses;
SELECT * FROM Enrollments;
SELECT * FROM Students;

-- Students x Enrollments
SELECT *
FROM Students, Enrollments

SELECT *
FROM Students CROSS JOIN Enrollments


-- Students and their enrollments
SELECT *
FROM Students, Enrollments
WHERE Students.StudId = Enrollments.StudId

SELECT *
FROM Students CROSS JOIN Enrollments
WHERE Students.StudId = Enrollments.StudId

-- Renaming operator
-- Selects all distinct pairs (C1, C2) where C1 and C2 are offered by the same department
SELECT * FROM Courses AS C1, Courses AS C2

SELECT
	C1.CourseTitle AS "Curs 1", 
	C2.CourseTitle AS "Curs 2" ,
	C1.Department
FROM 
	Courses AS C1, 
	Courses AS C2
WHERE 
	C1.Department = C2.Department
	AND C1.CourseTitle <> C2.CourseTitle
ORDER BY
	Department

-- Out of (C1, C2) and (C2, C1) keeps only the former
SELECT
	C1.CourseTitle AS "Curs 1", 
	C2.CourseTitle AS "Curs 2" ,
	C1.Department
FROM 
	Courses AS C1, 
	Courses AS C2
WHERE 
	C1.Department = C2.Department
	AND C1.CourseTitle < C2.CourseTitle
	
-- Theta inner join
SELECT *
FROM Students 
    INNER JOIN Enrollments ON Students.StudID < Enrollments.StudID

-- Equi inner join: Students and their enrollments
SELECT *
FROM Students 
    INNER JOIN Enrollments ON Students.StudID = Enrollments.StudID

SELECT 
	StudName, PoB, Major, EnrollmentDate
FROM 
	Students 
    INNER JOIN Enrollments ON Students.StudID = Enrollments.StudID

-- Natural join: Students who applied for English I
SELECT
	StudName, Major, Accepted
FROM
	Students s INNER JOIN Enrollments e ON s.StudID = e.StudID
WHERE
	e.CourseTitle = 'English I'


-- Left join: All students w/ or w/o enrollments
SELECT *
FROM Students 
    LEFT JOIN Enrollments ON Students.StudID = Enrollments.StudID

-- Right join: All courses offered by CS department w/ or w/o enrolled students
SELECT *
FROM Enrollments 
    RIGHT JOIN Courses ON Enrollments.CourseTitle = Courses.CourseTitle
WHERE 
	Department = 'CS'

-- Full join: Students and available courses
SELECT *
FROM Students 
    FULL JOIN Courses ON Students.Major = Courses.Department
--WHERE Courses.CourseTitle IS NULL

-- Left semi join with self-contained multi-valued subquery
SELECT *
FROM Students 
WHERE StudID IN (SELECT StudID FROM Enrollments WHERE CourseTitle='Baze de date I' AND Accepted=1)

-- Left semi join with correlated multi-valued subquery
SELECT *
FROM Students 
WHERE StudID IN (SELECT StudID FROM Enrollments WHERE Enrollments.StudID = Students.StudId AND CourseTitle='Baze de date I' AND Accepted=1)

-- Left semi join with inner join
SELECT 
	Students.*
FROM 
	Students 
	INNER JOIN Enrollments ON Enrollments.StudID = Students.StudId
WHERE 
	CourseTitle='Baze de date I' 
	AND Accepted=1

-- Left anti join with self-contained multi-valued subquery
SELECT *
FROM Students 
WHERE StudID NOT IN (SELECT StudID FROM Enrollments WHERE CourseTitle='English I' AND Accepted=1)

-- Left anti join with correleated multi-valued subquery
SELECT *
FROM Students 
WHERE StudID NOT IN (SELECT StudID FROM Enrollments WHERE Enrollments.StudID = Students.StudID AND CourseTitle='English I' AND Accepted=1)

-- Left anti join with EXISTS and correleated multi-valued subquery
SELECT *
FROM Students 
WHERE NOT EXISTS (SELECT StudID FROM Enrollments WHERE Enrollments.StudID = Students.StudID AND CourseTitle='English I' AND Accepted=1)


-- Union: ERROR - incompatible relations
SELECT * FROM Enrollments
UNION
SELECT * FROM Students

SELECT Department FROM Courses
UNION
SELECT Major FROM Students

SELECT Department FROM Courses
UNION ALL
SELECT Major FROM Students

-- Difference with except
SELECT StudID FROM Students
EXCEPT
SELECT StudID FROM Enrollments

-- Difference with left join
SELECT Students.*
FROM Students
    LEFT JOIN Enrollments ON Enrollments.StudID = Students.StudID
WHERE Enrollments.StudId IS NULL

-- Intersect
SELECT Department FROM Courses
INTERSECT
SELECT Major FROM Students

-- Intersect: Students' ids of those who enrolled in at least one course
SELECT StudID FROM Students
INTERSECT
SELECT StudID FROM Enrollments

-- Intersect with inner join
SELECT DISTINCT Department 
FROM Courses
	INNER JOIN Students ON Courses.Department = Students.Major

-- Number of students from Timisoara
SELECT COUNT(StudID) AS StudCount 
FROM Students
WHERE PoB = 'Tm'

-- Number of students born in each city
SELECT 
	PoB AS 'Place of Birth', 
	COUNT(*) AS 'Nb of students'
FROM Students 
GROUP BY PoB

-- Exercise 1: Students with no enrollments
SELECT Students.StudID, StudName
FROM Students
    LEFT JOIN Enrollments ON Enrollments.StudID = Students.StudID
WHERE Enrollments.StudID IS NULL

-- Exercise 2: List the id, name, surname, date of birth, place of birth, major 
-- and any unconfirmed enrollment they may have
SELECT  S.StudID AS ID,
		LEFT(StudName, CHARINDEX(' ', StudName)) AS NUME,
		RIGHT(StudName, LEN(StudName) - CHARINDEX(' ', StudName)) AS PRENUME,
		FORMAT(DoB, 'dd MMMM yyyy') AS "DATA NASTERII",
		PoB AS "LOCUL NASTERII",
		Major AS SPECIALIZARE,
		EC.*
FROM Students S
LEFT JOIN (SELECT E.*, C.Department, C.Credits
		   FROM Enrollments E 
		   INNER JOIN Courses C ON E.CourseTitle = C.CourseTitle) EC ON S.StudID = EC.StudID
WHERE Accepted IS NULL
ORDER BY NUME, PRENUME

-- Exercise 3: List the name of the students and their total unconfirmed credits sorted desc by 
-- total unconfirmed credits, for all students with at least 2 unconfirmed enrollments
SELECT StudName, SUM(EC.Credits) AS UnconfirmedCredits
FROM Students S
LEFT JOIN (SELECT E.*, C.Department, C.Credits
		   FROM Enrollments E 
		   INNER JOIN Courses C ON E.CourseTitle = C.CourseTitle) EC ON S.StudID = EC.StudID
WHERE Accepted IS NULL
GROUP BY StudName
HAVING COUNT(*) > 1
ORDER BY UnconfirmedCredits DESC

-- Exercise 4: Find duplicate student names
SELECT 
	LEFT(StudName, CHARINDEX(' ', StudName)) AS NUME,
	COUNT(*) AS DUPLICATE
FROM Students S
GROUP BY LEFT(StudName, CHARINDEX(' ', StudName))
HAVING COUNT(*) > 1
ORDER BY NUME

-- Exercise 5: Find the students who were not accepted for any of the courses they applied to
--             (i.e. if accepted for at least one course they should be filtered-out)
--             πStudId(Students) - πStudId(σAccepted=1 (Enrollments)) 
-- Correct
SELECT 
	* 
FROM Students 
LEFT JOIN Enrollments ON Enrollments.StudId = Students.StudID AND Accepted = 1 
WHERE Enrollments.StudId IS NULL

-- Wrong
-- SELECT StudId FROM Student LEFT JOIN Enrollments ON Enrollments.StudId = Student.StudID WHERE Enrollments.StudId IS NULL AND Decision != TRUE

-- Also wrong
-- SELECT * FROM Students LEFT JOIN Enrollments ON Enrollments.StudId = Students.StudID WHERE (Accepted IS NULL OR Accepted != 1) AND Enrollments.StudId IS NULL
