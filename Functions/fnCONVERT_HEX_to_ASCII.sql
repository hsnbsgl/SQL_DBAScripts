SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[fnCONVERT_HEX_to_ASCII] (@argHEX_Input VARCHAR(256))
RETURNS VARCHAR(500) AS  
BEGIN 

DECLARE @lcASCII_Output VARCHAR(500), @lcLength SMALLINT, @lcPos SMALLINT
DECLARE @lcChar CHAR(1), @lcFirst TINYINT, @lcSecond TINYINT

SELECT @lcASCII_Output = ''
SELECT @lcPos = 1
SELECT @lcLength = LEN(@argHEX_Input)
WHILE @lcPos<=@lcLength
BEGIN
	SELECT @lcChar = UPPER(SUBSTRING(@argHEX_Input, @lcPos, 1))
	IF (@lcChar >= '0') AND (@lcChar <= '9') 
		SELECT @lcFirst = (ASCII(@lcChar) - 48) * 16
	ELSE
		IF (@lcChar >= 'A') AND (@lcChar <= 'F') 
			SELECT @lcFirst = (ASCII(@lcChar) - 55) * 16

	SELECT @lcChar = UPPER(SUBSTRING(@argHEX_Input, @lcPos + 1, 1))
	IF (@lcChar >= '0') AND (@lcChar <= '9') 
		SELECT @lcSecond = ASCII(@lcChar) - 48
	ELSE
		IF (@lcChar >= 'A') AND (@lcChar <= 'F') 
			SELECT @lcSecond = ASCII(@lcChar) - 55

	SELECT @lcChar = CHAR(@lcFirst + @lcSecond)

	SELECT @lcASCII_Output = @lcASCII_Output + @lcChar

	SELECT @lcPos = @lcPos + 2
END

RETURN @lcASCII_Output

END
