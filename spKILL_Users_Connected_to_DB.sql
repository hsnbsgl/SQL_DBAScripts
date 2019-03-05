
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spKILL_Users_Connected_to_DB] 
@argDB_Name VARCHAR(128)
AS
BEGIN
	--Kill Users (Restore Needs Exclusive Access to the Database)
	DECLARE @lcSPID SMALLINT, @lcHostName VARCHAR(100), @lcCMD VARCHAR(100)

	DECLARE Cursor_Processes CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT DISTINCT L.request_session_id, S.[host_name] 
	FROM sys.dm_tran_locks L WITH (NOLOCK)
		LEFT JOIN sys.databases D WITH (NOLOCK) ON L.resource_database_id = D.database_id
		LEFT JOIN sys.dm_exec_sessions S WITH (NOLOCK) ON L.request_session_id = S.session_id
	WHERE D.[name]=@argDB_Name AND L.request_session_id <> @@SPID --don't kill yourself

	OPEN Cursor_Processes
	FETCH NEXT FROM Cursor_Processes INTO @lcSPID, @lcHostName

	WHILE @@FETCH_STATUS=0
	BEGIN
		IF EXISTS (SELECT session_id FROM sys.dm_exec_sessions S WITH (NOLOCK) WHERE session_id=@lcSPID AND [host_name] = @lcHostName) BEGIN
			SELECT @lcCMD = 'KILL ' + CONVERT(VARCHAR(5), @lcSPID)
			EXEC(@lcCMD)
			--WAITFOR DELAY '00:00:01'
		END

		FETCH NEXT FROM Cursor_Processes INTO @lcSPID, @lcHostName
	END

	CLOSE Cursor_Processes
	DEALLOCATE Cursor_Processes
END
