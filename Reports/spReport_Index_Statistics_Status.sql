
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_Index_Statistics_Status] 
	@argDatabaseName VARCHAR(128), @argObjectNameLike VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcSQL NVARCHAR(MAX)
	
	IF @argDatabaseName IS NULL BEGIN
		RAISERROR('Database Name cannot be empty.', 16, 1)
		RETURN
	END

	SET @lcSQL = 'USE '+ @argDatabaseName + ';
					SELECT  DB_NAME()   AS DatabaseName,
							S.name      AS SchemaName,
							T.name      AS TableName,
							I.name		AS IndexName,
							'''' + CONVERT(VARCHAR(100), STATS_DATE(P.Object_id, I.indid), 121) AS [Statistics Last Updated],
							CAST(P.rows AS DECIMAL(15, 0)) AS TotalRows,
							CAST(I.rowmodctr AS DECIMAL(15, 0)) AS RowsModified,
							CONVERT(DECIMAL(22,2), CASE WHEN rowcnt=0 THEN 0 ELSE rowmodctr / CONVERT(DECIMAL(28,2), rowcnt) * 100.00 END) AS PercentModified
					FROM sys.partitions P WITH (NOLOCK)
						JOIN sys.tables T WITH (NOLOCK) ON P.object_Id = T.object_id 
						JOIN sys.schemas S WITH (NOLOCK) ON T.schema_id = S.schema_id
						JOIN sysindexes I WITH (NOLOCK) ON P.object_id = I.id AND I.indid = P.index_id
					WHERE indid > 0 AND indid < 255 AND id > 1000 AND -- excluding system tables
						INDEXPROPERTY(id, I.name, ''IsStatistics'') = 0 AND INDEXPROPERTY(id, I.name, ''IsHypothetical'') = 0 ' +
						CASE WHEN @argObjectNameLike IS NULL THEN '' ELSE ' AND T.Name LIKE ''%' + @argObjectNameLike + '%''' END + 
					'ORDER BY RowsModified DESC --DatabaseName, SchemaName, TableName, IndexName'
	--PRINT (@lcSQL)
	EXEC( @lcSQL)
END
