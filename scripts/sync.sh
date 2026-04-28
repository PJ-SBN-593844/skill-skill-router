#!/usr/bin/env bash
# Update installed skills to the latest .skill release on Synapse.
#
# Usage:
#   scripts/sync.sh            # update every installed skill
#   scripts/sync.sh <name>     # update just that skill
#
# Sync removes the existing directory and re-runs install, so the
# on-disk state matches the current release. Protected skills
# (skill-creator, skill-router) are skipped when syncing all.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

sync_one() {
  local name="$1"
  if [ ! -e "$SKILLS_DIR/$name" ]; then
    echo "[skill-router] $name is not installed." >&2
    return 1
  fi
  echo "[skill-router] syncing $name"
  rm -rf "$SKILLS_DIR/$name"
  "$SCRIPT_DIR/install.sh" "$name"
}

NAME="${1:-}"
if [ -n "$NAME" ]; then
  sync_one "$NAME"
  exit $?
fi

# Sync all installed skills (excluding protected ones).
STATUS=0
if [ ! -d "$SKILLS_DIR" ]; then
  echo "[skill-router] no skills directory at $SKILLS_DIR"
  exit 0
fi

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  if is_protected "$name"; then
    echo "[skill-router] skipping protected skill: $name"
    continue
  fi
  if ! sync_one "$name"; then
    echo "[skill-router] failed to sync $name — resolve manually." >&2
    STATUS=1
  fi
done

exit $STATUS
