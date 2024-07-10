USE lectures

--------------------------------------------------
--- Create a view that shows the database locks
--------------------------------------------------
IF Object_ID('dbo.vwDbLocks') IS NOT NULL
    DROP VIEW dbo.vwDbLocks;
GO

CREATE VIEW dbo.vwDbLocks
AS
SELECT 
	request_session_id AS "Session ID",
	resource_type AS Resource, 
	--resource_associated_entity_id AS "Resource ID", 
	CASE
        WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(dm_tran_locks.resource_associated_entity_id)
        ELSE OBJECT_NAME(partitions.OBJECT_ID)
    END AS "Resource Name",
	request_status AS Status, 
	request_mode AS Mode,
    resource_description AS Description  
FROM 
	sys.dm_tran_locks  
LEFT JOIN 
	sys.partitions ON partitions.hobt_id = dm_tran_locks.resource_associated_entity_id
WHERE 
	resource_database_id = DB_ID()
	AND resource_type <> 'DATABASE'
	AND CASE
			WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(dm_tran_locks.resource_associated_entity_id)
			ELSE OBJECT_NAME(partitions.OBJECT_ID)
		END  <> 'vwDbLocks'
GO

-- Set isolation level to Read Committed Snapshot
-- Caveat: May not work in an Azure SQL Database
-- Turning ON
ALTER DATABASE lectures SET READ_COMMITTED_SNAPSHOT ON  WITH ROLLBACK IMMEDIATE

-- Turning OFF
ALTER DATABASE lectures SET READ_COMMITTED_SNAPSHOT OFF  WITH ROLLBACK IMMEDIATE

-- Show the status of RCSI (Read Committed Snapshot Isolation) flag
SELECT 
	Name, 
	Snapshot_isolation_state_desc, 
	is_read_committed_snapshot_on 
FROM 
	sys.databases 
WHERE 
	Name = DB_NAME()
-- End Set isolation level to Read Committed Snapshot


--------------------------------------------------
--- Session A (Alexandra)
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
--------------------------------------------------
-- Arrange
UPDATE Enrollments
SET Accepted = NULL
WHERE StudId = 100

BEGIN TRANSACTION

	UPDATE Enrollments
	SET Accepted = 1
	WHERE StudId = 100

	-- SELECT * FROM Enrollments

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

ROLLBACK TRANSACTION
-- COMMIT TRANSACTION
--------------------------------------------------
--- END Dirty Reads
--------------------------------------------------

--------------------------------------------------
--- Non-repeatable Reads
--------------------------------------------------
-- Arrange
UPDATE Courses
SET Credits = 5
WHERE CourseTitle IN ('Algebra', 'Algebra II', 'English I', 'Structuri de date')

BEGIN TRANSACTION

	-- First read
	SELECT * FROM Courses WHERE Department = 'MATH' AND Credits = 5

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

	WAITFOR DELAY '00:00:10' -- Wait for 10 secconds

	-- Second read
	SELECT * FROM Courses WHERE Department = 'MATH' AND Credits = 5

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

ROLLBACK TRANSACTION
--------------------------------------------------
--- END Non-repeatable Reads
--------------------------------------------------

--------------------------------------------------
--- Phantom Reads
--------------------------------------------------
-- Arrange
DELETE FROM Enrollments
WHERE StudId = 101 AND CourseTitle = 'Algebra'

BEGIN TRANSACTION

	SELECT COUNT(*) FROM Enrollments WHERE Accepted = 1

	WAITFOR DELAY '00:00:10' -- Wait for 10 secconds

	SELECT COUNT(*) FROM Enrollments WHERE Accepted = 1

COMMIT TRANSACTION
--------------------------------------------------
--- END Phantom Reads
--------------------------------------------------

--------------------------------------------------
--- Deadlock
--------------------------------------------------
BEGIN TRANSACTION

	UPDATE Courses SET Credits = 100 WHERE Department = 'LIT'

	WAITFOR DELAY '00:00:10' -- Wait for 10 secconds

	SELECT * FROM dbo.vwDbLocks ORDER BY "Session ID"

	UPDATE Courses SET Credits = 100 WHERE Department = 'CS'

	SELECT * FROM Courses

ROLLBACK TRANSACTION
--------------------------------------------------
--- END Deadlock
--------------------------------------------------
