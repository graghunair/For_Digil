SET NOCOUNT ON
GO

SET NOCOUNT ON
GO

USE [dba_local]
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
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD  CONSTRAINT [DF_tblDBMon_Config_Details_Updated_By]  DEFAULT (suser_sname()) FOR [Updated_By]
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD  CONSTRAINT [DF_tblDBMon_Config_Details_Date_Updated]  DEFAULT (getdate()) FOR [Date_Updated]
GO

INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value]) VALUES ('Purge_tblDBMon_SQL_Server_Threshold','10')
INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value]) VALUES ('Blocking_Milliseconds_Threshold','15000')
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SP_Version] 
GO
CREATE TABLE [dbo].[tblDBMon_SP_Version](
		[SP_Name]			SYSNAME,
		[SP_Version]		VARCHAR(15),
		[Last_Executed]		DATETIME,
		[Date_Modified]		DATETIME)
GO
ALTER TABLE [dbo].[tblDBMon_SP_Version] ADD CONSTRAINT [PK_tblDBMon_SP_Version] PRIMARY KEY ([SP_Name])
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SQL_Server]
GO
CREATE TABLE [dbo].[tblDBMon_SQL_Server](
--Inventory
	[Date_Captured] [datetime] NOT NULL,
	[Server_Name] [nvarchar](128) NOT NULL,
	[Domain] [varchar](50) NULL,
	[IP_Address] [varchar](50) NULL,
	[Port] [varchar](10) NULL,
	[Server_Host] [nvarchar](128) NULL,
	[Edition] [nvarchar](128) NULL,
	[Product_Version] [nvarchar](128) NULL,
	[Is_Clustered] [bit] NULL,
	[Is_Hadr_Enabled] [bit] NULL,
	[User_Databases] [smallint] NULL,
	[AOAG_Health] [bit] NULL,
	[AOAG_Details] [xml] NULL,
--H/W Specs
	[CPU] [int] NULL,
	[Physical_Memory_KB] [bigint] NULL,
	[Committed_Target_KB] [bigint] NULL,
--Configuration
	[SQL_Memory_Model] [nvarchar](120) NULL,
	[Instant_File_Initialization_Enabled] [nvarchar](1) NULL,
	[Server_Services] [xml] NULL,
--Monitoring
	[SQLServer_Start_Time] [datetime] NULL,
	[Full_Backup_Timestamp] [xml] NULL,
	[TLog_Backup_Timestamp] [xml] NULL,
	[Blocking] [bit] NULL,
	[CPU_Utilization] [tinyint] NULL,
	[Page_Life_Expectancy] [int] NULL,
	[TLog_Utlization] [xml] NULL,
	[Errors_And_Warnings] [xml] NULL,
	[File_System_Space] [xml] NULL,
	[Script_Version] [xml] NULL
)
GO

CREATE CLUSTERED INDEX [IDX_tblDBMon_SQL_Server_Date_Captured] ON [dbo].[tblDBMon_SQL_Server] ([Date_Captured] DESC)
GO

SELECT * FROM [dbo].[tblDBMon_SQL_Server]
GO


USE [dba_local]
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

--Variable declarations
	DECLARE @varPort								VARCHAR(10)
	DECLARE @varIP									VARCHAR(48)
	DECLARE @varDomain								VARCHAR(256)
	DECLARE @varUserDBCount							SMALLINT
	DECLARE @varCPU									INT
	DECLARE @varPhysical_Memory_KB					BIGINT
	DECLARE @varCommitted_Target_KB					BIGINT
	DECLARE @varSQLServer_Start_Time				DATETIME
	DECLARE @varSQL_Memory_Model					NVARCHAR(120)
	DECLARE @varInstant_File_Initialization_Enabled NVARCHAR(1)
	DECLARE @varServerServices						XML
	DECLARE @varPurge_tblDBMon_SQL_Server_Threshold TINYINT
	DECLARE @varBlocking_Milliseconds_Threshold		SMALLINT
	DECLARE @varBlocking							BIT
	DECLARE @varAvailabilityGroupProperties			XML
	DECLARE @varFullBackupTimestamp					XML
	DECLARE @varTLogBackupTimestamp					XML

--Get Instance IP Address and Port
SELECT	TOP 1 @varPort = [local_tcp_port],
		@varIP = [local_net_address]
FROM	[sys].[dm_exec_connections] 
WHERE	[local_tcp_port] IS NOT NULL
AND		[session_id] IS NOT NULL;

--Get User Databases count
SELECT	@varUserDBCount = COUNT(1)
FROM	[sys].[databases]
WHERE	[database_id] > 4
AND		[is_distributor] = 0

--Check if blocking exists beyond the wait_time threshold
SELECT	@varBlocking_Milliseconds_Threshold = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Blocking_Milliseconds_Threshold'

IF EXISTS (SELECT TOP 1 1 FROM [sys].[dm_exec_requests] WHERE [blocking_session_id] <> 0 AND [wait_time] > @varBlocking_Milliseconds_Threshold)
	BEGIN
		SET @varBlocking = 1
	END
ELSE
	BEGIN
		SET @varBlocking = 0
	END

--Get Server Domain
EXEC master..xp_regread		N'HKEY_LOCAL_MACHINE',
							N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\',
							@value_name = 'Domain',
							@value = @varDomain OUTPUT

--Get System Info							
SELECT	@varCPU = [cpu_count], 
		@varPhysical_Memory_KB = [physical_memory_kb],
		@varCommitted_Target_KB = [committed_target_kb],
		@varSQLServer_Start_Time = [sqlserver_start_time],
		@varSQL_Memory_Model = [sql_memory_model_desc]
FROM	[sys].[dm_os_sys_info]

