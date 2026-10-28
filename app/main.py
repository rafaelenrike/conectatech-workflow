import os
from datetime import UTC, datetime

from fastapi import FastAPI
from fastapi.responses import HTMLResponse

APP_VERSION = os.getenv("APP_VERSION", "dev")

app = FastAPI(
    title="Code to Cloud API",
    description="Aplicación mínima para demostrar un pipeline DevSecOps.",
    version=APP_VERSION,
)


@app.get("/", response_class=HTMLResponse)
def home() -> str:
    return f"""<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Code to Cloud: DevSecOps</title>
    <style>
      body {{ margin: 0; font-family: system-ui, sans-serif; color: #f8fafc;
              background: linear-gradient(135deg, #002b6b, #075985); }}
      main {{ max-width: 760px; margin: 12vh auto; padding: 48px; }}
      p {{ font-size: 1.25rem; line-height: 1.6; color: #dbeafe; }}
      code {{ background: #0f172a; padding: 4px 8px; border-radius: 6px; }}
    </style>
  </head>
  <body><main>
    <p>ConectaTech 2026</p>
    <h1>Code to Cloud: DevSecOps</h1>
    <p>Esta es la primera demo de funcionamiento de GitHub Actions, Docker y Terraform.</p>
    <p>Versión desplegada: <code>{APP_VERSION}</code></p>
  </main></body>
</html>"""


@app.get("/health")
def health() -> dict[str, str]:
    return {
        "status": "error",
        "version": APP_VERSION,
        "timestamp": datetime.now(UTC).isoformat(),
    }
