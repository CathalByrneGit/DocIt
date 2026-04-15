# Agent Instructions

**Path**: `CLAUDE.md`
**Purpose**: Defines how the DocIt agent behaves in every session.

<!-- explored: 2026-04-15 -->

## What It Does

`CLAUDE.md` is the agent's operating manual and the procedural tier of the knowledge model. When a user opens a DocIt conversation, the agent reads this file to understand the full operating context: what DocIt is, what the three operations are, how to write and tag docs, how to end a session, and what cross-project knowledge infrastructure to maintain.

## Key Sections

| Section | Purpose | Stability |
|---------|---------|-----------|
| Your Role | Agent mindset — augment, don't rewrite | Stable |
| Session Reading Order | Load tiering: index first, component docs on demand, full scan only for lint/graph | Stable |
| Consolidation Tiers | Four-layer knowledge model (working → episodic → semantic → procedural) | Stable |
| The Three Operations | Ingest / Update / Query as first-class operations | Stable |
| Ingest: New Codebase | Step-by-step for first-time codebase scans + Index Template | Stable |
| Component Template | Markdown template for module docs; includes entity tags | Stable |
| Update: After Code Changes | How to re-examine changed files and patch docs | Stable |
| End of Session: Crystallisation | 6-step end-of-session protocol | Stable |
| Conventions | File naming, dates, links, inferred, **tension**, gaps, supersession, entity tags | Stable |
| Friction Preservation | When to use `> **Tension**:`; why consensus docs are dangerous | Stable |
| Supersession Convention | How to mark outdated claims without deleting them | Stable |
| Entity Tagging | Entity types (incl. `source`), relationship tags (incl. `satisfies`), example | Stable |
| Source Documents | PDF/spec ingestion workflow; source doc template; immutability rule | Stable |
| Patterns | When to create `patterns/<name>.md` vs just note in INSIGHTS.md | Stable |
| Mermaid Diagrams | When to add, which type, conventions, four copy-paste examples | Stable |
| What Not To Do | Guard rails incl. consensus-doc prohibition; Antagonistic Lint checklist | Stable |
| If This Is a Core DocIt | Extra session-start protocol for reading MESSAGES.md and INSIGHTS.md | Stable |

## How It Works

The file is both human-readable documentation and machine-interpretable instructions. When the agent reads `CLAUDE.md`, it extracts:

1. **Behavioural rules** — augment not rewrite; mark gaps explicitly; write session notes first; preserve friction not consensus
2. **Load tiering** — index.md first, component docs on demand, full scan only when necessary
3. **The three operations** — which mode this session is (ingest / update / query)
4. **Structural templates** — what sections an index, component, or source doc must have
5. **Entity tagging convention** — `<!-- entity: type -->` and `<!-- depends-on: -->` in every component doc; `<!-- satisfies: -->` linking code to source doc sections
6. **Friction conventions** — `> **Inferred**:` for uncertainty; `> **Tension**:` for genuine conflicts and unresolved trade-offs
7. **Crystallisation checklist** — write session file → promote findings → update INSIGHTS.md → update DOCIT.md
8. **Core DocIt extras** — read MESSAGES.md, read INSIGHTS.md before exploring (if present)

## The Crystallisation Protocol

The most important addition to CLAUDE.md is the crystallisation step — the protocol that closes every session. It has six steps:

1. Write a raw session file to `sessions/`
2. Promote findings from it upward (component docs, patterns/, INSIGHTS.md, MESSAGES.md)
3. Extract cross-project patterns to `INSIGHTS.md`
4. Retire resolved `<!-- TODO: -->` markers
5. Update `DOCIT.md` log
6. Leave messages if core DocIt

This is how the working tier flows to the semantic tier. Without it, observations stay in context and are lost.

## Notes & Gotchas

The templates in `CLAUDE.md` use nested code blocks (markdown inside a markdown code block). Agents handle this well; editing manually requires care with backtick escaping.

The entity tags (`<!-- entity: -->`, `<!-- depends-on: -->`) are HTML comments — invisible in rendered markdown but extractable by `docit.sh graph`. They must be placed after the `<!-- explored: -->` tag and before the first section heading.

`> **Tension**:` and `> **Inferred**:` look similar but mean different things. `Inferred` = uncertain about a fact you couldn't verify. `Tension` = a real conflict you did verify — two components making contradictory assumptions, an ambiguous requirement, a surprising design choice. Both must be preserved; neither should be smoothed over.

Source docs (`<!-- entity: source -->`) have an immutability rule: the `>` quoted excerpts represent the original document and must never be modified. Only the `Implemented by` links and Coverage Summary around them can be updated.

The "What Not To Do" section is the most important guard rail. It now explicitly prohibits consensus docs — the agent's natural pull is toward smooth, readable summaries that hide genuine friction. Antagonistic Lint gives the checklist for actively hunting what consensus hides.

## Open Questions

- Should templates be extracted to a separate `templates/` directory for independent versioning?
- Should `CLAUDE.md` include example entity tag graphs showing correct vs incorrect tagging?
