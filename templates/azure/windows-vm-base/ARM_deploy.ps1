

param(
    [Parameter(HelpMessage = "Path to file of cached Azure creds. To create, run: `Save-AzureRmContext -Profile (Connect-AzureRmAccount) -Path path\to\file")]
    [string]$credsFile,

    [string]$configFile = "PSdeploy.parameters.json",
    [string]$templateFilePath = "template.json",
    [string]$parametersFilePath = "arm.parameters.json"
)


# variables
$deploymentName = "VM_Deployment_" + (Get-Date -Format "FileDateTime")


# Get configs
Write-Host "Getting JSON config..."
$config = Get-Content -Raw -Path $configFile | ConvertFrom-Json



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
}
else {
    Import-AzureRMContext -Path $credsFile
}

# select subscription
Write-Host "Selecting subscription '$($config.AzureSubscriptionId)'";
Select-AzureRmSubscription -SubscriptionID $config.AzureSubscriptionId;

# Register RPs
$resourceProviders = @("microsoft.storage", "microsoft.network", "microsoft.compute");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

# Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $config.resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$($config.resourceGroupName)' does not exist. To create a new resource group, please enter a location.";
    if (!$config.resourceGroupLocation) {
        $config.resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$($config.resourceGroupName)' in location '$($config.resourceGroupLocation)'";
    New-AzureRmResourceGroup -Name $config.resourceGroupName -Location $config.resourceGroupLocation
}
else {
    Write-Host "Using existing resource group '$($config.resourceGroupName)'";
}

# Validate the deployment
$validationError = (Test-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath)
if ($validationError) {
    Write-Host "Template validation failed with this message(s), exiting now:" -ForegroundColor Red
    $validationError | foreach { $_.Message, $_.Details }
    exit
} 

# Start the deployment
Write-Host "Starting deployment..." -ForegroundColor Yellow
if (Test-Path $parametersFilePath) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
}
else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath;
}

Write-Host "Deployment succeeded!" -ForegroundColor Green

# Get deployment outputs
$deploymentOutputs = (Get-AzureRmResourceGroupDeployment -ResourceGroupName $config.resourceGroupName -Name $deploymentName).Outputs
$vmName = $deploymentOutputs.vmname.value

# Enable PowerShell remoting
Write-Host "Invoking 'Run Command' called 'EnableRemotePS' to enable PowerShell remoting..." -ForegroundColor Yellow
Invoke-AzureRmVMRunCommand -ResourceGroupName $config.resourceGroupName -VMName $vmName -CommandId 'EnableRemotePS' 
Write-Host "Command 'EnableRemotePS' successfully invoked!" -ForegroundColor Yellow

Invoke-Expression -Command ".\post-deploy.ps1 -deploymentName $deploymentName"
