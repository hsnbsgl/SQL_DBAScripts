
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	Create logins with SID 
	Create Server Roles and assign members
	Could be used to synchronize logins on secondary server or dev,test servers
*/
CREATE OR ALTER PROCEDURE [dbo].[spCreateScript_Logins_ServerRoles] AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 'CREATE LOGIN [' + P.name + '] WITH PASSWORD=0x' + 
		CONVERT(VARCHAR(500), cast(convert(sysname, LoginProperty(p.name, 'PasswordHash')) AS varbinary(256)), 2) + ' HASHED, SID=0x' + 
		CONVERT(VARCHAR(100), P.sid, 2) +
		', DEFAULT_DATABASE=[' + P.default_database_name + ']' + 
		', DEFAULT_LANGUAGE=[' + P.default_language_name + ']' +
		', CHECK_POLICY=' + CASE WHEN ISNULL(L.is_policy_checked, 0)=1 THEN 'ON' ELSE 'OFF' END + 
		', CHECK_EXPIRATION=' + CASE WHEN ISNULL(L.is_expiration_checked, 0)=1 THEN 'ON' ELSE 'OFF' END
	FROM sys.server_principals p
		LEFT JOIN sys.sql_logins L ON P.sid = L.sid
	WHERE P.name NOT IN ('sa') AND P.type = 'S' AND P.name NOT LIKE '##%##' --SQL_LOGIN
	ORDER BY P.name;

	SELECT 'ALTER LOGIN [' + p.name + '] DISABLE'
	FROM sys.server_principals p
	WHERE p.name NOT IN ('sa') AND p.type = 'S' AND P.name NOT LIKE '##%##' AND p.is_disabled=1 --SQL_LOGIN
	ORDER BY P.name;

	SELECT 'CREATE LOGIN [' + P.name + '] FROM WINDOWS WITH DEFAULT_DATABASE=[' + P.default_database_name + '], DEFAULT_LANGUAGE=[' + P.default_language_name + ']'
	FROM sys.server_principals P
	WHERE P.name NOT IN ('BUILTIN\Administrators', 'NT AUTHORITY\SYSTEM', 'NT AUTHORITY\NETWORK SERVICE')
			AND P.type = 'U' --WINDOWS_LOGIN
	ORDER BY P.name;

	SELECT 'ALTER LOGIN [' + p.name + '] DISABLE'
	FROM sys.server_principals p
	WHERE p.type = 'U' AND p.is_disabled=1; --WIN_LOGIN

	SELECT 'CREATE SERVER ROLE ' + QUOTENAME(Name)  FROM sys.server_principals WHERE type='R' AND principal_id>10;

	SELECT 'ALTER SERVER ROLE ' +  QUOTENAME(role.name)  + ' ADD MEMBER ' + QUOTENAME(member.name)
	FROM sys.server_role_members
	INNER JOIN sys.server_principals AS role ON sys.server_role_members.role_principal_id = role.principal_id AND role.type='R' AND role.principal_id>10
	INNER JOIN sys.server_principals AS member ON sys.server_role_members.member_principal_id = member.principal_id;
	
END
