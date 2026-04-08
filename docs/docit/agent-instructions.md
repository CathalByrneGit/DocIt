# Agent Instructions

**Path**: `CLAUDE.md`
**Purpose**: Defines how the DocIt agent behaves in every session.

<!-- explored: 2026-04-08 -->

## What It Does

`CLAUDE.md` is the agent's operating manual and the procedural tier of the knowledge model. When a user opens a DocIt conversation, the agent reads this file to understand the full operating context: what DocIt is, what the three operations are, how to write and tag docs, how to end a session, and what cross-project knowledge infrastructure to maintain.

## Key Sections

| Section | Purpose | Stability |
|---------|---------|-----------|
| Your Role | Agent mindset — augment, don't rewrite | Stable |
| Consolidation Tiers | Four-layer knowledge model (working → episodic → semantic → procedural) | Stable |
| The Three Operations | Ingest / Update / Query as first-class operations | Stable |
| Ingest: New Codebase | Step-by-step for first-time codebase scans + Index Template | Stable |
| Component Template | Markdown template for module docs; includes entity tags | Stable |
| Update: After Code Changes | How to re-examine changed files and patch docs | Stable |
| End of Session: Crystallisation | 6-step end-of-session protocol | Stable |
| Conventions | File naming, dates, links, uncertainty, gaps, supersession, entity tags | Stable |
| Entity Tagging | Entity types, relationship tags, example, how graph command uses them | Stable |
| Patterns | When to create `patterns/<name>.md` vs just note in INSIGHTS.md | Stable |
| Mermaid Diagrams | When to add, which type, conventions, four copy-paste examples | Stable |
| What Not To Do | Guard rails against common failure modes | Stable |
| If This Is a Core DocIt | Extra session-start protocol for reading MESSAGES.md and INSIGHTS.md | Stable |

## How It Works

The file is both human-readable documentation and machine-interpretable instructions. When the agent reads `CLAUDE.md`, it extracts:

1. **Behavioural rules** — augment not rewrite; mark gaps explicitly; write session notes first
2. **The three operations** — which mode this session is (ingest / update / query)
3. **Structural templates** — what sections an index or component doc must have
4. **Entity tagging convention** — `<!-- entity: type -->` and `<!-- depends-on: -->` in every component doc
5. **Crystallisation checklist** — write session file → promote findings → update INSIGHTS.md → update DOCIT.md
6. **Core DocIt extras** — read MESSAGES.md, read INSIGHTS.md before exploring (if present)

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

The "What Not To Do" section is the most important guard rail. Without it, agents rewrite docs from scratch on update passes, discarding accumulated knowledge.

## Open Questions

- Should templates be extracted to a separate `templates/` directory for independent versioning?
- Should `CLAUDE.md` include example entity tag graphs showing correct vs incorrect tagging?
