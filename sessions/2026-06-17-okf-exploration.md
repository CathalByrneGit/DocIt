# Session: Google Open Knowledge Format (OKF)

**Date**: 2026-06-17
**Source**: https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing
**Focus**: External spec — OKF v0.1 assessed for DocIt applicability

---

## Raw Observations

### What OKF is
Google's open specification (v0.1, published 2026-06-12) formalizing the LLM-wiki pattern into a portable format. A "bundle" is a directory of markdown files with YAML frontmatter. One concept per file, file path = concept identity. Only required field: `type` in YAML frontmatter. Cross-linking via standard markdown links. Optional `index.md` for progressive disclosure and `log.md` for chronological history.

### Core design principles
| Principle | What it means |
|-----------|---------------|
| Minimally opinionated | Only `type` is required; producers decide content model |
| Producer/consumer independence | Writers and readers are decoupled; format is the contract |
| Format not platform | No vendor lock-in, no proprietary SDKs, no accounts needed |

### Reference implementations
- **Producer**: enrichment agent that walks BigQuery datasets and drafts OKF concept docs
- **Consumer**: static HTML visualizer — self-contained, no backend, no data leaves the page
- **Sample bundles**: GA4 e-commerce, Stack Overflow, Bitcoin (all BigQuery public datasets)

### Direct mapping to DocIt

| OKF concept | DocIt equivalent | Notes |
|-------------|-----------------|-------|
| Bundle | `docs/<project>/` | Same structure — directory per knowledge domain |
| Concept file | Component doc (`<component>.md`) | Same: one file per concept/module |
| `type` field (YAML) | `<!-- entity: type -->` (HTML comment) | Same purpose, different encoding |
| `index.md` | `docs/<project>/index.md` | Already present in DocIt |
| `log.md` | `DOCIT.md` exploration log + `sessions/` | DocIt splits this into two tiers |
| Cross-linking | Relative markdown links | Identical approach |
| YAML frontmatter | HTML comment tags | Different trade-offs (see below) |
| Producer/consumer split | Agent writes / human reads | DocIt adds the inverse: human writes notes, agent reads |

### YAML frontmatter vs HTML comments

OKF uses YAML frontmatter:
```yaml
---
type: BigQuery Table
title: Orders
timestamp: 2026-05-28T14:30:00Z
tags: [sales, revenue]
---
```

DocIt uses HTML comments:
```html
<!-- explored: 2026-04-08 -->
<!-- entity: service -->
<!-- depends-on: database, auth -->
```

**Trade-offs:**
- YAML: more standard, tooling-friendly (Hugo, Jekyll, Obsidian, any YAML parser), more readable when editing
- HTML comments: invisible in rendered markdown (clean GitHub view), can be placed anywhere in the doc (critical for inline `<!-- superseded: -->` markers)
- Hybrid approach possible: YAML frontmatter for top-of-file metadata, HTML comments for inline markers

**Decision: not changing now.** HTML comments work well for DocIt's current use. If DocIt wants OKF interoperability in the future, adding YAML frontmatter alongside HTML comments is straightforward. The inline markers (superseded, TODO, incorporated) must stay as HTML comments regardless.

### What was NOT taken from OKF
- YAML frontmatter adoption — not needed now, noted as open question
- `log.md` convention — DocIt's two-tier approach (sessions/ + DOCIT.md) is richer
- Formal conformance criteria — DocIt uses lint instead, which is more flexible
- BigQuery-specific reference implementations — different domain

### What IS taken
- **Convergence validation**: independent confirmation that markdown-as-database, agent-as-runtime is becoming an industry pattern
- **Producer/consumer independence as explicit principle**: DocIt docs should be self-describing for any consumer, not just the DocIt agent
- **YAML frontmatter as a future consideration**: noted in open questions for when/if OKF interop matters

---

## Findings to Promote

- [x] → `INSIGHTS.md`: "Markdown as Universal Knowledge Format" — convergence across 4 independent projects
- [x] → `DOCIT.md`: Exploration log row + YAML frontmatter open question
- [x] → `docs/docit/index.md`: Add format portability to Key Concepts

<!-- crystallised: 2026-06-17 -->
