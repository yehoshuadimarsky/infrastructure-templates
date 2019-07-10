# RUN FROM ADMIN POWERSHELL
param(
    [Parameter(Mandatory=$true)]
    [string]$userPasswordVal
)

# Variables
$localUserName = "myLocalUser"

# Random
Write-Host "Changing time zone..."
Set-TimeZone -Name "Eastern Standard Time"
# from https://gist.github.com/danielscholl/bbc18540418e17c39a4292ffcdcc95f0
function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
Disable-ieESC


########## Setup Users ##########

# Create User, add to RDP login group
Write-Host "Creating local user account for '$($localUserName)'..."
New-LocalUser $localUserName -Password (ConvertTo-SecureString  $userPasswordVal -AsPlainText -Force)
Write-Host "Adding user '$($localUserName)' to Remote Desktop Users..."
Add-LocalGroupMember -Name "Remote Desktop Users" -Member $localUserName



########## User Applications ##########


# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Choco install the apps
choco install choco-packages.config -y 



