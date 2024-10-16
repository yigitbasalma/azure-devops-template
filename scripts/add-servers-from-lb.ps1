param (
    [string]$LBAddress,
    [string]$LBUsername,
    [string]$LBPassword,
    [string]$VirtualServerName,

    [string]$VMUsername,
    [string]$VMPassword,

    [string]$DeploymentGroup,
    [string]$PersonalAccessToken,
    [string]$ParentProjectName,
    [string]$Environment
)

# Variables
$deployGroupIdentifier = "part1"
$vServers = @()
$timeoutSeconds = 300

# Create VM connection credentials
$SecureVMPassword = ConvertTo-SecureString "$VMPassword" -AsPlainText -Force
$VMCredential = New-Object System.Management.Automation.PSCredential -argumentlist $VMUsername,$SecureVMPassword

# Base64 encode the credentials for Basic Authentication
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$LBUsername`:$LBPassword"))

# Define the base API URL
$baseApiUrl = "$LBAddress/nitro/v1/config"

# Bypass SSL certificate validation
# [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# 1. Get the virtual server details to identify service groups
$virtualServerUrl = "$baseApiUrl/lbvserver_servicegroup_binding/$VirtualServerName"
$response = Invoke-RestMethod -Uri $virtualServerUrl -Method Get -Headers @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic $authInfo"
} -TimeoutSec $timeoutSeconds

# Extract service group bindings from the response
$serviceGroups = $response.lbvserver_servicegroup_binding

# 2. Get the members (servers) of each service group
foreach ($sg in $serviceGroups) {
    $serviceGroupName = $sg.servicegroupname
    $serviceGroupUrl = "$baseApiUrl/servicegroup_servicegroupmember_binding/$serviceGroupName"

    # Get the service group members
    $sgResponse = Invoke-RestMethod -Uri $serviceGroupUrl -Method Get -Headers @{
        "Content-Type" = "application/json"
        "Authorization" = "Basic $authInfo"
    } -TimeoutSec $timeoutSeconds

    # Extract and print the servers in each service group
    if ($sgResponse.servicegroup_servicegroupmember_binding) {
        $sgResponse.servicegroup_servicegroupmember_binding | ForEach-Object {
            $server = [PSCustomObject]@{
                Name         = $_.servername
                IPAddress    = $_.ip
                Port         = $_.port
                ServiceGroup = $serviceGroupName
                DeployGroup  = $deployGroupIdentifier
            }
            $vServers += $server

            Invoke-Command -ComputerName $_.ip -Credential $VMCredential -ArgumentList $DeploymentGroup, $ParentProjectName, $PersonalAccessToken, $deployGroupIdentifier, $Environment -ScriptBlock {
                param (
                    $DeploymentGroup,
                    $ParentProjectName,
                    $PersonalAccessToken,
                    $deployGroupIdentifier,
                    $Environment
                )

                # Set error handling
                $ErrorActionPreference = "Stop"

                # Check if the script is being run as an administrator
                If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                    throw "Run command in an administrator PowerShell prompt"
                }

                # Check if PowerShell version is 3.0 or higher
                If ($PSVersionTable.PSVersion -lt (New-Object System.Version("3.0"))) {
                    throw "The minimum version of Windows PowerShell required by the script (3.0) does not match the currently running version of Windows PowerShell."
                }

                # Create the azagent folder in the system drive if it doesn't exist
                If (-NOT (Test-Path $env:SystemDrive\'azagent')) {
                    mkdir $env:SystemDrive\'azagent'
                }

                # Navigate to the azagent directory
                cd $env:SystemDrive\'azagent'

                # Create subfolders A1, A2, ... A99 and navigate into the first available one
                for ($i = 1; $i -lt 100; $i++) {
                    $destFolder = "A" + $i.ToString()
                    if (-NOT (Test-Path ($destFolder))) {
                        mkdir $destFolder
                        cd $destFolder
                        break
                    }
                }

                # Define the agent zip file path
                $agentZip = "$PWD\agent.zip"

                # Configure the security protocols
                $DefaultProxy = [System.Net.WebRequest]::DefaultWebProxy
                $securityProtocol = @()
                $securityProtocol += [Net.ServicePointManager]::SecurityProtocol
                $securityProtocol += [Net.SecurityProtocolType]::Tls12
                [Net.ServicePointManager]::SecurityProtocol = $securityProtocol

                # Create a new web client for downloading the agent package
                $WebClient = New-Object Net.WebClient

                # Define the download URI for the agent
                $Uri = 'https://vstsagentpackage.azureedge.net/agent/3.245.0/vsts-agent-win-x64-3.245.0.zip'

                # Configure proxy settings if needed
                if ($DefaultProxy -and (-not $DefaultProxy.IsBypassed($Uri))) {
                    $WebClient.Proxy = New-Object Net.WebProxy($DefaultProxy.GetProxy($Uri).OriginalString, $True)
                }

                # Download the agent zip file
                $WebClient.DownloadFile($Uri, $agentZip)

                # Extract the downloaded zip file
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($agentZip, "$PWD")

                try {
                    # Configure the Azure DevOps agent
                    .\config.cmd --environment --environmentname "$DeploymentGroup" `
                                 --agent $env:COMPUTERNAME `
                                 --runasservice `
                                 --work '_work' `
                                 --url 'https://dev.azure.com/yigitbasalma/' `
                                 --projectname $ParentProjectName `
                                 --unattended `
                                 --addvirtualmachineresourcetags `
                                 --virtualmachineresourcetags "$deployGroupIdentifier,$Environment" `
                                 --auth PAT `
                                 --token $PersonalAccessToken
                }
                catch {
                    if ($_.Exception.Message -like "*already contains a virtual machine resource with name*") {
                        Write-Host "Virtual machine resource already exists. Ignoring the error and continuing..."
                    }
                }

                # Remove the agent zip file
                Remove-Item $agentZip
            }

            # Toggle deployment group
            if ( $deployGroupIdentifier -eq "part1" ) { $deployGroupIdentifier = "part2" } else {$deployGroupIdentifier = "part1" }
        }
    }
    else {
        Write-Host "No servers found in service group '$serviceGroupName'."
    }
}

# Set global variable to use after
$vServersToJson = $vServers | ConvertTo-Json -Compress
Write-Host "##vso[task.setvariable variable=VServers;]$vServersToJson"