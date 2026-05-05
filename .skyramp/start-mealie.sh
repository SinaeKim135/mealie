#!/usr/bin/env bash
# Brings up the Mealie service used by Skyramp Testbot.
#
# Idempotent: Skyramp invokes this from BOTH the workflow pre-step and
# the action's targetSetupCommand (matching the ebikes-lwc lifecycle).
# If the second call tore the container down, the JWT minted by the
# pre-step would no longer match the new container's signing secret.
#
# Behavior:
#   1. If /api/app/about is already responding 2xx, exit 0 with no changes.
#   2. Otherwise compose-up and block until /api/app/about responds 2xx
#      (loud failure with `docker compose ps` + last logs on timeout).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.skyramp.yml"
HEALTH_URL="http://localhost:9000/api/app/about"
MAX_WAIT_SECONDS="${MEALIE_READY_TIMEOUT:-900}"

# Fast path: another caller already brought Mealie up — leave it alone.
if curl -fsS "${HEALTH_URL}" >/dev/null 2>&1; then
  echo "[skyramp] mealie already healthy at ${HEALTH_URL}; nothing to do"
  exit 0
fi

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
