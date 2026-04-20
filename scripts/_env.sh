#!/usr/bin/env bash
# Shared helpers for skill-router scripts. Sourced, never executed.
#
# Provides:
#   BRAIN_URL           — base URL for the Brain /skills proxy, overridable
#                         via SYNAPSE_BRAIN_URL env var.
#   SKILLS_DIR          — absolute path to .claude/skills/ in the host repo.
#   PROTECTED_SKILLS    — array of skill names that must never be removed.
#   brain_get <path>    — GET {BRAIN_URL}{path}, print body to stdout, exit on failure.
#   brain_download <path> <dest>  — like brain_get, but streams to a file.
#   require_cmd <cmd>   — abort with a clear message if <cmd> is missing.

set -euo pipefail

BRAIN_URL="${SYNAPSE_BRAIN_URL:-https://synapse.tri2b.cloud}"
BRAIN_URL="${BRAIN_URL%/}"

_SCRIPT_DIR_ENV="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "$_SCRIPT_DIR_ENV/../.." && pwd)"

PROTECTED_SKILLS=(skill-creator skill-router)

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[skill-router] required command not found: $cmd" >&2
    exit 2
  fi
}

brain_get() {
  local path="$1"
  local url="$BRAIN_URL$path"
  require_cmd curl
  if ! curl -fsSL --max-time 30 "$url"; then
    echo "[skill-router] GET $url failed" >&2
    return 1
  fi
}

brain_download() {
  local path="$1"
  local dest="$2"
  local url="$BRAIN_URL$path"
  require_cmd curl
  if ! curl -fsSL --max-time 120 -o "$dest" "$url"; then
    echo "[skill-router] download $url failed" >&2
    return 1
  fi
}

is_protected() {
  local name="$1"
  local p
  for p in "${PROTECTED_SKILLS[@]}"; do
    [ "$name" = "$p" ] && return 0
  done
  return 1
}
