#!/usr/bin/env bash
# Installs VibeDiscipline from this clone into an existing project.
# A stopgap until the `vibe` CLI ships.
#
# Usage:
#   scripts/install.sh <target-dir> [options]
#
# Options:
#   --skills-only         copy .agent/skills/ and nothing else
#   --methodology <m>     agile | waterfall | hybrid (default: hybrid)
#   --force               overwrite files that already exist in the target
#   --dry-run             print what would happen, change nothing
#
# Never overwrites an existing AGENTS.md, CLAUDE.md or .claude/settings.json
# permissions block, and never copies this repo's own state.md or
# stack.lock.yml.
set -euo pipefail

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""; SKILLS_ONLY=0; FORCE=0; DRY=0; METH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-only) SKILLS_ONLY=1 ;;
    --force) FORCE=1 ;;
    --dry-run) DRY=1 ;;
    --methodology) METH="${2:-}"; [ $# -gt 1 ] && shift ;;
    --methodology=*) METH="${1#--methodology=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "[vibe] unknown option '$1'" >&2; usage >&2; exit 2 ;;
    *) [ -z "$TARGET" ] || { echo "[vibe] one target directory only" >&2; exit 2; }; TARGET="$1" ;;
  esac
  shift
done
[ -n "$TARGET" ] || { usage >&2; exit 2; }
[ -d "$TARGET" ] || { echo "[vibe] not a directory: $TARGET" >&2; exit 2; }
TARGET="$(cd "$TARGET" && pwd)"
[ "$TARGET" != "$SRC" ] || { echo "[vibe] target is this VibeDiscipline clone itself" >&2; exit 2; }
case "$METH" in ""|agile|waterfall|hybrid) ;; *) echo "[vibe] unknown methodology '$METH'" >&2; exit 2 ;; esac

MARK_START="<!-- vibediscipline:start -->"
MARK_END="<!-- vibediscipline:end -->"
say() { echo "[vibe] $*"; }
run() { if [ "$DRY" -eq 1 ]; then echo "  would: $*"; else "$@"; fi; }

copy_tree() { # <relative dir>
  local f
  (cd "$SRC" && find "$1" -type f ! -name '.DS_Store') | sort | while IFS= read -r f; do
    case "$f" in .agent/state.md|.agent/stack.lock.yml|.agent/VERSION) continue ;; esac
    copy_file "$f"
  done
}

say "installing into $TARGET$([ "$DRY" -eq 1 ] && echo ' (dry run)')"
[ -d "$TARGET/.git" ] || say "note: $TARGET is not a git repository; git hooks will not be activated"

# copy_file <relative path>: skips a file the target already has, unless
# --force. It runs in a subshell under copy_tree's pipe, so skips are
# collected in a file.
SKIPLOG="$(mktemp)"; trap 'rm -f "$SKIPLOG"' EXIT
copy_file() {
  local rel="$1" dest="$TARGET/$1"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then echo "  $rel" >>"$SKIPLOG"; return 0; fi
  if [ "$DRY" -eq 1 ]; then echo "  would: copy $rel"; return 0; fi
  mkdir -p "$(dirname "$dest")"
  cp "$SRC/$rel" "$dest"
}

if [ "$SKILLS_ONLY" -eq 1 ]; then
  copy_tree .agent/skills
  [ -s "$SKIPLOG" ] && { say "kept existing files (use --force to overwrite):"; cat "$SKIPLOG"; }
  say "done: skills only. Nothing outside .agent/skills/ was touched."
  exit 0
fi

# ── .agent/ and scripts/ ────────────────────────────────────────────
copy_tree .agent
for s in check.sh compile-permissions.cjs set-methodology.cjs validate-portability.sh; do
  copy_file "scripts/$s"
done
[ "$DRY" -eq 1 ] || chmod +x "$TARGET"/scripts/check.sh "$TARGET"/scripts/validate-portability.sh 2>/dev/null || true

