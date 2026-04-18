#!/usr/bin/env bash
# List every skill in registry.json with install status.
#
# A skill is "installed" if a submodule is registered for it in .gitmodules.
# The install column shows: yes | no.
#
# Usage:
#   scripts/catalog.sh            # human-readable table
#   scripts/catalog.sh --json     # registry JSON enriched with install flags

set -euo pipefail

FORMAT="${1:-text}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$SCRIPT_DIR/../registry.json"
ROOT="$(git rev-parse --show-toplevel)"

[ -f "$REGISTRY" ] || { echo "registry not found: $REGISTRY" >&2; exit 2; }

INSTALLED_NAMES=""
if [ -f "$ROOT/.gitmodules" ]; then
  INSTALLED_NAMES="$(git -C "$ROOT" config -f .gitmodules \
    --get-regexp '^submodule\..*\.path$' \
    | awk '{print $2}' \
    | awk -F/ '$1==".claude" && $2=="skills" && NF==3 {print $3}')"
fi

FLAGS_JSON="{}"
for name in $INSTALLED_NAMES; do
  FLAGS_JSON="$(printf '%s' "$FLAGS_JSON" | jq --arg n "$name" '. + {($n): true}')"
done

ENRICHED="$(jq --argjson flags "$FLAGS_JSON" '
  .skills |= map(. + {installed: ($flags[.name] // false)})
' "$REGISTRY")"

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
