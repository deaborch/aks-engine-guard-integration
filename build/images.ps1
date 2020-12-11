$baseDir = Split-Path $PSScriptRoot
$image = "$baseDir\image"
Set-Location $image

docker build -t delanyo32/azure-guard .
docker push delanyo32/azure-guard

Set-Location $baseDir