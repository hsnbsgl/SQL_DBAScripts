
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE OR ALTER PROCEDURE [dbo].[spReport_Full_Text_Indexes_Columns] 
@argDatabaseName VARCHAR(128)= NULL
AS
BEGIN
 

	SET NOCOUNT ON

	DECLARE @lcDB_Name VARCHAR(100), @lcSQL NVARCHAR(MAX);

	CREATE TABLE #Result ([DB_Name] VARCHAR(100), fulltext_catalog_id int, [Catalog] sysname, [Object_Name] sysname, 
							[Column_Name] sysname, [Type_Column_Name] sysname NULL, is_enabled bit, 
							change_tracking_state_desc varchar(60), crawl_type_desc varchar(60), crawl_start_date datetime, 
							crawl_end_date datetime, has_crawl_completed bit);

	DECLARE curDatabases CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT name FROM sys.databases WITH (NOLOCK)
	WHERE (name = @argDatabaseName OR @argDatabaseName IS NULL)
	ORDER BY name ASC

	OPEN curDatabases
	FETCH NEXT FROM curDatabases INTO @lcDB_Name
	WHILE @@FETCH_STATUS=0
	BEGIN
		SELECT @lcSQL = 'USE [' + @lcDB_Name + ']; ' +
						'SELECT ''' + @lcDB_Name + ''', FI.fulltext_catalog_id, FC.Name AS [Catalog], O.name AS [Object_Name], 
								C.name + '' ('' + type_name(C.user_type_id) + '' ('' + CONVERT(VARCHAR(10), C.max_length) + ''))'' AS [Column_Name], 
								TC.name AS [Type_Column_Name], FI.is_enabled, FI.change_tracking_state_desc, FI.crawl_type_desc, 
								FI.crawl_start_date, FI.crawl_end_date, FI.has_crawl_completed
						FROM sys.fulltext_indexes FI WITH (NOLOCK)
							JOIN sys.fulltext_catalogs FC WITH (NOLOCK) ON FI.fulltext_catalog_id = FC.fulltext_catalog_id
							JOIN sys.objects O WITH (NOLOCK) ON FI.object_id = O.object_id
							JOIN sys.fulltext_index_columns IC WITH (NOLOCK) ON FI.object_id = IC.object_id
							JOIN sys.columns C WITH (NOLOCK) ON C.object_id = FI.object_id AND C.column_id = IC.column_id
							LEFT JOIN sys.columns TC WITH (NOLOCK) ON TC.object_id = FI.object_id AND TC.column_id = IC.type_column_id ';

		INSERT INTO #Result
		EXEC (@lcSQL)
		FETCH NEXT FROM curDatabases INTO @lcDB_Name
	END
	CLOSE curDatabases
	DEALLOCATE curDatabases

	SET NOCOUNT OFF;

	SELECT [DB_Name], fulltext_catalog_id, [Catalog], [Object_Name], [Column_Name], [Type_Column_Name], is_enabled, 
			change_tracking_state_desc, crawl_type_desc, 
			'''' + CONVERT(VARCHAR(100), crawl_start_date, 121) AS crawl_start_date, 
			'''' + CONVERT(VARCHAR(100), crawl_end_date, 121) AS crawl_end_date, has_crawl_completed
	FROM #Result WITH (NOLOCK)
	ORDER BY [DB_Name], [Catalog], [Object_Name], [Column_Name];

	DROP TABLE #Result;
END
