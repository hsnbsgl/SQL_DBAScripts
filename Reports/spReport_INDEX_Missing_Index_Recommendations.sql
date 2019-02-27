SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[spReport_INDEX_Missing_Index_Recommendations]
@argDBName VARCHAR(128), @argObject_Name VARCHAR(128), @argTop_N SMALLINT
AS
BEGIN

IF @argTop_N IS NULL
	SELECT @argTop_N = 500

SELECT TOP (@argTop_N)  
CONVERT(DECIMAL(20,2), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS Total_Impact, 
	db_name(mid.database_id) AS DB_Name, 
	object_name(mid.object_id, mid.database_id) AS Object_Name,
	mid.equality_columns, mid.inequality_columns, mid.included_columns, 
	CONVERT(DECIMAL(20, 2), migs.avg_total_user_cost) AS avg_total_user_cost, 
	CONVERT(DECIMAL(20, 2), migs.avg_user_impact) AS avg_user_impact, 
	migs.user_seeks, migs.user_scans, migs.unique_compiles, 
	migs.last_user_seek, migs.last_user_scan, migs.system_seeks, migs.system_scans, migs.last_system_seek,
	migs.last_system_scan, migs.avg_total_system_cost, migs.avg_system_impact,
	migs.group_handle, mid.statement
FROM sys.dm_db_missing_index_group_stats  AS migs
	INNER JOIN sys.dm_db_missing_index_groups AS mig ON (migs.group_handle = mig.index_group_handle)
	INNER JOIN sys.dm_db_missing_index_details AS mid ON (mig.index_handle = mid.index_handle)
WHERE (mid.database_id = DB_ID(@argDBName) OR @argDBName IS NULL) AND
	((object_name(mid.object_id, mid.database_id) LIKE '%' + @argObject_Name + '%') OR (@argObject_Name IS NULL))
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC

END

