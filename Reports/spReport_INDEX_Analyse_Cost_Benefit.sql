
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_INDEX_Analyse_Cost_Benefit]
@argDBName VARCHAR(128), @argTable_Name VARCHAR(128) = NULL
AS 
BEGIN 

	DECLARE @lcMsg VARCHAR(100)

	IF @argDBName IS NULL BEGIN
		SET @lcMsg = 'Database Name should not be empty'
		RAISERROR(@lcMsg, 16, 1)
		RETURN
	END

	DECLARE @lcSQL NVARCHAR(MAX), @lcTable_name_cond VARCHAR(500)
	 
	SELECT @lcTable_name_cond = ''
	IF @argTable_Name IS NOT NULL
		SELECT @lcTable_name_cond = ' AND object_name(s.object_id) LIKE ''' + @argTable_Name + ''''

	SELECT @lcSQL = 'USE ' + @argDBName + '; ' + 
			'SELECT object_name(s.object_id) AS [Table_Name],
					i.name AS [Index_Name],
					(S.user_seeks + S.user_scans + S.user_lookups) - (S.user_updates + 1) AS [Benefit-Cost],
					CONVERT(DECIMAL(5, 2),  ((S.user_seeks + S.user_scans + S.user_lookups) / (S.user_seeks + S.user_scans + S.user_lookups + S.user_updates + 1.0)) * 100) AS [Benefit-Cost(%)],
					S.user_seeks + S.user_scans + S.user_lookups AS [user reads],
					S.user_updates AS [user writes],
					S.user_seeks, S.user_scans, S.user_lookups,
					S.system_seeks + S.system_scans + S.system_lookups AS [system reads] ,
					S.system_updates AS [system writes], 
					P.row_count, P.used_page_count AS Total_Used_Page_Count, CONVERT(DECIMAL(15,2), P.used_page_count/128.00) AS Total_used_MB 
			FROM sys.dm_db_index_usage_stats s WITH (NOLOCK)
				JOIN sys.indexes i WITH (NOLOCK) on i.object_id = s.object_id and i.index_id = s.index_id 
				JOIN sys.dm_db_partition_stats P  WITH (NOLOCK) ON P.object_id = S.object_id and P.index_id = S.index_id 
			WHERE objectproperty(s.object_id, ''IsUserTable'') = 1
					AND S.database_id = db_id() ' + @lcTable_name_cond + 
			' ORDER BY [Benefit-Cost] DESC ;'


	EXEC (@lcSQL)
	--PRINT (@lcSQL)

END

 
