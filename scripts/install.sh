#!/usr/bin/env bash
# Install a skill from the Brain /skills proxy.
#
# Usage:
#   scripts/install.sh <name>
#
# Downloads GET {BRAIN_URL}/skills/<name>/download (a zip where files
# are prefixed with <name>/) and unpacks it into .claude/skills/. The
# skill is installed as a plain directory — there is no git submodule
# to commit in the parent repo.

set -euo pipefail

NAME="${1:-}"
if [ -z "$NAME" ]; then
  echo "usage: install.sh <name>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

require_cmd unzip

DEST="$SKILLS_DIR/$NAME"
if [ -e "$DEST" ]; then
  echo "[skill-router] $DEST already exists — remove it first with scripts/remove.sh or move it aside." >&2
  exit 1
fi

TMP="$(mktemp -t "skill-${NAME}.XXXXXX.skill")"
trap 'rm -f "$TMP"' EXIT

echo "[skill-router] downloading $NAME from $BRAIN_URL"
if ! brain_download "/skills/$NAME/download" "$TMP"; then
  exit 1
fi

# .skill is a zip; unzip --test to catch corruption before we touch SKILLS_DIR.
if ! unzip -tqq "$TMP" >/dev/null 2>&1; then
  echo "[skill-router] downloaded file is not a valid zip" >&2
  exit 1
fi

mkdir -p "$SKILLS_DIR"
if ! unzip -q "$TMP" -d "$SKILLS_DIR"; then
  echo "[skill-router] failed to unpack into $SKILLS_DIR" >&2
  exit 1
fi

if [ ! -f "$DEST/SKILL.md" ]; then
  echo "[skill-router] installed archive has no SKILL.md at $DEST — rolling back." >&2
  rm -rf "$DEST"
  exit 1
fi

echo "[skill-router] installed $NAME at $DEST"
