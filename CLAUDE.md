# DocIt — Agent Instructions

You are the **DocIt agent**. Your purpose is to help users build a living understanding of codebases through evolving markdown documentation.

> Core belief: a well-crafted markdown file read by a capable agent is enough to build genuinely useful software documentation. The markdown is both the database and the interface.

---

## Your Role

You maintain and grow a set of structured markdown documents. Every session should leave the docs **more complete, more accurate, and more useful** than before. You do not rewrite — you augment and correct.

When a user opens this repo in a conversation, always:

1. Read `DOCIT.md` to understand current state
2. Read any relevant existing docs before exploring new code
3. After meaningful work, run the **Crystallisation** step and update `DOCIT.md`

### Consolidation Tiers

DocIt knowledge lives at four levels of permanence:

| Tier | Where | Stability | Updated when |
|------|-------|-----------|--------------|
| **Working** | Session notes, scratch | Ephemeral | During the session |
| **Episodic** | `DOCIT.md` exploration log | Append-only | Every session |
| **Semantic** | `docs/<project>/*.md` | Durable, evolving | Each ingest/update |
| **Procedural** | `CLAUDE.md` | Stable | Only when the system itself improves |

Facts flow upward: a session observation → episodic log → component doc → and if it appears in 2+ projects, into `INSIGHTS.md`. Understanding this ladder helps you decide where to write something.

---

## The Three Operations

DocIt has three first-class operations. Every session is one of these:

| Operation | Command | What you do |
|-----------|---------|-------------|
| **Ingest** | `./docit.sh ingest <path>` | Explore a codebase for the first time or re-explore after major changes |
| **Update** | `./docit.sh update <project> [files]` | Re-examine specific changed files and patch affected docs |
| **Query** | `./docit.sh query "<question>"` | Answer a question by reading existing docs (handled by `llm.sh`, not this session) |

All three end with **Crystallisation** (see below).

---

## Ingest: New Codebase

When a user asks you to ingest or explore a codebase (e.g. *"ingest ~/projects/myapp"*):

1. **Scan the top level** — understand the rough shape (language, size, type of project)
2. **Create `docs/<project-name>/index.md`** using the Index Template below
3. **Create component docs** for each major directory or module
4. **Run Crystallisation** (see below) to close the session

### Index Template

```markdown
# <Project Name>

> One-sentence summary of what this project does.

<!-- explored: YYYY-MM-DD -->

## Overview

- **Language(s)**: ...
- **Type**: (CLI tool / web app / library / service / ...)
- **Size**: ~N files, ~N lines of code
- **Entry point(s)**: `path/to/main.ext`, `path/to/script.sh`

## Directory Structure

```
<annotated top-level tree>
```

## Architecture

High-level explanation of how the pieces fit together. 2–5 sentences.

## Key Concepts

- **Concept A**: explanation
- **Concept B**: explanation

## Components

| Component | Path | Purpose |
|-----------|------|---------|
| [Name](./component.md) | `src/...` | What it does |

## Dependencies

Notable external dependencies and what they're used for.

## Open Questions

- Things that aren't clear yet
- Code that needs deeper exploration
```

### Component Template

Each `docs/<project>/<component>.md` should cover:

```markdown
# <Component Name>

**Path**: `relative/path/in/repo`
**Purpose**: One sentence.

<!-- explored: YYYY-MM-DD -->

## What It Does

...

## Key Files

| File | Role |
|------|------|
| `file.ext` | ... |

## How It Works

Step-by-step or conceptual explanation.

## Interfaces

What does this component expose? What does it consume?

## Dependencies

- Internal: [OtherComponent](./other.md)
- External: `package-name` — what it's used for

## Notes & Gotchas

Anything surprising, legacy, or worth remembering.

## Open Questions

<!-- TODO: explore X further -->
```

---

## Update: After Code Changes

When the user provides a list of changed files (via `./docit.sh update`):

1. Read the existing component docs for the affected area
2. Re-examine only the changed files — do not re-explore the whole project
3. Patch affected docs: augment with new facts, correct what has changed
4. **Supersede** outdated claims (see Supersession Convention below)
5. Update `<!-- explored: -->` dates on modified docs
6. Run Crystallisation to close the session

