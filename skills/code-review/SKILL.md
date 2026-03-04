# Code Review Skill

Structured code review workflow using the `reviewer` agent.

## When to Use
- After any significant implementation (> 50 lines changed)
- Before merging to main
- When touching auth, payments, or data handling (always)

## Steps

1. **Identify scope** — Which files were changed?
2. **Delegate to reviewer** — Pass the file list and context to `reviewer` agent  
3. **Categorize findings** — Critical / Warning / Suggestion
4. **Fix critical issues** — Pass back to `coder` agent for fixes
5. **Re-review** — Run reviewer again after fixes
6. **Document** — Note any accepted warnings and why they were accepted

## Checklist
- [ ] Security: no secrets, injection risks, auth bypasses
- [ ] Types: no `any`, proper error types
- [ ] Tests: does this need new tests?
- [ ] Docs: does this change any documented behavior?
