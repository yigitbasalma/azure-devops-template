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
                if (-NOT([string]::IsNullOrEmpty($ExpectedString))) {
                    if ($response.Content -eq $ExpectedString) {
                        Write-Host "[$AppAddr/$Path] Application up and running."
                    } else {
                        raise "[Try $currentRetry][$AppAddr/$Path] Invalid response code found: $( $response.StatusCode ) with $( $response.Content )"
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
    if ( $package.healthcheck.enabled ) {
        Do-Healthcheck -AppAddr $package.iis.host -Path $package.healthcheck.path -ReturnCodes $package.healthcheck.returnCodes -ExpectedString $package.healthcheck.expectedString
    }
}