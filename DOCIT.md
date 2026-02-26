# DOCIT — Living Document

> A codebase explorer powered by markdown and an AI agent.
> No databases. No special software. Just structured thinking, evolving in writing.

<!-- last-updated: 2026-02-26 -->

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
├── CLAUDE.md           ← Agent instructions (the "brain" — stable)
├── DOCIT.md            ← This file: living spec + state + log (evolving)
├── README.md           ← Human quick-start
├── docit.sh            ← Helper script for starting sessions
└── docs/               ← All generated explorations
    ├── docit/          ← DocIt exploring itself (dogfood)
    │   └── index.md
    └── <project>/      ← One directory per explored codebase
        ├── index.md
        └── <component>.md
```

### The Three Layers

| Layer | File(s) | Role | Changes |
|-------|---------|------|---------|
| **Instructions** | `CLAUDE.md` | How the agent behaves | Rarely — only as the system improves |
| **State** | `DOCIT.md` | What's been done, what's next | Every session |
| **Knowledge** | `docs/**` | Deep per-codebase documentation | Every exploration |

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
- [x] `CLAUDE.md` — agent instructions written
- [x] `DOCIT.md` — this living document created
- [x] `README.md` — human quick-start written
- [x] `docit.sh` — helper script created
- [x] `docs/docit/` — DocIt's self-documentation
- [ ] First external codebase explored
- [ ] Template validated against a real project
- [ ] Mermaid diagram support (future)
- [ ] LanceDB semantic indexing (future)

---

## Exploration Log

| Date | Target | Type | Notes |
|------|--------|------|-------|
| 2026-02-26 | DocIt | Bootstrap | Initial structure created; DocIt explores itself |

---

## Open Questions

- How granular should component docs be — file-level or directory-level? (Hypothesis: directory-level for large projects, file-level for small ones)
- What's the right update strategy for large codebases — section-by-section, or full re-exploration?
- Should `DOCIT.md` track per-codebase state, or should each `docs/<project>/` have its own `state.md`?
- At what point does a flat `docs/<project>/` directory need subdirectories?

---

## Next Steps

1. Run DocIt on a real codebase to validate the templates
2. Iterate on `CLAUDE.md` based on what the agent needs but doesn't have
3. Add a `state.md` per exploration if multi-session tracking gets complex
4. Consider: should `docit.sh` emit a ready-made prompt, or just a session overview?

---

## Future: LanceDB + Mermaid

When the markdown corpus grows large enough, two additions become worthwhile:

**Mermaid diagrams** — generate architecture diagrams directly in markdown. The agent already understands structure; emitting `graph TD` blocks is a small step. Useful for: data flows, module dependencies, class hierarchies.

**LanceDB indexing** — embed each doc chunk and store in a local LanceDB. Enables semantic search across all explorations: *"where does authentication happen across all my projects?"*. The markdown remains the source of truth; LanceDB is a query accelerator.

Neither is needed for v1. The markdown is already useful.
