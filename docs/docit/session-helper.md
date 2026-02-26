# Session Helper

**Path**: `docit.sh`
**Purpose**: CLI utility to start DocIt exploration sessions and check status.

<!-- explored: 2026-02-26 -->

## What It Does

`docit.sh` is a thin bash wrapper that makes it easy to start DocIt sessions without remembering the exact prompt format. It doesn't do any AI work itself — it just prints a ready-made prompt you paste into your Claude conversation.

## Key Files

| File | Role |
|------|------|
| `docit.sh` | The entire script — ~90 lines of bash |

## Commands

### `./docit.sh explore <path>`

Takes a filesystem path, resolves it to an absolute path, finds the project name, and prints:
- A session overview (target, project name, docs output path)
- A ready-to-paste Claude prompt that tells the agent exactly what to do

If docs already exist for this project, it notes "previously explored — agent will augment existing docs" so you know it won't start from scratch.

### `./docit.sh status`

Scans `docs/` for `index.md` files, counts them, and prints a summary of each explored codebase with:
- Project name
- Number of doc files
- Last explored date (extracted from `<!-- explored: -->` tags)

### `./docit.sh help`

Prints usage.

## How It Works

```bash
cmd_explore() {
  # 1. Validate path exists
  # 2. Resolve to absolute path
  # 3. Extract project name (basename)
  # 4. Check if index.md already exists (augment vs new)
  # 5. Print formatted session prompt
}
```

The script uses `mapfile` for array population (requires bash 4+). On macOS, the system bash is 3.x — use `brew install bash` or `#!/usr/bin/env bash` with a newer bash in PATH.

## Interfaces

**Input**: command-line arguments (`explore <path>`, `status`, `help`)
**Output**: stdout — formatted text for human reading

The script does not write any files. All file creation is done by the agent during the conversation.

## Dependencies

- Internal: reads `docs/` directory structure
- External: bash 4+, standard POSIX tools (`find`, `grep`, `awk`)

## Notes & Gotchas

The `explore` command deliberately prints a prompt rather than opening a conversation automatically. This keeps the tool simple and avoids a dependency on the `claude` CLI being installed. If you want auto-open, the prompt could be piped to `claude` directly.

The `<!-- explored: -->` date extraction uses a simple `grep -o` — it reads the first occurrence in `index.md`. This means component docs' dates are ignored in the status view.

## Open Questions

- Should `./docit.sh explore` accept a `--name` flag to override the project name?
- Worth adding `./docit.sh new-session <project>` that opens `claude` CLI directly if available?
