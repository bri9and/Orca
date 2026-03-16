# Security Rules

## Authentication & Sessions
- JWT sessions must never exceed 7 days; always implement refresh token rotation
- Never build custom auth; use Clerk, Supabase, or Auth0
- Never hardcode API keys; always use process.env variables
- Never commit .env files; always add to .gitignore before first commit

## Secure API Development
- Rotate all secrets on a 90-day cycle minimum
- Verify every suggested package for known CVEs before installing
- Prefer newer, actively maintained package versions unless a breaking change is confirmed
- Run `npm audit` after every build; only apply fixes after human review — never run `npm audit fix --force` autonomously
- Sanitize all user inputs using parameterized queries — never interpolate raw input into queries

## API & Access Control
- Enable Row-Level Security in the database from day one — never defer this
- Strip all console.log statements before any production deployment
- Configure CORS to restrict access to the allow-listed production domain only
- Validate all redirect URLs against an explicit allow-list
- Apply authentication and rate limiting to every endpoint — no exceptions

## Data & Infrastructure
- Enforce per-user AI API cost caps in both code and provider dashboard
- Add DDoS protection via Cloudflare or Vercel edge config on all public deployments
- Storage access must be scoped so users can only read/write their own files
- Validate file uploads by MIME signature, never by file extension alone
- Verify webhook signatures cryptographically before processing any payment data

## Environment & Operations
- Keep test and production environments fully separate — no shared credentials, no shared DBs
- Never allow webhooks to touch real systems in the test environment
- Enforce server-side permission checks on every privileged action — UI-level checks are not security
- Log all critical actions: deletions, role changes, payments, and data exports
- Build explicit account deletion flows that purge all user data — partial deletion creates compliance risk
- Automate backups and include a restore test in the automation — an untested backup is not a backup
