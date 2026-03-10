# Security Scanner Skill

Comprehensive security audit for any project. Detects secrets, vulnerable dependencies, insecure code patterns, misconfigurations, and access control gaps. Produces a structured report with severity levels and actionable remediation.

## When to Use
- Before any production deployment
- After adding new dependencies
- When touching auth, payments, file uploads, or user input handling
- On a recurring schedule (weekly recommended for active projects)
- When onboarding a new project into the orchestrator
- After any security incident or dependency advisory

## Trigger
`/secscan [project-path]` — runs the full scan against the specified project directory.

## Severity Levels

| Level | Meaning | Action Required |
|-------|---------|-----------------|
| **CRITICAL** | Active exploit risk — secrets exposed, RCE vectors, auth bypass | Fix immediately. Block deployment. |
| **HIGH** | Significant vulnerability — injection flaws, known CVEs, missing auth | Fix before next deploy. |
| **MEDIUM** | Weakness that could be exploited under specific conditions | Fix within current sprint. |
| **LOW** | Minor hardening opportunity — informational headers, verbose errors | Fix when convenient. |
| **INFO** | Best-practice suggestion — no immediate risk | Log for future improvement. |

---

## Scan Procedure

### Phase 1: Project Detection

Identify the project type and tech stack by checking for marker files:

| Marker File | Stack | Dependency Audit Command |
|-------------|-------|--------------------------|
| `package.json` | Node.js / JavaScript / TypeScript | `npm audit --json` |
| `package-lock.json` | Node.js (locked) | `npm audit --json` |
| `yarn.lock` | Node.js (Yarn) | `yarn audit --json` |
| `pnpm-lock.yaml` | Node.js (pnpm) | `pnpm audit --json` |
| `requirements.txt` or `pyproject.toml` | Python | `pip audit --format json` |
| `Cargo.toml` | Rust | `cargo audit --json` |
| `go.mod` | Go | `govulncheck ./...` |
| `Gemfile` | Ruby | `bundle audit check` |
| `composer.json` | PHP | `composer audit --format json` |

If multiple markers exist (monorepo), scan each workspace independently.

### Phase 2: Secrets & Credentials Scan

Search the codebase and git history for leaked secrets. This is the highest-priority check — a single leaked key can compromise everything.

#### 2a. Codebase Scan — Grep for Secret Patterns

Scan all tracked files for these patterns. Exclude `node_modules/`, `.git/`, `vendor/`, `target/`, `dist/`, `build/`, `__pycache__/`, and lock files.

```
# API keys and tokens
Pattern: (AKIA[0-9A-Z]{16})                          → AWS Access Key
Pattern: (sk-[a-zA-Z0-9]{20,})                       → OpenAI / Stripe secret key
Pattern: (ghp_[a-zA-Z0-9]{36})                       → GitHub personal access token
Pattern: (gho_[a-zA-Z0-9]{36})                       → GitHub OAuth token
Pattern: (github_pat_[a-zA-Z0-9_]{82})               → GitHub fine-grained PAT
Pattern: (xox[bpors]-[a-zA-Z0-9-]{10,})              → Slack token
Pattern: (sk-ant-[a-zA-Z0-9-]{90,})                  → Anthropic API key
Pattern: (AIza[0-9A-Za-z_-]{35})                     → Google API key
Pattern: (ya29\.[0-9A-Za-z_-]+)                      → Google OAuth token
Pattern: (SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}) → SendGrid API key
Pattern: (rk_live_[a-zA-Z0-9]{24,})                  → Stripe restricted key
Pattern: (AC[a-f0-9]{32})                            → Twilio Account SID
Pattern: (npm_[a-zA-Z0-9]{36})                       → npm access token
Pattern: (v2\.public\.[a-zA-Z0-9_-]+)                → Paseto v2 public token

# Generic patterns (higher false positive rate — verify manually)
Pattern: (password|passwd|pwd)\s*[:=]\s*['"][^'"]{8,} → Hardcoded password
Pattern: (secret|token|key)\s*[:=]\s*['"][^'"]{8,}   → Hardcoded secret
Pattern: (Bearer\s+[a-zA-Z0-9_.~+/=-]{20,})         → Bearer token
Pattern: -----BEGIN\s+(RSA|EC|DSA|OPENSSH)\s+PRIVATE\s+KEY----- → Private key

# Connection strings
Pattern: (mongodb(\+srv)?://[^\s'"]+)                → MongoDB connection string
Pattern: (postgres(ql)?://[^\s'"]+)                  → PostgreSQL connection string
Pattern: (mysql://[^\s'"]+)                          → MySQL connection string
Pattern: (redis://[^\s'"]+)                          → Redis connection string
Pattern: (amqp://[^\s'"]+)                           → RabbitMQ connection string
```

