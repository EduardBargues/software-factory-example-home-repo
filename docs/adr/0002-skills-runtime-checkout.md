# ADR-0002 — Shared skills: home-repo source of truth, runtime checkout in child CI

- **Status:** Accepted
- **Date:** 2026-11-22

## Situation

Shared skills must stay in sync across repos (the whole point of the home repo). But each child repo's **autonomous CI** factory checks out only *that* child repo, and Claude Code discovers skills from `.claude/skills/` in the working tree — so a skill living only in the home repo is invisible to a child's CI run.

## Options

- **(a) Vendor** — commit copies of the shared skills into each child repo (+ a lock file for provenance). CI works unchanged, but reintroduces hand-maintained duplication.
- **(b) Runtime checkout** — child CI clones the home repo at a pinned ref and copies its `.claude/skills/*` into the working tree before the agent runs. One source of truth; CI gains a checkout step.
- **(c) Submodule / subtree** — couples git trees; awkward; rejected in line with the pattern's "pointers over submodules" ethos.

## Choice

**(b) Runtime checkout.** The **home repo is the single source of truth** for shared skills (all first-party; no third-party vendoring). Each child repo's CI, *before* invoking the agent, checks out the home repo at a **pinned ref** and copies its skills into the working-tree `.claude/skills/` (ephemeral, never committed). The pin lives in each child's repurposed `skills-lock.json` (`{ "homeRepo": { "ref": "<tag-or-sha>" } }`); bumping it is a PR through the normal brakes. Interactive cross-repo sessions launched *from* the home repo use its skills directly.

## Why

- All repos are **public**, so the home-repo clone needs no PAT — the main objection to runtime checkout disappears.
- True single source of truth with **no hand-maintained duplication**; a skill is authored once.
- **Pinning** keeps CI reproducible: a home-repo change can't silently alter a child's behavior mid-flight; it lands as a reviewable pin bump.

## Consequences

- Each child CI workflow gains a "load shared skills" step and a home-repo ref pin.
- `skills-lock.json` changes meaning from external-provenance tracking to the home-repo ref pin; the former `humanlayer/show-me` skill becomes first-party in the home repo.
- Paywalled `course-*` skills remain git-ignored everywhere and are not part of this flow (CI does not need them).
