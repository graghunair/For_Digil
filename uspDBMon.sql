SET NOCOUNT ON
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_Config_Details]
GO
CREATE TABLE [dbo].[tblDBMon_Config_Details](
					[Config_Parameter] [varchar](100) NOT NULL,
					[Config_Parameter_Value] [varchar](400) NOT NULL,
					[Updated_By] [nvarchar](256) NOT NULL,
					[Date_Updated] [datetime] NOT NULL) 
GO
		
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [PK_tblDBMon_Config_Details_Config_Parameter] PRIMARY KEY ([Config_Parameter])
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [DF_tblDBMon_Config_Details_Updated_By] DEFAULT (suser_sname()) FOR [Updated_By]
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [DF_tblDBMon_Config_Details_Date_Updated] DEFAULT (getdate()) FOR [Date_Updated]
GO

INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value]) VALUES ('Purge_tblDBMon_SQL_Server_Threshold', '10')
GO

DROP PROCEDURE IF EXISTS [dbo].[uspDBMon]
GO
CREATE PROCEDURE [dbo].[uspDBMon]
AS
    /*
        Author		:    Digil Kunnummal
        Date		:    23rd August 2020
        Purpose		:    This Stored Procedure is used by the DBMon tool
        Version		:    1.0
        License:
        This script is provided "AS IS" with no warranties, and confers no rights.
                    EXEC [dbo].[uspDBMon]
					GO
					SELECT * FROM [dbo].[tblDBMon_SQL_Server]
					GO
    
        Modification History
        ----------------------
        Aug     23rd, 2020    :    v1.0    :    Digil Kunnummal    :    Inception
    */

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF

--Variable declarations
	DECLARE @varPort								VARCHAR(48)
	DECLARE @varIP									VARCHAR(48)
	DECLARE @varDomain								VARCHAR(256)
	DECLARE @varUserDBCnt							SMALLINT
	DECLARE @varCPU									INT
	DECLARE @varPhysical_Memory_KB					BIGINT
	DECLARE @varCommitted_Target_KB					BIGINT
	DECLARE @varSQLServer_Start_Time				DATETIME
	DECLARE @varSQL_Memory_Model					NVARCHAR(120)
	DECLARE @varServerServices						XML
	DECLARE @varPurge_tblDBMon_SQL_Server_Threshold TINYINT

SELECT	@varPurge_tblDBMon_SQL_Server_Threshold = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Purge_tblDBMon_SQL_Server_Threshold'

EXEC master..xp_regread		N'HKEY_LOCAL_MACHINE',
							N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\',
							@value_name = 'Domain',
							@value = @varDomain OUTPUT
									
SELECT	TOP 1 @varPort = [local_tcp_port],
		@varIP = [local_net_address]
FROM	[sys].[dm_exec_connections] 
WHERE	[local_tcp_port] IS NOT NULL
AND		[session_id] IS NOT NULL;

SELECT	@varCPU = [cpu_count], 
		@varPhysical_Memory_KB = [physical_memory_kb],
		@varCommitted_Target_KB = [committed_target_kb],
		@varSQLServer_Start_Time = [sqlserver_start_time],
		@varSQL_Memory_Model = [sql_memory_model_desc]
FROM	[sys].[dm_os_sys_info]

SET		@varServerServices = 
		(SELECT	[servicename] AS [Service_Name], 
				[service_account] AS [Service_Account],
				[startup_type_desc] AS [Startup_Type],	
				[status_desc] AS [Status],
				[instant_file_initialization_enabled] AS [Instant_File_Initialization]
		FROM	[sys].[dm_server_services] [Server_Services]
		WHERE	[servicename] LIKE '%SQL Server%'
		FOR XML AUTO, ELEMENTS)

INSERT INTO [dbo].[tblDBMon_SQL_Server](
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
		[AOAG_Health],
		[AOAG_Details],
		[CPU],
		[Physical_Memory_KB],
		[Committed_Target_KB],
		[SQL_Memory_Model],
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
		[Script_Version])
SELECT
		GETDATE() AS [Date_Captured],
		CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(128)) AS [Server_Name],
		@varDomain AS [Domain],
		@varIP AS [IP_Address],
		@varPort AS [Port],
		CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS NVARCHAR(128)) AS [Server_Host],
		CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128)) AS [Edition],
		CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128)) AS [Product_Version],
		CAST(SERVERPROPERTY('IsClustered') AS BIT) AS [Is_Clustered],
		CAST(SERVERPROPERTY('IsHadrEnabled') AS BIT) AS [Is_Hadr_Enabled],
		NULL AS [AOAG_Health],
		NULL AS [AOAG_Details],
		@varCPU AS [CPU], 
		@varPhysical_Memory_KB AS [Physical_Memory_KB],
		@varCommitted_Target_KB AS [Committed_Target_KB],
		@varSQL_Memory_Model AS [SQL_Memory_Model],
		@varServerServices AS [Server_Services],
		@varSQLServer_Start_Time AS [SQLServer_Start_Time],
		NULL AS [Full_Backup_Timestamp],
		NULL AS [TLog_Backup_Timestamp],
		NULL AS [Blocking],
		NULL AS [CPU_Utilization],
		NULL AS [Page_Life_Expectancy],
		NULL AS [TLog_Utlization],
		NULL AS [Errors_And_Warnings],
		NULL AS [File_System_Space],
		NULL AS [Script_Version]

DELETE  TOP (10000)
FROM	[dbo].[tblDBMon_SQL_Server]
WHERE	[Date_Captured] < GETDATE() - @varPurge_tblDBMon_SQL_Server_Threshold

UPDATE	[dbo].[tblDBMon_SP_Version]
SET		[Last_Executed] = GETDATE()
WHERE	[SP_Name] = OBJECT_NAME(@@PROCID)
GO

IF EXISTS (SELECT TOP 1 1 FROM [dbo].[tblDBMon_SP_Version] WHERE [SP_Name] = 'uspDBMon')
	BEGIN
		UPDATE	[dbo].[tblDBMon_SP_Version]
		SET		[SP_Version] = '1.0',
				[Last_Executed] = NULL,
				[Date_Modified] = GETDATE()
		WHERE	[SP_Name] = 'uspDBMon'
	END
ELSE
	BEGIN
		INSERT INTO [dbo].[tblDBMon_SP_Version] ([SP_Name], [SP_Version], [Last_Executed], [Date_Modified])
		VALUES ('uspDBMon', '1.0', NULL, GETDATE())
	END
GO

EXEC sp_addextendedproperty 
	@name = 'Version', @value = '1.0', 
	@level0type = 'SCHEMA', @level0name = 'dbo', 
	@level1type = 'PROCEDURE', @level1name = 'uspDBMon'
GO

EXEC [dbo].[uspDBMon]
GO
SELECT * FROM [dbo].[tblDBMon_SQL_Server]
GO
