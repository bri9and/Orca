---
name: db-drizzle-postgres
description: Enforce safe Drizzle + Postgres patterns — migrations, parameterized queries, schema discipline. Use when working with database schema, queries, or migrations.
---

# Drizzle + Postgres

Safely design, modify, and query a Postgres database using Drizzle.

## Rules

- All schema changes must go through migrations
- Never modify production schema without explicit confirmation
- Keep schema definitions centralized in `/db/schema`
- Use typed queries via Drizzle — avoid raw SQL unless necessary
- Validate all external inputs before DB operations

## Migrations

- Generate migration for every schema change: `npx drizzle-kit generate`
- Name migrations clearly and sequentially
- Never edit old migrations — create new ones
- Review migration SQL before applying

## Query Safety

- Use parameterized queries only — never interpolate user input
- Avoid dynamic SQL string building
- Limit query scope — avoid full table scans unless required
- Always consider indexes for new queries
- Use `.limit()` and `.where()` — no unbounded selects

## Data Integrity

- Enforce constraints at DB level (not just app logic)
- Use transactions for multi-step operations
- Be explicit about nullability and defaults
- Add `NOT NULL` unless there's a reason for nullable

## Anti-Patterns (block these)

- Editing schema directly without migration
- Silent data mutations
- Skipping validation before DB writes
- Over-fetching with `SELECT *`
- Missing indexes on foreign keys
