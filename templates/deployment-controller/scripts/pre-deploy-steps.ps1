param (
    [string]$Environment,
    [string]$Packages,
    [string]$AgentBuildPath,
    [string]$BuildNumber
)

$IISManagerCommand = "C:\Windows\system32\inetsrv\appcmd"

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    # Stop app pool
    & $IISManagerCommand stop apppool /apppool.name="$($package.iis.poolName)"
}

exit 0