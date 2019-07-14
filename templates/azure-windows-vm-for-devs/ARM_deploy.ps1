<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template
#>

param(
    [string]$credsFile,
    [string]$configFile="PSdeploy.parameters.json"
)


# Get configs
Write-Host "Getting JSON config..."
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json


# variables
$deploymentName="Josh_dev_VM_deployment_" + (Get-Date -Format "FileDateTime")
$templateFilePath = "template.json"
$parametersFilePath = "arm.parameters.json"


<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Write-Host "Logging in...";
if (!$credsFile) {
    Login-AzureRmAccount
} else {
    Import-AzureRMContext -Path $credsFile
}

# select subscription
Write-Host "Selecting subscription '$($config.AzureSubscriptionId)'";
Select-AzureRmSubscription -SubscriptionID $config.AzureSubscriptionId;

# Register RPs
$resourceProviders = @("microsoft.storage","microsoft.network","microsoft.compute");
if($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

# Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $config.resourceGroupName -ErrorAction SilentlyContinue
if(!$resourceGroup)
{
    Write-Host "Resource group '$($config.resourceGroupName)' does not exist. To create a new resource group, please enter a location.";
    if(!$config.resourceGroupLocation) {
        $config.resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$($config.resourceGroupName)' in location '$($config.resourceGroupLocation)'";
    New-AzureRmResourceGroup -Name $config.resourceGroupName -Location $config.resourceGroupLocation
}
else{
    Write-Host "Using existing resource group '$($config.resourceGroupName)'";
}

# Start the deployment
Write-Host "Starting deployment...";
if(Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
} else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath;
}

Write-Host "Deployment succeeded!"

# Enable PowerShell remoting
Write-Host "Invoking 'Run Command' called 'EnableRemotePS' to enable PowerShell remoting..."
Invoke-AzureRmVMRunCommand -ResourceGroupName $config.resourceGroupName -VMName (Read-Host 'Enter the VM name') -CommandId 'EnableRemotePS' 
Write-Host "Command 'EnableRemotePS' successfully invoked!"
