#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SQL_FILE="${PROJECT_ROOT}/sql/posts_policies.sql"

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "Expected SQL file not found at ${SQL_FILE}" >&2
  exit 1
fi

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "Environment variable SUPABASE_DB_URL must be set (postgres connection string)." >&2
  exit 1
fi

echo "Applying Supabase RLS and grants from ${SQL_FILE}..."
psql "${SUPABASE_DB_URL}" -f "${SQL_FILE}"

echo "Done."
