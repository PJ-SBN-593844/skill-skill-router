#!/usr/bin/env bash
# Remove an installed skill by deleting its directory under .claude/skills/.
#
# Usage:
#   scripts/remove.sh <name>
#
# Protected skills (skill-creator, skill-router) cannot be removed.
#
# If a legacy git submodule entry still exists for the skill in the
# parent repo's .gitmodules, this script will also deinit it. Otherwise
# a plain rm -rf is enough — nothing to commit.

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: remove.sh <name>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

if is_protected "$NAME"; then
  echo "[skill-router] refusing to remove protected skill: $NAME" >&2
  exit 1
fi

DEST_REL=".claude/skills/$NAME"
DEST_ABS="$SKILLS_DIR/$NAME"

if [ ! -e "$DEST_ABS" ]; then
  echo "[skill-router] $NAME is not installed."
  exit 0
fi

# Legacy cleanup: older router versions installed skills as git submodules.
# If a submodule entry still exists, tear it down through git so the
# parent repo's .gitmodules stays consistent.
ROOT=""
if ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  if [ -f "$ROOT/.gitmodules" ] && \
     git -C "$ROOT" config -f .gitmodules --get "submodule.${DEST_REL}.path" >/dev/null 2>&1; then
    echo "[skill-router] detected legacy submodule entry — deinitialising."
    git -C "$ROOT" submodule deinit -f "$DEST_REL" >/dev/null 2>&1 || true
    git -C "$ROOT" rm -f "$DEST_REL" >/dev/null 2>&1 || true
    rm -rf "$ROOT/.git/modules/$DEST_REL"
    cat <<DONE
[skill-router] removed legacy submodule $DEST_REL
  Next: commit the .gitmodules change in the parent repo.
DONE
    exit 0
  fi
fi

rm -rf "$DEST_ABS"
echo "[skill-router] removed $DEST_ABS"
