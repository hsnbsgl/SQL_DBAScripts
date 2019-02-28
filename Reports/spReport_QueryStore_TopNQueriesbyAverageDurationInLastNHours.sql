SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_QueryStore_TopNQueriesbyAverageDurationInLastNHours] 
@argDBName VARCHAR(128) = NULL, @argTop_N SMALLINT,@argInLastNHours SMALLINT
AS
BEGIN

	SET NOCOUNT ON ;

	IF @argTop_N IS NULL
		SELECT @argTop_N = 100;

	IF @argInLastNHours IS NULL
		SELECT @argInLastNHours = 8;

		
	DROP TABLE IF EXISTS #Temp_Result ;

    CREATE TABLE #Temp_Result
        (
          [DB_Name] VARCHAR(128) NULL ,
          [Avg_duration MilliSeconds] BIGINT ,
          [Query_text_id] BIGINT ,
		  [Query_id] BIGINT ,
          [Query_sql_text] NVARCHAR(MAX) ,
		  [Object_Name] VARCHAR(256) ,
		  [Plan_id] BIGINT ,
          [LocalLastExecutionTime] VARCHAR(50) 
        );
	
	DECLARE @lcSQL NVARCHAR(MAX), @lcDB_Name VARCHAR(100);

	DECLARE Database_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT name FROM sys.databases WITH (NOLOCK)
	WHERE name = @argDBName OR @argDBName IS NULL

	OPEN Database_Cursor
	FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	WHILE @@FETCH_STATUS = 0
	BEGIN
        SELECT  @lcSQL = 'USE ' + QUOTENAME(@lcDB_Name) + ';									
						SELECT TOP (@argTop_N)
								DB_NAME(),
								[rs].[avg_duration]/1000.00 ,
								[qst].[query_text_id] ,
								[qsq].[query_id] ,
								[qst].[query_sql_text] ,
								CASE WHEN [qsq].[object_id] = 0 THEN N''Ad-hoc''
									 ELSE OBJECT_NAME([qsq].[object_id])
								END AS [ObjectName] ,
								[qsp].[plan_id] ,
								( DATEADD(MINUTE, -( DATEDIFF(MINUTE, GETDATE(), GETUTCDATE()) ),
										  [rs].[last_execution_time]) ) AS [LocalLastExecutionTime]
						FROM    [sys].[query_store_query] [qsq]
								JOIN [sys].[query_store_query_text] [qst] ON [qsq].[query_text_id] = [qst].[query_text_id]
								JOIN [sys].[query_store_plan] [qsp] ON [qsq].[query_id] = [qsp].[query_id]
								JOIN [sys].[query_store_runtime_stats] [rs] ON [qsp].[plan_id] = [rs].[plan_id]
						WHERE   [rs].[last_execution_time] > DATEADD(HOUR, -@argInLastNHours, GETUTCDATE())
						ORDER BY [rs].[avg_duration] DESC; 
						';
		
		--PRINT @lcSQL
		INSERT INTO #Temp_Result
		EXEC sp_executesql @lcSQL, N'@argTop_N SMALLINT, @argInLastNHours SMALLINT', @argTop_N , @argInLastNHours 
		

		
   		FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	END
	CLOSE Database_Cursor 
	DEALLOCATE Database_Cursor

    SELECT TOP ( @argTop_N )
            [DB_Name] ,
            [Avg_duration MilliSeconds] ,
            [Object_Name] ,
            [Query_text_id] ,
            [Query_id] ,
            [Plan_id] ,
            [Query_sql_text] ,
            [LocalLastExecutionTime]
    FROM    #Temp_Result
    ORDER BY [Avg_duration MilliSeconds] DESC;

	DROP TABLE #Temp_Result;
	
END




