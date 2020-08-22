USE [DBA_DBMon]
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SQL_Servers]
GO
CREATE TABLE [dbo].[tblDBMon_SQL_Servers](
	[Date_Captured] DATETIME NOT NULL,
	[Handshake_Timestamp] DATETIME NULL,
--Inventory
	[Server_Name] NVARCHAR(128) NOT NULL,
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
	[Script_Version] XML NULL
)

ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [PK_tblDBMon_SQL_Servers_Server_Name] PRIMARY KEY CLUSTERED ([Server_Name]);
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Date_Captured] DEFAULT GETDATE() FOR [Date_Captured] ;
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Is_Active] DEFAULT 1 FOR [Is_Active] ;
ALTER TABLE [dbo].[tblDBMon_SQL_Servers] ADD CONSTRAINT [DF_tblDBMon_SQL_Servers_Production] DEFAULT 1 FOR [Is_Production] ;
GO

INSERT INTO [dbo].[tblDBMon_SQL_Servers]([Server_Name]) VALUES ('server-0')
INSERT INTO [dbo].[tblDBMon_SQL_Servers]([Server_Name]) VALUES ('server-1')
GO
SELECT * FROM [dbo].[tblDBMon_SQL_Servers]
GO

