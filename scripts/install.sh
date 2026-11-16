#!/usr/bin/env bash
# Installs VibeDiscipline from this clone into an existing project.
# A stopgap until the `vibe` CLI ships.
#
# Usage:
#   scripts/install.sh <target-dir> [options]
#
# Options:
#   --skills-only         copy .agent/skills/ and nothing else
#   --stack <s>           auto | laravel | node | python | generic (default: auto)
#                         picks the permissions.yml preset for a new install
#   --methodology <m>     agile | waterfall | hybrid (default: hybrid)
#   --upgrade             refresh skills, packs, adapters and scripts in a
#                         project that already has VibeDiscipline; keeps
#                         config.yml, permissions.yml and state.md
#   --force               overwrite files that already exist in the target
#   --dry-run             print what would happen, change nothing
#
# Never overwrites an existing AGENTS.md, CLAUDE.md or .claude/settings.json
# permissions block, and never copies this repo's own state.md or
# stack.lock.yml.
set -euo pipefail

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }

SRC="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""; SKILLS_ONLY=0; FORCE=0; DRY=0; METH=""; STACK="auto"; UPGRADE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --skills-only) SKILLS_ONLY=1 ;;
    --force) FORCE=1 ;;
    --dry-run) DRY=1 ;;
    --upgrade) UPGRADE=1 ;;
    --stack) STACK="${2:-}"; [ $# -gt 1 ] && shift ;;
    --stack=*) STACK="${1#--stack=}" ;;
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
case "$STACK" in auto|laravel|node|python|generic) ;; *) echo "[vibe] unknown stack '$STACK'" >&2; exit 2 ;; esac
if [ "$UPGRADE" -eq 1 ] && [ ! -d "$TARGET/.agent/skills" ]; then
  echo "[vibe] nothing to upgrade: $TARGET has no .agent/skills. Run without --upgrade to install." >&2
  exit 2
fi

# `init` on top of an existing install would keep every old script and
# skill and only rewrite the version file, leaving a half-updated project.
if [ "$UPGRADE" -eq 0 ] && [ "$FORCE" -eq 0 ] && [ "$SKILLS_ONLY" -eq 0 ] && [ -d "$TARGET/.agent/skills" ] && [ -f "$TARGET/AGENTS.md" ]; then
  HAVE="$(head -1 "$TARGET/.agent/VERSION" 2>/dev/null || true)"
  echo "[vibe] VibeDiscipline ${HAVE:-(unknown version)} is already installed in $TARGET"
  echo "[vibe] nothing was changed. To update it to $(head -1 "$SRC/.agent/VERSION"), run:"
  echo "[vibe]   vibe upgrade        (or: scripts/install.sh <dir> --upgrade)"
  exit 0
fi

MARK_START="<!-- vibediscipline:start -->"
MARK_END="<!-- vibediscipline:end -->"
say() { echo "[vibe] $*"; }
run() { if [ "$DRY" -eq 1 ]; then echo "  would: $*"; else "$@"; fi; }

