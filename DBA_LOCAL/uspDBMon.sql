SET NOCOUNT ON
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
	DECLARE @varServerServices						XML
	DECLARE @varPurge_tblDBMon_SQL_Server_Threshold TINYINT
	DECLARE @varBlocking_Milliseconds_Threshold		SMALLINT
	DECLARE @varBlocking							BIT
	DECLARE @varAvailabilityGroupProperties			XML

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
SET		@varServerServices = 
		(SELECT	[servicename] AS [Service_Name], 
				[service_account] AS [Service_Account],
				[startup_type_desc] AS [Startup_Type],	
				[status_desc] AS [Status],
				[instant_file_initialization_enabled] AS [Instant_File_Initialization]
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
		@varServerServices AS [Server_Services],
		@varSQLServer_Start_Time AS [SQLServer_Start_Time],
		NULL AS [Full_Backup_Timestamp],
		NULL AS [TLog_Backup_Timestamp],
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
SELECT * FROM [dbo].[tblDBMon_SQL_Server]
GO
