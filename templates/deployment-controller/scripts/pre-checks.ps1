param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    $ArtifactPath = "$AgentBuildPath\$BuildNumber\$($package.artifact.name)"
    if ( -NOT (Test-Path $ArtifactPath) ) {
        Write-Host "Package not found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME"
        continue
    }
    Write-Host "Package found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME"
}