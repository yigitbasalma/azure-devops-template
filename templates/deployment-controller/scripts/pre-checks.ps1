param (
    [string]$Environment,
    [string]$Packages,
    [string]$CurrentBuildPath,
    [string]$BuildNumber
)

# ANSI escape codes for colors
$green = "`e[32m"
$yellow = "`e[33m"
$red = "`e[31m"
$reset = "`e[0m"

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    Write-Host "------------Starting to the artifact existence pre-check---------------"

    $ArtifactPath = "$CurrentBuildPath\$BuildNumber\$($package.artifact.name)"
    if ( -NOT (Test-Path $ArtifactPath) ) {
        Write-Host "$red Package not found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME $reset"
        continue
    }
    Write-Host "$green Package found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME $reset"

    Write-Host "------------End to the artifact existence pre-check---------------"
}