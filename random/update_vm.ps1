
## Main script to run to fully set up all applications on newly-provisioned VM

$ErrorActionPreference = "Stop"


# Get configs
Write-Host "Getting JSON config..."
$config = Get-Content -Raw -Path .\PSdeploy.parameters.json | ConvertFrom-Json

$script1 = "setup_script1.ps1"



# sign in
Write-Host "Logging in...";
Login-AzureRmAccount;

# select subscription
Write-Host "Selecting subscription '$($config.AzureSubscriptionId)'";
Select-AzureRmSubscription -SubscriptionID $config.AzureSubscriptionId;

# call setup1.ps1
Write-Host "Starting the script '$($script1)' Azure VM..."
Invoke-AzureRmVMRunCommand -ResourceGroupName $config.resourceGroupName -VMName $config.VM_Name -CommandId 'RunPowerShellScript' `
 -ScriptPath $script1 -Parameter @{localUserName = $config.localUserName; localUserPassword = $config.localUserPassword}


# initiate reboot
Write-Host "Initiating reboot on the Azure VM..."
Restart-AzureRmVM -ResourceGroupName $config.resourceGroupName -Name $config.VM_Name
Write-Host "Reboot successful..."

# call setup2.ps1
# Invoke-Expression -Command ".\setup_script2.ps1"


