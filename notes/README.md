# Notes

Your free-form capture space. No conventions required.

Write whatever you like, however you like. Date it if that's useful. Don't if it isn't.

---

## What goes here

- Domain knowledge the code doesn't explain
- Rationale for past decisions
- Meeting notes, call summaries
- Quick observations that don't warrant a full session
- Contacts and process knowledge ("check with X before changing Y")

## What the agent does with it

At the start of each session the agent reads any notes for the current project. During crystallisation it promotes relevant observations into the appropriate component doc's `## Human Context` section, then marks the note `<!-- incorporated: YYYY-MM-DD -->`. The note file itself is never deleted or reformatted.

## Structure

```
notes/
├── README.md                          ← this file
├── <project>/
│   └── YYYY-MM-DD-<topic>.md          ← project-specific notes
└── YYYY-MM-DD-<topic>.md              ← cross-project notes
```

No other rules.
