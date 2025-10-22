#!/usr/bin/env bash
set -euo pipefail

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared CLI not found. Install from https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required for JSON parsing. Install it with 'sudo apt install jq' or your package manager." >&2
  exit 1
fi

TUNNEL_NAME="${TUNNEL_NAME:-solver-edge}"
TUNNEL_HOSTNAME="${TUNNEL_HOSTNAME:-}"  # e.g. solver.example.com
LOCAL_SERVICE_URL="${LOCAL_SERVICE_URL:-http://localhost:8000}"  # backend origin served through the tunnel
CONFIG_PATH="${CLOUDFLARED_CONFIG_PATH:-${HOME}/.cloudflared/${TUNNEL_NAME}.yaml}"

if [[ -z "${TUNNEL_HOSTNAME}" ]]; then
  echo "Set TUNNEL_HOSTNAME to the public hostname you want to expose (e.g. solver.example.com)." >&2
  exit 1
fi

if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
  echo "Optional: set CLOUDFLARE_ACCOUNT_ID to skip interactive prompts."
fi

# Ensure login has been performed at least once (creates cert.pem)
CERT_PATH="${HOME}/.cloudflared/cert.pem"
if [[ ! -f "${CERT_PATH}" ]]; then
  echo "Cloudflare cert not found at ${CERT_PATH}. Running 'cloudflared tunnel login'..."
  cloudflared tunnel login
fi

TUNNEL_UUID=$(cloudflared tunnel list --output json | jq -r ".[] | select(.name == \"${TUNNEL_NAME}\") | .id")
if [[ -z "${TUNNEL_UUID}" || "${TUNNEL_UUID}" == "null" ]]; then
  echo "Creating tunnel ${TUNNEL_NAME}..."
  cloudflared tunnel create "${TUNNEL_NAME}"
  TUNNEL_UUID=$(cloudflared tunnel list --output json | jq -r ".[] | select(.name == \"${TUNNEL_NAME}\") | .id")
fi

if [[ -z "${TUNNEL_UUID}" || "${TUNNEL_UUID}" == "null" ]]; then
  echo "Failed to determine tunnel UUID for ${TUNNEL_NAME}." >&2
  exit 1
fi

CREDENTIALS_FILE="${HOME}/.cloudflared/${TUNNEL_UUID}.json"
if [[ ! -f "${CREDENTIALS_FILE}" ]]; then
  echo "Expected credentials file at ${CREDENTIALS_FILE} not found. Aborting." >&2
  exit 1
fi

cat <<EOF >"${CONFIG_PATH}"
tunnel: ${TUNNEL_UUID}
credentials-file: ${CREDENTIALS_FILE}

ingress:
  - hostname: ${TUNNEL_HOSTNAME}
    service: ${LOCAL_SERVICE_URL}
  - service: http_status:404
EOF

echo "Updated tunnel config at ${CONFIG_PATH}."

echo "Mapping DNS ${TUNNEL_HOSTNAME} to tunnel ${TUNNEL_NAME}..."
cloudflared tunnel route dns "${TUNNEL_NAME}" "${TUNNEL_HOSTNAME}"

echo
echo "Start the tunnel with:"
echo "  cloudflared tunnel run ${TUNNEL_NAME}"
