# software-factory-example-home-repo

The **home repo** for a multi-repo software factory — the hub that holds shared agent steering and points at the child repos; you run *interactive, cross-repo* agent sessions from here. It has **no CI** of its own.

## What's here

- [`CLAUDE.md`](CLAUDE.md) — navigation pointers to the child repos + the working agreement.
- [`.claude/skills/`](.claude/skills/) — first-party shared skills, the single source of truth for the whole setup.
- [`.claude/settings.json`](.claude/settings.json) — versioned shared agent config (minimal in this iteration).
- [`GLOSSARY.md`](GLOSSARY.md) + [`GLOSSARY-MAP.md`](GLOSSARY-MAP.md) — shared factory vocabulary and the cross-repo index.
- [`docs/adr/`](docs/adr/) — system-wide decisions. [`docs/factory/SPEC.md`](docs/factory/SPEC.md) — the overall design + scaffolding plan.
- [`docs/factory/NEW-REPO-CHECKLIST.md`](docs/factory/NEW-REPO-CHECKLIST.md) — reusable steps to stand up a new factory repo (labels, secrets, WIF, smoke test).

## The repos

| Repo | Role |
|---|---|
| `software-factory-example-home-repo` | this hub — shared skills, docs, config, pointers |
| [`software-factory-example-python`](https://github.com/EduardBargues/software-factory-example-python) | the app + its factory; owns the persistent deploy |
| [`software-factory-example-terraform`](https://github.com/EduardBargues/software-factory-example-terraform) | Terraform module library; exposes one public module |

> This iteration is Claude-only (`CLAUDE.md`, not `AGENTS.md`). Child repos load these skills at CI time by checking out this repo at a pinned ref — see [`docs/adr/0002-skills-runtime-checkout.md`](docs/adr/0002-skills-runtime-checkout.md).
