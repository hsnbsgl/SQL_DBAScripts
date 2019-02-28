SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_QueryStore_Info] 
@argDBName VARCHAR(128) = NULL
AS
BEGIN

	SET NOCOUNT ON ;
	
	DROP TABLE IF EXISTS #Temp_Result ;

	CREATE TABLE #Temp_Result
	([DB_Name] varchar(128) NULL,
	[actual_state_desc] NVARCHAR(60), 
	[readonly_reason] INT,  
	[desired_state_desc] NVARCHAR(60), 
	[current_storage_size_mb] BIGINT, 
    [max_storage_size_mb] BIGINT, 
	[flush_interval_seconds] BIGINT, 
	[interval_length_minutes] BIGINT, 
    [stale_query_threshold_days] BIGINT, 
	[size_based_cleanup_mode_desc] NVARCHAR(60), 
    [query_capture_mode_desc] NVARCHAR(60), 
	[max_plans_per_query] BIGINT);

	DECLARE @lcSQL NVARCHAR(MAX), @lcDB_Name VARCHAR(100);

	DECLARE Database_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT name FROM sys.databases WITH (NOLOCK)
	WHERE name = @argDBName OR @argDBName IS NULL 

	OPEN Database_Cursor
	FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @lcSQL = 'SELECT 
							' + '''' + @lcDB_Name +'''' +',
							[actual_state_desc], 
							[readonly_reason], 
							[desired_state_desc], 
							[current_storage_size_mb], 
							[max_storage_size_mb], 
							[flush_interval_seconds], 
							[interval_length_minutes], 
							[stale_query_threshold_days], 
							[size_based_cleanup_mode_desc], 
							[query_capture_mode_desc], 
							[max_plans_per_query]
						FROM ' + QUOTENAME(@lcDB_Name) +'.[sys].[database_query_store_options];'
		
		--PRINT @lcSQL
		INSERT INTO #Temp_Result
		EXEC (@lcSQL);
		
   		FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	END
	CLOSE Database_Cursor 
	DEALLOCATE Database_Cursor

	SELECT * 
	FROM #Temp_Result 
	ORDER BY [DB_Name];

	DROP TABLE #Temp_Result;
END


