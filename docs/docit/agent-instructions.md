# Agent Instructions

**Path**: `CLAUDE.md`
**Purpose**: Defines how the DocIt agent behaves in every session.

<!-- explored: 2026-02-26 -->

## What It Does

`CLAUDE.md` is the agent's operating manual. When a user opens a DocIt conversation, the agent reads this file to understand:

- What DocIt is and what it's trying to achieve
- What to do at the start of a new exploration
- What templates to use for index and component docs
- How to handle updates to existing docs
- Naming conventions, uncertainty markers, gap markers

## Key Sections

| Section | Purpose |
|---------|---------|
| Your Role | Agent mindset — augment, don't rewrite |
| Starting a New Exploration | Step-by-step for first-time codebase scans |
| Index Template | Markdown template for `docs/<project>/index.md` |
| Component Template | Markdown template for individual module docs |
| Updating Existing Docs | How to handle second/third exploration passes |
| Conventions | File naming, dates, link format, uncertainty markers |
| What Not To Do | Guard rails against common failure modes |
| DOCIT.md Sections to Update | Reminder of what to update after each session |

## How It Works

The file uses markdown formatting to be both human-readable documentation and machine-interpretable instructions. When the agent reads `CLAUDE.md`, it extracts:

1. Behavioural rules (augment, don't rewrite; mark gaps explicitly)
2. Structural templates (what sections a good index doc has)
3. Conventions (kebab-case filenames, ISO dates, `> **Inferred:**` prefix)
4. Post-session checklist (what to update in `DOCIT.md`)

## Notes & Gotchas

The templates in `CLAUDE.md` use a nested code block pattern (markdown inside a markdown code block). Agents handle this well, but if you're editing manually, be careful with the backtick escaping.

The "What Not To Do" section is important — without it, agents tend to rewrite existing docs from scratch on update, losing accumulated knowledge.

## Open Questions

- Should the templates be extracted to a separate `templates/` directory so they can be versioned independently?
- Is the current set of conventions enough, or are there edge cases that need explicit rules?
