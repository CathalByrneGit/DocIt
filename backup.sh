#!/usr/bin/env bash
# backup.sh — Sync DocIt knowledge to a private backup repository
#
# Usage:
#   ./backup.sh [backup-dir]
#   DOCIT_BACKUP_DIR=~/docit-private ./backup.sh
#
# What it backs up:
#   docs/          — all codebase explorations
#   DOCIT.md       — the living document (state + log)
#   MESSAGES.md    — shared inbox (if present)
#   INSIGHTS.md    — cross-codebase knowledge (if present)
#
# The DocIt scaffold (CLAUDE.md, scripts) stays in the public repo.
# Your knowledge stays private.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${1:-${DOCIT_BACKUP_DIR:-}}"

# ─── Validate ─────────────────────────────────────────────────────────────────

if [[ -z "$BACKUP_DIR" ]]; then
  cat >&2 <<'EOF'
Error: no backup directory specified.

Provide one of:
  ./backup.sh ~/path/to/docit-private
  export DOCIT_BACKUP_DIR=~/path/to/docit-private

The backup directory must be an initialised git repository with a remote:
  git init ~/docit-private
  cd ~/docit-private
  git remote add origin <your-private-repo-url>
EOF
  exit 1
fi

if [[ ! -d "$BACKUP_DIR/.git" ]]; then
  echo "Error: $BACKUP_DIR is not a git repository." >&2
  echo "Run: git init \"$BACKUP_DIR\" && git -C \"$BACKUP_DIR\" remote add origin <url>" >&2
  exit 1
fi

# ─── Sync ─────────────────────────────────────────────────────────────────────

echo "Backing up DocIt knowledge to: $BACKUP_DIR"

# Always sync: docs/ and DOCIT.md
rsync -av --delete "$SCRIPT_DIR/docs/" "$BACKUP_DIR/docs/"
rsync -av "$SCRIPT_DIR/DOCIT.md" "$BACKUP_DIR/DOCIT.md"

# Sync federation files if they exist
for file in MESSAGES.md INSIGHTS.md CONTRIBUTORS.md; do
  if [[ -f "$SCRIPT_DIR/$file" ]]; then
    rsync -av "$SCRIPT_DIR/$file" "$BACKUP_DIR/$file"
  fi
done

# ─── Commit and push ──────────────────────────────────────────────────────────

cd "$BACKUP_DIR"

if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  echo "Nothing changed — backup is already up to date."
  exit 0
fi

git add -A
git commit -m "docit backup: $(date -u '+%Y-%m-%d %H:%M UTC')"
git push
echo "Backup pushed."
