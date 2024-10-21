param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

function Take-Backup {
    param (
        [string]$SiteName,
        [string]$BackupRootPath
    )

    $tempDir = "C:\BackupTemp"
    $backupPath = "$BackupRootPath\$SiteName"
    $backupName = "$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $iisWebsitePath = Get-WebFilePath "IIS:\Sites\$SiteName"

    if ( Test-Path $tempDir ) {
        Remove-Item -Path $tempDir -Recurse -Force | out-null
    } else {
        New-Item -ItemType "directory" -Path $tempDir | out-null
    }

    if ( -NOT(Test-Path $BackupPath) ) {
        New-Item -ItemType "directory" -Path $BackupPath | out-null
    }

    & robocopy $iisWebsitePath.FullName $tempDir /MIR /XF UmbracoTraceLog* /XD *cache* /NFL /NDL /NJH /NJS

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir,"$backupPath\$backupName")

    Remove-Item -Path $tempDir -Recurse -Force

    Write-Host "[$backupName] Backup procedure completed for the $SiteName."
}

function Do-Retention-Policy {
    param (
        [string]$SiteName,
        [string]$BackupRootPath,
        [int]$Retention
    )

    $backupPath = "$BackupRootPath\$SiteName"
    $objects = Get-ChildItem -Path $backupPath | Sort-Object -Descending -Property LastWriteTime | select -Skip $Retention

    $objects | ForEach-Object {
        $oldBackup = "$BackupRootPath\$($_.Name)"
        Remove-Item -Path $oldBackup -Recurse -Force | out-null
        Write-Host "[$oldBackup] Old backup file removed."
    }
}

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

    if ( $package.backup.enabled ) {
        Take-Backup -SiteName $package.iis.name -BackupRootPath $package.backup.path

        if ( $package.backup.retention -gt 0 ) {
            Do-Retention-Policy -SiteName $package.iis.name -BackupRootPath $package.backup.path -Retention $package.backup.retention
        }
    }
}

exit 0