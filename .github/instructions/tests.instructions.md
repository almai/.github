---
applyTo: "**/*.test.ts,**/*.test.tsx,**/*.spec.ts"
---

## Test file rules

- Use Vitest (`describe`, `it`, `expect`) — not Jest globals unless the project uses Jest.
- Each `it` block tests exactly one behaviour. One assertion focus per test.
- Test names are full sentences: `it('returns null when user is not found')`.
- Mock all I/O and external dependencies — no real network calls or file system writes in unit tests.
- Use `vi.mock()` at the top of the file for module mocks; prefer `vi.spyOn()` for partial mocks.
- Clean up mocks in `afterEach(() => vi.restoreAllMocks())`.
