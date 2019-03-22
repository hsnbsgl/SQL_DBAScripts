 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 
	Usage 1:			
			DECLARE @lcHTML VARCHAR(MAX)
			EXEC dbo.spConvertTableData_to_HTML 'DBName', 'TableNAme', 'WHERE Criteria', '#FFA6D9', '#FFFFFF', '<B>Header</B>', '<B>Footer</B>', @lcHTML OUTPUT
			SELECT @lcHTML

	Usage 2:			
			DECLARE @lcHTML VARCHAR(MAX)
			EXEC dbo.spConvertTableData_to_HTML @argDatabaseName = 'tempdb', @argTableName = '#tmpResult', @argWHERE_Condition = '', 
									@argColumnHeader_BackColor = '', @argColumnHeader_ForeColor = '', 
									@argHeader_HTML = '', @argFooter_HTML = '', 
									@argOutputData_HTML = @lcHTML OUTPUT;
*/
CREATE OR ALTER PROCEDURE [dbo].[spConvertTableData_to_HTML]
	@argDatabaseName VARCHAR(128), @argTableName VARCHAR(128), @argWHERE_Condition VARCHAR(MAX), 
	@argColumnHeader_BackColor VARCHAR(20), @argColumnHeader_ForeColor VARCHAR(20), 
	@argHeader_HTML VARCHAR(MAX), @argFooter_HTML VARCHAR(MAX), @argOutputData_HTML VARCHAR(MAX) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @lcSQL NVARCHAR(1000);

	IF ISNULL(@argColumnHeader_BackColor, '') = ''
		SET @argColumnHeader_BackColor = '#A6A6D9'

	IF ISNULL(@argColumnHeader_ForeColor, '') = ''
		SET @argColumnHeader_ForeColor = '#000000'

	-- Table Columns
	CREATE TABLE #TableColumns (ColumnName VARCHAR(128))
	SET @lcSQL = 'SELECT C.name FROM [' + @argDatabaseName + '].sys.columns C WHERE C.object_id=object_id(''' + @argDatabaseName + '..' + @argTableName + ''')'
	
	INSERT INTO #TableColumns
	EXEC (@lcSQL)

	-- Column Header
	DECLARE @lcColumnHeaderHTML NVARCHAR(MAX), @lcColumns NVARCHAR(MAX), @lcColumnDataSQL NVARCHAR(MAX), @lcColumnDataHTML NVARCHAR(MAX)
	SET @lcColumnHeaderHTML = (SELECT '<th> ' + C.ColumnName + ' </th> '
								FROM #TableColumns C 
								FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)')
	--Column Value
	SET @lcColumns = STUFF((SELECT ', '''', ISNULL(CONVERT(VARCHAR(MAX), [' + C.ColumnName + ']), '''') AS ''td'' '
							FROM #TableColumns C 
							FOR XML PATH(''), TYPE).value('.','VARCHAR(MAX)'), 1, 5, '')
	SET @lcColumnDataSQL = 'SET @lcColumnDataHTML = CAST((SELECT ' + @lcColumns + '
															FROM ' + IIF(@argDatabaseName='tempdb', '', @argDatabaseName + '..') + @argTableName + '
															' + ISNULL(@argWHERE_Condition, '') + '
															FOR XML PATH(''tr''), TYPE, ELEMENTS) AS NVARCHAR(MAX))'

	--PRINT @lcColumnDataSQL
	EXEC sp_executesql @lcColumnDataSQL, N'@lcColumnDataHTML NVARCHAR(MAX) OUTPUT', @lcColumnDataHTML OUTPUT


	SET @argOutputData_HTML ='<HTML><BODY>	' + ISNULL(@argHeader_HTML, '') + '
							<TABLE border=1 bordercolor=' + @argColumnHeader_BackColor + ' style="font-family:Tahoma; font-size:10pt">
							<TR style="background-color:' + @argColumnHeader_BackColor + '; color:' + @argColumnHeader_ForeColor + '">' + @lcColumnHeaderHTML + '</tr>'


	SET @argOutputData_HTML = @argOutputData_HTML + ISNULL(@lcColumnDataHTML,'') + '</TABLE> ' + 
							  ISNULL(@argFooter_HTML, '') +	'</BODY></HTML>'
END
