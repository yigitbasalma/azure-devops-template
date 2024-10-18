param (
    [string]$Environment,
    [string]$Packages,
    [string]$CurrentBuildPath,
    [string]$ArtifactDropLocation
)

Get-ChildItem -Path $ArtifactDropLocation

$($Packages | ConvertFrom-Json) | ForEach-Object {
    $appArtifactZipLocation = "$ArtifactDropLocation\$($_.artifact.name)"
    $configArtifactZipLocation = "$ArtifactDropLocation\$($_.artifact.config)"

    if ( Test-Path $appArtifactZipLocation ) {
        Write-Host "Package found for '$($_.name)'."
        $appArtifactDestLocation = "$CurrentBuildPath\$($_.type)_$($_.name)"

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($appArtifactZipLocation, $appArtifactDestLocation)

        if ( Test-Path $configArtifactZipLocation ) {
            Write-Host "Config found for '$($_.name)'."
            $configArtifactDestLocation = "$CurrentBuildPath\config_$($_.name)"

            [System.IO.Compression.ZipFile]::ExtractToDirectory($configArtifactZipLocation, $configArtifactDestLocation)
            Copy-Item -Path $configArtifactDestLocation\$environment\* -Destination "$appArtifactDestLocation\" -Force -Recurse
            Remove-Item -Path $configArtifactDestLocation -Force -Recurse
        }

        $publishPath = "$CurrentBuildPath\publish\$(build.BuildNumber)"

        if( -Not(Test-Path $publishPath) ) {
            New-Item -ItemType Directory -Path $publishPath
        }

        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
        [System.IO.Compression.ZipFile]::CreateFromDirectory($appArtifactDestLocation, "$publishPath\$($_.artifact.name)", [System.IO.Compression.CompressionLevel]::Optimal,$false)

        Remove-Item -Path $appArtifactDestLocation -Force -Recurse
    } else {
        Write-Host "No artifact found named '$appArtifactZipLocation' for '$($_.name)' named application and '$Environment' environment."
        exit 1
    }
}