# DocIt

> Explore and understand codebases through evolving markdown, powered by an AI agent.

---

## What Is This?

DocIt is a documentation system built on a simple idea: a well-crafted markdown file + a capable AI agent = living codebase documentation that stays useful over time.

You point DocIt at a codebase. The agent explores it, writes structured markdown, and tags components with typed entity relationships. Next time you ask about that codebase, the agent reads existing docs first. Over time, your docs accumulate real understanding — architecture, data flows, patterns, gotchas, open questions.

No databases. No build steps. No special software. Just markdown files and conversation.

---

## Quick Start

```bash
# 1. Clone and configure
git clone <this-repo> ~/DocIt
cd ~/DocIt
./docit.sh init          # guided setup: LLM backend, backup, auto-sync

# 2. Explore a codebase
./docit.sh ingest ~/projects/myapp

# 3. Paste the printed prompt into a Claude conversation
#    Agent reads CLAUDE.md, explores the codebase, writes docs/myapp/

# 4. Query your docs without opening a conversation
./docit.sh query "how does authentication work?" --project myapp

# 5. Check doc health
./docit.sh lint myapp
./docit.sh lint myapp --deep    # LLM-powered contradiction detection

# 6. See the dependency graph
./docit.sh graph myapp
```

---

## Repository Layout

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Agent instructions — the system's brain |
| `DOCIT.md` | Living document — spec, state, exploration log |
| `README.md` | This file |
| `docit.sh` | Main CLI: init, ingest, query, lint, graph, update, install-hook, sync, backup |
| `llm.sh` | LLM backend abstraction — claude / ollama / llama-server |
| `backup.sh` | Sync docs to a private git repo |
| `restore.sh` | Restore docs from backup |
| `merge.sh` | Sync with remote or merge a contributor's DocIt; uses `claude -p` for conflicts |
| `cron.sh` | Scheduled sync wrapper with lock file |
| `setup.sh` | Install cron/systemd automation |
| `.docit.conf.example` | Config template — copy to `.docit.conf` |
| `docs/` | All generated codebase explorations |
| `docs/docit/` | DocIt's self-documentation |
| `sessions/` | Working memory — raw session notes before crystallisation |
| `patterns/` | Cross-project architectural pattern library |
| `MESSAGES.md` | Shared inbox for agents and contributors (core DocIt) |
| `INSIGHTS.md` | Cross-codebase knowledge ledger (core DocIt) |
| `CONTRIBUTORS.md` | Team contributor registry (core DocIt) |

---

## How It Works

DocIt has three operations, all of which end with a **Crystallisation** step that flows knowledge upward:

```
Ingest  → explore a codebase → docs/<project>/
Update  → re-examine changed files → patch affected docs
Query   → answer a question → synthesised from existing docs
```

Knowledge flows through four tiers:

```
sessions/          ← working memory (raw notes during a session)
     ↓
DOCIT.md log       ← episodic (what happened, when)
     ↓
docs/<project>/    ← semantic (durable component docs)
patterns/          ← semantic (cross-project patterns)
     ↓
CLAUDE.md          ← procedural (the rules themselves)
```

---

## LLM Backends

DocIt works with Claude (default), Ollama, or llama-server. Configure in `.docit.conf`:

```bash
DOCIT_LLM=ollama
DOCIT_LLM_MODEL=qwen2.5:14b
```

See `.docit.conf.example` for all options. The `query`, `lint --deep`, and `merge.sh` conflict resolution all route through `llm.sh` — switching backends requires no script changes.

---

## Team Use

Each team member runs their own DocIt. A shared **core DocIt** aggregates knowledge:

```
alice/DocIt  ──merge.sh --contrib──▶  core/DocIt
bob/DocIt    ──merge.sh --contrib──▶      │
                                     MESSAGES.md   ← shared inbox
                                     INSIGHTS.md   ← cross-project patterns
                                     CONTRIBUTORS.md
```

The core agent reads `MESSAGES.md` at session start and acts on pending items.

---

## Staying Current

Install a post-commit hook in any repo you're documenting:

```bash
./docit.sh install-hook ~/projects/myapp
```

Every commit to that repo logs changed files to `sessions/`. Run `./docit.sh update myapp <files>` to generate the re-ingest prompt.

---

## Philosophy

The `CLAUDE.md` file is the program. The `DOCIT.md` file is the state. The agent is the CPU. This is "pseudo software" — no compilation, no deployment, no versioning hell. Fork the repo and you get the whole system.

Inspired by [PaulKinlan/journal](https://github.com/PaulKinlan/journal), [Karpathy's LLM wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f), and the idea that plain text + a capable agent = powerful software.
