# TDD Workflow Skill

Test-driven development loop for all new features.

## When to Use
- Building any new function, class, or API endpoint
- When fixing a bug (write a test that catches it first)

## Steps

1. **Define the interface** — What does this function take and return? Write the type signatures first
2. **Write a failing test (RED)** — Test only the public interface, not implementation details
3. **Run the test** — Confirm it fails for the right reason
4. **Write minimal implementation (GREEN)** — Write the least code needed to pass
5. **Run tests again** — Confirm they pass
6. **Refactor (IMPROVE)** — Clean up without breaking tests
7. **Check coverage** — Aim for 80%+ on new code

## Test Naming Convention
```
describe('functionName', () => {
  it('should [expected behavior] when [condition]', () => {
  })
})
```

## Forbidden
- Writing implementation before tests
- Testing implementation details (private methods, internal state)
- Mocking everything (mock only external dependencies)
- Skipping the refactor step
