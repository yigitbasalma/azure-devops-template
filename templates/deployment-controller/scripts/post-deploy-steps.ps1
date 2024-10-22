param (
    [string]$Packages
)

function Do-Healthcheck {
    param (
        [string]$AppAddr,
        [string]$Path,
        [string]$ReturnCodes,
        [string]$ExpectedString
    )

    $timeoutSec = 120
    $delaySec = 60
    $maxRetry = 5
    $currentRetry = 1
    $expectedReturnCodes = $ReturnCodes -split ","
    $headers = @{
        "User-Agent" = "Azure Devops Pipeline Health Check"
    }

    while ( $currentRetry -le $maxRetry ) {
        $response = Invoke-WebRequest -UseBasicParsing -Uri "http://$AppAddr/$Path" -Method GET -Headers $headers -TimeoutSec $timeoutSec

        try {
            if ( $successCodes.Contains($response.StatusCode)) {
                if ( $ExpectedString ) {
                    if ($response.Content -eq $ExpectedString) {
                        Write-Host "[$AppAddr/$Path] Application up and running."
                    } else {
                        raise "[Try $currentRetry][$AppAddr/$Path] Invalid response found: $( $response.StatusCode ) with $( $response.Content )"
                    }
                }
                Write-Host "[Try $currentRetry][$AppAddr/$Path] Application up and running."
            } else {
                raise "[Try $currentRetry][$AppAddr/$Path] Invalid response code found: $( $response.StatusCode ) with $( $response.Content )"
            }
        } catch {
            $currentRetry++
            Write-Host $_.Exception.Message
            Start-Sleep -Seconds $delaySec
        }
    }

    if ( $currentRetry -gt 1 ) {
        return $false
    }
}

foreach ( $package in $($Packages | ConvertFrom-Json) ) {
    if ( (Get-WebAppPoolState -Name "$($package.iis.poolName)").Value -eq "Started" ) {
        Write-Host "[$($package.iis.poolName)] The application pool is already started."
    } else {
        Start-WebAppPool -Name "$($package.iis.poolName)"
        while ( (Get-WebAppPoolState -Name "$($package.iis.poolName)").Value -ne "Started" ) {
            Write-Host "[$($package.iis.poolName)] Waiting for the application pool to start..."
            Start-Sleep -Seconds 30
        }
        Write-Host "[$($package.iis.poolName)] The application pool is now started."
    }

    if ( (Get-WebSite -Name "$($package.iis.name)").State -eq "Started" ) {
        Write-Host "[$($package.iis.name)] The website is already started."
    } else {
        Start-WebSite -Name "$($package.iis.name)"
        while ( (Get-WebSite -Name "$($package.iis.name)").State -ne "Started" ) {
            Write-Host "[$($package.iis.name)] Waiting for the website to start..."
            Start-Sleep -Seconds 30
        }
        Write-Host "[$($package.iis.name)] The website is now started."
    }

    if ( $package.healthcheck.enabled ) {
        Do-Healthcheck -AppAddr $package.iis.host -Path $package.healthcheck.path -ReturnCodes $package.healthcheck.returnCodes -ExpectedString $package.healthcheck.expectedString
    }
}