$baseDir = Split-Path $PSScriptRoot
$workingDir = "$baseDir\charts\"
Set-Location $workingDir

helm package azure-guard\

helm repo index azure-guard --url https://deaborch.github.io/aks-engine-guard-integration