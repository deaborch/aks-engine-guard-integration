$baseDir = Split-Path $PSScriptRoot
$daemonsetDir = "$baseDir\images\daemonset"
$jobDir = "$baseDir\images\job"
Set-Location $daemonsetDir

docker build -t delanyo32/master-config .
docker push delanyo32/master-config

Set-Location $jobDir

docker build -t delanyo32/guard-onboarding .
docker push delanyo32/guard-onboarding  

Set-Location $baseDir
