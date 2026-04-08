# Sessions — Working Memory

> Raw notes captured during exploration sessions, before crystallisation.
> This is the working tier: write freely here, then promote what matters.

---

## What This Directory Is For

The `sessions/` directory is the **working memory** of DocIt. It holds raw,
unpolished notes from exploration sessions — observations, half-formed thoughts,
things to investigate, contradictions spotted in passing.

At the end of each session, the **Crystallisation** step reads these notes and
promotes findings upward:

```
sessions/<date>-<project>.md   →   docs/<project>/<component>.md
                               →   INSIGHTS.md  (if cross-project)
                               →   patterns/    (if recurring pattern)
```

Session files are never directly linked from docs. They are working drafts.
Once crystallised, they can be archived or deleted.

---

## Session File Format

Name: `YYYY-MM-DD-<project>[-<focus>].md`

```markdown
# Session: <project> — YYYY-MM-DD

<!-- session: YYYY-MM-DD -->
**Project**: project-name
**Focus**: what you explored (e.g. "auth module", "initial scan")

## Raw Observations

Free-form notes. Write fast, don't polish.

- Finding: ...
- Question: ...
- Contradiction: ...
- Pattern spotted: ...

## Findings to Promote

After session, mark each finding with its destination:

- [ ] → docs/<project>/<component>.md: <what to add>
- [ ] → INSIGHTS.md: <cross-project pattern>
- [ ] → patterns/<name>.md: <recurring pattern>
- [ ] → MESSAGES.md: <question for contributor>

## Crystallised

<!-- crystallised: YYYY-MM-DD -->
(fill this in after running the Crystallisation step)
```

---

## Lifecycle

1. **During session**: agent writes raw observations here
2. **End of session**: agent runs Crystallisation — promotes findings, ticks off the list
3. **After crystallisation**: session file is complete (has `<!-- crystallised: -->` tag)
4. **Cleanup**: crystallised files older than 30 days can be archived to `sessions/archive/`

---

## What NOT to Put Here

- Do not write final documentation here — use `docs/<project>/`
- Do not put sensitive data here — sessions/ is committed with the repo
- Do not leave unchecked findings indefinitely — they represent a debt
