#!/usr/bin/env bash
# Update skill submodules to the latest commit on their remote default branch.
#
# Usage:
#   scripts/sync.sh            # update every installed skill submodule
#   scripts/sync.sh <name>     # update just that skill
#
# Runs `git submodule update --remote --merge`. Commit the pointer bump in the
# parent repo afterwards if you want to pin to the new version.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
NAME="${1:-}"

if [ -n "$NAME" ]; then
  DEST_REL=".claude/skills/$NAME"
  if ! git -C "$ROOT" config -f .gitmodules --get "submodule.${DEST_REL}.path" >/dev/null 2>&1; then
    echo "[skill-router] $NAME is not installed as a submodule." >&2
    exit 1
  fi
  echo "[skill-router] syncing $NAME"
  git -C "$ROOT" submodule update --remote --merge "$DEST_REL"
  exit 0
fi

# Sync all skill submodules.
PATHS="$(git -C "$ROOT" config -f .gitmodules \
  --get-regexp '^submodule\..*\.path$' \
  | awk '{print $2}' \
  | awk -F/ '$1==".claude" && $2=="skills" && NF==3')"

if [ -z "$PATHS" ]; then
  echo "[skill-router] no skill submodules to sync."
  exit 0
fi

STATUS=0
while IFS= read -r p; do
  [ -z "$p" ] && continue
  echo "[skill-router] syncing $p"
  if ! git -C "$ROOT" submodule update --remote --merge "$p"; then
    echo "[skill-router] failed to sync $p — resolve manually." >&2
    STATUS=1
  fi
done <<< "$PATHS"

exit $STATUS
