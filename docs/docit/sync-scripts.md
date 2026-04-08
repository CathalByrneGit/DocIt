# Sync Scripts

**Path**: `backup.sh`, `restore.sh`, `merge.sh`, `cron.sh`, `setup.sh`
**Purpose**: Knowledge persistence, multi-device sync, and team federation.

<!-- explored: 2026-04-08 -->
<!-- entity: utility -->
<!-- depends-on: living-document -->

## What It Does

Five scripts handle everything outside the agent's conversation: persisting knowledge to a private git repo, syncing across devices, and merging knowledge from team members' DocIts.

| Script | Trigger | What it does |
|--------|---------|--------------|
| `backup.sh` | Manual or post-merge | rsync docs/ + DOCIT.md + federation files to a private git repo, commit + push |
| `restore.sh` | Manual (disaster recovery) | Pull latest from backup repo, rsync back to local DocIt |
| `merge.sh` | Manual or via cron | Remote sync (git merge) or contributor import (`--contrib`) |
| `cron.sh` | Scheduler (not directly) | Lock-file wrapper: prevents overlapping runs, timestamps log output |
| `setup.sh` | One-time install | Installs `cron.sh` as a crontab or systemd user timer |

## Key Files

| File | Role |
|------|------|
| `backup.sh` | Push knowledge to private git repo |
| `restore.sh` | Pull knowledge from private git repo |
| `merge.sh` | Sync with git remote or import from contributor |
| `cron.sh` | Scheduled sync runner with lock file |
| `setup.sh` | Crontab/systemd installer for `cron.sh` |
| `.cron.log` | Append-only sync log (gitignored) |
| `.docit.conf` | `DOCIT_BACKUP_DIR` variable consumed by `backup.sh` and `merge.sh` |

## How It Works

```mermaid
graph TD
  User([User]) -->|"./setup.sh"| Scheduler[cron / systemd timer]
  Scheduler -->|"every N minutes"| Cron[cron.sh]
  Cron -->|acquires lock| Lock[/tmp/docit-cron.lock]
  Cron --> Merge[merge.sh]
  Merge -->|git fetch + merge| Remote[(git remote)]
  Merge -->|conflict .md files| Claude[claude -p]
  Claude -->|synthesised doc| Merge
  Merge -->|backup first| Backup[backup.sh]
  Backup -->|rsync + git push| BackupRepo[(private git repo)]
```

The `merge.sh` step is the key one: it doesn't just pick a side on conflicted `.md` files — it calls `claude -p` to read both versions and synthesise them into one coherent document, preserving knowledge from both sides.

### Conflict Resolution Flow (remote merge)

1. `git fetch origin`
2. Detect divergence (local and remote both have commits the other lacks)
3. `git merge --no-commit --no-ff` — produces conflict markers in `.md` files
4. For each conflicted `.md`: create a pseudo-conflict file, send to `claude -p` with synthesis prompt
5. Stage resolved files, `git commit`

### Contributor Import Flow (`merge.sh --contrib <path>`)

1. Walk `<contrib>/docs/` — for each project directory:
   - If it doesn't exist locally: copy in full
   - If it exists and files differ: create pseudo-conflict, call `claude -p` to synthesise
2. Merge `INSIGHTS.md` using the same synthesis approach
3. Append new entries from contributor's `MESSAGES.md` (deduplicating by line content)
4. Print summary; user reviews changes and commits manually

## Interfaces

**`backup.sh`**:
- Input: `DOCIT_BACKUP_DIR` (env or `.docit.conf`) or first positional arg
- Output: rsync to backup dir + git commit + push
- Idempotent: exits cleanly if nothing changed

**`restore.sh`**:
- Input: backup dir as first positional arg
- Prompts for confirmation before overwriting
- Pulls latest from backup remote, then rsyncs back

**`merge.sh`**:
- `./merge.sh` — remote merge with `origin`
- `./merge.sh <remote>` — remote merge with named remote
- `./merge.sh --contrib <path>` — contributor import
- Falls back gracefully if `claude` CLI is not available (skips synthesis, leaves for manual resolution)

**`cron.sh`**:
- No arguments — reads config from `.docit.conf`
- Lock file at `/tmp/docit-cron.lock` (PID-checked, stale lock removed)
- Appends timestamped output to `.cron.log`

**`setup.sh`**:
- `./setup.sh [--interval <minutes>]` — install (default: 30 min)
- `./setup.sh --uninstall` — remove
- Auto-detects systemd vs crontab; prefers systemd if `basic.target` is active

## Dependencies

- **git**: required by `merge.sh`, `backup.sh`, `restore.sh`
- **rsync**: required by `backup.sh`, `restore.sh`
- **claude CLI**: used by `merge.sh` for conflict synthesis; degrades gracefully without it
- **systemd** (optional): used by `setup.sh` if detected; falls back to crontab
- **crontab**: fallback scheduler for `setup.sh`

## Notes & Gotchas

`backup.sh` syncs `docs/` with `--delete`, so files removed locally will be removed from the backup on the next run. This is intentional — the backup mirrors current state, not history. Git history in the backup repo provides the history.

`restore.sh` also uses `--delete` on `docs/` — it fully mirrors the backup. Run it only as disaster recovery.

`merge.sh` backs up before merging if `DOCIT_BACKUP_DIR` is set. This provides a safety net before any destructive merge step.

`claude -p` in `merge.sh` is stateless — each conflict is sent as a single prompt with both versions inlined. The synthesis quality depends on context length; very large docs (>50KB) may be truncated.

The `cron.sh` lock file is PID-checked: if the stored PID is no longer running, the stale lock is cleared automatically. No manual intervention needed after a crash.

## Open Questions

- Should `backup.sh` also sync `sessions/` (working notes), or is that intentionally ephemeral?
- Should `restore.sh` have a `--dry-run` flag to preview what would be overwritten?
- Should `merge.sh --contrib` update `CONTRIBUTORS.md` automatically after a successful import?
