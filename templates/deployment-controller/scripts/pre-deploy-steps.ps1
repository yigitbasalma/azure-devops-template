param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    Stop-WebAppPool -Name "$($package.iis.poolName)"
    while ( (Get-WebAppPoolState -Name "$($package.iis.poolName)").Value -ne "Stopped" ) {
        Write-Host "[$($package.iis.poolName)] Waiting for the application pool to stop..."
        Start-Sleep -Seconds 1
    }
    Write-Host "[$($package.iis.poolName)] The application pool is now stopped."
}

exit 0