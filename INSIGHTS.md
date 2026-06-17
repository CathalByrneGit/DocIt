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

## Consensus Docs Are Dangerous
**Seen in**: docit (principle), jonadas.com essay
**First noted**: 2026-04-15 by docit-agent
**Last updated**: 2026-04-15

LLMs have a gravitational pull toward consensus — toward the average of everything they have read. When an agent summarises a codebase component, the natural output is accurate, well-formatted, and smoothed over. Genuine tensions — contradictory assumptions between components, ambiguous requirement implementations, surprising design choices — get resolved into readable prose that hides the decision point entirely.

Techio demonstrated this with 300 files of reading notes fed to an LLM compiler: output was perfectly formatted and completely useless, reading like Wikipedia entries rather than working knowledge.

The fix is explicit governance rules that force friction preservation. In DocIt: the `> **Tension**:` convention documents genuine conflicts rather than resolving them; the Antagonistic Lint checklist actively hunts for places where consensus is disguising conflict; source doc immutability ensures the original requirements can't be quietly rewritten to match what the code actually does.

> **Implication**: when reviewing agent-generated docs, the most dangerous output is not the obviously wrong claim — it is the smoothly written paragraph that has erased a real trade-off. Hunt for `> **Tension**:` markers that are absent where they should be present.

## Markdown as Universal Knowledge Format
**Seen in**: docit, mempalace, google-okf, karpathy-llm-wiki
**First noted**: 2026-06-17 by docit-agent
**Last updated**: 2026-06-17

Four independent projects converge on the same architecture: a directory of markdown files, maintained by an AI agent, with no database and no proprietary platform. Karpathy proposed LLM-wiki as a pattern. MemPalace implemented it for personal memory. Google formalized it as OKF v0.1 (Open Knowledge Format, published 2026-06-12). DocIt applies it to codebase documentation.

The shared design surface: one concept per file, directory structure as taxonomy, cross-linking via standard markdown links, an index file for progressive disclosure, and agent-as-runtime for reads and writes. The format is both human-readable and machine-parseable without special tooling.

Where they diverge is instructive: OKF uses YAML frontmatter for structured metadata; DocIt uses HTML comments (invisible in rendered markdown). OKF separates producer and consumer cleanly; DocIt adds a bidirectional flow where humans also write (notes/) and the agent promotes. MemPalace prioritises verbatim storage and retrieval benchmarks; DocIt prioritises friction preservation and living updates.

The convergence suggests this is not a trend but a stable equilibrium — markdown directories are the natural format for agent-maintained knowledge, the way JSON became the natural format for APIs.

> **Implication**: invest in the format's self-describing qualities (templates, entity tags, consistent structure) rather than building proprietary tooling around it. Any agent that can read markdown and follow links can consume DocIt docs — the value is in the content model, not the runtime.
