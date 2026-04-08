# Patterns

> Recurring architectural patterns observed across multiple codebases.
> This is the middle tier between per-project docs and the INSIGHTS.md summary.

<!-- explored: 2026-04-08 -->

---

## What Goes Here

A pattern doc belongs in `patterns/` when:

- The same architectural approach has been seen in **2+ projects**
- It's detailed enough to deserve its own doc (more than an INSIGHTS.md entry)
- Future explorations should link here rather than re-document from scratch

The flow is:
```
Spot it in a project → note in INSIGHTS.md → when seen again, promote to patterns/
```

---

## Pattern Doc Template

Filename: `patterns/<kebab-case-name>.md`

```markdown
# <Pattern Name>

**Type**: architectural | data | integration | security | testing | structural
**Seen in**: project-a, project-b
**First noted**: YYYY-MM-DD

<!-- explored: YYYY-MM-DD -->

## What It Is

One paragraph description.

## When It Appears

What conditions or requirements lead teams to use this pattern.

## How It Works

Concrete explanation. Code structure, data flow, key files.

## Variations

| Project | Variation | Notes |
|---------|-----------|-------|
| project-a | description | why they deviated |

## Trade-offs

What this pattern trades off. When it breaks down.

## Related Patterns

- [Other Pattern](./other-pattern.md) — how they relate

## Open Questions

<!-- TODO: ... -->
```

---

## Patterns

<!-- New pattern docs go in this directory. List them here as they're added. -->

| Pattern | Type | Seen in | Notes |
|---------|------|---------|-------|
| _(none yet — add as codebases are explored)_ | — | — | — |
