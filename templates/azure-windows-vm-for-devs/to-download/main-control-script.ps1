
param(
    [Parameter(Mandatory=$true)]
    [string]$userPassword
)


$now = Get-Date -Format "yyyy-MM-ddTHH-mm-ss_ffff"
$logfile = "$(Get-Location)\PSlogfile_$($now).log"

# per https://stackoverflow.com/a/27361865/6067848
function timestamp { Process{"$(Get-Date -Format o): $_"} };

# Run script, with timestamp on each line of output and saved to specified log file
.\setup_script.ps1 -userPasswordVal $userPassword | timestamp *> $logfile



# Delete choco config file
# $FileName = "choco-packages.config"
# if (Test-Path $FileName) 
# {
#     Write-Host "Deleting the config file called $($FileName)"
#     Remove-Item $FileName
# }