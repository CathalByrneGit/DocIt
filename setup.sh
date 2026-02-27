#!/usr/bin/env bash
# setup.sh — Install automated DocIt syncing
#
# Usage:
#   ./setup.sh [--interval <minutes>] [--uninstall]
#
# Installs cron.sh as a scheduled job. Detects whether to use:
#   - crontab (most systems)
#   - systemd user timer (Linux with systemd)
#
# Default interval: 30 minutes
# The sync backs up your DocIt docs and merges changes from remote.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL=30
UNINSTALL=false

# ─── Parse args ───────────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval)
      INTERVAL="${2:-30}"
      shift 2
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

CRON_ENTRY="*/$INTERVAL * * * * $SCRIPT_DIR/cron.sh"
CRON_MARKER="# docit-autosync"

# ─── systemd setup ────────────────────────────────────────────────────────────

setup_systemd() {
  local unit_dir="$HOME/.config/systemd/user"
  mkdir -p "$unit_dir"

  cat > "$unit_dir/docit-sync.service" <<EOF
[Unit]
Description=DocIt automatic sync

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/cron.sh
EOF

  cat > "$unit_dir/docit-sync.timer" <<EOF
[Unit]
Description=DocIt sync every $INTERVAL minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=${INTERVAL}min
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl --user daemon-reload
  systemctl --user enable --now docit-sync.timer
  echo "Systemd timer installed: docit-sync.timer (every $INTERVAL minutes)"
}

uninstall_systemd() {
  systemctl --user disable --now docit-sync.timer 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/docit-sync.service"
  rm -f "$HOME/.config/systemd/user/docit-sync.timer"
  systemctl --user daemon-reload
  echo "Systemd timer removed."
}

# ─── crontab setup ────────────────────────────────────────────────────────────

setup_crontab() {
  local existing
  existing="$(crontab -l 2>/dev/null || true)"

  if echo "$existing" | grep -q "$CRON_MARKER"; then
    echo "DocIt cron entry already present — updating interval."
    local updated
    updated="$(echo "$existing" | grep -v "$CRON_MARKER")"
    (echo "$updated"; echo "$CRON_ENTRY $CRON_MARKER") | crontab -
  else
    (echo "$existing"; echo "$CRON_ENTRY $CRON_MARKER") | crontab -
  fi

  echo "Crontab entry installed (every $INTERVAL minutes):"
  echo "  $CRON_ENTRY"
}

uninstall_crontab() {
  local existing
  existing="$(crontab -l 2>/dev/null || true)"
  if echo "$existing" | grep -q "$CRON_MARKER"; then
    echo "$existing" | grep -v "$CRON_MARKER" | crontab -
    echo "Crontab entry removed."
  else
    echo "No DocIt crontab entry found."
  fi
}

# ─── Entry point ──────────────────────────────────────────────────────────────

# Ensure cron.sh is executable
chmod +x "$SCRIPT_DIR/cron.sh"

# Prefer systemd if available and running
if systemctl --user is-active --quiet basic.target 2>/dev/null; then
  SCHEDULER="systemd"
else
  SCHEDULER="crontab"
fi

echo "Scheduler detected: $SCHEDULER"

if $UNINSTALL; then
  case "$SCHEDULER" in
    systemd)  uninstall_systemd ;;
    crontab)  uninstall_crontab ;;
  esac
else
  case "$SCHEDULER" in
    systemd)  setup_systemd ;;
    crontab)  setup_crontab ;;
  esac
  echo ""
  echo "DocIt will automatically sync every $INTERVAL minutes."
  echo "Logs: $SCRIPT_DIR/.cron.log"
  echo ""
  echo "To uninstall: ./setup.sh --uninstall"
fi
