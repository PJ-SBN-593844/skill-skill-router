---
name: skill-router
description: Catalog, install, remove, and sync Claude Code skills via the Synapse Brain /skills proxy. Skills are plain directories under .claude/skills/ — no git submodules, no GitHub auth on the client. Use whenever the user asks which skills exist, wants to install/fetch/sync/remove a skill, or starts a task that would benefit from a registered skill that is not yet installed locally. Trigger proactively when a request maps to a known skill (e.g. notes, tenants, tags, deploys, MCP servers, rules) and that skill is not yet under .claude/skills/.
---

# Skill Router

Manages the set of skills installed under `.claude/skills/`. Every skill is fetched from the **Synapse Brain `/skills` proxy**, which mirrors the private skill-* GitHub repos owned by the authoring organisation. The router does three things:

1. Lists the available catalog by calling `GET {BRAIN}/skills`.
2. Installs a skill by downloading `GET {BRAIN}/skills/<name>/download` (a `.skill` zip) and unpacking it into `.claude/skills/<name>/`.
3. Tells Claude, via its description, which skills exist so the router can fetch them on demand.

## Why Brain as the source of truth

- Clients don't need a GitHub token. Brain holds the GitHub App credentials and proxies the bytes.
- Skill repos can stay private. Only Brain needs read access.
- The same API surface works from Claude Code (via these shell scripts) and from the claude.ai chat app (via `WebFetch`) — no git submodules, no auth round trips.
- Skills on disk are plain directories. No `.gitmodules` to maintain, no pointer bumps to commit.

## Configuration

- `SYNAPSE_BRAIN_URL` — base URL of the Brain API. Defaults to `https://synapse.tri2b.cloud`. Override in local/dev environments.

## When to trigger

Use the router when any of these apply:

1. The user asks what skills exist, what's installed, or what's available.
2. The user asks to install / fetch / add / sync / update / remove / uninstall a skill.
3. The user starts a task that clearly maps to a known skill that is not yet installed locally. Install it first, then let normal skill triggering pick it up.

Do **not** trigger when the required skill is already installed — just let the normal skill system activate it.

## Repository conventions

- Skill `<name>` is published as `<name>.skill` (a zip whose files are prefixed with `<name>/`) attached to a tagged GitHub Release on the `skill-<name>` repo.
- `skill-creator` and `skill-router` are protected from removal; they must stay installed.

## Commands

All scripts live under `scripts/` and are safe to run from any working directory inside the host repo.

| Command | What it does |
| --- | --- |
| `scripts/catalog.sh [--json]` | Lists every skill returned by `GET /skills` with its local install status. |
| `scripts/list_installed.sh` | Lists skill directories currently present under `.claude/skills/`. |
| `scripts/install.sh <name>` | Downloads `<name>.skill` from Brain and unpacks it to `.claude/skills/<name>/`. Refuses if that path already exists. |
| `scripts/remove.sh <name>` | Deletes `.claude/skills/<name>/`. Detects and tears down legacy git submodule entries if present. Refuses for `skill-creator` and `skill-router`. |
| `scripts/sync.sh [<name>]` | Removes and re-installs the named skill, or every installed skill when no argument is passed. |

### Install flow

1. `scripts/catalog.sh` to confirm the skill is published.
2. `scripts/install.sh <name>`.
3. That's it — no commit to the parent repo. The harness will rescan `.claude/skills/` between turns and pick up the new skill.

### Remove flow

1. `scripts/remove.sh <name>`.
2. If a legacy git submodule entry is detected, it will be removed via `git submodule deinit` + `git rm` — in that case, commit the resulting `.gitmodules` change.

### Sync flow

- `scripts/sync.sh` with no arguments updates every installed skill.
- `scripts/sync.sh <name>` updates just that one.
- Sync always pulls the **latest release**; pin by not running sync, or use a specific Brain instance that lags behind production.

## Caveats

- `curl`, `unzip`, and `jq` are required on the host for the scripts to work. All three are standard on devbox/macOS/Linux.
- Brain must be reachable. If your environment can't hit `SYNAPSE_BRAIN_URL`, set the env var to a reachable instance (e.g. a port-forward).
- If a skill doesn't appear in `catalog.sh`, it is either not published yet, not tagged with the `claude-skill` topic in its GitHub repo, or the Brain GitHub App doesn't have access to it.
- Migrating from an older submodule-based install: run `scripts/remove.sh <name>` first (which detects and tears down the submodule), then `scripts/install.sh <name>`. Commit the `.gitmodules` change in the parent repo.
