# Glossary — Software Factory (shared)

Canonical, repo-independent vocabulary for the factory. Shared across every repo in this setup; repo-specific terms live in each repo's own `GLOSSARY.md` (see [`GLOSSARY-MAP.md`](./GLOSSARY-MAP.md)). Use these terms exactly; avoid the listed alternatives so agents and humans don't drift.

## Home-repo pattern

- **Home repo** — the hub repository (`software-factory-example-home-repo`) holding shared skills, shared docs/vocabulary, versioned agent config, and pointers to the child repos. Where humans launch *interactive* cross-repo agent sessions. Has no CI of its own. _Avoid: meta-repo, root repo._
- **Child repo** — a repository the home repo points at (`…-python`, `…-terraform`); keeps its own code, history, CI, and issue tracker. _Avoid: spoke, sub-repo._
- **Pointer** — a one-line reference in the home repo's `CLAUDE.md` to a child repo: name, purpose, local path, and a clone-from-remote fallback. Not a submodule. _Avoid: link, reference._
- **Shared skill** — a first-party skill authored once in the home repo's `.claude/skills/` and consumed by every repo. _Avoid: global skill._
- **Skills pin** — the home-repo ref (tag/SHA) a child repo locks to in its `skills-lock.json`; bumped via PR.
- **Progressive disclosure** — the scaling tactic of grouping pointers by area into separate files once a flat list grows too large (~20–40+ repos). Not needed yet.

## Factory structure

- **Factory** — a system of agents that turns tickets, PRs, and schedules into merged (and eventually deployed) code on remote infrastructure.
- **Service** — a slot in the factory filled by a product: ticket tracker, git host, runner, orchestrator, observability platform.
- **Ticket tracker** — where tickets live and the factory's human interface. Here: **GitHub Issues**. _Avoid: issue tracker, project board._
- **Git host** — where branches, PRs, and reviews live. Here: **GitHub**.
- **Runner** — the disposable machine a **run** executes on; nothing on it survives the run. Here: **GitHub Actions** ephemeral VMs. _Avoid: server, box, sandbox._
- **Orchestrator** — receives triggers, starts runs, records what's queued/in-flight/finished. Here: **GitHub Actions**. _Avoid: dispatcher, scheduler._
- **Observability platform** — where runs' logs/traces are seen. Here: GitHub Actions run logs + the `/retro` task.
- **Harness** — the coding agent/model a run drives. Here: **Claude Code**, behind a single swappable agent definition imported by every task.

## Work units

- **Task** — a kind of work the factory performs, defined once and run many times (a GitHub Actions workflow): explore, implement, review, deploy. _Avoid: job, workflow (in prose), action._
- **Trigger** — the event that starts a run: a label change, a clock, or another run.
- **Run** — one execution of a task on one runner, from trigger to finish, treated as a black box. A run never waits for a human. _Avoid: session._
- **Verdict** — the explore run's classification of a ticket: `easy-call`, `needs-a-human`, or `blocked`.
- **Label (`agent:*`)** — both the trigger for a task and the hand-off between tasks; applying one is an **approval** only a triage-role-or-above collaborator can give.

## Quality & control

- **Brake** — a control that stops a bad change. Three brakes, cheapest to most expensive: automated check, automated review, human review.
- **Accelerator** — a mechanism that raises throughput, used only once the brakes are trusted (*accelerate only once you can brake*): the explore→implement→review pipeline and its auto-chaining, the reusable workflows, `dev-setup`, and the trust ladder. _Counterpart of: brake._
- **Automated check** — the first brake; deterministic. Fails the same way every time. Push every mechanizable rule down to this layer.
- **Automated review** — the second brake; the `agent:review` run. Probabilistic (it is an agent).
- **Human review** — the third brake; a person before the merge. The most expensive; use `/retro` to move its catches to a lower brake.
- **Bug** — a wrong change. _Avoid: defect._
- **Lint rule** — an automated check that encodes a rule the built-in checks cannot express. The preferred home for a mechanizable rule.
- **Coding standard (`CODING_STANDARDS.md`)** — a **fuzzy** rule the **review** run enforces, for a thing no check can express. Per-repo. Grown and pruned via `/retro`; no run edits it.
- **No-op** — a standard line you can delete with no change to agent output. Cut it.
- **Sediment** — stale, duplicate, or contradictory standards. Prune them.
- **Trust ladder** — removing human gates one at a time as `/retro` shows the agent reliably handles a hand-off.
- **Two-way door / one-way door** — a reversible vs hard-to-reverse change; drives blast-radius and auto-merge eligibility.

## Feedback loop

- **Retro (`/retro`)** — the task that audits a run or a file. For each finding it chooses one route: a check, a coding standard, or delete.
- **Lint rule ratchet** — the workflow to roll a new lint rule over an existing repo: each day fix one failing case, until the rule is safe everywhere.
- **Regression guard** — a test added with a bug fix. It stops the bug from returning.
- **Data source** — a part of the agent environment it reads to verify its work: logs, a database, the UI, the issue tracker.

## Shared auth

- **FACTORY_PAT** — the fine-grained, single-repo, expiring GitHub token a repo's tasks use to trigger downstream runs and open PRs (the built-in `GITHUB_TOKEN` can't). Scoped per repo.
- **OIDC federation** — keyless auth: GitHub mints a short-lived OIDC token per run, exchanged for cloud/Anthropic access. No long-lived secrets stored.
