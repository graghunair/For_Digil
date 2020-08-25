USE [DBA_DBMon]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SP_Version] 
GO

CREATE TABLE [dbo].[tblDBMon_SP_Version](
		[SP_Name]			SYSNAME,
		[SP_Version]		VARCHAR(15),
		[Last_Executed]		DATETIME,
		[Date_Modified]		DATETIME,
	CONSTRAINT [PK_tblDBMon_SP_Version] PRIMARY KEY CLUSTERED 
(
	[SP_Name] ASC
))
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SQL_Servers]
GO
CREATE TABLE [dbo].[tblDBMon_SQL_Servers](
--Inventory
	[Server_Name] NVARCHAR(128) NOT NULL,
	[Handshake_Timestamp] DATETIME NULL,
	[Domain] VARCHAR(50) NULL,
	[IP_Address] VARCHAR(50) NULL,
	[Port] INT NULL,
	[Is_Active] BIT NOT NULL,
	[Is_Production] BIT NOT NULL,
	[Server_Host] nvarchar(128) NULL,
	[Edition] nvarchar(128) NULL,
	[Product_Version] nvarchar(128) NULL,
	[OS_Version] NVARCHAR(128) NULL,
	[Is_Clustered] BIT NULL,
	[Is_Hadr_Enabled] BIT NULL,
	[User_Databases] SMALLINT NULL,
	[AOAG_Health] BIT NULL,
	[AOAG_Details] XML NULL,
	[Application_Category] VARCHAR(500) NULL,
	[Application_Contact] VARCHAR(500) NULL,
	[Comments] VARCHAR(2000) NULL,
--H/W Specs
	[CPU] INT NULL,
	[Physical_Memory_KB] BIGINT NULL,
	[Committed_Target_KB] BIGINT NULL,
--Configuration
	[SQL_Memory_Model] NVARCHAR(120) NULL,
	[Instant_File_Initialization_Enabled] [NVARCHAR](1) NULL,
	[Server_Services] XML,
--Monitoring
	[SQLServer_Start_Time] DATETIME NULL,	
	[Full_Backup_Timestamp] XML NULL,
	[TLog_Backup_Timestamp] XML NULL,
	[Blocking] BIT NULL,
	[CPU_Utilization] TINYINT NULL,
	[Page_Life_Expectancy] INT NULL,
	[TLog_Utlization] XML,
	[Errors_And_Warnings] XML NULL,
	[File_System_Space] XML NULL,
	[Script_Version] XML NULL,
	[Date_Entered] DATETIME NOT NULL
)

ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [PK_tblDBMon_SQL_Servers_Server_Name] PRIMARY KEY CLUSTERED ([Server_Name]);
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Date_Entered] DEFAULT GETDATE() FOR [Date_Entered] ;
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Is_Active] DEFAULT 1 FOR [Is_Active] ;
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Production] DEFAULT 1 FOR [Is_Production] ;
GO

INSERT INTO [dbo].[tblDBMon_SQL_Servers]([Server_Name]) VALUES ('server-0')
INSERT INTO [dbo].[tblDBMon_SQL_Servers]([Server_Name]) VALUES ('server-1')
GO

SELECT * FROM [dbo].[tblDBMon_SQL_Servers]
GO

DROP VIEW IF EXISTS [dbo].[vwDBMon_SQL_Servers]
GO

CREATE VIEW [dbo].[vwDBMon_SQL_Servers]
AS
SELECT	[Server_Name],
		DATEDIFF(mi, [Handshake_Timestamp], GETDATE()) AS [Last_Handshake_Mins],
		[Domain],
		[IP_Address],
		[Port],
		[Is_Production],
		[Edition],
		CASE 
			WHEN	[Product_Version] LIKE '10%' THEN '2008/R2'
			WHEN	[Product_Version] LIKE '11%' THEN '2012'
			WHEN	[Product_Version] LIKE '12%' THEN '2014'
			WHEN	[Product_Version] LIKE '13%' THEN '2016'
			WHEN	[Product_Version] LIKE '14%' THEN '2017'
			WHEN	[Product_Version] LIKE '15%' THEN '2019'
			ELSE 'Unknown'
		END [SQL_Version],
		[OS_Version],
		[Is_Hadr_Enabled],
		[User_Databases],
		UPPER([AOAG_Details].value('(/AGL/Listener_Name)[1]', 'nvarchar(126)')) AS [Listener_Name],
		[AOAG_Details].value('(/AGL/Port)[1]', 'INT') AS [Listener_Port],
		[AOAG_Details].value('(/AGL/IP)[1]', 'nvarchar(126)') AS [Listener_IP],
		[AOAG_Details].value('(/AGL/ARS/Role)[1]', 'nvarchar(126)') AS [AOAG_Role],
		[AOAG_Details].value('(/AGL/ARS/AG/AR/AGS/Sync_Health)[1]', 'nvarchar(126)') AS [AOAG_Synchronization_Health],
		[AOAG_Details].value('(/AGL/ARS/AG/AR/Availability_Mode)[1]', 'nvarchar(126)') AS AOAG_Availability_Mode,
		[AOAG_Details].value('(/AGL/ARS/AG/AR/Failover_Mode)[1]', 'nvarchar(126)') AS AOAG_Failover_Mode,
		[Application_Category],
		DATEDIFF(hh, [SQLServer_Start_Time], GETDATE()) AS [Uptime_Hours],
		[Full_Backup_Timestamp].value('(/Database_Full_Backup_Timestamp/Database_Name)[1]', 'varchar(50)') AS [Full_Backup_Database_Name],
		DATEDIFF(dd, [Full_Backup_Timestamp].value('(/Database_Full_Backup_Timestamp/Backup_Finish_Date)[1]', 'varchar(50)') , GETDATE()) AS [Last_Full_Backup_Days],
		[TLog_Backup_Timestamp].value('(/Database_TLog_Timestamp/Database_Name)[1]', 'varchar(50)') AS [TLog_Backup_Database_Name],
		DATEDIFF(hh, [TLog_Backup_Timestamp].value('(/Database_TLog_Timestamp/Backup_Finish_Date)[1]', 'varchar(50)'), GETDATE()) AS [Last_TLog_Backup_Hours]
FROM [dbo].[tblDBMon_SQL_Servers]
WHERE	[Is_Active] = 1
GO

SELECT	*
FROM	[dbo].[vwDBMon_SQL_Servers]
GO
