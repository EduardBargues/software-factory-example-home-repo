# software-factory-example-home-repo

The **home repo** for this software-factory setup: the hub holding shared skills, shared factory vocabulary, versioned agent config, and navigation pointers to the child repos. Run *interactive, cross-repo* agent sessions from here. This repo has **no CI**; the autonomous factory lives in each child repo.

Read these before proposing changes, and use their terms exactly:

- [`GLOSSARY.md`](GLOSSARY.md) — shared, repo-independent factory vocabulary.
- [`GLOSSARY-MAP.md`](GLOSSARY-MAP.md) — index of all three repos' glossaries and how they relate.
- [`docs/adr/`](docs/adr/) — system-wide Architecture Decision Records.
- [`docs/factory/SPEC.md`](docs/factory/SPEC.md) — the multi-repo design and scaffolding plan.
- [`docs/factory/NEW-REPO-CHECKLIST.md`](docs/factory/NEW-REPO-CHECKLIST.md) — how to stand up a new factory child repo (labels, secrets, WIF, smoke test).

## Navigation pointers

The repos this setup touches. Each is expected as a sibling directory; **clone from the remote if missing**, and use a git **worktree** when several agents work the same repo at once. Read a child repo's own `CLAUDE.md` before changing it.

- **App (`software-factory-example-python`)**: Python app + its factory pipeline; owns the persistent AWS deploy. Path: `../software-factory-example-python`. Clone from `https://github.com/EduardBargues/software-factory-example-python.git` if missing.
- **Terraform (`software-factory-example-terraform`)**: Terraform module library; exposes one public `modules/public/app`; owns no persistent infra. Path: `../software-factory-example-terraform`. Clone from `https://github.com/EduardBargues/software-factory-example-terraform.git` if missing.

## Shared skills

First-party skills in `.claude/skills/` are the single source of truth for the whole setup. Child repos load them at CI time by checking out this repo at a pinned ref (see [`docs/adr/0002-skills-runtime-checkout.md`](docs/adr/0002-skills-runtime-checkout.md)); interactive sessions here use them directly. Any `course-*` skills stay git-ignored.

## Working agreement

- Look up every fact yourself (filesystem, `git`, `gh`), using subagents for wide searches. Bring decisions, not raw dumps.
- File issues in **each repo's own** GitHub Issues, not here.
- This iteration is Claude-only: steer with `CLAUDE.md`, not `AGENTS.md`. Genericising to `AGENTS.md` is a later iteration.
