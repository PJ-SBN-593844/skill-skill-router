#!/usr/bin/env bash
# Add a skill entry to registry.json.
#
# Usage:
#   scripts/register.sh <name> <repo-url> [--description "text"]
#
# If --description is omitted, the script fetches SKILL.md from the repo via
# `gh` and parses its frontmatter description field. That requires gh to be
# installed and authenticated with read access to the repo.
#
# Re-registering an existing name updates the entry in place.

set -euo pipefail

NAME=""
URL=""
DESC=""

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--description)
      DESC="${2:-}"
      shift 2
      ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      if [ -z "$NAME" ]; then
        NAME="$1"
      elif [ -z "$URL" ]; then
        URL="$1"
      else
        echo "unexpected argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [ -z "$NAME" ] || [ -z "$URL" ]; then
  echo "usage: register.sh <name> <repo-url> [--description \"text\"]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="$SCRIPT_DIR/../registry.json"
[ -f "$REGISTRY" ] || { echo "registry not found: $REGISTRY" >&2; exit 2; }

# Derive owner/repo from SSH or HTTPS URL for gh fallback.
derive_repo_slug() {
  local u="$1"
  u="${u#git@github.com:}"
  u="${u#https://github.com/}"
  u="${u%.git}"
  printf '%s' "$u"
}

if [ -z "$DESC" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "no --description given and gh is not installed; cannot auto-fetch." >&2
    exit 2
  fi
  SLUG="$(derive_repo_slug "$URL")"
  echo "[skill-router] fetching description from $SLUG:SKILL.md"
  RAW="$(gh api "repos/$SLUG/contents/SKILL.md" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)"
  if [ -z "$RAW" ]; then
    echo "could not fetch SKILL.md from $SLUG — pass --description manually." >&2
    exit 1
  fi
  # Extract `description:` line from the YAML frontmatter (between first two --- lines).
  DESC="$(printf '%s' "$RAW" | awk '
    /^---[[:space:]]*$/ { n++; next }
    n==1 && /^description:[[:space:]]*/ {
      sub(/^description:[[:space:]]*/, "")
      print
      exit
    }
  ')"
  if [ -z "$DESC" ]; then
    echo "SKILL.md from $SLUG has no description field — pass --description manually." >&2
    exit 1
  fi
fi

UPDATED="$(jq --arg name "$NAME" --arg repo "$URL" --arg desc "$DESC" '
  . as $root
  | ($root.skills | map(select(.name == $name)) | length) as $exists
  | if $exists > 0 then
      .skills |= map(
        if .name == $name then . + {repo: $repo, description: $desc} else . end
      )
    else
      .skills += [{name: $name, repo: $repo, description: $desc}]
    end
  | .skills |= sort_by(.name)
' "$REGISTRY")"

printf '%s\n' "$UPDATED" > "$REGISTRY"
echo "[skill-router] registered $NAME -> $URL"
