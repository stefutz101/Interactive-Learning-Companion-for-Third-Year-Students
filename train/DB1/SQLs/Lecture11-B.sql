USE lectures

--------------------------------------------------
--- Session B (Bogdan)
--------------------------------------------------

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Note: This is the default for MS SQL SERVER
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

-- Show the transaction level of the current connection
DBCC USEROPTIONS

--------------------------------------------------
--- Dirty Reads
---------------------------------------------------
BEGIN TRANSACTION

	SELECT * FROM Enrollments
	WHERE StudId = 100
	
	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

COMMIT TRANSACTION
--------------------------------------------------
--- END Dirty Reads
---------------------------------------------------

--------------------------------------------------
--- Non-repeatable Reads
--------------------------------------------------
BEGIN TRANSACTION

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

	UPDATE Courses
	SET Credits = 0
	WHERE Credits = 5

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

	SELECT * FROM Courses

COMMIT TRANSACTION
--------------------------------------------------
--- END Non-repeatable Reads
--------------------------------------------------


--------------------------------------------------
--- Phantom Reads
--------------------------------------------------
BEGIN TRANSACTION

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

	INSERT INTO Enrollments
	(
		StudId, 
		CourseTitle,
		EnrollmentDate, 
		Accepted
	)
	VALUES
	(
		101,
		'Algebra',
		GETDATE(),
		1
	)
	
	-- UPDATE Enrollments SET Accepted = NULL

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

COMMIT TRANSACTION
--------------------------------------------------
--- END Phantom Reads
--------------------------------------------------

--------------------------------------------------
--- Deadlock
--------------------------------------------------
BEGIN TRANSACTION

	UPDATE Courses SET Credits = 200 WHERE Department = 'CS'

	UPDATE Courses SET Credits = 200 WHERE Department = 'LIT'

	SELECT * FROM Courses
	   	 
ROLLBACK TRANSACTION
--------------------------------------------------
--- END Deadlock
--------------------------------------------------

