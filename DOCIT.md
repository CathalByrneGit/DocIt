# DOCIT — Living Document

> A codebase explorer powered by markdown and an AI agent.
> No databases. No special software. Just structured thinking, evolving in writing.

<!-- last-updated: 2026-04-08 -->

---

## Vision

Modern codebases are complex. Documentation rots. Wikis go stale. Onboarding takes days.

DocIt takes a different approach: instead of documentation that diverges from code, DocIt maintains a **living document system** where an AI agent explores a codebase and continuously updates structured markdown. Each session adds to the previous. Nothing is thrown away.

The core insight — borrowed from plain-text knowledge management and AI-assisted development — is that **a well-crafted markdown file, read by a capable agent, is enough**. The markdown is both the database and the interface. The agent is the runtime.

---

## How It Works

```
User: "Explore this repo: ~/projects/myapp"
         │
         ▼
   Agent reads CLAUDE.md        ← operating rules
   Agent reads DOCIT.md         ← current state
         │
         ▼
   Agent scans target codebase
         │
         ▼
   Creates/updates docs/<myapp>/
     ├── index.md               ← overview, structure, entry points
     ├── core.md                ← component doc
     └── api.md                 ← component doc
         │
         ▼
   Updates DOCIT.md             ← logs what was explored
         │
         ▼
User: "What does the auth module do?"
   Agent reads existing docs first, then digs deeper, then updates
```

Each run **augments** rather than replaces. The docs accumulate understanding.

---

## Architecture

```
DocIt/
├── CLAUDE.md               ← Agent instructions (procedural tier — stable)
├── DOCIT.md                ← This file: living spec + state + log (episodic tier)
├── README.md               ← Human quick-start
├── docit.sh                ← Main CLI: init, ingest, query, lint, graph,
│                              update, install-hook, status, sync, backup
├── llm.sh                  ← LLM backend abstraction (claude/ollama/llama-server)
├── .docit.conf.example     ← Config template (copy to .docit.conf, gitignored)
│
├── backup.sh               ← Sync docs/ to a private git repo
├── restore.sh              ← Restore docs/ from backup
├── merge.sh                ← Remote sync or --contrib federation merge
├── cron.sh                 ← Scheduled sync wrapper (lock file + logging)
├── setup.sh                ← Install cron/systemd automation
│
├── MESSAGES.md             ← Shared inbox: agents and contributors leave notes
├── INSIGHTS.md             ← Cross-codebase knowledge ledger (core DocIt only)
├── CONTRIBUTORS.md         ← Team members feeding into this core DocIt
│
├── sessions/               ← Working memory tier (ephemeral session notes)
│   └── README.md
│
├── patterns/               ← Cross-project pattern library (middle tier)
│   └── index.md
│
└── docs/                   ← Semantic tier: all generated explorations
    ├── docit/              ← DocIt exploring itself (dogfood)
    │   ├── index.md
    │   ├── agent-instructions.md
    │   ├── living-document.md
    │   ├── session-helper.md
    │   └── sync-scripts.md
    └── <project>/          ← One directory per explored codebase
        ├── index.md
        └── <component>.md
```

### Four Consolidation Tiers

| Tier | Where | Stability | Updated when |
|------|-------|-----------|--------------|
| **Working** | `sessions/` | Ephemeral | During the session |
| **Episodic** | `DOCIT.md` exploration log | Append-only | Every session |
| **Semantic** | `docs/`, `patterns/` | Durable, evolving | Each ingest/update |
| **Procedural** | `CLAUDE.md` | Stable | Only when the system itself improves |

### Individual vs Core DocIt

| Mode | Has | Purpose |
|------|-----|---------|
| **Individual** | `CLAUDE.md`, `DOCIT.md`, scripts, `docs/` | One person's lens on codebases they work with |
| **Core** | Everything above + `MESSAGES.md`, `INSIGHTS.md`, `CONTRIBUTORS.md` | Team's shared, synthesised knowledge base |

Individual DocIts feed into a core via `merge.sh --contrib`. The core agent reads the inbox (`MESSAGES.md`) at session start and synthesises cross-project patterns into `INSIGHTS.md`.

---

## Philosophy

### Markdown as Software

The `CLAUDE.md` file is the program. The `DOCIT.md` file is the state. The agent is the CPU. This is "pseudo software" in the most useful sense — no compilation, no deployment, no versioning hell. Just text files and conversation.

When you fork this repo, you get the whole system. When you collaborate, your teammates read the same docs. When the codebase changes, you run DocIt again and the docs are updated, not replaced.

### Living Documentation

Traditional docs: written once, rot immediately.
DocIt: written incrementally, updated on each exploration, gaps explicitly marked.

The `<!-- TODO: explore X -->` markers are first-class citizens. Acknowledged gaps are better than pretended completeness.

### Evolving Alongside the User

DocIt grows in tandem with the user's understanding. Early explorations are shallow. Later ones fill in detail. The agent knows what's already documented and builds on it rather than starting fresh.

---

## Current Status

