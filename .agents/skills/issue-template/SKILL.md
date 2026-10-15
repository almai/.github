---
name: issue-template
description: 'Designs, creates, and improves sophisticated GitHub issue forms in `.github/ISSUE_TEMPLATE/` using GitHub’s YAML form schema. Use when asked to create, add, revise, or validate an issue template or issue form.'
metadata:
  version: "1.0"
---

# Issue Template

Create clear, actionable GitHub issue forms that gather the minimum information maintainers need to triage and resolve an issue.

## When to Use This Skill

- Create a new issue form or convert an existing issue template to an issue form.
- Improve or validate a `.yml` file in `.github/ISSUE_TEMPLATE/`.

## Prerequisites

- Work from the repository root and use the existing issue forms as local examples.
- `scripts/validate.sh` requires Ruby; it uses only Ruby's standard library.

## Workflow

- [ ] 1. Identify the report type, its audience, and the decisions maintainers need to make. Check existing forms and repository labels/types to avoid overlap or inventing metadata.
- [ ] 2. Design a short flow: use markdown blocks for brief context, required fields only for information essential to triage, and optional fields for useful but nonessential details. Prefer a dropdown for a small, stable set of choices; use text fields for open-ended answers. Never request passwords, access tokens, or other secrets.
- [ ] 3. Create or edit `.github/ISSUE_TEMPLATE/<descriptive-name>.yml`. Use GitHub issue forms (not Markdown frontmatter); include unique, descriptive field labels and stable `id` values, clear prompts and examples, and only valid top-level and field-schema keys. Set `title`, `labels`, `type`, `projects`, or `assignees` only when their values are appropriate for this repository.
- [ ] 4. Run `bash .agents/skills/issue-template/scripts/validate.sh .github/ISSUE_TEMPLATE/<descriptive-name>.yml`. If it fails, fix the reported form and rerun this step until it passes.
- [ ] 5. Review the rendered flow mentally as a reporter: every question is understandable, required fields are justified, dropdown choices are distinct, and submitted answers will make a useful issue. If not, go back to Step 2, revise, and rerun Step 4.

Keep forms focused: avoid redundant questions, broad “anything else” requirements, oversized dropdowns, and copied boilerplate that does not fit the report type. If a request is specifically about security vulnerabilities, direct reporters to the repository’s security reporting policy rather than collecting sensitive details in a public issue.

## References

- [Form schema and field guidance](references/form-schema.md)
- [GitHub issue-form syntax](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)
- [Configuring issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [Common issue-form validation errors](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/common-validation-errors-when-creating-issue-forms)

## Troubleshooting

- **The validator reports a schema problem:** correct the indicated key, type, label, identifier, or option and rerun it. The script checks common authoring errors; GitHub remains the final authority for its evolving form schema.
- **GitHub does not show the form:** confirm it is a `.yml` file in `.github/ISSUE_TEMPLATE/` on the default branch, and that its `name`, `description`, and `body` are valid.
- **The form asks for information that is unavailable or sensitive:** make the field optional or remove it; never ask for credentials or private keys.

## Scripts

- `scripts/validate.sh` — checks one issue form or every `.yml` form in a directory for common GitHub schema validation errors.
