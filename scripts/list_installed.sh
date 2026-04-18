#!/usr/bin/env bash
# List skills currently installed as submodules under .claude/skills/.
#
# Source of truth: .gitmodules. A skill is "installed" when there's a submodule
# entry whose path is .claude/skills/<name>.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"

[ -f "$ROOT/.gitmodules" ] || exit 0

git -C "$ROOT" config -f .gitmodules \
  --get-regexp '^submodule\..*\.path$' \
  | awk '{print $2}' \
  | awk -F/ '$1==".claude" && $2=="skills" && NF==3 {print $3}' \
  | sort
