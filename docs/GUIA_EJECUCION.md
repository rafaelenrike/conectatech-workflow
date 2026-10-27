# Guía de ejecución

## 1. Preparar el repositorio

Copie el paquete a un repositorio nuevo, confirme que la rama principal se llama `main` y ajuste `sonar-project.properties`:

```properties
sonar.projectKey=clave-real-del-proyecto
sonar.projectName=Code to Cloud DevSecOps
```

Si usa SonarQube Cloud, agregue también `sonar.organization`. Si usa un servidor privado, los runners de GitHub deben poder alcanzarlo por red.

## 2. Verificar herramientas

```bash
chmod +x scripts/*.sh
./scripts/preflight.sh
```

Si falta la sesión de Azure:

```bash
az login
```

## 3. Crear backend y Service Principal

El sufijo debe ser globalmente único porque forma parte del nombre de ACR y de la cuenta de almacenamiento.

```bash
./scripts/bootstrap-azure.sh rafa26 eastus2
```

El script crea dos grupos de recursos, el backend de estado y un Service Principal con secreto de un año. Asigna `Contributor` y `User Access Administrator` solo al grupo del demo, más `Storage Blob Data Contributor` sobre la cuenta del estado.

Se generan tres archivos:

- `azure-credentials.json`: valor exacto para el secret `AZURE_CREDENTIALS`.
- `.azure-sp.env`: exports `ARM_*` para Terraform local.
- `github-variables.txt`: variables no secretas que debe crear en GitHub.

Los dos archivos con credenciales están excluidos por `.gitignore`. No los copie al repositorio, chat ni capturas.

## 4. Configurar GitHub manualmente

Abra **Settings > Secrets and variables > Actions**.

En **Secrets**, cree:

- `AZURE_CREDENTIALS`: pegue todo el JSON de `azure-credentials.json`.
- `SONAR_TOKEN`: token del proyecto SonarQube.

En **Variables**, cree cada par nombre/valor de `github-variables.txt` y además:

- `SONAR_HOST_URL`: por ejemplo `https://sonarqube.example.com`.

El JSON debe conservar estas cuatro claves:

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

El paso de SonarQube se omite explícitamente si falta token o URL. Esto permite preparar el resto del taller sin esconder un fallo de configuración.

## 5. Probar Terraform local

```bash
source .azure-sp.env
terraform -chdir=infra init \
  -backend-config="resource_group_name=${TFSTATE_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TFSTATE_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TFSTATE_CONTAINER}" \
  -backend-config="key=code-to-cloud.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform -chdir=infra validate
terraform -chdir=infra plan
```

Terraform toma `client_id`, `client_secret`, `tenant_id` y `subscription_id` de las cuatro variables `ARM_*`. No las escriba en archivos `.tf` ni `.tfvars`.

## 6. Ejecutar la aplicación local

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install ".[dev]"
ruff check .
pytest
./scripts/demo-local.sh
```

Valide:

```bash
curl http://localhost:8080/health
```

## 7. Mostrar CI y seguridad

Cree una rama `demo-change`, cambie el mensaje visible de `app/main.py`, haga commit y abra un pull request. Recorra los dos jobs:

1. Ruff y pruebas con cobertura.
2. SonarQube SAST.
3. Build de la imagen.
4. Trivy sobre la imagen.
5. Formato de Terraform.
6. Checkov sobre `infra/`.

Para enseñar un fallo sin improvisar, cambie temporalmente el umbral de cobertura o introduzca un error en un test. Revierta el cambio antes del merge.

## 8. Crear infraestructura

En **Actions**, elija **Provision Azure infrastructure**, pulse **Run workflow** y deje `apply=false` para mostrar solo el plan. Después de revisarlo, repita con `apply=true` o muestre la ejecución preparada.

El workflow lee `AZURE_CREDENTIALS`, autentica Azure Login y expone sus cuatro campos como `ARM_*` para el provider y el backend de Terraform.

Los recursos principales son:

- Azure Container Registry con acceso administrativo desactivado.
- Identidad administrada con permiso `AcrPull`.
- Azure Container Apps Environment.
- Container App con ingreso HTTPS y escalado 0–1.
- Log Analytics Workspace.

## 9. Desplegar

Ejecute **Deploy application** manualmente para el primer despliegue. El workflow:

1. Recupera exactamente el commit aprobado.
2. Inicia sesión en Azure con `AZURE_CREDENTIALS`.
3. Construye la imagen con el SHA como versión.
4. Ejecuta el gate de Trivy.
5. Publica en ACR.
6. Actualiza Container Apps.
7. Ejecuta un smoke test contra `/health`.

Después del primer despliegue, cada CI exitoso en `main` inicia CD automáticamente.

## 10. Verificar y explicar rollback

En Azure Portal, abra **Container App > Revision management**. Una nueva imagen crea una revisión. Para recuperar una versión anterior, reasigne el tráfico a una revisión sana o ejecute de nuevo el workflow con una etiqueta conocida.

```bash
curl https://URL_DE_LA_APP/health
```

## 11. Eliminar recursos

```bash
source .azure-sp.env
./scripts/destroy.sh rafa26
```

Después revise y elimine manualmente los grupos `rg-code-to-cloud-demo`, `rg-code-to-cloud-state` y el Service Principal si ya no se usarán. Borre también los dos archivos locales con credenciales cuando termine.

## Problemas frecuentes

| Síntoma | Causa probable | Acción |
|---|---|---|
| Azure Login informa `AADSTS7000215` | Secreto inválido o vencido | Rote la credencial y reemplace `AZURE_CREDENTIALS` y `.azure-sp.env` |
| GitHub indica que el JSON no es válido | Secret incompleto o comillas alteradas | Pegue nuevamente el archivo completo, sin texto adicional |
| Terraform no abre el estado | Falta `Storage Blob Data Contributor` | Revise la asignación sobre la cuenta de almacenamiento |
| SonarQube se omite | Falta token o URL | Revise secret y variable, sin imprimir el token |
| Trivy bloquea la imagen base | Paquete con vulnerabilidad corregible | Actualice la imagen base y reconstruya |
| Container App no puede descargar | Falta `AcrPull` o la identidad | Revise la identidad y el registry block de Terraform |
| El smoke test falla al inicio | La nueva revisión aún arranca | Espere los seis reintentos y revise logs de la revisión |