# This repo's own stack must not travel: recon detects the target's stack.
CFG="$TARGET/.agent/config.yml"
if [ "$DRY" -eq 0 ] && [ -f "$CFG" ] && ! grep -qxF '  .agent/config.yml' "$SKIPLOG" && grep -q '^stack:' "$CFG"; then
  awk '
    /^stack:/ { print "# stack: detected by the recon skill into .agent/stack.lock.yml."; print "# Add a `stack:` block here only to override what recon finds."; skip = 1; next }
    skip && /^[^[:space:]#]/ { skip = 0 }
    skip && /^[[:space:]]*$/ { skip = 0 }
    !skip
  ' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
fi

if [ "$DRY" -eq 1 ]; then
  echo "  would: write .agent/VERSION"
else
  printf '%s\ntier: governed\ninstalled: %s\n' "$(head -1 "$SRC/.agent/VERSION")" "$(date +%Y-%m-%d)" > "$TARGET/.agent/VERSION"
fi

# ── AGENTS.md: ours above theirs, between markers, once ─────────────
A="$TARGET/AGENTS.md"
if [ ! -f "$A" ]; then
  run cp "$SRC/AGENTS.md" "$A"
  say "AGENTS.md created"
elif grep -qF "$MARK_START" "$A" || grep -q 'This project uses \*\*VibeDiscipline\*\*' "$A"; then
  say "AGENTS.md already contains VibeDiscipline — left alone"
elif [ "$DRY" -eq 1 ]; then
  echo "  would: put VibeDiscipline's AGENTS.md above the existing content"
else
  { echo "$MARK_START"; cat "$SRC/AGENTS.md"; echo "$MARK_END"; echo; cat "$A"; } > "$A.tmp" && mv "$A.tmp" "$A"
  say "AGENTS.md: VibeDiscipline added above your existing content (kept)"
fi

# ── CLAUDE.md: a pointer only ───────────────────────────────────────
C="$TARGET/CLAUDE.md"
POINTER='See [AGENTS.md](./AGENTS.md) — the constitution for this repository.'
if [ ! -f "$C" ]; then
  if [ "$DRY" -eq 1 ]; then echo "  would: create CLAUDE.md (pointer to AGENTS.md)"; else
    printf '%s\nDo not duplicate its content here; edit AGENTS.md instead.\n' "$POINTER" > "$C"
  fi
elif grep -q 'AGENTS\.md' "$C"; then
  say "CLAUDE.md already points at AGENTS.md — left alone"
elif [ "$DRY" -eq 1 ]; then
  echo "  would: add an AGENTS.md pointer line above your CLAUDE.md content"
else
  { echo "$POINTER"; echo; cat "$C"; } > "$C.tmp" && mv "$C.tmp" "$C"
  say "CLAUDE.md: pointer to AGENTS.md added above your existing content (kept)"
fi

# ── methodology ─────────────────────────────────────────────────────
if [ -n "$METH" ]; then
  if [ "$DRY" -eq 1 ]; then echo "  would: set methodology to $METH"; else
    node "$TARGET/scripts/set-methodology.cjs" "$METH" >/dev/null && say "methodology: $METH"
  fi
fi

# ── compile permissions ─────────────────────────────────────────────
SETTINGS="$TARGET/.claude/settings.json"
if ! command -v node >/dev/null 2>&1; then
  say "node not found — permissions NOT compiled. Install Node, then run:"
  say "  node scripts/compile-permissions.cjs"
elif [ -f "$SETTINGS" ] && grep -q '"permissions"' "$SETTINGS" && ! grep -q 'GENERATED by scripts/compile-permissions' "$SETTINGS" && [ "$FORCE" -eq 0 ]; then
  say ".claude/settings.json already has its own permissions — NOT compiled, so"
  say "nothing of yours was replaced. To adopt the VibeDiscipline policy, move your"
  say "rules into .agent/permissions.yml and run: node scripts/compile-permissions.cjs"
elif [ "$DRY" -eq 1 ]; then
  echo "  would: node scripts/compile-permissions.cjs"
else
  (cd "$TARGET" && node scripts/compile-permissions.cjs) | sed 's/^/  /'
fi

if [ -s "$SKIPLOG" ]; then
  say "kept existing files (use --force to overwrite):"
  cat "$SKIPLOG"
fi

cat <<EOF

[vibe] done. Next:
  1. Edit .agent/permissions.yml for your stack (the shipped command lists
     are Laravel's), then re-run: node scripts/compile-permissions.cjs
  2. Open the project in Claude Code once and accept the trust dialog;
     until then the compiled allow-list is ignored.
  3. Ask your agent to run the recon skill. It writes .agent/stack.lock.yml.
  4. Review and commit the new files.
EOF
