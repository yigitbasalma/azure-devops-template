param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

$IISManagerCommand = "C:\Windows\system32\inetsrv\appcmd"

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    $ArtifactPath = "$AgentBuildPath\$BuildNumber\$($package.artifact.name)"
    if ( -NOT (Test-Path $ArtifactPath) ) {
        Write-Host "Package not found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME"
        continue
    }
    Write-Host "Package found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME"

    $IISPoolState = & $IISManagerCommand list apppool /name:$($package.iis.poolName) /text:state
    if ( ([string]::IsNullOrEmpty($IISPoolState)) ) {
        Write-Host "Pool named '$($package.iis.poolName)' is not found on $env:COMPUTERNAME"
        continue
    }
    Write-Host "Pool named '$($package.iis.poolName)' is found on $env:COMPUTERNAME"
}

exit 0