param (
    [string]$Environment,
    [string]$Packages,
    [string]$CurrentBuildPath,
    [string]$BuildNumber
)

function ArtifactExistence-Check {
    param (
        [string]$Path
    )

    if ( Test-Path $Path ) {
        return $true
    }

    return $false
}

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    $ArtifactPath = "$CurrentBuildPath\$BuildNumber\$($package.artifact.name)"
    if ( -NOT (ArtifactExistence-Check -Path $ArtifactPath) ) {
        Write-Host "Package not found for $($package.name) on $ArtifactPath at $env:COMPUTERNAME"
        continue
    }
}