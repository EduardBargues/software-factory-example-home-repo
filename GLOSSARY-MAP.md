# Glossary Map

This setup spans three repos. Shared, repo-independent factory vocabulary lives in the home repo's [`GLOSSARY.md`](./GLOSSARY.md); each repo adds its own repo-specific terms.

## Contexts

- [Shared factory](./GLOSSARY.md) — repo-independent factory vocabulary (home-repo pattern, tasks, brakes, feedback loop, shared auth). Lives in this home repo.
- [App (`software-factory-example-python`)](../software-factory-example-python/GLOSSARY.md) — the application domain and its deploy (two-tier deploy, apply-before-merge, hexagonal ports, the app's domain terms).
- [Terraform (`software-factory-example-terraform`)](../software-factory-example-terraform/GLOSSARY.md) — the module library (public/private modules, ephemeral apply, Terratest, IaC brakes).

> Paths assume the three repos are checked out as siblings. Each child is also reachable via the pointers in [`CLAUDE.md`](./CLAUDE.md) (clone from remote if missing).

## Relationships

- **Home repo → children**: the home repo points at both children (`CLAUDE.md`) and is the single source of truth for shared skills (each child pins a home-repo ref — see ADR-0002).
- **Terraform → App**: the Terraform repo publishes one public module (`modules/public/app`) as tagged releases; the App repo consumes it via a pinned `git::…?ref=<tag>` source and owns all persistent `apply` (see Terraform ADR-0001).
- **Shared ↔ children**: a term defined in the shared glossary must not be redefined in a child glossary; children only add terms unique to their context.
