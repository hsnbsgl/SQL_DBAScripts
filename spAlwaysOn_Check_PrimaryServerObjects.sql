SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Description: Checks Secondary Server for missing logins,server roles,server role memberships,linked servers, jobs etc.
	
	Execute this script on the secondary server ssms (Login failed for user 'NT AUTHORITY\ANONYMOUS LOGON'.) 	  
*/
CREATE OR ALTER PROCEDURE [dbo].[spAlwaysOn_Check_PrimaryServerObjects] 
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcSQL NVARCHAR(MAX), @lcPrimaryReplica VARCHAR(128)=NULL;
	
	IF (@lcPrimaryReplica IS NULL) BEGIN;
		/*Get Primary replica name*/		
		SELECT   TOP 1 @lcPrimaryReplica=primary_replica
		FROM sys.dm_hadr_availability_group_states hags
			INNER JOIN sys.availability_groups ag ON ag.group_id = hags.group_id
                
		IF (@lcPrimaryReplica IS NULL) BEGIN;
			PRINT  N'Primary Replica missing';
			RETURN;
		END;
	END;

	IF (@lcPrimaryReplica=@@SERVERNAME) BEGIN;
		PRINT 'Execute this script on the secondary server'
		RETURN;
	END;
	
	DROP TABLE IF EXISTS #Result;

	CREATE TABLE #Result (ObjectName VARCHAR(500),Description VARCHAR(MAX) );
	
	DECLARE @primaryLogins TABLE (
		[name]	VARCHAR(128) NOT NULL,
		[Hash]	VARBINARY(8000)
	);
	
	SET @lcSQL=N'
	SELECT sp.[name],
		   HASHBYTES(''SHA2_512'', CONVERT(VARCHAR(MAX),ISNULL(sp.[name],''''))+ CONVERT(VARCHAR(MAX),ISNULL(sp.default_database_name,''''))+  CONVERT(VARCHAR(MAX),ISNULL(sp.default_language_name,''''))+  CONVERT(VARCHAR(MAX),ISNULL(l.is_policy_checked,0)) +  CONVERT(VARCHAR(MAX),ISNULL(l.is_expiration_checked,0)))
	FROM ['+@lcPrimaryReplica+'].master.sys.server_principals AS sp
	LEFT JOIN ['+@lcPrimaryReplica+'].master.sys.sql_logins AS l ON sp.[sid]=l.[sid]
	WHERE sp.[type] IN (''U'', ''G'', ''S'') AND
		  sp.[name] NOT LIKE ''NT Service\%'' AND
		  sp.[name] NOT IN (''NT AUTHORITY\SYSTEM'')';

	INSERT INTO @primaryLogins
	EXECUTE sp_executesql @lcSQL;
	
	---Server roles
	DECLARE @primaryRoles TABLE (
		[name]	VARCHAR(128) NOT NULL
	);

	SET @lcSQL=N'
	SELECT sr.[name]
	FROM ['+@lcPrimaryReplica+'].master.sys.server_principals AS sr
	WHERE sr.is_fixed_role=0 AND
		  sr.[type]=''R''';

	INSERT INTO @primaryRoles
	EXECUTE sp_executesql @lcSQL;

	--- Role üyelikleri 
	DECLARE @primaryMembers TABLE (
		[role_name]		VARCHAR(128) NOT NULL,
		[member_name]	VARCHAR(128) NOT NULL
	);

	SET @lcSQL=N'
	SELECT r.name, m.name
	FROM ['+@lcPrimaryReplica+N'].master.sys.server_principals AS r
	INNER JOIN ['+@lcPrimaryReplica+N'].master.sys.server_role_members AS rm ON r.principal_id=rm.role_principal_id
	INNER JOIN ['+@lcPrimaryReplica+N'].master.sys.server_principals AS m ON rm.member_principal_id=m.principal_id';

	INSERT INTO @primaryMembers
	EXECUTE sp_executesql @lcSQL;
	
	---Jobs
	DECLARE @primaryJobs TABLE (
		[name] VARCHAR(MAX) NOT NULL,
		[stepname] VARCHAR(MAX) NOT NULL,
		[schedulename] VARCHAR(MAX) NOT NULL,
		[Hash] VARBINARY(8000)
	);

	---Linked Servers
	DECLARE @primaryLinkedServers TABLE (
			SRV_NAME	sysname NULL,					--Name of the linked server.
			SRV_PROVIDERNAME	nvarchar(128) NULL,		--Friendly name of the OLE DB provider managing access to the specified linked server.
			SRV_PRODUCT	nvarchar(128) NULL,				--Product name of the linked server.
			SRV_DATASOURCE	nvarchar(4000) NULL,		--OLE DB data source property corresponding to the specified linked server.
			SRV_PROVIDERSTRING	nvarchar(4000) NULL,	--OLE DB provider string property corresponding to the linked server.
			SRV_LOCATION	nvarchar(4000) NULL,		--OLE DB location property corresponding to the specified linked server.
			SRV_CAT	sysname NULL
	);

	DECLARE @LinkedServers TABLE (
			SRV_NAME	sysname NULL,					--Name of the linked server.
			SRV_PROVIDERNAME	nvarchar(128) NULL,		--Friendly name of the OLE DB provider managing access to the specified linked server.
			SRV_PRODUCT	nvarchar(128) NULL,				--Product name of the linked server.
			SRV_DATASOURCE	nvarchar(4000) NULL,		--OLE DB data source property corresponding to the specified linked server.
			SRV_PROVIDERSTRING	nvarchar(4000) NULL,	--OLE DB provider string property corresponding to the linked server.
			SRV_LOCATION	nvarchar(4000) NULL,		--OLE DB location property corresponding to the specified linked server.
			SRV_CAT	sysname NULL
	);
 
	SET @lcSQL=N'
	SELECT job.name,Step.step_name,S.name,
	HASHBYTES(''SHA2_512'',
			CONVERT(VARCHAR(MAX),ISNULL(job.name,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(job.description,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.step_name,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.subsystem,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(step.database_name,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.command,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.flags,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.additional_parameters,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(step.cmdexec_success_code,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.on_success_action,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.on_success_step_id,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.on_fail_action,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(Step.retry_interval,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(S.name,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.enabled,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_type,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_interval,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_subday_type,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_subday_interval,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_relative_interval,'''')) +
			CONVERT(VARCHAR(MAX),ISNULL(s.freq_recurrence_factor,'''')) )
	FROM ['+@lcPrimaryReplica+N'].msdb.dbo.sysjobs Job
	LEFT JOIN ['+@lcPrimaryReplica+N'].msdb.dbo.sysjobsteps Step ON Step.job_id=job.job_id
	LEFT JOIN ['+@lcPrimaryReplica+N'].msdb.dbo.sysjobschedules Schedule ON Schedule.job_id = Job.job_id
	LEFT JOIN ['+@lcPrimaryReplica+N'].msdb.dbo.sysschedules S ON s.schedule_id=Schedule.schedule_id
	';

	INSERT INTO @primaryJobs
	EXECUTE sp_executesql @lcSQL;

	--- Login doesn't exist on the secondary 
	INSERT INTO #Result
	SELECT  p.[name] ,'Login Missing'
	FROM @primaryLogins AS p
	WHERE p.name NOT IN (SELECT name FROM master.sys.server_principals WHERE [type] IN ('U', 'G', 'S'));

	INSERT INTO #Result
	SELECT  p.[name] ,'Login Definiton Different'
	FROM @primaryLogins AS p
		INNER JOIN master.sys.server_principals sp ON sp.name=p.name
		LEFT JOIN  master.sys.sql_logins AS l ON sp.[sid]=l.[sid]
	WHERE 
	HASHBYTES('SHA2_512', CONVERT(VARCHAR(MAX),ISNULL(sp.[name],''))+ CONVERT(VARCHAR(MAX),ISNULL(sp.default_database_name,''))+  CONVERT(VARCHAR(MAX),ISNULL(sp.default_language_name,''))+  CONVERT(VARCHAR(MAX),ISNULL(l.is_policy_checked,0)) +  CONVERT(VARCHAR(MAX),ISNULL(l.is_expiration_checked,0)))
	!=p.[Hash]  	  
	  
	--- Roles that don't exist on the secondary
	INSERT INTO #Result
	SELECT r.[name] ,'Server Role Missing'
	FROM @primaryRoles AS r
	WHERE name NOT IN (
		SELECT name
		FROM sys.server_principals
		WHERE is_fixed_role=0 AND
			  [type]='R');

	-------------------------------------------------------------------------------

	---Role memberships:
	INSERT INTO #Result 
	SELECT r.[name]  + ' --> ' +  m.[name],'Server Role Membership Extra User'
	FROM sys.server_role_members AS rm
	INNER JOIN sys.server_principals AS r ON r.principal_id=rm.role_principal_id
	INNER JOIN sys.server_principals AS m ON m.principal_id=rm.member_principal_id
	LEFT JOIN @primaryMembers AS pm ON pm.member_name=m.name AND pm.[role_name]=r.name
	WHERE pm.role_name IS NULL;

	--- Add server role memberships:
	INSERT INTO #Result 
	SELECT pr.[name] + ' --> ' +  pl.[name],'Server Role Membership Missing User'
	FROM @primaryMembers AS pm
	INNER JOIN @primaryLogins AS pl ON pm.member_name=pl.name
	INNER JOIN @primaryRoles AS pr ON pm.role_name=pr.name
	LEFT JOIN sys.server_principals AS r ON pm.role_name=r.name AND r.[type]='R'
	LEFT JOIN sys.server_principals AS m ON pm.member_name=m.name
	LEFT JOIN sys.server_role_members AS rm ON r.principal_id=rm.role_principal_id AND m.principal_id=rm.member_principal_id
	WHERE rm.role_principal_id IS NULL;
	-------------------------------------------------

	--- Jobs
	INSERT INTO #Result 
	SELECT DISTINCT p.[name] ,'Job Missing'
	FROM @primaryJobs AS p
	WHERE p.name NOT IN (SELECT name FROM msdb.dbo.sysjobs);

	INSERT INTO #Result 
	SELECT DISTINCT p.[name] + ' --> ' + p.stepname ,'Job Step Missing'
	FROM @primaryJobs AS p
		INNER JOIN msdb.dbo.sysjobs job ON job.name=p.name
		LEFT JOIN msdb.dbo.sysjobsteps Step ON Step.job_id=job.job_id AND Step.step_name=p.stepname
	WHERE job.name=p.name AND step.step_name IS NULL
	
	INSERT INTO #Result 
	SELECT DISTINCT p.[name] ,'Job Definition Different'
	FROM @primaryJobs AS p
		INNER JOIN msdb.dbo.sysjobs job ON job.name=p.name
		LEFT JOIN msdb.dbo.sysjobsteps Step ON Step.job_id=job.job_id
		LEFT JOIN msdb.dbo.sysjobschedules Schedule ON Schedule.job_id = Job.job_id
		LEFT JOIN msdb.dbo.sysschedules S ON s.schedule_id=Schedule.schedule_id
	WHERE job.name=p.name AND step.step_name=p.stepname AND s.name=p.schedulename AND
		HASHBYTES('SHA2_512',
		CONVERT(VARCHAR(MAX),ISNULL(job.name,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(job.description,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.step_name,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.subsystem,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(step.database_name,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.command,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.flags,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.additional_parameters,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(step.cmdexec_success_code,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.on_success_action,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.on_success_step_id,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.on_fail_action,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(Step.retry_interval,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(S.name,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.enabled,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_type,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_interval,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_subday_type,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_subday_interval,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_relative_interval,'')) +
		CONVERT(VARCHAR(MAX),ISNULL(s.freq_recurrence_factor,'')) )!=p.[Hash]  	  
	-------------------------------------------------
	
	--- Linked Servers
	SET @lcSQL=N'EXEC '+@lcPrimaryReplica+N'.master.sys.sp_linkedservers';

	INSERT INTO @primaryLinkedServers
	EXECUTE sp_executesql @lcSQL;

	INSERT INTO @LinkedServers
	EXECUTE sys.sp_linkedservers;

	INSERT INTO #Result 
	SELECT r.SRV_NAME ,'Linked Server Missing'
	FROM @primaryLinkedServers AS r
	WHERE r.SRV_NAME NOT IN (SELECT SRV_NAME FROM @LinkedServers);
	-------------------------------------------------		

	SELECT * FROM #Result;

	DROP TABLE #Result;
	
END
