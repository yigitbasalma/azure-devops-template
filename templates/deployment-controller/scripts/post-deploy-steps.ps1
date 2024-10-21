param (
    [string]$Packages
)

function Do-Healthcheck {
    param (
        [string]$Host,
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

    while ( $currentRetry -gt $maxRetry ) {
        $response = Invoke-WebRequest -Uri "$Host/$Path" -Method GET -Headers $headers -TimeoutSec $timeoutSec

        try {
            if ( $successCodes.Contains($response.StatusCode)) {
                if (-NOT([string]::IsNullOrEmpty($ExpectedString))) {
                    if ($response.Content -eq $ExpectedString) {
                        Write-Host "[$Host/$Path] Application up and running."
                    } else {
                        raise "[Try $currentRetry][$Host/$Path] Invalid response code found: $( $response.StatusCode ) with $( $response.Content )"
                    }
                }
                Write-Host "[Try $currentRetry][$Host/$Path] Application up and running."
            } else {
                raise "[Try $currentRetry][$Host/$Path] Invalid response code found: $( $response.StatusCode ) with $( $response.Content )"
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
    # Healthchecks
}