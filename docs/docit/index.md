# DocIt

> A codebase explorer powered by markdown and an AI agent. No special software required.

<!-- explored: 2026-02-26 -->

## Overview

- **Language(s)**: Markdown, Bash
- **Type**: Documentation system / agent-driven knowledge tool
- **Size**: 5 files, ~4 key concepts
- **Entry points**: `docit.sh`, `CLAUDE.md` (agent entry), `DOCIT.md` (state entry)

## Directory Structure

```
DocIt/
├── CLAUDE.md           ← Agent operating instructions
├── DOCIT.md            ← Living document: vision, state, exploration log
├── README.md           ← Human-facing introduction
├── docit.sh            ← Session helper script
└── docs/               ← All generated codebase explorations
    └── docit/
        └── index.md    ← This file (DocIt exploring itself)
```

## Architecture

DocIt is a three-layer system. The **instructions layer** (`CLAUDE.md`) is stable — it defines the rules the agent follows. The **state layer** (`DOCIT.md`) is fluid — it tracks what's known, what's not, and what's next. The **knowledge layer** (`docs/`) grows with every exploration.

No code runs at start-up. The system activates when a user opens a conversation with Claude, references `CLAUDE.md`, and asks about a codebase. The agent is the runtime.

## Key Concepts

- **Living documentation**: docs are augmented, not replaced, on each session
- **Acknowledged gaps**: `<!-- TODO: -->` markers are first-class — better to mark uncertainty than fake completeness
- **Dogfooding**: `docs/docit/` shows what DocIt output looks like, using DocIt itself as the subject
- **Pseudo software**: the markdown files are the program; the AI agent is the CPU

## Components

| Component | Path | Purpose |
|-----------|------|---------|
| [Agent Instructions](./agent-instructions.md) | `CLAUDE.md` | Defines agent behaviour, templates, conventions |
| [Living Document](./living-document.md) | `DOCIT.md` | System state, vision, exploration log |
| [Session Helper](./session-helper.md) | `docit.sh` | CLI to start exploration sessions |

## Dependencies

- **Claude (AI agent)**: the agent that reads `CLAUDE.md` and does the exploration work
- **Bash**: for `docit.sh` (requires bash 4+ for `mapfile`)
- **Git**: optional, but expected — DocIt repos are meant to be version-controlled

## Open Questions

- Should each `docs/<project>/` have a `state.md` for per-project exploration tracking?
- At what corpus size does LanceDB indexing become worth the complexity?
- Should `docit.sh explore` open the conversation automatically via `claude` CLI?

<!-- TODO: add docs/docit/agent-instructions.md deeper analysis -->
<!-- TODO: add docs/docit/living-document.md deeper analysis -->