SET @varFullBackupTimestamp = 
			(SELECT		TOP 1 [name] as [Database_Name], 
						DATEADD(S ,DATEDIFF (S, GETDATE(), GETUTCDATE()), ISNULL(backup_finish_date, 0)) Backup_Finish_Date
			FROM		sys.databases [Database_Full_Backup_Timestamp]
			LEFT JOIN	(
							SELECT		a.[database_name], MAX(a.backup_finish_date) backup_finish_date
							FROM		msdb.dbo.backupset a
							WHERE		a.[type] = 'd'
							GROUP BY	a.[database_name]
						) a
					ON	[name] = a.[database_name]
			INNER JOIN	sys.database_mirroring
					ON	[Database_Full_Backup_Timestamp].database_id = sys.database_mirroring.database_id
			WHERE		[state] <> 6
			AND			[Database_Full_Backup_Timestamp].database_id <> 2
			AND			sys.fn_hadr_backup_is_preferred_replica([name]) = 1
			AND			(sys.database_mirroring.mirroring_role <> 2 or sys.database_mirroring.mirroring_role is null)
			ORDER BY	2
			FOR XML AUTO, ELEMENTS)

SET @varTLogBackupTimestamp = 
			(SELECT		TOP 1 [name] as [Database_Name], 
						DATEADD(S ,DATEDIFF (S, GETDATE(), GETUTCDATE()), ISNULL(backup_finish_date, 0)) Backup_Finish_Date
			FROM		sys.databases [Database_TLog_Timestamp]
			LEFT JOIN	(
							SELECT		a.[database_name], MAX(a.backup_finish_date) backup_finish_date
							FROM		msdb.dbo.backupset a
							WHERE		a.[type] = 'l'
							GROUP BY	a.[database_name]
						) a
					ON	[name] = a.[database_name]
			INNER JOIN	sys.database_mirroring
					ON	[Database_TLog_Timestamp].database_id = sys.database_mirroring.database_id 
			WHERE		[Database_TLog_Timestamp].recovery_model <> 3 
			AND			[state] = 0
			AND			[Database_TLog_Timestamp].database_id <> 2
			AND			sys.fn_hadr_backup_is_preferred_replica([name]) = 1
			AND			(sys.database_mirroring.mirroring_role <> 2 or sys.database_mirroring.mirroring_role is null)
			ORDER BY	2
			FOR XML AUTO, ELEMENTS)

--Get AlwaysOn Availability Group details
SET @varAvailabilityGroupProperties = 
		(SELECT		AGL.[dns_name] AS [Listner_Name], 
					AGL.[port] AS [Port],
					REPLACE(REPLACE(REPLACE(AGL.[ip_configuration_string_from_cluster], '(', ''), ')', ''),'''', '') AS [IP], 
					ARS.[role] AS [Role], 
					AG.[name] AS [AG_Name],
					AR.[availability_mode_desc] AS [Availability_Mode], 
					AR.[failover_mode_desc] AS [Failover_Mode],
					AGS.[synchronization_health_desc] [Sync_Health]
		FROM		[sys].[dm_hadr_availability_group_states] AGS
		INNER JOIN	[sys].[dm_hadr_availability_replica_states] ARS
				ON	AGS.group_id = ARS.group_id
		INNER JOIN	[sys].[availability_groups] AG
				ON	AGS.group_id = AG.group_id
		INNER JOIN	[sys].[availability_replicas] AR
				ON	AR.replica_id = ARS.replica_id
		LEFT OUTER JOIN [sys].[availability_group_listeners] AGL
				ON	AGL.group_id = AGS.group_id	
		WHERE		ARS.is_local = 1
		FOR XML AUTO, ELEMENTS)

--Get SQL Server services details
SELECT	@varInstant_File_Initialization_Enabled = [instant_file_initialization_enabled]
FROM	[sys].[dm_server_services]
WHERE	[filename] LIKE '%sqlservr.exe%'
		
SET		@varServerServices = 
		(SELECT	[servicename] AS [Service_Name], 
				[service_account] AS [Service_Account],
				[startup_type_desc] AS [Startup_Type],	
				[status_desc] AS [Status]
		FROM	[sys].[dm_server_services] [Server_Services]
		WHERE	[servicename] LIKE '%SQL Server%'
		FOR XML AUTO, ELEMENTS)

--Enter the values captured locally
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
		@varUserDBCount AS [User_Databases],
		NULL AS [AOAG_Health],
		@varAvailabilityGroupProperties AS [AOAG_Details],
		@varCPU AS [CPU], 
		@varPhysical_Memory_KB AS [Physical_Memory_KB],
		@varCommitted_Target_KB AS [Committed_Target_KB],
		@varSQL_Memory_Model AS [SQL_Memory_Model],
		@varInstant_File_Initialization_Enabled AS [Instant_File_Initialization_Enabled],
		@varServerServices AS [Server_Services],
		@varSQLServer_Start_Time AS [SQLServer_Start_Time],
		@varFullBackupTimestamp AS [Full_Backup_Timestamp],
		@varTLogBackupTimestamp AS [TLog_Backup_Timestamp],
		@varBlocking AS [Blocking],
		NULL AS [CPU_Utilization],
		NULL AS [Page_Life_Expectancy],
		NULL AS [TLog_Utlization],
		NULL AS [Errors_And_Warnings],
		NULL AS [File_System_Space],
		NULL AS [Script_Version]

--Purge data
SELECT	@varPurge_tblDBMon_SQL_Server_Threshold = [Config_Parameter_Value]
FROM	[dbo].[tblDBMon_Config_Details]
WHERE	[Config_Parameter] = 'Purge_tblDBMon_SQL_Server_Threshold'

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
SELECT	TOP 1 * 
FROM	[dbo].[tblDBMon_SQL_Server]
ORDER BY [Date_Captured] DESC
GO

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
