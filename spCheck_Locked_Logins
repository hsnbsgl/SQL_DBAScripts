SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*
 Description: Check for locked or expired sql logins ,  unlock and send mail to DBA team
 Usage	  :		Execute the sp every minute by a job
				EXEC spCheck_Locked_Logins @argSendMail=1,@argUnlock=1

*/
CREATE OR ALTER PROCEDURE [dbo].[spCheck_Locked_Logins]
	@argSendMail BIT=0, @argUnlock BIT=0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @lcLoginName VARCHAR(200), @lcIsLocked BIT, @lcIsExpired BIT, @lcLockOutTime DATETIME, @lcSendMail BIT, @lcTimeInfo VARCHAR(50);
	DECLARE @lcExpiration_Checked BIT,@lcMinutesPassed INT;
	DECLARE @lcRecipients VARCHAR(200), @lcSQL VARCHAR(500), @lcSubject VARCHAR(250); 


	DECLARE curLogin_Cursor CURSOR LOCAL FAST_FORWARD READ_ONLY FOR 
	SELECT  Name, CONVERT(BIT, LOGINPROPERTY(Name, N'IsLocked')) AS IsLocked, CONVERT(BIT, LOGINPROPERTY(Name, N'IsExpired')) AS IsExpired,
			CONVERT(DATETIME, LOGINPROPERTY(name, 'LockoutTime')) AS LockOutTime, is_expiration_checked
	FROM sys.sql_logins WITH (NOLOCK)
	WHERE ( LOGINPROPERTY(Name,N'IsLocked')=1 OR LOGINPROPERTY(Name,N'IsExpired')=1 ) AND is_disabled=0
	
	OPEN curLogin_Cursor 
	FETCH NEXT FROM curLogin_Cursor INTO @lcLoginName, @lcIsLocked, @lcIsExpired, @lcLockOutTime, @lcExpiration_Checked 

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @lcSendMail = 0, @lcTimeInfo='', @lcMinutesPassed=0
		   
		--How long it has been locked
		IF (@lcLockOutTime IS NOT NULL) AND (@lcLockOutTime >= '1950-01-01') BEGIN --Default value is 1900-01-01 
			SET @lcMinutesPassed = DATEDIFF(minute, @lcLockOutTime, getdate())
			IF @lcMinutesPassed <= 5 BEGIN --less than 5 minutes
				SELECT @lcSendMail = 1, @lcTimeInfo = '(' + CONVERT(VARCHAR(10), @lcMinutesPassed) + ' Minutes. LockOutTime=' + CONVERT(VARCHAR(100), @lcLockOutTime, 121) + ')'
			END
			ELSE IF @lcMinutesPassed <= 60 BEGIN		-- greater than 5 minutes, less than 1 hour
				IF (@lcMinutesPassed % 5) < 1 BEGIN	
					SELECT @lcSendMail = 1, @lcTimeInfo = '(' + CONVERT(VARCHAR(10), @lcMinutesPassed) + ' Minutes. LockOutTime=' + CONVERT(VARCHAR(100), @lcLockOutTime, 121) + ')'
				END
			END
			ELSE BEGIN 
				IF (@lcMinutesPassed % 60) < 1 BEGIN --Send mail every hour
					SELECT @lcSendMail = 1, @lcTimeInfo = '(' + CONVERT(VARCHAR(10), @lcMinutesPassed / 60) + ' Hours. LockOutTime=' + CONVERT(VARCHAR(100), @lcLockOutTime, 121) + ')'
				END
			END
		END
		ELSE BEGIN 
			SET @lcSendMail = 1      
		END


		IF @argSendMail=1 AND @lcIsLocked=1 AND @lcSendMail = 1
		BEGIN
		
			SET @lcRecipients='xxx@xxx.com'  
			SET @lcSubject = @@SERVERNAME + ' - ' + 'Login is locked out' + ' (' + @lcLoginName + ') ' + @lcTimeInfo
				
			EXEC msdb.dbo.sp_send_dbmail @recipients = @lcRecipients, @subject = @lcSubject, @body_format = 'HTML';
		END		
	
		IF @argSendMail=1 AND @lcIsExpired=1
		BEGIN
		
			SET @lcRecipients='xxx@xxx.com'  
			SET @lcSubject = @@SERVERNAME + ' - ' + 'Login is expired' + ' (' + @lcLoginName + ')'
				
			EXEC msdb.dbo.sp_send_dbmail @recipients = @lcRecipients, @subject = @lcSubject, @body_format = 'HTML';
		END		

		--Unlock login				
		IF @lcIsLocked=1 AND (@argUnlock=1 OR @lcMinutesPassed>=5)
		BEGIN
			SET @lcSQL='ALTER LOGIN ' + @lcLoginName + ' WITH CHECK_POLICY=OFF '
			
			--PRINT @lcSQL
			EXEC( @lcSQL)
			
			SET @lcSQL='ALTER LOGIN ' + @lcLoginName + ' WITH CHECK_POLICY=ON ' + CASE WHEN @lcExpiration_Checked = 1 THEN ', CHECK_EXPIRATION=ON' ELSE '' END
			
			--PRINT @lcSQL
			EXEC( @lcSQL)
		END
		
		FETCH NEXT FROM curLogin_Cursor INTO @lcLoginName, @lcIsLocked, @lcIsExpired, @lcLockOutTime, @lcExpiration_Checked 
	END
	CLOSE curLogin_Cursor 
	DEALLOCATE curLogin_Cursor 

	SET NOCOUNT OFF;
END
