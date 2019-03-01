
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	Description:	Scale Up Database Files Add Max 100 MB or %10 
*/
CREATE OR ALTER PROCEDURE [dbo].[spAuto_Growth_SetDBSizes] 
AS BEGIN

SET NOCOUNT ON;

	DECLARE @lcObjects_Cursor CURSOR, @lcSQL NVARCHAR(4000), @lcObject_Id INT, @lcDB_Name VARCHAR(50),@lcTotalSizeMB INT,@lcLogicalFileName VARCHAR(500),@lcAddition FLOAT

	DECLARE @DBFreeSpaces AS TABLE 
	(
	DBName  VARCHAR(500),                                                                                                                          
	DBIsReadOnly INT,
	FileId INT,
	LogicalFileName  VARCHAR(500),                                                                                                                   
	FileNameWithURL  VARCHAR(500),                                                                                                                                                                                                                                                   
	FileIsReadOnly BIT,
	IsPrimaryFile BIT,
	IsLogFile   BIT,
	GrowthType VARCHAR(50),   
	Growth    INT,             
	MaxSize_MB   FLOAT ,        
	TotalSize_MB FLOAT ,
	TotalSize_Primary_MB FLOAT,       
	FreeSize_Treshold	FLOAT ,  
	Addition	FLOAT ,                
	SpaceUsed_MB	FLOAT ,              
	FreeSpace_MB	FLOAT ,           
	NextGrowthSize_MB	FLOAT  
	)

	DECLARE Database_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT name FROM sys.databases
	WHERE name NOT IN ('master', 'model','msdb', 'Northwind', 'pubs', 'tempdb', 'mssqlweb')

	OPEN Database_Cursor
	FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SELECT @lcSQL = 'USE '+ @lcDB_Name + ';
					SELECT DB_NAME() AS DBName ,
						 (CASE DATABASEPROPERTYEX(DB_NAME(),''Updateability'') WHEN ''READ_ONLY'' THEN 1 ELSE 0 END) AS DBIsReadOnly,
						 f.file_id,
						 f.name AS LogicalFileName,
						 f.physical_name AS FileNameWithURL,
						 FILEPROPERTY(f.name,'' IsReadOnly'' ) AS FileIsReadOnly,
						 FILEPROPERTY(f.name, ''IsPrimaryFile'') AS IsPrimaryFile,
						 FILEPROPERTY(f.name, ''IsLogFile'') AS IsLogFile,
						 (CASE WHEN f.growth<128 THEN ''Percent'' ELSE ''MB'' END) AS GrowthType,
						 (CASE WHEN f.growth<128 THEN growth ELSE ROUND(CAST(f.growth*8 AS FLOAT)/1024,2) END) AS Growth,
						 (CASE f.max_size WHEN -1 THEN -1 ELSE ROUND(CAST(f.max_size/1024 AS FLOAT)*8,2) END) AS MaxSize_MB,
						 ROUND(CAST(f.size*8 as float)/1024,2) AS TotalSize_MB,
						 NULL,NULL,NULL,
						 ROUND(CAST(FILEPROPERTY(f.name, ''SpaceUsed'')*8 as float)/1024,2) AS SpaceUsed_MB	,
						 ROUND(CAST((f.size - FILEPROPERTY(f.name, ''SpaceUsed''))*8 AS FLOAT)/1024,2) as FreeSpace_MB,
						 ROUND((CASE WHEN f.growth<128 THEN (growth/100.)*CAST(f.size*8 AS FLOAT)/1024
									ELSE ROUND(CAST(f.growth*8 AS FLOAT)/1024,2)END),2) AS NextGrowthSize_MB
					FROM sys.database_files f '
			
		INSERT INTO @DBFreeSpaces		
		EXEC( @lcSQL)

   		FETCH NEXT FROM Database_Cursor INTO @lcDB_Name
	END
	CLOSE Database_Cursor 
	DEALLOCATE Database_Cursor
	
	UPDATE x
	SET 
		x.TotalSize_Primary_MB =DB2.TotalSize_MB 
	FROM @DBFreeSpaces AS x
	INNER JOIN @DBFreeSpaces DB2 ON DB2.DBName=x.DBName AND DB2.IsPrimaryFile=1  
	WHERE x.IsLogFile=1 
 
	DELETE FROM @DBFreeSpaces WHERE FreeSpace_MB>=100  OR ISNULL(FileIsReadOnly,0)<>0 OR ISNULL(DBIsReadOnly,0)=1  
 
	UPDATE @DBFreeSpaces SET FreeSize_Treshold=CASE WHEN TotalSize_MB/10 >100 THEN 100 ELSE TotalSize_MB/10 END WHERE ISNULL(IsLogFile,0)<>1
	UPDATE @DBFreeSpaces SET FreeSize_Treshold=CASE WHEN TotalSize_Primary_MB/10 >100 THEN 100 ELSE TotalSize_Primary_MB/10 END WHERE IsLogFile=1		
	UPDATE @DBFreeSpaces SET Addition=FreeSize_Treshold-FreeSpace_MB WHERE FreeSize_Treshold>FreeSpace_MB 	
	DELETE FROM @DBFreeSpaces WHERE ISNULL(Addition,0)<=2 OR ISNULL(Addition,0)>100 
	
	UPDATE @DBFreeSpaces SET TotalSize_MB=TotalSize_MB + Addition

	DECLARE Database_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 	
	SELECT DBName,ROUND(TotalSize_MB,0),LogicalFileName,Addition FROM @DBFreeSpaces 

	OPEN Database_Cursor
	FETCH NEXT FROM Database_Cursor INTO @lcDB_Name,@lcTotalSizeMB,@lcLogicalFileName,@lcAddition
	WHILE @@FETCH_STATUS = 0
	BEGIN
	 
			SELECT  @lcSQL = 'ALTER DATABASE ' + @lcDB_Name + ' MODIFY FILE ( NAME= N''' + @lcLogicalFileName +''', SIZE = '+CAST(@lcTotalSizeMB AS VARCHAR(50))+' MB )';
				
			--EXEC( @lcSQL)
						
			PRINT @lcSQL;	 
		
		FETCH NEXT FROM Database_Cursor INTO @lcDB_Name,@lcTotalSizeMB,@lcLogicalFileName,@lcAddition
	      	
	END
	CLOSE Database_Cursor 
	DEALLOCATE Database_Cursor

SET NOCOUNT OFF;

END

