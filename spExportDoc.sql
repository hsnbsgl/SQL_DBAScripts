SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
   Description:	Exports varbinary data to destination file			
   Usage:
		EXEC dbo.spExportDoc @argDocSQL = 'SELECT Document FROM Documents WHERE Id=1 ', @argFolderName = 'C:\ExportedDocuments\', @argFileName = 'File1.docx'
	https://social.msdn.microsoft.com/Forums/sqlserver/en-US/29f30130-3a64-4b91-86b3-5fa09dbc4220/dumping-varbinarymax-column-values-to-files-on-harddisk-using-a-sql-script?forum=transactsql
*/
CREATE OR ALTER PROCEDURE [dbo].[spExportDoc] 
	@argDocSQL NVARCHAR(2000), @argFolderName VARCHAR(1000), @argFileName VARCHAR(200) 
AS
BEGIN
	DECLARE @lcFormatFile VARCHAR(100), @lcCommand NVARCHAR(4000), @lcFilePath VARCHAR(2000);

	IF RIGHT(@argFolderName, 1) <> '\'
		SET @argFolderName = @argFolderName + '\';

	SELECT @lcFormatFile = @argFolderName + 'Doc_Export.fmt';
	SELECT @lcFilePath = @argFolderName + @argFileName;

	 -- First write a format file which allows us to dump the image column without column 
	SELECT @lcCommand = 'echo 9.0 >> '+ @lcFormatFile;
	EXEC xp_cmdshell @lcCommand;
	SELECT @lcCommand = 'echo 1 >> '+ @lcFormatFile;
	EXEC xp_cmdshell @lcCommand;
	SELECT @lcCommand = 'echo 1       SQLBINARY     0       0       ""   1     blob_data              "" >> '+ @lcFormatFile;
	EXEC xp_cmdshell @lcCommand;

	-- Export document to file
	SELECT @lcCommand = 'bcp "' + @argDocSQL + '" queryout "'+ @lcFilePath + '" -f "' + @lcFormatFile + '" -T -S' + @@SERVERNAME;
	PRINT @lcCommand;
	EXEC xp_cmdshell @lcCommand;

	-- Delete format file
	SELECT @lcCommand = 'del '+ @lcFormatFile;
	EXEC xp_cmdshell @lcCommand;
END
