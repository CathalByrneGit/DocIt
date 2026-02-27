#!/usr/bin/env bash
# restore.sh — Restore DocIt knowledge from a backup repository
#
# Usage:
#   ./restore.sh <backup-dir>
#
# WARNING: This overwrites your local docs/, DOCIT.md, and any federation
# files with whatever is in the backup repo. Use with care.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${1:-}"

# ─── Validate ─────────────────────────────────────────────────────────────────

if [[ -z "$BACKUP_DIR" ]]; then
  echo "Usage: ./restore.sh <backup-dir>" >&2
  exit 1
fi

if [[ ! -d "$BACKUP_DIR/.git" ]]; then
  echo "Error: $BACKUP_DIR is not a git repository." >&2
  exit 1
fi

# ─── Confirm ──────────────────────────────────────────────────────────────────

echo "Restore source: $BACKUP_DIR"
echo "Restore target: $SCRIPT_DIR"
echo ""
echo "This will overwrite:"
echo "  docs/"
echo "  DOCIT.md"
[[ -f "$BACKUP_DIR/MESSAGES.md" ]]    && echo "  MESSAGES.md"
[[ -f "$BACKUP_DIR/INSIGHTS.md" ]]    && echo "  INSIGHTS.md"
[[ -f "$BACKUP_DIR/CONTRIBUTORS.md" ]] && echo "  CONTRIBUTORS.md"
echo ""
read -r -p "Continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

# ─── Pull latest from backup remote ───────────────────────────────────────────

echo "Pulling latest from backup remote..."
git -C "$BACKUP_DIR" pull

# ─── Restore ──────────────────────────────────────────────────────────────────

if [[ -d "$BACKUP_DIR/docs" ]]; then
  rsync -av --delete "$BACKUP_DIR/docs/" "$SCRIPT_DIR/docs/"
fi

rsync -av "$BACKUP_DIR/DOCIT.md" "$SCRIPT_DIR/DOCIT.md"

for file in MESSAGES.md INSIGHTS.md CONTRIBUTORS.md; do
  if [[ -f "$BACKUP_DIR/$file" ]]; then
    rsync -av "$BACKUP_DIR/$file" "$SCRIPT_DIR/$file"
  fi
done

echo "Restore complete."
