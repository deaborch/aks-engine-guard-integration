$baseDir = Split-Path $PSScriptRoot
$workingDir = "$baseDir\charts\"
Set-Location $workingDir

helm package guard-intergration\

helm repo index guard-intergration --url https://deaborch.github.io/aks-engine-guard-integration