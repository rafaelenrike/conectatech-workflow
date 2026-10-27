# Agenda de 120 minutos

| Minutos | Duración | Bloque | Resultado visible |
|---:|---:|---|---|
| 00–05 | 5 min | Apertura y objetivo | El público entiende el recorrido completo |
| 05–25 | 20 min | Conceptos de Git, IaC, CI/CD, contenedores y seguridad integrada | Vocabulario común para seguir el demo |
| 25–35 | 10 min | Arquitectura y repositorio | Mapa entre carpetas, workflows y recursos de Azure |
| 35–50 | 15 min | Aplicación y Docker local | Pruebas verdes, imagen creada y `/health` activo |
| 50–75 | 25 min | CI y controles de seguridad | GitHub Actions muestra tests, SonarQube, Checkov y Trivy |
| 75–95 | 20 min | Terraform y Azure | Plan revisado e infraestructura ya preparada o aplicada |
| 95–110 | 15 min | CD a Container Apps | Nueva revisión desplegada y URL pública funcional |
| 110–118 | 8 min | Lectura de fallos y rollback | El público sabe dónde diagnosticar y cómo volver atrás |
| 118–120 | 2 min | Cierre | Enlace al repositorio y ruta de réplica posterior |

## Regla de tiempo

La infraestructura debe estar aprovisionada antes de entrar al salón. Durante el bloque de Terraform muestre el plan y los recursos ya creados. Solo ejecute un `apply` en vivo si la red y Azure respondieron correctamente en el ensayo del mismo día.
