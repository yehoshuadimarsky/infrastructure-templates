
Param(
    [parameter(mandatory = $true)]
    [string]$configFile
)


Write-Host "Getting configs from JSON file '$($configFile)' ..."
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

# create log folder
If (!(Test-Path $config.logFolderLocation)) {
    New-Item -ItemType Directory -Force -Path $config.logFolderLocation
}

$now = Get-Date -Format "yyyy-MM-ddTHH-mm-ss_ffff"
$logfile = "$($config.logFolderLocation)\PSlogfile_$($now).log"


# per https://stackoverflow.com/a/27361865/6067848
function timestamp { Process { "$(Get-Date -Format o): $_" } };

"The log file location is: $logfile, starting script run now..." | timestamp | Tee-Object -FilePath $logfile -Append


# Run script, with timestamp on each line of output and saved to specified log file
.\setup_script.ps1 -localUserName $config.localUserName -localUserPassword $config.localUserPassword | timestamp | Tee-Object -FilePath $logfile -Append

# reboot
Restart-Computer -ComputerName . -Wait

# Run script, with timestamp on each line of output and saved to specified log file
.\setup_script2.ps1 | timestamp | Tee-Object -FilePath $logfile -Append