copy_tree() { # <relative dir>
  local f
  (cd "$SRC" && find "$1" -type f ! -name '.DS_Store') | sort | while IFS= read -r f; do
    case "$f" in .agent/state.md|.agent/stack.lock.yml|.agent/VERSION|.agent/presets/*) continue ;; esac
    copy_file "$f"
  done
}

say "installing into $TARGET$([ "$DRY" -eq 1 ] && echo ' (dry run)')"
[ -d "$TARGET/.git" ] || say "note: $TARGET is not a git repository; git hooks will not be activated"

# copy_file <relative path>: skips a file the target already has, unless
# --force. It runs in a subshell under copy_tree's pipe, so skips are
# collected in a file.
SKIPLOG="$(mktemp)"; UPDLOG="$(mktemp)"; trap 'rm -f "$SKIPLOG" "$UPDLOG"' EXIT
# What VibeDiscipline owns and an upgrade may replace. Everything else an
# existing project has (config, permissions, state) is the project's.
owned() { case "$1" in .agent/skills/*|.agent/ecosystems/*|.agent/adapters/*|scripts/*) return 0 ;; esac; return 1; }
copy_file() {
  local rel="$1" dest="$TARGET/$1"
  if [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ] || { [ "$UPGRADE" -eq 1 ] && owned "$rel"; }; then
      cmp -s "$SRC/$rel" "$dest" && return 0
      echo "  $rel" >>"$UPDLOG"
    else
      echo "  $rel" >>"$SKIPLOG"; return 0
    fi
  fi
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
for s in check.sh compile-permissions.cjs vibe-guard.cjs bridge-claude.cjs set-methodology.cjs validate-portability.sh; do
  copy_file "scripts/$s"
done
[ "$DRY" -eq 1 ] || chmod +x "$TARGET"/scripts/check.sh "$TARGET"/scripts/validate-portability.sh 2>/dev/null || true

# ── permissions preset for the target's stack (new installs only) ───
detect_stack() {
  if [ -f "$TARGET/artisan" ] || [ -f "$TARGET/composer.json" ]; then echo laravel
  elif [ -f "$TARGET/pyproject.toml" ] || [ -f "$TARGET/manage.py" ] || [ -f "$TARGET/setup.py" ] || ls "$TARGET"/requirements*.txt >/dev/null 2>&1; then echo python
  elif [ -f "$TARGET/package.json" ]; then echo node
  else echo generic; fi
}
if grep -qxF '  .agent/permissions.yml' "$SKIPLOG"; then
  say "permissions.yml: yours was kept"
else
  if [ "$STACK" = "auto" ]; then STACK="$(detect_stack) (detected)"; fi
  PRESET="${STACK%% *}"
  if [ "$PRESET" != "laravel" ] && [ "$DRY" -eq 0 ]; then
    cp "$SRC/.agent/presets/permissions.$PRESET.yml" "$TARGET/.agent/permissions.yml"
  fi
  say "permissions preset: $STACK"
fi

# This repo's own config (its stack, its stricter check settings, its
# ignore list) must not travel: a new install gets the clean template.
if ! grep -qxF '  .agent/config.yml' "$SKIPLOG" && [ "$DRY" -eq 0 ]; then
  cp "$SRC/.agent/presets/config.yml" "$TARGET/.agent/config.yml"
fi

if [ "$DRY" -eq 1 ]; then
  echo "  would: write .agent/VERSION"
else
  WAS="$(sed -n 's/^installed: //p' "$TARGET/.agent/VERSION" 2>/dev/null | head -1 || true)"
  printf '%s\ntier: governed\ninstalled: %s\n' "$(head -1 "$SRC/.agent/VERSION")" "${WAS:-$(date +%Y-%m-%d)}" > "$TARGET/.agent/VERSION"
  if [ "$UPGRADE" -eq 1 ]; then echo "upgraded: $(date +%Y-%m-%d)" >> "$TARGET/.agent/VERSION"; fi
fi

# ── AGENTS.md: ours above theirs, between markers, once ─────────────
A="$TARGET/AGENTS.md"
if [ ! -f "$A" ]; then
  run cp "$SRC/AGENTS.md" "$A"
  say "AGENTS.md created"
elif [ "$UPGRADE" -eq 1 ] && grep -qF "$MARK_START" "$A" && grep -qF "$MARK_END" "$A"; then
  # Replace only what sits between the markers; the project's own text stays.
  if [ "$DRY" -eq 1 ]; then echo "  would: refresh the VibeDiscipline block in AGENTS.md"; else
    awk -v s="$MARK_START" -v e="$MARK_END" -v f="$SRC/AGENTS.md" '
      $0 == s { print; while ((getline line < f) > 0) print line; skip = 1; next }
      $0 == e { skip = 0 }
      !skip' "$A" > "$A.tmp" && mv "$A.tmp" "$A"
    say "AGENTS.md: VibeDiscipline block refreshed, your content kept"
  fi
elif [ "$UPGRADE" -eq 1 ] && ! cmp -s "$SRC/AGENTS.md" "$A"; then
  # An install from before the markers existed: the file starts with our
  # title and our text ends with the "Adapt, don't override" section.
  # Replace exactly that span; whatever follows it is the project's own.
  END_LINE="$(awk '/^## Adapt, don.t override/ { found = 1; next } found && /^(#|<)/ { print NR - 1; exit } END { if (found) print NR }' "$A" | head -1)"
  if [ "$(head -1 "$A")" = "# AGENTS.md — Project Constitution" ] && [ -n "$END_LINE" ]; then
    if [ "$DRY" -eq 1 ]; then echo "  would: replace the old VibeDiscipline text in AGENTS.md (lines 1-$END_LINE)"; else
      REST="$(tail -n +"$((END_LINE + 1))" "$A")"
      if [ -n "$(printf '%s' "$REST" | tr -d '[:space:]')" ]; then
        { echo "$MARK_START"; cat "$SRC/AGENTS.md"; echo "$MARK_END"; echo; printf '%s\n' "$REST"; } > "$A.tmp"
      else
        cp "$SRC/AGENTS.md" "$A.tmp"
      fi
      mv "$A.tmp" "$A"
      say "AGENTS.md: updated to the current version, your content kept"
    fi
  else
    say "AGENTS.md differs from the current version and has no markers — left alone."
    say "  compare it with $SRC/AGENTS.md and merge by hand"
  fi
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

# ── Claude Code skill stubs (.claude/skills/vibe-*), never anyone else's ──
if command -v node >/dev/null 2>&1; then
  if [ "$DRY" -eq 1 ]; then echo "  would: node scripts/bridge-claude.cjs"; else
    (cd "$TARGET" && node scripts/bridge-claude.cjs) | sed 's/^/  /'
  fi
fi

if [ -s "$UPDLOG" ]; then
  say "updated (your local edits to these, if any, were replaced):"
  cat "$UPDLOG"
fi
if [ "$UPGRADE" -eq 1 ]; then
  [ -s "$UPDLOG" ] || say "already up to date"
  say "kept as yours: .agent/config.yml, .agent/permissions.yml, .agent/state.md"
  say "upgrade done: version $(head -1 "$SRC/.agent/VERSION")"
  exit 0
fi
if [ -s "$SKIPLOG" ]; then
  say "kept existing files (use --force to overwrite):"
  cat "$SKIPLOG"
fi

cat <<EOF

[vibe] done. Next:
  1. Read .agent/permissions.yml and add your project's own commands and
     paths, then re-run: node scripts/compile-permissions.cjs
  2. Open the project in Claude Code once and accept the trust dialog;
     until then the compiled allow-list is ignored.
  3. Ask your agent to run the recon skill. It writes .agent/stack.lock.yml.
  4. Review and commit the new files.
EOF
