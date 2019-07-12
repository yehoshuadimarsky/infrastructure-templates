# Windows VM for software development

## Notes
I haven't yet figured out how to remotely execute PowerShell scripts on the VM from the local computer, so for now, after creating the VM, you need to RDP into it, copy the scripts and config files, and run locally on that VM.

## Prerequisites
AzureRM PowerShell modules installed

## Instructions
1. Create the following local settings files and save them in this directory:

    1. `arm.parameters.json` -> file contents:

        ```
        {
            "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {
                "adminUsername": {
                    "value": "admin"
                },
                "adminPassword": {
                    "value": "<admin password>"
                },
                "userPassword": {
                    "value": "<user password>"
                },
                "allowedIPAddresses":{
                    "value": [
                        "1.2.3.4"
                    ]
                },
                "dnsLabelPrefix": {
                    "value": "mydnsPrefix"
                }
            }
        }
        ```
    2. `PSdeploy.parameters.json` -> file contents:

        ```
        {
            "AzureSubscriptionId": "< GUID > ",
            "resourceGroupName": "my-resource-group",
            "resourceGroupLocation": "eastus",
            "VM_Name": "VMdevvm",
            "localUserName": "< local user name > ",
            "localUserPassword": "< password >"
        }
        ```
2. In a PowerShell terminal run the `ARM_deploy.ps1` file. Follow the login prompts.
3. RDP into the Azure VM with the Admin creds, copy these files
    * `setup_script1.ps1`
    * `setup_script2.ps1`
    * All the `choco-packages-*.config` files
4. Run the first script, it will reboot.
5. RDP in again, run the second script.
