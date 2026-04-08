#!/usr/bin/env bash
# docit.sh — DocIt session helper
#
# Usage:
#   ./docit.sh init                        First-time setup
#   ./docit.sh ingest  <path>              Explore a new or updated codebase
#   ./docit.sh query   "<question>"        Answer a question from your docs
#   ./docit.sh lint    [project] [--deep]  Check doc health
#   ./docit.sh graph   <project>           Emit Mermaid dependency graph from entity tags
#   ./docit.sh update  <project> [files]   Generate update prompt after code changes
#   ./docit.sh install-hook <path>         Install post-commit hook in a target repo
#   ./docit.sh status                      Show all explored codebases
#   ./docit.sh sync    [remote]            Merge from remote DocIt
#   ./docit.sh backup  [dir]               Back up docs to private git repo
#   ./docit.sh help                        Show this message
#
# Aliases: explore = ingest
#
# Config: copy .docit.conf.example to .docit.conf and edit.
# See llm.sh for LLM backend options (claude / ollama / llama-server).

set -euo pipefail

DOCIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$DOCIT_ROOT/docs"

# Load local config if present
if [[ -f "$DOCIT_ROOT/.docit.conf" ]]; then
  # shellcheck source=/dev/null
  source "$DOCIT_ROOT/.docit.conf"
fi

# ─── Usage ────────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
DocIt — Codebase Explorer

Usage:
  ./docit.sh init                          First-time setup wizard
  ./docit.sh ingest  <path>                Explore a new or updated codebase
  ./docit.sh query   "<question>"          Answer a question from your docs
  ./docit.sh lint    [project] [--deep]    Check doc health; --deep uses LLM
  ./docit.sh graph   <project>             Mermaid dependency graph from entity tags
  ./docit.sh update  <project> [files…]    Prompt for re-ingesting changed files
  ./docit.sh install-hook <repo-path>      Install post-commit hook in target repo
  ./docit.sh status                        Show all explored codebases
  ./docit.sh sync    [remote]              Merge from remote DocIt (default: origin)
  ./docit.sh backup  [dir]                 Back up docs/ to a private git repo
  ./docit.sh help                          Show this message

Aliases:
  explore = ingest

Options for query:
  --project <name>   Scope search to one project's docs
  --save             Save answer as a doc in docs/<project>/queries/

Examples:
  ./docit.sh init
  ./docit.sh ingest ~/projects/myapp
  ./docit.sh query "how does auth work?" --project myapp --save
  ./docit.sh lint myapp
  ./docit.sh lint myapp --deep
  ./docit.sh graph myapp
  ./docit.sh update myapp src/auth/refresh.ts
  ./docit.sh install-hook ~/projects/myapp

Config (.docit.conf — copy from .docit.conf.example):
  DOCIT_LLM=claude              # claude (default) | ollama | llama-server
  DOCIT_LLM_MODEL=llama3.1:8b   # model for ollama/llama-server
  DOCIT_BACKUP_DIR=~/docit-data  # backup repo path
EOF
}

# ─── ingest ───────────────────────────────────────────────────────────────────

cmd_ingest() {
  local target_path="${1:-}"

  if [[ -z "$target_path" ]]; then
    echo "Error: provide a path to ingest." >&2
    echo "Usage: ./docit.sh ingest <path>" >&2
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
  local mode="new exploration"

  [[ -f "$docs_output/index.md" ]] && mode="augmenting existing docs"

  cat <<EOF
┌─────────────────────────────────────────────────────────┐
│                  DocIt Ingest Session                    │
└─────────────────────────────────────────────────────────┘

Target:   $abs_path
Project:  $project_name
Docs:     $docs_output/
Mode:     $mode

─── Paste this into your Claude conversation ─────────────

I want to ingest the codebase at: $abs_path

Please:
1. Read CLAUDE.md for your operating instructions
2. Read DOCIT.md for current state
3. Ingest $abs_path — create or update docs in docs/$project_name/
4. End the session with the Crystallisation step from CLAUDE.md

Start by reading CLAUDE.md, then DOCIT.md, then begin.

──────────────────────────────────────────────────────────
EOF
}

# ─── query ────────────────────────────────────────────────────────────────────

