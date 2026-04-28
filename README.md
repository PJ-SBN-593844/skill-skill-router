# skill-router

> Catalog, install, remove, and sync Claude Code skills via the Synapse /skills proxy. Skills are plain directories under .claude/skills/ — no git submodules, no GitHub auth on the client. Use whenever the user asks which skills exist, wants to install/fetch/sync/remove a skill, or starts a task that would benefit from a registered skill that is not yet installed locally. Trigger proactively when a request maps to a known skill (e.g. notes, tenants, tags, deploys, MCP servers, rules) and that skill is not yet under .claude/skills/.

Loaded by Claude Code when the description above matches the user's request. Full instructions live in [`SKILL.md`](./SKILL.md).

## Install

The router is self-installing once any copy of `skill-router` lives under `.claude/skills/`. From any host repo:

```sh
curl -fsSL https://synapse.tri2b.cloud/skills/skill-router/download -o /tmp/skill-router.skill
mkdir -p .claude/skills
unzip -q /tmp/skill-router.skill -d .claude/skills
```

Override the Synapse URL with the `SYNAPSE_URL` env var if you're pointing at a different instance.

## License

Tri2b Community Source Licence v1.0 — see [`LICENSE`](./LICENSE).
