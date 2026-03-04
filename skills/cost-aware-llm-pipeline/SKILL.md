# Cost-Aware LLM Pipeline Skill

Guidelines for choosing the right model for each task to maximize quality while managing cost.

## Model Selection Matrix

| Task | Model | Cost tier | Notes |
|------|-------|-----------|-------|
| Code generation & editing | Claude Sonnet | Medium | Best for agentic tasks |
| Web research & docs | Gemini 1.5 Flash | Low | Fast, 1M context |
| Large doc analysis (>100k tokens) | Gemini 1.5 Pro | Medium | Best large context |
| Code review, Q&A | GPT-4o-mini | Low | Fast, cheap, smart |
| Complex reasoning | GPT-4o | Medium | Strong logic |
| Long-form writing | Claude Opus | High | Only when quality must be exceptional |

## Rules
1. **Default to Sonnet** for coding tasks — it's the best cost/quality balance for code
2. **Use Flash instead of Pro** for Gemini unless the context exceeds 200k tokens
3. **Use GPT-4o-mini** for any classification, routing, or short Q&A tasks
4. **Reserve Opus** for final drafts of important written content only
5. **Never use Opus for code** — Sonnet is better for agentic coding tasks

## Cost Warning Triggers
- > 10 tool calls in a single session → consider breaking into smaller tasks
- Repeatedly sending large files as context → extract only the relevant sections
- Using Opus for anything other than writing → switch to Sonnet
