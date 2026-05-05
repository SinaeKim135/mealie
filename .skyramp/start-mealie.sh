#!/usr/bin/env bash
# Brings up the Mealie service used by Skyramp Testbot for test generation
# and execution. Idempotent: tears down any prior run, starts fresh, and
# blocks until /api/app/about responds 2xx (or fails loudly with logs).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.skyramp.yml"
HEALTH_URL="http://localhost:9000/api/app/about"
MAX_WAIT_SECONDS="${MEALIE_READY_TIMEOUT:-900}"

echo "[skyramp] tearing down any existing mealie container"
docker compose -f "${COMPOSE_FILE}" down -v --remove-orphans 2>/dev/null || true

echo "[skyramp] starting mealie via ${COMPOSE_FILE}"
docker compose -f "${COMPOSE_FILE}" up -d

echo "[skyramp] waiting up to ${MAX_WAIT_SECONDS}s for ${HEALTH_URL}"
deadline=$(( $(date +%s) + MAX_WAIT_SECONDS ))
while (( $(date +%s) < deadline )); do
  if curl -fsS "${HEALTH_URL}" >/dev/null 2>&1; then
    echo "[skyramp] mealie is ready"
    exit 0
  fi
  sleep 2
done

echo "[skyramp] mealie did NOT become ready within ${MAX_WAIT_SECONDS}s — last logs:"
docker compose -f "${COMPOSE_FILE}" ps || true
docker compose -f "${COMPOSE_FILE}" logs --tail=80 mealie || true
exit 1
