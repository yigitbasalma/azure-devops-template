param (
    [string]$LBAddress,
    [string]$LBUsername,
    [string]$LBPassword,

    [string]$VServers,
    [string]$Operation
)

switch ($Operation) {
    "enable" {
        # Enable vservers
    }
    "disable" {
        $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$LBUsername`:$LBPassword"))
        $baseApiUrl = "$LBAddress/nitro/v1/config"

        $($VServers | ConvertFrom-Json) | ForEach-Object {
            # Define the body of the request to disable the vServer
            $body = @{
                servicegroup = @{
                    servername       = $_.Name
                    servicegroupname = $_.ServiceGroup
                    port             = $_.Port
                }
            } | ConvertTo-Json

            # Send the request to disable the vServer
            $response = Invoke-RestMethod -Uri "$baseApiUrl/servicegroup?action=disable" -Method Post -Headers @{
                "Content-Type" = "application/json"
                "Authorization" = "Basic $authInfo"
            } -Body $body

            # Check the response
            if ($response.message -eq $null) {
                Write-Host "$($_.Name) server is disabled."
            } else {
                Write-Host "Failed to disable vServer '$($_.Name)'. Error: $($response.message)"
            }
        }
    }
    default {
        Write-Host "Invalid operation. Please enter 'enable' or 'disable'."
    }
}