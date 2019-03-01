
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/*
	Converts HHMMSS format to HH:MM:SS
*/
CREATE OR ALTER FUNCTION [dbo].[fnFormat_Job_Time] (@argTime int)  
RETURNS VARCHAR(8) AS  
BEGIN 
 
DECLARE @lcResult  VARCHAR(8), @lcTime VARCHAR(8)

SELECT @lcTime = CONVERT(VARCHAR(8), @argTime)

SELECT @lcResult = REPLACE(SPACE(6-LEN(@lcTime)) + @lcTime, ' ', 0)
SELECT @lcResult = SUBSTRING(@lcResult, 1, 2) + ':' + SUBSTRING(@lcResult, 3, 2) + ':' + SUBSTRING(@lcResult, 5, 2)

RETURN @lcResult

END

