# skill-router

> Catalog, install, remove, and sync skills that live as git submodules under .claude/skills/. Maintains a versioned registry of known skill repos with their descriptions. Use whenever the user asks which skills exist, wants to install/fetch/sync/remove a skill, wants to register a newly published skill, or starts a task that would benefit from a skill that is not yet installed locally. Trigger proactively when a request maps to a registered skill (e.g. notes, tenants, tags, deploys, MCP servers, rules) and that skill is not yet under .claude/skills/.

Loaded by Claude Code when the description above matches the user's request. Full instructions live in [`SKILL.md`](./SKILL.md).

## Install

From a repo that has [`skill-router`](https://github.com/PJ-SBN-593844/skill-skill-router) installed:

```sh
.claude/skills/skill-router/scripts/install.sh skill-router
```

Installs the skill as a git submodule under `.claude/skills/skill-router/`.

## License

Tri2b Community Source Licence v1.0 — see [`LICENSE`](./LICENSE).
