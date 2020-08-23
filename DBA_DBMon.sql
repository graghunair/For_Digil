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
		[Handshake_Timestamp],
		DATEDIFF(mi, [Handshake_Timestamp], GETDATE()) AS [Last_Handshake_Mins],
		[Domain],
		[IP_Address],
		[Port],
		[Is_Active],
		[Is_Production],
		[Server_Host],
		[Edition],
		[Product_Version],
		[Is_Clustered],
		[Is_Hadr_Enabled],
		[User_Databases],
		[AOAG_Health],
		[AOAG_Details],
		[Application_Category],
		[Application_Contact],
		[Comments],
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
		[Script_Version],
		[Date_Entered]
FROM [dbo].[tblDBMon_SQL_Servers]
GO

SELECT	*
FROM	[dbo].[vwDBMon_SQL_Servers]
GO
