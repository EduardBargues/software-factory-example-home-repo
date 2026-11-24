#!/usr/bin/env bash
# new-factory-repo.sh — stand up a new factory child repo, mirroring an existing one.
#
# Automates docs/factory/NEW-REPO-CHECKLIST.md steps 0 (scaffold), 1 (branch
# protection), 2 (labels), 6 (hub wiring hint). The steps that need a human —
# 3 (secrets), 4 (Anthropic WIF), 5 (AWS OIDC) — are PRINTED at the end, not done.
#
# It copies the generic factory machinery verbatim from a reference child
# (default: the Python app) and generates clean per-repo files, including a
# minimal pyproject + a stub src/ and tests/ so the `brakes` check is green from
# the first commit. Assumes the reference (and therefore the new child) is Python.
#
# Usage:
#   scripts/new-factory-repo.sh <name> [--owner O] [--reference R] [--description "..."] [--dry-run]
#
# Example:
#   scripts/new-factory-repo.sh software-factory-example-grill-bot \
#     --description "Slack grilling bot for the software factory."

set -euo pipefail

OWNER="EduardBargues"
REFERENCE="software-factory-example-python"
DESCRIPTION=""
DRY_RUN=false
NAME=""

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '3,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --owner) OWNER="$2"; shift 2 ;;
    --reference) REFERENCE="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -*) die "unknown flag: $1" ;;
    *) [ -z "$NAME" ] || die "unexpected argument: $1"; NAME="$1"; shift ;;
  esac
done
[ -n "$NAME" ] || usage 1
[ -z "$DESCRIPTION" ] && DESCRIPTION="A factory child repo ($NAME)."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT_DIR="$(cd "$HUB_DIR/.." && pwd)"
REF_DIR="$PARENT_DIR/$REFERENCE"
DEST_DIR="$PARENT_DIR/$NAME"
# Python package name: strip the common prefix, make it an identifier.
PKG="$(printf '%s' "$NAME" | sed 's/^software-factory-example-//; s/[^a-zA-Z0-9]/_/g')"

# --- preconditions ---
command -v gh >/dev/null || die "gh CLI not found"
command -v git >/dev/null || die "git not found"
[ -d "$REF_DIR" ] || die "reference repo not found at $REF_DIR (clone it as a sibling)"
[ ! -e "$DEST_DIR" ] || die "destination already exists: $DEST_DIR"
export GH_TOKEN="${GH_TOKEN:-$(gh auth token 2>/dev/null || true)}"
[ -n "$GH_TOKEN" ] || die "not logged in to gh (run: gh auth login)"
if gh repo view "$OWNER/$NAME" >/dev/null 2>&1; then die "repo $OWNER/$NAME already exists"; fi
HUB_REF="$(git -C "$HUB_DIR" rev-parse HEAD)"

echo "==> New factory repo"
echo "    name:        $OWNER/$NAME"
echo "    reference:   $REFERENCE"
echo "    package:     $PKG"
echo "    hub pin:     $HUB_REF"
echo "    dry-run:     $DRY_RUN"
echo

run() { if $DRY_RUN; then echo "+ $*"; else "$@"; fi; }

