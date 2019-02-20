/* 
    Default alerts 
    Change @lcOperatorName 
*/

USE [msdb]
GO
/* Login failed Alert could be used in production servers only */
DECLARE @lcAlertName SYSNAME=N'Login failed Alert', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @message_id=18456, @enabled=1, @delay_between_responses=60, @include_event_description_in=1
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email 
GO

DECLARE @lcAlertName SYSNAME=N'017 - Insufficient Resources', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=17, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'018 - Nonfatal Internal Error', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=18, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email 
GO

DECLARE @lcAlertName SYSNAME=N'019 - Fatal Error in Resource', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=19, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'020 - Fatal Error in Current Process', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=20, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'021 - Fatal Error in Database Processes', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=21, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'022 - Fatal Error Table Integrity Suspect', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=22, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'023 - Fatal Error Database Integrity Suspect', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=23, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'024 - Fatal Error Hardware Error', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=24, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'025 - Fatal Error', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @severity=25, @enabled=1, @include_event_description_in=1, @delay_between_responses=60
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'823 - Read/Write Failure', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @message_id = 823, @severity = 0, @enabled = 1, @include_event_description_in = 1, @delay_between_responses = 30
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'824 - Page Error', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @message_id = 824, @severity = 0, @enabled = 1, @include_event_description_in = 1, @delay_between_responses = 30
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email
GO

DECLARE @lcAlertName SYSNAME=N'825 - Read-Retry Required', @lcOperatorName SYSNAME = 'DB Admins'
EXEC msdb.dbo.sp_add_alert @name=@lcAlertName, @message_id = 825, @severity = 0, @enabled = 1, @include_event_description_in = 1, @delay_between_responses = 30
EXEC msdb.dbo.sp_add_notification @alert_name=@lcAlertName, @operator_name=@lcOperatorName, @notification_method=1 --Email

GO