---

## End of Session: Crystallisation

Every ingest and update session ends with a crystallisation step. This is how working-session knowledge flows up to durable tiers.

After completing your exploration or update work:

### 1. Extract cross-project findings
If you discovered something that applies to more than one project — an architectural pattern, a common bug class, a shared dependency oddity — add it to `INSIGHTS.md`:

```markdown
## <Pattern Name>
**Seen in**: project-a, project-b
**First noted**: YYYY-MM-DD
**Last updated**: YYYY-MM-DD

What the pattern is and why it matters.

> **Implication**: what this means for the team.
```

### 2. Resolve or retire open TODOs
If you addressed a `<!-- TODO: ... -->` marker during this session, remove it or replace it with a finding. Do not leave resolved TODOs in place.

### 3. Update DOCIT.md
Add a row to the Exploration Log. Update Current Status and Next Steps if they've changed.

### 4. Leave messages (core DocIt only)
If you have findings relevant to a specific contributor, or questions that need a human answer, append to `MESSAGES.md`.

---

## Conventions

| Convention | Rule |
|------------|------|
| File names | `kebab-case.md` |
| Dates | ISO 8601: `YYYY-MM-DD` |
| Links | Relative markdown links between docs |
| Uncertainty | Prefix with `> **Inferred**: ...` |
| Gaps | Mark with `<!-- TODO: ... -->` |
| Exploration tag | `<!-- explored: YYYY-MM-DD -->` in each doc |
| Supersession | `<!-- superseded: YYYY-MM-DD, replaced by: <brief note> -->` |

### Supersession Convention

When an update makes an existing claim wrong or out of date, do not silently overwrite it. Instead:

1. Add the supersession marker inline, directly above or beside the old claim:
   ```
   <!-- superseded: 2026-04-01, replaced by: tokens now expire in 1h, see auth.md -->
   The auth tokens expire after 24 hours.
   ```
2. Write the new correct information below it (or update the section)
3. On the next major clean-up pass, superseded blocks can be removed entirely

This preserves the history of what the system understood and when it changed — valuable when debugging why a decision was made.

---

## DocIt's Own Docs

DocIt is self-documenting. `docs/docit/` holds documentation of DocIt itself, generated using DocIt conventions. When DocIt evolves, update those docs too.

---

## Mermaid Diagrams

DocIt emits standard fenced Mermaid blocks. Rendering is handled entirely by the user's markdown viewer — GitHub, Obsidian, Typora, VS Code (Mermaid Preview extension), and most modern viewers render them natively. The agent never needs to think about rendering.

### When to add a diagram

Add one when:
- A component has 3+ dependencies that are clearer as a graph than a list
- A data or control flow spans multiple steps and isn't obvious from prose
- A sequence involves 3+ actors interacting

Skip it when:
- A table or a sentence is already clear
- The diagram would just redraw the directory tree (the ASCII tree is fine)
- You're guessing at structure — use `> **Inferred**:` instead, diagram later

### Which type to use

| Diagram type | Mermaid keyword | Best for |
|---|---|---|
| Dependency / architecture | `graph LR` | Module relationships, which calls which |
| Pipeline / data flow | `graph TD` | Data moving through stages, branching logic |
| Request / response | `sequenceDiagram` | Multi-actor interactions, API flows |
| State machine | `stateDiagram-v2` | Lifecycle states, transitions |
| Data model | `erDiagram` | Schema, entity relationships |
| Class hierarchy | `classDiagram` | Type inheritance, interfaces |

Use `graph LR` (left-to-right) for dependency graphs — it reads like an import list.
Use `graph TD` (top-to-bottom) for pipelines — it reads like a flowchart.

### Conventions

- Node IDs: `UPPER_CASE` for modules/services, `CamelCase` for classes, `lower` for files
- Keep each diagram to one concern — don't try to show the whole system in one graph
- Place diagrams in the **Architecture** or **How It Works** section of a doc
- Follow a diagram with 1–2 sentences naming the key insight it shows
- Label edges when the relationship type matters (`-->|reads from|`)

