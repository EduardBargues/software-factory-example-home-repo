# ADR-0005 — Escalation via Slack grilling: an always-on Fargate bot running grill → to-spec → to-tickets

- **Status:** Accepted (design; not yet implemented)
- **Date:** 2026-11-24

## Situation

When `explore` returns `needs-a-human`, escalation today is manual: ADR-0004 says "a
grilling/wayfinder session is launched from the hub's harness" — a human notices, clones
the hub, and drives it solo. We want a `needs-a-human` ticket to convene a **collaborative,
multi-participant** session where the requester and teammates talk with the agent, and we
want the outcome to flow back into the factory automatically as decomposed, dependency-aware
tickets — not as prose a human then has to re-file.

## Options

- **(a) Keep manual local escalation** (status quo) — zero infra, but solo, easy to miss, and no automatic hand-back into the factory.
- **(b) Native Claude-in-Slack app** — cheap, but it's generic Claude: no shared skills, no repo write-back, no factory integration.
- **(c) A dedicated Slack grilling bot** — a service that hosts the shared `grilling` / `to-spec` / `to-tickets` skills in Slack and writes the result back as factory-ready tickets.

## Choice

**(c).** A new child repo `software-factory-example-grill-bot` deploys the bot.

- **Execution model** — **one always-on Fargate service** holding a **single Slack Socket
  Mode connection**, multiplexing all grilling **threads** (routes each event by `thread_ts`).
  Chosen over one-ephemeral-task-per-session because Slack **load-balances events
  unpredictably across all connections of the same app**, so concurrent per-session tasks
  would steal each other's events. A single connection is the only shape that supports
  **concurrent** grillings. Trade-off accepted: a small always-on task instead of scale-to-zero.
- **Trigger** — the bot **polls both child repos** (app + terraform) for the
  `agent:grill-with-docs` label. State is tracked in the label itself:
  `agent:grill-with-docs → grilling:active → grilled`. `explore`'s `needs-a-human` verdict
  comment points the human at the `agent:grill-with-docs` label so escalation is discoverable.
  The **target channel** is read from the issue (a `Grill in: #channel` line in the body),
  with a configured **default channel** as fallback.
- **Per session** — the grilling runs **in a Slack thread, not a dedicated channel**: the bot
  **posts a session-opener message** to the target channel and conducts the whole session in
  **that message's thread** (single-threaded, like a Claude Code session; no channel is
  created, and the bot must be a member of the channel). It **filters to threads it owns**
  (`thread_ts`), ignoring other channel chatter. It clones the **hub** (skills, ADR-0002) +
  the **originating repo** (context) and runs the `grilling` skill. Conversation is
  **stateless per turn**: each inbound reply spins a fresh `claude -p` over the thread + the
  issue — the **thread is the durable transcript**. Events are deduped by Slack `event_id`;
  a **per-thread lock** prevents two quick replies from spawning racing turns.
- **Ending pipeline** — when the grilling **frontier is empty**, the bot runs `to-spec` then
  `to-tickets`, surfacing their two built-in human checkpoints **in the thread** (the spec
  *seam check*, then the ticket *breakdown quiz*). The **spec is published onto the original
  issue** (which becomes the **parent/map**); the tickets become its **sub-issues** with
  **native cross-repo blocking edges** (ADR-0004). The bot labels **only the current frontier**
  (unblocked children) `agent:explore` — reconciling the skills' `ready-for-agent` vocabulary
  to the factory's entry label — then posts a **closing summary in the thread** and sets `grilled`.
- **Auth** — Claude is **keyless** via the Fargate task's IAM role + a new **Anthropic AWS
  federation rule** (WIF supports AWS IAM, not just GitHub Actions). The Slack `xoxb`/`xapp`
  tokens and the bot's GitHub credential live in **SSM Parameter Store `SecureString`**,
  injected by the task definition. The bot's GitHub identity needs **write access to both
  child repos** (`to-tickets` creates cross-repo children).
- **Infra** — deployed **once** via the terraform repo (a new ECS/Fargate module). **No API
  Gateway** — Socket Mode needs no inbound endpoint.

## Consequences

- **Extends ADR-0004's escalation line**: "launched from the hub harness" becomes "convened
  in Slack by the grill-bot." The **hub stays issue-free** — the bot writes only to child repos.
- **ADR-0004's blocked-gate and `to-tickets`' native edges lock together**: blocked children
  are ⛔-skipped by `explore` until their blockers close; humans **pull the frontier**.
- **Always-on cost** (one small Fargate task) is accepted as the price of **concurrent** grillings.
- **ADRs are listed, not authored**: the spec carries an "ADR candidates" section; authoring
  stays a human/follow-up step (the bot opens no PRs in v1).
- **Build, not buy or fork** — evaluated SaaS (Devin/Factory.ai are autonomous *coders*, not requirements-grillers, and ship repos to a third party; Charlie Labs, the closest fit, is shutting down) and OSS skeletons (thin; adapting them costs ~as much as greenfield and adds a low-reputation dependency). The novel IP (grilling → spec → tickets wired into the factory) is ours regardless, so build 05–06 **greenfield on official frameworks** (Slack Bolt + Claude Code/Agent SDK), using the OSS repos as read-only reference for gotchas only.
- **Wayfinder stays deferred** — v1 is the one-shot `grill → spec → tickets`, not the ongoing
  multi-session map.
- v1 is **Claude-only** and single-workspace; multi-workspace and private channels are future.
