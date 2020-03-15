# Overview
This creates a basic Windows VM in Azure using the ARM Templates approach, along with the associated resources required (networking, storage, etc.), all in a new dedicated Resource Group.

This deployment uses the following files:

* `ARM_deploy.ps1`
    * Top level script to run, this creates the ARM deployment, and then on the last line it invokes the `post-deploy.ps1` script
* `arm.parameters.json`
    * Config/settings file for the ARM template
* `post-deploy.ps1`
    * Powershell script to run after the resources are created, this does some basic setup and housekeeping, such as
        * Enabling PowerShell remoting
        * Creating a local non-admin user with RDP permissions
        * Installing Chocolatey, a popular package manager for Windows
* `PSdeploy.parameters.json`
    * Config file for all non-ARM configs
* `template.json`
    * The ARM JSON document that describes the resources being created

The `.gitignore` file excludes the 2 config/settings files, so examples are provided here with the `*.example.json` suffix.

To extend this template, copy it to a new folder, then modify it.
