
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* =============================================	
	Description:	Lists Active requests 
 =============================================
*/
CREATE OR ALTER PROCEDURE [dbo].[spReport_Active_Requests] 
	@argShow_DBCC_Input_Buffer TINYINT
AS
BEGIN
	SET NOCOUNT ON;
	--SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

	DECLARE @lcsession_id SMALLINT, @lcrequest_id INT, @lcSQL VARCHAR(200);
	CREATE TABLE #Requests (session_id SMALLINT, request_id INT, [text] TEXT);
	CREATE TABLE #InputBuffer_Temp(EventType VARCHAR(30), [Parameters] INT, EventInfo VARCHAR(4000));

	IF @argShow_DBCC_Input_Buffer = 1 BEGIN
		DECLARE Requests_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
		SELECT R.session_id, R.request_id 
		FROM sys.dm_exec_requests R WITH (NOLOCK)
				JOIN sys.dm_exec_connections C WITH (NOLOCK) ON R.Connection_id = C.Connection_id

		OPEN Requests_Cursor
		FETCH NEXT FROM Requests_Cursor INTO @lcsession_id, @lcrequest_id
		WHILE @@FETCH_STATUS=0
		BEGIN
			SELECT @lcSQL = 'DBCC INPUTBUFFER(' + CONVERT(VARCHAR(10), @lcsession_id) + ',' + CONVERT(VARCHAR(10), @lcrequest_id) + ')';

			--BEGIN TRY
				INSERT INTO #InputBuffer_Temp(EventType, [Parameters], EventInfo)
				EXEC (@lcSQL);
			--END TRY
			--BEGIN CATCH
			--END CATCH
			
			INSERT INTO #Requests (session_id, request_id, [text])
			SELECT @lcsession_id, @lcrequest_id, EventInfo FROM #InputBuffer_Temp;

			TRUNCATE TABLE #InputBuffer_Temp;

			FETCH NEXT FROM Requests_Cursor INTO @lcsession_id, @lcrequest_id
		END
		CLOSE Requests_Cursor
		DEALLOCATE Requests_Cursor
		DROP TABLE #InputBuffer_Temp
	END

	SELECT S.session_id AS SPID, R.command, S.[host_name] AS Hostname, 
			dbo.fnGetJobNameFromApplicationName(S.[program_name]) as Program, DB_NAME(R.database_id) AS [Database],
			S.login_name,
			'''' + CONVERT(VARCHAR(100), R.start_time, 121) AS [Start Time], 
			CONVERT(DECIMAL(22,4), R.cpu_time / 1000.000) AS [CPU Time(s)], 
			CONVERT(DECIMAL(22,4), R.total_elapsed_time / 1000.000) AS [Duration(s)], 
			R.Status, R.scheduler_id, R.reads, R.writes, R.logical_reads, R.blocking_session_id AS [Blocking SPID],
			R.wait_resource, R.wait_type, R.wait_time AS [wait_time (ms)], 
			dbo.fnTransactionIsolationLevel_Description(R.transaction_isolation_level, R.database_id) AS transaction_isolation_level,
			TR.text AS [DBCC BUFFER],
			LTRIM(RTRIM(St.text)) AS [SQL Text],
			dbo.fnGet_SQL_Statement (st.Text, R.statement_start_offset, R.statement_end_offset) AS [SQL Statement],
			R.open_transaction_count AS [Open Tran.#], 
			R.percent_complete AS [Complete(%)], CAST(S.context_info AS VARCHAR(128)) AS context_info
	FROM sys.dm_exec_requests R WITH (NOLOCK)
			LEFT JOIN #Requests TR WITH (NOLOCK) ON R.Session_id = TR.session_id AND R.request_id = TR.request_id
			JOIN sys.dm_exec_sessions S WITH (NOLOCK) ON R.Session_id = S.session_id
			JOIN sys.dm_exec_connections C WITH (NOLOCK) ON R.Connection_id = C.Connection_id
			OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) st

	DROP TABLE #Requests;
END
