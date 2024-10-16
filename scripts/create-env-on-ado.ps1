param (
    [string]$ParentProjectName,
    [string]$ProjectName,
    [string]$PersonalAccessTokenB64,
    [string]$Environment
)

$successCodes = @(200, 201)
$url = "https://dev.azure.com/yigitbasalma/$ParentProjectName/_apis/pipelines/environments?api-version=7.2-preview.1"
$headers = @{
    "Authorization" = "Basic $PersonalAccessTokenB64"
    "Content-Type" = "application/json"
}

# Define the request body
$body = @{
    name = "$ProjectName-$Environment"
    description = "$ProjectName project servers for $Environment environment."
} | ConvertTo-Json

# Make the HTTP request
try {
    $response = Invoke-WebRequest -Uri $url -Method POST -Headers $headers -Body $body

    if ( $successCodes.Contains($response.StatusCode) ) {
        Write-Host "Resource created successfully."
    } else {
        Write-Host "Invalid response code found: $( $response.StatusCode ) with $( $response.Content )"
        exit 1
    }
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__

    if ($statusCode -eq 500) {
        Write-Host "Resource already exists. Skipping ..."
    } else {
        Write-Host "An error occurred: $( $_.Exception.Message )"
        exit 1
    }
}