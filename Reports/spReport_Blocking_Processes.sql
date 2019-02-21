SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[spReport_Blocking_Processes] 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	SET NOCOUNT ON;

	SELECT R.session_id AS [Blocked SPID], R.blocking_session_id AS [Blocking SPID], 
			S.host_name AS [Blocked Host], S2.host_name AS [Blocking Host], 
			dbo.fnGetJobNameFromApplicationName(S.program_name) AS [Blocked App], dbo.fnGetJobNameFromApplicationName(S2.program_name) AS [Blocking App], 
			LTRIM(RTRIM(ST.text)) AS 'Blocked SQL', LTRIM(RTRIM(ST2.text)) AS 'Blocking SQL', R.wait_type, R.wait_resource, 
			(SELECT SUBSTRING(text, (R.statement_start_offset/2) + 1,
									((CASE WHEN R.statement_end_offset = -1 THEN DATALENGTH(SQ1.text) 
										   ELSE R.statement_end_offset END - R.statement_start_offset) / 2) + 1)
				FROM sys.dm_exec_sql_text(R.sql_handle) SQ1) AS 'Blocked Statement',
			(SELECT SUBSTRING(text, (R2.statement_start_offset/2) + 1,
									((CASE WHEN R2.statement_end_offset = -1 THEN DATALENGTH(SQ2.text) 
										   ELSE R2.statement_end_offset END - R2.statement_start_offset) / 2) + 1)
				FROM sys.dm_exec_sql_text(R2.sql_handle) SQ2) AS 'Blocking Statement'
		FROM sys.dm_exec_requests R WITH (NOLOCK)
				JOIN sys.dm_exec_sessions S WITH (NOLOCK) ON R.session_id = S.session_id
				CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) ST
				LEFT JOIN sys.dm_exec_requests R2 WITH (NOLOCK) ON R.blocking_session_id = R2.session_id
				LEFT JOIN sys.dm_exec_sessions S2 WITH (NOLOCK) ON R.blocking_session_id = S2.session_id
				LEFT JOIN sys.dm_exec_connections C2 WITH (NOLOCK) ON R.blocking_session_id = C2.session_id
				OUTER APPLY sys.dm_exec_sql_text(C2.most_recent_sql_handle) ST2
	WHERE R.blocking_session_id <> 0;

	SET NOCOUNT OFF;
END
