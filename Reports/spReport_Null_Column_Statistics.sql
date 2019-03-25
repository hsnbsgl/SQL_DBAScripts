SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE OR ALTER   PROCEDURE [dbo].[spReport_Null_Column_Statistics]
	@argDBName VARCHAR(128) 
AS 
BEGIN
	SET ANSI_WARNINGS OFF;
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #NullStatistics;

	CREATE TABLE #NullStatistics
		(
		  Id INT IDENTITY(1, 1) UNIQUE CLUSTERED ,
		  TableName VARCHAR(128) ,
		  ColumnName VARCHAR(128) ,
		  TypeName VARCHAR(50) ,
		  TotalRowCount DECIMAL(18, 2) ,
		  NullRowCount DECIMAL(18, 2)
		);
		
	DECLARE @lcSQL NVARCHAR(MAX);
	
	SELECT @lcSQL = 'USE ' + @argDBName + '; ' +'
	DECLARE @lcObjectName VARCHAR(500);
	DECLARE @lcScript NVARCHAR(MAX);

	DECLARE curDatabases CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT ''SELECT ''+ '''''''' + QUOTENAME(o.name) + '''''','''''' + QUOTENAME(c.name) + '''''','''''' + QUOTENAME(t.name) +'''''''' +'', COUNT(*),
					COUNT(*)-COUNT(''+ QUOTENAME(c.name) +'')
			FROM '' +  o.name  + '' WITH (NOLOCK) HAVING COUNT(*)>0 '' FROM sys.columns C
		INNER JOIN sys.objects O ON O.object_id=C.object_id
		INNER JOIN sys.types T ON t.system_type_id=c.system_type_id
		INNER JOIN sys.schemas S ON s.schema_id=o.schema_id
		WHERE S.name=''dbo'' and o.type=''U'' AND c.is_nullable=1  AND c.is_computed=0 AND t.name NOT IN (''varbinary'',''text'',''image'',''ntext'')

	OPEN curDatabases
	FETCH NEXT FROM curDatabases INTO @lcScript
	WHILE @@FETCH_STATUS=0
	BEGIN

		--PRINT @lcScript;
		INSERT INTO #NullStatistics
		EXEC sp_executesql @lcScript;
	     
		FETCH NEXT FROM curDatabases INTO @lcScript
	END
	CLOSE curDatabases
	DEALLOCATE curDatabases ';

	--PRINT  @lcSQL;
	EXEC sp_executesql @lcSQL;

	SELECT  TableName ,
			ColumnName ,
			TypeName ,
			CONVERT(INT, TotalRowCount) AS TotalRowCount ,
			CONVERT(INT, NullRowCount) AS NullRowCount ,
			CONVERT (INT, ( NullRowCount / TotalRowCount ) * 100) AS [percentage]
	FROM    #NullStatistics
	ORDER BY [percentage] DESC ,NullRowCount DESC;
    
END
