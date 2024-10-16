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
                params = @{
                    action  = "disable"
                }
                service = @{
                    name    = $_.Name
                }
            } | ConvertTo-Json

            # Send the request to disable the vServer
            $response = Invoke-RestMethod -Uri "$baseApiUrl" -Method Post -Headers @{
                "Content-Type" = "application/x-www-form-urlencoded"
                "Authorization" = "Basic $authInfo"
            } -Body $body

            # Check the response
            if ($response.errorcode -eq 0) {
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