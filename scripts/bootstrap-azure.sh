#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: $0 SUFIJO_UNICO [REGION]"
  echo "Ejemplo: $0 rafa26 eastus2"
  exit 2
fi

name_suffix="$1"
location="${2:-eastus2}"

if [[ ! "${name_suffix}" =~ ^[a-z0-9]{4,10}$ ]]; then
  echo "El sufijo debe contener de 4 a 10 letras minúsculas o números."
  exit 2
fi

subscription_id=$(az account show --query id -o tsv)
tenant_id=$(az account show --query tenantId -o tsv)
state_rg="rg-code-to-cloud-state"
demo_rg="rg-code-to-cloud-demo"
storage_account="stctc${name_suffix}"
state_container="tfstate"
service_principal_name="sp-code-to-cloud-${name_suffix}"
acr_name="acrctc${name_suffix}"
container_app_name="ca-code-to-cloud-${name_suffix}"
credentials_file="azure-credentials.json"
local_env_file=".azure-sp.env"
variables_file="github-variables.txt"

echo "Creando grupos de recursos y backend remoto..."
az group create --name "${state_rg}" --location "${location}" --output none
az group create --name "${demo_rg}" --location "${location}" --output none
az storage account create \
  --name "${storage_account}" \
  --resource-group "${state_rg}" \
  --location "${location}" \
  --sku Standard_LRS \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --output none
az storage container create \
  --name "${state_container}" \
  --account-name "${storage_account}" \
  --auth-mode key \
  --output none

if [[ -n "$(az ad sp list --display-name "${service_principal_name}" --query '[0].appId' -o tsv)" ]]; then
  echo "Ya existe ${service_principal_name}. Use otro sufijo o elimine esa identidad antes de repetir."
  exit 1
fi

demo_scope="/subscriptions/${subscription_id}/resourceGroups/${demo_rg}"
state_scope="/subscriptions/${subscription_id}/resourceGroups/${state_rg}/providers/Microsoft.Storage/storageAccounts/${storage_account}"

echo "Creando Service Principal con alcance limitado al grupo del demo..."
sp_json=$(az ad sp create-for-rbac \
  --name "${service_principal_name}" \
  --role Contributor \
  --scopes "${demo_scope}" \
  --years 1 \
  --output json)

client_id=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["appId"])' <<< "${sp_json}")
client_secret=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])' <<< "${sp_json}")
created_tenant_id=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["tenant"])' <<< "${sp_json}")

if [[ "${created_tenant_id}" != "${tenant_id}" ]]; then
  echo "El tenant devuelto no coincide con la sesión actual. No se generaron archivos locales."
  exit 1
fi

echo "Asignando permisos para crear el rol AcrPull y acceder al estado..."
az role assignment create \
  --assignee "${client_id}" \
  --role "User Access Administrator" \
  --scope "${demo_scope}" \
  --output none
az role assignment create \
  --assignee "${client_id}" \
  --role "Storage Blob Data Contributor" \
  --scope "${state_scope}" \
  --output none

CREDENTIALS_FILE="${credentials_file}" \
LOCAL_ENV_FILE="${local_env_file}" \
VARIABLES_FILE="${variables_file}" \
CLIENT_ID="${client_id}" \
CLIENT_SECRET="${client_secret}" \
TENANT_ID="${tenant_id}" \
SUBSCRIPTION_ID="${subscription_id}" \
DEMO_RG="${demo_rg}" \
STATE_RG="${state_rg}" \
STORAGE_ACCOUNT="${storage_account}" \
STATE_CONTAINER="${state_container}" \
NAME_SUFFIX="${name_suffix}" \
LOCATION="${location}" \
ACR_NAME="${acr_name}" \
CONTAINER_APP_NAME="${container_app_name}" \
python3 <<'PY'
import json
import os
import pathlib
import shlex

credentials = {
    "clientId": os.environ["CLIENT_ID"],
    "clientSecret": os.environ["CLIENT_SECRET"],
    "subscriptionId": os.environ["SUBSCRIPTION_ID"],
    "tenantId": os.environ["TENANT_ID"],
}
pathlib.Path(os.environ["CREDENTIALS_FILE"]).write_text(
    json.dumps(credentials, indent=2) + "\n", encoding="utf-8"
)

local_values = {
    "ARM_CLIENT_ID": os.environ["CLIENT_ID"],
    "ARM_CLIENT_SECRET": os.environ["CLIENT_SECRET"],
    "ARM_TENANT_ID": os.environ["TENANT_ID"],
    "ARM_SUBSCRIPTION_ID": os.environ["SUBSCRIPTION_ID"],
    "TF_VAR_resource_group_name": os.environ["DEMO_RG"],
    "TF_VAR_name_suffix": os.environ["NAME_SUFFIX"],
    "TFSTATE_RESOURCE_GROUP": os.environ["STATE_RG"],
    "TFSTATE_STORAGE_ACCOUNT": os.environ["STORAGE_ACCOUNT"],
    "TFSTATE_CONTAINER": os.environ["STATE_CONTAINER"],
}
env_text = "".join(
    f"export {key}={shlex.quote(value)}\n" for key, value in local_values.items()
)
pathlib.Path(os.environ["LOCAL_ENV_FILE"]).write_text(env_text, encoding="utf-8")

github_values = {
    "AZURE_RESOURCE_GROUP": os.environ["DEMO_RG"],
    "AZURE_LOCATION": os.environ["LOCATION"],
    "TFSTATE_RESOURCE_GROUP": os.environ["STATE_RG"],
    "TFSTATE_STORAGE_ACCOUNT": os.environ["STORAGE_ACCOUNT"],
    "TFSTATE_CONTAINER": os.environ["STATE_CONTAINER"],
    "TF_NAME_SUFFIX": os.environ["NAME_SUFFIX"],
    "ACR_NAME": os.environ["ACR_NAME"],
    "AZURE_CONTAINER_APP_NAME": os.environ["CONTAINER_APP_NAME"],
}
variables_text = "".join(f"{key}={value}\n" for key, value in github_values.items())
pathlib.Path(os.environ["VARIABLES_FILE"]).write_text(variables_text, encoding="utf-8")
PY

chmod 600 "${credentials_file}" "${local_env_file}"

echo "Bootstrap completado."
echo "1. Copie el contenido de ${credentials_file} al secret AZURE_CREDENTIALS de GitHub."
echo "2. Cree manualmente las variables listadas en ${variables_file}."
echo "3. Para Terraform local ejecute: source ${local_env_file}"
echo "4. Configure SONAR_TOKEN y SONAR_HOST_URL en GitHub."
echo "Proteja los dos archivos con credenciales; ya están excluidos por .gitignore."
