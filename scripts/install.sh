#!/usr/bin/env bash
# Install a registered skill as a git submodule under .claude/skills/<name>/.
#
# Usage:
#   scripts/install.sh <name>
#
# The repo URL is looked up in registry.json. The skill must already be
# registered — add it with register.sh first if not.

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: install.sh <name>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$SCRIPT_DIR/../registry.json"
ROOT="$(git rev-parse --show-toplevel)"
DEST_REL=".claude/skills/$NAME"
DEST_ABS="$ROOT/$DEST_REL"

[ -f "$REGISTRY" ] || { echo "registry not found: $REGISTRY" >&2; exit 2; }

URL="$(jq -r --arg n "$NAME" '.skills[] | select(.name == $n) | .repo' "$REGISTRY")"
if [ -z "$URL" ] || [ "$URL" = "null" ]; then
  echo "[skill-router] $NAME is not in registry.json — register it first with register.sh" >&2
  exit 1
fi

# Already a submodule? No-op.
if git -C "$ROOT" config -f .gitmodules --get "submodule.${DEST_REL}.path" >/dev/null 2>&1; then
  echo "[skill-router] $NAME already installed as submodule."
  exit 0
fi

# Plain directory in the way? Refuse — caller must remove or migrate it.
if [ -e "$DEST_ABS" ]; then
  echo "[skill-router] $DEST_REL exists but is not a submodule." >&2
  echo "               Remove or migrate it manually before installing." >&2
  exit 1
fi

echo "[skill-router] adding submodule $NAME -> $URL"
git -C "$ROOT" submodule add "$URL" "$DEST_REL"

if [ ! -f "$DEST_ABS/SKILL.md" ]; then
  echo "[skill-router] cloned repo has no top-level SKILL.md — rolling back." >&2
  git -C "$ROOT" submodule deinit -f "$DEST_REL" >/dev/null 2>&1 || true
  git -C "$ROOT" rm -f "$DEST_REL" >/dev/null 2>&1 || true
  rm -rf "$ROOT/.git/modules/$DEST_REL"
  exit 1
fi

cat <<DONE
[skill-router] installed $NAME at $DEST_REL
  Next: review and commit .gitmodules + $DEST_REL in the parent repo.
DONE
