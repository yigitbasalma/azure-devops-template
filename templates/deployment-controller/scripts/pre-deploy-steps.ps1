param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    if ( (Get-WebAppPoolState -Name "$($package.iis.poolName)").Value -eq "Stopped" ) {
        Write-Host "[$($package.iis.poolName)] The application pool is already stopped."
    } else {
        Stop-WebAppPool -Name "$($package.iis.poolName)"
        while ( (Get-WebAppPoolState -Name "$($package.iis.poolName)").Value -ne "Stopped" ) {
            Write-Host "[$($package.iis.poolName)] Waiting for the application pool to stop..."
            Start-Sleep -Seconds 30
        }
        Write-Host "[$($package.iis.poolName)] The application pool is now stopped."
    }

    if ( (Get-WebSite -Name "$($package.iis.name)").State -eq "Stopped" ) {
        Write-Host "[$($package.iis.name)] The website is already stopped."
    } else {
        Stop-WebSite -Name "$($package.iis.name)"
        while ( (Get-WebSite -Name "$($package.iis.name)").State -ne "Stopped" ) {
            Write-Host "[$($package.iis.name)] Waiting for the website to stop..."
            Start-Sleep -Seconds 30
        }
        Write-Host "[$($package.iis.name)] The website is now stopped."
    }
}

exit 0