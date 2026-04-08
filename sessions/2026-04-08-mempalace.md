# Session: MemPalace exploration

**Date**: 2026-04-08
**Source**: https://github.com/milla-jovovich/mempalace
**Focus**: External system — mining for ideas applicable to DocIt

---

## Raw Observations

### What MemPalace is
- Local-first AI memory system, 96.6% R@5 on LongMemEval (raw verbatim mode, 500 test questions)
- Ancient mnemonic "method of loci" applied to AI memory: spatially structured retrieval
- Pure local: ChromaDB + SQLite, zero API calls at retrieval time
- 23-file Python library with MCP server (19 tools), CLI, and knowledge graph

### The Palace metaphor
| MemPalace term | DocIt equivalent |
|---|---|
| Wing | `docs/<project>/` |
| Room | component doc |
| Hall | cross-cutting fact category (no equivalent yet) |
| Closet | `<!-- explored: -->` summary in index.md |
| Drawer | raw session notes in `sessions/` |
| Tunnel | `patterns/` cross-project links |

### The 4-layer memory stack (layers.py)
- L0 (~100 tokens): `identity.txt` — always loaded, stable "who am I" context
- L1 (~600-900 tokens): top-15 highest-weight memories across all rooms — "essential story"
- L2 (~200-500 tokens each): on-demand filtered by wing or room — loaded when topic comes up
- L3 (unlimited): full semantic search when needed
- "Wake-up" = L0+L1, designed to inject into system prompt without eating context window

**DocIt gap**: CLAUDE.md says "read relevant existing docs" but doesn't structure HOW. Agents on large projects currently load everything, risking context overflow. Need explicit load order: index.md always → recently modified component docs → specific components on demand.

### "Store verbatim, retrieve structured" — the key finding
- AAAK lossy compression (abbreviation dialect): 84.2% R@5
- Raw verbatim + ChromaDB: 96.6% R@5
- Compression loses context that retrieval depends on
- DocIt's supersession convention already follows this: never delete, mark superseded

### Tunnel rooms = bidirectional pattern links
- "Same room appearing in multiple wings auto-creates tunnel rooms (bridge nodes)"
- MemPalace makes cross-wing connections automatic and visible
- DocIt's patterns/ has the forward link: `Seen in: project-a, project-b`
- Gap: component docs in project-a don't link BACK to the pattern
- DocIt already has `<!-- implements: pattern-name -->` entity tag — just needs the prose convention too

### Halls = cross-cutting fact types
- Halls represent memory types consistent ACROSS all wings: facts, events, discoveries, preferences, advice
- MemPalace's general_extractor classifies facts into: decisions, preferences, milestones, problems, emotional
- Classification is keyword-heuristic, not LLM (validates DocIt's lightweight philosophy)
- DocIt has entity types for COMPONENTS (module/service/model/interface/utility/pattern) but no equivalent for individual FACTS within docs
- Not implementing yet — needs validation across 2+ real project docs first

### The April 2026 transparency note
- Maintainers self-corrected: AAAK compression was overclaimed, "+34% palace boost" was standard filtering not novel, some features not wired
- 96.6% headline stands but only for raw verbatim mode
- Relevant: MemPalace ran into the same problem DocIt's supersession convention is designed to prevent — quiet overwrites. They had to publish a retraction note instead of having inline correction history.

---

## Findings to Promote

- [ ] → `CLAUDE.md`: Add structured session reading order (load tiering)
  - Start: DOCIT.md + project index.md (L0 equivalent)
  - Then: component docs for affected areas only (L2 equivalent)
  - Full load only when needed (L3 equivalent)

- [ ] → `CLAUDE.md`: Strengthen bidirectional pattern links
  - When a component implements a pattern, add prose link to `patterns/<name>.md` in Dependencies section
  - Already have `<!-- implements: -->` tag; add the human-readable link convention

- [ ] → `INSIGHTS.md`: "Store verbatim, retrieve structured" principle
  - Seen in: mempalace (and implicitly DocIt's own design)
  - Raw storage + structured retrieval > lossy compression + unstructured retrieval

- [ ] → `DOCIT.md`: Exploration log row

<!-- crystallised: 2026-04-08 -->
