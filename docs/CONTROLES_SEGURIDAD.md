# Controles de seguridad del demo

| Control | Superficie | Momento | Comportamiento del pipeline |
|---|---|---|---|
| SonarQube | Código Python | CI | Publica análisis SAST; requiere token y URL |
| Checkov | Terraform | CI | Falla ante políticas incumplidas |
| Trivy | Imagen final | CI y CD | Bloquea vulnerabilidades HIGH/CRITICAL con corrección disponible |
| Ruff y pytest | Código y comportamiento | CI | Bloquean errores básicos y cobertura menor a 85% |
| Service Principal | Identidad de automatización | Infra y CD | Autentica con `AZURE_CREDENTIALS` y Azure RBAC |
| Identidad administrada | Pull desde ACR | Runtime | Evita usuario y contraseña del registro |
| Permisos mínimos | Token de GitHub | Todos | Cada workflow declara únicamente `contents: read` |

## Tratamiento del secreto de Azure

- `AZURE_CREDENTIALS` contiene `clientId`, `clientSecret`, `tenantId` y `subscriptionId`.
- El valor se configura manualmente como secret de Actions y nunca se imprime.
- El bootstrap genera `azure-credentials.json` y `.azure-sp.env` con permisos `600`; ambos están excluidos de Git.
- La credencial se crea con vigencia de un año. Registre propietario y fecha de rotación.
- El alcance del principal se limita al grupo del demo y a la cuenta de almacenamiento del estado.

## Límites deliberados

El registro conserva acceso de red pública para que un runner alojado por GitHub pueda publicar la imagen. El control administrativo permanece deshabilitado y el acceso requiere Azure RBAC. En producción conviene usar un runner dentro de la red, Private Link y políticas de salida.

Las acciones están fijadas por versión mayor o versión exacta para mantener legible el workshop. En un entorno regulado, fije cada acción a un SHA completo y automatice sus actualizaciones.

Checkov aplica su conjunto vigente de reglas. `.checkov.yml` documenta las excepciones del demo para ACR Basic: red pública requerida por runners alojados, una sola región y funciones empresariales fuera del alcance. Trivy compensa explícitamente el análisis de vulnerabilidades antes del push. En producción, cada excepción necesita propietario, fecha de revisión y una medida compensatoria verificable.
