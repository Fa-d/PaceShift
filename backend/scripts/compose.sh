#!/usr/bin/env bash
#
# Thin wrapper around `docker compose` that loads GLM_API_KEY from the macOS
# Keychain (service `zai-api-key`) at runtime so the `api` container receives it.
# The key is never written to disk — mirrors the convention in glm_smoke_test.sh.
#
# Usage:
#   backend/scripts/compose.sh up -d        # recreate containers with the key
#   backend/scripts/compose.sh logs -f api
#   backend/scripts/compose.sh down
#
# Any pre-exported GLM_API_KEY (or GLM_BASE_URL/GLM_MODEL) takes precedence.
set -euo pipefail

if [[ -z "${GLM_API_KEY:-}" ]]; then
  GLM_API_KEY="$(security find-generic-password -s zai-api-key -w 2>/dev/null || true)"
  if [[ -z "${GLM_API_KEY}" ]]; then
    echo "✗ GLM_API_KEY not set and no Keychain entry 'zai-api-key' found." >&2
    echo "  Store it first:  security add-generic-password -U -a \"\$USER\" -s zai-api-key -w \"KEY\"" >&2
    exit 2
  fi
fi
export GLM_API_KEY

# Forward optional overrides if they're already in the environment.
# Default to glm-4.5-flash: the free tier that needs no Z.ai balance. glm-5.2 /
# glm-4.5-air require a funded account (HTTP 429 otherwise). To upgrade once the
# account is recharged:  GLM_MODEL=glm-5.2 backend/scripts/compose.sh up -d
export GLM_BASE_URL="${GLM_BASE_URL:-https://api.z.ai/api/paas/v4}"
export GLM_MODEL="${GLM_MODEL:-glm-4.5-flash}"

cd "$(dirname "$0")/.."
exec docker compose "$@"