- [x] Project created and bootstrapped
- [x] `CLAUDE.md` — agent instructions written (incl. core DocIt session rules)
- [x] `DOCIT.md` — this living document created
- [x] `README.md` — human quick-start written
- [x] `docit.sh` — init, ingest, query, lint (+ --deep), graph, update, install-hook, status, sync, backup
- [x] `docs/docit/` — DocIt's self-documentation
- [x] `backup.sh` / `restore.sh` / `merge.sh` / `cron.sh` / `setup.sh` — sync scripts
- [x] `MESSAGES.md` / `INSIGHTS.md` / `CONTRIBUTORS.md` — federation layer (seeded)
- [x] `llm.sh` — LLM backend abstraction (claude / ollama / llama-server)
- [x] `sessions/` — working memory tier; session files feed crystallisation
- [x] `patterns/` — cross-project pattern library (middle tier)
- [x] Entity tagging — `<!-- entity: -->` + `<!-- depends-on: -->` in component docs
- [x] `docit.sh graph` — Mermaid dependency graph from entity tags
- [x] `docit.sh install-hook` — post-commit hook logging changes to `sessions/`
- [x] `docit.sh init` — guided first-time setup wizard
- [x] `docit.sh lint --deep` — LLM-powered contradiction/inconsistency detection
- [x] Crystallisation protocol — sessions/ as source, patterns/ as destination, INSIGHTS.md for cross-project
- [x] Supersession convention — `<!-- superseded: -->` inline markers
- [x] Consolidation tiers — working → episodic → semantic → procedural
- [x] `.docit.conf.example` + `.gitignore`
- [ ] First external codebase explored
- [ ] Template validated against a real project
- [ ] First contributor merged via `merge.sh --contrib`
- [ ] LanceDB semantic indexing (future)

---

## Exploration Log

| Date | Target | Type | Notes |
|------|--------|------|-------|
| 2026-02-26 | DocIt | Bootstrap | Initial structure created; DocIt explores itself |
| 2026-02-27 | DocIt | Enhancement | Added sync scripts (backup, restore, merge, cron, setup); federation layer (MESSAGES, INSIGHTS, CONTRIBUTORS); core DocIt instructions in CLAUDE.md |
| 2026-02-27 | DocIt | Enhancement | Added Mermaid guidelines to CLAUDE.md (when/which type/conventions/4 examples); live architecture diagrams in docs/docit/index.md |
| 2026-04-08 | DocIt | Enhancement | Karpathy triangle complete: ingest+query+lint; llm.sh backend abstraction; crystallisation + supersession + consolidation tiers in CLAUDE.md |
| 2026-04-08 | DocIt | Enhancement | Karpathy/Rohit synthesis: sessions/ (working tier), patterns/ (middle tier), entity tagging, graph command, install-hook, lint --deep, init wizard |
| 2026-04-08 | DocIt | Doc update | Updated existing docs to match new functionality: README rewritten; index.md, agent-instructions.md, living-document.md, session-helper.md updated; sync-scripts.md created; DOCIT.md tiers/architecture corrected |
| 2026-04-08 | mempalace (external) | Exploration | Explored milla-jovovich/mempalace for applicable ideas; extracted 4 learnings: load tiering, bidirectional pattern links, store-verbatim principle, halls/fact-types concept; applied first three to CLAUDE.md and INSIGHTS.md |
| 2026-04-15 | jonadas.com (external) | Exploration | Explored "Beyond Karpathy's LLM-Wiki: The Necessity of Cognitive Governance" (Techio); applied 3 learnings to CLAUDE.md: source doc immutability, `> **Tension**:` friction-preservation convention, antagonistic lint checklist; docs updated accordingly |
| 2026-04-20 | passo.uno (external) | Exploration | Explored "What makes docs beautiful" (Ferri-Benedetti); applied Calvino's six literary qualities as a Writing Style section in CLAUDE.md: lightness, quickness, exactitude, visibility, multiplicity, consistency |

---

## Open Questions

- How granular should component docs be — file-level or directory-level? (Hypothesis: directory-level for large projects, file-level for small ones)
- What's the right update strategy for large codebases — section-by-section, or full re-exploration?
- Should `DOCIT.md` track per-codebase state, or should each `docs/<project>/` have its own `state.md`?
- At what point does a flat `docs/<project>/` directory need subdirectories?
- When a core DocIt merges from N contributors simultaneously, what's the right ordering? (Most recent first? By contributor seniority on the project?)
- Should `MESSAGES.md` have an archiving convention once it grows large?

---

## Next Steps

1. Run DocIt on a real codebase to validate the ingest templates end-to-end
2. Run the first crystallisation cycle: explore → write session file → promote to docs
3. Try `merge.sh --contrib` with a real second DocIt to stress-test federation
4. Add a pattern doc to `patterns/` once the same approach is seen in 2+ projects
5. Iterate on `CLAUDE.md` based on what the agent needs but doesn't have in practice

---

## Future

**LanceDB indexing** — embed each doc chunk and store in a local LanceDB. Enables semantic search across all explorations: *"where does authentication happen across all my projects?"*. The markdown remains the source of truth; LanceDB is a query accelerator. Worth adding once the corpus exceeds ~50 docs.
