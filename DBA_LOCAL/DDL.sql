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
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [DF_tblDBMon_Config_Details_Updated_By] DEFAULT (suser_sname()) FOR [Updated_By]
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [DF_tblDBMon_Config_Details_Date_Updated] DEFAULT (getdate()) FOR [Date_Updated]
GO
INSERT INTO [dbo].[tblDBMon_Config_Details]([Config_Parameter], [Config_Parameter_Value]) VALUES ('Purge_tblDBMon_SQL_Server_Threshold', '10')
GO

DROP TABLE IF EXISTS [dbo].[tblDBMon_SP_Version] 
GO
CREATE TABLE [dbo].[tblDBMon_SP_Version](
		[SP_Name]			SYSNAME,
		[SP_Version]		VARCHAR(15),
		[Last_Executed]		DATETIME,
		[Date_Modified]		DATETIME)
GO
ALTER TABLE [dbo].[tblDBMon_Config_Details] ADD CONSTRAINT [PK_tblDBMon_SP_Version] PRIMARY KEY ([SP_Name])
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
	[User_Databases] SMALLINT NULL,
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
GO
CREATE CLUSTERED INDEX [IDX_tblDBMon_SQL_Server_Date_Captured] ON [dbo].[tblDBMon_SQL_Server]([Date_Captured])
GO
