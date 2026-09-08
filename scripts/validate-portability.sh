#!/usr/bin/env bash
# Enforces the one-way dependency rule (plan Section 8): the skills layer
# (.agent/skills/**) must never hard-depend on repo-layer paths — it may
# only reference them inside an explicit "if present / if it exists"
# conditional, since the same skill files get copied standalone into
# other projects that have none of these files.
#
# This is a heuristic, not a full parser: it flags any mention of a
# repo-layer path and requires nearby context language showing the
# reference is conditional. False positives are possible — read the
# flagged line before assuming it's a real violation.
set -uo pipefail

SKILLS_DIR=".agent/skills"
# Only match paths that appear in inline code formatting (`docs/...`),
# since a bare "docs/" can legitimately appear as a branch-naming example
# (e.g. "docs/<slug>" inside a fenced code block) without being a real
# reference to the docs/ directory.
FORBIDDEN='`docs/|`\.agent/permissions\.yml|`\.agent/config\.yml|`\.agent/adapters/|`\.agent/stack\.lock\.yml|`\.agent/state\.md'
CONDITIONAL='exists|present|missing|stale|otherwise|else$|only\)|ships in v0\.2'

VIOLATIONS=0

while IFS= read -r -d '' file; do
  # The config-resolution contract itself documents these paths as the
  # very thing being made conditional — it is the rule, not a violation
  # of it.
  if [ "$(basename "$file")" = "config-resolution.md" ]; then
    continue
  fi
  while IFS= read -r line; do
    lineno="${line%%:*}"
    content="${line#*:}"
    # Skip lines that are clearly inside the config-resolution ladder's
    # own conditional structure or a markdown table/code fence label.
    if echo "$content" | grep -qE "$CONDITIONAL"; then
      continue
    fi
    # Look 2 lines before and 2 lines after for conditional context —
    # prose often wraps "if X exists" across a line break either way.
    total_lines=$(wc -l < "$file")
    end=$((lineno+2)); [ "$end" -gt "$total_lines" ] && end="$total_lines"
    context=$(sed -n "$((lineno>2 ? lineno-2 : 1)),${end}p" "$file")
    if echo "$context" | grep -qiE "$CONDITIONAL"; then
      continue
    fi
    echo "POSSIBLE VIOLATION  $file:$lineno"
    echo "  $content"
    VIOLATIONS=$((VIOLATIONS + 1))
  done < <(grep -nE "$FORBIDDEN" "$file" || true)
done < <(find "$SKILLS_DIR" -name '*.md' -print0)

echo ""
if [ "$VIOLATIONS" -gt 0 ]; then
  echo "[vibe] $VIOLATIONS possible portability violation(s) found."
  echo "[vibe] each flagged skill file may hard-depend on a repo-layer path."
  echo "[vibe] fix: wrap the reference in an explicit 'if present' condition,"
  echo "[vibe] per .agent/skills/_shared/config-resolution.md."
  exit 1
fi

echo "[vibe] portability check passed — no hard repo-layer dependency found"
echo "[vibe] in $SKILLS_DIR (heuristic scan)."
exit 0
