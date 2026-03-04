# Search First Skill

Always research before implementing. This skill enforces a research-before-coding workflow.

## When to Use
- Before implementing ANY new feature
- When working with an unfamiliar library or API
- When debugging a mysterious error

## Steps

1. **Formulate search queries** — Be specific. Include version numbers and framework names
2. **Search official documentation first** — Always prefer the official docs over blog posts
3. **Search GitHub issues** — For library-specific problems, GitHub issues often have the real answer
4. **Synthesize findings** — Summarize what you found in 3-5 bullet points
5. **Identify the recommended pattern** — Based on research, state what the implementation should look like
6. **Only then code** — Pass findings to `coder` agent

## Forbidden
- Implementing from memory alone for any external library
- Using deprecated APIs found in old blog posts without verifying current status
- Assuming version compatibility without checking

## Output Format
Brief research summary with sources, then pass to `coder` with clear implementation guidance.
