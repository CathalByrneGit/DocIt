#!/usr/bin/env bash
# docit.sh — DocIt session helper
#
# Usage:
#   ./docit.sh explore <path>    Print a session prompt for exploring a codebase
#   ./docit.sh status            Show what's been explored so far
#   ./docit.sh help              Show this message
#
# DocIt works through conversation. This script helps you start and manage sessions.

set -euo pipefail

DOCIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$DOCIT_ROOT/docs"

# ─── Commands ─────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
DocIt — Codebase Explorer

Usage:
  ./docit.sh explore <path>   Start an exploration session for a codebase
  ./docit.sh status           Show all explored codebases
  ./docit.sh help             Show this message

Examples:
  ./docit.sh explore ~/projects/myapp
  ./docit.sh status
EOF
}

cmd_explore() {
  local target_path="${1:-}"

  if [[ -z "$target_path" ]]; then
    echo "Error: provide a path to explore." >&2
    echo ""
    usage
    exit 1
  fi

  local abs_path
  abs_path="$(cd "$target_path" 2>/dev/null && pwd)" || {
    echo "Error: path not found: $target_path" >&2
    exit 1
  }

  local project_name
  project_name="$(basename "$abs_path")"
  local docs_output="$DOCS_DIR/$project_name"
  local already_explored=""

  if [[ -f "$docs_output/index.md" ]]; then
    already_explored="(previously explored — agent will augment existing docs)"
  fi

  cat <<EOF
┌─────────────────────────────────────────────────────────┐
│                  DocIt Exploration Session               │
└─────────────────────────────────────────────────────────┘

Target:     $abs_path
Project:    $project_name
Docs out:   $docs_output/
Status:     ${already_explored:-"(new exploration)"}

─── Paste this into your Claude conversation ─────────────

I want to explore the codebase at: $abs_path

Please:
1. Read CLAUDE.md for your operating instructions
2. Read DOCIT.md for the current state of this project
3. Explore $abs_path and create or update docs in docs/$project_name/
4. Update DOCIT.md with an entry in the Exploration Log when done

Start by reading CLAUDE.md, then DOCIT.md, then begin the exploration.

──────────────────────────────────────────────────────────
EOF
}

cmd_status() {
  echo "DocIt Status"
  echo "============"
  echo "Root: $DOCIT_ROOT"
  echo ""

  if [[ ! -d "$DOCS_DIR" ]]; then
    echo "No explorations yet."
    echo ""
    echo "Run: ./docit.sh explore <path>"
    return
  fi

  local indexes
  mapfile -t indexes < <(find "$DOCS_DIR" -mindepth 2 -maxdepth 2 -name "index.md" 2>/dev/null | sort)

  if [[ ${#indexes[@]} -eq 0 ]]; then
    echo "No explorations yet."
    echo ""
    echo "Run: ./docit.sh explore <path>"
    return
  fi

  echo "Explored codebases (${#indexes[@]}):"
  echo ""

  for index_file in "${indexes[@]}"; do
    local project_dir
    project_dir="$(dirname "$index_file")"
    local project_name
    project_name="$(basename "$project_dir")"

    # Extract the explored date if present
    local explored_date=""
    if grep -q "explored:" "$index_file" 2>/dev/null; then
      explored_date=$(grep -o 'explored: [0-9-]*' "$index_file" | head -1 | awk '{print $2}')
    fi

    # Count component docs
    local doc_count
    doc_count=$(find "$project_dir" -name "*.md" | wc -l | tr -d ' ')

    printf "  %-30s  %s docs" "$project_name" "$doc_count"
    [[ -n "$explored_date" ]] && printf "  (last explored: %s)" "$explored_date"
    echo ""
  done
}

# ─── Entry point ──────────────────────────────────────────────────────────────

case "${1:-help}" in
  explore)        cmd_explore "${2:-}" ;;
  status)         cmd_status ;;
  help|--help|-h) usage ;;
  *)
    echo "Unknown command: $1" >&2
    echo ""
    usage
    exit 1
    ;;
esac
