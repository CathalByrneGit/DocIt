#!/usr/bin/env bash
# cron.sh — Automated DocIt sync: backup + merge on a schedule
#
# Usage (do not run directly — let setup.sh or crontab invoke this):
#   ./cron.sh
#
# Crontab example (every 30 minutes):
#   */30 * * * * /home/user/DocIt/cron.sh
#
# What it does:
#   1. Acquires a lock file to prevent overlapping runs
#   2. Runs merge.sh (which backs up first if DOCIT_BACKUP_DIR is set)
#   3. Logs all output with timestamps to .cron.log
#   4. Releases the lock

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="/tmp/docit-cron.lock"
LOG_FILE="$SCRIPT_DIR/.cron.log"

# ─── Lock ─────────────────────────────────────────────────────────────────────

if [[ -f "$LOCK_FILE" ]]; then
  LOCK_PID="$(cat "$LOCK_FILE" 2>/dev/null || echo "")"
  if [[ -n "$LOCK_PID" ]] && kill -0 "$LOCK_PID" 2>/dev/null; then
    echo "$(date -u '+%Y-%m-%d %H:%M UTC'): Skipping — previous run (PID $LOCK_PID) still active" >> "$LOG_FILE"
    exit 0
  else
    # Stale lock
    rm -f "$LOCK_FILE"
  fi
fi

echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# ─── Sync ─────────────────────────────────────────────────────────────────────

echo "$(date -u '+%Y-%m-%d %H:%M UTC'): Starting DocIt sync..." >> "$LOG_FILE"

if "$SCRIPT_DIR/merge.sh" >> "$LOG_FILE" 2>&1; then
  echo "$(date -u '+%Y-%m-%d %H:%M UTC'): Sync complete." >> "$LOG_FILE"
else
  EXIT_CODE=$?
  echo "$(date -u '+%Y-%m-%d %H:%M UTC'): Sync failed (exit code $EXIT_CODE)." >> "$LOG_FILE"
fi
