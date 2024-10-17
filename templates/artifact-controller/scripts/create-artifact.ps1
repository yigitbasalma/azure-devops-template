param (
    [string]$Environment,
    [string]$Packages
)

$($Packages | ConvertFrom-Json) | ForEach-Object {
    Write-Host $_.name
}