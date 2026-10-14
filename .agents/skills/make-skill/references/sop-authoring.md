# Unattended Workflows (SOP Add-on)

An add-on to the normal skill rules, not a separate skill type. Read it only
when a skill runs **without a human in the loop**: an agent or pipeline calls it
headlessly, a scheduled job runs it, or another skill consumes its result.

Interactive skills, where the user watches and can step in, don't need anything
here. [skill-design-principles.md](skill-design-principles.md) already covers
them: low-freedom steps, checklists with go-back lines, verification loops and
deterministic hooks.

## Contents

- [When this add-on applies](#when-this-add-on-applies)
- [Already covered by the general rules](#already-covered-by-the-general-rules)
- [What to add](#what-to-add)
- [Step tags](#step-tags)
- [Self-check](#self-check)

## When this add-on applies

Apply it when **all** of these hold:

- The skill has a clear start state and a verifiable end state.
- It must run the same way every time.
- Nobody is available to answer a question mid-run, or its output is parsed by
  a machine rather than read by a person.

If any of these is false, write a normal skill and leave this file aside.

## Already covered by the general rules

Don't restate these in an unattended skill. Follow the linked rule instead:

| Need | General rule |
|---|---|
| Fixed, named tool sequence; no "choose an approach" | [Degrees of freedom](skill-design-principles.md#degrees-of-freedom), low freedom |
| Recovery path when a step fails | [Checklist with a go-back line](skill-design-principles.md#checklist-with-a-go-back-line) |
| Verifiable "done" state | [Verification loop](skill-design-principles.md#verification-loop) |
| Guard that must never be skipped | [Deterministic hooks](skill-design-principles.md#deterministic-hooks-for-hard-redlines) |
| Short, imperative, under 500 lines | [Concise is key](skill-design-principles.md#concise-is-key) |

Unattended doesn't mean every step is low freedom. A step may stay high
freedom when unattended if its result must fit the Output Schema; that schema
bounds the step instead of a fixed command.

## What to add

These matter only when no one is watching:

| Section / property | Why it matters unattended |
|---|---|
| `## Input Schema`: name, type, required, default, description | The caller can't be asked for a missing value. Every input needs a type and a default or a hard failure. |
| `## Output Schema`: the JSON emitted on success (status, result, artifacts) | Another agent or pipeline parses the result. Prose isn't a contract. |
| **Idempotent**: each mutating step opens with an `@check` guard; upsert over insert | A retried or re-scheduled run must not duplicate or corrupt state. |
| **Observable**: step IDs and success/failure lines in `@output` | Nobody saw the run. The log is the only record of where it stopped. |
| **Parallelizable**: unique per-run working dir; no shared `/tmp/work` | Two runs may overlap. |
| `## Error Recovery`: table of error condition → action | Recovery can't be improvised by a human. Each known failure needs a fixed action, including "stop and report". |

Start from [sop-template.md](sop-template.md), which already contains these
sections.

## Step tags

Inside `## Procedure`, make each step machine-parseable:

```markdown
### Step 1: Create branch

@check: Branch does not exist OR --force flag set
@command:
` ` `bash
git checkout -b feature/xyz
` ` `
@output: step=1 status=ok branch=feature/xyz
@on-error: Branch exists and no --force → stop, emit status=error reason=branch-exists
```

- `@check`: pre-condition or idempotency guard (binary: holds / doesn't hold).
- `@command`: the exact command(s) to run.
- `@output`: the expected result, in the format the Output Schema promises.
- `@on-error`: the fixed recovery path for that step. Unattended means no
  "ask the user"; stop and report instead.

## Self-check

Run `scripts/validate-skills.sh` for the general checks. Then confirm by hand:

- [ ] Input Schema, Procedure, Success Criteria, Error Recovery and Output
      Schema sections are present.
- [ ] Every mutating step has an `@check`, and every `@on-error` ends in a
      fixed action, never "ask the user".
- [ ] No step depends on a shared fixed temp path.
      If any box fails, go back to the step it names, fix it, and re-check.
