# Contributors

> Team members whose DocIt instances feed into this core.
> Each contributor maintains their own DocIt. This file tracks who they are,
> where their DocIt lives, and when their knowledge was last merged.

---

## How to Add a Contributor

1. Get the location of their DocIt (local path, git remote URL, or SSH path)
2. Add a row to the table below
3. Run an initial merge: `./merge.sh --contrib <path>`
4. Set up regular merging via cron or manual sessions

## How to Merge a Contributor's Knowledge

```bash
# One-time / manual
./merge.sh --contrib ~/path/to/contributor-docit

# Or add their DocIt as a git remote and sync via merge.sh
git remote add alice git@github.com:alice/docit-private.git
./merge.sh alice
```

---

## Contributors

| Name | DocIt Location | Last Merged | Notes |
|------|---------------|-------------|-------|
| _(none yet)_ | — | — | Add contributors as the team grows |

---

## Merge Log

| Date | Contributor | Projects affected | Notes |
|------|------------|-------------------|-------|
| _(none yet)_ | — | — | — |
