#!/usr/bin/env bash
# Validates all Agent Skills in a skills directory
# Requires yq (mikefarah v4+) and jq — brew install yq jq
# Usage: bash validate-skills.sh                 (checks <repo>/.agents/skills)
#        SKILLS_DIR=<dir> bash validate-skills.sh  (checks another skills dir)

SKILLS_DIR="${SKILLS_DIR:-$(git rev-parse --show-toplevel)/.agents/skills}"
TOTAL_ERRORS=0
VALID=0

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "No .agents/skills/ directory found — skipping"
  exit 0
fi

mapfile -t FOLDERS < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ ${#FOLDERS[@]} -eq 0 ]]; then
  echo "No skill folders found — skipping"
  exit 0
fi

echo "Validating ${#FOLDERS[@]} skill folder(s) in $SKILLS_DIR..."
echo ""

for folder in "${FOLDERS[@]}"; do
  folder_name="$(basename "$folder")"
  skill_file="$folder/SKILL.md"
  folder_errors=0

  echo "Checking $folder_name..."

  # SKILL.md must exist
  if [[ ! -f "$skill_file" ]]; then
    echo "  ❌ Missing SKILL.md"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    continue
  fi

  # Extract frontmatter block (lines between first pair of ---)
  frontmatter=$(awk 'BEGIN{found=0} /^---/{found++; if(found==2) exit; next} found==1{print}' "$skill_file")

  if [[ -z "$frontmatter" ]]; then
    echo "  ❌ No YAML frontmatter found in SKILL.md"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    continue
  fi

  # Parse name and description using yq from stdin
  name=$(printf '%s\n' "$frontmatter" | yq '.name // ""' 2>/dev/null || echo "")
  description=$(printf '%s\n' "$frontmatter" | yq '.description // ""' 2>/dev/null || echo "")

  # --- Validate name ---
  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "  ❌ name: required and must be a string"
    folder_errors=$((folder_errors + 1))
  else
    name_len=${#name}
    valid_chars=true
    has_double_hyphen=false

    # Check character set
    if ! printf '%s' "$name" | grep -qE '^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$'; then
      valid_chars=false
    fi
    # Check consecutive hyphens
    if printf '%s' "$name" | grep -q '\-\-'; then
      has_double_hyphen=true
    fi

    if [[ "$valid_chars" == false ]]; then
      echo "  ❌ name: must be lowercase letters, numbers, hyphens; must not start/end with a hyphen"
      folder_errors=$((folder_errors + 1))
    elif [[ "$has_double_hyphen" == true ]]; then
      echo "  ❌ name: must not contain consecutive hyphens"
      folder_errors=$((folder_errors + 1))
    elif [[ $name_len -lt 1 || $name_len -gt 64 ]]; then
      echo "  ❌ name: must be 1–64 characters (got $name_len)"
      folder_errors=$((folder_errors + 1))
    elif [[ "$name" != "$folder_name" ]]; then
      echo "  ❌ name: \"$name\" does not match folder name \"$folder_name\""
      folder_errors=$((folder_errors + 1))
    fi
  fi

  # --- Validate description ---
  if [[ -z "$description" || "$description" == "null" ]]; then
    echo "  ❌ description: required and must be a string"
    folder_errors=$((folder_errors + 1))
  else
    desc_len=${#description}
    if [[ $desc_len -lt 10 ]]; then
      echo "  ❌ description: must be at least 10 characters (got $desc_len)"
      folder_errors=$((folder_errors + 1))
    elif [[ $desc_len -gt 1024 ]]; then
      echo "  ❌ description: must not exceed 1024 characters (got $desc_len)"
      folder_errors=$((folder_errors + 1))
    fi
  fi

  # --- Validate metadata.version ---
  version=$(printf '%s\n' "$frontmatter" | yq '.metadata.version // ""' 2>/dev/null || echo "")
  if [[ -z "$version" || "$version" == "null" ]]; then
    echo "  ❌ metadata.version: required (e.g. \"1.0\")"
    folder_errors=$((folder_errors + 1))
  fi

  # --- CHANGELOG.md must exist and document the current version ---
  changelog="$folder/CHANGELOG.md"
  if [[ ! -f "$changelog" ]]; then
    echo "  ❌ CHANGELOG.md: missing"
    folder_errors=$((folder_errors + 1))
  elif [[ -n "$version" && "$version" != "null" ]] && ! grep -qE "^##+ ${version//./\\.}([[:space:]]|\$)" "$changelog"; then
    echo "  ❌ CHANGELOG.md: no entry for current version \"$version\""
    folder_errors=$((folder_errors + 1))
  fi

  # --- evals/README.md must exist ---
  if [[ ! -f "$folder/evals/README.md" ]]; then
    echo "  ❌ evals/README.md: missing"
    folder_errors=$((folder_errors + 1))
  fi

  # --- Warn if body is long ---
  body_lines=$(awk 'BEGIN{found=0} /^---/{found++; if(found==2){printing=1; next}} printing{print}' "$skill_file" | wc -l | tr -d ' ')
  if [[ $body_lines -gt 500 ]]; then
    echo "  ⚠️  body: $body_lines lines (recommended max 500)"
  fi

  # --- Required sections: # Title always; When to Use / Prerequisites once body exceeds ~100 lines ---
  body_text=$(awk 'BEGIN{found=0} /^---/{found++; if(found==2){printing=1; next}} printing{print}' "$skill_file")
  if ! grep -qE '^# ' <<<"$body_text"; then
    echo "  ❌ body: missing a top-level '# Title' heading"
    folder_errors=$((folder_errors + 1))
  fi
  if [[ $body_lines -gt 100 ]]; then
    if ! grep -qE '^##+ When to Use This Skill$' <<<"$body_text"; then
      echo "  ⚠️  body: $body_lines lines but no '## When to Use This Skill' section"
    fi
    if ! grep -qE '^##+ Prerequisites$' <<<"$body_text"; then
      echo "  ⚠️  body: $body_lines lines but no '## Prerequisites' section"
    fi
  fi

  # --- Scripts/Troubleshooting footers when applicable ---
  if [[ -d "$folder/scripts" ]] && ! grep -qE '^##+ Scripts$' <<<"$body_text"; then
    echo "  ⚠️  scripts/ bundled but no '## Scripts' footer in the body"
  fi
  if [[ -d "$folder/scripts" ]] && ! grep -qiE '^##+ (Troubleshooting|Error Recovery|Failure [Mm]odes)' <<<"$body_text"; then
    echo "  ⚠️  scripts/ bundled but no '## Troubleshooting' or '## Error Recovery' section"
  fi

  # --- Reference files must have no frontmatter ---
  if [[ -d "$folder/references" ]]; then
    while IFS= read -r -d '' ref_file; do
      if head -1 "$ref_file" | grep -qE '^---[[:space:]]*$'; then
        rel="${ref_file#"$folder/"}"
        echo "  ❌ $rel: reference files must not have YAML frontmatter"
        folder_errors=$((folder_errors + 1))
      fi
    done < <(find "$folder/references" -type f -name '*.md' -print0)
  fi

  # --- Warn if a long body/reference lacks a Contents index ---
  if [[ $body_lines -gt 100 ]]; then
    if ! awk 'BEGIN{found=0} /^---/{found++; next} found==2' "$skill_file" | grep -qE '^##+ Contents$'; then
      echo "  ⚠️  body: $body_lines lines but no '## Contents' index"
    fi
  fi
  for ref_dir in references; do
    if [[ -d "$folder/$ref_dir" ]]; then
      while IFS= read -r -d '' ref_file; do
        ref_lines=$(wc -l < "$ref_file" | tr -d ' ')
        if [[ $ref_lines -gt 100 ]] && ! grep -qE '^##+ (Contents|Table of contents)$' "$ref_file"; then
          rel="${ref_file#"$folder/"}"
          echo "  ⚠️  $rel: $ref_lines lines but no Contents/Table of contents index"
        fi
      done < <(find "$folder/$ref_dir" -type f -name '*.md' -print0)
    fi
  done

  # --- Warn if a script uses a common non-stdlib tool without an install line ---
  # The install line must name the tool and an install command on the same line,
  # e.g. "# Requires gh — brew install gh" or "// Requires tsx — pnpm add -D tsx".
  if [[ -d "$folder/scripts" ]]; then
    w='(^|[^a-zA-Z0-9_.-])'; e='([^a-zA-Z0-9_-]|$)'
    inst='(brew install|apt-get install|go install|pip install|pnpm add|npm install|npm i )'
    while IFS= read -r -d '' script_file; do
      rel="${script_file#"$folder/"}"
      # Usage = code lines only (shebang counts; comments and marked lines don't).
      code=$(grep -vE '^[[:space:]]*(#[^!]|#$|//|\*|/\*)|lint-ignore-install' "$script_file")
      for tool in yq jq gh aws terraform sqlite3 tsx; do  # lint-ignore-install
        if grep -qE "${w}${tool}${e}" <<<"$code" \
          && ! grep -qiE "${w}${tool}${e}.*${inst}|${inst}.*${w}${tool}${e}" "$script_file"; then
          echo "  ⚠️  $rel: uses '$tool' but has no install line (tool + install command on one line)"
        fi
      done
    done < <(find "$folder/scripts" -type f \( -name '*.sh' -o -name '*.mjs' -o -name '*.ts' \) -print0)
  fi

  # --- Check asset file sizes (5MB limit) ---
  MAX_SIZE=$((5 * 1024 * 1024))
  for asset_dir in scripts references assets templates; do
    if [[ -d "$folder/$asset_dir" ]]; then
      while IFS= read -r -d '' asset_file; do
        size=$(stat -f%z "$asset_file" 2>/dev/null || stat -c%s "$asset_file" 2>/dev/null || echo 0)
        if [[ $size -gt $MAX_SIZE ]]; then
          rel="${asset_file#"$folder/"}"
          size_mb=$(echo "$size" | awk '{printf "%.2f", $1/1024/1024}')
          echo "  ❌ asset: $rel exceeds 5MB limit (${size_mb}MB)"
          folder_errors=$((folder_errors + 1))
        fi
      done < <(find "$folder/$asset_dir" -type f -print0)
    fi
  done

  if [[ $folder_errors -eq 0 ]]; then
    echo "  ✅ valid"
    VALID=$((VALID + 1))
  else
    TOTAL_ERRORS=$((TOTAL_ERRORS + folder_errors))
  fi
done

echo ""
if [[ $TOTAL_ERRORS -eq 0 ]]; then
  echo "🎉 All $VALID skill(s) passed validation"
  exit 0
else
  echo "❌ Validation failed with $TOTAL_ERRORS error(s)"
  exit 1
fi
