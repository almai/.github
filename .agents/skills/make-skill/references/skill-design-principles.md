# Skill Design Principles

Design guidance for authoring effective skills. Read this when the skill being
built is non-trivial — multiple workflows, bundled resources, or branching logic.

## Table of contents

- [Concise is key](#concise-is-key)
- [Degrees of freedom](#degrees-of-freedom)
- [Progressive disclosure](#progressive-disclosure)
- [Workflow patterns](#workflow-patterns)
- [Output patterns](#output-patterns)
- [Verification loop](#verification-loop)
- [Deterministic hooks for hard redlines](#deterministic-hooks-for-hard-redlines)
- [What NOT to include](#what-not-to-include)

## Concise is key

The context window is a shared public good: system prompt, conversation history,
other skills' metadata, and the user request all compete for it.

**Default assumption: the agent is already smart.** Only add context the agent
does not already have. Challenge each line — "does this paragraph justify its
token cost?" Prefer concise examples over verbose explanation.

## Degrees of freedom

Match specificity to the task's fragility and variability:

| Freedom | Use when | Form |
|---|---|---|
| **High** | Multiple approaches valid; decisions are context-dependent | Text-based heuristics |
| **Medium** | A preferred pattern exists; some variation acceptable | Pseudocode / parameterized scripts |
| **Low** | Operations are fragile; consistency is critical; exact sequence required | Specific scripts, few parameters |

Think of the agent exploring a path: a narrow bridge with cliffs needs guardrails
(low freedom); an open field allows many routes (high freedom).

Freedom is set **per step**, not per skill. A mostly-guidance skill can still
have one low-freedom step that runs a script. A skill that runs with no human
in the loop pushes most steps toward low freedom; see
[sop-authoring.md](sop-authoring.md) for the few extra rules that applies.

### Script or CLI tool

Before bundling low-freedom logic as a skill script, decide whether it belongs
in a reusable CLI tool instead:

| Prefer a CLI tool when | Prefer a skill script when |
|---|---|
| Several skills or clients could use it | The logic is specific to this skill |
| It is complex enough to deserve its own tests | It is a simple validation or check |
| | It is glue between existing tools |

The skill then calls the tool, and its own scripts stay minimal.

## Progressive disclosure

Skills load in three levels to manage context:

1. **Metadata** (`name` + `description`) — always in context (~100 words)
2. **SKILL.md body** — loaded when the skill triggers (keep < 500 lines)
3. **Bundled resources** — loaded only as needed (scripts can run without being read)

**Core principle:** when a skill supports multiple variations, frameworks, or
options, keep only the core workflow and selection guidance in SKILL.md. Move
variant-specific details into separate `references/` files and link them.

**Guidelines:**

- Keep references **one level deep** from SKILL.md — every reference links
  directly from SKILL.md, not from another reference.
- For reference files longer than 100 lines, add a table of contents at the top.
  This applies to `SKILL.md` itself too: once the body passes ~100 lines, open
  it with a `## Contents` list matching its exact headings, so an agent
  previewing just the first 100 lines (e.g. via `head`) can jump straight to
  the section it needs instead of reading the whole file.
- Information lives in **either** SKILL.md **or** a reference — never duplicated.

### Pattern: domain-specific organization

For multi-domain skills, split by domain so irrelevant context never loads:

```
bigquery-skill/
├── SKILL.md            # overview + navigation
└── references/
    ├── finance.md      # revenue, billing metrics
    ├── sales.md        # opportunities, pipeline
    └── product.md      # API usage, features
```

When the user asks about sales, only `sales.md` is read. The same applies to
multi-framework skills (`aws.md` / `gcp.md` / `azure.md`).

## Workflow patterns

### Sequential

For complex tasks, give an overview near the top of SKILL.md, then numbered steps:

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

### Conditional

For branching logic, guide the agent through explicit decision points:

```markdown
1. Determine the modification type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow: [steps]
3. Editing workflow: [steps]
```

### Checklist with a go-back line

When step order matters and skipping or reordering a step is consequential,
give the agent a copy-pasteable checklist to paste into its own reply and
tick off as it progresses — this keeps state visible across a long tool-call
sequence instead of relying on the agent's memory of what it already did:

```markdown
- [ ] Step 1: Back up the target file
- [ ] Step 2: Apply the transformation
- [ ] Step 3: Run the validation script
      If validation fails, go back to Step 2, fix the mismatch, and
      re-run the check before ticking this box.
- [ ] Step 4: Commit
```

Every verification step in the checklist should carry its own explicit
fallback ("if X fails, go back to step N") rather than leaving the agent to
improvise a recovery path.

## Output patterns

Use when a skill must produce consistent output. Match strictness to need.

### Template pattern

For strict requirements (API responses, data formats), provide an exact template
and say "ALWAYS use this exact structure". For flexible guidance, provide a
sensible default and say "use your best judgment; adjust sections as needed".

### Examples pattern

When output quality depends on seeing examples, provide input/output pairs —
they convey desired style and detail level better than descriptions alone:

```markdown
## Commit message format

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

## Verification loop

End fragile or multi-step workflows with a self-check the agent runs against
its own output — a test command, a validation script, or a short rubric —
and loop (fix, re-run) until every check passes. Don't stop at "ran the
script"; the loop only counts as closed once the script's output is clean.

If a check fails because of an edge case the skill didn't anticipate, have
the agent propose a one-line addition to the relevant `references/` file
before finishing, instead of silently special-casing it in the conversation.
That keeps the lesson in the skill for next time rather than losing it when
the session ends.

## Deterministic hooks for hard redlines

Some rules must hold 100% of the time — a destructive command that must never
run unconfirmed, a threshold that always needs sign-off. Prose instructions
degrade under pressure or model variance; a rule like this belongs in a
pre-execution hook or guard script the agent is told to run, not in advice it
could rationalize around in a given turn.

This repo already has two working examples of the pattern to point to instead
of re-deriving one from scratch:

- `scripts/secret-scan.sh` + the pre-push git hook — blocks a push containing
  a secret instead of trusting every commit author to remember to check.
- `link-dotfiles.sh`'s bare `--force` guard — a repo-wide force-link used to
  silently overwrite machine-specific files; it now only *lists* what it would
  do, and the destructive path requires the explicit `--only <target> --force`
  (or `--force --all`) escape hatch. The guardrail is in the script, not in a
  comment telling the agent to be careful.

When a skill you're authoring has a redline like this, extract it into a
script under `scripts/` and have `SKILL.md` instruct the agent to run that
script rather than perform the risky step by hand.

## What NOT to include

A skill contains only files that directly support its function. Do **not** create:

- `README.md`, `INSTALLATION_GUIDE.md`, `QUICK_REFERENCE.md` (auxiliary docs)
- Notes about the process of creating the skill
- Setup/testing procedures meant for humans

These add clutter and confusion. The exception in this repo's convention is the
required `CHANGELOG.md` and `evals/` folder — see SKILL.md.
