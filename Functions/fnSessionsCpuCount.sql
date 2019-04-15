
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE OR ALTER FUNCTION [dbo].[fnSessionsCpuCount]
(	
)
RETURNS TABLE 
AS
RETURN 
(
	
  SELECT DISTINCT ost.session_id, COUNT(DISTINCT ost.scheduler_id) AS CPU_InUse
  FROM sys.dm_os_tasks ost GROUP BY ost.session_id
	
)
