#!/bin/bash
set -e
set -o pipefail

cat << EOF
MICROSOFT SOFTWARE LICENSE TERMS
MICROSOFT Azure Arc enabled Kubernetes
This software is licensed to you as part of your or your company's subscription license for Microsoft Azure Services. You may only use the software with Microsoft Azure Services and subject to the terms and conditions of the agreement under which you obtained Microsoft Azure Services. If you do not have an active subscription license for Microsoft Azure Services, you may not use the software. Microsoft Azure Legal Information: https://azure.microsoft.com/en-us/support/legal/
----------------------------------------------------------------------------------
EOF

echo "Starting onboarding process"

if [[ -z "${TENANT_ID}" ]]; then
  echo "ERROR: variable TENANT_ID is required."
  exit 1
fi

if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  echo "ERROR: variable SUBSCRIPTION_ID is required."
  exit 1
fi

if [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "ERROR: variable RESOURCE_GROUP is required."
  exit 1
fi

if [[ -z "${CONNECTED_CLUSTER}" ]]; then
  echo "ERROR: variable CONNECTED_CLUSTER is required."
  exit 1
fi

if [[ -z "${LOCATION}" ]]; then
  echo "ERROR: variable LOCATION is required."
  exit 1
fi

if [[ -z "${CLIENT_ID}" ]]; then
  echo "ERROR: variable CLIENT_ID is required."
  exit 1
fi

if [[ -z "${CLIENT_SECRET}" ]]; then
  echo "ERROR: variable CLIENT_SECRET is required."
  exit 1
fi

APISERVER=https://kubernetes.default.svc/
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt > ca.crt

echo "Azure login"
az login --service-principal \
  -u ${CLIENT_ID} \
  -p ${CLIENT_SECRET} \
  --tenant ${TENANT_ID}

az account set \
  --subscription ${SUBSCRIPTION_ID}

echo "Onboarding complete"

echo "Initilalizing Guard"
guard init ca

echo "Validating guard service"
GUARD_SERVICE="$(kubectl -n kube-system get services --field-selector metadata.name=guard -o jsonpath='{.items[*].spec.clusterIP}')"

if [ -z "$GUARD_SERVICE" ]; then
  kubectl create svc clusterip guard --tcp=433:8443 -n kube-system
  GUARD_SERVICE="$(kubectl -n kube-system get services --field-selector metadata.name=guard -o jsonpath='{.items[*].spec.clusterIP}')"
fi

guard init server --ips=$GUARD_SERVICE
guard init client -o Azure

#get arm id
ARM_ID=$(az connectedk8s show --resource-group $RESOURCE_GROUP -n $CONNECTED_CLUSTER --query "id")
ARM_ID=$(echo "$ARM_ID" | sed -e 's/^"//' -e 's/"$//')

guard get installer \
--auth-providers="Azure" \
--azure.auth-mode=obo \
--authz-providers="Azure" \
--azure.client-id=$CLIENT_ID \
--azure.client-secret=$CLIENT_SECRET \
--azure.tenant-id=$TENANT_ID \
--azure.graph-call-on-overage-claim=true \
--azure.authz-mode="arc"  \
--azure.resource-id=$ARM_ID \
--addr $GUARD_SERVICE:443 \
--azure.authz-resolve-group-memberships=false \
--authz-providers=azure > installer.yaml

kubectl apply -f installer.yaml

guard get webhook-config azure -o Azure --addr $GUARD_SERVICE:443  --mode authn > guard-authn-webhook.yaml
guard get webhook-config azure -o Azure --addr $GUARD_SERVICE:443  --mode authz > guard-authz-webhook.yaml


echo "Creating key vault"

az group create --name ${RESOURCE_GROUP} -l EastUS -o table

az keyvault create \
  --name ${RESOURCE_GROUP}-kv \
  --resource-group ${RESOURCE_GROUP} \
  --location ${LOCATION}


az keyvault secret set \
  --name guard-authn \
  --vault-name ${RESOURCE_GROUP}-kv \
  --file guard-authn-webhook.yaml

az keyvault secret set \
  --name guard-authz \
  --vault-name ${RESOURCE_GROUP}-kv \
  --file guard-authz-webhook.yaml


echo "Creating secrets for CSI driver"
kubectl create secret generic secrets-store-creds --from-literal clientid=$CLIENT_ID --from-literal clientsecret=$CLIENT_SECRET