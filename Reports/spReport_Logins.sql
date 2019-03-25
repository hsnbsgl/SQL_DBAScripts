SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE OR ALTER PROCEDURE [dbo].[spReport_Logins] 
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcNULL_Date DATETIME='1950-01-01'
	
	SELECT P.[name], P.type_desc, P.is_disabled, L.is_policy_checked, L.is_expiration_checked, 
			'''' + CONVERT(VARCHAR(100), P.create_date, 121) AS create_date, 
			P.default_database_name, P.default_language_name, 
			LoginProperty(P.[name], 'IsLocked') AS IsLocked,
			LoginProperty(P.[name], 'IsExpired') AS IsExpired,
			IS_SRVROLEMEMBER ( 'sysadmin', P.name) AS sysadmin, 
			LOGINPROPERTY(P.name, 'BadPasswordCount') AS BadPasswordCount,
			CASE WHEN LOGINPROPERTY(P.name, 'BadPasswordTime')<=@lcNULL_Date THEN NULL ELSE '''' + CONVERT(VARCHAR(100), LOGINPROPERTY(P.name, 'BadPasswordTime'), 121) END AS BadPasswordTime,
			CASE WHEN LOGINPROPERTY(P.name, 'LockoutTime')<=@lcNULL_Date THEN NULL ELSE '''' + CONVERT(VARCHAR(100), LOGINPROPERTY(P.name, 'LockoutTime'), 121) END AS LockoutTime
	FROM sys.server_principals P
		LEFT JOIN sys.sql_logins L ON L.principal_id = P.principal_id
	WHERE P.[type] NOT IN ('R') --Exclude roles
	ORDER BY P.[name]

END
