param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    $site = Get-Website -Name $package.iis.name
    $appArtifactZipLocation = "$AgentBuildPath\$BuildNumber\$($package.artifact.name)"
    $tempDir = "C:\Temp\$($package.artifact.name)"

    if ( Test-Path $tempDir ) {
        Remove-Item -Path $tempDir -Recurse -Force | out-null
    } else {
        New-Item -ItemType "directory" -Path $tempDir | out-null
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($appArtifactZipLocation, $tempDir)

    Copy-Item -Path "$tempDir\*" -Destination $site.physicalPath -Recurse
}