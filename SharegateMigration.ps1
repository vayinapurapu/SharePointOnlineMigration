# Load the sites from CSV
# check for incremental - Completed
# check for migration speed control - Need to check with SG team 
# check for monitoring the running jobs, if gets throttled, is there option to pause 
function CheckUrl($urlparam) {
  <#
    .Description
    This function checks the destination URL after loaded from CSV
  #>
    try {
        Write-Host "verifying the url $urlparam" -ForegroundColor Yellow
        $CheckConnection = Invoke-WebRequest -Uri $urlparam
        if($CheckConnection.StatusCode -eq 200) {
        Write-Host "Connection Verified" -ForegroundColor Green
        $status="Success"
    }
}
catch [System.Net.WebException] {
    $ExceptionMessage = $Error[0].Exception
    if ($ExceptionMessage -match "403") {
    Write-Host "URL exists, but you are not authorized" -ForegroundColor Yellow
    Write-LogWarning -Message "URL $urlparam exists, but you are not authorized" -TimeStamp -LogPath $ErrorLogFile
    }
    elseif ($ExceptionMessage -match "503"){
    Write-Host "Error: Server Busy" -ForegroundColor Red
    Write-LogWarning -Message "URL $urlparam exists, but server is busy" -TimeStamp -LogPath $ErrorLogFile
    }
    elseif ($ExceptionMessage -match "404"){
    Write-Host "Error: URL doesn't exists" -ForegroundColor Red
    Write-LogError -Message "URL $urlparam doesn't exists" -TimeStamp -LogPath $ErrorLogFile
    
    }
    else{
    Write-Host "Error: There is an unknown error" -ForegroundColor Red
    Write-LogError -Message "URL $urlparam unknown error" -TimeStamp -LogPath $ErrorLogFile
    }
    $status="Error Occured"
}
return $status
}
Import-Module PSLogging
$CurrentDate = Get-Date
$DateFormat = $CurrentDate.ToString('MM-dd-yyyy_hh-mm-ss')
$LogPath = "C:\Users\vayina1\Temp\OpsLogs"
$ErrorLogFile= "C:\Users\vayina1\Temp\ErrorLogs\MigraionError_" + $DateFormat + ".txt"
$LogName = "MigraionLogs_" + $DateFormat + ".log"
$LogFullPath = $LogPath + "\" + $LogName
$SitesInfo = Import-Csv -Path "C:\Users\vayina1\Desktop\VinayWorkingDocs\Migration\ToBeMigrated.csv"

Start-Log -LogPath $LogPath -LogName $LogName -ScriptVersion "1.0" | Out-Null  

$copySettings = New-CopySettings -OnContentItemExists IncrementalUpdate

foreach($record in $SitesInfo){
    
    $SiteCheck = CheckUrl($record.DestinationSite)
    if($SiteCheck -contains "Success") {
        try {
            $srcSite = Connect-Site -Url $record.SourceSite
            $dstSite = Connect-Site -Url $record.DestinationSite -Browser
            Write-Host "Migration started from $srcSite to $dstSite" -ForegroundColor Yellow
            Write-LogInfo -Message "**************************************************************************************************************" -LogPath $LogFullPath
            Write-LogInfo -Message "Source Site: $srcSite" -LogPath $LogFullPath
            Write-LogInfo -Message "Destination Site: $dstSite" -LogPath $LogFullPath
            $MigrationResult = Copy-Site -Site $srcSite -DestinationSite $dstSite -Merge -NoCustomizedListForms  -CopySettings $copySettings -ErrorAction Stop 
            Write-Host $MigrationResult.Errors
            Write-Host $MigrationResult.Result

    
            if($MigrationResult.Errors -ne $null){
                Write-Host "The migration completed with errors" -ForegroundColor Yellow
                
                Write-LogInfo -Message $MigrationResult.Result -TimeStamp -LogPath $LogFullPath        
                Write-LogInfo -Message "**************************************************************************************************************`r`n" -LogPath $LogFullPath
            }

        }
        catch {
            $ErrorMessage = $_
            Write-Host "An Exception occured...$ErrorMessage"
            Write-LogError -Message $ErrorMessage -TimeStamp -LogPath $ErrorLogFile
        }
    }
    else {
    Write-Host "Error Occured... $SiteCheck" -ForegroundColor Red
    
    }
}
    

