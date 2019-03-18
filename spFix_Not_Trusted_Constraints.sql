
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER FUNCTION [dbo].[fnSQL_Operator_Email_Address] (@argOperator_Name VARCHAR(128))  
RETURNS VARCHAR(100) AS  
BEGIN 

	DECLARE @lcResult VARCHAR(100);

	SELECT @lcResult = email_address FROM msdb.dbo.sysoperators WHERE name = @argOperator_Name;

	RETURN @lcResult

END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	Check For Foreign Keys and Constraints ( is_not_trusted=1 and is_disabled=0 )
*/

CREATE OR ALTER PROCEDURE [dbo].[spFix_Not_Trusted_Constraints](@argDBName VARCHAR(128)=NULL)
AS BEGIN

	SET NOCOUNT ON;

	DECLARE @lcSQL NVARCHAR(MAX), @lcDB_Name VARCHAR(128) ,@lcSchemaName VARCHAR(50),@lcTableName VARCHAR(500),@lcConstraintName VARCHAR(500);

	DECLARE @Tables AS TABLE 
	(
	DatabaseName  VARCHAR(128),                                                                                                                          
	SchemaName  VARCHAR(50),             
	TableName  VARCHAR(500)  ,
	ConstraintName  VARCHAR(500)  	            
	);

	DECLARE curDatabase_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT name FROM sys.databases
	WHERE name NOT IN ('master', 'model','msdb', 'Northwind', 'pubs', 'tempdb', 'mssqlweb') AND name=ISNULL(@argDBName,name) AND is_read_only=0  AND state=0

	OPEN curDatabase_Cursor
	FETCH NEXT FROM curDatabase_Cursor INTO @lcDB_Name
	WHILE @@FETCH_STATUS = 0
	BEGIN				
		--PRINT @lcDB_Name
		SELECT @lcSQL = 'USE ['+ @lcDB_Name + '];						
						SELECT  DB_NAME() AS DBName ,  s.name  AS SchemaName ,  o.name AS TableName, i.name AS ConstraintName
						FROM sys.foreign_keys i
							INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
							INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
						WHERE i.is_not_trusted = 1 AND i.is_disabled = 0
						UNION 
						SELECT  DB_NAME() , s.name ,  o.name , i.name  FROM sys.check_constraints i 
							INNER JOIN sys.objects o ON i.parent_object_id = o.object_id
							INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
						WHERE is_not_trusted=1 AND is_disabled=0'
			
		INSERT INTO @Tables		
		EXEC( @lcSQL)

   		FETCH NEXT FROM curDatabase_Cursor INTO @lcDB_Name
	END
	CLOSE curDatabase_Cursor 
	DEALLOCATE curDatabase_Cursor
 
	DECLARE curTable_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 	
	SELECT DISTINCT DatabaseName,SchemaName,TableName,ConstraintName FROM @Tables 

	OPEN curTable_Cursor
	FETCH NEXT FROM curTable_Cursor INTO  @lcDB_Name,@lcSchemaName,@lcTableName,@lcConstraintName 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY

				PRINT @lcDB_Name +'.'+ @lcSchemaName +'.'+ @lcTableName + '.' + @lcConstraintName
				
				SELECT  @lcSQL = 'USE [' + @lcDB_Name + ']; ALTER TABLE [' + @lcSchemaName+ '].[' + @lcTableName + '] WITH CHECK CHECK CONSTRAINT [' + @lcConstraintName + '];'
				
				EXEC( @lcSQL);
									
		END TRY

		BEGIN CATCH 
			DECLARE @lcSubject VARCHAR(MAX),@lcBody VARCHAR(MAX),@lcEmail_Address VARCHAR(MAX);
			
			SELECT @lcEmail_Address = dbo.fnSQL_Operator_Email_Address('DB Admins');
			
			SET @lcSubject =  @@SERVERNAME +'.' +  @lcDB_Name +'.'+ @lcSchemaName +'.'+ @lcTableName + '.' + @lcConstraintName  +  ' - Constraint Check Error';
			
			SELECT @lcBody = 'Error No=' + ISNULL(CONVERT(VARCHAR(10), ERROR_NUMBER()), 'NULL') +  
						', Procedure=' + ISNULL(ERROR_PROCEDURE(), 'NULL') + 
						', Line=' + ISNULL(CONVERT(VARCHAR(10), ERROR_LINE()), 'NULL') + 
						', Message=' + ISNULL(ERROR_MESSAGE(), 'NULL');

			EXEC msdb.dbo.sp_send_dbmail @recipients = @lcEmail_Address, @subject = @lcSubject, @body_format = 'HTML';
						
		END CATCH
		
		FETCH NEXT FROM curTable_Cursor INTO @lcDB_Name,@lcSchemaName,@lcTableName,@lcConstraintName 
	      	
	END
	CLOSE curTable_Cursor 
	DEALLOCATE curTable_Cursor

	SET NOCOUNT OFF;

END




