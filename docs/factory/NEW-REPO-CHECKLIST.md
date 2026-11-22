# Standing up a new factory repo

A reusable, ordered checklist for adding a new child repo to this software-factory
setup. Steps **2** and **4** are the ones that silently bite first-timers — they're
provisioning steps, not code, so the factory looks correct but the first run fails.

Replace `<name>` with the new repo and `<owner>` with the GitHub owner throughout.

## 0. Scaffold the repo

Copy the factory machinery from an existing child repo (e.g. `software-factory-example-terraform`):

- `.github/actions/{run-agent,load-shared-skills}` (+ any brake-setup action)
- `.github/workflows/{auto-label,agent-explore,agent-implement,agent-review,ci,morning-rebase}` (+ `run-e2e` if it deploys)
- `.pre-commit-config.yaml` (adapt the brakes to the repo's language)
- `CLAUDE.md`, `GLOSSARY.md`, `CODING_STANDARDS.md`, `docs/`
- `.config/pip/pip.conf` + `scripts/dev-setup.sh` (reproducible local brakes)
- `skills-lock.json` pinning **this** home repo:
  ```json
  { "homeRepo": { "repo": "<owner>/software-factory-example-home-repo", "ref": "<tag-or-sha>" } }
  ```

Create it public and push (workflow files need the `workflow` token scope — `gh auth refresh -s workflow` first):

```bash
gh repo create <owner>/<name> --public --source=. --remote=origin --push
```

## 1. Branch protection (match the other repos)

Require the `brakes` status check (**strict**), PRs before merge, **enforce admins**,
no force-push, no deletions. (A CI-free repo like this home repo omits the required check.)

## 2. Factory labels — REQUIRED

`auto-label` cannot apply a label that doesn't exist, so create them first:

```bash
for l in agent:explore agent:implement agent:review agent:rebase; do
  gh label create "$l" --repo <owner>/<name> --force
done
# plus any repo-specific labels, e.g. run-e2e for an IaC repo
```

Tip: copy exact colors/descriptions from an existing repo —
`gh label list --repo <owner>/<existing> --json name,color,description`.

## 3. Secrets

```bash
gh secret set FACTORY_PAT               --repo <owner>/<name>   # fine-grained, THIS repo only: Actions/Contents/Issues/PRs/Workflows = R/W
gh secret set ANTHROPIC_FEDERATION_RULE_ID  --repo <owner>/<name>
gh secret set ANTHROPIC_ORGANIZATION_ID     --repo <owner>/<name>
gh secret set ANTHROPIC_SERVICE_ACCOUNT_ID  --repo <owner>/<name>
gh secret set ANTHROPIC_WORKSPACE_ID        --repo <owner>/<name>
```

Each repo ships a `scripts/setup-*-secrets.sh` wizard that automates this.

## 4. Anthropic WIF federation — REQUIRED

The agent authenticates via GitHub OIDC → Anthropic Workload Identity Federation.
The federation rule's **subject prefix must match the new repo's OIDC subject**, which
is the immutable form:

```
repo:<owner>@<owner_id>/<name>@<repo_id>:…
```

Get the numeric ids:

```bash
gh api repos/<owner>/<name> --jq '{owner_id: .owner.id, repo_id: .id}'
```

Then **either** broaden an existing rule's subject prefix to cover the repo, **or** add a
dedicated rule (subject prefix `repo:<owner>@<owner_id>/<name>@<repo_id>`) and point the
repo's `ANTHROPIC_FEDERATION_RULE_ID` secret at it.

**Verify** in the Anthropic Console's federated-authentication activity log: a run should
show `outcome: success`. A prefix mismatch shows `outcome: failure, reason: match_subject_prefix`
(and the CLI retries for ~3 min before the task fails — so it looks like a mid-run error).

## 5. AWS OIDC (only if the repo deploys)

Add the repo's subject to the relevant `terraform-<env>` role trust policy —
see `software-factory-example-terraform/modules/private/github-oidc`.

## 6. Wire it into the hub

Add a one-line pointer to the new repo in this home repo's [`CLAUDE.md`](../../CLAUDE.md),
and add it to [`GLOSSARY-MAP.md`](../../GLOSSARY-MAP.md) if it has its own vocabulary.

## 7. Smoke test

Open one trivial issue ("add a line to the README") and confirm it auto-chains
**explore → implement → review** to a review-ready PR. Green both ways = the repo is live.
Then close the throwaway issue/PR.
