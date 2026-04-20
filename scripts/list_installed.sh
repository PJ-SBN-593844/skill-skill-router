#!/usr/bin/env bash
# List skills currently present under .claude/skills/.
#
# A skill is "installed" when there's a directory with a SKILL.md under
# .claude/skills/<name>/. Every other directory is ignored (stale
# fragments, in-progress drafts, etc.).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_env.sh"

[ -d "$SKILLS_DIR" ] || exit 0

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  [ -f "$dir/SKILL.md" ] || continue
  basename "$dir"
done | sort
