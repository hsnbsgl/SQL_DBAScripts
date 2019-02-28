SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_QueryStore_TopNQueriesbyExecutionCount] 
@argDBName VARCHAR(128) = NULL,  @argTop_N SMALLINT
AS
BEGIN

	SET NOCOUNT ON ;

	IF @argTop_N IS NULL
		SELECT @argTop_N = 500;
		
	DROP TABLE IF EXISTS #Temp_Result ;

    CREATE TABLE #Temp_Result
        (
          [DB_Name] VARCHAR(128) NULL ,
          [Query_id] BIGINT ,
          [Query_text_id] BIGINT ,
		  [ObjectName] NVARCHAR(MAX),
          [Query_sql_text] NVARCHAR(MAX) ,
          [total_execution_count] BIGINT 
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
				SELECT  
						DB_NAME(),
						q.query_id ,
						qt.query_text_id ,
						OBJECT_NAME(q.object_id),
						qt.query_sql_text ,
						SUM(rs.count_executions) AS total_execution_count
				FROM    sys.query_store_query_text AS qt
						JOIN sys.query_store_query AS q ON qt.query_text_id = q.query_text_id
						JOIN sys.query_store_plan AS p ON q.query_id = p.query_id
						JOIN sys.query_store_runtime_stats AS rs ON p.plan_id = rs.plan_id
				GROUP BY q.query_id ,
						q.object_id,
						qt.query_text_id ,
						qt.query_sql_text;';
		
		--PRINT @lcSQL
		INSERT INTO #Temp_Result
		EXEC (@lcSQL);
		
   		FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	END
	CLOSE Database_Cursor 
	DEALLOCATE Database_Cursor

    SELECT TOP ( @argTop_N )
            [DB_Name] ,
            [Total_Execution_Count] ,
            [Query_id] ,
            [Query_text_id] ,
			[ObjectName],
            [Query_sql_text]
    FROM    #Temp_Result
    ORDER BY total_execution_count DESC;

	DROP TABLE #Temp_Result;
	
END



