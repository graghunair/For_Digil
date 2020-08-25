SET NOCOUNT ON
GO

USE [dba_local]
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon_GetHandshakeInfo]
GO
CREATE PROCEDURE [dbo].[uspDBMon_GetHandshakeInfo]
AS
    /*
        Author		:    Digil Kunnummal
        Date		:    23rd August 2020
        Purpose		:    This Stored Procedure is used by the DBMon tool
        Version		:    1.0
        License:
        This script is provided "AS IS" with no warranties, and confers no rights.
                    EXEC [dbo].[uspDBMon_GetHandshakeInfo]
					GO
					SELECT * FROM [dbo].[tblDBMon_SQL_Server]
					GO
    
        Modification History
        ----------------------
        Aug     23rd, 2020    :    v1.0    :    Digil Kunnummal    :    Inception
    */

SET NOCOUNT ON

SELECT		TOP 1
			[Date_Captured],
			[Server_Name],
			[Domain],
			[IP_Address],
			[Port],
			[Server_Host],
			[Edition],
			[Product_Version],
			[Is_Clustered],
			[Is_Hadr_Enabled],
			[User_Databases],
			[AOAG_Health],
			[AOAG_Details],
			[CPU],
			[Physical_Memory_KB],
			[Committed_Target_KB],
			[SQL_Memory_Model],
			[Instant_File_Initialization_Enabled],
			[Server_Services],
			[SQLServer_Start_Time],	
			[Full_Backup_Timestamp],
			[TLog_Backup_Timestamp],
			[Blocking],
			[CPU_Utilization],
			[Page_Life_Expectancy],
			[TLog_Utlization],
			[Errors_And_Warnings],
			[File_System_Space],
			[Script_Version]
FROM		[dbo].[tblDBMon_SQL_Server]
ORDER BY	[Date_Captured] DESC

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon_GetHandshakeInfo')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0 GHI',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE()
		WHERE	[SP_Name] = 'uspDBMon_GetHandshakeInfo'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified])
		VALUES ('uspDBMon_GetHandshakeInfo', '1.0 GHI', NULL, GETDATE())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0 GHI', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon_GetHandshakeInfo'
GO

EXEC [dbo].[uspDBMon_GetHandshakeInfo]
GO
SELECT * FROM [dbo].[tblDBMon_SP_Version]
GO
