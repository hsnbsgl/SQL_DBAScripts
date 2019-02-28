 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[fnSQLServerDataDir]()
RETURNS NVARCHAR(4000)
AS
BEGIN 

	DECLARE @rc INT,@dir NVARCHAR(4000);

	EXEC @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultData', @dir OUTPUT, 'no_output' ;

	IF (@dir IS NULL)
	BEGIN
		EXEC @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\Setup',N'SQLDataRoot', @dir OUTPUT, 'no_output';
		SELECT @dir = @dir + N'\Data';
	END 

	RETURN @dir ;

END

