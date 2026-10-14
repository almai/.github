---
name: make-skill
description: 'Create new agent skills, from short guidance skills to unattended SOP/workflow skills. Use when asked to "create a skill", "make a new skill", "scaffold a skill", "implement a skill", "build a skill", "add a skill", "create an SOP", "new workflow skill", or "agent-ready procedure". Also activate when executing a plan that includes creating a skill — even if the user does not literally say "make a skill". Generates SKILL.md with proper frontmatter, directory structure, and optional scripts/references/assets/templates folders, and covers skill-design principles (progressive disclosure, per-step degrees of freedom, checklists, verification loops, hooks) plus an add-on for skills that run with no human in the loop (input/output schemas, idempotency, step tags).'
metadata:
  version: "3.3"
---

# Make Skill

## Contents

- [When to Use This Skill](#when-to-use-this-skill)
- [Decide how much structure the skill needs](#decide-how-much-structure-the-skill-needs)
- [Prerequisites](#prerequisites)
- [Creating a New Skill](#creating-a-new-skill) — Steps 1–5
- [Skill Structure Example](#skill-structure-example)
- [Conventions](#conventions)
- [Validation Checklist](#validation-checklist)
- [Anti-patterns](#anti-patterns)
- [Troubleshooting](#troubleshooting)
- [References](#references)
- [Scripts](#scripts)

The single meta-skill for creating new agent skills, from short guidance skills
to workflows that run unattended. Use this when you need to scaffold a new
skill folder or generate a SKILL.md file.

**IMPORTANT — always activate this skill before creating any new skill, even when executing a plan. If a plan says "create a skill" or "scaffold a skill folder", read these conventions first.**

## When to Use This Skill

- User asks to "create a skill", "make a new skill", or "scaffold a skill"
- User asks to "implement a skill", "build a skill", or "add a skill"
- User asks to "create an SOP", build a "workflow skill", or an "agent-ready procedure"
- A plan you are executing includes creating a new skill directory
- User wants to add a specialized capability to their agent setup
- User needs to wrap a repeated workflow into a reusable, auto-discovered skill

## Decide how much structure the skill needs

There is one kind of skill. What varies is how much structure each step gets,
and whether anyone is watching the run. Answer both questions:

| Question | If yes… |
|---|---|
| **Is it more than one concern?** Multiple workflows, branching logic, fragile steps, or bundled scripts | Read **[references/skill-design-principles.md](references/skill-design-principles.md)**. Set the degree of freedom per step, and use the checklist, verification-loop and hook patterns where they fit. |
| **Does it run with no human in the loop?** Called headlessly, scheduled, or its output parsed by another agent or pipeline | Also read **[references/sop-authoring.md](references/sop-authoring.md)** and start the body from **[references/sop-template.md](references/sop-template.md)**. It adds input/output schemas, idempotency guards and step tags. |

If both answers are no, follow the steps below and keep the body short.

## Prerequisites

- A clear purpose: what does the skill accomplish and what prompts trigger it?
- A keyword-rich description covering WHAT it does and WHEN to invoke it
- Knowledge of any bundled resources needed (scripts, references, assets, templates)

## Creating a New Skill

### Step 1: Create the Skill Directory

Choose the right scope:

| Scope | Path | When |
|---|---|---|
| **Global** | `~/.agents/skills/<skill-name>/` | Useful across all projects |
| **Project** | `<repo>/.agents/skills/<skill-name>/` | Specific to one repo (takes precedence over a global skill of the same name) |

```
~/.agents/skills/<skill-name>/
└── SKILL.md          # Required
```

> If this machine uses the `~/code/skl` management layer (an `install.sh` that
> symlinks each skill into `~/.agents/skills/`), author the skill there and run
> `install.sh` to link it. If `~/code/skl/install.sh` is absent, author directly
> in `~/.agents/skills/<name>/` — the skills there are plain directories.

### Step 2: Generate SKILL.md with Frontmatter

Every skill requires YAML frontmatter with `name`, `description`, and `metadata.version`:

```yaml
---
name: <skill-name>
description: '<What it does>. Use when <specific triggers, scenarios, keywords>.'
metadata:
  version: "1.0"
---
```

#### Frontmatter Field Requirements

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | **Yes** | 1-64 chars, lowercase letters/numbers/hyphens only, must match folder name |
| `description` | **Yes** | 10-1024 chars, must describe WHAT it does AND WHEN to use it |
| `metadata.version` | **Yes** | SemVer string e.g. `"1.0"`. Bump minor for new features, major for breaking changes to the workflow. |

#### Description Best Practices

**CRITICAL**: The `description` is the PRIMARY mechanism for automatic skill discovery. Include:

1. **WHAT** the skill does (capabilities)
2. **WHEN** to use it (triggers, scenarios, keywords users might say)

**Good example:**

```yaml
description: 'Validates note frontmatter against a JSON schema. Use when asked to "validate notes", "check frontmatter", or after creating a new note.'
```

**Poor example:**

```yaml
description: 'Note checker'
```

### Step 3: Write the Skill Body

After the frontmatter, add markdown instructions. The body must stay **under 500 lines**. Link out to `references/` files for detailed material rather than inlining everything.

#### Required sections

Every skill body must include at least these:

| Section | Purpose |
|---------|---------|
| `# <Title>` | Brief overview of the skill |
| `## When to Use This Skill` | Reinforces description triggers — explicit list of scenarios |
| `## Prerequisites` | Required tools, environment, env vars |

For a body under ~100 lines, `## When to Use This Skill` and `## Prerequisites`
are optional. A good `description` already carries the triggers, so a short
skill can skip a section that would only repeat it. Add `## Prerequisites` back
if the skill needs a tool or env var the description doesn't mention.

#### Recommended sections

Add these as appropriate:

| Section | Purpose | When to include |
|---------|---------|-----------------|
| `## <Workflow sections>` | Numbered steps for each workflow the skill supports | Always — this is the skill's core value |
| `## Anti-patterns` | What NOT to do — common mistakes | When there are non-obvious pitfalls |
| `## Troubleshooting` | Common issues and solutions | When scripts or tools can fail. An `## Error Recovery` or failure-modes section counts; don't add both |
| `## References` | Links to bundled reference docs, scripts, and external resources | When the skill has `references/` or `scripts/` |
| `## Scripts` | Footer listing all scripts with one-line descriptions | When the skill has `scripts/` |

#### `## Scripts` footer convention

If your skill bundles scripts, end the body with a `## Scripts` section listing them:

```markdown
## Scripts

- `scripts/validate.mjs` — check all docs against the manifest
- `scripts/scaffold.sh` — create a new doc from a template
```

This makes scripts discoverable without reading the directory listing.

### Step 4: Create Required Companion Files

Two files are required alongside SKILL.md:

**`CHANGELOG.md`** — version history. Start with:
```markdown
# Changelog

## 1.0

- Initial version.
```

**`evals/README.md`** — evaluation artefacts. Create the folder and seed with:
```markdown
# Evals — <skill-name>

Record golden examples, failure notes, and hypothesis log entries here after each weekly skill health review.
```

### Step 5: Add Optional Directories (If Needed)

| Folder | Purpose | When to Use |
|--------|---------|-------------|
| `scripts/` | Executable automation | Deterministic operations the agent should run, not reason about |
| `references/` | Documentation the agent reads | Detailed knowledge the agent needs at runtime (decision trees, cheat sheets, API docs) |
| `assets/` | Static files used AS-IS | Diagrams, sample data |
| `templates/` | Starter code/docs the agent copies and modifies | Scaffolds to extend |
| `evals/` | Evaluation artefacts | Required — golden examples, failure notes, hypothesis log |

#### Script conventions

Scripts should be executable and self-contained. Use one of these languages:

| Extension | Runtime | When to use |
|-----------|---------|-------------|
| `.sh` | `bash` | Shell automation, pipeline orchestration, tools with CLI deps (`yq`, `jq`) |
| `.mjs` | `node` | Data processing, file manipulation, JSON/YAML parsing — zero-dep Node ESM |
| `.ts` | `tsx` | Only for skills that run inside a TypeScript project, where `tsx` is usually installed. Put the install line next to the invocation: `pnpm add -D tsx` |

Prefer `.mjs` for most scripts — it covers file I/O, JSON parsing, and validation with zero dependencies. Prefer `.sh` when the script primarily orchestrates CLI tools.

If a script needs anything beyond the runtime's stdlib (a CLI tool like `yq`/`jq`, an npm package, a pip package), put the exact install command in a comment directly above the first line that uses it — not in a separate setup doc the agent has to go find:

```bash
# scripts/check-frontmatter.sh — requires yq: brew install yq (or: go install github.com/mikefarah/yq/v4@latest)
name=$(yq '.name' .agents/skills/my-skill/SKILL.md)
```

This makes the skill work on a teammate's machine on day one without a missing-dependency failure mid-run.

```bash
# scripts/check-something.sh
#!/usr/bin/env bash
name=$(yq '.name' .agents/skills/my-skill/SKILL.md)
echo "Skill name: $name"
```

```javascript
// scripts/validate.mjs — Node ESM, zero deps
import { readdir, readFile } from 'node:fs/promises';
const files = await readdir('docs/', { recursive: true });
```

#### References conventions

Files in `references/` are markdown documents the agent reads at skill activation time. They should:

- Be plain `.md` files with **no frontmatter** (they are not docs — they are internal skill knowledge).
- Have a clear `# Title` and be self-contained.
- Focus on one concern per file (e.g., `authoring-decisions.md`, `frontmatter.md`).
- Use tables, decision trees, and worked examples — optimise for LLM consumption.

#### Template placement — inside skill vs. project-level

| Location | When |
|----------|------|
| `.agents/skills/<skill>/templates/` | Templates consumed only by this skill's workflow |
| Project-level (e.g., `docs/templates/`) | Templates that other skills, CI, or humans also use |

If a template is shared across workflows, keep it in the project and reference the path from the skill body. Don't duplicate.

## Skill Structure Example

```
.agents/skills/my-skill/
├── SKILL.md                    # Required — instructions and frontmatter (name, description, metadata.version)
├── CHANGELOG.md                # Required — version history
├── evals/
│   └── README.md               # Required — golden examples, failure notes, hypothesis log
├── scripts/
│   ├── validate.mjs            # Node ESM automation
│   └── helper.sh               # Bash automation
├── references/
│   ├── decision-tree.md        # How-to-choose guide for the agent
│   └── field-reference.md      # Lookup material
├── assets/
│   └── diagram.png             # Static resources
└── templates/
    └── starter.md              # Doc or code scaffold
```

## Conventions

- **Location**: global skills in `~/.agents/skills/<name>/`; project skills in `<repo>/.agents/skills/<name>/` (repo-local wins on name clash)
- **Frontmatter**: `name`, `description`, and `metadata.version` — required fields
- **Validation script**: `bash ~/.agents/skills/make-skill/scripts/validate-skills.sh` — validates every skill in the repo's `.agents/skills/`; set `SKILLS_DIR=<dir>` to check another directory
- **Existing skills as examples**: list contents of `~/.agents/skills/` for reference
- **Always activate this skill** before creating a new skill, even during plan execution
- **If using the `~/code/skl` layer**: author there and run its `install.sh` to symlink the skill into `~/.agents/skills/`, then commit. Absent that layer, author directly in `~/.agents/skills/<name>/`.

## Validation Checklist

- [ ] Folder name is lowercase with hyphens and matches `name:` exactly
- [ ] `description` is 10-1024 characters and explains both WHAT and WHEN
- [ ] `metadata.version` is set (e.g. `"1.0"`)
- [ ] `CHANGELOG.md` exists with an entry for the current version
- [ ] `evals/README.md` exists
- [ ] Body content is under 500 lines
- [ ] Body has a `## Contents` index at the top if it exceeds ~100 lines (see [references/skill-design-principles.md](references/skill-design-principles.md#progressive-disclosure))
- [ ] Body has required sections: `# Title`, `## When to Use This Skill`, `## Prerequisites` (the last two are optional when the body is under ~100 lines)
- [ ] Fragile/consequential multi-step workflows use a copy-pasteable `- [ ]` checklist with a "go back to step N" fallback on verification steps (see [references/skill-design-principles.md](references/skill-design-principles.md#checklist-with-a-go-back-line))
- [ ] Workflow ends with a self-verification loop (run a check, fix, re-run until clean) where applicable (see [references/skill-design-principles.md](references/skill-design-principles.md#verification-loop))
- [ ] Scripts with non-stdlib dependencies document the install command next to the invocation
- [ ] Any hard safety/business redline is enforced by a script/hook, not left as prose-only advice (see [references/skill-design-principles.md](references/skill-design-principles.md#deterministic-hooks-for-hard-redlines))
- [ ] Body has `## Scripts` footer if scripts are bundled
- [ ] Body has `## Troubleshooting` (or an `## Error Recovery` / failure-modes section) if scripts or tools can fail
- [ ] Bundled assets are under 5MB each
- [ ] Reference files have no frontmatter
- [ ] Scripts use `.sh` or `.mjs` extensions; `.ts` only for skills that run inside a TypeScript project, with a `pnpm add -D tsx` install line
- [ ] For skills that run with no human in the loop: the self-check in [references/sop-authoring.md](references/sop-authoring.md#self-check) passes
- [ ] `bash ~/.agents/skills/make-skill/scripts/validate-skills.sh` passes.
      If it reports an error, fix it and re-run until it passes before ticking
      this box. Treat its ⚠️ warnings for the new skill as items to fix too.

## Anti-patterns

- **Don't skip `metadata.version`** — it enables skill health tracking and meaningful changelogs.
- **Don't inline long reference material** — if a section exceeds ~50 lines, move it to `references/` and link to it.
- **Don't skip the `## Scripts` footer** — scripts are invisible to the agent unless listed somewhere in the body.
- **Don't put project-shared templates inside the skill** — if CI or humans also use a template, it belongs at project level.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Skill not auto-discovered | Add more keywords and trigger phrases to `description` |
| Skill not activated during plan execution | Ensure `description` includes verbs like "implement", "build", "add" — not just "create" |
| Name validation fails | Ensure lowercase, no consecutive hyphens, matches folder name exactly |
| Script fails to run | `.sh`: check deps are available. `.mjs`: check `node` is available. `.ts`: run `pnpm add -D tsx` in the target project |
| Description too short | Add capabilities, triggers, and keywords until purpose is unambiguous |
| Body too long | Move detailed material to `references/` — keep SKILL.md as the execution checklist |

## References

- [references/skill-design-principles.md](references/skill-design-principles.md) — progressive disclosure, per-step degrees of freedom, workflow/output patterns, checklists, verification loops, hooks; read for any non-trivial skill
- [references/sop-authoring.md](references/sop-authoring.md) — add-on for skills that run with no human in the loop: input/output schemas, idempotency, step tags
- [references/sop-template.md](references/sop-template.md) — copy-paste SKILL.md template for unattended skills

## Scripts

- `scripts/validate-skills.sh` — validates every skill in the repo's `.agents/skills/`, or in `SKILLS_DIR=<dir>` (frontmatter, name, body length, asset sizes, Contents index, script install comments)
