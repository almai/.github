# almai/.github

Org-level configuration for GitHub Copilot and community health files.

## Contents

| Path | Purpose |
|---|---|
| `.github/copilot-instructions.md` | Org-wide Copilot coding standards — copy into any repo's `.github/` to activate |

## Usage

To apply the org coding standards to a repository, copy the instructions file:

```bash
curl -sO https://raw.githubusercontent.com/almai/.github/main/.github/copilot-instructions.md
mkdir -p .github && mv copilot-instructions.md .github/
```

Or add it as a git submodule / copy it manually.
