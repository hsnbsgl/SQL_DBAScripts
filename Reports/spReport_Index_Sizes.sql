SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[spReport_Index_Sizes] 
@argDBName VARCHAR(128), @argOnly_User_Tables TINYINT = 1
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcSQL VARCHAR(2000)
	
	IF @argDBName  IS NULL BEGIN
		RAISERROR('Database Name cannot be empty.', 16, 1)
		RETURN
	END
	
		
	CREATE TABLE #Index_Sizes (ObjectName VARCHAR(128), index_id INT, IndexName VARCHAR(128), IndexType VARCHAR(128), CompressionDesc VARCHAR(128), 
								[RowCount] DECIMAL(15, 0), Object_Total_reserved_MB DECIMAL(15,2), Total_reserved_MB DECIMAL(15,2), Total_used_MB DECIMAL(15,2), in_row_reserved_MB DECIMAL(15,2), 
								in_row_used_MB DECIMAL(15,2), lob_reserved_MB DECIMAL(15,2), lob_used_MB DECIMAL(15,2), row_overflow_reserved_MB DECIMAL(15,2), 
								row_overflow_used_MB DECIMAL(15,2), ObjectId INT, partition_number INT)
	
	SELECT @lcSQL = 'USE [' + @argDBName + ']; ' + 
					'SELECT SCHEMA_NAME(O.[schema_id]) + ''.'' + O.name AS ObjectName, S.index_id, i.name AS IndexName, i.type_desc, 
							P.data_compression_desc AS [Compression], S.row_count, 0, 
							reserved_page_count/128.00 AS Total_reserved_MB, used_page_count/128.00 AS Total_used_MB, 
							in_row_reserved_page_count/128.00 AS in_row_reserved_MB, in_row_used_page_count/128.00 AS in_row_used_MB,
							lob_reserved_page_count/128.00 AS lob_reserved_MB, lob_used_page_count/128.00 AS lob_used_MB,
							row_overflow_reserved_page_count/128.00 AS row_overflow_reserved_MB, row_overflow_used_page_count/128.00 AS row_overflow_used_MB,
							S.[object_id], S.partition_number
					FROM sys.dm_db_partition_stats S WITH (NOLOCK)
						JOIN sys.objects O WITH (NOLOCK) ON O.object_id = S.object_id 
						 JOIN sys.indexes i WITH (NOLOCK) ON i.object_id = S.object_id AND i.index_id = S.index_id
						 JOIN sys.partitions P WITH (NOLOCK) ON P.object_id = S.object_id and P.index_id= S.index_id ' + 
					CASE WHEN @argOnly_User_Tables = 1 THEN 'WHERE objectproperty(S.object_id,''IsUserTable'') = 1 ' ELSE '' END + 
					'ORDER BY Total_reserved_MB DESC'

	INSERT INTO #Index_Sizes 
	EXEC (@lcSQL)
	
	UPDATE #Index_Sizes SET Object_Total_reserved_MB = G.Object_Total_reserved_MB
	FROM #Index_Sizes I 
		JOIN (SELECT ObjectName, SUM(Total_reserved_MB) AS Object_Total_reserved_MB 
				FROM #Index_Sizes 
				GROUP BY ObjectName) G ON I.ObjectName = G.ObjectName
	
	SELECT * 
	FROM #Index_Sizes
	ORDER BY Object_Total_reserved_MB DESC, Total_reserved_MB DESC

	DROP TABLE #Index_Sizes
	
	SET NOCOUNT OFF
END
