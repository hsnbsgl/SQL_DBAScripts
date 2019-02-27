SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE OR ALTER PROCEDURE [dbo].[spReport_Databases_FreeSpace] 
AS
BEGIN

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
	MaxSize_MB    DECIMAL(22,2) ,        
	TotalSize_MB  DECIMAL(22,2) ,                
	SpaceUsed_MB    DECIMAL(22,2) ,              
	FreeSpace_MB       DECIMAL(22,2) , 
	FreeSpace_Percent DECIMAL(22,2),          
	NextGrowthSize_MB DECIMAL(22,2)        
	)

	INSERT INTO @DBFreeSpaces
	EXECUTE master.sys.sp_MSforeachdb 'USE [?];
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
					 ROUND(CAST(FILEPROPERTY(f.name, ''SpaceUsed'')*8 as float)/1024,2) AS SpaceUsed_MB	,
					 ROUND(CAST((f.size - FILEPROPERTY(f.name, ''SpaceUsed''))*8 AS FLOAT)/1024,2) as FreeSpace_MB,
					 NULL AS FreeSpace_Percent,					 
					 ROUND((CASE WHEN f.growth<128 THEN (growth/100.)*CAST(f.size*8 AS FLOAT)/1024
								ELSE ROUND(CAST(f.growth*8 AS FLOAT)/1024,2)END),2) AS NextGrowthSize_MB
				FROM sys.database_files f '

	SELECT 	DBName,DBIsReadOnly,FileId,LogicalFileName,FileNameWithURL,FileIsReadOnly,IsPrimaryFile ,
			IsLogFile,GrowthType,Growth,MaxSize_MB,TotalSize_MB,SpaceUsed_MB,FreeSpace_MB,
			FreeSpace_Percent=CONVERT(DECIMAL(22,2),FreeSpace_MB/TotalSize_MB*100),NextGrowthSize_MB 	
	FROM @DBFreeSpaces ORDER BY DBName 

 
END
