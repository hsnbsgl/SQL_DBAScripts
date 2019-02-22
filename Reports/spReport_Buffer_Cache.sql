
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
	Description: if @@argDatabaseName parameter is null returns cache size and buffer count For each database
				 else return objects in the buffer cache for given database

*/
CREATE OR ALTER PROCEDURE [dbo].[spReport_Buffer_Cache] 
	@argDatabaseName VARCHAR(128) --NULL returns all databases
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcSQL NVARCHAR(MAX);
	
	IF @argDatabaseName IS NULL BEGIN --Get total buffer usage by database
		SELECT CASE WHEN database_id = 32767 THEN 'RESOURCE DB' ELSE DB_NAME(database_id) END AS [Database Name], 
				CAST (COUNT(*)/128.00 AS DECIMAL(10,2)) AS [Cached Size (MB)], 
				COUNT(*) AS [Buffer Count]
		FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
		GROUP BY database_id
		ORDER BY [Cached Size (MB)] DESC;
	END
	
	ELSE BEGIN 
		CREATE TABLE #BufferCache (ObjectName VARCHAR(128), PageType VARCHAR(60), IndexId INT, IndexName VARCHAR(128), 
									IndexType VARCHAR(128), CacheSizeMB DECIMAL(10,2), [BufferCount] INT, 
									Object_TotalCacheSizeMB DECIMAL(10,2), Object_TotalBufferCount INT) 

		SELECT @lcSQL = 'USE [' + @argDatabaseName + ']; ' + 
				'SELECT OBJECT_NAME(p.[object_id]), b.page_type, p.index_id, I.name, I.type_desc,
						CAST (COUNT(*)/128.00 AS DECIMAL(10,2)), COUNT(*), 0, 0
				FROM sys.dm_os_buffer_descriptors AS b WITH (NOLOCK) 
					LEFT JOIN sys.allocation_units AS a WITH (NOLOCK) ON a.allocation_unit_id = b.allocation_unit_id
					LEFT JOIN sys.partitions AS p WITH (NOLOCK) ON (a.container_id = p.hobt_id AND a.type IN (1, 3)) OR (a.container_id=p.partition_id AND a.type=2)
					LEFT JOIN sys.indexes I WITH (NOLOCK) ON I.[object_id] = p.[object_id] AND p.index_id = I.index_id
				WHERE b.database_id = DB_ID() 
				GROUP BY p.[object_id], b.page_type, p.index_id, I.name, I.type_desc;'
	
		--PRINT @lcSQL
		INSERT INTO #BufferCache
		EXEC (@lcSQL);
		
		UPDATE #BufferCache SET Object_TotalCacheSizeMB = O.Object_TotalCacheSizeMB, Object_TotalBufferCount= O.Object_TotalBufferCount
		FROM #BufferCache B 
			JOIN (SELECT ObjectName, SUM(CacheSizeMB) AS Object_TotalCacheSizeMB, SUM([BufferCount]) AS Object_TotalBufferCount
					FROM #BufferCache 
					GROUP BY ObjectName) O ON B.ObjectName = O.ObjectName;
		
		SELECT * 
		FROM #BufferCache
		ORDER BY Object_TotalCacheSizeMB DESC, IndexId, PageType;

	END
	
	SET NOCOUNT OFF
END