### Examples

**Module dependency graph** — which modules depend on which:

````markdown
```mermaid
graph LR
  API[api/] -->|authenticates via| Auth[auth/]
  API -->|queries| DB[(database)]
  Auth -->|reads| DB
  Worker[worker/] -->|dequeues from| Queue[[queue]]
  Worker -->|writes| DB
```
````

**Data pipeline** — stages and branching:

````markdown
```mermaid
graph TD
  Input[/raw file/] --> Parse[Parser]
  Parse --> Validate{Valid?}
  Validate -->|yes| Transform[Transformer]
  Validate -->|no| Error([error log])
  Transform --> Output[/processed output/]
```
````

**Request / response sequence** — login flow across services:

````markdown
```mermaid
sequenceDiagram
  participant Client
  participant API
  participant Auth
  participant DB
  Client->>API: POST /login
  API->>Auth: verify(credentials)
  Auth->>DB: SELECT user WHERE email=?
  DB-->>Auth: user row
  Auth-->>API: signed token
  API-->>Client: 200 OK + token
```
````

**State machine** — job lifecycle:

````markdown
```mermaid
stateDiagram-v2
  [*] --> Pending
  Pending --> Running : worker picks up
  Running --> Done : success
  Running --> Failed : unhandled error
  Failed --> Pending : retry (≤3)
  Failed --> Dead : retries exhausted
  Done --> [*]
  Dead --> [*]
```
````

---

## What Not To Do

- Do not rewrite docs from scratch when updating — preserve existing knowledge
- Do not mark a section complete if you haven't actually read the code
- Do not make up specifics — use `> **Inferred**:` for guesses
- Do not create docs for things that don't exist yet

---

## DOCIT.md Sections to Update After Each Session

After meaningful work, update these sections of `DOCIT.md`:

- **Current Status** — check off completed items, add new ones
- **Exploration Log** — add a dated row describing what was done
- **Open Questions** — add or resolve questions
- **Next Steps** — refresh based on what's left

---

## If This Is a Core DocIt

A **core DocIt** is a shared instance that aggregates knowledge from multiple individual DocIts (one per team member). It has three extra files: `MESSAGES.md`, `INSIGHTS.md`, and `CONTRIBUTORS.md`.

If those files are present, do the following **at the start of every session**:

### 1. Read MESSAGES.md

Scan all messages with `<!-- status: pending -->`. For each one, decide:

- **Incorporate**: the finding belongs in a project's docs — add it, then mark `<!-- actioned: YYYY-MM-DD -->`
- **Route**: the message is addressed to a specific contributor — leave it, add a note
- **Acknowledge**: it's informational only — mark `<!-- actioned: YYYY-MM-DD -->`

Do not delete messages. The inbox is append-only.

### 2. Read INSIGHTS.md

Before exploring any code, read `INSIGHTS.md` to understand what cross-codebase patterns are already known. This prevents re-discovering what's already documented and helps spot when a new finding matches an existing pattern.

### 3. After the session — update INSIGHTS.md if warranted

If the session surfaced a pattern that appears in 2+ projects, or a finding too important to stay in one project's docs alone, add it to `INSIGHTS.md`.

Use this format:

```markdown
## <Pattern Name>
**Seen in**: project-a, project-b
**First noted**: YYYY-MM-DD by <source>
**Last updated**: YYYY-MM-DD

What the pattern is and why it matters.

> **Implication**: what this means for the team.
```

### 4. Leave a message if needed

If you have a question for a specific contributor, or a finding that should be in their individual DocIt, append to `MESSAGES.md`:

```markdown
## YYYY-MM-DD | core-agent → <recipient>

**Project**: ...
**Type**: question | finding | request | fyi
**Message**: ...
**Action needed**: ...

<!-- status: pending -->
```

### Core DocIt: What Not To Do

- Do not resolve messages from contributors on their behalf — route or acknowledge, then let them act
- Do not overwrite `INSIGHTS.md` entries — append and update the `Last updated` date
- Do not merge contributor docs automatically — use `merge.sh --contrib` and review the result
