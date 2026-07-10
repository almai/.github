---
applyTo: "**/*.ts,**/*.tsx"
---

## TypeScript-specific rules

- Enable strict mode in `tsconfig.json` (`"strict": true`).
- Never use `any` — use `unknown` and narrow with a type guard, or use a specific type.
- Prefer `type` over `interface` for object shapes unless declaration merging is needed.
- Use Zod for runtime validation; derive the TypeScript type with `z.infer<typeof Schema>`.
- All exported async functions must declare their return type explicitly.
- Use `satisfies` instead of `as` when you want type checking without widening.
