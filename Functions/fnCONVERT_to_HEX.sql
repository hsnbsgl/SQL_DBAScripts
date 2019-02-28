
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION [dbo].[fnCONVERT_to_HEX] (@argInput VARCHAR(256))  
RETURNS VARCHAR(500) AS  
BEGIN 

DECLARE @lcHex_Output VARCHAR(500), @lcLength SMALLINT, @lcPos SMALLINT, @lcAscii TINYINT
DECLARE @lcHexString VARCHAR(16), @lcFirstint TINYINT, @lcSecondint TINYINT

SELECT @lcHexString = '0123456789ABCDEF'

SELECT @lcHex_Output = ''
SELECT @lcPos = 1
SELECT @lcLength = LEN(@argInput)
WHILE @lcPos<=@lcLength
BEGIN
	SELECT @lcAscii = ASCII(SUBSTRING(@argInput, @lcPos, 1))
	SELECT @lcFirstint = FLOOR(@lcAscii/16)
	SELECT @lcSecondint = @lcAscii - (@lcFirstint*16)

	SELECT @lcHex_Output = @lcHex_Output + SUBSTRING(@lcHexString, @lcFirstint+1, 1) +
						SUBSTRING(@lcHexString, @lcSecondint+1, 1)
	SELECT @lcPos = @lcPos + 1
END

RETURN @lcHex_Output

END



