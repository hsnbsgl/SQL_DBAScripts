
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[spReport_Database_Sizes]
AS 
BEGIN

DECLARE @lcSQL NVARCHAR(MAX), @lcDB_Name VARCHAR(128), @lcDB_Id INT;
DECLARE @lcTemp_Pages TABLE([DB_Id] INT, Reserved_Pages BIGINT, Used_Pages BIGINT, Pages BIGINT);
DECLARE @lcTemp_File_Size TABLE([DB_Id] INT, Data_File_Size BIGINT, Log_File_size BIGINT);
DECLARE @lcTemp_Log_Usage TABLE([DB_Name] VARCHAR(128), Log_Size_MB DECIMAL(15, 2), Log_Space_Use_Perc DECIMAL(10, 7), [Status] SMALLINT);

INSERT INTO @lcTemp_Log_Usage
EXEC ('dbcc sqlperf(logspace) WITH NO_INFOMSGS')

DECLARE DBs_Cursor CURSOR FOR
SELECT name, database_id FROM sys.databases ORDER BY name

OPEN DBs_Cursor
FETCH NEXT FROM DBs_Cursor INTO @lcDB_Name, @lcDB_Id
WHILE @@FETCH_STATUS=0
BEGIN
	--Pages
	SELECT @lcSQL = 'SELECT ' + CONVERT(VARCHAR(10), @lcDB_Id) + ', SUM(a.total_pages), SUM(a.used_pages), ' +
						   'SUM(CASE WHEN it.internal_type IN (202,204) THEN 0 ' +
										'WHEN a.type != 1 THEN a.used_pages ' +
										'WHEN p.index_id < 2 THEN a.data_pages ' +
										'ELSE 0 END) ' +
					'FROM [' + @lcDB_Name + '].sys.partitions p ' +
						'JOIN [' + @lcDB_Name + '].sys.allocation_units a on p.partition_id = a.container_id ' +
						'LEFT JOIN [' + @lcDB_Name + '].sys.internal_tables it on p.object_id = it.object_id '
	INSERT INTO @lcTemp_Pages([DB_Id], Reserved_Pages, Used_Pages, Pages)
	EXEC (@lcSQL)
	--PRINT (@lcSQL)

	--File Sizes
	SELECT @lcSQL = 'SELECT ' + CONVERT(VARCHAR(10), @lcDB_Id) + 
						', SUM(CONVERT(BIGINT, CASE WHEN type = 0 THEN size ELSE 0 END)), ' +
						'SUM(CONVERT(BIGINT, CASE WHEN type = 1 THEN size ELSE 0 END))' +
					'FROM sys.master_files WHERE database_id = ' + CONVERT(VARCHAR(10), @lcDB_Id)

	INSERT INTO @lcTemp_File_Size([DB_Id], Data_File_Size, Log_File_size)
	EXEC (@lcSQL)
	--PRINT (@lcSQL)

	FETCH NEXT FROM DBs_Cursor INTO @lcDB_Name, @lcDB_Id
END
CLOSE DBs_Cursor
DEALLOCATE DBs_Cursor

SELECT D.name, 
		CONVERT(DECIMAL(15,2), (F.Data_File_Size * 8192)/1048576.0) AS [Data_File_Size(MB)], 
		CONVERT(DECIMAL(15,2), (F.Log_File_size * 8192)/1048576.0) AS [Log_File_size(MB)], 
		CONVERT(DECIMAL(15,2), LU.Log_Space_Use_Perc) AS [Log_Space_Used(%)], 
		CONVERT(DECIMAL(15,2), (CASE WHEN F.Data_File_Size >= P.Reserved_Pages 
									THEN (F.Data_File_Size - P.Reserved_Pages) * 8192 / 1048576.0  
									ELSE 0 END)) AS [Unallocated_Space(MB)],
		CONVERT(DECIMAL(15,2), (P.Reserved_Pages * 8192) / 1048576.0) AS [Reserved(MB)], 
		CONVERT(DECIMAL(15,2), (P.Pages * 8192) / 1048576.0) AS [Data_Size(MB)],
		CONVERT(DECIMAL(15,2), ((P.Used_Pages - P.Pages) * 8192) / 1048576.0) AS [Index_Size(MB)],
		CONVERT(DECIMAL(15,2), ((P.Reserved_Pages - P.Used_Pages) * 8192) / 1048576.0) AS [Unused(MB)]
FROM sys.databases D 
		JOIN @lcTemp_File_Size F ON D.database_id = F.[DB_Id]
		JOIN @lcTemp_Pages P ON D.database_id = P.[DB_Id]
		JOIN @lcTemp_Log_Usage LU ON D.name = LU.[DB_Name]
ORDER BY D.name;

END
