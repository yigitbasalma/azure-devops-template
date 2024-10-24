param (
    [string]$ProjectName,
    [string]$Environment,
    [string]$Packages,
    [string]$BuildNumber,
    [string]$CurrentBuildPath,
    [string]$ArtifactDropLocation
)

# Consts
$nasLocation = "C:\NAS"

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

        $publishPath = "$CurrentBuildPath\publish\$BuildNumber"

        if( -Not(Test-Path $publishPath) ) {
            New-Item -ItemType Directory -Path $publishPath | out-null
        }

        [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem")
        [System.IO.Compression.ZipFile]::CreateFromDirectory($appArtifactDestLocation, "$publishPath\$($_.artifact.name)", [System.IO.Compression.CompressionLevel]::Optimal,$false)

        Remove-Item -Path $appArtifactDestLocation -Force -Recurse

        # If environment is pre-prod which is the last environment before production, save artifact into the NAS
        # for production deployment
        if ( $Environment -eq "pre-prod" ) {
            $nasDestinationPath = "$nasLocation\$Environment\$ProjectName\$($_.name)\$BuildNumber"

            Write-Host "Target environment is $Environment. Saving artifact into $nasDestinationPath for the production deployment."

            if( -Not(Test-Path $nasDestinationPath) ) {
                New-Item -ItemType Directory -Path $nasDestinationPath | out-null
            }

            Copy-Item -Path $publishPath\* -Destination "$nasDestinationPath\" -Force -Recurse
        }
    } else {
        Write-Host "No artifact found named '$appArtifactZipLocation' for '$($_.name)' named application and '$Environment' environment."
        exit 1
    }
}