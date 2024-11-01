param (
    [string]$ParentProjectName,
    [string]$ProjectName,
    [string]$PersonalAccessTokenB64,
    [string]$Environment
)

$vServers = @()
$environmentName = "$ProjectName-$Environment"
$url = "https://dev.azure.com/yigitbasalma/$ParentProjectName/_apis/pipelines/environments"
$headers = @{
    "Authorization" = "Basic $PersonalAccessTokenB64"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "$($url)?api-version=7.2-preview.1" -Method Get -Headers $headers

[string]$environmentId
$response.value | ForEach-Object {
    if ( $_.name -eq $environmentName ) {
        $environmentId = $_.id
    }
}

$response = Invoke-RestMethod -Uri "$url/$environmentId/providers/virtualmachines?api-version=7.2-preview.1" -Method Get -Headers $headers

$response.value | ForEach-Object {
    $server = [PSCustomObject]@{
        Name         = $_.name
        IP           = (Resolve-DnsName -Name $_.name | Where-Object { $_.QueryType -eq "A" }).IPAddress
        Tags         = $_.tags
    }
    $vServers += $server
}

# Set global variable to use after
$vServersToJson = $vServers | ConvertTo-Json -Compress
Write-Host "##vso[task.setvariable variable=VServers;isOutput=true]$vServersToJson"