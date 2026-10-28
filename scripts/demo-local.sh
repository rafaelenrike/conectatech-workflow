#!/usr/bin/env bash
set -euo pipefail

image_name="code-to-cloud:local"
container_name="code-to-cloud-demo"

docker build --build-arg APP_VERSION=local -t "${image_name}" .
docker run --rm -d --name "${container_name}" -p 8080:8080 "${image_name}"

cleanup() {
  docker stop "${container_name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for attempt in 1 2 3 4 5 6; do
  if curl --fail --silent http://127.0.0.1:8080/health; then
    echo
    echo "Demo disponible en http://127.0.0.1:8080"
    echo "Presione Ctrl+C para finalizar."
    while true; do sleep 30; done
  fi
  sleep 2
done

echo "La aplicación no respondió a tiempo."
docker logs "${container_name}"
exit 1
