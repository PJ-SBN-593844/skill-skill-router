#!/usr/bin/env bash
# Remove an installed skill submodule.
#
# Usage:
#   scripts/remove.sh <name>
#
# Runs:
#   git submodule deinit <path>
#   git rm <path>
#   rm -rf .git/modules/<path>
#
# Protected skills (skill-creator, skill-router) cannot be removed.

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: remove.sh <name>" >&2
  exit 2
fi

case "$NAME" in
  skill-creator|skill-router)
    echo "[skill-router] refusing to remove protected skill: $NAME" >&2
    exit 1
    ;;
esac

ROOT="$(git rev-parse --show-toplevel)"
DEST_REL=".claude/skills/$NAME"

if ! git -C "$ROOT" config -f .gitmodules --get "submodule.${DEST_REL}.path" >/dev/null 2>&1; then
  echo "[skill-router] $NAME is not installed as a submodule."
  exit 0
fi

git -C "$ROOT" submodule deinit -f "$DEST_REL"
git -C "$ROOT" rm -f "$DEST_REL"
rm -rf "$ROOT/.git/modules/$DEST_REL"

cat <<DONE
[skill-router] removed submodule $DEST_REL
  Next: commit the changes to .gitmodules in the parent repo.
DONE
