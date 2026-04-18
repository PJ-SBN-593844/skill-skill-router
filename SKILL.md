---
name: skill-router
description: Catalog, install, remove, and sync skills that live as git submodules under .claude/skills/. Maintains a versioned registry of known skill repos with their descriptions. Use whenever the user asks which skills exist, wants to install/fetch/sync/remove a skill, wants to register a newly published skill, or starts a task that would benefit from a skill that is not yet installed locally. Trigger proactively when a request maps to a registered skill (e.g. notes, tenants, tags, deploys, MCP servers, rules) and that skill is not yet under .claude/skills/.
---

# Skill Router

Manages the set of skills available under `.claude/skills/`. Every skill is tracked as a **git submodule** of the parent repo, pointing at a standalone repo (by convention `PJ-SBN-593844/skill-<name>`). The router does three things:

1. Maintains a version-controlled **registry** (`registry.json`) that maps skill names to their repo URLs and descriptions.
2. Wraps `git submodule add / deinit / update` so installing or removing a skill is a single command.
3. Tells Claude, via its description, which skills exist in the org so the router can fetch them on demand.

## Why submodules + a registry

- **Submodules** mean every clone of the parent repo can see exactly which version of each skill was in use when a commit was made. Skills evolve independently in their own repos; the parent repo pins a specific commit. Running `git submodule update --init --recursive` on a fresh clone brings in whatever skills were installed at that time.
- **The registry** is a flat JSON file describing every known skill, whether installed locally or not. Claude reads it to decide which skill to fetch for a given task, without having to hit the GitHub API mid-conversation.
- Listing skills in the registry does **not** install them. Installation is an explicit `install.sh <name>` step that adds a submodule entry to `.gitmodules` and checks the skill out.

## When to trigger

Use the router when any of these apply:

1. The user asks what skills exist, what's installed, or what's registered.
2. The user asks to install / fetch / add / sync / update / remove / uninstall a skill.
3. The user publishes a new skill (via `skill-creator`'s `publish_skill.sh`) and needs to record it in the registry.
4. The user starts a task that clearly maps to a registered skill that is not yet installed. In that case: install the skill first, then let normal skill triggering pick it up.

Do **not** trigger when the required skill is already installed — just let the normal skill system activate it.

## Repository conventions

- By convention, skill `<name>` lives at `git@github.com:PJ-SBN-593844/skill-<name>.git` and is installed as a submodule at `.claude/skills/<name>/`. The `skill-` prefix is stripped on disk.
- Every skill repo must have a top-level `SKILL.md` with YAML frontmatter.
- `skill-creator` and `skill-router` are protected from removal; they must stay installed.

## Registry

`registry.json` holds the list of known skills. Each entry has:

```json
{
  "name": "brain-notes",
  "repo": "git@github.com:PJ-SBN-593844/skill-brain-notes.git",
  "description": "Use when the user wants to create, read, update, delete, ..."
}
```

When you add an entry, keep `description` close to the frontmatter description of the skill's `SKILL.md`. That way the router can explain the skill before installing it.

## Commands

All scripts live under `scripts/` and must be run from the parent repo root.

| Command | What it does |
| --- | --- |
| `scripts/catalog.sh [--json]` | Lists every skill in `registry.json` with install status (submodule present or not). |
| `scripts/list_installed.sh` | Lists skills currently present as submodules under `.claude/skills/`. |
| `scripts/install.sh <name>` | Looks up `<name>` in the registry and runs `git submodule add <url> .claude/skills/<name>`. No-op if already installed. |
| `scripts/remove.sh <name>` | Runs `git submodule deinit` + `git rm` for that skill, and cleans `.git/modules/.claude/skills/<name>`. Refuses for `skill-creator` and `skill-router`. |
| `scripts/sync.sh [<name>]` | Runs `git submodule update --remote --merge` on one or all installed skills. |
| `scripts/register.sh <name> <repo-url> [--description "..."]` | Appends a new entry to `registry.json`. If `--description` is omitted, fetches the description from the repo's `SKILL.md` via `gh`. |

### Install flow

1. Run `scripts/catalog.sh` to confirm the skill exists in the registry.
2. If not, run `scripts/register.sh <name> <repo-url>` first.
3. Run `scripts/install.sh <name>`.
4. Commit the changes to `.gitmodules` and the new submodule reference in the parent repo. The harness will rescan `.claude/skills/` between turns and pick up the new skill.

### Remove flow

1. Confirm with the user — removal rewrites `.gitmodules` and requires a parent-repo commit.
2. Run `scripts/remove.sh <name>`.
3. Commit the changes.

### Sync flow

- `scripts/sync.sh` with no arguments updates every installed skill.
- `scripts/sync.sh <name>` updates just that one.
- Sync moves the submodule pointer to the remote's default branch tip. Commit the pointer bump afterwards if you want the parent repo to track the new version.

### Register flow

After publishing a new skill with `skill-creator`'s `publish_skill.sh`:

1. `scripts/register.sh <name> git@github.com:PJ-SBN-593844/skill-<name>.git`
2. Commit `registry.json`.
3. Optionally `scripts/install.sh <name>` to immediately vendor it.

## Caveats

- The router assumes `gh` is available and authenticated for registry operations that read from GitHub. Submodule add/remove/update do not need `gh`; they use plain `git`.
- Submodules require `git submodule update --init --recursive` on fresh clones. Document that in the parent repo's README so new contributors pull skills without surprise.
- `skill-creator`'s current `publish_skill.sh` also adds the published skill as a submodule directly. That still works under this model, but the registry must be updated afterwards so the router knows about it. Folding `register.sh` into the publish flow is a natural follow-up.
