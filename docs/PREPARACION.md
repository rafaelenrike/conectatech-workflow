# Preparación previa

## Requisitos del instructor

- Cuenta de GitHub con permiso para Actions, secrets, variables y environments.
- Suscripción de Azure donde pueda crear grupos de recursos, aplicaciones de Entra y asignaciones de rol.
- Permiso para crear un Service Principal y credenciales de aplicación.
- SonarQube Server accesible desde runners alojados por GitHub, o un runner propio si la instancia es privada.
- Git, Docker Desktop o Docker Engine, Azure CLI, Terraform y Python 3.
- Navegador con sesiones iniciadas en GitHub, Azure Portal y SonarQube.
- Red estable y posibilidad de compartir pantalla a 1920×1080.

## 48 a 24 horas antes

- [ ] Crear el repositorio y proteger `main` con el workflow de CI como check requerido.
- [ ] Crear el environment `production`. Activar aprobación si hay otra persona disponible.
- [ ] Ejecutar `scripts/bootstrap-azure.sh` con un sufijo único.
- [ ] Copiar `azure-credentials.json` al secret `AZURE_CREDENTIALS`.
- [ ] Crear manualmente las variables indicadas en `github-variables.txt`.
- [ ] Configurar `SONAR_TOKEN`, `SONAR_HOST_URL` y la clave del proyecto.
- [ ] Registrar propietario y fecha de rotación del secreto del Service Principal.
- [ ] Ejecutar los tres workflows al menos una vez.
- [ ] Confirmar que la URL pública y `/health` responden.
- [ ] Descargar o conservar capturas de una ejecución exitosa y una fallida.
- [ ] Verificar límites, créditos y políticas de la suscripción de Azure.
- [ ] Preparar una rama `demo-change` con un cambio pequeño en el texto de la página.

## Una hora antes

- [ ] Ejecutar `scripts/preflight.sh`.
- [ ] Confirmar que Docker está iniciado.
- [ ] Ejecutar `source .azure-sp.env` y comprobar `terraform -chdir=infra validate`.
- [ ] Abrir las pestañas: repositorio, Actions, SonarQube, Azure Portal y aplicación.
- [ ] Ejecutar `pytest` y `terraform -chdir=infra fmt -check -recursive`.
- [ ] Revisar que ningún secreto sea visible en el terminal, archivos abiertos o historial de comandos.
- [ ] Aumentar el tamaño de fuente del terminal y navegador.
- [ ] Desactivar notificaciones del sistema.
- [ ] Dejar la presentación en modo exposición.

## Plan B sin red

- [ ] Mantener la imagen Docker construida localmente.
- [ ] Conservar la salida de `terraform plan` en una captura o texto sin valores sensibles.
- [ ] Conservar capturas de los cuatro controles de CI y del deployment.
- [ ] Mantener abierta la última URL desplegada.
- [ ] Tener el repositorio clonado y la presentación disponibles sin conexión.

## Valores que nunca deben mostrarse

- `SONAR_TOKEN`.
- `clientSecret` del Service Principal.
- Contenido de `AZURE_CREDENTIALS`, `azure-credentials.json` o `.azure-sp.env`.
- Tokens de sesión de Azure CLI.
- Datos personales o recursos de otras suscripciones.

## Después del workshop

- [ ] Destruir los recursos administrados por Terraform.
- [ ] Eliminar los grupos de recursos del demo y del estado si no se reutilizarán.
- [ ] Eliminar el Service Principal o rotar inmediatamente su secreto.
- [ ] Borrar `azure-credentials.json` y `.azure-sp.env` de los equipos usados para la demostración.
