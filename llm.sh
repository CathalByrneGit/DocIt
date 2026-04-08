#!/usr/bin/env bash
# llm.sh — LLM backend abstraction for DocIt
#
# Usage:
#   ./llm.sh "prompt text"
#   echo "prompt" | ./llm.sh
#   ./llm.sh --system "system prompt" "user prompt"
#
# Configuration (.docit.conf or environment variables):
#   DOCIT_LLM=claude            # claude (default) | ollama | llama-server
#   DOCIT_LLM_MODEL=llama3.1:8b # model name (ollama / llama-server)
#   DOCIT_LLM_URL=http://...    # base URL for llama-server (default: localhost:8080)
#   DOCIT_LLM_TEMPERATURE=0.2   # sampling temperature (default: 0.2)
#
# All DocIt scripts that need LLM inference route through here.
# To switch from Claude to a local model, set DOCIT_LLM in .docit.conf.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config if present
if [[ -f "$SCRIPT_DIR/.docit.conf" ]]; then
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/.docit.conf"
fi

BACKEND="${DOCIT_LLM:-claude}"
MODEL="${DOCIT_LLM_MODEL:-}"
URL="${DOCIT_LLM_URL:-http://localhost:8080}"
TEMPERATURE="${DOCIT_LLM_TEMPERATURE:-0.2}"

# ─── Parse args ───────────────────────────────────────────────────────────────

SYSTEM_PROMPT=""
USER_PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --system)
      SYSTEM_PROMPT="${2:-}"
      shift 2
      ;;
    --help|-h)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      USER_PROMPT="$1"
      shift
      ;;
  esac
done

# Read from stdin if no positional prompt given
if [[ -z "$USER_PROMPT" ]]; then
  USER_PROMPT="$(cat)"
fi

if [[ -z "$USER_PROMPT" ]]; then
  echo "Error: no prompt provided (pass as argument or via stdin)" >&2
  exit 1
fi

# ─── Backend: claude ──────────────────────────────────────────────────────────

backend_claude() {
  if ! command -v claude &>/dev/null; then
    echo "Error: 'claude' CLI not found. Install it or set DOCIT_LLM to another backend." >&2
    exit 1
  fi
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    printf '%s\n\n%s' "$SYSTEM_PROMPT" "$USER_PROMPT" | claude -p
  else
    printf '%s' "$USER_PROMPT" | claude -p
  fi
}

# ─── Backend: ollama ──────────────────────────────────────────────────────────

backend_ollama() {
  MODEL="${MODEL:-llama3.1:8b}"
  if ! command -v ollama &>/dev/null && ! curl -sf http://localhost:11434/api/tags &>/dev/null; then
    echo "Error: ollama not running. Start it with: ollama serve" >&2
    exit 1
  fi

  local payload
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    payload="$(jq -n \
      --arg model "$MODEL" \
      --arg system "$SYSTEM_PROMPT" \
      --arg user "$USER_PROMPT" \
      '{model: $model, stream: false, messages: [
        {role: "system", content: $system},
        {role: "user",   content: $user}
      ]}')"
  else
    payload="$(jq -n \
      --arg model "$MODEL" \
      --arg user "$USER_PROMPT" \
      '{model: $model, stream: false, messages: [
        {role: "user", content: $user}
      ]}')"
  fi

  curl -sf http://localhost:11434/api/chat \
    -H "Content-Type: application/json" \
    -d "$payload" | jq -r '.message.content'
}

# ─── Backend: llama-server ────────────────────────────────────────────────────

backend_llama_server() {
  if ! curl -sf "$URL/health" &>/dev/null && ! curl -sf "$URL/v1/models" &>/dev/null; then
    echo "Error: llama-server not reachable at $URL" >&2
    echo "Start it with: llama-server --model <model.gguf> --port 8080" >&2
    exit 1
  fi

  local messages
  if [[ -n "$SYSTEM_PROMPT" ]]; then
    messages="$(jq -n \
      --arg system "$SYSTEM_PROMPT" \
      --arg user "$USER_PROMPT" \
      '[{role:"system",content:$system},{role:"user",content:$user}]')"
  else
    messages="$(jq -n \
      --arg user "$USER_PROMPT" \
      '[{role:"user",content:$user}]')"
  fi

  curl -sf "$URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --argjson msgs "$messages" \
      --argjson temp "$TEMPERATURE" \
      '{model:"local", temperature:$temp, messages:$msgs}')" \
  | jq -r '.choices[0].message.content'
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────

case "$BACKEND" in
  claude)        backend_claude ;;
  ollama)        backend_ollama ;;
  llama-server)  backend_llama_server ;;
  *)
    echo "Error: unknown DOCIT_LLM backend: '$BACKEND'" >&2
    echo "Valid values: claude, ollama, llama-server" >&2
    exit 1
    ;;
esac
