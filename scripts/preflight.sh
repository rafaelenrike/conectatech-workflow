#!/usr/bin/env bash
set -euo pipefail

required=(git docker az terraform python3)
missing=0

for command_name in "${required[@]}"; do
  if command -v "${command_name}" >/dev/null 2>&1; then
    printf "OK  %-12s %s\n" "${command_name}" "$(command -v "${command_name}")"
  else
    printf "FALTA  %s\n" "${command_name}"
    missing=1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "FALTA  Docker no está iniciado o el usuario no puede acceder al daemon."
  missing=1
fi

if ! az account show >/dev/null 2>&1; then
  echo "FALTA  Sesión de Azure CLI. Ejecute: az login"
  missing=1
fi

if [[ "${missing}" -ne 0 ]]; then
  echo "Preflight incompleto. Corrija los elementos marcados como FALTA."
  exit 1
fi

echo "Preflight local completado."
