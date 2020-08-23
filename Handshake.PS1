cls

#Variable Declarations and Initiations
    [string]$varDBA_Server_Name ="GORAGHU-QATAR\SQL2016"
    [string]$varDBA_Database_Name = "DBA_DBMon"
    [string]$varTarget_Database_Name = "dba_local"

#T-SQL Queries
    $varGetSQL_Servers =
@"
    SELECT	[Server_Name] 
    FROM	[dbo].[tblDBMon_SQL_Servers]
    WHERE	[Is_Active] = 1
    GO
"@

    $varGetHandshake_Info = 
@"
    EXEC [dbo].[uspDBMon_GetHandshakeInfo]
    GO
"@

#Get a list of SQL Servers
    $varSQL_Servers = Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varGetSQL_Servers

#Loop through each SQL Server
    ForEach ($varSQL_Server in $varSQL_Servers)
        {
            $varHandshake_Info = Invoke-Sqlcmd -ServerInstance $varSQL_Server.Server_Name -Database $varTarget_Database_Name -Query $varGetHandshake_Info
            
            #$varHandshake_Info.Server_Name 
            #$varHandshake_Info.Date_Captured 
            #$varHandshake_Info.Domain
            
            $varUpdate_Handshake_Info = "UPDATE [dbo].[tblDBMon_SQL_Servers] SET " + 
                                        "[Handshake_Timestamp] = '" + $varHandshake_Info.Date_Captured + "', " + 
                                        "[Domain] = '" + $varHandshake_Info.Domain + "', " + 
                                        "[Edition] = '" + $varHandshake_Info.Edition + "', " + 
                                        "[Product_Version] = '" + $varHandshake_Info.Product_Version + "', " + 
                                        "[Is_Clustered] = '" + $varHandshake_Info.Is_Clustered + "', " + 
                                        "[Is_Hadr_Enabled] = '" + $varHandshake_Info.Is_Hadr_Enabled + "', " + 
                                        "[CPU] = '" + $varHandshake_Info.CPU + "', " + 
                                        "[Physical_Memory_KB] = '" + $varHandshake_Info.Physical_Memory_KB + "', " + 
                                        "[Committed_Target_KB] = '" + $varHandshake_Info.Committed_Target_KB + "', " + 
                                        "[SQL_Memory_Model] = '" + $varHandshake_Info.SQL_Memory_Model + "', " + 
                                        "[Server_Services] = '" + $varHandshake_Info.Server_Services + "'" + 
                                        " WHERE [Server_Name] = '" + $varHandshake_Info.Server_Name + "'"
            #$varUpdate_Handshake_Info
            
            Invoke-Sqlcmd -ServerInstance $varDBA_Server_Name -Database $varDBA_Database_Name -Query $varUpdate_Handshake_Info
        }

