# Living Document

**Path**: `DOCIT.md`
**Purpose**: The single source of truth for the system's state, vision, and history.

<!-- explored: 2026-04-08 -->

## What It Does

`DOCIT.md` is updated by the agent after every meaningful session. It serves three roles simultaneously:

1. **Specification** — describes what DocIt is and why
2. **State** — tracks what's been built, what's in progress, what's missing
3. **Log** — records every exploration with date and notes

This triple role is intentional. Traditional documentation separates spec, state, and changelog into three different places. Keeping them together means the agent only needs to update one place, and the human only needs to read one place.

## Key Sections

| Section | Stability | Updated When |
|---------|-----------|--------------|
| Vision | Stable | Only if the core idea changes |
| How It Works | Mostly stable | When the workflow changes |
| Architecture | Stable | When files are added/removed |
| Philosophy | Stable | Rarely |
| Current Status | Fluid | Every session |
| Exploration Log | Append-only | Every exploration |
| Open Questions | Fluid | Every session |
| Next Steps | Fluid | Every session |
| Future | Stable | When roadmap changes |

## How It Works

The agent reads `DOCIT.md` at the start of every session to understand:
- What has already been explored (Exploration Log)
- What's known to be missing (Open Questions, TODO items)
- What should be done next (Next Steps)
- The current status of DocIt itself (Current Status checklist)

After the session, the agent updates the fluid sections (Status, Log, Questions, Next Steps) in-place. The Exploration Log is **append-only** — old rows are never edited.

## Notes & Gotchas

The `<!-- last-updated: YYYY-MM-DD -->` tag at the top should be updated on every write — quick signal that the file is current.

The Exploration Log uses a four-column table (Date / Target / Type / Notes). Type is one of: Bootstrap, Enhancement, Ingest, Update. Keeping the type consistent makes the log scannable.

The Current Status checklist uses `- [x]` for done and `- [ ]` for pending. The agent updates this during crystallisation — it checks off items completed in the session and adds new pending items discovered.

## Open Questions

- Should `DOCIT.md` link to per-project state files, or is the single log table sufficient for many projects?
- As the Exploration Log grows long, should old entries be archived to `DOCIT-archive.md`?
