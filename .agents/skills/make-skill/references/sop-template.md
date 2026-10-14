# SOP Skill Template (Unattended Workflows)

## Contents

- Template (the fenced block below): frontmatter, Prerequisites, Input Schema,
  Procedure, Success Criteria, Error Recovery, Output Schema
- [Template Usage Notes](#template-usage-notes): `@command`, `@check`,
  `@output`, `@on-error` tags

Copy this template when a skill runs with no human in the loop (see
[sop-authoring.md](sop-authoring.md)). Interactive skills don't need it.

---

```markdown
---
name: <skill-name>
description: <One sentence: what it does. Second sentence: when to trigger. Include key phrases that should activate this SOP.>
metadata:
  version: "1.0"
---

# <Skill Title>

<One-line description of the workflow outcome.>

## Prerequisites

- [ ] <Required tool> is installed
- [ ] <Required permission> is granted
- [ ] <Required state> exists

Run `scripts/validate.sh` to verify.

## Input Schema

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| param1 | string | yes | - | Description |
| param2 | boolean | no | false | Description |
| param3 | string[] | no | [] | Description |

## Procedure

### Step 1: <Phase Name>

@check: <Pre-condition that must be true>

@command:
\`\`\`bash
<exact command to run>
\`\`\`

@output: <Expected result or format>

@on-error: <What to do if this step fails>

---

### Step 2: <Phase Name>

@check: <Pre-condition that must be true>

@command:
\`\`\`bash
<exact command to run>
\`\`\`

@output: <Expected result or format>

@on-error: <What to do if this step fails>

---

### Step N: <Final Phase>

@check: <Pre-condition that must be true>

@command:
\`\`\`bash
<exact command to run>
\`\`\`

@output: <Expected result or format>

## Success Criteria

All must be true for the SOP to be considered complete:

- [ ] <Verifiable outcome 1>
- [ ] <Verifiable outcome 2>
- [ ] <Verifiable outcome 3>

## Error Recovery

| Error Condition | Recovery Action |
|-----------------|-----------------|
| <Error 1> | <Action to take> |
| <Error 2> | <Action to take> |
| <Unrecoverable> | Abort and notify user |

## Output Schema

On success, this SOP produces:

\`\`\`json
{
  "status": "complete",
  "result": "<description>",
  "artifacts": ["<list of created files/resources>"]
}
\`\`\`
```

---

## Template Usage Notes

### @command Tags

Use `@command:` to mark executable blocks. This makes steps machine-parseable:

```markdown
@command:
\`\`\`bash
git checkout -b feature/xyz
\`\`\`
```

### @check Tags

Use `@check:` for idempotency guards:

```markdown
@check: Branch does not exist OR --force flag
```

### @output Tags

Use `@output:` to specify expected results:

```markdown
@output: New branch created, working directory clean
```

### @on-error Tags

Use `@on-error:` for recovery paths:

```markdown
@on-error: If branch exists, prompt user to use --force or choose different name
```
