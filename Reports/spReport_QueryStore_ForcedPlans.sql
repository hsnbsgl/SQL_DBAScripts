
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER  PROCEDURE [dbo].[spReport_QueryStore_ForcedPlans] 
@argDBName VARCHAR(128) = NULL
AS
BEGIN

	SET NOCOUNT ON;
	
	DROP TABLE IF EXISTS #Temp_Result ;

    CREATE TABLE #Temp_Result
        (
          [DB_Name] VARCHAR(128) NULL ,
          ObjectName VARCHAR(256) ,
          [Query_id] BIGINT ,
          [Plan_group_id] BIGINT ,
          [Query_parameterization_type_desc] NVARCHAR(60) ,
          [Query_sql_text] NVARCHAR(MAX) ,
          [last_execution_time] VARCHAR(50) ,
          [count_compiles] BIGINT ,
          [is_trivial_plan] BIT ,
          [is_parallel_plan] BIT ,
          [is_forced_plan] BIT ,
          [force_failure_count] BIGINT ,
          [last_force_failure_reason_desc] NVARCHAR(128)
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
							SELECT   DB_NAME() AS [DB_Name] ,
									OBJECT_NAME([qsq].[object_id]) AS ObjectName ,
									qsq.query_id ,
									qsp.plan_group_id ,        
									qsq.query_parameterization_type_desc ,
									qst.query_sql_text ,
									( DATEADD(MINUTE, -( DATEDIFF(MINUTE, GETDATE(), GETUTCDATE()) ),
										  [qsq].[last_execution_time]) ),
									qsq.count_compiles ,
									qsp.is_trivial_plan ,
									qsp.is_parallel_plan ,
									qsp.is_forced_plan ,
									qsp.force_failure_count ,
									qsp.last_force_failure_reason_desc
							FROM    sys.query_store_query qsq
							LEFT JOIN sys.query_store_query_text qst ON qsq.query_text_id = qst.query_text_id
							LEFT JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
							WHERE qsp.is_forced_plan=1;';
		
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



