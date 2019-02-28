
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[spReport_INDEX_Unused_Indexes]
@argDBName VARCHAR(128)
AS 
BEGIN

DECLARE @lcMsg VARCHAR(100);

IF @argDBName IS NULL BEGIN
		SET @lcMsg = 'Database Name should not be empty'
		RAISERROR(@lcMsg, 16, 1)
		RETURN
END

DECLARE   @lcSQL NVARCHAR(MAX)
 

SELECT @lcSQL = 'USE ' + @argDBName + '; ' + 
				'SELECT object_name(i.object_id) AS [Object_Name], 
					i.name AS Index_Name, 
					i.type_desc, i.is_unique, i.is_primary_key, i.is_disabled, i.is_unique_constraint,
					i.fill_factor
				FROM sys.indexes i 
					JOIN sys.objects o ON o.object_id = i.object_id
				WHERE o.type = ''U'' AND 
						i.index_id NOT IN (SELECT s.index_id 
											FROM sys.dm_db_index_usage_stats s 
 											WHERE s.object_id=i.object_id and i.index_id=s.index_id and 
											database_id = db_id())
				ORDER BY [Object_Name], Index_Name ASC'

EXEC (@lcSQL)

END
