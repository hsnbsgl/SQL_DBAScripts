
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE OR ALTER PROCEDURE [dbo].[spReport_Full_Text_Catalogs] 
@argDatabaseName  VARCHAR(128)=NULL
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @lcDB_Name VARCHAR(100), @lcSQL NVARCHAR(MAX);

	CREATE TABLE #Result ([DB_Name] VARCHAR(100), fulltext_catalog_id int, [name] sysname, [path] varchar(260), 
							is_default bit, is_accent_sensitivity_on bit, Populatestatus TINYINT, ItemCount INT, 
							UniqueKeyCount INT, IndexSize INT);

	DECLARE curDatabases CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT name FROM sys.databases WITH (NOLOCK)
	WHERE (name = @argDatabaseName OR @argDatabaseName IS NULL)
	ORDER BY name ASC

	OPEN curDatabases
	FETCH NEXT FROM curDatabases INTO @lcDB_Name
	WHILE @@FETCH_STATUS=0
	BEGIN

		SELECT @lcSQL = 'USE [' + @lcDB_Name + ']; ' +
						'SELECT ''' + @lcDB_Name + ''', fulltext_catalog_id, [name], [path], is_default, is_accent_sensitivity_on, 
							FULLTEXTCATALOGPROPERTY(name, ''Populatestatus''), FULLTEXTCATALOGPROPERTY(name, ''ItemCount''), 
							FULLTEXTCATALOGPROPERTY(name, ''UniqueKeyCount''), FULLTEXTCATALOGPROPERTY(name, ''IndexSize'') 
						FROM sys.fulltext_catalogs WITH (NOLOCK)';

		INSERT INTO #Result
		EXEC (@lcSQL)
		FETCH NEXT FROM curDatabases INTO @lcDB_Name
	END
	CLOSE curDatabases
	DEALLOCATE curDatabases

	SET NOCOUNT OFF;


	SELECT [DB_Name], fulltext_catalog_id, [name], [path], is_default, is_accent_sensitivity_on, 
			CASE Populatestatus WHEN 0 THEN 'Idle'
								WHEN 1 THEN 'Full population in progress'
								WHEN 2 THEN 'Paused'
								WHEN 3 THEN 'Throttled'
								WHEN 4 THEN 'Recovering'
								WHEN 5 THEN 'Shutdown'
								WHEN 6 THEN 'Incremental population in progress'
								WHEN 7 THEN 'Building index'
								WHEN 8 THEN 'Disk is full. Paused.'
								WHEN 9 THEN 'Change tracking'
								ELSE CONVERT(VARCHAR(5), Populatestatus)
			END AS Populatestatus, 
			ItemCount, UniqueKeyCount, IndexSize AS [IndexSize (MB)] 
	FROM #Result WITH (NOLOCK)
	ORDER BY [DB_Name], fulltext_catalog_id;

	DROP TABLE #Result;
END
