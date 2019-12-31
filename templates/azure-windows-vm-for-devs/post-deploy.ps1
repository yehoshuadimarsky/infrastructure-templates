
## inherits Azure creds from the calling script?

param(
    [Parameter(Mandatory = $true)][string]$deploymentName,
    [string]$configFile = "PSdeploy.parameters.json", # all non-ARM params
    [string]$parametersFilePath = "arm.parameters.json"
)

$ErrorActionPreference = "Stop"
Write-Host "Starting the script called 'post-deploy.ps1'..." -ForegroundColor Green

# Get configs
Write-Host "Getting JSON configs..." -ForegroundColor Yellow
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json
$armConfig = Get-Content -Raw -Path $parametersFilePath | ConvertFrom-Json


# get variables
$deploymentOutputs = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName).Outputs
$vmName = $deploymentOutputs.vmname.value
$vmWebAddress = $deploymentOutputs.hostname.value


############# Functions ###############

function cust_Create-Credential($username, $passwd) {
    Write-Host "Creating PS Credential object..." -ForegroundColor Yellow
    return New-Object System.Management.Automation.PSCredential(
        $username, 
        (ConvertTo-SecureString -AsPlainText -String $passwd -Force)    
    )
}

function cust_Reboot-VM {
    Write-Host "Initiating reboot now..." -ForegroundColor Yellow
    $vmRebootOp = (Restart-AzureRmVM -ResourceGroupName $config.resourceGroupName -Name $vmName -AsJob)
    while ($vmRebootOp.State -ne "Completed") {
        Start-Sleep 1
        if ($vmRebootOp.State -eq "Failed") {
            Write-Host $vmRebootOp -ForegroundColor Red
            break
            exit
        }
    }
    Write-Host "VM sucessfully rebooted" -ForegroundColor Green
}

function cust_Create-PSSession($winCred) {
    # Create PowerShell remote session
    Write-Host "Creating remote PowerShell session..." -ForegroundColor Yellow
    $PSSessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck
    $PsSession = New-PSSession -ComputerName $vmWebAddress -Port 5986 -SessionOption $PSSessionOptions -UseSSL -Credential $winCred
    Write-Host "Remote PowerShell session created" -ForegroundColor Yellow
    return $PsSession
}


######### start work ###########

# create Credentials
$adminCred = cust_Create-Credential -username $armConfig.parameters.adminUsername.value `
    -passwd $armConfig.parameters.adminPassword.value
$userCred = cust_Create-Credential -username $config.localUserName `
    -passwd $config.localUserPassword


########## Setup Users ##########
# via PS remote session
$myPsSession = cust_Create-PSSession -winCred $adminCred

# admin configs
Invoke-Command -Session $myPsSession -ScriptBlock {
    $ErrorActionPreference = "Stop"

    # Disable auto launching Server Manager
    # from https://charbelnemnom.com/2016/11/how-to-disable-server-manager-at-startup-for-all-users-windowsserver-servermanager/
    Write-Host "Disabling the Server Manager from launching on startup..."
    Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

    # Disable Internet Explorer Enhanced Security mode
    # from https://gist.github.com/danielscholl/bbc18540418e17c39a4292ffcdcc95f0
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    # stop Explorer process
    $explorer = Get-Process -Name Explorer -ErrorAction SilentlyContinue
    if ($explorer) {
        $explorer | Stop-Process -Force
    }
    Remove-Variable explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}


Invoke-Command -Session $myPsSession -ScriptBlock {
    $ErrorActionPreference = "Stop"
    
    # Create local user
    $localUser = Get-LocalUser | Where-Object { $_.Name -eq $using:config.localUserName }
    if (-not $localUser) {
        Write-Host "Creating local user account for '$($using:config.localUserName)'..."
        New-LocalUser $using:config.localUserName -Password `
        (ConvertTo-SecureString $using:config.localUserPassword -AsPlainText -Force) -PasswordNeverExpires
    }
    else {
        Write-Host "Local user account '$($using:config.localUserName)' already exists, skipping..."
    }

    # Add user to RDP and PowerShell remoting groups
    foreach ($grp in @("Remote Desktop Users", "Remote Management Users")) {
        $IsInGroup = (Get-LocalGroupMember -Group $grp | ForEach-Object { $_.Name -split "\\" -contains $using:config.localUserName } ) 
        if (!($IsInGroup -contains $true)) {
            Write-Host "Adding user '$($using:config.localUserName)' to $($grp)..."
            Add-LocalGroupMember -Name $grp -Member $using:config.localUserName
        }
        else {
            Write-Host "User '$($using:config.localUserName)' is already part of '$($grp)', skipping..."
        }
    }
}


########## Install apps ##########

# Install choco and set up DSN via PS remote session
Invoke-Command -Session $myPsSession -ScriptBlock {
    $ErrorActionPreference = "Stop"

    # choco
    if (test-path "C:\ProgramData\chocolatey\choco.exe") {
        Write-Host "Chocolatey already installed, skipping"
    }
    else {
        Write-Host "Installing Chocolatey"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
     
    # chrome
    choco install googlechrome --yes
}


# reboot
cust_Reboot-VM

# kill all open powershell sessions
Get-PSSession | Remove-PSSession
