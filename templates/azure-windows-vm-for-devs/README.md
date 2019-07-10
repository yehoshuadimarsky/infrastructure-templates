# Windows VM for software development

## Notes
You will need to create 2 local settings files and save them in this directory.

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
        "resourceGroupLocation": "eastus"
    }
    ```