**Important**: Ignore matches inside `*.example`, `*.sample`, `*.template` files, test fixtures with clearly fake values (e.g., `sk-test-1234`), and documentation. Flag everything else as **CRITICAL**.

#### 2b. Git History Scan — Check for Previously Committed Secrets

```bash
# Check if .env files were ever committed
git log --all --diff-filter=A -- '*.env' '.env.*' '.env.local' '.env.production'

# Check for large secret-like files ever added
git log --all --diff-filter=A -- '*.pem' '*.key' '*.p12' '*.pfx' '*.jks' '*.keystore'

# Search recent commit diffs for secret patterns
git log --all -p --since="90 days ago" -S "AKIA" -S "sk-" -S "BEGIN PRIVATE KEY"
```

If secrets are found in history, severity is **CRITICAL** — even if the file is now deleted, the secret is in the git history and must be rotated.

#### 2c. Environment File Checks

```
- [ ] .env is listed in .gitignore
- [ ] .env.local is listed in .gitignore
- [ ] .env.production is listed in .gitignore
- [ ] No .env files are currently tracked by git (git ls-files '*.env*')
- [ ] .env.example exists with placeholder values (not real secrets)
```

### Phase 3: Dependency Vulnerabilities

Run the appropriate audit command from Phase 1. Parse results and classify:

| Audit Severity | Mapped Level |
|----------------|-------------|
| critical | **CRITICAL** |
| high | **HIGH** |
| moderate | **MEDIUM** |
| low | **LOW** |

**Additional checks:**
- [ ] No dependencies pinned to `*` or `latest`
- [ ] Lock file exists and is committed
- [ ] No `--force` or `--legacy-peer-deps` in install scripts (masks resolution problems)
- [ ] Check for known malicious packages: cross-reference package names against recent advisory databases
- [ ] Check for typosquatting: flag any dependency with a name suspiciously similar to a popular package

### Phase 4: Insecure Code Patterns

Grep the source code for these vulnerability patterns. Context matters — review each match to determine if it is actually exploitable.

