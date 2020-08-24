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
