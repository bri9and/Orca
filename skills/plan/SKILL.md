# Plan Skill

Invoke this skill to create a structured implementation plan before writing any code.

## When to Use
- When given a feature request or task with unclear scope
- Before starting any coding work
- When a task involves multiple files or systems

## Steps

1. **Understand the request** — Ask clarifying questions if anything is ambiguous
2. **Research** — Delegate to `researcher` agent to check for existing solutions
3. **List affected files** — Identify what will be created, modified, or deleted
4. **Write the plan** — Create a numbered, ordered plan with agent assignments
5. **Identify risks** — Call out anything uncertain or risky
6. **Get approval** — Present the plan before executing

## Output
A markdown plan document saved to `./plans/[feature-name].md` in the current project.
