# DocIt

> Explore and understand codebases through evolving markdown, powered by an AI agent.

---

## What Is This?

DocIt is a documentation system built on a simple idea: a well-crafted markdown file + a capable AI agent = living codebase documentation that actually stays useful.

You point DocIt at a codebase. The agent explores it and writes structured markdown. Next time you ask about that codebase, the agent reads the existing docs first, then digs deeper. Over time, your docs accumulate real understanding — architecture, key concepts, gotchas, open questions.

No databases. No build steps. No special software. Just markdown files and conversation.

---

## Quick Start

1. Clone this repo
2. Open a Claude conversation and reference `CLAUDE.md`
3. Say: *"Explore the codebase at /path/to/myproject"*
4. The agent generates `docs/<project-name>/index.md` and component docs
5. Next session: ask follow-up questions, the agent builds on what's already there

---

## Repository Layout

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Agent instructions — defines how DocIt sessions work |
| `DOCIT.md` | Living document — spec, current state, exploration log |
| `README.md` | This file |
| `docit.sh` | Helper script for starting sessions |
| `docs/` | All generated codebase explorations |
| `docs/docit/` | DocIt's self-documentation (dogfood example) |

---

## The Two Key Files

**`CLAUDE.md`** is the system's brain. It tells the agent:
- What to explore and how to structure the output
- What templates to use for index and component docs
- How to augment existing docs without overwriting them
- Conventions for marking gaps and uncertainty

**`DOCIT.md`** is the system's state. It holds:
- The vision and philosophy
- Current status (what's done, what's next)
- An exploration log (every codebase explored, when)
- Open questions about the system itself

The agent reads both at the start of every session.

---

## Example Session

```
You: Explore this repo: ~/projects/my-api

Agent: reads CLAUDE.md, reads DOCIT.md
Agent: scans ~/projects/my-api
Agent: creates docs/my-api/index.md     ← overview, structure, entry points
Agent: creates docs/my-api/routes.md    ← the routes module
Agent: creates docs/my-api/models.md    ← the data models
Agent: updates DOCIT.md                 ← logs the exploration

You: How does authentication work in my-api?

Agent: reads docs/my-api/index.md first
Agent: reads docs/my-api/routes.md
Agent: digs into the auth code specifically
Agent: updates docs/my-api/auth.md with new detail
```

---

## Philosophy

This is "pseudo software" — the markdown is the program, the agent is the runtime. Fork the repo and you get the whole system. No installation required.

Inspired by [PaulKinlan/journal](https://github.com/PaulKinlan/journal) and the emerging practice of using plain text + AI agents as a complete, durable software stack.

---

## Roadmap

- [x] Core markdown + agent system
- [ ] Mermaid diagram generation for architecture visualization
- [ ] LanceDB integration for semantic search across all explorations
