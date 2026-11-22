# ADR-0001 — Multi-repo factory with a home-repo hub

- **Status:** Accepted
- **Date:** 2026-11-22
- **Supersedes:** `software-factory-example-python` ADR-0001 (single-repo, single-app topology)

## Situation

The factory began as a single repo co-locating factory + app + infra (python ADR-0001), which explicitly deferred "graduate to a separate infra repo … consumed by the app repo" as a later factory exercise. We are now taking that graduation, and at the same time adopting Matt Pocock's **home-repo pattern** to keep shared agent steering (skills, docs, vocabulary) in sync across the growing set of repos.

## Options

- **(a) Stay single-repo** — keep app + infra + factory co-located (python ADR-0001's choice).
- **(b) Split into app + infra repos only** — two factories, duplicate the shared skills/docs in each.
- **(c) Split into app + infra repos, plus a home-repo hub** — the two child repos keep their own code, history, CI and issue trackers; a third **home repo** holds shared skills, shared docs, versioned agent config, and navigation **pointers** to the children.

## Choice

**(c)** Three repos:

- **`software-factory-example-home-repo`** — the hub. Holds shared skills, the shared factory `GLOSSARY.md` + `GLOSSARY-MAP.md`, versioned `settings.json`, and `CLAUDE.md` pointers to the children. **No CI of its own**; it is where humans launch *interactive* cross-repo agent sessions.
- **`software-factory-example-python`** — the app repo. Owns app code and the **persistent** deploy. Keeps its own factory pipeline.
- **`software-factory-example-terraform`** — the Terraform **module library**. Exposes one public module; owns no persistent infra. Keeps its own factory pipeline.

Each child keeps its own `CLAUDE.md`, `GLOSSARY.md`, `CODING_STANDARDS.md`, and build/test commands.

## Why

- **The deferred graduation is now the point.** Splitting infra into its own repo faithfully reproduces the platform-team / product-team boundary python ADR-0001 named as a future goal, and is itself proof the factory can operate across repos.
- **The hub keeps shared steering DRY.** Without it, every child duplicates skills/docs and they drift. The home repo is the single source of truth; children consume from it (skills: ADR-0002; vocabulary: `GLOSSARY-MAP.md`).
- **Pointers over submodules.** The home repo references children by plain path + clone-from-remote fallback in `CLAUDE.md` — no submodules, per the pattern.
- **Scale headroom.** Three repos is trivially within the pattern's comfort zone (it holds to ~20–40 before progressive disclosure is needed).

## Consequences

- The app↔infra change that python ADR-0001 kept atomic now spans two repos: an infra change ships as a tagged module release, then the app repo bumps its pinned `?ref=`. This ordering cost is the deliberate price of the platform/product boundary.
- `FACTORY_PAT` and OIDC federation are now configured per child repo.
- The home repo is CI-free; autonomous factory runs live only in the children.
- Monorepo remains the better default *when feasible* (Pocock's own stance); the home repo is the chosen fallback here specifically to demonstrate the pattern and separate infra/app lifecycles.