# Substitute @@placeholders@@ in a generated file (pipe-delimited so / is safe).
subst() {
  $DRY_RUN && return 0
  sed -e "s|@@NAME@@|$NAME|g" -e "s|@@PKG@@|$PKG|g" -e "s|@@OWNER@@|$OWNER|g" \
      -e "s|@@DESC@@|$DESCRIPTION|g" -e "s|@@HUBREF@@|$HUB_REF|g" "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

# --- 0. scaffold: copy generic machinery verbatim ---
echo "==> 0. Scaffold (copy generic machinery from $REFERENCE)"
GENERIC=(
  ".github/workflows/auto-label.yml"
  ".github/workflows/morning-rebase.yml"
  ".github/workflows/agent-explore.yml"
  ".github/workflows/agent-implement.yml"
  ".github/workflows/agent-review.yml"
  ".github/workflows/ci.yml"
  ".config/pip/pip.conf"
  "scripts/dev-setup.sh"
  "scripts/mint-factory-pat.sh"
  "scripts/check_file_size.py"
  ".pre-commit-config.yaml"
  ".editorconfig"
  ".gitattributes"
  ".gitignore"
  "LICENSE"
)
for rel in "${GENERIC[@]}"; do
  [ -f "$REF_DIR/$rel" ] || { echo "  skip (missing in reference): $rel"; continue; }
  echo "  copy  $rel"
  run mkdir -p "$DEST_DIR/$(dirname "$rel")"
  run cp -p "$REF_DIR/$rel" "$DEST_DIR/$rel"
done

# docs/agents/issue-tracker.md — copy and repoint to the new repo.
if [ -f "$REF_DIR/docs/agents/issue-tracker.md" ]; then
  echo "  copy  docs/agents/issue-tracker.md (repointed)"
  run mkdir -p "$DEST_DIR/docs/agents"
  if ! $DRY_RUN; then
    sed "s|$REFERENCE|$NAME|g" "$REF_DIR/docs/agents/issue-tracker.md" >"$DEST_DIR/docs/agents/issue-tracker.md"
  fi
fi

# --- 0b. generate clean per-repo files ---
echo "==> 0b. Generate per-repo files"
gen() { echo "  gen   $1"; $DRY_RUN && return 0; mkdir -p "$DEST_DIR/$(dirname "$1")"; cat >"$DEST_DIR/$1"; }

gen "skills-lock.json" <<'EOF'
{
  "homeRepo": {
    "repo": "@@OWNER@@/software-factory-example-home-repo",
    "ref": "@@HUBREF@@"
  }
}
EOF
subst "$DEST_DIR/skills-lock.json"

gen ".python-version" <<'EOF'
3.12
EOF

gen "pyproject.toml" <<'EOF'
[project]
name = "@@NAME@@"
version = "0.0.0"
description = "@@DESC@@"
requires-python = ">=3.12"
dependencies = []

[dependency-groups]
dev = [
    "ruff>=0.6",
    "mypy>=1.11",
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "bandit>=1.7",
    "pip-audit>=2.7",
    "pre-commit>=3.8",
]

# Resolve from public PyPI, overriding any token-gated global index. Integrity is
# still enforced by the hash-pinned uv.lock, so this changes the source, not the check.
[[tool.uv.index]]
url = "https://pypi.org/simple"
default = true

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/@@PKG@@"]

# --- Brakes configuration ---

[tool.ruff]
line-length = 100
target-version = "py312"
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "PL", "RUF"]

