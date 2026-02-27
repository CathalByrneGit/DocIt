#!/usr/bin/env bash
# merge.sh — Merge changes from a remote DocIt or team member's DocIt
#
# Usage:
#   ./merge.sh                        Merge from origin (multi-device sync)
#   ./merge.sh <remote-name>          Merge from a named git remote
#   ./merge.sh --contrib <path>       Merge knowledge from another local DocIt
#
# How it works:
#   1. Back up current state (if DOCIT_BACKUP_DIR is set)
#   2. Fetch from the remote
#   3. Check if local and remote have diverged
#   4. Attempt git merge
#   5. For any conflicted .md files: invoke claude -p to synthesise both sides
#   6. Commit the resolved merge
#
# The claude -p step is the key: instead of choosing one side of a doc conflict,
# Claude reads both versions and synthesises them — preserving knowledge from both.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Parse args ───────────────────────────────────────────────────────────────

MODE="remote"
REMOTE="origin"
CONTRIB_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contrib)
      MODE="contrib"
      CONTRIB_PATH="${2:-}"
      if [[ -z "$CONTRIB_PATH" ]]; then
        echo "Error: --contrib requires a path to another DocIt" >&2
        exit 1
      fi
      shift 2
      ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      REMOTE="$1"
      shift
      ;;
  esac
done

# ─── Helpers ──────────────────────────────────────────────────────────────────

require_claude() {
  if ! command -v claude &>/dev/null; then
    cat >&2 <<'EOF'
Warning: 'claude' CLI not found. Falling back to manual conflict resolution.
Install the Claude CLI to enable automatic conflict resolution:
  https://docs.anthropic.com/claude-code
EOF
    return 1
  fi
  return 0
}

resolve_conflict_with_claude() {
  local conflict_file="$1"
  local project_context="${2:-}"

  echo "  Resolving conflict in: $conflict_file"

  local prompt
  prompt="$(cat <<PROMPT
You are a DocIt agent merging documentation from two contributors.

The following markdown file has git merge conflict markers (<<<<<<<, =======, >>>>>>>).
Your job: synthesise both versions into one coherent document.

Rules:
- Preserve all unique knowledge from BOTH sides
- Remove duplication where both sides say the same thing
- If both sides have different dates in <!-- explored: -->, keep the more recent one
- For Open Questions: merge the lists, deduplicating identical questions
- Remove all conflict markers (<<<<<<, =======, >>>>>>>)
- Output only the resolved markdown, nothing else

${project_context:+Context: $project_context}

FILE: $(basename "$conflict_file")

CONTENT:
$(cat "$conflict_file")
PROMPT
)"

  local resolved
  resolved="$(echo "$prompt" | claude -p 2>/dev/null)" || {
    echo "  Warning: claude -p failed for $conflict_file — leaving for manual resolution" >&2
    return 1
  }

  echo "$resolved" > "$conflict_file"
  echo "  Resolved: $conflict_file"
}

# ─── Mode: remote sync (multi-device or push/pull with origin) ────────────────

do_remote_merge() {
  cd "$SCRIPT_DIR"

  # Backup first if configured
  if [[ -n "${DOCIT_BACKUP_DIR:-}" ]]; then
    echo "Backing up before merge..."
    "$SCRIPT_DIR/backup.sh" "$DOCIT_BACKUP_DIR" || true
  fi

  echo "Fetching from $REMOTE..."
  git fetch "$REMOTE"

  local local_sha remote_sha base_sha
  local_sha="$(git rev-parse HEAD)"
  remote_sha="$(git rev-parse "$REMOTE/$(git branch --show-current)" 2>/dev/null)" || {
    echo "No tracking branch found on $REMOTE — nothing to merge."
    exit 0
  }
  base_sha="$(git merge-base HEAD "$remote_sha")"

  if [[ "$local_sha" == "$remote_sha" ]]; then
    echo "Already up to date."
    exit 0
  fi

  if [[ "$base_sha" == "$local_sha" ]]; then
    echo "Remote is ahead — fast-forwarding."
    git merge --ff-only "$remote_sha"
    exit 0
  fi

  if [[ "$base_sha" == "$remote_sha" ]]; then
    echo "Local is ahead — nothing to pull."
    exit 0
  fi

  echo "Branches have diverged — merging..."
  git merge --no-commit --no-ff "$remote_sha" || true

  # Resolve any conflicted markdown files
  local conflicts
  conflicts="$(git diff --name-only --diff-filter=U 2>/dev/null)" || true

  if [[ -z "$conflicts" ]]; then
    echo "Merge succeeded with no conflicts."
    git commit --no-edit
    return
  fi

  echo ""
  echo "Conflicts found:"
  echo "$conflicts" | sed 's/^/  /'
  echo ""

  local has_claude=false
  require_claude && has_claude=true

  local unresolved=0
  while IFS= read -r conflict_file; do
    if [[ "$conflict_file" == *.md ]]; then
      if $has_claude; then
        resolve_conflict_with_claude "$SCRIPT_DIR/$conflict_file" || (( unresolved++ )) || true
        git add "$conflict_file"
      else
        echo "  Skipping (no claude CLI): $conflict_file"
        (( unresolved++ )) || true
      fi
    else
      echo "  Non-markdown conflict (manual): $conflict_file"
      (( unresolved++ )) || true
    fi
  done <<< "$conflicts"

  if [[ $unresolved -gt 0 ]]; then
    echo ""
    echo "$unresolved file(s) need manual resolution. Resolve them and run:"
    echo "  git add <file> && git commit"
    exit 1
  fi

  git commit -m "merge: sync with $REMOTE on $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo "Merge complete."
}

