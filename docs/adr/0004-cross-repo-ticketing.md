# ADR-0004 — Cross-repo ticketing: app-repo-centric, native sub-issues + dependencies, no orchestrator

- **Status:** Accepted
- **Date:** 2026-11-23

## Situation

Work spans the app and terraform repos, and some tickets depend on others across
that boundary (e.g., an app feature needs a new terraform module first). We need to
control cross-repo dependencies and coordinate multi-repo efforts — without breaking
the per-repo factory trigger model (each factory's `auto-label → explore → …` fires
on *its own* repo's issues).

## Options

- **(a) Central ticket queue + orchestrator** — all tickets in the hub; a dispatcher pushes work into the children. Powerful, but a large build and it fights the per-repo trigger model.
- **(b) Home-repo map issue** — a `wayfinder:map` issue in the hub parents the child tickets. Works, but reverses the hub's "no issues here" rule and adds a coordination artifact where the app issue already is one.
- **(c) App-repo-centric, native cross-repo primitives** — tickets originate in the child repos; cross-repo coordination uses GitHub's native cross-repo sub-issues + dependencies, anchored on the originating issue.

## Choice

**(c).** Confirmed facts: GitHub's **sub-issues** and **issue dependencies** are GA
and work **across repos of the same owner** (keyed by global issue id; driven via
`gh`/API with issue URLs — the web "blocked by" picker is same-repo-biased, so use
the CLI/API).

- **Entry** — tickets are born in the **child repo** (the **app repo** by default; it carries the requirement, infra serves it). A one-off goes straight in and the factory auto-starts it; coordinated/cross-repo work goes through a **map**.
- **Escalation** — when a ticket needs human thinking (`needs-a-human`), a **grilling/wayfinder session is launched from the hub's harness** (shared skills); it decomposes the work.
- **Coordination** — **native cross-repo sub-issues** (`gh issue create -R <repo> --parent <url>`) and **native cross-repo `blocked-by`** (`gh issue edit <blocked> --add-blocked-by <url>`), anchored on the originating app issue. The **Map**, when used, is a `wayfinder:map` issue in the **originating repo**, not the hub.
- **Gating** — the factory respects a blocker via a **deterministic blocked-check in `explore`**: if the ticket has an open blocker, `explore` skips the agent run, comments the blockers, and does not auto-chain. When a blocker closes, a human **pulls the frontier** (re-applies `agent:explore`). (`auto-label` is left unchanged — it fires on `opened`, before edges exist, so a skip there would race; `explore` runs after edges are set and is the reliable gate.)
- The **hub stays issue-free** — ADR-0001's "no issues here" rule is unchanged.

## Consequences

- **No orchestrator and no scheduled "promoter"** — dependency sequencing past the first auto-start is human-pulled. Deferred as a future Software-Factory-Part-2 step.
- **No spanning GitHub Project** in v1 — a Project can hold both repos' issues and renders the sub-issue hierarchy, but has **no native dependency field** (would need a sync script), so it's deferred as an additive board.
- Cross-repo dependencies must be created via `gh`/API (URLs), not the UI picker; **verify on first real use** (UI/edge maturity is thinner than the API).
- Sub-issues are a tree (one parent, 8 deep, 100 wide); a second cross-repo edge uses a dependency or a reference, not a second parent.
- The `wayfinder` skill and each repo's `issue-tracker.md` are updated for cross-repo maps, children, blocking, and the frontier query.
