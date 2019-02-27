SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROC [dbo].[spReport_Databases_Info]
AS
BEGIN
SELECT D.database_id, D.name, P.name AS [Owner], 
	CONVERT(VARCHAR(100), D.create_date, 121) AS create_date, 
	D.compatibility_level, D.collation_name,
	user_access_desc AS user_access, is_read_only, 
	is_auto_close_on, is_auto_shrink_on, state_desc AS [state], 
	snapshot_isolation_state_desc AS snapshot_isolation_state, 
	is_read_committed_snapshot_on, recovery_model_desc AS recovery_model,
	page_verify_option_desc AS page_verify_option,
	is_auto_create_stats_on, is_auto_update_stats_on, is_auto_update_stats_async_on,
	is_trustworthy_on, is_broker_enabled, log_reuse_wait_desc AS log_reuse_wait,
	is_ansi_null_default_on, is_ansi_nulls_on, is_ansi_padding_on, is_ansi_warnings_on, is_arithabort_on, is_concat_null_yields_null_on, is_numeric_roundabort_on, is_quoted_identifier_on, is_recursive_triggers_on, is_cursor_close_on_commit_on, is_local_cursor_default, is_fulltext_enabled, is_db_chaining_on, is_parameterization_forced, is_master_key_encrypted_by_server, is_sync_with_backup, service_broker_guid, is_date_correlation_on
FROM sys.databases D
	LEFT JOIN sys.server_principals P ON D.owner_sid = P.sid
ORDER BY D.name
END
