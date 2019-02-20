
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER FUNCTION [dbo].[fnGetJobNameFromApplicationName] (@argApplicationName VARCHAR(300))
RETURNS VARCHAR(300)
AS
BEGIN
	DECLARE @lcJobId_Pos INT, @lcJobId UNIQUEIDENTIFIER, @lcApplicationName VARCHAR(300)

	SET @lcJobId_Pos = CHARINDEX('(Job 0x', @argApplicationName) + 7
	IF @lcJobId_Pos > 7 BEGIN
		SET @lcJobId = CAST(
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 06, 2) + SUBSTRING(@argApplicationName, @lcJobId_Pos + 04, 2) + 
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 02, 2) + SUBSTRING(@argApplicationName, @lcJobId_Pos + 00, 2) + '-' +
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 10, 2) + SUBSTRING(@argApplicationName, @lcJobId_Pos + 08, 2) + '-' +
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 14, 2) + SUBSTRING(@argApplicationName, @lcJobId_Pos + 12, 2) + '-' +
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 16, 4) + '-' +
							SUBSTRING(@argApplicationName, @lcJobId_Pos + 20, 12) AS uniqueidentifier)
		SELECT @lcApplicationName = name FROM msdb.dbo.sysjobs WHERE job_id = @lcJobId
		IF @lcApplicationName IS NULL --Job not found
			SET @lcApplicationName = @argApplicationName
		ELSE
			SET @lcApplicationName = STUFF(@argApplicationName, @lcJobId_Pos-2, 34, @lcApplicationName)
	END
	ELSE
		SET @lcApplicationName = @argApplicationName

	RETURN @lcApplicationName;
END
