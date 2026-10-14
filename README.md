# almai/.github

Org-level configuration for GitHub Copilot and community health files.

## Contents

| Path | Purpose |
|---|---|
| `.github/copilot-instructions.md` | Org-wide Copilot coding standards — copy into any repo's `.github/` to activate |
| `.github/ISSUE_TEMPLATE/session-summary.yml` | Default issue form for session-summary logs (Outcome/Focus-Area classification, Commits, Decisions, Follow-ups, Notes) — applies automatically to any repo under this account without its own `ISSUE_TEMPLATE/` |
| `.github/ISSUE_TEMPLATE/bug-report.yml` | Default bug-report issue form (repro steps, expected/actual behaviour, version, OS) |
| `.github/ISSUE_TEMPLATE/feature-request.yml` | Default feature-request issue form (problem, proposed solution, alternatives, priority) |
| `.github/ISSUE_TEMPLATE/task.yml` | Default task issue form (description, acceptance criteria, implementation notes, parent epic, priority) |
| `.github/ISSUE_TEMPLATE/epic.yml` | Default epic issue form (goal, background, in/out of scope, acceptance criteria, child issues, priority, milestone) |

## Usage

To apply the org coding standards to a repository, copy the instructions file:

```bash
curl -sO https://raw.githubusercontent.com/almai/.github/main/.github/copilot-instructions.md
mkdir -p .github && mv copilot-instructions.md .github/
```

Or add it as a git submodule / copy it manually.

The issue templates need no copying — GitHub serves everything under
`.github/ISSUE_TEMPLATE/` here as the default template chooser for any repository under
this account that doesn't have its own `ISSUE_TEMPLATE/` folder, as long as this repo stays
public. The override is folder-level, not per-template: if a repository defines **any**
file of its own under `.github/ISSUE_TEMPLATE/`, none of the templates from here are used
for that repository — the whole set from here is replaced, not merged template-by-template.

`session-summary.yml`'s fields each carry their own usage hint (e.g. "pull the list from
`git log --oneline <range>`"), so filling it out mostly replaces the need for a separate
prompt — run the git log command(s) the hints point at, then fill the form in order.
