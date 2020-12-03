$baseDir = Split-Path $PSScriptRoot
$workingDir = "$baseDir\helm"
Set-Location $workingDir

$TENANT_ID=""
$SUBSCRIPTION_ID=""
$RESOURCE_GROUP=""
$CONNECTED_CLUSTER=""
$LOCATION=""
$CLIENT_ID=""
$CLIENT_SECRET=""

helm install --debug --dry-run azure-guard  . `
--set tenantId=$TENANT_ID `
--set subscriptionId=$SUBSCRIPTION_ID `
--set resourceGroup=$RESOURCE_GROUP `
--set location=$LOCATION `
--set connectedCluster=$CONNECTED_CLUSTER `
--set clientId=$CLIENT_ID `
--set clientSecret=$CLIENT_SECRET 