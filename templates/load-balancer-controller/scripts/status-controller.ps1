param (
    [string]$LBAddress,
    [string]$LBUsername,
    [string]$LBPassword,

    [string]$VServers,
    [string]$DeploymentPart,
    [string]$Operation
)

$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$LBUsername`:$LBPassword"))
$baseApiUrl = "$LBAddress/nitro/v1/config"

switch ($Operation) {
    "enable" {
        $($VServers | ConvertFrom-Json) | ForEach-Object {
            if ( $DeploymentPart -ne $_.DeployGroup ) {
                # Define the body of the request to disable the vServer
                $body = @{
                    server = @{
                        name = $_.Name
                    }
                } | ConvertTo-Json

                # Send the request to disable the vServer
                $response = Invoke-RestMethod -Uri "$baseApiUrl/server?action=enable" -Method Post -Headers @{
                    "Content-Type" = "application/json"
                    "Authorization" = "Basic $authInfo"
                } -Body $body

                # Check the response
                if ($response.message -eq $null) {
                    Write-Host "$( $_.Name ) server is disabled."
                } else {
                    Write-Host "Failed to disable vServer '$( $_.Name )'. Error: $( $response.message )"
                }
            }
        }
    }
    "disable" {
        $($VServers | ConvertFrom-Json) | ForEach-Object {
            if ( $DeploymentPart -ne $_.DeployGroup ) {
                # Define the body of the request to disable the vServer
                $body = @{
                    server = @{
                        name = $_.Name
                    }
                } | ConvertTo-Json

                # Send the request to disable the vServer
                $response = Invoke-RestMethod -Uri "$baseApiUrl/server?action=disable" -Method Post -Headers @{
                    "Content-Type" = "application/json"
                    "Authorization" = "Basic $authInfo"
                } -Body $body

                # Check the response
                if ($response.message -eq $null) {
                    Write-Host "$( $_.Name ) server is disabled."
                } else {
                    Write-Host "Failed to disable vServer '$( $_.Name )'. Error: $( $response.message )"
                }
            }
        }
    }
    default {
        Write-Host "Invalid operation. Please enter 'enable' or 'disable'."
    }
}