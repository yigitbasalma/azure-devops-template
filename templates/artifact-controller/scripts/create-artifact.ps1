param (
    [string]$Environment,
    [string]$Packages
)

Write-Host $Packages

$($Packages | ConvertFrom-Json) | ForEach-Object {
    Write-Host $_.name
}