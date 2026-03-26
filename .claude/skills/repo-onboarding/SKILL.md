---
name: repo-onboarding
description: Map a repository's structure, stack, and risk areas before making any changes. Use when starting work on a new or unfamiliar codebase.
argument-hint: "[path to repo]"
---

# Repo Onboarding

Quickly understand a repository before making changes.

## Steps

1. Identify framework and language
2. Identify package manager and dependencies
3. Identify test commands (`test`, `lint`, `typecheck`)
4. Identify key services (DB, auth, APIs, billing)
5. Map directory structure (top 2 levels)
6. Read README, CLAUDE.md, .env.example if they exist

If `$ARGUMENTS` is provided, use that as the repo path. Otherwise use the current working directory.

## Output

Return a short summary covering:
- **Stack**: language, framework, package manager
- **Commands**: dev, build, test, lint, typecheck
- **Services**: database, auth, external APIs
- **Risk areas**: auth, billing, infra, migrations
- **Structure**: key directories and what they contain
