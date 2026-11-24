# ADR-0003 — Centralize shared factory CI in the home repo (reusable workflows + composite actions)

- **Status:** Accepted
- **Date:** 2026-11-23

## Situation

Each child repo carries its own copy of the factory CI. Much of it is **identical**
across repos (the `run-agent` harness, `load-shared-skills`, `auto-label`,
`morning-rebase`, and the explore/implement/review scaffolding). Duplicating it means
a pipeline fix or improvement must be applied N times and can drift between repos —
the same problem the home-repo pattern already solves for *skills and docs*.

## Options

- **(a) Keep per-repo copies** — simplest; no cross-repo coupling; but duplicated and drift-prone.
- **(b) Centralize in the home repo** — host the identical pieces once as **reusable workflows** (`workflow_call`) and **cross-repo composite actions**; children call them pinned to a tag.

## Choice

**(b), phased.** The home repo hosts the shared CI; children reference it pinned by tag.

- **Phase 1 (this ADR):** move the byte-identical pieces — the `run-agent` and
  `load-shared-skills` composite actions, and the `auto-label` and `morning-rebase`
  reusable workflows. Children keep thin caller workflows (which own the `on:`
  triggers) and reference the home repo `@<tag>`.
- **Phase 2 (later):** graduate explore/implement/review to reusable workflows with
  **inputs** for the repo-specific bits (agent prompt, brake setup).
- **Stays per-repo** (deliberately): the **brakes** (`ci.yml`, language-specific —
  uv/ruff vs terraform/tflint/checkov), the **agent prompts**, and repo-only
  workflows (`run-e2e`, deploy).

## Why

- **DRY the pipeline, not just the docs** — a fix to `run-agent` (model, CLI, auth)
  lands once and every child inherits it at the pinned tag. New repos become thin callers.
- The home repo stays **CI-free in practice**: it only *hosts* `workflow_call`
  definitions; nothing runs on the home repo's own events (home ADR-0001 holds).

## Consequences

- **Pin by a moving major tag, never `@main`.** Children pin the home repo at a
  **moving major tag** (`@v0`), the actions-ecosystem convention (`actions/checkout@v4`):
  a **backward-compatible** fix moves `v0` and every child inherits it with *no* child-side
  change (fast rollout); a **breaking** change cuts `v1` and is adopted per child via PR
  (gated rollout). Immutable point releases (`v0.1.1`) are kept for the record and for
  `v0` to track. `@main` is **never** used — an unpinned ref would let any home-repo edit
  rewrite every child's *privileged* CI (OIDC, the agent) at once, with no change visible
  in the child and no reproducibility.
- The other home-repo pin — the skills ref in `skills-lock.json` — stays a **SHA/point-tag**
  bumped by reviewed PR; skills changes aren't covered by the workflow compatibility
  contract, so they keep the tighter pin.
- **Coupling / blast radius:** a bug in a shared workflow can affect all children;
  debugging spans two repos. Tag pinning bounds the blast radius.
- Reusable workflows receive the **caller's** `github` context, so event fields and
  `secrets: inherit` work as in the per-repo versions.
- With only two children today the payoff is modest; it compounds as repos are added —
  which is the explicit direction of this setup.
