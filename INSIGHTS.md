# Insights

> Cross-codebase patterns and discoveries.
> Add an entry when a pattern appears in 2+ projects, or when a finding is too important to stay buried in one project's docs.
> This is a curated ledger — not everything goes here, only what's worth knowing across the whole codebase portfolio.

---

## Format

```
## <Pattern or Finding Name>
**Seen in**: project-a, project-b
**First noted**: YYYY-MM-DD by <contributor>
**Last updated**: YYYY-MM-DD

Description. What the pattern is, why it matters, what to watch out for.

> **Implication**: what this means for the team / future work.
```

---

## Insights

<!-- New insights go below this line -->

## Store Verbatim, Retrieve Structured
**Seen in**: mempalace, docit
**First noted**: 2026-04-08 by docit-agent
**Last updated**: 2026-04-08

Raw, uncompressed storage paired with structured retrieval outperforms lossy compression paired with flat search. MemPalace demonstrated this concretely: raw verbatim mode scores 96.6% R@5 on LongMemEval, while their AAAK lossy compression dialect drops to 84.2% — a 12-point regression. Compression strips the contextual detail that retrieval depends on.

DocIt follows the same principle: the supersession convention never deletes old claims, it marks them as superseded inline. Entity tagging + the `graph` command provide the structured retrieval layer on top of raw markdown storage.

The implication is: when a knowledge system faces a choice between "compress smartly now" vs "store fully and structure the index", choose the latter. Intelligence should be in the retrieval layer, not the storage layer.

> **Implication**: do not summarise component docs to save space. Preserve full detail and use the entity graph, patterns/, and INSIGHTS.md to create navigable structure on top. The cost of storage is low; the cost of lost context is high.
