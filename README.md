# Skill Template

This is the scaffold used by `skill-creator`'s publish flow to seed every new skill repository. When `publish_skill.sh` runs, it copies the contents of this directory into the new skill's initial commit (unless the skill already provides its own version of a file).

## What's inside

- `SKILL.md` — placeholder with the required frontmatter shape
- `.github/workflows/build.yml` — CI that validates the frontmatter and packages the skill as a tarball artifact on every push
- `.gitignore` — sensible defaults

## Editing the template

Changes here affect **future** skill repos only. Existing published skill repos keep whatever pipeline they were initialised with — bump them individually if you want the new template.
