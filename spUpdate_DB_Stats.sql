
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[spUpdate_DB_Stats] (@argDBName VARCHAR(500)=NULL)
AS BEGIN

	SET NOCOUNT ON;	 
			
	DECLARE  @lcSQL NVARCHAR(MAX), @lcDB_Name VARCHAR(50) ,@lcSchemaName VARCHAR(50),@lcTableName VARCHAR(500), @lcStart_Time DATETIME;
	
	DECLARE @Tables AS TABLE 
	(
	DatabaseName  VARCHAR(500),                                                                                                                          
	SchemaName  VARCHAR(50),             
	TableName  VARCHAR(500)              
	)

	DECLARE curDatabase_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT name FROM sys.databases
	WHERE name NOT IN ('master', 'model','msdb', 'Northwind', 'pubs', 'tempdb', 'mssqlweb') AND name=ISNULL(@argDBName,name) AND is_read_only=0

	OPEN curDatabase_Cursor
	FETCH NEXT FROM curDatabase_Cursor INTO @lcDB_Name
	WHILE @@FETCH_STATUS = 0
	BEGIN
		--PRINT @lcDB_Name
		SELECT @lcSQL = 'USE ['+ @lcDB_Name + '];
						WITH CTETable 
						AS
						(
							SELECT DBTables.*,ISNULL(
								CASE WHEN DBTables.TotalRows<=1000 THEN
										CASE WHEN  PercentModified>=20.0 THEN 1 END
								WHEN PercentModified >=100.00  THEN 1
								ELSE 
									CASE WHEN DBTables.TotalRows > 100000000  AND PercentModified > 0.1 THEN 1
									   WHEN DBTables.TotalRows	 > 10000000  AND PercentModified > 1.0 THEN 1
									   WHEN DBTables.TotalRows   > 1000000  AND PercentModified > 2.0 THEN 1
									   WHEN DBTables.TotalRows   > 100000  AND PercentModified > 5.0 THEN 1
									   WHEN DBTables.TotalRows   > 10000  AND PercentModified > 10.0 THEN 1
									   WHEN DBTables.TotalRows   > 1000  AND PercentModified > 20.0 THEN 1   END
								 END,0) AS UpdateStatics
							FROM 
							(
								SELECT  DISTINCT
										DB_NAME()   AS DatabaseName,
										S.name      AS SchemaName,
										T.name      AS TableName,
										I.rowmodctr AS RowsModified,
										P.rows      AS TotalRows,
										CONVERT(DECIMAL(22,2), CASE WHEN rowcnt=0 THEN 0 ELSE rowmodctr / CONVERT(DECIMAL(28,2), rowcnt) * 100.00 END) AS PercentModified
								FROM sys.partitions P 
									INNER JOIN sys.tables  T ON P.object_Id = T.object_id 
									INNER JOIN sys.schemas S ON T.schema_id = S.schema_id
									INNER JOIN sysindexes  I ON P.object_id = I.id
								WHERE indid > 0 AND indid < 255 AND id > 1000 AND -- excluding system tables
								INDEXPROPERTY(id, I.name, ''IsStatistics'') = 0 AND INDEXPROPERTY(id, I.name, ''IsHypothetical'') = 0 AND rowmodctr <> 0
							) DBTables
						)
						SELECT DISTINCT DatabaseName,SchemaName,TableName FROM CTETable WHERE UpdateStatics=1 ;'
			
		INSERT INTO @Tables		
		EXEC( @lcSQL)

   		FETCH NEXT FROM curDatabase_Cursor INTO @lcDB_Name
	END
	CLOSE curDatabase_Cursor 
	DEALLOCATE curDatabase_Cursor
 
	DECLARE curTable_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 	
	SELECT DISTINCT DatabaseName,SchemaName,TableName FROM @Tables 

	OPEN curTable_Cursor
	FETCH NEXT FROM curTable_Cursor INTO  @lcDB_Name,@lcSchemaName,@lcTableName 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			--PRINT @lcDB_Name+'.'+@lcSchemaName+'.'+@lcTableName 
			SELECT @lcStart_Time = GETDATE();
			
			SELECT  @lcSQL = 'USE [' + @lcDB_Name + ']; UPDATE STATISTICS [' + @lcSchemaName+ '].[' + @lcTableName + '] WITH ALL ;'
				
			EXEC( @lcSQL)
									
			--PRINT @lcSQL
		END TRY

		BEGIN CATCH --Hata oluştu
			DECLARE @lcSubject VARCHAR(50);
			
			SET @lcSubject = @@SERVERNAME + ' - ' + @lcDB_Name +  ' - Update Statistics Error.';
			
			/*Send Mail here*/
		
		END CATCH
		
		FETCH NEXT FROM curTable_Cursor INTO @lcDB_Name,@lcSchemaName,@lcTableName 
	      	
	END
	CLOSE curTable_Cursor 
	DEALLOCATE curTable_Cursor

	SET NOCOUNT OFF;

END

