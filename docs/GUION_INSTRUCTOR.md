# Guion del instructor

## Antes de empezar

Deje abiertas cinco pestañas en este orden: presentación, repositorio, ejecución de CI preparada, Azure Portal y aplicación desplegada. Mantenga un terminal en la raíz del repositorio.

## 00–05. Apertura

Mensaje: el objetivo no consiste en memorizar herramientas. El público verá cómo una sola modificación recorre controles automáticos hasta convertirse en una revisión observable en Azure.

Muestre la URL final durante diez segundos. Así el público conoce el destino antes de entrar en los componentes.

## 05–25. Conceptos

Use la presentación. Conecte cada concepto con un archivo que aparecerá después:

- GitHub conserva la historia y activa eventos.
- Terraform expresa el estado deseado de la infraestructura.
- Docker empaqueta la aplicación y su entorno de ejecución.
- GitHub Actions orquesta controles y despliegues.
- DevSecOps coloca decisiones verificables antes de producción.

No abra todavía el portal ni el código.

## 25–35. Arquitectura

Abra el árbol del repositorio. Recorra `app/`, `tests/`, `infra/`, `.github/workflows/` y `scripts/`. Relacione los tres workflows con el mapa de la presentación.

Frase de transición: “Ahora seguiremos el mismo commit durante todo el recorrido”.

## 35–50. Aplicación y contenedor

1. Abra `app/main.py` y explique `/health`.
2. Ejecute `pytest` y señale la cobertura.
3. Abra el `Dockerfile`: multi-stage, usuario no root y healthcheck.
4. Ejecute `scripts/demo-local.sh`.
5. Abra la página y consulte `/health`.

Si el build tarda más de tres minutos, use la imagen preparada y continúe.

## 50–75. CI y controles

Abra el pull request preparado. Muestre la secuencia del workflow y entre solo en las líneas de salida que prueban cada control.

Para SonarQube, muestre un hallazgo o el Quality Gate del proyecto. Para Checkov, identifique el archivo y la regla. Para Trivy, explique que inspecciona el sistema operativo y las dependencias presentes en la imagen final.

Opcional: muestre una ejecución fallida ya guardada. No introduzca un fallo nuevo si el tiempo supera el minuto 68.

## 75–95. Terraform y Azure

Abra primero el workflow de infraestructura y señale `AZURE_CREDENTIALS` y las cuatro variables `ARM_*`. Explique que el Service Principal está limitado al grupo del demo y que el secreto exige custodia y rotación. Luego abra `infra/main.tf` y señale cuatro relaciones: Container App Environment, ACR, identidad administrada y rol `AcrPull`. Muestre el plan preparado y los recursos en Azure Portal.

Evite esperar un `apply` completo frente al público. Si lo ejecuta, mantenga la explicación activa y cambie a la ejecución preparada después de cinco minutos.

## 95–110. Despliegue

Ejecute **Deploy application**. Mientras corre, explique cómo Azure Login consume `AZURE_CREDENTIALS`, por qué `contents: read` es suficiente para el token de GitHub y cómo Trivy actúa como gate antes del push. Al terminar, abra la URL y `/health`; compare el SHA mostrado con el commit de GitHub.

## 110–118. Diagnóstico y rollback

Muestre dónde encontrar logs de la revisión y cómo ver revisiones anteriores. Explique que una entrega segura necesita una salida conocida cuando el cambio falla.

## 118–120. Cierre

Comparta el repositorio. Recomiende esta ruta posterior: ejecutar local, leer CI, crear su propio backend, provisionar Azure y finalmente activar CD. Recuerde destruir los recursos para detener costos.

## Puntos de corte

- Si pierde 5 minutos: omita el fallo intencional.
- Si pierde 10 minutos: muestre el plan guardado en lugar de lanzar Terraform.
- Si pierde 15 minutos: use la ejecución de CD preparada y conserve la verificación final en vivo.
