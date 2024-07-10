USE [AdventureWorks2017]
GO

-- Create our big table
CREATE TABLE [dbo].[BigTable]
(
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] IDENTITY(1,1) NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal] [numeric](38, 6) NOT NULL,
	[rowguid] [uniqueidentifier] NOT NULL,
	[ModifiedDate] [datetime] NOT NULL
)
GO

-- Populate the BigTable with 1000 x 542 rows
INSERT INTO [dbo].[BigTable] SELECT [SalesOrderID]
	,'0123456789' --,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,1 --,[SpecialOfferID]
	,[UnitPrice]
	,[UnitPriceDiscount]
	,[LineTotal]
	,[rowguid]
	,[ModifiedDate] 
FROM [SalesLT].[SalesOrderDetail]
-- Adjust 1000 value according to your needs
GO 1000

SELECT COUNT(*) FROM BigTable

SELECT TOP 100 * FROM BigTable

-- Enable the execution time tracking in the messages tab
-- In SSMS, enable 'Include Live Query Statistics'
SET STATISTICS TIME ON

-- Removes all clean buffers from the buffer pool, and columnstore objects from the columnstore object pool
DBCC DROPCLEANBUFFERS

-- Lookup for a record by SalesOrderDetailID (without any index)
SELECT * FROM BigTable WHERE SalesOrderDetailID=120

-- The CPU time indicates the total time that is spent by the CPU(s). 
-- The elapsed time is the total time to complete the execution of the query. 
--    This elapsed time includes all I/O operations time, wait times, and the time is taken to transfer the resultset to the client.


--- Create one clustered index
CREATE CLUSTERED INDEX [CLI_SalesOrderDetailID] ON [dbo].[BigTable]
(
	[SalesOrderDetailID] ASC
)
GO

-- Create one non-clustered index
CREATE NONCLUSTERED INDEX [NonClusteredIndexDemo] ON [dbo].[BigTable]
(
	[UnitPrice] ASC,
	[ModifiedDate] ASC
)
INCLUDE ([OrderQty])
GO

-- Create one column store index
CREATE NONCLUSTERED COLUMNSTORE INDEX [NonClusteredColumnStoreIndexDemo] ON [dbo].[BigTable]
(
	[SalesOrderID],
	[SalesOrderDetailID],
	[CarrierTrackingNumber],
	[OrderQty],
	[ProductID],
	[SpecialOfferID],
	[UnitPrice],
	[UnitPriceDiscount],
	[LineTotal],
	[ModifiedDate]
) WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0) ON [PRIMARY]
GO

-- Run some loads against our BigTable
--
-- Enable the execution time tracking in the messages tab
SET STATISTICS TIME ON

-- Lookup for a record SalesOrderDetailID
-- Now, this is using 'by default' the [CLI_SalesOrderDetailID] index
SELECT * FROM BigTable WHERE SalesOrderDetailID=120

-- Slow: Table Scan (using the clustered index)
SELECT OrderQty FROM [dbo].[BigTable] 
WITH (INDEX(CLI_SalesOrderDetailID))
WHERE UnitPrice = 63.90 

-- Fast: Index Seek (using a non-clustered index)
SELECT OrderQty FROM [dbo].[BigTable] 
WITH (INDEX(NonClusteredIndexDemo)) 
WHERE UnitPrice = 63.90 

-- Aggregating a column using a column-store index vs. clustered index
SELECT AVG(UnitPrice) FROM [dbo].[BigTable]
WITH (INDEX(CLI_SalesOrderDetailID))

SELECT AVG(UnitPrice) FROM [dbo].[BigTable]
WITH (INDEX(NonClusteredColumnStoreIndexDemo))


-- Show index structure (pages etc)
DBCC TRACEON (3604);
GO

-- Show all index pages for a table
DBCC IND ('db100-samples', BigTable, -1)
GO

-- Show all pages of a database
DBCC PAGE ('db100-samples', 1, 1, 3); 
GO

-- Show an index page
DBCC PAGE ('db100-samples', 1, 8896, 3); 
GO


-- Cleanup time
DROP INDEX [CLI_SalesOrderDetailID] ON [dbo].[BigTable]
GO

DROP INDEX [NonClusteredIndexDemo] ON [dbo].[BigTable]
GO

--DROP INDEX [NonClusteredColumnStoreIndexDemo] 
--GO

DROP TABLE BigTable
GO
