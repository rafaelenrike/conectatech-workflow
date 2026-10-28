#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 SUFIJO_UNICO"
  exit 2
fi

name_suffix="$1"

if [[ -f .azure-sp.env ]]; then
  # Archivo local generado por bootstrap-azure.sh; nunca debe versionarse.
  source .azure-sp.env
fi

required_env=(ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_SUBSCRIPTION_ID)
for variable_name in "${required_env[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "FALTA  ${variable_name}. Ejecute el bootstrap o exporte las cuatro variables ARM_* antes de continuar."
    exit 1
  fi
done

read -r -p "Esto destruirá los recursos administrados por Terraform. Escriba DESTROY: " confirmation
if [[ "${confirmation}" != "DESTROY" ]]; then
  echo "Cancelado."
  exit 1
fi

terraform -chdir=infra init \
  -backend-config="resource_group_name=rg-code-to-cloud-state" \
  -backend-config="storage_account_name=stctc${name_suffix}" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=code-to-cloud.tfstate" \
  -backend-config="use_azuread_auth=true"

terraform -chdir=infra destroy \
  -var="resource_group_name=rg-code-to-cloud-demo" \
  -var="name_suffix=${name_suffix}"
