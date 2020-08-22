USE [dba_local]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SQL_Server]
GO
CREATE TABLE [dbo].[tblDBMon_SQL_Server](
	[Date_Captured] DATETIME NOT NULL,
	[Server_Name] NVARCHAR(128) NOT NULL,
	[Domain] VARCHAR(50) NULL,
	[IP_Address] VARCHAR(50) NULL,
	[Port] INT NULL,
	[Server_Host] nvarchar(128) NULL,
	[Edition] nvarchar(128) NULL,
	[Product_Version] nvarchar(128) NULL,
	[Is_Clustered] BIT NULL,
	[Is_Hadr_Enabled] BIT NULL,
	[AOAG_Health] BIT NULL,
	[AOAG_Details] XML NULL,
	[CPU] INT NULL,
	[Physical_Memory_KB] BIGINT NULL,
	[Committed_Target_KB] BIGINT NULL,
	[SQL_Memory_Model] NVARCHAR(120) NULL,
	[Server_Services] XML NULL,
	[SQLServer_Start_Time] DATETIME NULL,	
	[Full_Backup_Timestamp] XML NULL,
	[TLog_Backup_Timestamp] XML NULL,
	[Blocking] BIT NULL,
	[CPU_Utilization] TINYINT NULL,
	[Page_Life_Expectancy] INT NULL,
	[TLog_Utlization] XML,
	[Errors_And_Warnings] XML NULL,
	[File_System_Space] XML NULL,
	[Script_Version] XML NULL)

CREATE CLUSTERED INDEX [IDX_tblDBMon_SQL_Server_Date_Captured] ON [dbo].[tblDBMon_SQL_Server]([Date_Captured])
GO
DROP PROCEDURE IF EXISTS [dbo].[uspDBMon]
GO
CREATE PROCEDURE [dbo].[uspDBMon]
AS
SET NOCOUNT ON

--Variable declarations
	DECLARE @varPort						VARCHAR(48)
	DECLARE @varIP							VARCHAR(48)
	DECLARE @varDomain						VARCHAR(256)
	DECLARE @varUserDBCnt					SMALLINT
	DECLARE @varCPU							INT
	DECLARE @varPhysical_Memory_KB			BIGINT
	DECLARE @varCommitted_Target_KB			BIGINT
	DECLARE @varSQLServer_Start_Time		DATETIME
	DECLARE @varSQL_Memory_Model			NVARCHAR(120)
	DECLARE @varServerServices				XML

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
GO

EXEC dbo.uspDBMon
GO
SELECT * FROM [dbo].[tblDBMon_SQL_Server]
GO
