# Org-Wide Coding Standards

These instructions apply to all Copilot sessions. Follow them for every change,
regardless of task scope.

---

## TypeScript Structure

- **Barrel exports:** every domain folder under `src/` must have an `index.ts`
  that re-exports its public API. Never import a file directly when its barrel
  already re-exports it (`import { foo } from './foo'` → `import { foo } from '.'`).
- **Depth limit:** max 3 levels under `src/`. (`src/auth/middleware/jwt.ts` ✅ — `src/a/b/c/d.ts` ❌)
- **Filenames:** kebab-case `.ts` — e.g. `user-service.ts`, `auth-middleware.ts`.
  Tests: co-located as `<name>.test.ts`.
- **No top-level mutable state:** no module-level `let` or `var`. Use `const`
  or encapsulate state inside a class/closure.
- **No debug leftovers:** no `console.*` or `debugger` in library code.
  Use the structured logger instead.

## Folder Naming

| Pattern | Use for |
|---|---|
| Plural (`types/`, `schemas/`, `utils/`, `handlers/`, `services/`, `adapters/`) | Generic categories |
| Singular (`auth/`, `builder/`, `parser/`, `cli/`) | Specific domains |

**Where does new code go?**

```
Shared type / interface      → types/
Validation schema            → schemas/
Business logic               → {domain}/ matching its concern
External integration         → adapters/ or {service-name}/
Reusable utility             → utils/
Configuration                → config file at src/ root
Entry point / server         → src/ root
Public API export            → add to the domain's index.ts barrel
```

## Design Principles

- **Deep modules:** prefer simple interfaces over simple implementations.
  Push complexity inward so callers need minimal knowledge to use a module.
- **Information hiding:** only export what callers need. Everything not in the
  barrel is private to the module.
- **No pass-through functions:** a function that only delegates to another
  function adds interface surface without hiding anything — inline it or merge it.
- **No wide interfaces:** functions with 5+ parameters should use an options
  object or be decomposed into smaller operations.
- **Single responsibility:** every file and folder has one clear reason to change.

## Validation at Boundaries

Any function in `services/`, `handlers/`, `tools/`, or `mcp/` that accepts
external input must validate it with a Zod schema before use. Never trust
unvalidated input inside domain logic.

## Cohesion

Split a file when its exports serve unrelated consumers (different reasons to
change) or mix abstraction levels. Keep code together when it forms a single
pipeline or concern. A 200-line cohesive file is better than three fragmented ones.

Comments explain **why**, not what. Complex logic, non-obvious workarounds, and
"why not the obvious approach" deserve a comment. Self-evident code does not.
