# Multi-repo software factory — design & scaffolding plan

- **Status:** Design agreed (grilling complete 2026-11-22). Scaffolding **not yet started** — awaiting authorization.
- **Owner:** EduardBargues

Extends the single-repo factory (`software-factory-example-python`) into a three-repo setup using the **home-repo pattern** (Matt Pocock, aihero.dev) plus the platform/product (infra/app) split that python ADR-0001 deferred.

## 1. Goals

- Keep shared agent steering (skills, vocabulary, config) DRY across repos via a single hub.
- Split infrastructure into its own Terraform **module library**, consumed by the app repo.
- Bring the Terraform repo's factory to **parity** with the python repo's (pipeline + brakes + auth + docs).
- Change nothing about *how deploy ultimately works* beyond the existing spec: AWS Lambda via keyless OIDC, requirement-driven from the app repo.

## 2. The three repos

| Repo | Role | CI? | Owns |
|---|---|---|---|
| `software-factory-example-home-repo` | **Hub** — shared skills, shared glossary + `GLOSSARY-MAP.md`, `settings.json`, `CLAUDE.md` pointers | No | Shared steering; interactive cross-repo sessions |
| `software-factory-example-python` | **App repo** | Yes | App code; **persistent** deploy (apply-before-merge); consumes the TF module |
| `software-factory-example-terraform` | **Module library** | Yes | One public module; **ephemeral** test apply only; no persistent infra |

All three: **public**, personal account (`EduardBargues`), Claude-only (`CLAUDE.md`, no `AGENTS.md` this iteration).

## 3. Decisions (see ADRs)

- **Home-repo topology** — home ADR-0001 (supersedes python ADR-0001).
- **Skills: home-repo source of truth, runtime checkout in child CI, pinned ref** — home ADR-0002.
- **Single public module over private internals, pinned git-source distribution, repo-wide tags** — terraform ADR-0001.
- **Testing: layered** — native `terraform test` + mocks in per-PR brakes; real-apply e2e (native apply + Terratest) **on-demand via `run-e2e` label**, ephemeral in a sandbox, **never nightly, never a default merge gate**.

## 4. Home repo mechanics

- **Pointers** live in `CLAUDE.md`: name, purpose, local path, clone-from-remote fallback. No submodules.
- **Shared skills**: first-party, in `.claude/skills/`. The former `humanlayer/show-me` becomes first-party (attribution dropped). `course-*` stay git-ignored.
- **`settings.json`**: versioned shared agent config (later iteration may expand this).
- **No workflows.** The home repo never runs the factory.

## 5. Terraform repo factory

- **Module layout**: `modules/public/app` (sole consumable) + `modules/private/{lambda,dynamodb,eventbridge,…}` composed by relative path. `examples/` instantiate the public module for tests. `test/` holds Terratest (Go). `modules/public/app/tests/*.tftest.hcl` hold native tests.
- **Consumption**: `git::https://github.com/EduardBargues/software-factory-example-terraform.git//modules/public/app?ref=vX.Y.Z`. Release = cut a repo-wide `vX.Y.Z` tag.
- **Per-PR brakes (no creds)**: `fmt -check`, `validate`, `tflint`, Checkov, gitleaks, native `terraform test` + `mock_provider`.
- **On-demand e2e (`run-e2e` label)**: ephemeral apply of `examples/` + Terratest assertions, then destroy; OIDC into a scoped role in a **dedicated sandbox AWS account**; unique resource names + a reaper for leak safety.
- **Pipeline**: explore / implement / review / human-merge, mirrored from the python repo and adapted for IaC. Same agent-proofing (no editing `.github/`, pre-commit config, `.config/`; no `--no-verify`).
- **Day one**: factory + test harness + empty `modules/` `examples/` `test/` skeleton. **No real modules** until the app repo raises the first requirement. The `modules/public/app` shape above is the agreed target for that first module.

## 6. App repo changes

- Remove shared skills from `.claude/skills/`; add a **"load shared skills"** CI step (checkout home repo at pinned ref → copy skills into working tree before the agent runs).
- Repurpose `skills-lock.json` → home-repo ref pin (`{ "homeRepo": { "ref": "<tag>" } }`).
- Trim `GLOSSARY.md` to app-specific terms (shared vocab now lives in the home repo); keep `CODING_STANDARDS.md`.
- Mark python ADR-0001 **superseded by** home ADR-0001.
- Later (requirement-driven): consume `modules/public/app` via pinned source; own `apply` / apply-before-merge.

## 7. Scaffolding plan (phased — awaiting go-ahead)

**Phase A — Home repo**
1. `.claude/skills/` ← move all first-party shared skills; de-attribute `show-me`; `.gitignore` the `course-*`.
2. `settings.json` (shared config). `CLAUDE.md`, `GLOSSARY.md`, `GLOSSARY-MAP.md`, ADR-0001/0002 (✅ drafted).
3. `git init`, first commit. (No GitHub push until authorized.)

**Phase B — Terraform repo (factory parity, module-empty)**
1. Pipeline workflows (explore/implement/review) + `run-agent` action, adapted from python repo.
2. Brakes: `.pre-commit-config.yaml` (fmt/validate/tflint/Checkov/gitleaks) + `ci.yml`.
3. `run-e2e` label workflow (ephemeral apply + Terratest) — OIDC, sandbox account.
4. "Load shared skills" step + `skills-lock.json` pin to the home repo.
5. Skeleton `modules/public/` `modules/private/` `examples/` `test/go.mod`; `docs/factory/{SPEC,RUNBOOK}.md` adapted for IaC. ADR-0001 (✅ drafted), `GLOSSARY.md`, `CLAUDE.md` (✅ drafted).
6. `git init`, first commit.

**Phase C — App repo changes**
1. "Load shared skills" step + repurposed `skills-lock.json`; remove vendored shared skills.
2. Trim `GLOSSARY.md`; mark python ADR-0001 superseded; add a `CLAUDE.md` pointer back to the home repo if useful.

**Phase D — GitHub (explicit authorization required for each)**
1. Create the two new **public** repos under `EduardBargues`.
2. Push all three; wire `FACTORY_PAT` + OIDC federation (Anthropic WIF per repo; AWS WIF for app deploy + terraform sandbox) — a **wizard** walks the dashboard/CLI steps.
3. Enable branch protection + the collaborator-gated `auto-label` on the new repo.

## 8. Open setup tasks (human-only, wizard candidates)

- Create a **dedicated sandbox AWS account** for ephemeral applies; define the scoped OIDC role (Lambda + IAM-for-function + CloudWatch Logs), constrained by OIDC `sub` to this repo.
- Mint `FACTORY_PAT` per new repo; configure Anthropic WIF per repo.
- Decide the first requirement that drives the first real `modules/public/app` build.

## 9. Security notes (per org controls)

- No long-lived secrets in CI — OIDC short-lived creds only; `.env`/secret files never moved into the home repo.
- Least-privilege OIDC roles; dedicated sandbox isolated from prod/staging.
- Go test code (Terratest) runs privileged → human peer review required.
- CVE-scan pinned deps (pip-audit for python; keep Terratest `go.mod` pinned and scanned).
