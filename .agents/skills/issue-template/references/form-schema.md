# GitHub Issue Form Schema

Use this quick reference while creating `.yml` forms in `.github/ISSUE_TEMPLATE/`. GitHub's full schema can change; consult the linked documentation when a field or constraint is uncertain.

## File and top-level keys

- Use a `.yml` extension. Forms belong in `.github/ISSUE_TEMPLATE/`.
- Required top-level keys are nonblank strings `name` and `description`, plus a nonempty `body` array. GitHub requires a template name longer than three characters.
- Optional keys: `title` (string), `labels` (strings or comma-delimited string), `assignees` (strings or comma-delimited string), `type` (string), and `projects` (strings or comma-delimited string).
- Do not add YAML document separators (`---`) or unsupported top-level keys.

## Form elements

Every body item has a supported `type` and an `attributes` mapping. Supported types:

| Type | Use | Required attributes |
|---|---|---|
| `markdown` | Short static instructions or context; not submitted | `value` |
| `input` | One-line response | `label` |
| `textarea` | Longer response; may allow attachments | `label` |
| `dropdown` | Selection from a defined set | `label`, nonempty `options` |
| `checkboxes` | Independent acknowledgements or choices | `label`, nonempty `options` with a `label` per option |
| `upload` | File upload | `label` |

`id` is optional except for markdown, where it is not supported. Use unique IDs made only of letters, numbers, `-`, or `_`. All user-input fields need distinct labels; checkbox-option labels must also be distinct from one another and other input labels. Similar labels can normalize to the same field reference, so choose clearly distinct labels or give colliding fields unique IDs.

Common attributes include `description`, `placeholder`, and `value` for text fields. Textareas also support `render` to format submitted content as code. Dropdowns support `multiple`, `options`, and an integer `default` index. Checkboxes use `options` entries with a `label` and optional boolean `required`. A `validations` mapping can set boolean `required`; `input` and `textarea` also support nonnegative integer `min_length`.

## Common validation pitfalls

- Quote strings that YAML could interpret as booleans or numbers, especially dropdown choices such as `"Yes"`, `"No"`, and `"1.0"`.
- Keep options unique and nonempty. Do not use reserved `None`; when a dropdown has a default, do not include `None` or `n/a`.
- Include at least one user-input element; markdown alone is not a usable form.
- Keep keys within the top-level, element, and attribute schema. Avoid boolean-like words as YAML keys.
- Provide all required attributes, use the expected scalar/list/map types, and avoid blank strings.
- Do not use sensitive-data terms in input labels; GitHub blocks some labels that could solicit credentials.

## Official references

- [About issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- [Configuring issue templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)
- [Syntax for issue forms](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
- [Syntax for GitHub's form schema](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-githubs-form-schema)
- [Common validation errors](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/common-validation-errors-when-creating-issue-forms)
