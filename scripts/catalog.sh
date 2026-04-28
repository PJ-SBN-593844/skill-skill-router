#!/usr/bin/env bash
# List every skill available from the Synapse /skills proxy, with local
# install status.
#
# Source of truth: GET {SYNAPSE_URL}/skills. The "installed" column
# reflects whether a directory with that name exists under
# .claude/skills/.
#
# Usage:
#   scripts/catalog.sh            # human-readable table
#   scripts/catalog.sh --json     # Synapse response + installed flags

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

require_cmd jq

FORMAT="${1:-text}"

INSTALLED_NAMES=""
if [ -d "$SKILLS_DIR" ]; then
  INSTALLED_NAMES="$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort || true)"
fi

FLAGS_JSON="{}"
for name in $INSTALLED_NAMES; do
  FLAGS_JSON="$(printf '%s' "$FLAGS_JSON" | jq --arg n "$name" '. + {($n): true}')"
done

RESPONSE="$(synapse_get /skills)"

ENRICHED="$(printf '%s' "$RESPONSE" | jq --argjson flags "$FLAGS_JSON" '
  .skills |= map(. + {installed: ($flags[.name] // false)})
')"

if [ "$FORMAT" = "--json" ]; then
  printf '%s\n' "$ENRICHED"
  exit 0
fi

printf '%-24s %-10s %s\n' "NAME" "INSTALLED" "DESCRIPTION"
printf '%s\n' "$ENRICHED" | jq -r '
  .skills[] | [
    .name,
    (if .installed then "yes" else "no" end),
    (.description // "")
  ] | @tsv
' | while IFS=$'\t' read -r name inst desc; do
  printf '%-24s %-10s %s\n' "$name" "$inst" "$desc"
done
