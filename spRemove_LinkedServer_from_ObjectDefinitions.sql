
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*Warning: Do no exec this script on prod - only for dev and test */

CREATE OR ALTER PROCEDURE [dbo].[spRemove_LinkedServer_from_ObjectDefinitions] 
	@argDatabaseName VARCHAR(128), @argLinkedServerName VARCHAR(128)
AS
BEGIN
	SET NOCOUNT ON;

	IF @@SERVERNAME NOT LIKE 'DEV%' AND @@SERVERNAME NOT LIKE 'TEST%' BEGIN
		RAISERROR('This sp only works on DEV and TEST environments.', 16,1) WITH SETERROR;
		RETURN
	END

	DECLARE @lcSQL NVARCHAR(MAX), @lcLinkedServerName VARCHAR(128);
	DECLARE @lcDefinition NVARCHAR(MAX), @lcObjectName VARCHAR(128), @lcObjectType VARCHAR(128);

	CREATE TABLE #ObjectDefinitions (ObjectName SYSNAME, TypeDesc NVARCHAR(60), ObjectDefinition NVARCHAR(MAX));

	SET @lcLinkedServerName = '%' + @argLinkedServerName + '.%'
	SET @lcSQL=N'USE [' + @argDatabaseName + '];
				INSERT INTO #ObjectDefinitions
				SELECT O.name, O.type_desc, M.definition
				FROM sys.sql_modules M
					JOIN sys.objects O ON M.object_id = O.object_id
				WHERE definition LIKE @lcLinkedServerName AND O.name NOT LIKE ''OLD%'' 
				'
	EXEC sp_executesql @lcSQL, N'@lcLinkedServerName VARCHAR(128)', @lcLinkedServerName;

	DECLARE curObjectDefinitions CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT ObjectName, TypeDesc, ObjectDefinition FROM #ObjectDefinitions
	ORDER BY ObjectName ASC

	OPEN curObjectDefinitions
	FETCH NEXT FROM curObjectDefinitions INTO @lcObjectName, @lcObjectType, @lcDefinition
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @lcDefinition = REPLACE(@lcDefinition, @argLinkedServerName + '.', '')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE VIEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE  VIEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE   VIEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE    VIEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE     VIEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE ViEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE  ViEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE   ViEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE    ViEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE     ViEW', 'ALTER VIEW')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE PROCEDURE', 'ALTER PROCEDURE')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE PROC', 'ALTER PROCEDURE')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE FUNCTION', 'ALTER FUNCTION')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE  FUNCTION', 'ALTER FUNCTION')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE   FUNCTION', 'ALTER FUNCTION')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE FUNCTiON', 'ALTER FUNCTION')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE  FUNCTiON', 'ALTER FUNCTION')
		SET @lcDefinition = REPLACE(@lcDefinition, 'CREATE   FUNCTiON', 'ALTER FUNCTION')

		--SET @lcDefinition = 'USE [' + @argDatabaseName + '];' +  NCHAR(13) + NCHAR(10) + @lcDefinition
		SET @lcSQL = QUOTENAME(@argDatabaseName) + '.sys.sp_executesql @lcDefinition '
		PRINT 'Object Name: ' +  @argDatabaseName + '..' + @lcObjectName + ' (' + @lcObjectType + ') ' +  ' LinkedServer Name: ' + @argLinkedServerName + ' has been removed ...'
		--PRINT @lcDefinition
		EXEC sp_executesql @lcSQL, N'@lcDefinition NVARCHAR(MAX)', @lcDefinition

		FETCH NEXT FROM curObjectDefinitions INTO @lcObjectName, @lcObjectType, @lcDefinition
	END
	CLOSE curObjectDefinitions
	DEALLOCATE curObjectDefinitions

END
