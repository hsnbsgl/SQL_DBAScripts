USE [ADMIN]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Description	:	Drop user from all databases 
	Usage		:	Drop login and exec sp

	IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'xxx')
		DROP LOGIN [xxx];
	exec spDropUser_From_AllDatabases @argUserName='xxx';	

*/
CREATE OR ALTER PROCEDURE [dbo].[spDropUser_From_AllDatabases]
	@argUserName VARCHAR(100)
AS 
BEGIN
	SET NOCOUNT ON;

	DECLARE @lcSQL NVARCHAR(MAX), @lcDatabaseName VARCHAR(128);
	DECLARE @tblScripts TABLE(Script VARCHAR(MAX));
	 
	-- Check for Databases exclude readonly and secondaries
	DECLARE curDatabases CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT D.name FROM sys.databases D WITH (NOLOCK)
		LEFT JOIN sys.availability_databases_cluster AD WITH (NOLOCK) ON Ad.database_name=D.name
		LEFT JOIN sys.dm_hadr_availability_replica_states RS WITH (NOLOCK) ON AD.group_id = RS.group_id		
	WHERE D.is_read_only=0 AND ISNULL(RS.is_local, 1) = 1 AND  ISNULL(RS.[role],1)=1
	ORDER BY name

	OPEN curDatabases
	FETCH NEXT FROM curDatabases INTO @lcDatabaseName
	WHILE @@FETCH_STATUS=0
	BEGIN
		PRINT 'Checking Database : ' + @lcDatabaseName

		DELETE FROM @tblScripts

		-----------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Roles owned by user		
		SET @lcSQL = 'USE [' + @lcDatabaseName + '];
					SELECT ''ALTER AUTHORIZATION ON ROLE::['' + R.name + ''] TO [dbo];''
					FROM sys.database_principals R
						JOIN sys.database_principals O ON R.owning_principal_id = O.principal_id
					WHERE R.type=''R'' AND O.name = @argUserName;' 

		INSERT INTO @tblScripts
		EXEC sp_executesql @lcSQL, N'@argUserName VARCHAR(50)', @argUserName;

		-----------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Schemas owned by user		
		SET @lcSQL = 'USE [' + @lcDatabaseName + '];
					SELECT ''ALTER AUTHORIZATION ON SCHEMA::['' + S.name + ''] TO [dbo];''
					FROM sys.schemas S 
						JOIN sys.database_principals O ON S.principal_id = O.principal_id
					WHERE O.name = @argUserName;' 

		INSERT INTO @tblScripts
		EXEC sp_executesql @lcSQL, N'@argUserName VARCHAR(50)', @argUserName;

		-----------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Drop Schema 
		SET @lcSQL = 'USE [' + @lcDatabaseName + '];
					SELECT ''DROP SCHEMA ['' + name + '']; '' 
					FROM sys.schemas 
					WHERE name = @argUserName;' 

		INSERT INTO @tblScripts
		EXEC sp_executesql @lcSQL, N'@argUserName VARCHAR(50)', @argUserName;

		-----------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Drop User
		SET @lcSQL = 'USE [' + @lcDatabaseName + '];
					SELECT ''DROP USER ['' + name + '']; '' 
					FROM sys.database_principals 
					WHERE name = @argUserName;' 

		INSERT INTO @tblScripts
		EXEC sp_executesql @lcSQL, N'@argUserName VARCHAR(50)', @argUserName;


		DECLARE @lcScript VARCHAR(1000)
		
		DECLARE curScripts CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
		SELECT 'USE [' + @lcDatabaseName + ']; ' + Script FROM @tblScripts
		
		OPEN curScripts
		FETCH NEXT FROM curScripts INTO @lcScript
		WHILE @@FETCH_STATUS=0
		BEGIN
			PRINT CHAR(9) + 'Executing Script : ' + @lcScript
			EXEC (@lcScript)
		
			FETCH NEXT FROM curScripts INTO @lcScript
		END
		CLOSE curScripts
		DEALLOCATE curScripts
		
		FETCH NEXT FROM curDatabases INTO @lcDatabaseName
	END
	CLOSE curDatabases
	DEALLOCATE curDatabases
END