#### SQL Injection
```
Pattern: query\s*\(\s*['"`].*\$\{       → Template literal in SQL query
Pattern: query\s*\(\s*['"`].*\+\s*      → String concatenation in SQL query
Pattern: \.raw\s*\(\s*['"`].*\$\{       → Raw query with interpolation
Pattern: execute\s*\(\s*f['"]           → Python f-string in SQL (Python)
Pattern: execute\s*\(\s*['"].*%          → Python %-format in SQL (Python)
```
Severity: **HIGH** (CRITICAL if user input flows directly into the query)

#### Cross-Site Scripting (XSS)
```
Pattern: dangerouslySetInnerHTML        → React unescaped HTML injection
Pattern: innerHTML\s*=                  → Direct DOM HTML injection
Pattern: outerHTML\s*=                  → Direct DOM HTML injection
Pattern: document\.write\s*\(          → Document write
Pattern: \.html\s*\(                   → jQuery .html() with dynamic content
Pattern: v-html\s*=                    → Vue unescaped HTML directive
Pattern: \[innerHTML\]\s*=             → Angular innerHTML binding
Pattern: \| safe\b                     → Django/Jinja2 safe filter
Pattern: \{!! .* !!\}                  → Laravel Blade unescaped output
Pattern: <%- .* %>                     → EJS unescaped output
```
Severity: **HIGH** — verify that the content is sanitized before rendering. If sourced from user input without sanitization, escalate to **CRITICAL**.

#### Command Injection
```
Pattern: child_process.*exec\s*\(      → Node.js exec (shell)
Pattern: execSync\s*\(                 → Node.js synchronous exec
Pattern: spawn\s*\(\s*['"](?!node)     → Spawning arbitrary commands
Pattern: os\.system\s*\(              → Python os.system
Pattern: subprocess\.call\s*\(.*shell\s*=\s*True  → Python shell=True
Pattern: subprocess\.Popen\s*\(.*shell\s*=\s*True → Python shell=True
Pattern: eval\s*\(                     → JavaScript/Python eval
Pattern: Function\s*\(                 → JavaScript Function constructor
Pattern: new\s+Function\s*\(          → JavaScript Function constructor
Pattern: exec\s*\(                     → Python exec
Pattern: compile\s*\(                  → Python compile + exec chain
Pattern: unserialize\s*\(             → PHP object injection
Pattern: pickle\.loads?\s*\(          → Python pickle deserialization
Pattern: yaml\.load\s*\((?!.*Loader)  → Python unsafe YAML load
```
Severity: **CRITICAL** if user input can reach the call. **HIGH** otherwise.

#### Path Traversal
```
Pattern: \.\.\//                       → Relative path traversal
Pattern: req\.(params|query|body).*path → User input in file path
Pattern: fs\.(read|write|unlink).*req\. → Filesystem op with user input
Pattern: open\s*\(.*request\.          → Python file open with request data
```
Severity: **HIGH**

#### Prototype Pollution (JavaScript)
```
Pattern: Object\.assign\s*\(\s*\{\}   → Shallow merge (check source)
Pattern: \[req\.(body|query|params)    → Dynamic property access from input
Pattern: __proto__                     → Direct proto access
Pattern: constructor\.prototype        → Constructor prototype access
```
Severity: **MEDIUM**

### Phase 5: Configuration Issues

#### 5a. CORS Configuration
```
Pattern: cors\(\)                            → CORS with no options (allows all)
Pattern: origin:\s*['"]?\*['"]?             → CORS allows all origins
Pattern: Access-Control-Allow-Origin.*\*    → Permissive CORS header
Pattern: credentials:\s*true.*origin.*\*    → Credentials with wildcard origin
```
Severity: **HIGH** for wildcard + credentials. **MEDIUM** for wildcard alone.

#### 5b. Security Headers (Check for Absence)
The following headers should be set in production:
```
- [ ] Strict-Transport-Security (HSTS)
- [ ] Content-Security-Policy (CSP)
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY or SAMEORIGIN
- [ ] Referrer-Policy
- [ ] Permissions-Policy
```
If using Next.js, check `next.config.js` for `headers()`. If using Express, check for `helmet` middleware.
Severity: **MEDIUM** per missing header. **HIGH** if no security headers are set at all.

#### 5c. Debug & Logging
```
Pattern: console\.log\s*\(             → Console log (strip before production)
Pattern: console\.(debug|trace)\s*\(   → Debug logging
Pattern: DEBUG\s*=\s*True              → Django/Flask debug mode
Pattern: app\.debug\s*=\s*True         → Flask debug mode
Pattern: devtool.*eval                 → Webpack source maps exposing source
Pattern: stack.*trace.*error           → Stack traces leaked to client
```
Severity: **LOW** for console.log. **HIGH** for debug mode in production config.

#### 5d. Rate Limiting
Check for presence of rate limiting middleware:
```
- express-rate-limit (Node.js/Express)
- @nestjs/throttler (NestJS)
- slowapi / flask-limiter (Python)
- Rate limiting in API gateway config (nginx, Cloudflare, Vercel)
```
If no rate limiting is found on API routes: **MEDIUM**.
If no rate limiting on auth endpoints (login, register, password reset): **HIGH**.

#### 5e. .gitignore Completeness
Verify these entries exist:
```
- [ ] .env / .env.* / .env.local / .env.production
- [ ] node_modules/
- [ ] .next/ (Next.js)
- [ ] dist/ / build/ / out/
- [ ] *.pem / *.key / *.p12
- [ ] .DS_Store
- [ ] credentials.json / service-account*.json
- [ ] *.sqlite / *.db (local databases)
- [ ] coverage/ (test coverage reports)
```
Severity: **CRITICAL** if .env is missing from .gitignore. **MEDIUM** for other missing entries.

### Phase 6: Auth & Access Control

#### 6a. Authentication
```
Pattern: jwt\.sign\(.*expiresIn.*['"](\d+d)  → Check JWT expiry (>7 days is HIGH)
Pattern: jwt\.verify\s*\((?!.*algorithms)      → JWT verify without algorithm pinning
Pattern: algorithm.*['"]none['"]               → JWT "none" algorithm
Pattern: session.*secret.*['"][^'"]{0,15}['"]  → Weak session secret (<16 chars)
Pattern: bcrypt.*rounds?\s*[:=]\s*(\d+)       → Bcrypt rounds (<10 is MEDIUM)
Pattern: (md5|sha1)\s*\(                      → Weak hash for passwords
Pattern: password.*plain                       → Plaintext password handling
```

#### 6b. Access Control
```
- [ ] All API routes have auth middleware (check route definitions)
- [ ] Admin routes have role-based access checks
- [ ] Database queries are scoped to the authenticated user (RLS or WHERE user_id = ?)
- [ ] File uploads/downloads enforce ownership checks
- [ ] Webhook endpoints validate signatures before processing
- [ ] No direct object references without authorization (IDOR)
```
Severity: **HIGH** for missing auth on mutating endpoints. **CRITICAL** for missing auth on admin or payment endpoints.

### Phase 7: File Upload & Input Validation

```
Pattern: multer\s*\((?!.*fileFilter)          → Multer without file filter
Pattern: upload.*(?!.*mimetype)               → Upload handler without MIME check
Pattern: req\.(body|query|params)(?!.*valid)  → User input without validation
Pattern: enctype.*multipart(?!.*csrf)         → File upload form without CSRF token
Pattern: \.extension|\.ext(?!.*whitelist)     → File extension check (verify it's a whitelist, not blacklist)
```

**Required controls:**
- [ ] File type validated by MIME signature (magic bytes), not just extension
- [ ] Upload size limits are enforced server-side
- [ ] Uploaded files are stored outside the web root
- [ ] Filenames are sanitized or replaced with UUIDs
- [ ] Antivirus scanning for uploaded files (for high-security applications)

Severity: **HIGH** for missing MIME validation. **MEDIUM** for missing size limits.

### Phase 8: Infrastructure & Deployment

```
- [ ] HTTPS enforced (redirect HTTP → HTTPS or HSTS preload)
- [ ] No exposed debug endpoints (/debug, /trace, /status with sensitive info)
- [ ] No exposed admin panels without auth (/admin, /wp-admin, /phpmyadmin)
- [ ] No exposed source maps in production (.map files)
- [ ] Docker images use non-root user
- [ ] No secrets in Dockerfile or docker-compose.yml
- [ ] No privileged ports exposed unnecessarily
- [ ] Database not exposed to public internet
- [ ] Backup encryption at rest
```

Check deployment config files:
- `Dockerfile`, `docker-compose.yml` — secrets, root user, exposed ports
- `vercel.json`, `netlify.toml` — redirect rules, headers
- `nginx.conf`, `Caddyfile` — TLS config, proxy headers
- `fly.toml`, `render.yaml` — environment variables defined in plaintext

Severity: **CRITICAL** for exposed debug endpoints with sensitive data. **HIGH** for missing HTTPS.

---

## Report Format

Output the scan results as a structured markdown report:

```markdown
# Security Scan Report
**Project**: [name]
**Path**: [absolute path]
**Scanned**: [date]
**Stack**: [detected technologies]

## Summary
| Severity | Count |
|----------|-------|
| CRITICAL | X |
| HIGH     | X |
| MEDIUM   | X |
| LOW      | X |
| INFO     | X |

## Findings

### [CRITICAL] Title of finding
- **File**: `path/to/file.ts:42`
- **Pattern**: What was detected
- **Evidence**: The matching code snippet (redact actual secret values)
- **Risk**: What an attacker could do with this
- **Remediation**: Exact steps to fix
  1. Step one
  2. Step two

### [HIGH] Title of finding
...

## Passed Checks
- ✓ No .env files tracked by git
- ✓ Lock file committed
- ✓ CORS properly configured
...

## Recommendations
1. [Prioritized list of next actions]
2. ...
```

---

## Post-Scan Actions

1. **CRITICAL findings** — Block deployment. Create pipeline tasks for each finding with `high` priority assigned to `coder` agent. Notify the user immediately.
2. **HIGH findings** — Create pipeline tasks with `high` priority. Fix before next deploy.
3. **MEDIUM/LOW findings** — Log to the scan report. Create pipeline tasks with `medium`/`low` priority for the next sprint.
4. **Clean scan** — Log the result. Schedule the next scan.

## Agent Delegation

| Phase | Agent | Reason |
|-------|-------|--------|
| Pattern scanning (Phases 2, 4-7) | `reviewer` | Fast pattern matching and classification |
| Dependency audit (Phase 3) | `coder` | Needs to run CLI commands |
| Remediation implementation | `coder` | Writing fix code |
| Report writing | `reviewer` | Structured analysis output |
| Research (new vuln patterns) | `researcher` | Web search for latest advisories |

## Limitations

- Static analysis only — this skill does not execute code or perform dynamic/runtime testing
- Pattern matching may produce false positives — every finding must be verified in context
- Git history scan covers the last 90 days by default — for a full history audit, extend the range
- Does not replace penetration testing, SAST/DAST tools, or SOC2/compliance audits
- Dependency audit requires the respective CLI tool to be installed (`npm`, `pip-audit`, `cargo-audit`, etc.)
- Cannot detect business logic flaws, race conditions, or timing attacks

## Forbidden

- Never print or log actual secret values in the report — always redact (e.g., `sk-...XXXX`)
- Never commit scan reports containing unredacted secrets
- Never run `npm audit fix --force` automatically — present findings for human review
- Never dismiss a CRITICAL finding without explicit user acknowledgment
- Never skip the git history scan — deleted secrets are still compromised secrets