# ─── Mode: contrib merge (import knowledge from a team member's DocIt) ────────

do_contrib_merge() {
  if [[ ! -d "$CONTRIB_PATH/docs" ]]; then
    echo "Error: $CONTRIB_PATH does not look like a DocIt (no docs/ directory)" >&2
    exit 1
  fi

  local contrib_name
  contrib_name="$(basename "$CONTRIB_PATH")"
  echo "Importing knowledge from: $CONTRIB_PATH ($contrib_name)"

  # For each project in the contributor's docs/
  local projects=()
  while IFS= read -r -d '' proj; do
    projects+=("$(basename "$proj")")
  done < <(find "$CONTRIB_PATH/docs" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

  if [[ ${#projects[@]} -eq 0 ]]; then
    echo "No project docs found in contributor's DocIt."
    exit 0
  fi

  local has_claude=false
  require_claude && has_claude=true

  for project in "${projects[@]}"; do
    local src="$CONTRIB_PATH/docs/$project"
    local dst="$SCRIPT_DIR/docs/$project"

    if [[ ! -d "$dst" ]]; then
      echo "New project from contributor: $project — copying."
      cp -r "$src" "$dst"
      continue
    fi

    echo "Merging project: $project"

    # Merge each .md file
    while IFS= read -r -d '' src_file; do
      local rel_path="${src_file#$src/}"
      local dst_file="$dst/$rel_path"

      if [[ ! -f "$dst_file" ]]; then
        echo "  New doc: $rel_path"
        mkdir -p "$(dirname "$dst_file")"
        cp "$src_file" "$dst_file"
        continue
      fi

      # Both exist — check if they differ
      if diff -q "$src_file" "$dst_file" &>/dev/null; then
        continue
      fi

      echo "  Differing doc: $rel_path"

      if $has_claude; then
        # Create a pseudo-conflict file for claude to resolve
        local tmp_conflict
        tmp_conflict="$(mktemp)"
        cat > "$tmp_conflict" <<CONFLICT
<<<<<<< local (this DocIt)
$(cat "$dst_file")
=======
$(cat "$src_file")
>>>>>>> contrib ($contrib_name)
CONFLICT
        resolve_conflict_with_claude "$tmp_conflict" "Project: $project" && \
          cp "$tmp_conflict" "$dst_file"
        rm -f "$tmp_conflict"
      else
        echo "  No claude CLI — skipping merge of $rel_path (keeping local)"
      fi

    done < <(find "$src" -name "*.md" -print0)
  done

  # Merge INSIGHTS.md if contributor has one
  if [[ -f "$CONTRIB_PATH/INSIGHTS.md" ]] && [[ -f "$SCRIPT_DIR/INSIGHTS.md" ]]; then
    echo "Merging INSIGHTS.md..."
    if $has_claude; then
      local tmp_insights
      tmp_insights="$(mktemp)"
      cat > "$tmp_insights" <<CONFLICT
<<<<<<< local
$(cat "$SCRIPT_DIR/INSIGHTS.md")
=======
$(cat "$CONTRIB_PATH/INSIGHTS.md")
>>>>>>> contrib ($contrib_name)
CONFLICT
      resolve_conflict_with_claude "$tmp_insights" "Cross-codebase insights ledger" && \
        cp "$tmp_insights" "$SCRIPT_DIR/INSIGHTS.md"
      rm -f "$tmp_insights"
    fi
  fi

  # Append contributor's messages to local MESSAGES.md if present
  if [[ -f "$CONTRIB_PATH/MESSAGES.md" ]] && [[ -f "$SCRIPT_DIR/MESSAGES.md" ]]; then
    echo "Appending new messages from contributor..."
    echo "" >> "$SCRIPT_DIR/MESSAGES.md"
    echo "<!-- imported from $contrib_name on $(date -u '+%Y-%m-%d') -->" >> "$SCRIPT_DIR/MESSAGES.md"
    # Only append entries from contributor not already in local (rough dedup by date+source line)
    grep -v '^#\|^>\|^<!--\|^$' "$CONTRIB_PATH/MESSAGES.md" | \
      grep -vxFf <(grep -v '^#\|^>\|^<!--\|^$' "$SCRIPT_DIR/MESSAGES.md") \
      >> "$SCRIPT_DIR/MESSAGES.md" 2>/dev/null || true
  fi

  echo ""
  echo "Contrib merge from $contrib_name complete."
  echo "Review changes, then commit:"
  echo "  git add -A && git commit -m 'merge: import knowledge from $contrib_name'"
}

# ─── Entry point ──────────────────────────────────────────────────────────────

case "$MODE" in
  remote) do_remote_merge ;;
  contrib) do_contrib_merge ;;
esac