[tool.mypy]
python_version = "3.12"
strict = true
files = ["src", "tests"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=@@PKG@@ --cov-report=term-missing"

[tool.coverage.report]
show_missing = true
EOF
subst "$DEST_DIR/pyproject.toml"

gen "src/@@PKG@@/__init__.py" <<'EOF'
"""Scaffold package — replace with the real implementation."""


def healthcheck() -> bool:
    """A trivial seam so the brakes (mypy, pytest, coverage) have something to run."""
    return True
EOF
# gen() substitutes nothing; fix the package dir name and placeholders now.
if ! $DRY_RUN; then
  mv "$DEST_DIR/src/@@PKG@@" "$DEST_DIR/src/$PKG"
  subst "$DEST_DIR/src/$PKG/__init__.py"
fi

gen "tests/test_smoke.py" <<'EOF'
from @@PKG@@ import healthcheck


def test_healthcheck() -> None:
    assert healthcheck() is True
EOF
subst "$DEST_DIR/tests/test_smoke.py"

gen "CLAUDE.md" <<'EOF'
# @@NAME@@

@@DESC@@ Part of a multi-repo **software factory** (home-repo ADR-0001).

Read before proposing changes, and use their terms exactly:

- [`GLOSSARY.md`](GLOSSARY.md) — this repo's vocabulary (shared factory terms live in the hub).
- [`CODING_STANDARDS.md`](CODING_STANDARDS.md) — fuzzy rules the review brake enforces.
- [`docs/adr/`](docs/adr/) — Architecture Decision Records.

## The multi-repo factory

- **Hub** — [`software-factory-example-home-repo`](https://github.com/@@OWNER@@/software-factory-example-home-repo) (`../software-factory-example-home-repo`; clone if missing). **Read its `CLAUDE.md` to understand — or answer questions about — the whole factory** (brakes, accelerators, topology). Run *cross-repo* sessions from there.

## Agent skills

### Issue tracker

Issues and specs are tracked in this repo's **GitHub Issues** (via the `gh` CLI). See `docs/agents/issue-tracker.md`.
EOF
subst "$DEST_DIR/CLAUDE.md"

gen "README.md" <<'EOF'
# @@NAME@@

@@DESC@@

Part of a multi-repo software factory — see the hub:
<https://github.com/@@OWNER@@/software-factory-example-home-repo>.

## Local setup

```bash
./scripts/dev-setup.sh
```

## Brakes

`ruff`, `mypy --strict`, `pytest` (+coverage), plus `gitleaks` / `bandit` /
`pip-audit` / `actionlint`, run via pre-commit and the `brakes` CI check.
EOF
subst "$DEST_DIR/README.md"

gen "GLOSSARY.md" <<'EOF'
# Glossary — @@NAME@@

Repo-specific vocabulary. Shared, repo-independent factory vocabulary lives in the
hub's [`GLOSSARY.md`](../software-factory-example-home-repo/GLOSSARY.md) (see the hub's
`GLOSSARY-MAP.md`). Add only terms unique to this repo.
EOF
subst "$DEST_DIR/GLOSSARY.md"

gen "CODING_STANDARDS.md" <<'EOF'
# Coding standards

Fuzzy rules the **review** brake enforces, for things no automated check can express.
Grown and pruned via `/retro`. Empty to start.
EOF

run mkdir -p "$DEST_DIR/docs/adr"
$DRY_RUN || : >"$DEST_DIR/docs/adr/.gitkeep"

# --- 0c. lockfile + initial commit + create + push ---
echo "==> 0c. Lockfile, commit, create, push"
if command -v uv >/dev/null; then
  run bash -c "cd '$DEST_DIR' && uv lock"
else
  echo "  warn: uv not found — uv.lock NOT generated; run scripts/dev-setup.sh before the first CI run (brakes uses 'uv sync --locked')."
fi
run bash -c "cd '$DEST_DIR' && git init -q -b main && git add -A && git commit -q -m 'Scaffold factory child repo (new-factory-repo.sh)'"
run gh repo create "$OWNER/$NAME" --public --source="$DEST_DIR" --remote=origin --push --description "$DESCRIPTION"

# --- 1. branch protection ---
echo "==> 1. Branch protection (require 'brakes' strict, PRs, enforce admins, no force-push/delete)"
run gh api -X PUT "repos/$OWNER/$NAME/branches/main/protection" \
  --input - <<'EOF'
{
  "required_status_checks": { "strict": true, "contexts": ["brakes"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# --- 2. labels (mirror the reference) ---
echo "==> 2. Factory labels (mirrored from $REFERENCE)"
for l in agent:explore agent:implement agent:review agent:rebase; do
  meta="$(gh label list --repo "$OWNER/$REFERENCE" --json name,color,description \
    --jq ".[] | select(.name==\"$l\") | \"\(.color)\t\(.description)\"" 2>/dev/null || true)"
  color="${meta%%$'\t'*}"; desc="${meta#*$'\t'}"
  [ -n "$color" ] || { color="ededed"; desc="factory: $l"; }
  run gh label create "$l" --repo "$OWNER/$NAME" --color "$color" --description "$desc" --force
done

# --- 6 + manual steps ---
cat <<EOF

==> DONE (mechanical steps). Remaining — need a human:

  3. Secrets (run the wizard in the new repo):
       cd $DEST_DIR && ./scripts/mint-factory-pat.sh     # FACTORY_PAT (this repo only)
     Set the shared Anthropic WIF secrets (copy from $REFERENCE if reusing the rule):
       ANTHROPIC_FEDERATION_RULE_ID ANTHROPIC_ORGANIZATION_ID ANTHROPIC_SERVICE_ACCOUNT_ID ANTHROPIC_WORKSPACE_ID

  4. Anthropic WIF federation — point a rule at the new repo's immutable OIDC subject:
       gh api repos/$OWNER/$NAME --jq '{owner_id: .owner.id, repo_id: .id}'
     Then broaden an existing rule's subject prefix OR add a dedicated rule
     (subject prefix: repo:$OWNER@<owner_id>/$NAME@<repo_id>) and set ANTHROPIC_FEDERATION_RULE_ID.
     Verify in the Anthropic Console activity log: outcome: success.

  5. AWS OIDC (only if this repo deploys): add its subject to the terraform-<env> role trust.

  6. Wire into the hub — add to $HUB_DIR/CLAUDE.md and GLOSSARY-MAP.md:
       - **$NAME** — $DESCRIPTION Path: \`../$NAME\`. Clone from https://github.com/$OWNER/$NAME.git if missing.

  7. Smoke test — open a trivial issue ("add a line to the README") and confirm it
     auto-chains explore -> implement -> review to a ready PR. Then close it.
EOF
