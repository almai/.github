# Changelog

## 3.3

- `validate-skills.sh` now mechanically enforces items from the Validation
  Checklist that were previously manual-only: `metadata.version` presence,
  `CHANGELOG.md` existing with an entry for the current version,
  `evals/README.md` existing, a top-level `# Title` heading, `## When to Use
  This Skill` / `## Prerequisites` once the body exceeds ~100 lines, a
  `## Scripts` footer and a `## Troubleshooting`/`## Error Recovery`/failure-modes
  section when `scripts/` is bundled, and no YAML frontmatter in `references/*.md`.
- Fixed a body-extraction bug: the Contents/required-sections checks stopped
  reading past the first `---` horizontal rule inside the body (not just the
  frontmatter fence), silently skipping everything after it.

## 3.2

- `validate-skills.sh` honours a `SKILLS_DIR` override, so it can check `profile/dot-agents/skills/`.
- The install-line check now needs the tool and an install command on the same line, ignores comments and `.tsx` extensions, and also checks `sqlite3`, `tsx` and `.ts` scripts.
- An `## Error Recovery` or failure-modes section satisfies the Troubleshooting requirement.

## 3.1

- `## When to Use This Skill` and `## Prerequisites` are optional for bodies
  under ~100 lines, where they would only repeat the description.
- `.ts` scripts are allowed for skills that run inside a TypeScript project,
  with a `pnpm add -D tsx` install line next to the invocation.

## 3.0

- SOP is no longer a separate skill type. "Decide the skill type first" is
  now "Decide how much structure the skill needs": set the degree of freedom
  per step, and use the unattended add-on only when the skill runs with no
  human in the loop.
- `references/sop-authoring.md` cut down to the add-on: it points to
  `skill-design-principles.md` for what the general rules already cover
  (determinism, recovery, done-state, guards, concision) and keeps only input/
  output schemas, idempotency, observability, parallel-safety, error-recovery
  table and step tags, plus a manual self-check. It states that a step may
  stay high freedom when unattended if its result must fit the Output Schema.
- Moved "Script or CLI tool" from `sop-authoring.md` to
  `skill-design-principles.md`, since it applies to every skill.
- Removed `scripts/init_sop_skill.ts` and `scripts/validate_sop_skill.ts`
  (breaking). They needed `tsx` inside a TypeScript project, and nothing
  used them.
- `references/sop-template.md` frontmatter now includes `metadata.version`.

## 2.1

- Added authoring rules distilled from `docs/skills-prompt.md`'s 10-rule
  framework: `## Contents` index requirement extended to `SKILL.md` itself
  (not just reference files), a checklist-with-go-back-line workflow pattern,
  a self-verification loop pattern (with a rule to propose a 1-line fix for
  undocumented edge cases), a deterministic-hooks-for-hard-redlines principle
  (citing this repo's `secret-scan.sh`/`link-dotfiles.sh --force` as working
  examples), and a dependency-install-comment convention for scripts.
- `scripts/validate-skills.sh` now warns (not fails) on: body/reference over
  100 lines without a Contents index, and scripts using `yq`/`jq`/`gh`/`aws`/
  `terraform` without a nearby install-command comment.
- Added matching checkboxes to the Validation Checklist.
- Explicitly did not adopt a per-skill `model:` frontmatter field or
  model-tier calibration — pi's skill schema has no target-model field.
- Dogfooding: added `## Contents` indexes to this skill's own `SKILL.md` and
  `references/sop-template.md`; the Validation Checklist's final validator
  step now says to fix and re-run until it passes.

## 2.0

- Merged the `create-skills` and `plan-agent-sop` skills into this single
  authoring skill, eliminating overlapping triggers and conflicting conventions.
- Added `references/skill-design-principles.md` — progressive disclosure, degrees
  of freedom, and workflow/output patterns (from `create-skills`).
- Added `references/sop-authoring.md`, `references/sop-template.md`, and the
  `scripts/init_sop_skill.ts` / `scripts/validate_sop_skill.ts` scripts for
  authoring deterministic SOP/workflow skills (from `plan-agent-sop`).
- SKILL.md now branches on skill type (SOP / non-trivial / simple) and links the
  relevant reference.
- Description expanded with SOP/workflow triggers.
- Fixed broken `~/code/skl/` script and install paths to reflect the actual
  layout (`~/.agents/skills/<name>/`, `scripts/validate-skills.sh`).

## 1.0

- Initial version migrated from dotfiles.
