# Code to Cloud: DevSecOps

Paquete de demostración para un workshop unilateral de máximo dos horas. El recorrido parte de una aplicación FastAPI, ejecuta controles de calidad y seguridad en GitHub Actions, crea infraestructura con Terraform y publica una imagen en Azure Container Apps.

## Qué contiene

- Aplicación pequeña con endpoints `/` y `/health`.
- Pruebas, cobertura y linting.
- Imagen Docker multi-stage que se ejecuta con usuario sin privilegios.
- Terraform para Azure Container Registry, Container Apps, identidad administrada y observabilidad básica.
- CI con SonarQube, Checkov y Trivy.
- Automatización de Azure mediante un Service Principal y el secreto `AZURE_CREDENTIALS`.
- Guion del instructor, agenda exacta y listas de preparación.

## Arquitectura resumida

```text
Git push / pull request
          |
          v
GitHub Actions CI
  tests + Ruff + SonarQube + Checkov + Docker + Trivy
          |
          v  solo si pasa el pipeline en main
Azure Container Registry
          |
          v  identidad administrada con AcrPull
Azure Container Apps  --->  /health
```

Terraform guarda su estado en un contenedor privado de Azure Storage. Los workflows usan un Service Principal cuyo JSON se almacena como `AZURE_CREDENTIALS`. Para operaciones locales, el mismo principal se expone mediante `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` y `ARM_SUBSCRIPTION_ID`.

## Inicio rápido local

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install ".[dev]"
pytest
ruff check .
./scripts/demo-local.sh
```

Abra <http://localhost:8080> y <http://localhost:8080/health>.

## Puesta en marcha completa

1. Cree un repositorio en GitHub y copie este contenido.
2. Ajuste `sonar-project.properties` con la clave real del proyecto.
3. Ejecute `./scripts/preflight.sh` e inicie sesión con `az login`.
4. Ejecute `./scripts/bootstrap-azure.sh sufijo eastus2`.
5. En **Settings > Secrets and variables > Actions**, cree el secret `AZURE_CREDENTIALS` pegando el contenido de `azure-credentials.json`.
6. Cree manualmente las variables listadas en `github-variables.txt`.
7. Agregue el secret `SONAR_TOKEN` y la variable `SONAR_HOST_URL`.
8. Haga push a `main` y confirme que **CI and security** termina correctamente.
9. Ejecute **Provision Azure infrastructure** con `apply=true`.
10. Ejecute **Deploy application**. En cambios posteriores, el despliegue se activa después de un CI exitoso en `main`.

La guía detallada está en [docs/GUIA_EJECUCION.md](docs/GUIA_EJECUCION.md). El guion minuto a minuto está en [docs/GUION_INSTRUCTOR.md](docs/GUION_INSTRUCTOR.md).

## Variables y secretos de GitHub

El bootstrap genera dos archivos locales protegidos y un listado de variables. No los publique ni los adjunte a evidencias del taller.

| Tipo | Nombre | Uso |
|---|---|---|
| Secret | `AZURE_CREDENTIALS` | JSON con `clientId`, `clientSecret`, `tenantId` y `subscriptionId` |
| Secret | `SONAR_TOKEN` | Token de análisis SonarQube |
| Variable | `SONAR_HOST_URL` | URL del servidor SonarQube |
| Variable | `AZURE_RESOURCE_GROUP` | Grupo de recursos del demo |
| Variable | `AZURE_LOCATION` | Región de Azure |
| Variable | `TFSTATE_RESOURCE_GROUP` | Grupo del backend de Terraform |
| Variable | `TFSTATE_STORAGE_ACCOUNT` | Cuenta del backend de Terraform |
| Variable | `TFSTATE_CONTAINER` | Contenedor del estado |
| Variable | `TF_NAME_SUFFIX` | Sufijo globalmente único |
| Variable | `ACR_NAME` | Nombre de Azure Container Registry |
| Variable | `AZURE_CONTAINER_APP_NAME` | Nombre de Azure Container App |

## Terraform local con variables ARM

El bootstrap genera `.azure-sp.env` con permisos de archivo restringidos:

```bash
source .azure-sp.env
terraform -chdir=infra init \
  -backend-config="resource_group_name=${TFSTATE_RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${TFSTATE_STORAGE_ACCOUNT}" \
  -backend-config="container_name=${TFSTATE_CONTAINER}" \
  -backend-config="key=code-to-cloud.tfstate" \
  -backend-config="use_azuread_auth=true"
terraform -chdir=infra plan
```

## Decisiones de seguridad que conviene explicar

- El secreto de Azure se concentra en `AZURE_CREDENTIALS`, se oculta en logs y se rota al menos anualmente.
- El principal tiene alcance de grupo de recursos y acceso de datos solo a la cuenta del estado.
- El registro mantiene `admin_enabled = false`.
- Container Apps descarga la imagen con una identidad administrada y el rol `AcrPull`.
- Trivy bloquea vulnerabilidades `HIGH` y `CRITICAL` con solución disponible.
- Checkov bloquea configuraciones IaC incumplidas.
- Cada workflow declara únicamente `contents: read` para el token de GitHub.
- La imagen corre con UID/GID `10001` y expone solo el puerto 8080.

Para producción, almacene y rote el secreto en un gestor corporativo, reduzca aún más los roles, use endpoints privados para ACR y el backend, fije las acciones a SHA completos, aplique retención y bloqueo al estado, y exija aprobación en el environment `production`.

## Limpieza

```bash
source .azure-sp.env
./scripts/destroy.sh sufijo
```

El script destruye lo administrado por Terraform después de pedir confirmación. Los grupos de recursos, el backend y el Service Principal se revisan y eliminan manualmente cuando ya no sean necesarios.

## Referencias

- [Azure Login](https://github.com/Azure/login)
- [Service Principal para Terraform en Azure](https://learn.microsoft.com/azure/developer/terraform/authenticate-to-azure-with-service-principle)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Terraform en GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [SonarQube Scan Action](https://github.com/SonarSource/sonarqube-scan-action)
- [Checkov Action](https://github.com/bridgecrewio/checkov-action)
- [Trivy Action](https://github.com/aquasecurity/trivy-action)
