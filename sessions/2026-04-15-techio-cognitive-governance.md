# Session: Techio — Beyond Karpathy's LLM-Wiki

**Date**: 2026-04-15
**Source**: https://www.jonadas.com/writing/essays/beyond-karpathys-llm-wiki
**Focus**: External essay — cognitive governance applied to DocIt

---

## Raw Observations

### The core argument
Techio fed 300 files of reading notes to an LLM compiler (Karpathy-style). Output was accurate, well-formatted, completely useless — read like Wikipedia. Root cause: LLMs pull toward consensus, toward the average of everything they've read. Frictionless fluency erases the tensions that make ideas worth having.

His fix: cognitive governance — an explicit ruleset (SCHEMA.md) that forces the agent to find antagonists, surface contradictions, identify omissions, resist consensus.

### The three-layer architecture (Zettelkasten-adapted)
| Layer | Rule |
|-------|------|
| Raw sources (PDFs, original notes) | Immutable — agent reads, never modifies |
| LIT notes (extracted claims) | Agent creates, structured per source |
| ZET/MOC (atomic insights, maps) | Agent links; governed by SCHEMA.md |

SCHEMA.md = CLAUDE.md in DocIt terms. Both are governance programs written in natural language.

### Why this is directly relevant to DocIt
- DocIt's ingest/update operations have no friction-preservation instruction — the agent will naturally produce consensus docs
- Source docs (PDFs) we just added have no immutability rule — without one, an agent could quietly rewrite quoted excerpts to match what the code does
- DocIt's lint --deep asks for contradictions but doesn't give a checklist that forces antagonistic reading

### What was NOT taken from Techio
- Full LIT/ZET/MOC pipeline — DocIt already has its own tier system (sessions → docs → patterns → INSIGHTS). Mapping exactly onto Zettelkasten would create confusion rather than improvement
- Human-in-the-loop review at each tier — DocIt is designed to minimise friction

---

## Findings to Promote

- [x] → `CLAUDE.md`: Source doc immutability — quoted excerpts locked, only links/coverage around them can change
- [x] → `CLAUDE.md`: `> **Tension**:` convention added to conventions table
- [x] → `CLAUDE.md`: Friction Preservation section — when to use Tension, why consensus docs are dangerous
- [x] → `CLAUDE.md`: Antagonistic Lint — specific checklist for what lint should hunt for
- [x] → `docs/docit/agent-instructions.md`: Key sections table updated, gotchas updated
- [x] → `docs/docit/index.md`: Key concepts updated with friction preservation and source traceability
- [x] → `INSIGHTS.md`: "Consensus Docs Are Dangerous" entry added
- [x] → `DOCIT.md`: Exploration log row added

<!-- crystallised: 2026-04-15 -->
