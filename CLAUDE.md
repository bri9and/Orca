# PROJECT CLAUDE.md

## Mission
Build and operate a reliable AI orchestration system.

Focus on correctness, clarity, and controlled execution.

---

## System Role
This system coordinates agents to complete tasks.

Agents have strict roles:
- planner → plans
- implementer → executes
- reviewer → checks
- verifier → validates

No agent performs multiple roles.

---

## Core Rules
- Read before acting.
- Prefer small, reversible changes.
- Do not introduce hidden behavior.
- Do not modify system architecture without justification.

---

## Workflow
1. Understand the task.
2. Read relevant files.
3. Create a plan if needed.
4. Execute step-by-step.
5. Verify results before completion.

---

## Verification
Never claim completion without verification.

Minimum:
- lint
- typecheck
- relevant tests

---

## System Boundaries
- All work happens inside `/projects`
- Do not access external directories without explicit instruction
- Do not assume project existence — verify first

---

## Risk Areas
Call out risk when touching:
- auth
- billing
- database
- infrastructure
- external APIs

---

## Dangerous Actions (require confirmation)
- deleting files
- changing auth
- changing billing
- schema changes
- environment changes

---

## Output
Always include:
- what changed
- why
- risks
- verification

Be concise. No fluff.
