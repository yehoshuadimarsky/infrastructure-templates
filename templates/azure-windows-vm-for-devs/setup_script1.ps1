# RUN FROM ADMIN POWERSHELL
param(
    [Parameter(Mandatory = $true)]
    [string]$localUserName,

    [Parameter(Mandatory = $true)]
    [string]$localUserPassword
)


$ErrorActionPreference = "Stop"

# Random

# Disable auto launching Server Manager
# from https://charbelnemnom.com/2016/11/how-to-disable-server-manager-at-startup-for-all-users-windowsserver-servermanager/
Write-Host "Disabling the Server Manager from launching on startup..."
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

# Disable Internet Explorer Enhanced Security mode
# from https://gist.github.com/danielscholl/bbc18540418e17c39a4292ffcdcc95f0
function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    $toRestartExplorer = @($false, $false)

    if ((Get-ItemProperty -Path $AdminKey -Name "IsInstalled").IsInstalled -eq 1) {
        Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
        $toRestartExplorer[0] = $true
    }

    if ((Get-ItemProperty -Path $UserKey -Name "IsInstalled").IsInstalled -eq 1) {
        Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
        $toRestartExplorer[1] = $true
    }
    
    if ($toRestartExplorer -contains $true) {
        Stop-Process -Name Explorer
        Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
    }
    else {
        Write-Host "IE Enhanced Security Configuration (ESC) is already disabled." -ForegroundColor Green
    }
    
}
Disable-ieESC


########## Setup Users ##########

# Create User, add to RDP login group
$localUser = Get-LocalUser | Where-Object {$_.Name -eq $localUserName}
if (-not $localUser) {
    Write-Host "Creating local user account for '$($localUserName)'..."
    New-LocalUser $localUserName -Password (ConvertTo-SecureString  $localUserPassword -AsPlainText -Force)
}
else {
    Write-Host "Local user account '$($localUserName)' already exists, skipping..."
}

$rdpGroup = "Remote Desktop Users"
$IsInRdpGroup = (Get-LocalGroupMember -Group $rdpGroup | ForEach-Object { $_.Name -split "\\" -contains $localUserName } ) 
if (!($IsInRdpGroup -contains $true)) {
    Write-Host "Adding user '$($localUserName)' to $($rdpGroup)..."
    Add-LocalGroupMember -Name $rdpGroup -Member $localUserName
}
else {
    Write-Host "User '$($localUserName)' is already part of '$($rdpGroup)', skipping..."
}





########## User Applications ##########


# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


Restart-Computer
