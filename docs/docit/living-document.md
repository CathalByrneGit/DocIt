# Living Document

**Path**: `DOCIT.md`
**Purpose**: The single source of truth for the system's state, vision, and history.

<!-- explored: 2026-02-26 -->

## What It Does

`DOCIT.md` is updated by the agent after every meaningful session. It serves three roles simultaneously:

1. **Specification** — describes what DocIt is and why
2. **State** — tracks what's been built, what's in progress, what's missing
3. **Log** — records every exploration with date and notes

This triple role is intentional. Traditional documentation separates "what it should do" (spec), "what it does now" (state), and "what happened" (changelog) into three different places. Keeping them together in one file means the agent only needs to update one place, and the human only needs to read one place.

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

After the session, the agent updates the fluid sections (Status, Log, Questions, Next Steps) in-place.

## Notes & Gotchas

The `<!-- last-updated: YYYY-MM-DD -->` tag at the top of `DOCIT.md` should be updated on every write. It's a quick signal to the human that the file is recent.

The Exploration Log table should be **append-only** — never edit old rows, only add new ones. This preserves the history of what the agent has understood over time.

## Open Questions

- Should `DOCIT.md` link to per-project state files, or is the single log table enough for many projects?
- Is there value in a `CHANGELOG.md` that's separate from the exploration log?
