 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE OR ALTER PROCEDURE [dbo].[spCheck_QueryStore_Info]
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcDBName VARCHAR(200),@lcSQL NVARCHAR(MAX)

	DROP TABLE IF EXISTS #tmpQueryStore;

	CREATE TABLE #tmpQueryStore (DBName VARCHAR(128),current_storage_size_mb BIGINT,max_storage_size_mb BIGINT,readonly_reason BIGINT);

	DECLARE curDatabases CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT  Name
	FROM sys.Databases WITH (NOLOCK)	
	
	OPEN curDatabases 
	FETCH NEXT FROM curDatabases INTO @lcDBName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		/*
		Textual description of the actual operation mode of Query Store.
		OFF (0)
		READ_ONLY (1)
		READ_WRITE (2)
		ERROR (3)		
		*/

		/*
			readonly_reason	
			
			1 – database is in read-only mode

			2 – database is in single-user mode

			4 – database is in emergency mode

			8 – database is secondary replica (applies to Always On and Azure SQL Database geo-replication). This value can be effectively observed only on readable secondary replicas

			65536 – the Query Store has reached the size limit set by the MAX_STORAGE_SIZE_MB option.

			131072 - The number of different statements in Query Store has reached the internal memory limit. Consider removing queries that you do not need or upgrading to a higher service tier to enable transferring Query Store to read-write mode.
			Only applies to SQL Database.

			262144 – Size of in-memory items waiting to be persisted on disk has reached the internal memory limit. Query Store will be in read-only mode temporarily until the in-memory items are persisted on disk. 
			Only applies to SQL Database.

			524288 – Database has reached disk size limit. Query Store is part of user database, so if there is no more available space for a database, that means that Query Store cannot grow further anymore.
			Only applies to SQL Database.
		 */


		SET @lcSQL ='USE' + QUOTENAME(@lcDBName) +';
					SELECT DB_NAME(),current_storage_size_mb,max_storage_size_mb,readonly_reason FROM sys.database_query_store_options WHERE actual_state IN (1,3) AND desired_state=2 AND readonly_reason<>8 ;'					
		
		INSERT INTO	#tmpQueryStore(DBName,current_storage_size_mb,max_storage_size_mb,readonly_reason)
		EXEC sp_executesql @lcSQL;
		

		FETCH NEXT FROM curDatabases INTO @lcDBName
	END
	CLOSE curDatabases 
	DEALLOCATE curDatabases 


	IF EXISTS (SELECT * FROM #tmpQueryStore)	
	BEGIN   
		DECLARE @lcEmail VARCHAR(50)='x@x', @xml NVARCHAR(MAX), @xml2 NVARCHAR(MAX);
		DECLARE @lcBody NVARCHAR(MAX), @lcSubject NVARCHAR(MAX);
		
		SET @lcSubject = @@SERVERNAME + ' - Query Store Warning ' ;	

		SET @xml = CAST(( SELECT DBName AS 'td','',current_storage_size_mb AS 'td' ,'',max_storage_size_mb AS 'td','',readonly_reason AS 'td'
		FROM  #tmpQueryStore
		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))


		
		SET @lcBody ='<HTML><BODY><H3>Query Store Uyarı </H3>
		<P>	Readonly Reasons<br>				
			1 – database is in read-only mode<br>	
			2 – database is in single-user mode<br>	
			4 – database is in emergency mode<br>	
			8 – database is secondary replica (applies to Always On and Azure SQL Database geo-replication). This value can be effectively observed only on readable secondary replicas<br>	
			65536 – the Query Store has reached the size limit set by the MAX_STORAGE_SIZE_MB option.<br>	
			131072 - The number of different statements in Query Store has reached the internal memory limit. Consider removing queries that you do not need or upgrading to a higher service tier to enable transferring Query Store to read-write mode.
			Only applies to SQL Database.<br>	
			262144 – Size of in-memory items waiting to be persisted on disk has reached the internal memory limit. Query Store will be in read-only mode temporarily until the in-memory items are persisted on disk. 
			Only applies to SQL Database.<br>	
			524288 – Database has reached disk size limit. Query Store is part of user database, so if there is no more available space for a database, that means that Query Store cannot grow further anymore.
			Only applies to SQL Database.<br>	
		</P>				
		<TABLE BORDER=1 BORDERCOLOR=#A6A6D9 STYLE="font-family:Tahoma; font-size:10pt">
		<TR BGCOLOR=#A6A6D9>
		 <th> DB Name </th><th> Current Storage Size(MB) </th><th> Max Storage Size(MB) </th><th> Read Only Reason </th></tr>'    

		SET @lcBody = @lcBody + @xml +'</TABLE></BODY></HTML>'
		
		--PRINT @body
		EXEC msdb.dbo.sp_send_dbmail
		@body = @lcBody,
		@body_format ='HTML',
		@recipients = @lcEmail,
		@subject =@lcSubject;		 

	END
	
	SET NOCOUNT OFF;
END