cmd_query() {
  local question="${1:-}"
  local project=""
  local save=false

  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project|-p) project="${2:-}"; shift 2 ;;
      --save|-s)    save=true; shift ;;
      *)            shift ;;
    esac
  done

  if [[ -z "$question" ]]; then
    echo 'Usage: ./docit.sh query "<question>" [--project <name>] [--save]' >&2
    exit 1
  fi

  local search_dir="${DOCS_DIR}${project:+/$project}"

  if [[ ! -d "$search_dir" ]]; then
    echo "Error: no docs found at $search_dir" >&2
    echo "Run: ./docit.sh ingest <path>" >&2
    exit 1
  fi

  # Always include all index.md files as anchors
  local -a context_files=()
  while IFS= read -r -d '' f; do
    context_files+=("$f")
  done < <(find "$search_dir" -name "index.md" -print0 2>/dev/null)

  # Pull in docs matching keywords from the question
  local keywords
  keywords="$(echo "$question" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '\n' \
    | awk 'length>3' \
    | sort -u \
    | tr '\n' '|' \
    | sed 's/|$//')"

  if [[ -n "$keywords" ]]; then
    while IFS= read -r -d '' f; do
      local skip=false
      for existing in "${context_files[@]:-}"; do
        [[ "$existing" == "$f" ]] && skip=true && break
      done
      $skip || context_files+=("$f")
    done < <(grep -ril -E "$keywords" "$search_dir" --include="*.md" -Z 2>/dev/null || true)
  fi

  # Cap at 12 docs to stay within context
  if [[ ${#context_files[@]} -gt 12 ]]; then
    context_files=("${context_files[@]:0:12}")
  fi

  if [[ ${#context_files[@]} -eq 0 ]]; then
    echo "No relevant docs found for this query." >&2
    exit 1
  fi

  echo "Querying${project:+ [$project]} — ${#context_files[@]} doc(s) in context..."
  echo ""

  # Build doc context block
  local context=""
  for f in "${context_files[@]}"; do
    context+="=== ${f#$DOCIT_ROOT/} ===
$(cat "$f")

"
  done

  local prompt
  printf -v prompt \
    'You are a DocIt agent. Answer the following question using ONLY the documentation provided below.\nBe specific. Cite which doc file your answer comes from.\nIf the answer is not in the docs, say so clearly and name the file most likely to contain it.\n\nQUESTION: %s\n\nDOCUMENTATION:\n%s' \
    "$question" "$context"

  local answer
  answer="$(printf '%s' "$prompt" | "$DOCIT_ROOT/llm.sh")"

  printf '%s\n' "$answer"

  # Optionally save as a query doc
  if $save; then
    local slug today out_dir save_path
    slug="$(echo "$question" \
      | tr '[:upper:]' '[:lower:]' \
      | tr -cs 'a-z0-9' '-' \
      | sed 's/^-//;s/-$//' \
      | cut -c1-60)"
    today="$(date -u '+%Y-%m-%d')"
    out_dir="${DOCS_DIR}${project:+/$project}/queries"
    mkdir -p "$out_dir"
    save_path="$out_dir/${today}-${slug}.md"

    {
      printf '# Query: %s\n\n' "$question"
      printf '<!-- explored: %s -->\n\n' "$today"
      printf '**Project**: %s\n' "${project:-(all)}"
      printf '**Asked**: %s\n\n' "$today"
      printf '## Answer\n\n%s\n\n' "$answer"
      printf '## Source Docs\n\n'
      for f in "${context_files[@]}"; do
        printf -- '- `%s`\n' "${f#$DOCIT_ROOT/}"
      done
    } > "$save_path"

    echo ""
    echo "Saved: ${save_path#$DOCIT_ROOT/}"
  fi
}

# ─── lint ─────────────────────────────────────────────────────────────────────

_lint_project() {
  local project="$1"
  local dir="$2"
  local issues=0
  local warnings=0

  printf 'Linting: %s\n' "$project"
  printf '%.0s─' {1..50}; echo ""

  if [[ ! -f "$dir/index.md" ]]; then
    echo "  ✗ Missing index.md"
    (( issues++ )) || true
  fi

  local today_epoch
  today_epoch="$(date +%s)"

  while IFS= read -r -d '' mdfile; do
    local rel="${mdfile#$dir/}"

    # Missing explored tag
    if ! grep -q '<!-- explored:' "$mdfile" 2>/dev/null; then
      echo "  ✗ $rel — missing <!-- explored: YYYY-MM-DD --> tag"
      (( issues++ )) || true
    else
      # Stale check (>60 days)
      local date_str=""
      date_str="$(grep -o 'explored: [0-9-]*' "$mdfile" | head -1 | awk '{print $2}')"
      if [[ -n "$date_str" ]]; then
        local explored_epoch=0 age_days=0
        explored_epoch="$(date -d "$date_str" +%s 2>/dev/null \
          || date -j -f '%Y-%m-%d' "$date_str" +%s 2>/dev/null \
          || echo 0)"
        if [[ $explored_epoch -gt 0 ]]; then
          age_days=$(( (today_epoch - explored_epoch) / 86400 ))
          if [[ $age_days -gt 60 ]]; then
            printf '  ⚠ %s — stale (%dd old, explored %s)\n' "$rel" "$age_days" "$date_str"
            (( warnings++ )) || true
          fi
        fi
      fi
    fi

    # Open TODO count (informational, not an error)
    local todo_count=0
    todo_count="$(grep -c '<!-- TODO:' "$mdfile" 2>/dev/null || true)"
    if [[ $todo_count -gt 0 ]]; then
      printf '  ○ %s — %d open TODO(s)\n' "$rel" "$todo_count"
    fi

    # Broken relative links
    while IFS= read -r link; do
      if [[ ! -f "$dir/$link" ]]; then
        printf '  ✗ %s — broken link: ./%s\n' "$rel" "$link"
        (( issues++ )) || true
      fi
    done < <(grep -oP '\]\(\./\K[^)]+' "$mdfile" 2>/dev/null || true)

  done < <(find "$dir" -name "*.md" -print0 2>/dev/null)

  # index.md references component files that don't exist
  if [[ -f "$dir/index.md" ]]; then
    while IFS= read -r linked; do
      if [[ ! -f "$dir/$linked" ]]; then
        printf '  ✗ index.md links to missing file: %s\n' "$linked"
        (( issues++ )) || true
      fi
    done < <(grep -oP '\]\(\./\K[^)]+\.md' "$dir/index.md" 2>/dev/null || true)
  fi

  if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
    echo "  ✓ Clean"
  else
    [[ $issues -gt 0 ]]   && printf '  %d error(s)\n' "$issues"
    [[ $warnings -gt 0 ]] && printf '  %d warning(s)\n' "$warnings"
  fi
  echo ""

  return $(( issues > 0 ? 1 : 0 ))
}

cmd_lint() {
  local project=""
  local deep=false
  local exit_code=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --deep) deep=true; shift ;;
      *)      project="$1"; shift ;;
    esac
  done

  if [[ -n "$project" ]]; then
    local dir="$DOCS_DIR/$project"
    if [[ ! -d "$dir" ]]; then
      echo "Error: no docs for project '$project'" >&2
      exit 1
    fi
    _lint_project "$project" "$dir" || exit_code=1
    $deep && _lint_deep "$project" "$dir"
  else
    local found=0
    while IFS= read -r -d '' dir; do
      _lint_project "$(basename "$dir")" "$dir" || exit_code=1
      $deep && _lint_deep "$(basename "$dir")" "$dir"
      found=1
    done < <(find "$DOCS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    [[ $found -eq 0 ]] && echo "No projects to lint. Run: ./docit.sh ingest <path>"
  fi

  return $exit_code
}

_lint_deep() {
  local project="$1"
  local dir="$2"

  printf 'Deep lint (LLM): %s\n' "$project"
  printf '%.0s─' {1..50}; echo ""

  # Collect all docs
  local context=""
  while IFS= read -r -d '' f; do
    context+="=== ${f#$dir/} ===
$(cat "$f")

"
  done < <(find "$dir" -name "*.md" ! -path "*/queries/*" -print0 2>/dev/null)

  if [[ -z "$context" ]]; then
    echo "  No docs to analyse."
    echo ""
    return
  fi

  local prompt
  printf -v prompt \
'You are a DocIt quality reviewer. Read the following documentation for the "%s" project.

Identify and report:
1. CONTRADICTIONS: two docs stating conflicting facts about the same thing
2. INCONSISTENCIES: the same term used with different meanings across docs
3. STALE CLAIMS: anything that looks like it may be outdated (check superseded markers)
4. GAPS: important aspects of the project clearly missing from the docs

For each issue: cite the specific file(s), quote the conflicting text, and suggest how to resolve it.
If no issues are found, say so clearly.

DOCUMENTATION:
%s' "$project" "$context"

  printf '%s' "$prompt" | "$DOCIT_ROOT/llm.sh"
  echo ""
}

# ─── update ───────────────────────────────────────────────────────────────────

cmd_update() {
  local project="${1:-}"

  if [[ -z "$project" ]]; then
    echo "Usage: ./docit.sh update <project> [changed-file…]" >&2
    exit 1
  fi

  shift || true
  local -a changed=("$@")

  if [[ ! -d "$DOCS_DIR/$project" ]]; then
    echo "Error: no docs for '$project'. Run: ./docit.sh ingest <path>" >&2
    exit 1
  fi

  local files_block
  if [[ ${#changed[@]} -gt 0 ]]; then
    files_block="$(printf '  - %s\n' "${changed[@]}")"
  else
    files_block="  (no specific files given — re-scan the whole project)"
  fi

  cat <<EOF
┌─────────────────────────────────────────────────────────┐
│                  DocIt Update Session                    │
└─────────────────────────────────────────────────────────┘

Project:       $project
Existing docs: $DOCS_DIR/$project/
Changed files:
$files_block

─── Paste this into your Claude conversation ─────────────

The following files changed in the '$project' codebase:

$files_block

Please:
1. Read CLAUDE.md for your operating instructions
2. Read DOCIT.md for current state
3. Read docs/$project/index.md and the relevant component docs
4. Re-examine the changed files above
5. Update affected docs — augment and correct, do not rewrite
6. Mark superseded content:
     <!-- superseded: $(date -u '+%Y-%m-%d'), replaced by: <brief note> -->
7. Update <!-- explored: --> dates on modified docs
8. Run the Crystallisation step from CLAUDE.md to close the session

──────────────────────────────────────────────────────────
EOF
}

# ─── status ───────────────────────────────────────────────────────────────────

cmd_status() {
  echo "DocIt Status"
  echo "============"
  echo "Root:    $DOCIT_ROOT"
  echo "Backend: ${DOCIT_LLM:-claude}"
  echo ""

  if [[ ! -d "$DOCS_DIR" ]]; then
    echo "No explorations yet. Run: ./docit.sh ingest <path>"
    return
  fi

  local -a indexes=()
  while IFS= read -r -d '' f; do
    indexes+=("$f")
  done < <(find "$DOCS_DIR" -mindepth 2 -maxdepth 2 -name "index.md" -print0 2>/dev/null | sort -z)

  if [[ ${#indexes[@]} -eq 0 ]]; then
    echo "No explorations yet. Run: ./docit.sh ingest <path>"
    return
  fi

  printf "Explored codebases (%d):\n\n" "${#indexes[@]}"

  for index_file in "${indexes[@]}"; do
    local proj_dir proj_name explored_date doc_count query_count
    proj_dir="$(dirname "$index_file")"
    proj_name="$(basename "$proj_dir")"
    explored_date="$(grep -o 'explored: [0-9-]*' "$index_file" 2>/dev/null | head -1 | awk '{print $2}' || true)"
    doc_count="$(find "$proj_dir" -name "*.md" ! -path "*/queries/*" 2>/dev/null | wc -l | tr -d ' ')"
    query_count="$(find "$proj_dir/queries" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"

    printf "  %-28s  %s docs" "$proj_name" "$doc_count"
    [[ "$query_count" -gt 0 ]] && printf ", %s saved queries" "$query_count"
    [[ -n "$explored_date" ]]  && printf "  (last: %s)" "$explored_date"
    echo ""
  done
}

# ─── graph ────────────────────────────────────────────────────────────────────

cmd_graph() {
  local project="${1:-}"

  if [[ -z "$project" ]]; then
    echo "Usage: ./docit.sh graph <project>" >&2
    exit 1
  fi

  local dir="$DOCS_DIR/$project"
  if [[ ! -d "$dir" ]]; then
    echo "Error: no docs for project '$project'" >&2
    exit 1
  fi

  # Collect nodes and edges from entity tags in component docs
  local -a node_lines=()
  local -a edge_lines=()

  while IFS= read -r -d '' mdfile; do
    local filename
    filename="$(basename "$mdfile" .md)"
    [[ "$filename" == "index" ]] && continue

    # Node ID: sanitise filename to valid Mermaid ID
    local node_id="${filename//[^a-zA-Z0-9_]/_}"

    # Label: first H1 heading, or filename if none
    local label
    label="$(grep -m1 '^# ' "$mdfile" 2>/dev/null | sed 's/^# //' || echo "$filename")"

    # Entity type → Mermaid node shape
    local entity_type=""
    entity_type="$(grep -o 'entity: [a-z]*' "$mdfile" 2>/dev/null | head -1 | awk '{print $2}')"

    case "$entity_type" in
      service)   node_lines+=("  ${node_id}[[$label]]") ;;
      model)     node_lines+=("  ${node_id}[($label)]") ;;
      interface) node_lines+=("  ${node_id}{$label}") ;;
      *)         node_lines+=("  ${node_id}[$label]") ;;
    esac

    # depends-on edges
    local deps=""
    deps="$(grep -o 'depends-on: [^-]*-->' "$mdfile" 2>/dev/null \
      | sed 's/depends-on: //;s/ -->//' || true)"

    if [[ -n "$deps" ]]; then
      IFS=',' read -ra dep_arr <<< "$deps"
      for dep in "${dep_arr[@]}"; do
        dep="$(echo "$dep" | tr -d ' ')"
        local dep_id="${dep//[^a-zA-Z0-9_]/_}"
        edge_lines+=("  ${node_id} --> ${dep_id}")
      done
    fi

    # implements edges (dashed)
    local impls=""
    impls="$(grep -o 'implements: [^-]*-->' "$mdfile" 2>/dev/null \
      | sed 's/implements: //;s/ -->//' || true)"

    if [[ -n "$impls" ]]; then
      IFS=',' read -ra impl_arr <<< "$impls"
      for impl in "${impl_arr[@]}"; do
        impl="$(echo "$impl" | tr -d ' ')"
        local impl_id="${impl//[^a-zA-Z0-9_]/_}"
        edge_lines+=("  ${node_id} -.->|implements| ${impl_id}")
      done
    fi

  done < <(find "$dir" -name "*.md" ! -name "index.md" ! -path "*/queries/*" -print0 2>/dev/null)

  if [[ ${#node_lines[@]} -eq 0 ]]; then
    echo "No entity tags found in docs/$project/."
    echo "Add <!-- entity: module --> tags to component docs, then re-run."
    exit 0
  fi

  printf '```mermaid\ngraph LR\n'
  printf '%s\n' "${node_lines[@]}"
  [[ ${#edge_lines[@]} -gt 0 ]] && printf '%s\n' "${edge_lines[@]}"
  printf '```\n'
}

# ─── install-hook ─────────────────────────────────────────────────────────────

cmd_install_hook() {
  local repo_path="${1:-}"

  if [[ -z "$repo_path" ]]; then
    echo "Usage: ./docit.sh install-hook <repo-path>" >&2
    exit 1
  fi

  local abs_repo
  abs_repo="$(cd "$repo_path" 2>/dev/null && pwd)" || {
    echo "Error: path not found: $repo_path" >&2
    exit 1
  }

  if [[ ! -d "$abs_repo/.git" ]]; then
    echo "Error: $abs_repo is not a git repository" >&2
    exit 1
  fi

  local project_name
  project_name="$(basename "$abs_repo")"
  local hook_path="$abs_repo/.git/hooks/post-commit"
  local sessions_dir="$DOCIT_ROOT/sessions"

  if [[ -f "$hook_path" ]]; then
    echo "Warning: post-commit hook already exists at $hook_path"
    read -r -p "Overwrite? (yes/no): " confirm
    [[ "$confirm" != "yes" ]] && exit 0
  fi

  cat > "$hook_path" <<HOOK
#!/usr/bin/env bash
# DocIt post-commit hook — auto-generated by docit.sh install-hook
# Logs changed files to a pending session in DocIt's sessions/ directory.
# Run: ./docit.sh update $project_name <files> to generate the update prompt.

DOCIT_DIR="$DOCIT_ROOT"
PROJECT="$project_name"

CHANGED="\$(git diff-tree --no-commit-id -r --name-only HEAD 2>/dev/null)"
[[ -z "\$CHANGED" ]] && exit 0

DATE="\$(date -u '+%Y-%m-%d')"
SESSION_FILE="\$DOCIT_DIR/sessions/\${DATE}-\${PROJECT}-pending.md"

mkdir -p "\$DOCIT_DIR/sessions"

{
  # Create header if file doesn't exist yet
  if [[ ! -f "\$SESSION_FILE" ]]; then
    printf '# Session: %s — %s\n\n' "$project_name" "\$DATE"
    printf '<!-- session: %s -->\n' "\$DATE"
    printf '**Project**: %s\n' "$project_name"
    printf '**Focus**: pending updates from commits\n\n'
    printf '## Pending Changes\n\n'
  fi

  printf '### Commit: %s\n' "\$(git log -1 --format='%h %s')"
  printf '%s\n\n' "\$(echo "\$CHANGED" | sed 's/^/- /')"

} >> "\$SESSION_FILE"

echo "DocIt: logged changes → \${SESSION_FILE#\$DOCIT_DIR/}"
HOOK

  chmod +x "$hook_path"

  echo "Hook installed: $hook_path"
  echo "Project:        $project_name"
  echo "Sessions dir:   $sessions_dir/"
  echo ""
  echo "After each commit, changed files will be logged to sessions/."
  echo "Run: ./docit.sh update $project_name <files> to generate the update prompt."
}

# ─── init ─────────────────────────────────────────────────────────────────────

cmd_init() {
  echo "DocIt Setup"
  echo "==========="
  echo ""

  if [[ -f "$DOCIT_ROOT/.docit.conf" ]]; then
    echo "Found existing .docit.conf:"
    cat "$DOCIT_ROOT/.docit.conf"
    echo ""
    read -r -p "Reconfigure? (yes/no) [no]: " redo
    [[ "${redo:-no}" != "yes" ]] && exit 0
  fi

  # LLM backend
  echo "LLM Backend:"
  echo "  1) claude       (default — requires Claude CLI: https://docs.anthropic.com/claude-code)"
  echo "  2) ollama       (local — https://ollama.com)"
  echo "  3) llama-server (local — https://github.com/ggerganov/llama.cpp)"
  echo ""
  read -r -p "Choice [1]: " llm_choice

  local llm_val="claude"
  local model_val=""
  local url_val=""

  case "${llm_choice:-1}" in
    2)
      llm_val="ollama"
      read -r -p "Model name [llama3.1:8b]: " model_input
      model_val="${model_input:-llama3.1:8b}"
      ;;
    3)
      llm_val="llama-server"
      read -r -p "Server URL [http://localhost:8080]: " url_input
      url_val="${url_input:-http://localhost:8080}"
      read -r -p "Model name [local]: " model_input
      model_val="${model_input:-local}"
      ;;
  esac

  # Backup
  echo ""
  read -r -p "Backup directory (leave blank to skip): " backup_input

  # Auto-sync
  echo ""
  read -r -p "Install auto-sync (cron/systemd)? (yes/no) [no]: " sync_choice

  # Write config
  {
    echo "DOCIT_LLM=$llm_val"
    [[ -n "$model_val" ]] && echo "DOCIT_LLM_MODEL=$model_val"
    [[ -n "$url_val" ]]   && echo "DOCIT_LLM_URL=$url_val"
    [[ -n "$backup_input" ]] && echo "DOCIT_BACKUP_DIR=$backup_input"
  } > "$DOCIT_ROOT/.docit.conf"

  echo ""
  echo "Written: .docit.conf"
  cat "$DOCIT_ROOT/.docit.conf"

  if [[ "${sync_choice:-no}" == "yes" ]]; then
    echo ""
    "$DOCIT_ROOT/setup.sh"
  fi

  echo ""
  echo "DocIt is ready."
  echo "Next: ./docit.sh ingest <path-to-codebase>"
}

# ─── sync / backup (delegate) ─────────────────────────────────────────────────

cmd_sync() {
  local remote="${1:-}"
  [[ -n "$remote" ]] && "$DOCIT_ROOT/merge.sh" "$remote" || "$DOCIT_ROOT/merge.sh"
}

cmd_backup() {
  "$DOCIT_ROOT/backup.sh" "${1:-${DOCIT_BACKUP_DIR:-}}"
}

# ─── Entry point ──────────────────────────────────────────────────────────────

case "${1:-help}" in
  init)              cmd_init ;;
  ingest|explore)    cmd_ingest       "${2:-}" ;;
  query)             cmd_query        "${2:-}" "${@:3}" ;;
  lint)              cmd_lint         "${@:2}" ;;
  graph)             cmd_graph        "${2:-}" ;;
  update)            cmd_update       "${2:-}" "${@:3}" ;;
  install-hook)      cmd_install_hook "${2:-}" ;;
  status)            cmd_status ;;
  sync)              cmd_sync         "${2:-}" ;;
  backup)            cmd_backup       "${2:-}" ;;
  help|--help|-h)    usage ;;
  *)
    echo "Unknown command: $1" >&2; echo ""; usage; exit 1 ;;
esac
