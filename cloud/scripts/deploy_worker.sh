#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKER_DIR="${PROJECT_ROOT}/edge_worker"
WRANGLER_CONFIG="${WORKER_DIR}/wrangler.toml"

if ! command -v wrangler >/dev/null 2>&1; then
  echo "wrangler CLI not found. Install with 'npm i -g wrangler' or via package manager." >&2
  exit 1
fi

if [[ ! -f "${WRANGLER_CONFIG}" ]]; then
  echo "Expected wrangler.toml at ${WRANGLER_CONFIG}." >&2
  exit 1
fi

echo "Deploying Cloudflare Worker from ${WORKER_DIR}..."
cd "${WORKER_DIR}"

# Ensure dependencies are installed (npm ci if package-lock exists, else install)
if [[ -f package-lock.json ]]; then
  npm ci >/dev/null
elif [[ -f package.json ]]; then
  npm install >/dev/null
fi

wrangler deploy --env production --config "${WRANGLER_CONFIG}"

echo "Worker deployment complete."
