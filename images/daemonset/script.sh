#!/bin/bash
set -e
set -o pipefail

cat << EOF
MICROSOFT SOFTWARE LICENSE TERMS
MICROSOFT Azure Arc enabled Kubernetes
This software is licensed to you as part of your or your company's subscription license for Microsoft Azure Services. You may only use the software with Microsoft Azure Services and subject to the terms and conditions of the agreement under which you obtained Microsoft Azure Services. If you do not have an active subscription license for Microsoft Azure Services, you may not use the software. Microsoft Azure Legal Information: https://azure.microsoft.com/en-us/support/legal/
----------------------------------------------------------------------------------
EOF

echo "Starting configuration process"

if [[ -z "${TENANT_ID}" ]]; then
  echo "ERROR: variable TENANT_ID is required."
  exit 1
fi

if [[ -z "${RESOURCE_GROUP}" ]]; then
  echo "ERROR: variable RESOURCE_GROUP is required."
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

echo "Azure login"
az login --service-principal \
  -u ${CLIENT_ID} \
  -p ${CLIENT_SECRET} \
  --tenant ${TENANT_ID}

rm -rf /etc/kubernetes/guard

mkdir -p /etc/kubernetes/guard

cd /etc/kubernetes/guard

echo "Downloading guard configs"
az keyvault secret download \
  --name guard-authn \
  --vault-name ${RESOURCE_GROUP}-kv \
  --file guard-authn-webhook.yaml

az keyvault secret download \
  --name guard-authz \
  --vault-name ${RESOURCE_GROUP}-kv \
  --file guard-authz-webhook.yaml

echo "Modifying api-server"
APIMODEL="/etc/kubernetes/manifests/kube-apiserver.yaml"

sed -i 's/Node,RBAC/Node,Webhook,RBAC/' $APIMODEL
sed -i 's|args: \["|args: \["--authorization-webhook-cache-authorized-ttl=5m0s","--authentication-token-webhook-cache-ttl=5m0s","--authentication-token-webhook-config-file=/etc/kubernetes/guard/guard-authn-webhook.yaml", "--authorization-webhook-config-file=/etc/kubernetes/guard/guard-authz-webhook.yaml", "--runtime-config=authentication.k8s.io/v1beta1=true,authorization.k8s.io/v1beta1=true", "|g' $APIMODEL

sleep 30m
